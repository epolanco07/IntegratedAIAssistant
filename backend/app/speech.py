"""Fully local Kokoro text-to-speech for Arthur."""

from __future__ import annotations

from io import BytesIO
from pathlib import Path
from threading import Lock
from urllib.request import urlretrieve
import wave

import numpy as np
from kokoro_onnx import Kokoro


BACKEND_DIRECTORY = Path(__file__).resolve().parents[1]
MODEL_DIRECTORY = BACKEND_DIRECTORY / ".models" / "kokoro"
MODEL_PATH = MODEL_DIRECTORY / "kokoro-v1.0.onnx"
VOICES_PATH = MODEL_DIRECTORY / "voices-v1.0.bin"

# Kokoro's British male George preset is a formal, polished, mid-pitch voice.
ARTHUR_VOICE = "bm_george"
ARTHUR_LANGUAGE = "en-gb"
ARTHUR_SPEED = 0.96

MODEL_FILES = {
    MODEL_PATH: "https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.1/kokoro-v1.0.onnx",
    VOICES_PATH: "https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.1/voices-v1.0.bin",
}

_engine: Kokoro | None = None
_engine_lock = Lock()


def synthesize_speech(text: str) -> bytes:
    """Return local Kokoro speech as a standard WAV payload."""

    clean_text = text.strip()
    if not clean_text:
        raise ValueError("Speech text cannot be empty.")

    with _engine_lock:
        engine = _get_engine()
        samples, sample_rate = engine.create(
            clean_text,
            voice=ARTHUR_VOICE,
            speed=ARTHUR_SPEED,
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
