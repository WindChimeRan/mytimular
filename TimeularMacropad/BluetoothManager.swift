import CoreBluetooth
import Combine

/// Manages BLE connection to the Timeular Tracker and publishes orientation changes.
final class BluetoothManager: NSObject, ObservableObject {
    // MARK: - Published state

    @Published var isConnected = false
    @Published var currentSide: Int = 0
    @Published var batteryLevel: Int = 0
    @Published var isScanning = false

    // MARK: - BLE constants

    static let deviceName = "Timeular Tracker"
    static let orientationServiceUUID = CBUUID(string: "c7e70010-c847-11e6-8175-8c89a55d403c")
    static let orientationCharUUID = CBUUID(string: "c7e70012-c847-11e6-8175-8c89a55d403c")
    static let batteryServiceUUID = CBUUID(string: "180F")
    static let batteryCharUUID = CBUUID(string: "2A19")

    // MARK: - Callback

    var onSideChanged: ((Int) -> Void)?

    // MARK: - Private

    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var orientationChar: CBCharacteristic?
    private var reconnectTimer: Timer?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        isScanning = true
        centralManager.scanForPeripherals(
            withServices: [Self.orientationServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        // Also try to retrieve already-connected peripherals
        let connected = centralManager.retrieveConnectedPeripherals(
            withServices: [Self.orientationServiceUUID]
        )
        if let device = connected.first {
            centralManager.stopScan()
            isScanning = false
            peripheral = device
            device.delegate = self
            centralManager.connect(device)
        }
    }

    func disconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        if let p = peripheral {
            centralManager.cancelPeripheralConnection(p)
        }
    }

    private func scheduleReconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.startScanning()
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScanning()
        } else {
            DispatchQueue.main.async {
                self.isConnected = false
            }
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? ""
        guard name.lowercased().contains("timeular") else { return }

        central.stopScan()
        isScanning = false
        self.peripheral = peripheral
        peripheral.delegate = self
        central.connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self.isConnected = true
        }
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        peripheral.discoverServices([
            Self.orientationServiceUUID,
            Self.batteryServiceUUID,
        ])
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        DispatchQueue.main.async {
            self.isConnected = false
            self.currentSide = 0
        }
        orientationChar = nil
        scheduleReconnect()
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard let chars = service.characteristics else { return }
        for char in chars {
            if char.uuid == Self.orientationCharUUID {
                orientationChar = char
                peripheral.setNotifyValue(true, for: char)
                peripheral.readValue(for: char)
            } else if char.uuid == Self.batteryCharUUID {
                peripheral.setNotifyValue(true, for: char)
                peripheral.readValue(for: char)
            }
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard let data = characteristic.value, !data.isEmpty else { return }

        if characteristic.uuid == Self.orientationCharUUID {
            let side = Int(data[0])
            DispatchQueue.main.async {
                let previousSide = self.currentSide
                self.currentSide = side
                if side != previousSide && side != 0 {
                    self.onSideChanged?(side)
                }
            }
        } else if characteristic.uuid == Self.batteryCharUUID {
            let level = Int(data[0])
            DispatchQueue.main.async {
                self.batteryLevel = level
            }
        }
    }
}
