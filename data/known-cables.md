# Known cables

A working list of USB-C cables that have been reported to WhatCable via the
in-app "Report this cable" flow. This is a memory aid for future trust-signal
and inventory work, seeded from the closed [`cable-report`](https://github.com/darrylmorley/whatcable/issues?q=label%3Acable-report)
issues on GitHub.

The full reports (with reporter notes, dates, and triage replies) live on the
issue tracker. This file holds a condensed, deduplicated view of the e-marker
fingerprints. Vendor names below come from the bundled USB-IF list (shipped
with WhatCable v0.8.1 onwards), not from whatever name the reporting build
showed at the time.

## Why this file exists

WhatCable's [issue template](../.github/ISSUE_TEMPLATE/cable-report.yml)
states the goal: a public database of known-good and counterfeit USB-C cable
fingerprints. The Cable Trust Signals work (see `planning/cable-trust-signals.md`)
will eventually consume a curated subset of this. For now it is a flat
hand-maintained markdown table; format may change once the consumer exists.

## Table

| VID | PID | Vendor (USB-IF) | XID | Speed | Power | Type | Brand / model context | Source |
|---|---|---|---|---|---|---|---|---|
| `0x0138` | `0x0310` | Unregistered | none | USB4 Gen 4 (80 Gbps) | 5 A / 50 V (250 W) | passive | UGOURD TB5/USB4 cable, AliExpress (no USB-IF cert) | [#71](https://github.com/darrylmorley/whatcable/issues/71) |
| `0x0522` | `0x0A06` | ACON, Advanced-Connectek, Inc. | `0x939` | USB4 Gen 3 (40 Gbps) | 5 A / 20 V (100 W) | passive | Bundled in UGREEN Revodok Max 213 (U710) dock; housing marked TB4 | [#84](https://github.com/darrylmorley/whatcable/issues/84) |
| `0x201C` | `0x0000` | Hongkong Freeport Electronics Co. | none | USB 2.0 (480 Mbps) | 5 A / 20 V (100 W) | passive | Anker 333 USB-C 3.3 ft nylon | [#60](https://github.com/darrylmorley/whatcable/issues/60) |
| `0x2095` | `0x004F` | CE LINK LIMITED | none | USB 3.2 Gen 2 (10 Gbps) | 5 A / 20 V (100 W) | passive | Monoprice Essentials USB-C 10 Gbps 0.5 m | [#48](https://github.com/darrylmorley/whatcable/issues/48) |
| `0x20C2` | `0x0005` | Sumitomo Electric Ind., Ltd. | none | USB 3.2 Gen 2 (10 Gbps) | 5 A / 20 V (100 W) | passive | delock TB3-branded cable | [#44](https://github.com/darrylmorley/whatcable/issues/44) |
| `0x2B1D` | `0x1512` | Lintes Technology Co., Ltd. | none | USB4 Gen 3 (40 Gbps) | 5 A / 20 V (100 W) | passive | CalDigit TS4 dock bundled cable (likely) | [#62](https://github.com/darrylmorley/whatcable/issues/62) |
| `0x2E99` | `0x0000` | Hynetek Semiconductor Co., Ltd | none | USB4 Gen 3 (40 Gbps) | 5 A / 50 V (250 W) | passive | Dbilida TB4-branded 240 W cable, Amazon (no USB-IF cert) | [#49](https://github.com/darrylmorley/whatcable/issues/49) |
| `0x315C` | `0x0000` | Chengdu Convenientpower Semiconductor Co., LTD | none | USB4 Gen 3 (40 Gbps) | 5 A / 20 V (100 W) | passive | acasis cable bundled with TBU405M1 enclosure | [#45](https://github.com/darrylmorley/whatcable/issues/45) |
| `0x0000` | `0x0000` | (zeroed) | none | (none advertised) | (not advertised) | passive | CUKTECH No.6 140 W (e-marker present but VID/PID/speed all zeroed) | [#61](https://github.com/darrylmorley/whatcable/issues/61) |

Sorted by VID. The zeroed-fingerprint entry is parked at the bottom because it
is identity-less.

## Patterns worth flagging for trust-signals work

Three of the nine reports show patterns that the planned Cable Trust Signals
heuristics should pick up:

1. **Marketing claim outpaces e-marker capability.** #49 (Dbilida) is sold as
   "Thunderbolt 4 / 40 Gbps / 240 W" but the e-marker reports passive USB4
   Gen 3 with no USB-IF cert. The cable may carry the advertised data rate,
   but there is no cert backing the claim.
2. **Genuinely unregistered VID with no XID.** #71 (UGOURD AliExpress) reports
   80 Gbps USB4 Gen 4 from an unregistered VID and zero XID. Plausibly real
   silicon, but unverifiable from the e-marker alone.
3. **Zeroed identity fields.** #61 (CUKTECH No.6) has a present e-marker that
   reports `0x0000` for VID, PID, and no speed. Already flagged by trust
   signals today; the report confirms the pattern is real and not a parser
   bug.

The other six reports describe cables whose e-marker matches their marketing.

## Adding new entries

When triaging a new closed cable-report issue:

1. Pull VID, PID, XID, speed, current rating, and type from the markdown
   table in the issue body.
2. Look up the canonical USB-IF vendor name (do not use the "as reported"
   name, since older WhatCable versions show "Unregistered / unknown" for
   VIDs that were registered all along).
3. Distil the reporter's notes to one short phrase covering brand and
   purchase context. Strip Amazon affiliate links, full product titles, and
   anything that reads as personal context.
4. Add the row in VID order. Link the issue under the Source column.
5. If the report shows a trust-signal pattern (marketing/e-marker mismatch,
   unregistered + no cert, zeroed fields, impossible PDOs), note it in the
   Patterns section above.

After editing this file, re-render the public page:

```bash
swift scripts/render-known-cables.swift
```

That writes `docs/cables.html`. Commit both files together.

This file is not bundled into the app. It is a human reference. When the
trust-signals or inventory features need this data at runtime, we'll
formalise it then.
