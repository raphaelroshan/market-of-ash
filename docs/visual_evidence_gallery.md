# Market of Ash — Basin Vertical-Slice Gallery

These are local real-renderer captures from `v0.13.0-alpha-basin-vertical-slice`. They document the current game flow rather than final promotional art. Every image below is backed by a native capture manifest that records the exact viewport, screen state, focus and required-control bounds, platform, and display scale.

The latest completion-aware 1280×720 review sequence is [`v0.16.1-ma-gpt56-1a-2026-09-04`](visual_evidence/v0.16.1-ma-gpt56-1a-2026-09-04/README.md). Its manifest additionally proves native-window size and two-frame navigation stability from Introduction 2 through the terminal receipt.

The follow-up [`journey phase identity`](visual_evidence/v0.16.1-journey-phase-identity-2026-09-04/README.md) sequence shows the same rail changing from Departure Desk to Road Stop, Roadside Decision, and Arrived at Reedwatch.

The [`encounter copy`](visual_evidence/v0.16.1-encounter-copy-2026-09-04/README.md) sequence verifies action-first choice headings, exact single-instance costs, and omission of zero-cost noise.

The [`road endpoint identity`](visual_evidence/v0.16.1-road-endpoint-identity-2026-09-04/README.md) sequence shows registry-driven origin and destination silhouettes across all three regions.

| Field | Value |
|---|---|
| Build | `v0.13.0-alpha-basin-vertical-slice` |
| Engine | Godot 4.4.1 |
| Capture origin | Local macOS OpenGL real-renderer run |
| Primary journey size | 1600×900 |
| Constrained checks | 1280×720 normal and Large text |
| Full capture inventory | 25 states per viewport; 50 validated frames |
| Manifests | [`1280×720`](visual_evidence/v0.13.0-alpha-basin-vertical-slice/native-capture-1280x720.json), [`1600×900`](visual_evidence/v0.13.0-alpha-basin-vertical-slice/native-capture-1600x900.json) |

## Complete journey

### 1. Choose a caravan journey

![Main Menu](visual_evidence/v0.13.0-alpha-basin-vertical-slice/01_main_menu_1600x900.png)

The clean profile has one primary start action and states the trade-and-consequence premise before play.

### 2. Learn what the road changes

![Introduction](visual_evidence/v0.13.0-alpha-basin-vertical-slice/02_introduction_1600x900.png)

Three short illustrated cards teach local needs, caravan limits, roads, and promises without replacing the real game flow.

### 3. Read the Bazaar as a place

![Ashgate Bazaar](visual_evidence/v0.13.0-alpha-basin-vertical-slice/03_bazaar_1600x900.png)

Settlement identity, stall navigation, cargo, resources, local pressure, and ordinary trade share one game-facing scene.

### 4. Compare every legal itinerary

![Departure Desk](visual_evidence/v0.13.0-alpha-basin-vertical-slice/04_departure_1600x900.png)

Fee, time, provisions, cargo value, risk, confidence, and net consequence remain visible before commitment. Unfavorable routes are not hidden.

### 5. Travel through an in-between place

![Road observation](visual_evidence/v0.13.0-alpha-basin-vertical-slice/05_road_1600x900.png)

The selected road has its own corridor, landmark, progress, origin, destination, and status instead of bypassing travel.

### 6. Resolve a disclosed road problem

![Road event](visual_evidence/v0.13.0-alpha-basin-vertical-slice/06_event_1600x900.png)

Each response names its exact cost, expected outcome, and missing prerequisites. The event does not hide an extra damage system.

### 7. See the consequence

![Event result](visual_evidence/v0.13.0-alpha-basin-vertical-slice/07_event_result_1600x900.png)

The result holds long enough to read and connects the choice to the remaining journey.

### 8. Return to trade in a different place

![Destination Bazaar](visual_evidence/v0.13.0-alpha-basin-vertical-slice/08_arrival_bazaar_1600x900.png)

Arrival hands the caravan into a settlement-specific market, preserving the loop rather than ending at a report screen.

### 9. Finish with a causal replay prompt

![Campaign debrief](visual_evidence/v0.13.0-alpha-basin-vertical-slice/09_campaign_debrief_1600x900.png)

The ending explains the recent route, trade, resources, event decisions, regional consequence, causal lesson, and one concrete replay experiment.

## Constrained and Large text checks

![Departure at 1280×720](visual_evidence/v0.13.0-alpha-basin-vertical-slice/10_departure_1280x720.png)

![Departure with Large text at 1280×720](visual_evidence/v0.13.0-alpha-basin-vertical-slice/11_departure_large_text_1280x720.png)

![Event with Large text at 1280×720](visual_evidence/v0.13.0-alpha-basin-vertical-slice/12_event_large_text_1280x720.png)

The manifests validate that required controls remain inside the active layer. Scrollable detail is allowed; required state, decision context, and primary action may not be clipped.

## Use and limits

This set is suitable for test instructions, development history, and an alpha production journal. It is not final key art. The source remains procedural and replaceable, and the release notes retain the remaining human hardware, accessibility, comprehension, and storefront gates.

## 0.13.1 Departure clarity patch

The follow-up audit found that a hypothetical route forecast could look like cargo already aboard. The patch evidence records the empty-hold state at normal and Large text sizes.

![Departure plan distinguishes held cargo](visual_evidence/v0.13.1-alpha-basin-vertical-slice/departure-empty-plan-1600x900.png)

![Departure plan at Large text](visual_evidence/v0.13.1-alpha-basin-vertical-slice/departure-empty-plan-large-text-1280x720.png)

Full provenance is in the patch [`capture record`](visual_evidence/v0.13.1-alpha-basin-vertical-slice/README.md).

## 0.13.2 Large-text route selection patch

The constrained-window follow-up found that Large text could clip the selected card's literal `SELECTED` label. The patch restores the textual state without removing route consequences or displacing the pinned actions.

![Selected route remains explicit at 1600×900](visual_evidence/v0.13.2-alpha-basin-vertical-slice/departure-selected-large-text-1600x900.png)

![Selected route remains explicit at 1280×720](visual_evidence/v0.13.2-alpha-basin-vertical-slice/departure-selected-large-text-1280x720.png)

Full provenance is in the patch [`capture record`](visual_evidence/v0.13.2-alpha-basin-vertical-slice/README.md).

## 0.13.3 Bazaar trade ticket patch

The current visual audit found that the Market Stall's complete decision was correct but too paragraph-like. The structured ticket gives cargo, journey, route economics, risk, capacity, reason, and next action a deliberate scan order.

![Bazaar trade ticket at 1600×900](visual_evidence/v0.13.3-alpha-basin-vertical-slice/bazaar-trade-ticket-1600x900.png)

![Losing route remains explicit at 1280×720](visual_evidence/v0.13.3-alpha-basin-vertical-slice/bazaar-trade-ticket-loss-1280x720.png)

Full provenance is in the patch [`capture record`](visual_evidence/v0.13.3-alpha-basin-vertical-slice/README.md).

## 0.13.4 Roadside decision dossier patch

The encounter rail now turns the threat model into a compact dossier and removes repeated title/setup copy, bringing response cards closer to the visible road situation.

![Roadside dossier at 1600×900](visual_evidence/v0.13.4-alpha-basin-vertical-slice/roadside-dossier-1600x900.png)

![Roadside dossier with Large text](visual_evidence/v0.13.4-alpha-basin-vertical-slice/roadside-dossier-large-text-1280x720.png)

Full provenance is in the patch [`capture record`](visual_evidence/v0.13.4-alpha-basin-vertical-slice/README.md).

## 0.13.5 Responsive opening patch

Main Menu and Introduction now deliberately stack at 1280 pixels and below, keeping their complete default copy and actions inside the card. The preferred 1600×900 window retains the split scene with a wider action rail.

![Main Menu at 1280×720](visual_evidence/v0.13.5-alpha-basin-vertical-slice/main-menu-1280x720.png)

![Introduction with Large Text at 1280×720](visual_evidence/v0.13.5-alpha-basin-vertical-slice/introduction-road-large-text-1280x720.png)

![Introduction with Large Text at 1600×900](visual_evidence/v0.13.5-alpha-basin-vertical-slice/introduction-road-large-text-1600x900.png)

Full provenance is in the patch [`capture record`](visual_evidence/v0.13.5-alpha-basin-vertical-slice/README.md).

## 0.13.6 Licensed interface audio patch

Successful commands, blocked actions, and committed travel now use three short CC0 cues from the temporary asset kit. The visual flow is intentionally unchanged.

![Trade surface remains unchanged](visual_evidence/v0.13.6-alpha-basin-vertical-slice/trade-confirmation-surface-1280x720.png)

![Large Text event surface remains unchanged](visual_evidence/v0.13.6-alpha-basin-vertical-slice/route-event-large-text-1280x720.png)

Full provenance is in the patch [`capture record`](visual_evidence/v0.13.6-alpha-basin-vertical-slice/README.md).

## 0.13.7 Caravan departure dust patch

Committed travel now opens with a brief palette-tinted dust wake, then clears before the mandatory road stop and its next action.

![Caravan leaving Ashgate](visual_evidence/v0.13.7-alpha-basin-vertical-slice/caravan-departure-dust-1280x720.png)

![Dust cleared at the road stop](visual_evidence/v0.13.7-alpha-basin-vertical-slice/road-stop-1280x720.png)

Full provenance is in the patch [`capture record`](visual_evidence/v0.13.7-alpha-basin-vertical-slice/README.md).

## 0.13.8 Bazaar trade receipt patch

Successful purchases and sales now receive a brief stamped market receipt containing realized cargo, cash, and hold values.

![Purchase receipt at 1280×720](visual_evidence/v0.13.8-alpha-basin-vertical-slice/trade-receipt-1280x720.png)

![Purchase receipt with Large Text](visual_evidence/v0.13.8-alpha-basin-vertical-slice/trade-receipt-large-text-1280x720.png)

Full provenance is in the patch [`capture record`](visual_evidence/v0.13.8-alpha-basin-vertical-slice/README.md).

## 0.16.0 GPT-5.6 private-alpha campaign

The current candidate validates 86 release-facing states at 1600×900, spanning the clean opening, ordinary trade, route comparison, in-between travel, authored contact, changed market, optional black-market pressure, terminal receipt, all three regional sandboxes, and failure-forward replacement actors.

![Investment route comparison](visual_evidence/v0.16.0-private-alpha-2026-09-03/investment-departure-1600x900.png)

![Emberfen route comparison](visual_evidence/v0.16.0-private-alpha-2026-09-03/siltfire-emberfen-departure-desk-1600x900.png)

![Ash Sifter result](visual_evidence/v0.16.0-private-alpha-2026-09-03/siltfire-ash-sifter-result-1600x900.png)

The durable subset and complete manifest are in the [`0.16.0 capture record`](visual_evidence/v0.16.0-private-alpha-2026-09-03/README.md); the tagged release publishes all 86 frames as a separate archive.

## 0.16.1 responsive-shell and clean-trade revalidation

The post-RC2 1280×720 clipping finding is repaired. Introduction copy and actions remain inside the card with deliberate gutters, while the same clean save proceeds through ordinary purchase, route comparison, road consequence, changed markets, and a terminal receipt.

![Repaired Introduction at 1280×720](visual_evidence/v0.16.1-ma-i1-i2-revalidation-2026-09-03/1280x720/introduction-caravan-1280x720.png)

![Clean route comparison at 1280×720](visual_evidence/v0.16.1-ma-i1-i2-revalidation-2026-09-03/1280x720/investment-departure-1280x720.png)

![Terminal receipt at 1600×900](visual_evidence/v0.16.1-ma-i1-i2-revalidation-2026-09-03/1600x900/investment-terminal-receipt-1600x900.png)

The [`revalidation record`](visual_evidence/v0.16.1-ma-i1-i2-revalidation-2026-09-03/README.md) links the selected frames to complete 86-state manifests at both viewports.
