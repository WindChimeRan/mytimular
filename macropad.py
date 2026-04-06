#!/usr/bin/env python3
"""
Timeular Macropad — repurpose your Timeular Tracker as an 8-key macropad.

Each side (1-8) maps to a configurable shell command or keyboard shortcut.
Edit the SIDE_ACTIONS dict below to customize.

Usage:
    python3 macropad.py

Requirements:
    pip3 install bleak
"""
import asyncio
import json
import os
import subprocess
import sys
from pathlib import Path

from bleak import BleakClient, BleakScanner

DEVICE_NAME = "Timeular Tracker"
ORIENTATION_UUID = "c7e70012-c847-11e6-8175-8c89a55d403c"
CONFIG_PATH = Path(__file__).parent / "macropad_config.json"

# Default config — written to macropad_config.json on first run
DEFAULT_CONFIG = {
    "_comment": "Map each side (1-8) to an action. Types: 'shell' runs a command, 'keystroke' sends a key combo via AppleScript.",
    "actions": {
        "1": {"type": "shell", "command": "open -a 'Terminal'", "label": "Terminal"},
        "2": {"type": "shell", "command": "open -a 'Safari'", "label": "Safari"},
        "3": {"type": "shell", "command": "open -a 'Finder'", "label": "Finder"},
        "4": {"type": "keystroke", "key": "space", "modifiers": ["command"], "label": "Spotlight"},
        "5": {"type": "shell", "command": "open -a 'Notes'", "label": "Notes"},
        "6": {"type": "keystroke", "key": "3", "modifiers": ["command", "shift"], "label": "Screenshot"},
        "7": {"type": "shell", "command": "say 'Side seven'", "label": "Say Side 7"},
        "8": {"type": "shell", "command": "open -a 'Activity Monitor'", "label": "Activity Monitor"},
    },
}


def load_config():
    if CONFIG_PATH.exists():
        with open(CONFIG_PATH) as f:
            return json.load(f)
    # Write default config
    with open(CONFIG_PATH, "w") as f:
        json.dump(DEFAULT_CONFIG, f, indent=2)
    print(f"Created default config at {CONFIG_PATH}")
    print("Edit it to customize your side actions.\n")
    return DEFAULT_CONFIG


def execute_action(side: int, config: dict):
    key = str(side)
    actions = config.get("actions", {})
    if key not in actions:
        print(f"  Side {side}: no action configured")
        return

    action = actions[key]
    label = action.get("label", f"Side {side}")
    action_type = action.get("type", "shell")

    print(f"  -> [{label}]", end=" ", flush=True)

    if action_type == "shell":
        cmd = action.get("command", "")
        try:
            subprocess.Popen(cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            print("(executed)")
        except Exception as e:
            print(f"(error: {e})")

    elif action_type == "keystroke":
        key_char = action.get("key", "")
        modifiers = action.get("modifiers", [])
        applescript = _build_keystroke_applescript(key_char, modifiers)
        try:
            subprocess.Popen(
                ["osascript", "-e", applescript],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            print("(keystroke sent)")
        except Exception as e:
            print(f"(error: {e})")
    else:
        print(f"(unknown type: {action_type})")


def _build_keystroke_applescript(key: str, modifiers: list) -> str:
    mod_map = {
        "command": "command down",
        "shift": "shift down",
        "option": "option down",
        "control": "control down",
    }
    mod_parts = [mod_map[m] for m in modifiers if m in mod_map]
    if mod_parts:
        using = "using {" + ", ".join(mod_parts) + "}"
    else:
        using = ""
    return f'tell application "System Events" to keystroke "{key}" {using}'


async def main():
    config = load_config()

    print("Timeular Macropad")
    print("=" * 40)
    print("\nConfigured actions:")
    for side in range(1, 9):
        action = config.get("actions", {}).get(str(side), {})
        label = action.get("label", "(not set)")
        print(f"  Side {side}: {label}")

    print(f"\nScanning for {DEVICE_NAME}...")
    print("Flip the tracker to wake it.\n")

    device = None

    def on_detect(d, adv):
        nonlocal device
        if d.name and "timeular" in d.name.lower():
            device = d

    scanner = BleakScanner(detection_callback=on_detect)
    await scanner.start()
    for _ in range(40):
        await asyncio.sleep(0.5)
        if device:
            break
    await scanner.stop()

    if not device:
        print("Timeular Tracker not found.")
        print("Make sure the Timeular app is closed and flip the tracker.")
        sys.exit(1)

    print(f"Found {device.name} ({device.address})")

    current_side = [None]

    def on_orientation(sender, data):
        side = data[0]
        if side == current_side[0]:
            return
        if side == 0:
            print(f"\n  Side: (in transit)")
            current_side[0] = 0
            return
        current_side[0] = side
        print(f"\n  Side: {side}")
        execute_action(side, config)

    disconnect_event = asyncio.Event()

    def on_disconnect(client):
        print("\nTracker disconnected.")
        disconnect_event.set()

    async with BleakClient(device, disconnected_callback=on_disconnect) as client:
        print(f"Connected!\n")

        # Read initial side
        val = await client.read_gatt_char(ORIENTATION_UUID)
        current_side[0] = val[0]
        print(f"Current side: {current_side[0]}")
        print("\nListening for flips... (Ctrl+C to quit)\n")

        await client.start_notify(ORIENTATION_UUID, on_orientation)

        # Keep running until disconnected
        try:
            await disconnect_event.wait()
        except asyncio.CancelledError:
            pass

    print("Reconnect by running the script again.")


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nStopped.")
