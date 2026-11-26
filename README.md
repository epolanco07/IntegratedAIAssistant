# Arthur Personal AI Assistant

Native macOS SwiftUI frontend for a future personal assistant. The application currently provides a polished local preview with mock chat responses and native audio abstractions; no AI provider, integration, or remote browser connection is active yet.

## Run

Open `Jarvis/Jarvis.xcodeproj` in Xcode, select the **Jarvis** macOS scheme, and run it. The target uses a synchronized project folder, so Swift files under `Jarvis/` are automatically included.

## Architecture

- `Jarvis/App` owns observable application state and the single app entry point.
- `Jarvis/Views` contains SwiftUI navigation and feature views.
- `Jarvis/Models` holds transport-independent UI data.
- `Jarvis/Services` exposes replaceable protocol boundaries for chat, backend health, voice, integrations, and Keychain storage.
- `Jarvis/Voice` and `Jarvis/Audio` contain native AVFoundation capture/playback building blocks.
- `backend/` and `remote_agent/` are intentionally placeholders. A future FastAPI backend will be the only component that communicates with a remote automation agent.

## Backend boundary

`HTTPBackendService` is ready for a local `/health` endpoint. Replace `MockChatService` at the composition root in `JarvisApp` only after the backend owns authentication, model access, and sensitive action confirmation. Do not store API keys, browser sessions, or SSH keys in the app.

## Verification

```sh
xcodebuild -project Jarvis/Jarvis.xcodeproj -scheme Jarvis -configuration Debug -destination 'platform=macOS' build
```
