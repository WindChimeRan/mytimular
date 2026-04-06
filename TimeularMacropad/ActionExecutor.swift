import AppKit
import Carbon.HIToolbox

/// Executes side actions: launch apps, send keystrokes, run shell commands, open URLs.
enum ActionExecutor {
    static func execute(_ action: SideAction) {
        switch action.type {
        case .launchApp:
            launchApp(action)
        case .keystroke:
            sendKeystroke(action)
        case .shell:
            runShell(action)
        case .url:
            openURL(action)
        }
    }

    // MARK: - Launch App

    private static func launchApp(_ action: SideAction) {
        guard let path = action.appPath else { return }
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.openApplication(
            at: url,
            configuration: NSWorkspace.OpenConfiguration()
        )
    }

    // MARK: - Keystroke via CGEvent

    private static func sendKeystroke(_ action: SideAction) {
        guard let combo = action.keyCombo else { return }
        guard let keyCode = keyCodeForString(combo.key) else {
            print("ActionExecutor: unknown key '\(combo.key)'")
            return
        }

        var flags = CGEventFlags()
        if combo.command { flags.insert(.maskCommand) }
        if combo.shift { flags.insert(.maskShift) }
        if combo.option { flags.insert(.maskAlternate) }
        if combo.control { flags.insert(.maskControl) }

        let source = CGEventSource(stateID: .hidSystemState)
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true) {
            keyDown.flags = flags
            keyDown.post(tap: .cghidEventTap)
        }
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) {
            keyUp.flags = flags
            keyUp.post(tap: .cghidEventTap)
        }
    }

    // MARK: - Shell Command

    private static func runShell(_ action: SideAction) {
        guard let cmd = action.shellCommand, !cmd.isEmpty else { return }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", cmd]
        process.standardOutput = nil
        process.standardError = nil
        try? process.run()
    }

    // MARK: - Open URL

    private static func openURL(_ action: SideAction) {
        guard let str = action.urlString, let url = URL(string: str) else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Key code mapping

    private static func keyCodeForString(_ key: String) -> CGKeyCode? {
        let map: [String: CGKeyCode] = [
            "a": 0x00, "s": 0x01, "d": 0x02, "f": 0x03, "h": 0x04,
            "g": 0x05, "z": 0x06, "x": 0x07, "c": 0x08, "v": 0x09,
            "b": 0x0B, "q": 0x0C, "w": 0x0D, "e": 0x0E, "r": 0x0F,
            "y": 0x10, "t": 0x11, "1": 0x12, "2": 0x13, "3": 0x14,
            "4": 0x15, "6": 0x16, "5": 0x17, "7": 0x1A, "8": 0x1C,
            "9": 0x19, "0": 0x1D, "o": 0x1F, "u": 0x20, "i": 0x22,
            "p": 0x23, "l": 0x25, "j": 0x26, "k": 0x28, "n": 0x2D,
            "m": 0x2E,
            "return": 0x24, "tab": 0x30, "space": 0x31, "delete": 0x33,
            "escape": 0x35, "left": 0x7B, "right": 0x7C, "down": 0x7D,
            "up": 0x7E,
            "f1": 0x7A, "f2": 0x78, "f3": 0x63, "f4": 0x76,
            "f5": 0x60, "f6": 0x61, "f7": 0x62, "f8": 0x64,
            "f9": 0x65, "f10": 0x6D, "f11": 0x67, "f12": 0x6F,
            "-": 0x1B, "=": 0x18, "[": 0x21, "]": 0x1E,
            ";": 0x29, "'": 0x27, ",": 0x2B, ".": 0x2F, "/": 0x2C,
            "\\": 0x2A, "`": 0x32,
        ]
        return map[key.lowercased()]
    }
}
