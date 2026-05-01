# WhatCable

A small macOS menu bar app that tells you, in plain English, what each USB-C cable plugged into your Mac can actually do.

> What can this USB-C cable actually do?

USB-C cables are notoriously hard to tell apart at a glance — the same connector covers everything from USB 2.0 charge-only cables to 240W / 40 Gbps Thunderbolt 4. macOS already exposes most of the relevant info via IOKit; WhatCable surfaces it in a friendly menu bar popover.

## What it shows

For each USB-C / MagSafe port:

- **At-a-glance headline** — Thunderbolt / USB4, USB device, Charging only, Slow USB / charge-only cable, Nothing connected
- **Cable speed** decoded from the e-marker chip (USB 2.0, 5/10/20/40/80 Gbps)
- **Cable power rating** (3 A or 5 A, max 60 W / 100 W / 240 W) — what the cable itself can carry
- **Charger output** — every PDO the connected charger advertises (e.g. 5V/9V/12V/15V/20V), with the currently negotiated voltage highlighted live
- **Connected device identity** — vendor and product type, decoded from the partner's PD Discover Identity response
- **Active transports** — USB 2 / USB 3 / Thunderbolt / DisplayPort
- **A "Show technical details" toggle** that reveals the underlying IOKit properties for engineers

Right-click the menu bar icon for **Refresh**, **About**, and **Quit**.

## How it works

WhatCable reads three families of IOKit services, no entitlements or private APIs required:

| Service | What it gives us |
| --- | --- |
| `AppleHPMInterfaceType10/11` | Per-port state: connection, transports, plug orientation, e-marker presence |
| `IOPortFeaturePowerSource` | Full PDO list from the connected source, with live "winning" PDO |
| `IOPortTransportComponentCCUSBPDSOP` | PD Discover Identity VDOs for SOP (partner) and SOP' (cable e-marker) |

The cable speed and power decoding follows the USB Power Delivery 3.x spec.

## Run from source

```bash
swift run WhatCable
```

Requires macOS 14+ and Swift 5.9 (Xcode 15+).

## Build a distributable .app

```bash
./scripts/build-app.sh
```

Produces a universal `dist/WhatCable.app` (arm64 + x86_64) and `dist/WhatCable.zip`.

**Modes:**

| Configuration | Result |
| --- | --- |
| No `.env` | Ad-hoc signed. Works locally; Gatekeeper warns on other Macs. |
| `.env` with `DEVELOPER_ID` | Developer ID signed + hardened runtime. Suitable for limited distribution. |
| `.env` with `DEVELOPER_ID` + `NOTARY_PROFILE` | Full notarisation + stapled ticket. Gatekeeper-clean for everyone. |

**One-time setup for full notarisation:**

```bash
# Find your signing identity
security find-identity -v -p codesigning

# Store notarytool credentials in the keychain
xcrun notarytool store-credentials "WhatCable-notary" \
    --apple-id "you@example.com" \
    --team-id "ABCDE12345" \
    --password "<app-specific-password>"   # from appleid.apple.com

# Then create .env from the template
cp .env.example .env
# ...and fill in DEVELOPER_ID
```

To install locally:

```bash
cp -R dist/WhatCable.app /Applications/
```

## Caveats

- **Cable e-marker info only appears for cables that carry one.** Most USB-C cables under 60 W are unmarked. Any Thunderbolt / USB4 cable, any 5 A / 100 W+ cable, and most quality data cables will be e-marked.
- **PD spec coverage:** decoder targets PD 3.0 / 3.1. PD 3.2 EPR variants may need tweaks once we see real data.
- **Vendor IDs are shown numerically** — there's no bundled USB-IF vendor name database (yet).
- **macOS only.** iOS sandboxing makes USB-C e-marker access much harder.

## Releases

Latest builds are on the [Releases page](https://github.com/darrylmorley/whatcable/releases).

## Credits

Built by Bitmoor Ltd.
