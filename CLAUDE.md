# Stem iOS — Update Handover (April 2026)

## What needs to happen

The web app and API have been significantly updated. The iOS app needs to catch up:

1. **"Finds" → "Artifacts" rename** across all models, API calls, and UI text
2. **Node architecture** — stems now have hierarchical sub-topics
3. **Stem detail screen redesign** — organic layout with left-rail trunk
4. **Explore updates** — featured stems, new categories (37 total)

## Current state

- **stems-api** is fully updated: uses "artifacts" terminology, endpoints at `/stems/{id}/artifacts`, and now includes node CRUD endpoints and returns `nodes` + `artifactNodes` in the GET /stems/:id response
- **iOS app** still uses "finds" everywhere and has no node support

## Terminology

- **Stem** — a topic collection (e.g. "Byzantine Architecture")
- **Artifact** — a link, note, or resource inside a stem (formerly "find")
- **Node** — an organizational sub-topic within a stem (supports 3-level nesting)
- **Branch** — a collaborative stem with co-curators

## Architecture

- iOS 17+, SwiftUI, async/await, zero external dependencies
- API base: `https://api.stem.md`
- Auth: Bearer token in Keychain
- Fonts: DM Sans, DM Serif Display, DM Mono

## Rename scope (Find → Artifact)

Every occurrence of "find" needs to become "artifact":

### Models (Stem/Models/Models.swift)
- `struct Find` → `struct Artifact`
- `findCount: Int?` → `artifactCount: Int?` (on Stem)
- CodingKeys: `find_count` → `artifact_count`
- `findId`, `findTitle` → `artifactId`, `artifactTitle` (on StemNotification)
- CodingKeys: `find_id` → `artifact_id`, `find_title` → `artifact_title`
- NotificationType: `.newFind` → `.newArtifact`, `.findApproved` → `.artifactApproved`
- Raw values: `"new_find"` → `"new_artifact"`, `"find_approved"` → `"artifact_approved"`

### API Client (Stem/Services/APIClient.swift)
- `addFind()` → `addArtifact()`
- `deleteFind()` → `deleteArtifact()`
- `updateFindStatus()` → `updateArtifactStatus()`
- `AddFindBody` → `AddArtifactBody`
- `AddFindResponse` → `AddArtifactResponse`
- Endpoint: `/stems/{id}/finds` → `/stems/{id}/artifacts`
- `FeedResponse.finds` → `FeedResponse.artifacts`
- `StemDetailResponse.finds` → `StemDetailResponse.artifacts`

### Components
- Rename file `FindCard.swift` → `ArtifactCard.swift`, struct `FindCard` → `ArtifactCard`
- `FeedGroupCard.swift`: `finds: [Find]` → `artifacts: [Artifact]`
- `StemCard.swift`: update find count display

### Views
- `StemDetailView.swift`: `showAddFind` → `showAddArtifact`, `vm.finds` → `vm.artifacts`, "No finds yet" → "No artifacts yet"
- Rename `AddFindSheet.swift` → `AddArtifactSheet.swift`, "Add find" → "Add artifact"
- `StemDetailViewModel.swift`: `finds: [Find]` → `artifacts: [Artifact]`
- `FeedViewModel.swift`: all finds → artifacts
- `FeedView.swift`: "see finds here" → "see artifacts here"
- `EditStemView.swift`: "all its finds" → "all its artifacts"
- `NotificationsView.swift`: update case handling and display text
- Rename `OnboardingFindView.swift` → `OnboardingArtifactView.swift`
- `OnboardingWelcomeView.swift`: update copy

## New: Node support

### New models to add (Models.swift)
```swift
struct Node: Codable, Identifiable, Hashable {
    let id: String
    let parentId: String?
    let title: String
    let description: String?
    let emoji: String?
    let position: Int
    let stemSide: Int
    let status: String
    let createdBy: String

    enum CodingKeys: String, CodingKey {
        case id, title, description, emoji, position, status
        case parentId = "parent_id"
        case stemSide = "stem_side"
        case createdBy = "created_by"
    }
}

struct ArtifactNode: Codable, Hashable {
    let artifactId: String
    let nodeId: String
    let position: Int

    enum CodingKeys: String, CodingKey {
        case position
        case artifactId = "artifact_id"
        case nodeId = "node_id"
    }
}
```

### StemDetailResponse update
```swift
struct StemDetailResponse: Codable {
    let stem: Stem
    let artifacts: [Artifact]
    let nodes: [Node]
    let artifactNodes: [ArtifactNode]
    let followerCount: Int
    let isFollowing: Bool
    let isOwner: Bool
    let categories: [String]
}
```

### New API methods
```swift
func createNode(stemId: String, title: String, emoji: String?, parentId: String?) async throws -> CreateNodeResponse
func updateNode(stemId: String, nodeId: String, title: String, emoji: String?, description: String?) async throws
func deleteNode(stemId: String, nodeId: String) async throws
func assignArtifactToNode(stemId: String, nodeId: String, artifactId: String) async throws
func removeArtifactFromNode(stemId: String, nodeId: String, artifactId: String) async throws
```

API endpoints:
- `POST   /stems/{id}/nodes` — body: `{ title, emoji?, parent_id? }`
- `PUT    /stems/{id}/nodes/{nodeId}` — body: `{ title, emoji?, description? }`
- `DELETE /stems/{id}/nodes/{nodeId}`
- `POST   /stems/{id}/nodes/{nodeId}/artifacts` — body: `{ artifact_id }`
- `DELETE /stems/{id}/nodes/{nodeId}/artifacts/{artifactId}`

## Stem detail screen redesign

The web uses a central trunk with alternating left/right branches. On mobile (< 680px) it collapses to a **single-column with left rail** — this is the pattern for iOS:

### Layout concept
- Thin vertical green line (2pt, `StemColors.forest`) on the left edge
- Each item (node or artifact) gets an `HStack`: junction dot (10pt circle) + horizontal connector (2pt line, 40pt wide) + card
- Nodes use green-tinted background (`StemColors.leaf`), show emoji + title + artifact count + arrow
- Tapping a node pushes a `NodeDetailView` via NavigationStack
- Artifacts use standard card styling

### New SwiftUI views needed

**`StemOrganicView`** — main layout
- Input: artifacts, nodes, artifactNodes
- Compute: rootNodes, rootArtifacts, childNodesMap, nodeToArtifacts, artifactToNodes (same logic as web)
- Build interleaved list sorted by position
- Render with left rail + connector + card pattern

**`NodeDetailView`** — drill-in for a node
- Shows node emoji, title, description
- Own left-rail layout with node's artifacts
- Sub-node cards push deeper

**`NodeCard`** — compact card for nodes
- Green background, emoji + title + count + chevron

### StemDetailView changes
Replace the current LazyVStack of FindCards (lines 25-46) with StemOrganicView.
Keep the header, toolbar, follow button, etc as-is.

### StemDetailViewModel changes
Add computed properties for node tree:
```swift
var rootNodes: [Node] { nodes.filter { $0.parentId == nil } }
var rootArtifacts: [Artifact] { artifacts.filter { !artifactToNodes.keys.contains($0.id) } }
var childNodesMap: [String: [Node]] { ... }
var nodeToArtifacts: [String: [String]] { ... }
var artifactToNodes: [String: [String]] { ... }
```

## Explore updates

The explore screen needs:
1. Featured stems section at the top (the API `/explore` may need to include featured — check if it does, if not the web's featured stems are queried directly from D1, the API may need a `/explore/featured` endpoint)
2. The categories list needs updating — 12 new categories were added: Archaeology, Computer Science, Culture, Education, Engineering, Environment, Fashion, Finance, Gaming, Law, Medicine, Travel

## Design system reference

Colors (from web CSS variables):
- `--forest: #2D5A3D` — primary accent, trunk, buttons
- `--branch: #4A7A5C` — hover/secondary
- `--leaf: #E8F0EB` (light) / `#1E2A1C` (dark) — node card backgrounds
- `--leaf-border: #c8dece` (light) / `#2A4A30` (dark)
- `--surface: #FFFFFF` (light) / `#262520` (dark) — card backgrounds
- `--paper: #F7F4EF` (light) / `#1C1B18` (dark) — page background
- `--ink: #1C1A17` (light) / `#E8E6E0` (dark) — primary text

## Brand voice reminders
- Avoid em-dashes (LLM tell)
- Avoid "obsessions" (negative connotation)
- Max 1x "rabbit holes" per page
- Warm, personal, conversational
- No periods on short copy lines

## Implementation order
1. Find → Artifact rename (compile and verify before continuing)
2. Add Node/ArtifactNode models
3. Update StemDetailResponse + API client
4. Build StemOrganicView, NodeCard, NodeDetailView
5. Wire into StemDetailView
6. Update explore with new categories
7. Test on device
