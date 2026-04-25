# Stem iOS

SwiftUI, iOS 17+, async/await, zero external dependencies. Live app calling `https://api.stem.md`.

## Terminology

- **Stem** — a topic collection (e.g. "Byzantine Architecture")
- **Artifact** — a link, note, or resource inside a stem (was "find" pre-April 2026)
- **Node** — an organizational sub-topic within a stem (supports 3-level nesting)
- **Branch** — a collaborative stem with co-curators
- "Trail" is marketing only, never in the app UI.

## Stack

- SwiftUI, iOS 17+ deployment target. Tested through iOS 26.x.
- Auth: Sign in with Apple + Google OAuth via web. Bearer token in Keychain (shared group `group.md.stem` for the Share Extension).
- Fonts: DM Sans (body), DM Serif Display (headings), DM Mono (metadata).
- Project generator: **XcodeGen** (`project.yml`). `Stem.xcodeproj` is gitignored. Run `xcodegen` after adding/renaming/removing source files.

## Stem detail UI pattern (April 2026 redesign)

The stem detail screen uses an **overview + focus** pattern, not push navigation or inline recursive expansion:

- **Overview:** the whole "plant" is always on screen. Compact rows along a left rail (2pt forest line with junction dots). Top-level nodes and loose artifacts. Titles and metadata only, no article bodies.
- **Focus:** tapping a row pulls it closer. A large card animates forward via `matchedGeometryEffect`, the overview behind dims and blurs but stays visible at the edges. Swipe down, tap the backdrop, or tap the × to return.
- **Focus transfer:** if the focused view is a node, tapping one of its children transfers focus rather than pushing a new screen. The overview behind never changes — the root stem is always the home base.
- **Artifact focus:** large card with OG image, title, domain, description, user's note, and an "Open link" button that fires `SFSafariViewController` in a full-screen cover.
- **Node focus:** large card with emoji, title, description, and a mini-stem showing the node's direct children.

Key files:
- `Stem/Views/Stems/StemDetailView.swift` — container, header, state (focused target), dim backdrop, focus overlay.
- `Stem/Views/Stems/StemOverviewView.swift` — the left-rail list of nodes and loose artifacts.
- `Stem/Views/Stems/StemFocusLayer.swift` — the focused card (artifact or node).
- `Stem/Views/Stems/StemDetailViewModel.swift` — loads stem detail, exposes node-tree computed properties (rootNodes, rootArtifacts, childNodes(of:), artifacts(in:), etc).

## Design system

- Colors live in `Stem/DesignSystem/StemColors.swift`. Key tokens: `forest` (primary accent), `paper` (page background), `surface` (card background), `ink`/`inkMid`/`inkLight` (text), `leaf`/`leafBorder` (node card tint).
- Category tints per-stem in `CategoryColors.swift`.
- Use `DS.Spacing.*` and `DS.Radius.*` rather than magic numbers.

## API

- `APIClient` in `Stem/Services/APIClient.swift` — Observable singleton, Bearer auth. Calls `https://api.stem.md`.
- Artifact endpoints: `/stems/:id/artifacts` (POST/PUT/DELETE).
- Node endpoints: `/stems/:id/nodes` + `/stems/:id/nodes/:nodeId/artifacts`.
- `GET /stems/:id` returns `{ stem, artifacts, nodes, artifactNodes, followerCount, isFollowing, isOwner, categories }`.

## Known gaps (App Store submission blockers)

- `PrivacyInfo.xcprivacy` missing (required iOS 17.4+).
- `UILaunchScreen` dict in Info.plist is empty — needs a launch screen.
- `AppIcon.appiconset` only has a single PNG. Verify all required sizes.
- README claims push notifications; code doesn't exist. Either ship APNs or stop advertising it.
- `stem://` URL scheme is registered but has no `onOpenURL` handler.
- Node CRUD exists in the API client but has no UI yet — users can see nodes in stems but not create or edit them from iOS.
- Artifact reader (`/reader` + `/frame-check` endpoints on stems-api) is not used; artifact links open via `SFSafariViewController`. Inline reader is a future enhancement.

## Brand voice

- Avoid em-dashes (LLM tell).
- Avoid "obsessions" (negative).
- Max 1x "rabbit holes" per page.
- Warm, personal, conversational.
- No periods on short copy lines.
