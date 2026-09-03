# Market of Ash — latest review

**Build:** `0.16.0-early-access-rc2`  
**Main commit:** `9d7d368`  
**Engine:** Godot 4.4.1  
**Viewport:** 1280×720  
**Evidence:** `docs/visual_evidence/v0.16.0-early-access-rc2-review-2026-09-03/`

## Verification result

The full repository verification suite passed. The deterministic economy, ordinary-trade, adaptive-basin, campaign, controller, accessibility, save, and Early Access gates remain green. The current release-budget check reports 25 deterministic world/save round trips in 150.15 ms against a 5,000 ms limit.

## Visual result

The title screen communicates the caravan ledger and trade premise, but the composition remains sparse for an investment-facing build. The Introduction communicates the central tension effectively, yet the right-side Next control and the second-page explanatory copy still run into the 1280×720 viewport boundary. This is a confirmed presentation defect, not an economy defect.

The smoke flow currently reaches Introduction 2 of 3 rather than the first Bazaar decision. That means the next evidence gate must be a complete clean-save sequence: first purchase, route comparison, departure, road consequence, arrival sale or recovery, changed return market, and terminal receipt.

## Roadmap update

The first mandatory task remains **MA-GPT56-1 / MA-EA-1**: repair the actual `ResponsiveColumns` and minimum-size negotiation, preserve readable copy, and add layout assertions for every required control. Do not make contracts mandatory, hide text, or solve the issue by globally shrinking the UI. After the responsive fix, build the complete ordinary-trade path before adding a second region.

## Evidence files

- `01_title.png` — Main Menu.
- `02_first_action.png` — Introduction 1 of 3.
- `03_followup.png` — Introduction 2 of 3, showing the remaining clipping.
