"""Fully local Kokoro text-to-speech for Arthur."""

from __future__ import annotations

from io import BytesIO
import json
from pathlib import Path
import re
from threading import Lock
from urllib.request import urlretrieve
import wave

import numpy as np
from kokoro_onnx import Kokoro


BACKEND_DIRECTORY = Path(__file__).resolve().parents[1]
MODEL_DIRECTORY = BACKEND_DIRECTORY / ".models" / "kokoro"
MODEL_PATH = MODEL_DIRECTORY / "kokoro-v1.0.onnx"
VOICES_PATH = MODEL_DIRECTORY / "voices-v1.0.bin"

# Kokoro's British male Daniel preset has a lower, grounded delivery suited
# to a concise desktop assistant without imitating a specific performer.
ARTHUR_VOICE = "bm_daniel"
ARTHUR_LANGUAGE = "en-gb"
ARTHUR_SPEED = 0.96

MODEL_FILES = {
    MODEL_PATH: "https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.1/kokoro-v1.0.onnx",
    VOICES_PATH: "https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.1/voices-v1.0.bin",
}

_engine: Kokoro | None = None
_engine_lock = Lock()


def synthesize_speech(text: str, speed: float = ARTHUR_SPEED) -> bytes:
    """Return local Kokoro speech as a standard WAV payload."""

    clean_text = normalize_for_speech(text)
    if not clean_text:
        raise ValueError("Speech text cannot be empty.")

    with _engine_lock:
        engine = _get_engine()
        samples, sample_rate = engine.create(
            clean_text,
            voice=ARTHUR_VOICE,
            speed=min(max(speed, 0.72), 1.18),
            lang=ARTHUR_LANGUAGE,
        )

    # AVAudioPlayer reads uncompressed PCM WAV without any third-party codec.
    pcm = (np.clip(samples, -1.0, 1.0) * 32767).astype("<i2").tobytes()
    output = BytesIO()
    with wave.open(output, "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        wav_file.writeframes(pcm)
    return output.getvalue()


def normalize_for_speech(text: str) -> str:
    """Turn chat formatting and common mathematical notation into plain speech."""

    clean = _extract_reply_text(text).strip()
    if not clean:
        return ""

    # RTF occasionally arrives from copied mathematical material. Decode its
    # Unicode escapes and discard presentation-only control words first.
    clean = re.sub(
        r"\\u(-?\d+)\??",
        lambda match: chr(int(match.group(1)) if int(match.group(1)) >= 0 else int(match.group(1)) + 65_536),
        clean,
    )
    clean = clean.replace("\\par", " ").replace("\\line", " ")
    clean = re.sub(r"\\(?:rtf\d+|ansi|deff\d+|pard|plain|b|i|ul|fs\d+|f\d+|cf\d+)\b", "", clean)

    # Resolve innermost grouped LaTex structures first, allowing nested
    # expressions such as \\frac{1}{\\frac{2}{3}} to become intelligible.
    fraction = re.compile(r"\\(?:d?frac)\s*\{([^{}]+)\}\s*\{([^{}]+)\}")
    square_root = re.compile(r"\\sqrt\s*\{([^{}]+)\}")
    text_group = re.compile(r"\\(?:text|mathrm|mathbf|operatorname)\s*\{([^{}]+)\}")
    while True:
        updated = fraction.sub(lambda match: f" {match.group(1)} over {match.group(2)} ", clean)
        updated = square_root.sub(lambda match: f" square root of {match.group(1)} ", updated)
        updated = text_group.sub(lambda match: f" {match.group(1)} ", updated)
        if updated == clean:
            break
        clean = updated

    # A superscript circle is the standard LaTex degree marker. Resolve it
    # before generic exponent handling so 90^\\circ is spoken as 90 degrees.
    clean = clean.replace("^\\circ", " degrees ").replace("^{\\circ}", " degrees ")

    # LaTex operators and delimiters become their natural spoken equivalent.
    replacements = {
        "\\times": " times ", "\\cdot": " times ", "\\div": " divided by ",
        "\\pm": " plus or minus ", "\\mp": " minus or plus ",
        "\\leq": " less than or equal to ", "\\geq": " greater than or equal to ",
        "\\neq": " not equal to ", "\\approx": " approximately ",
        "\\infty": " infinity ", "\\sum": " sum of ", "\\prod": " product of ",
        "\\circ": " degrees ", "\\degree": " degrees ",
        "\\int": " integral of ", "\\lim": " limit of ", "\\partial": " partial ",
        "\\nabla": " del ", "\\Delta": " delta ", "\\therefore": " therefore ",
        "\\because": " because ", "\\in": " is in ", "\\notin": " is not in ",
        "\\subset": " is a subset of ", "\\cup": " union ", "\\cap": " intersection ",
        "\\rightarrow": " approaches ", "\\to": " approaches ",
        "\\pi": " pi ", "\\theta": " theta ", "\\alpha": " alpha ",
        "\\beta": " beta ", "\\gamma": " gamma ", "\\delta": " delta ",
        "\\lambda": " lambda ", "\\mu": " mu ", "\\sigma": " sigma ",
        "\\phi": " phi ", "\\omega": " omega ",
        "\\sin": " sine ", "\\cos": " cosine ", "\\tan": " tangent ",
        "\\sec": " secant ", "\\csc": " cosecant ", "\\cot": " cotangent ",
        "\\arcsin": " arc sine ", "\\arccos": " arc cosine ",
        "\\arctan": " arc tangent ", "\\ln": " natural log ",
        "\\log": " log ", "\\exp": " e to the power of ",
        "\\left": "", "\\right": "", "\\,": " ", "\\ ": " ",
        "\\(": "", "\\)": "", "\\[": "", "\\]": "",
        "×": " times ", "÷": " divided by ", "±": " plus or minus ",
        "≤": " less than or equal to ", "≥": " greater than or equal to ",
        "≠": " not equal to ", "≈": " approximately ", "∞": " infinity ",
        "√": " square root of ", "°": " degrees ", "π": " pi ", "θ": " theta ",
        "α": " alpha ", "β": " beta ", "γ": " gamma ", "δ": " delta ",
        "λ": " lambda ", "μ": " mu ", "σ": " sigma ", "φ": " phi ", "ω": " omega ",
        "=": " equals ", "+": " plus ", "−": " minus ",
        "²": " squared ", "³": " cubed ", "⁴": " to the fourth power ",
        "⁵": " to the fifth power ", "⁶": " to the sixth power ",
    }
    for source, spoken in replacements.items():
        clean = clean.replace(source, spoken)

    clean = re.sub(r"\^\{([^{}]+)\}", r" to the power of \1 ", clean)
    clean = re.sub(r"\^\s*([A-Za-z0-9]+)", r" to the power of \1 ", clean)
    clean = re.sub(r"_\{([^{}]+)\}", r" subscript \1 ", clean)
    clean = re.sub(r"_\s*([A-Za-z0-9]+)", r" subscript \1 ", clean)

    # Remove Markdown and residual formatting only after mathematical asterisks
    # are converted, so `3 * 4` is still spoken correctly.
    clean = re.sub(r"```[A-Za-z]*", "", clean)
    clean = clean.replace("**", "").replace("`", "")
    clean = re.sub(r"(?m)^\s*[-*]\s+", "", clean)
    clean = clean.replace("*", " times ")
    clean = clean.replace("{", " ").replace("}", " ")
    clean = re.sub(r"\\[A-Za-z]+", "", clean)
    functions = {
        "arcsin": "arc sine", "arccos": "arc cosine", "arctan": "arc tangent",
        "sin": "sine", "cos": "cosine", "tan": "tangent", "sec": "secant",
        "csc": "cosecant", "cot": "cotangent", "ln": "natural log",
    }
    for symbol, spoken in functions.items():
        clean = re.sub(rf"\b{symbol}\b", spoken, clean, flags=re.IGNORECASE)
    return re.sub(r"\s+", " ", clean).strip()


def _extract_reply_text(text: str) -> str:
    """Use the actual reply field if a provider ever sends a JSON wrapper."""

    try:
        payload = json.loads(text)
    except json.JSONDecodeError:
        return text
    if isinstance(payload, dict):
        for key in ("reply", "message", "content", "text"):
            value = payload.get(key)
            if isinstance(value, str):
                return value
    return text


def _get_engine() -> Kokoro:
    global _engine
    if _engine is None:
        _ensure_model_files()
        _engine = Kokoro(str(MODEL_PATH), str(VOICES_PATH))
    return _engine


def _ensure_model_files() -> None:
    MODEL_DIRECTORY.mkdir(parents=True, exist_ok=True)
    for path, url in MODEL_FILES.items():
        if not path.exists():
            urlretrieve(url, path)
