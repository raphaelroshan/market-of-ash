# Alpha Accessibility and Input Audit

**Build:** `0.9.0-alpha-roadmap`  
**Scope:** Main Menu → Settlement Shop → Departure Desk → Route Event/Arrival → Settlement Shop  
**Status:** Automated checks pass; the hardware/rendered checks below remain release-candidate gates.

## Implemented safeguards

| Area | Current behavior | Evidence |
| --- | --- | --- |
| Keyboard | Tab/directional navigation uses Godot focus traversal. Accept, Back, and Pause keys can be rebound from the Main Menu; conflicting or modified shortcuts are rejected and defaults can be restored. | UI smoke exercises remapping, conflict rejection, persistence, and default restoration. |
| Controller | D-pad/stick focus traversal uses Godot UI actions; A accepts, B goes back/pauses, and Menu pauses during play. | Controller bindings are source controlled and asserted by the UI smoke test. |
| Pointer targets | Primary trade/journey controls use enlarged wrapped buttons, while settlement markers keep separate visible and expanded hit rectangles. | UI smoke asserts action minimum sizes, non-overlapping marker label bounds, and a 60-logical-pixel marker hit height, which scales to 45 px at the 960×540 browser target. |
| Focus continuity | Shop, Departure Desk, route decisions, and arrival each establish a predictable enabled focus target. Pause owns focus while open; Resume restores the prior control when it still exists and falls back safely when a save/load refresh rebuilt it. Changing text size re-reveals the currently focused control inside its scroll rail. | UI smoke assertions cover every transition, modal focus isolation, the dynamic-control lifetime case, and a large-text event-choice visibility regression. |
| Reduced motion | A persisted Main Menu option skips caravan interpolation and presents the completed route immediately without changing simulation time or outcome. | UI smoke test checks completed progress, no active animation, and settings-file round trip. |
| Text size/reflow | A persisted Main Menu option increases inherited, explicit, and custom-drawn map text by 25%; launch controls remain above optional settings, long Shop context and Departure content scroll vertically, primary trade/journey/arrival actions remain pinned, long dynamic action labels wrap across lines, and the map reserves separate header/footer strips for its scaled legend text. | UI smoke checks map font scaling and non-overlapping instruction, heading, marker, route-key, and result bounds, plus Buy, Plan, Commit, Return, Enter Settlement, focused event-choice visibility, scaling without campaign mutation, settings-file round trip, scroll ancestors, and wrapped controls; packaged browser captures cover the 960×540 baseline layout. |
| Color independence | Money, provisions, risk, crisis, current map location, settlement resilience, standing, escalation, disabled reasons, and outcomes are always written as text; color is supplementary. Disabled route-event prerequisites remain persistently visible rather than tooltip-only. | Static UI inspection and UI text assertions. |
| Timing | No choice has a real-time deadline. Travel motion never blocks `Enter settlement`, and reduced motion can remove it. | Command/UI architecture and reduced-motion test. |
| Audio | Restrained generated cues distinguish successful commands/file operations, blocked actions/save failures, and committed travel. A persisted Main Menu switch disables them immediately; all essential outcomes remain available as text. | UI smoke checks cue setup, save/load/report outcomes, autosave warnings, mute behavior, and settings-file round trip. |
| Save recovery | Successful commands autosave through a temporary file and keep one backup generation; manual Save and Load expose day, settlement, save version, and content version. An autosave failure is promoted into the immediate command result with a warning cue instead of remaining below the fold. Oversized, invalid, or newer files are rejected before parsing into a candidate world and cannot replace the active run. | UI smoke tests missing, valid, corrupt-primary recovery, oversized, future-version, successful autosave, and command-success/save-failure paths; core save normalization tests. |
| Pause | A modal layer stops the scene tree, reports current run/save context, and offers Resume, Save, Load, and Return to main menu. Event decisions remain pending underneath it; failed save/exit and load attempts keep the overlay open with their reason instead of discarding or obscuring the live session. | UI smoke checks paused state, Resume focus, successful-load focus, event preservation, and failed save/load protection. |
| Feedback capture | Shop and Pause export a versioned JSON report with exact packaged commit/run, platform, broad last-input type, viewport, presentation settings, session/first-trade timing, seed, state summary, contracts, events, route conditions, information, crew, ending context, commands, and game log; no personal identifiers are collected. Pause displays success or failure and the local output path without closing. | UI smoke parses the report, verifies the environment and reconstruction evidence, and checks visible success/failure feedback while asserting no campaign mutation. |

## Manual input matrix

Run this against the packaged Windows build before sharing an alpha. Record device model, Windows version, display scale, build commit, and seed.

| Flow | Mouse | Keyboard | Controller | Pass condition |
| --- | --- | --- | --- | --- |
| Main Menu → Start | Click | Tab, Enter/Space | D-pad/stick, A | Starts in Shop with cargo selector focused. |
| Remap keyboard | Click a binding, press a key | Focus a binding, Enter/Space, then press an unmodified key | Controller remains available but is not remapped | New label and controls hint update; conflict/navigation keys are rejected; Restore Defaults repairs the original scheme. |
| Shop trade | Click selectors/buttons | Tab/arrows, Enter/Space | D-pad/stick, A | Price explanation remains visible; buy/sell result and autosave status update. |
| Shop → Departure | Click | Focus Plan departure, Enter/Space | Focus Plan departure, A | Destination receives focus; no resources change. |
| Departure edit/back | Click / Return button | Selectors; Escape | Selectors; B | Legal routes update; back restores Shop focus and does not mutate state. P/Menu opens Pause. |
| Commit/event | Click | Focus Commit, Enter/Space | Focus Commit, A | First enabled event response receives focus; disabled reason remains visible as adjacent text. |
| Arrival | Click Enter settlement | Enter/Space | A | Entry action receives focus and returns to the destination Shop. |
| Save/load | Click | Tab, Enter/Space | D-pad/stick, A | Summary identifies day/location/version; bad save leaves current run intact. |
| Reset | Click, confirm/cancel | Focus Reset, Enter/Space, then confirm/cancel | D-pad/stick, A/B | Opening the dialog does not mutate state; cancel preserves the run; confirmation explains when the previous disk save will be replaced. |

## Manual visual/accessibility matrix

| Check | Required configurations | Pass condition |
| --- | --- | --- |
| Window scaling | 1280×720, 1920×1080, and minimum 960×540 | No primary action, selected value, result, or save status is clipped. |
| OS scaling | Windows 100%, 125%, 150%, 200% | Text remains readable and controls do not overlap. |
| Color vision | Grayscale plus protan/deutan simulation | Every state and warning remains identifiable from words and numbers. |
| Long content | All three crew offers, active contract, and each four-choice route event | Controls and disabled explanations remain reachable and readable. |
| Reduced motion | Off and on | Off is brief and non-blocking; on removes interpolation with identical state results. |
| Web build | Current Chrome, Edge, Firefox | Keyboard focus is visible; browser shortcuts do not prevent normal play. |

## Open alpha blockers

1. The last successful CI run captures the packaged Web Main Menu and initial Settlement Shop at 960×540 and 1280×720 after confirming the loading overlay clears and the canvas accepts the Start action. The current workflow also drives the focused Plan action by keyboard, captures the Departure Desk, and uses decoded-pixel comparison to reject focus-only transitions; that extension awaits a runner after the account billing/spend gate is cleared. The headless UI path separately asserts meaningful pinned Buy, Plan, Commit, and Return geometry. Event/arrival states, rendered large-text line wrapping, and high OS scaling still need human review.
2. Controller behavior is configured and headlessly asserted but has not been exercised on physical Windows hardware.
3. Controller remapping and screen-reader semantics are not implemented; essential information and fixed controller bindings remain available as text. Interface cues are supplementary and can be disabled.

## Remapping plan

Gameplay code remains bound only to named actions. The current Main Menu remapper changes keyboard bindings, rejects modifier/reserved/conflicting shortcuts, preserves controller mappings and at least one key for every required action, writes mappings to the separate user settings file, and offers Restore Defaults. Campaign saves never contain device-specific mappings. A later settings screen can expand this to controller rebinding without changing gameplay code.

## Release-candidate record

For each candidate, attach:

- commit and artifact/run URL;
- Godot and content/save versions;
- seed(s) exercised;
- Windows clean-launch result;
- completed rows from both matrices;
- any clipping, focus loss, unreadable state, or save recovery defect with reproduction steps.
