import os
from pathlib import Path

from dotenv import load_dotenv
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build


load_dotenv()

# This scope allows Arthur to view and create Calendar events.
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
) -> dict:
    service = get_calendar_service()

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

    return service.events().insert(
        calendarId="primary",
        body=event,
        sendUpdates="none",
    ).execute()