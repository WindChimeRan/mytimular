# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Timeular Macropad is a macOS menu bar app (Swift/SwiftUI) that repurposes a Timeular Tracker as an 8-key macropad via BLE. When the tracker is flipped to a side, the app executes a user-configured action (launch app, keyboard shortcut, shell command, or open URL).

There is also a Python prototype (`macropad.py`) using `bleak` for BLE — this was the proof-of-concept before the native Swift app.

## Build & Run

```bash
# Debug build (Swift Package Manager)
swift build

# Release build + bundle into .app
./bundle.sh
# Output: build/Timeular Macropad.app

# Run the bundled app
open "build/Timeular Macropad.app"
```

The project can also be opened in Xcode via `TimeularMacropad.xcodeproj` (generated from `project.yml` with XcodeGen).

## Architecture

The app is a `MenuBarExtra`-based SwiftUI app (`LSUIElement = true`, no dock icon).

- **BluetoothManager** — CoreBluetooth `CBCentralManager`/`CBPeripheral` delegate. Scans for a device named "Timeular Tracker", subscribes to the orientation characteristic (`c7e70012-...`), and publishes `currentSide` (1-8, 0 = in transit). Auto-reconnects on disconnect via a 3-second timer. Scans without service UUID filter because the advertised UUID differs from the GATT service UUID.
- **ActionStore** — Persists side-to-action mappings as JSON in `~/Library/Application Support/TimeularMacropad/actions.json`. Initializes missing sides with empty defaults.
- **SideAction / ActionType** — Data model. Four action types: `app`, `keystroke`, `shell`, `url`.
- **ActionExecutor** — Executes actions: `NSWorkspace` for apps/URLs, `CGEvent` for keystrokes (requires Accessibility permission), `Process` with `/bin/zsh` for shell commands.
- **MenuBarView** — Main popover UI showing connection status, battery level, all 8 sides with their configured actions, and a reconnect button.
- **SideEditView** — Inline editor (replaces the side list in the popover) for configuring a side's action type, label, and parameters.

## BLE Protocol

- Orientation service: `c7e70010-c847-11e6-8175-8c89a55d403c`
- Orientation characteristic: `c7e70012-c847-11e6-8175-8c89a55d403c` (notify, read) — first byte is side number (1-8, 0 = transitioning)
- Battery: standard BLE battery service `180F` / characteristic `2A19`

## Platform Requirements

- macOS 14.0+, Swift 5.9
- Bluetooth permission (entitlements include `com.apple.security.device.bluetooth`)
- Sandbox disabled (needed for shell command execution and CGEvent posting)
- Accessibility permission required at runtime for keystroke actions
