import SwiftUI
import ServiceManagement

struct MenuBarView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @ObservedObject var actionStore: ActionStore
    @State private var editingSide: Int?
    @AppStorage("launchAtLogin") private var launchAtLogin = false

    var body: some View {
        VStack(spacing: 0) {
            if let side = editingSide {
                // Inline edit view — replaces the side list
                SideEditView(
                    action: actionStore.action(for: side),
                    onSave: { updated in
                        actionStore.update(updated)
                        editingSide = nil
                    },
                    onCancel: {
                        editingSide = nil
                    }
                )
            } else {
                header
                Divider()
                sideList
                Divider()
                footer
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            bluetoothManager.onSideChanged = { side in
                let action = actionStore.action(for: side)
                if action.appPath != nil || action.keyCombo != nil
                    || action.shellCommand != nil || action.urlString != nil {
                    ActionExecutor.execute(action)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "octagon.fill")
                .foregroundColor(bluetoothManager.isConnected ? .green : .secondary)
            Text("Timeular Macropad")
                .font(.headline)
            Spacer()
            if bluetoothManager.isConnected {
                HStack(spacing: 4) {
                    Image(systemName: "battery.100")
                        .font(.caption)
                    Text("\(bluetoothManager.batteryLevel)%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Button {
                    bluetoothManager.startScanning()
                } label: {
                    Label(bluetoothManager.isScanning ? "Scanning..." : "Reconnect", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .disabled(bluetoothManager.isScanning)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Side list

    private var sideList: some View {
        VStack(spacing: 2) {
            ForEach(1...8, id: \.self) { side in
                sideRow(side)
            }
        }
        .padding(.vertical, 4)
    }

    private func sideRow(_ side: Int) -> some View {
        let action = actionStore.action(for: side)
        let isActive = bluetoothManager.currentSide == side

        return Button {
            editingSide = side
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isActive ? Color.accentColor : Color.secondary.opacity(0.2))
                        .frame(width: 26, height: 26)
                    Text("\(side)")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundColor(isActive ? .white : .primary)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(action.label)
                        .font(.system(.body, weight: isActive ? .semibold : .regular))
                        .lineLimit(1)
                    Text(action.summary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: action.type.icon)
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .toggleStyle(.checkbox)
                .font(.caption)
                .onChange(of: launchAtLogin) { _, newValue in
                    setLaunchAtLogin(newValue)
                }

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .font(.caption)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to set login item: \(error)")
        }
    }
}
