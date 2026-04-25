import Foundation

@MainActor @Observable
final class StemDetailViewModel {
    var stem: Stem?
    var artifacts: [Artifact] = []
    var nodes: [Node] = []
    var artifactNodes: [ArtifactNode] = []
    var followerCount = 0
    var isFollowing = false
    var isOwner = false
    var categories: [String] = []
    var loading = true
    var error: String?

    private let stemId: String

    init(stemId: String) {
        self.stemId = stemId
    }

    func load() async {
        loading = true
        error = nil
        do {
            let res = try await APIClient.shared.getStemDetail(id: stemId)
            stem = res.stem
            artifacts = res.artifacts
            nodes = res.nodes ?? []
            artifactNodes = res.artifactNodes ?? []
            followerCount = res.followerCount
            isFollowing = res.isFollowing
            isOwner = res.isOwner
            categories = res.categories ?? []
        } catch {
            self.error = "Couldn't load this stem"
        }
        loading = false
    }

    private var isTogglingFollow = false

    func toggleFollow() async {
        guard !isTogglingFollow else { return }
        isTogglingFollow = true
        defer { isTogglingFollow = false }
        let wasFollowing = isFollowing
        isFollowing.toggle()
        followerCount += isFollowing ? 1 : -1
        do {
            if isFollowing {
                _ = try await APIClient.shared.followStem(id: stemId)
            } else {
                _ = try await APIClient.shared.unfollowStem(id: stemId)
            }
        } catch {
            isFollowing = wasFollowing
            followerCount += wasFollowing ? 1 : -1
        }
    }

    // MARK: - Node tree

    /// Top-level nodes (no parent).
    var rootNodes: [Node] {
        nodes
            .filter { $0.parentId == nil }
            .sorted { $0.position < $1.position }
    }

    /// Artifacts that are not assigned to any node.
    var rootArtifacts: [Artifact] {
        let assignedIds = Set(artifactNodes.map { $0.artifactId })
        return artifacts.filter { !assignedIds.contains($0.id) }
    }

    /// Direct child nodes of a given node.
    func childNodes(of nodeId: String) -> [Node] {
        nodes
            .filter { $0.parentId == nodeId }
            .sorted { $0.position < $1.position }
    }

    /// Artifacts directly assigned to a given node, in position order.
    func artifacts(in nodeId: String) -> [Artifact] {
        let ordered = artifactNodes
            .filter { $0.nodeId == nodeId }
            .sorted { $0.position < $1.position }
        return ordered.compactMap { link in artifacts.first { $0.id == link.artifactId } }
    }

    /// Count of direct artifact assignments for a node.
    func artifactCount(in nodeId: String) -> Int {
        artifactNodes.reduce(into: 0) { count, link in
            if link.nodeId == nodeId { count += 1 }
        }
    }

    /// Count of direct sub-nodes of a node.
    func subNodeCount(of nodeId: String) -> Int {
        nodes.reduce(into: 0) { count, node in
            if node.parentId == nodeId { count += 1 }
        }
    }

    func artifact(id: String) -> Artifact? {
        artifacts.first { $0.id == id }
    }

    func node(id: String) -> Node? {
        nodes.first { $0.id == id }
    }
}
