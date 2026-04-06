import SwiftUI

struct SideEditView: View {
    @State var action: SideAction
    var onSave: (SideAction) -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Title
            HStack {
                Text("Configure Side \(action.id)")
                    .font(.headline)
                Spacer()
            }

            // Label
            HStack {
                Text("Label")
                    .frame(width: 60, alignment: .trailing)
                TextField("Label", text: $action.label)
                    .textFieldStyle(.roundedBorder)
            }

            // Action type picker
            HStack {
                Text("Action")
                    .frame(width: 60, alignment: .trailing)
                Picker("", selection: $action.type) {
                    ForEach(ActionType.allCases) { type in
                        Label(type.displayName, systemImage: type.icon)
                            .tag(type)
                    }
                }
                .labelsHidden()
            }

            // Type-specific fields
            switch action.type {
            case .launchApp:
                appPicker
            case .keystroke:
                keystrokeEditor
            case .shell:
                shellEditor
            case .url:
                urlEditor
            }

            Spacer()

            // Buttons
            HStack {
                Button("Cancel", role: .cancel) {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    onSave(action)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(minHeight: 280)
    }

    // MARK: - App Picker

    private var appPicker: some View {
        HStack {
            Text("App")
                .frame(width: 60, alignment: .trailing)

            if let path = action.appPath {
                let name = (path as NSString).lastPathComponent
                Label(name, systemImage: "app.fill")
                    .lineLimit(1)
            } else {
                Text("No app selected")
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Choose...") {
                chooseApp()
            }
        }
    }

    private func chooseApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.treatsFilePackagesAsDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            action.appPath = url.path
            if action.label == "Side \(action.id)" {
                action.label = url.deletingPathExtension().lastPathComponent
            }
        }
    }

    // MARK: - Keystroke Editor

    private var keystrokeEditor: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Key")
                    .frame(width: 60, alignment: .trailing)
                TextField("e.g. space, a, f1", text: Binding(
                    get: { action.keyCombo?.key ?? "" },
                    set: { newVal in
                        if action.keyCombo == nil {
                            action.keyCombo = KeyCombo(key: newVal)
                        } else {
                            action.keyCombo?.key = newVal
                        }
                    }
                ))
                .textFieldStyle(.roundedBorder)
            }

            HStack {
                Text("Mods")
                    .frame(width: 60, alignment: .trailing)
                Toggle("⌘", isOn: modBinding(\.command))
                    .toggleStyle(.checkbox)
                Toggle("⇧", isOn: modBinding(\.shift))
                    .toggleStyle(.checkbox)
                Toggle("⌥", isOn: modBinding(\.option))
                    .toggleStyle(.checkbox)
                Toggle("⌃", isOn: modBinding(\.control))
                    .toggleStyle(.checkbox)
                Spacer()
            }

            if let combo = action.keyCombo, !combo.key.isEmpty {
                HStack {
                    Text("")
                        .frame(width: 60)
                    Text("Preview: \(combo.displayString)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
    }

    private func modBinding(_ keyPath: WritableKeyPath<KeyCombo, Bool>) -> Binding<Bool> {
        Binding(
            get: { action.keyCombo?[keyPath: keyPath] ?? false },
            set: { newVal in
                if action.keyCombo == nil {
                    action.keyCombo = KeyCombo(key: "")
                }
                action.keyCombo?[keyPath: keyPath] = newVal
            }
        )
    }

    // MARK: - Shell Editor

    private var shellEditor: some View {
        HStack(alignment: .top) {
            Text("Cmd")
                .frame(width: 60, alignment: .trailing)
            TextEditor(text: Binding(
                get: { action.shellCommand ?? "" },
                set: { action.shellCommand = $0 }
            ))
            .font(.system(.body, design: .monospaced))
            .frame(height: 60)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.secondary.opacity(0.3))
            )
        }
    }

    // MARK: - URL Editor

    private var urlEditor: some View {
        HStack {
            Text("URL")
                .frame(width: 60, alignment: .trailing)
            TextField("https://... or app://...", text: Binding(
                get: { action.urlString ?? "" },
                set: { action.urlString = $0 }
            ))
            .textFieldStyle(.roundedBorder)
        }
    }
}
