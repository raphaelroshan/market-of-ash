# Alpha Accessibility and Input Audit

**Build:** `0.9.0-alpha-roadmap`  
**Scope:** Main Menu → Settlement Shop → Departure Desk → Route Event/Arrival → Settlement Shop  
**Status:** Automated checks pass; the hardware/rendered checks below remain release-candidate gates.

## Implemented safeguards

| Area | Current behavior | Evidence |
| --- | --- | --- |
| Keyboard | Tab/directional navigation uses Godot focus traversal; Enter and Space activate the focused control; Escape returns from uncommitted departure planning or pauses elsewhere; P always pauses during play. | `tests/test_map_ui.gd` and `project.godot` input-map assertions. |
| Controller | D-pad/stick focus traversal uses Godot UI actions; A accepts, B goes back/pauses, and Menu pauses during play. | Controller bindings are source controlled and asserted by the UI smoke test. |
| Focus continuity | Shop, Departure Desk, route decisions, and arrival each establish a predictable enabled focus target. | UI smoke assertions cover every transition. |
| Reduced motion | A persisted Main Menu option skips caravan interpolation and presents the completed route immediately without changing simulation time or outcome. | UI smoke test checks completed progress, no active animation, and settings-file round trip. |
| Text size/reflow | A persisted Main Menu option increases inherited and explicit interface text by 25%; the long Shop and Departure rails use vertical scrolling. | UI smoke test checks scaling without campaign mutation, settings-file round trip, and both rails' scroll ancestors. |
| Color independence | Money, provisions, risk, crisis, standing, escalation, disabled reasons, and outcomes are always written as text; color is supplementary. | Static UI inspection and UI text assertions. |
| Timing | No choice has a real-time deadline. Travel motion never blocks `Enter settlement`, and reduced motion can remove it. | Command/UI architecture and reduced-motion test. |
| Save recovery | Successful commands autosave through a temporary file and keep one backup generation; manual Save and Load expose day, settlement, save version, and content version. Invalid or newer files are validated in a candidate world and cannot replace the active run. | UI smoke tests missing, valid, corrupt-primary recovery, future-version rejection, and autosave paths; core save normalization tests. |
| Pause | A modal layer stops the scene tree, reports current run/save context, and offers Resume, Save, Load, and Return to main menu. Event decisions remain pending underneath it. | UI smoke checks paused state, Resume focus, focus restoration, and event preservation. |

## Manual input matrix

Run this against the packaged Windows build before sharing an alpha. Record device model, Windows version, display scale, build commit, and seed.

| Flow | Mouse | Keyboard | Controller | Pass condition |
| --- | --- | --- | --- | --- |
| Main Menu → Start | Click | Tab, Enter/Space | D-pad/stick, A | Starts in Shop with cargo selector focused. |
| Shop trade | Click selectors/buttons | Tab/arrows, Enter/Space | D-pad/stick, A | Price explanation remains visible; buy/sell result and autosave status update. |
| Shop → Departure | Click | Focus Plan departure, Enter/Space | Focus Plan departure, A | Destination receives focus; no resources change. |
| Departure edit/back | Click / Return button | Selectors; Escape | Selectors; B | Legal routes update; back restores Shop focus and does not mutate state. P/Menu opens Pause. |
| Commit/event | Click | Focus Commit, Enter/Space | Focus Commit, A | First enabled event response receives focus; disabled reason remains visible as adjacent text. |
| Arrival | Click Enter settlement | Enter/Space | A | Entry action receives focus and returns to the destination Shop. |
| Save/load | Click | Tab, Enter/Space | D-pad/stick, A | Summary identifies day/location/version; bad save leaves current run intact. |

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

1. Large-text reflow and scrolling are implemented but still need rendered checks at minimum window and high OS scaling for clipping and comfortable line length.
2. Controller behavior is configured and headlessly asserted but has not been exercised on physical Windows hardware.
3. Runtime input remapping is not implemented yet; the pause layer currently exposes the fixed bindings. Accessibility preferences persist in a separate settings file.
4. Audio cues and screen-reader semantics are not implemented; essential information remains available as text.

## Remapping plan

Keep gameplay code bound only to named actions. Add a Settings screen that listens for a replacement input, rejects reserved OS shortcuts, preserves at least one binding for Accept and Cancel, writes mappings to a separate user settings file, and offers Restore Defaults. Never serialize device-specific mappings into campaign saves.

## Release-candidate record

For each candidate, attach:

- commit and artifact/run URL;
- Godot and content/save versions;
- seed(s) exercised;
- Windows clean-launch result;
- completed rows from both matrices;
- any clipping, focus loss, unreadable state, or save recovery defect with reproduction steps.
