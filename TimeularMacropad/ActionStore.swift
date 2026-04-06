import Foundation
import Combine

/// Persists side action configurations to disk.
final class ActionStore: ObservableObject {
    @Published var actions: [Int: SideAction] = [:]

    private let storageURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("TimeularMacropad", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        storageURL = dir.appendingPathComponent("actions.json")

        load()

        // Fill in empty defaults for unconfigured sides
        for side in 1...8 where actions[side] == nil {
            actions[side] = .empty(side: side)
        }
    }

    func action(for side: Int) -> SideAction {
        actions[side] ?? .empty(side: side)
    }

    func update(_ action: SideAction) {
        actions[action.id] = action
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            let list = try JSONDecoder().decode([SideAction].self, from: data)
            for a in list {
                actions[a.id] = a
            }
        } catch {
            print("ActionStore: failed to load: \(error)")
        }
    }

    private func save() {
        do {
            let list = actions.values.sorted { $0.id < $1.id }
            let data = try JSONEncoder().encode(list)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("ActionStore: failed to save: \(error)")
        }
    }
}
