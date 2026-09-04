# MA-GPT56-1A — responsive capture and complete journey

**Status:** Complete for repository-owned scope

**Build:** `0.16.1-early-access-rc1`

**Engine:** Godot `4.4.1.stable.official.49a5bc7b6`
**Evidence:** `docs/visual_evidence/v0.16.1-ma-gpt56-1a-2026-09-04/`

## Finding

The repeat review did not capture a 1280×720 game window. Its image shows the 1.25 scale of a 1600×900 native window cropped by a 1280×720 virtual desktop. Startup fitting considered only `WINDOW_MODE_WINDOWED`; a host that classified the oversized startup window as maximized could therefore bypass the clamp. The review path also recorded only the screenshot dimensions, not the native-window size or whether navigation had completed.

## Resolution

- Startup fitting accepts both windowed and maximized startup modes, normalizes an oversized maximized window, and rechecks display bounds for four settled frames.
- Deliberate fullscreen and exclusive-fullscreen modes remain untouched.
- Native captures record requested size, actual native-window size, physical screen, usable area, logical viewport, and window mode.
- Critical vertical-slice captures wait for their exact player state to remain stable for two renderer frames. The contract covers Introduction pages, Bazaar purchase, Departure, road stop, event, arrival, destination sale, changed return market, optional black-market pressure, and ending.
- The evidence validator rejects cropped-window contracts and early captures.
- A reusable extractor produces compact review sequences from the validated source manifest.
- The road-side context now renders its actual waypoint instead of the literal `%s` placeholder found during the visual pass.
- Zero-cost settlement actions no longer lead with `0 ashmarks`; the optional arms sale now leads with its cargo exchange, payout, and escalation consequence.

No copy was shortened, no control was hidden, global text size was unchanged, and ordinary trade remains sufficient to reach the ending.

## Evidence result

Godot 4.4.1 native capture and validation passed independently at:

- 960×540
- 1280×720
- 1600×900

The curated 1280×720 sequence contains 12 states. Introduction 2 preserves 48-pixel outer gutters, the body wraps to two complete lines, and the primary action ends 62 pixels before the right edge. The same sequence continues through the first purchase, road decision, arrival receipt, changed market, return sale, optional black-market choice, recovery action, and terminal receipt.

The full repository verification suite passes. The release benchmark completes 25 deterministic world/save round trips in 54.16 ms against the 5,000 ms limit.

## Remaining external gates

Physical Windows high-DPI behavior, physical-controller coverage, assistive-technology testing, and moderated first-time-player comprehension remain external tests. They are not replaced by renderer evidence.
