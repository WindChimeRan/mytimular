"""Scan the Timeular Tracker's GATT services and characteristics.

On macOS, already-connected BLE devices don't advertise, so we need
to retrieve them from CoreBluetooth's connected peripheral list.
"""
import asyncio
from bleak import BleakClient, BleakScanner

async def main():
    # On macOS, try scanning with service UUID filter or broader scan
    # The Timeular might be asleep - need to flip/move it to wake
    print("Scanning for BLE devices (10 seconds)...")
    print(">>> Flip or move your Timeular tracker to wake it up! <<<\n")

    target = None

    def detection_callback(device, advertisement_data):
        nonlocal target
        if device.name and "timeular" in device.name.lower():
            target = device
            print(f"  *** FOUND: {device.name} ({device.address}) ***")
            print(f"      RSSI: {advertisement_data.rssi}")
            print(f"      Service UUIDs: {advertisement_data.service_uuids}")

    scanner = BleakScanner(detection_callback=detection_callback)
    await scanner.start()
    # Wait and check periodically
    for i in range(20):
        await asyncio.sleep(0.5)
        if target:
            break
    await scanner.stop()

    if not target:
        # List all found devices for debugging
        devices = scanner.discovered_devices_and_advertisement_data
        print(f"\nFound {len(devices)} devices total. Listing all with names:")
        for d, adv in devices.values():
            if d.name:
                print(f"  {d.name} ({d.address}) RSSI={adv.rssi}")
                print(f"    Services: {adv.service_uuids}")
        print("\nTimeular not found. Try:")
        print("  1. Flip the tracker to wake it")
        print("  2. Make sure the Timeular app is closed (it may hold the connection)")
        return

    print(f"\nConnecting to {target.name} ({target.address})...")
    async with BleakClient(target) as client:
        print(f"Connected: {client.is_connected}\n")
        print(f"{'='*60}")
        print("GATT Services and Characteristics")
        print(f"{'='*60}\n")
        for service in client.services:
            print(f"Service: {service.uuid}")
            print(f"  Description: {service.description}")
            for char in service.characteristics:
                props = ", ".join(char.properties)
                print(f"  Characteristic: {char.uuid}")
                print(f"    Description: {char.description}")
                print(f"    Properties: {props}")
                if "read" in char.properties:
                    try:
                        value = await client.read_gatt_char(char.uuid)
                        print(f"    Value: {value} (hex: {value.hex()})")
                    except Exception as e:
                        print(f"    Read error: {e}")
                if "notify" in char.properties:
                    print(f"    [SUPPORTS NOTIFY - potential orientation data]")
                for desc in char.descriptors:
                    print(f"    Descriptor: {desc.uuid} = {desc.description}")
            print()

asyncio.run(main())
