import os
from datetime import datetime, timezone as datetime_timezone
from email.utils import parseaddr
from pathlib import Path
from typing import Sequence

from dotenv import load_dotenv
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build


load_dotenv()

# This scope allows Arthur to view, create, invite attendees to, and delete
# events in the user's primary calendar.
SCOPES = ["https://www.googleapis.com/auth/calendar"]

TOKEN_PATH = Path(os.environ["GOOGLE_TOKEN_PATH"])

GOOGLE_CLIENT_CONFIG = {
    "installed": {
        "client_id": os.environ["GOOGLE_CLIENT_ID"],
        "client_secret": os.environ["GOOGLE_CLIENT_SECRET"],
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url": (
            "https://www.googleapis.com/oauth2/v1/certs"
        ),
        "redirect_uris": ["http://localhost"],
    }
}


def get_calendar_service():
    credentials = None

    # Reuse the saved authorization if it exists.
    if TOKEN_PATH.exists():
        credentials = Credentials.from_authorized_user_file(
            TOKEN_PATH,
            SCOPES,
        )

    # Refresh an expired access token automatically.
    if credentials and credentials.expired and credentials.refresh_token:
        credentials.refresh(Request())

    # First-time authorization: opens Google in your browser.
    if not credentials or not credentials.valid:
        flow = InstalledAppFlow.from_client_config(
            GOOGLE_CLIENT_CONFIG,
            SCOPES,
        )
        credentials = flow.run_local_server(port=0)

        TOKEN_PATH.parent.mkdir(parents=True, exist_ok=True)
        TOKEN_PATH.write_text(credentials.to_json())

    return build("calendar", "v3", credentials=credentials)


def create_calendar_event(
    title: str,
    starts_at: str,
    ends_at: str,
    timezone: str = "America/Chicago",
    attendee_emails: Sequence[str] | None = None,
) -> dict:
    service = get_calendar_service()

    attendee_emails = _validated_emails(attendee_emails or [])

    event = {
        "summary": title,
        "start": {
            "dateTime": starts_at,
            "timeZone": timezone,
        },
        "end": {
            "dateTime": ends_at,
            "timeZone": timezone,
        },
    }
    if attendee_emails:
        event["attendees"] = [{"email": email} for email in attendee_emails]

    return service.events().insert(
        calendarId="primary",
        body=event,
        # Calendar sends the invitation emails only when guests were supplied.
        sendUpdates="all" if attendee_emails else "none",
    ).execute()


def find_calendar_events(
    query: str = "",
    time_min: str | None = None,
    time_max: str | None = None,
    max_results: int = 10,
) -> list[dict]:
    """Return upcoming matching events with stable IDs for confirmation."""

    service = get_calendar_service()
    parameters: dict[str, object] = {
        "calendarId": "primary",
        "singleEvents": True,
        "orderBy": "startTime",
        "maxResults": min(max(max_results, 1), 25),
        "timeMin": time_min or datetime.now(datetime_timezone.utc).isoformat(),
    }
    if query.strip():
        parameters["q"] = query.strip()
    if time_max:
        parameters["timeMax"] = time_max

    response = service.events().list(**parameters).execute()
    return [
        {
            "id": event["id"],
            "title": event.get("summary", "Untitled event"),
            "starts_at": event.get("start", {}).get("dateTime", event.get("start", {}).get("date")),
            "ends_at": event.get("end", {}).get("dateTime", event.get("end", {}).get("date")),
            "attendees": [guest.get("email") for guest in event.get("attendees", [])],
        }
        for event in response.get("items", [])
    ]


def delete_calendar_event(event_id: str, notify_attendees: bool = True) -> None:
    """Permanently remove a specific Calendar event after confirmation."""

    service = get_calendar_service()
    service.events().delete(
        calendarId="primary",
        eventId=event_id,
        sendUpdates="all" if notify_attendees else "none",
    ).execute()


def _validated_emails(emails: Sequence[str]) -> list[str]:
    valid: list[str] = []
    for email in emails:
        _, parsed = parseaddr(email.strip())
        if not parsed or "@" not in parsed:
            raise ValueError(f"Invalid attendee email address: {email}")
        if parsed not in valid:
            valid.append(parsed)
    return valid
