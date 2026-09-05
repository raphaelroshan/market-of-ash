# MA-GPT56-1C — safe startup and completion-aware opening

**Status:** Complete for repository-owned scope

**Build:** `0.16.1-early-access-rc1`

**Engine:** Godot `4.4.1.stable.official.49a5bc7b6`

**Evidence:** `docs/visual_evidence/v0.16.1-ma-gpt56-1c-2026-09-05/`

## Finding

The September 5 audit again photographed a 1600×900 startup surface through a 1280×720 virtual desktop before runtime window fitting settled. The image was therefore a crop, not the compact 1280×720 layout recorded by the repository-owned capture contract. The audit traversal also did not prove the Introduction page reached before each screenshot.

## Resolution

- Native builds bootstrap at 1280×720, then promote to the preferred 1600×900 only when the physical and usable display bounds can contain it.
- Explicit resolution requests remain authoritative and are only clamped when they exceed the display.
- The packaged Windows screenshot harness supplies a user-visible capture-size marker so startup promotion cannot override its exact 960×540 client contract after Godot consumes engine arguments.
- `ResponsiveColumns` reports the composition actually selected after child minimum-size negotiation rather than only the requested breakpoint.
- All three Introduction pages assert card gutters and containment for progress, title, body scroll, body, note, Back, Next, and skip controls.
- Native opening traversal activates the real semantic buttons and waits for the exact expected screen and Introduction page for two stable frames. Large Text now has its own completion requirement.

No prose was removed, no text was globally reduced, and the preferred large desktop presentation remains 1600×900.

## Evidence result

Godot 4.4.1 native capture and pixel/layout validation pass independently at 960×540, 1280×720, and 1600×900. At 1280×720 each Introduction card has 48-pixel outer gutters, its body is 1152 pixels wide inside the card, and the primary action ends at x=1216, leaving 64 pixels before the viewport edge.

The 12-state review sequence continues from all three Introduction pages through the first ordinary purchase, route comparison, road stop, Three Riders consequence, arrival sale, changed return market, and terminal receipt. Every critical state records two stable frames before capture.

The QA workflow introduced by PRs #82 and #83 is incorporated as an additional evidence layer. `bash scripts/agent_qa.sh` returns `PASS`, wraps the full verifier, records the default ordinary-trade scenario contract, and preserves a real 1280×720 Main Menu frame after eight stable semantic frames. The scenario remains honestly classified `PLANNED`; the completion-aware native journey above is still the executable ordinary-trade proof.

## Remaining external gates

Physical Windows high-DPI behavior, physical-controller coverage, assistive-technology testing, and moderated first-time-player comprehension remain external tests.
