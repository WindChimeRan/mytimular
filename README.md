# Timeular Macropad

<p align="center">
  <img src="assets/IMG_0171.png" width="300" />
  <img src="assets/Timeular%20Macropad.png" width="300" />
</p>

I had a Timeular Tracker sitting on my desk, fully charged but gathering dust (I didn't pay monthly subscription fee!). I also had Claude Opus 4.6 and a head full of ideas. Even though I don't know Swift, Opus does — so I described what I wanted and let it write a native macOS menu bar app from scratch.

Now I flip my Timeular to switch macOS desktops: side 1 for my main workspace, side 2 for a side project, side 3 for another — no keyboard shortcuts to memorize, just a satisfying physical flip.

## How it was built (prompts)

1. **Scan** — Asked Claude to find the Timeular over Bluetooth. It picked Python to explore the device.
2. **Prototype** — Read the orientation signal on flip, wired it to shell commands — a working macropad in a single script.
3. **Go native** — Rewrote everything in Swift/SwiftUI as a proper macOS menu bar app with CoreBluetooth.
4. **Ship it** — It works!
