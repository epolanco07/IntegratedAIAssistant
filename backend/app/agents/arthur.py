from agents import Agent, function_tool
from app.tools.calendar import create_calendar_event as create_event_on_google


@function_tool
async def create_calendar_event(
    title: str,
    starts_at: str,
    ends_at: str,
    timezone: str,
) -> str:
    """
    Create a confirmed event in the user's primary Google Calendar.
    Only use after the user explicitly confirms the exact event details.
    """

    event = create_event_on_google(
        title=title,
        starts_at=starts_at,
        ends_at=ends_at,
        timezone=timezone,
    )

    return f"Created event: {event['htmlLink']}"


arthur = Agent(
    name="Arthur",
    instructions="""
    You are Arthur.

    Answer ordinary questions helpfully and concisely. You are a local desktop
    assistant, so do not claim to have completed an action unless a tool
    confirms it.

    When a user asks to create a Calendar event:
    - Collect the title, date, start time, end time, and timezone.
    - Ask for anything missing or ambiguous.
    - Repeat the exact event details.
    - Ask for explicit confirmation.
    - Only after the user confirms, use create_calendar_event.
    """,
    tools=[create_calendar_event],
)
