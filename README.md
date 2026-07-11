# MenuSwipe

macOS menu-bar app. Two-finger horizontal swipe **over the menu bar** switches
between running apps.

## How it works
A session-level `CGEventTap` watches trackpad scroll events. When a continuous
(two-finger) scroll happens inside the menu bar strip and is horizontal-dominant,
MenuSwipe consumes it and activates the previous/next app in your order.

## Build & run
```bash
./build.sh
open MenuSwipe.app
```
First launch prompts for **Accessibility** (System Settings → Privacy & Security →
Accessibility). Grant it — the swipe starts working, no relaunch.

## Menu (status item ⇄)
- **Attivo** — enable/disable (disabled = scrolls pass through untouched)
- **Inverti direzione** — flip swipe direction
- **Sensibilità** — Bassa / Media / Alta (swipe distance per switch)
- **Ambito swipe**
  - *Quali app scorrere*: Tutte / Solo a sinistra / Solo a destra
  - *Sinistra/destra rispetto a*: App attiva (dinamico) / App fissa (pivot) / Metà lista
- **Riordina app…** — drag-to-reorder window; the swipe follows this order

## App order
Order is user-defined and persisted (bundle IDs in UserDefaults). New apps append
at the end; reorder them in the window. Quit apps keep their remembered slot.

## Scope model
`scope = f(side, reference)`. Reference index r = current app / chosen pivot /
list middle. `left` → apps before r, `right` → apps after r, `all` → whole ring
(wraps). Pure logic covered by `scratchpad/scope_check.swift` (ALL PASS).

## Limits
- Primary-display menu bar only (v1).
- If swipe doesn't fire after granting Accessibility, also enable **Input Monitoring**.
