"""Listen for Timeular orientation changes to identify the side-reporting characteristic."""
import asyncio
from bleak import BleakClient, BleakScanner

DEVICE_NAME = "Timeular Tracker"

# Characteristics that support notify/indicate (potential orientation reporters)
NOTIFY_CHARS = [
    "c7e70001-c847-11e6-8175-8c89a55d403c",  # notify + write
    "c7e70012-c847-11e6-8175-8c89a55d403c",  # indicate + read (had value 0x07)
    "c7e70021-c847-11e6-8175-8c89a55d403c",  # indicate
    "c7e70032-c847-11e6-8175-8c89a55d403c",  # notify + write
    "c7e70033-c847-11e6-8175-8c89a55d403c",  # indicate + write
]

# Also read this one periodically - suspected current side
ORIENTATION_READ = "c7e70012-c847-11e6-8175-8c89a55d403c"


def make_handler(uuid_short):
    def handler(sender, data):
        print(f"  >> [{uuid_short}] NOTIFY: {list(data)} (hex: {data.hex()})")
    return handler


async def main():
    print("Scanning for Timeular Tracker (10s)...")
    print(">>> Flip the tracker NOW to wake it! <<<\n")

    device = None
    def on_detect(d, adv):
        nonlocal device
        if d.name and "timeular" in d.name.lower():
            device = d
            print(f"Found: {d.name} ({d.address})")

    scanner = BleakScanner(detection_callback=on_detect)
    await scanner.start()
    for _ in range(40):  # 20 seconds
        await asyncio.sleep(0.5)
        if device:
            break
    await scanner.stop()

    if not device:
        print("Not found. Make sure the Timeular app is closed and flip the tracker.")
        return

    print(f"\nConnecting to {device.name}...")
    async with BleakClient(device) as client:
        print(f"Connected!\n")

        # Read initial orientation
        val = await client.read_gatt_char(ORIENTATION_READ)
        print(f"Initial orientation (c7e70012): {list(val)} = side {val[0]}")

        # Subscribe to all notify/indicate characteristics
        for uuid in NOTIFY_CHARS:
            short = uuid.split("-")[0]
            try:
                await client.start_notify(uuid, make_handler(short))
                print(f"Subscribed to {short}")
            except Exception as e:
                print(f"Could not subscribe to {short}: {e}")

        print(f"\n{'='*50}")
        print("LISTENING FOR 30s - Flip to different sides!")
        print(f"{'='*50}\n")

        for i in range(30):
            await asyncio.sleep(1)
            try:
                val = await client.read_gatt_char(ORIENTATION_READ)
                print(f"  [poll] side = {val[0]} (raw: {val.hex()})")
            except Exception:
                pass

        print("\nDone.")

asyncio.run(main())
