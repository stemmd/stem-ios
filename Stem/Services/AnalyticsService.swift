import Foundation

@MainActor
final class Analytics {
    static let shared = Analytics()

    private let deviceId: String
    private let sessionId = UUID().uuidString
    private var queue: [Event] = []
    private var flushTask: Task<Void, Never>?

    private struct Event: Encodable {
        let name: String
        let properties: [String: String]?
        let timestamp: String
        let deviceId: String
        let sessionId: String
    }

    private init() {
        if let existing = UserDefaults.standard.string(forKey: "stem_device_id") {
            deviceId = existing
        } else {
            let id = UUID().uuidString
            UserDefaults.standard.set(id, forKey: "stem_device_id")
            deviceId = id
        }
        startPeriodicFlush()
    }

    nonisolated static func track(_ name: String, _ properties: [String: String]? = nil) {
        Task { @MainActor in
            shared.enqueue(name, properties)
        }
    }

    private func enqueue(_ name: String, _ properties: [String: String]?) {
        let event = Event(
            name: name,
            properties: properties,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            deviceId: deviceId,
            sessionId: sessionId
        )
        queue.append(event)
        if queue.count >= 50 {
            flush()
        }
    }

    func flush() {
        guard !queue.isEmpty else { return }
        let batch = queue
        queue = []

        Task {
            do {
                var request = URLRequest(url: URL(string: "https://api.stem.md/events")!)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(["events": batch])
                _ = try await URLSession.shared.data(for: request)
            } catch {
                // Re-queue on failure (drop if queue gets too large)
                if queue.count < 200 {
                    queue.insert(contentsOf: batch, at: 0)
                }
            }
        }
    }

    private func startPeriodicFlush() {
        flushTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                flush()
            }
        }
    }
}
