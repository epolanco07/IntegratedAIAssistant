"""HTTP entry point for Arthur's local backend.

Run from the ``backend`` directory with:
    .venv/bin/python -m uvicorn app.main:app --reload
"""

import os
import re
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field


# Load secrets before importing Arthur: his Calendar tool reads its configuration
# when the agent module is imported.
BACKEND_DIRECTORY = Path(__file__).resolve().parents[1]
load_dotenv(BACKEND_DIRECTORY / ".env")

# Accept the earlier local variable name too, while providing the exact name
# expected by the OpenAI SDK. New installs should use OPENAI_API_KEY.
if not os.getenv("OPENAI_API_KEY") and os.getenv("OPEN_API_KEY"):
    os.environ["OPENAI_API_KEY"] = os.environ["OPEN_API_KEY"]

from agents import Runner, SQLiteSession  # noqa: E402

from app.agents.arthur import ArthurContext, arthur  # noqa: E402
from app.tools.memory import record_conversation_message  # noqa: E402


app = FastAPI(
    title="Arthur Backend",
    version="0.1.0",
    description="A local API that lets the macOS app send messages to Arthur.",
)


def _concise_calendar_confirmation(reply: str) -> str:
    """Enforce Arthur's one-line Calendar confirmation contract.

    This catches the old checklist-shaped response if the model produces it,
    before that text reaches the desktop app. Regular conversation is left
    untouched.
    """

    if not re.search(r"(?:^|\n)\s*(?:to\s+confirm|\*\*title:\*\*)", reply, re.I):
        return reply

    fields: dict[str, str] = {}
    for line in reply.splitlines():
        clean = line.strip().lstrip("- ").replace("**", "")
        label, separator, value = clean.partition(":")
        if separator and label.lower() in {"title", "date", "time"}:
            fields[label.lower()] = value.strip()

    title = fields.get("title")
    date = fields.get("date")
    time = fields.get("time")
    if not title:
        return reply

    # "Saturday, November 28, 2026" becomes the compact, spoken-friendly
    # "Saturday the 28th of November". A date the user already phrased
    # naturally is preserved rather than expanded.
    if date:
        match = re.fullmatch(r"([A-Za-z]+),\s*([A-Za-z]+)\s+(\d{1,2})(?:,\s*\d{4})?", date)
        if match:
            weekday, month, day = match.groups()
            suffix = "th" if 10 < int(day) % 100 < 14 else {1: "st", 2: "nd", 3: "rd"}.get(int(day) % 10, "th")
            date = f"{weekday} the {day}{suffix} of {month}"

    details = " ".join(part for part in [date, time] if part)
    return f"Add {title}{' ' + details if details else ''}?"


class ChatRequest(BaseModel):
    """The message sent from the macOS app to Arthur."""

    message: str = Field(min_length=1, max_length=10_000)
    conversation_id: str = Field(min_length=1, max_length=128)
    timezone: str | None = Field(default=None, max_length=128)


class ChatResponse(BaseModel):
    """Arthur's text reply returned to the macOS app."""

    reply: str
    commands: list[dict[str, str]] = []


@app.get("/health")
async def health() -> dict[str, str]:
    """A lightweight check that the local backend is running."""

    return {"status": "ok"}


@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest) -> ChatResponse:
    """Run one Arthur turn for a message received from the desktop app."""

    if not os.getenv("OPENAI_API_KEY"):
        raise HTTPException(
            status_code=503,
            detail="OPENAI_API_KEY is missing from backend/.env.",
        )

    try:
        # The session keeps the conversation's previous turns. That matters for
        # workflows such as: Arthur proposes a calendar event, then the user
        # confirms it in their next message.
        session = SQLiteSession(
            request.conversation_id,
            BACKEND_DIRECTORY / ".agent_sessions.sqlite3",
        )
        timezone_name = request.timezone or os.getenv("ARTHUR_TIMEZONE", "America/Chicago")
        try:
            timezone = ZoneInfo(timezone_name)
        except ZoneInfoNotFoundError:
            timezone_name = os.getenv("ARTHUR_TIMEZONE", "America/Chicago")
            timezone = ZoneInfo(timezone_name)
        now = datetime.now(timezone)
        agent_context = ArthurContext(
            current_datetime=now.strftime("%A, %B %-d, %Y at %-I:%M %p %Z"),
            timezone=timezone_name,
        )
        record_conversation_message(request.conversation_id, "user", request.message)
        result = await Runner.run(
            arthur,
            request.message,
            context=agent_context,
            session=session,
        )
    except Exception as error:
        # Keep provider details out of the response while leaving them in the
        # terminal log for local debugging.
        print(f"Arthur request failed: {error}")
        raise HTTPException(
            status_code=500,
            detail="Arthur could not process that request.",
        ) from error

    reply = _concise_calendar_confirmation(str(result.final_output))
    record_conversation_message(request.conversation_id, "assistant", reply)
    return ChatResponse(reply=reply, commands=agent_context.app_commands)
