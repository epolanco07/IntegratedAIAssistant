"""HTTP entry point for Arthur's local backend.

Run from the ``backend`` directory with:
    .venv/bin/python -m uvicorn app.main:app --reload
"""

import os
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

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

from app.agents.arthur import arthur  # noqa: E402
from app.tools.memory import record_conversation_message  # noqa: E402


app = FastAPI(
    title="Arthur Backend",
    version="0.1.0",
    description="A local API that lets the macOS app send messages to Arthur.",
)


class ChatRequest(BaseModel):
    """The message sent from the macOS app to Arthur."""

    message: str = Field(min_length=1, max_length=10_000)
    conversation_id: str = Field(min_length=1, max_length=128)


class ChatResponse(BaseModel):
    """Arthur's text reply returned to the macOS app."""

    reply: str


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
        timezone_name = os.getenv("ARTHUR_TIMEZONE", "America/Chicago")
        now = datetime.now(ZoneInfo(timezone_name))
        temporal_context = (
            "SYSTEM DATE/TIME CONTEXT (authoritative): "
            f"It is {now.strftime('%A, %B %-d, %Y at %-I:%M %p %Z')}. "
            f"Timezone: {timezone_name}. Interpret relative dates such as "
            "today, tomorrow, and next week from this timestamp.\n\n"
        )
        record_conversation_message(request.conversation_id, "user", request.message)
        result = await Runner.run(
            arthur,
            temporal_context + "User message: " + request.message,
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

    reply = str(result.final_output)
    record_conversation_message(request.conversation_id, "assistant", reply)
    return ChatResponse(reply=reply)
