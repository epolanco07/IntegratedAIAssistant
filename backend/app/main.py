"""HTTP entry point for Arthur's local backend.

Run from the ``backend`` directory with:
    .venv/bin/python -m uvicorn app.main:app --reload
"""

import os
from pathlib import Path

from agents import Runner, SQLiteSession
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field


# Load secrets before importing Arthur: his Calendar tool reads its configuration
# when the agent module is imported.
BACKEND_DIRECTORY = Path(__file__).resolve().parents[1]
load_dotenv(BACKEND_DIRECTORY / ".env")

from app.agents.arthur import arthur  # noqa: E402


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
        result = await Runner.run(arthur, request.message, session=session)
    except Exception as error:
        # Keep provider details out of the response while leaving them in the
        # terminal log for local debugging.
        print(f"Arthur request failed: {error}")
        raise HTTPException(
            status_code=500,
            detail="Arthur could not process that request.",
        ) from error

    return ChatResponse(reply=str(result.final_output))
