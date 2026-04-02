# Stem for iOS

The native iOS app for [Stem](https://stem.md). Curate what you're into.

## Features

- **Feed** -- see finds from people and stems you follow
- **Explore** -- discover stems and people across the community
- **Create** -- start a new stem and add finds from anywhere
- **Share Extension** -- save any link to your stems right from the iOS Share Sheet. Safari, YouTube, Twitter, anywhere.
- **Notifications** -- know when someone follows you, adds to your stems, or approves your finds
- **Push notifications** -- native APNs integration

## Architecture

SwiftUI + async/await targeting iOS 17+. No third-party dependencies.

```
Stem/
  App/            Entry point, tab navigation
  Models/         Codable data models
  Services/       API client, Keychain, push
  Views/          SwiftUI views by feature
ShareExtension/   iOS Share Sheet target
```

The app talks to the same Cloudflare backend as the web app via JSON API endpoints (`/api/v1/*`). Auth uses Bearer tokens stored in the shared Keychain (accessible by both the main app and the Share Extension via App Group).

## Setup

1. Open the project in Xcode 16+
2. Set your development team in Signing & Capabilities
3. Create an App Group (`group.md.stem`) for shared Keychain access between the app and Share Extension
4. Build and run

## Share Extension

The Share Extension is the main reason this app exists. When you tap Share in any iOS app:

1. Stem appears in the share sheet
2. Shows the URL with a stem picker and optional note field
3. One tap to save. Done.

Auth is shared between the main app and the extension via a shared Keychain (App Group), so you only sign in once.

## API

The app consumes `/api/v1/*` endpoints on `stem.md`:

| Endpoint | Method | Description |
|---|---|---|
| `/api/v1/feed` | GET | Paginated feed |
| `/api/v1/stems` | GET/POST | List or create stems |
| `/api/v1/stems/:id` | GET/DELETE | Stem detail or delete |
| `/api/v1/stems/:id/finds` | POST | Add a find |
| `/api/v1/users/:username` | GET | User profile |
| `/api/v1/notifications` | GET/POST | List or mark read |

Auth via `Authorization: Bearer <session_token>` header.

## License

MIT License. See [LICENSE](LICENSE).
