import SwiftUI

@main
struct TimeularMacropadApp: App {
    @StateObject private var bluetoothManager = BluetoothManager()
    @StateObject private var actionStore = ActionStore()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(
                bluetoothManager: bluetoothManager,
                actionStore: actionStore
            )
            .frame(width: 320)
        } label: {
            Label {
                Text("Timeular Macropad")
            } icon: {
                Image(systemName: bluetoothManager.isConnected ? "octagon.fill" : "octagon")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
