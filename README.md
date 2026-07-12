# MenuSwipe

**Experimental / work-in-progress.** A macOS menu-bar utility exploring how to
scroll through menu bar icons.

## What it does now
On launch (after granting **Accessibility** + **Screen Recording**) it:
1. Enumerates every app's menu bar extras via the Accessibility API
   (`AXExtrasMenuBar`).
2. Captures each real glyph from the screen at its true position.
3. Shows them in a borderless, always-on-top **overlay** over the menu bar's
   icon area — a horizontally scrollable strip. Clicking a glyph `AXPress`es the
   real element, opening its true menu.

## Build & run
```bash
./build.sh
open MenuSwipe.app
```
Grant **Accessibility** and **Screen Recording** to MenuSwipe in
System Settings → Privacy & Security. Ad-hoc signed, so each rebuild resets the
grants.

## Honest status & limitations
The original goal — *scroll the real system menu bar icons in place, all always
visible, no second surface, no hide/show* — is **not achievable** for a
third-party app. Each menu bar icon is owned by its app; macOS exposes no API to
move or scroll another app's icons. Approaches tried:

| Approach | Outcome |
|---|---|
| Hide/reveal via spacer status item | works, but icons appear/disappear |
| Wide status item strip | on notched Macs it eats bar width → pushes real icons behind the notch |
| Floating overlay (this build) | doesn't consume bar width, but a fixed window can't align pixel-perfect with the real bar |

A polished result (seamless, notch-aware, click-forwarding) is essentially what
**Bartender** does — using private APIs and continuous per-OS maintenance. This
repo is a research spike, not a finished product.
