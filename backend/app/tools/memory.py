"""Durable local conversation memory for Arthur.

The OpenAI Agents session database keeps active-chat context. This module keeps
an independent, searchable record of every user and assistant message so Arthur
can retrieve relevant details after a session is no longer in model context.
"""

import re
import sqlite3
from datetime import datetime, timezone
from pathlib import Path


MEMORY_DATABASE = Path(__file__).resolve().parents[2] / ".arthur_memory.sqlite3"


def record_conversation_message(conversation_id: str, role: str, text: str) -> None:
    """Append one user or assistant message to local durable memory."""

    message = text.strip()
    if not message:
        return

    with _connection() as connection:
        connection.execute(
            """
            INSERT INTO conversation_memory (conversation_id, role, text, created_at)
            VALUES (?, ?, ?, ?)
            """,
            (conversation_id, role, message, datetime.now(timezone.utc).isoformat()),
        )


def search_conversation_memory(query: str, limit: int = 8) -> list[dict[str, str]]:
    """Search prior Arthur conversations by meaningful words in newest-first order."""

    terms = list(dict.fromkeys(re.findall(r"[A-Za-z0-9_'-]{3,}", query.lower())))[:8]
    if not terms:
        return []

    where_clause = " OR ".join("LOWER(text) LIKE ?" for _ in terms)
    parameters = [f"%{term}%" for term in terms] + [min(max(limit, 1), 20)]
    with _connection() as connection:
        rows = connection.execute(
            f"""
            SELECT conversation_id, role, text, created_at
            FROM conversation_memory
            WHERE {where_clause}
            ORDER BY created_at DESC
            LIMIT ?
            """,
            parameters,
        ).fetchall()

    return [dict(row) for row in rows]


def _connection() -> sqlite3.Connection:
    connection = sqlite3.connect(MEMORY_DATABASE, timeout=5)
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA journal_mode=WAL")
    connection.execute(
        """
        CREATE TABLE IF NOT EXISTS conversation_memory (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            conversation_id TEXT NOT NULL,
            role TEXT NOT NULL CHECK(role IN ('user', 'assistant')),
            text TEXT NOT NULL,
            created_at TEXT NOT NULL
        )
        """
    )
    connection.execute(
        """
        CREATE INDEX IF NOT EXISTS conversation_memory_created_at
        ON conversation_memory (created_at DESC)
        """
    )
    return connection
