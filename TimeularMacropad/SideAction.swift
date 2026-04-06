import Foundation

enum ActionType: String, Codable, CaseIterable, Identifiable {
    case launchApp = "app"
    case keystroke = "keystroke"
    case shell = "shell"
    case url = "url"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .launchApp: return "Launch App"
        case .keystroke: return "Keyboard Shortcut"
        case .shell: return "Shell Command"
        case .url: return "Open URL"
        }
    }

    var icon: String {
        switch self {
        case .launchApp: return "app.badge"
        case .keystroke: return "keyboard"
        case .shell: return "terminal"
        case .url: return "link"
        }
    }
}

struct KeyCombo: Codable, Equatable {
    var key: String
    var command: Bool = false
    var shift: Bool = false
    var option: Bool = false
    var control: Bool = false

    var displayString: String {
        var parts: [String] = []
        if control { parts.append("⌃") }
        if option { parts.append("⌥") }
        if shift { parts.append("⇧") }
        if command { parts.append("⌘") }
        parts.append(key.uppercased())
        return parts.joined()
    }
}

struct SideAction: Codable, Identifiable, Equatable {
    var id: Int  // side number 1-8
    var type: ActionType
    var label: String
    var appPath: String?
    var keyCombo: KeyCombo?
    var shellCommand: String?
    var urlString: String?

    var summary: String {
        switch type {
        case .launchApp:
            if let path = appPath {
                let name = (path as NSString).lastPathComponent.replacingOccurrences(of: ".app", with: "")
                return name
            }
            return "No app selected"
        case .keystroke:
            return keyCombo?.displayString ?? "No shortcut set"
        case .shell:
            return shellCommand ?? "No command set"
        case .url:
            return urlString ?? "No URL set"
        }
    }

    static func empty(side: Int) -> SideAction {
        SideAction(id: side, type: .shell, label: "Side \(side)")
    }
}
