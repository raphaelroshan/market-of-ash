# Alpha Accessibility and Input Audit

**Build:** `0.9.0-alpha-roadmap`  
**Scope:** Main Menu → Settlement Shop → Departure Desk → Route Event/Arrival → Settlement Shop  
**Status:** Automated checks pass; the hardware/rendered checks below remain release-candidate gates.

## Implemented safeguards

| Area | Current behavior | Evidence |
| --- | --- | --- |
| Keyboard | Tab/directional navigation uses explicit primary-screen cycles plus Godot focus traversal. Accept, Back, and Pause keys can be rebound from the Main Menu; conflicting or modified shortcuts are rejected, defaults can be restored, and preference-write failures are shown without undoing the current-session choice. | UI smoke exercises focus order, remapping, conflict rejection, persistence, write failure, and default restoration. |
| Controller | D-pad/stick focus traversal uses explicit vertical neighbors as well as Tab-order links; Left/Right adjusts focused quantities. Accept, Back, and Pause controller buttons can be rebound independently from keyboard keys; conflicting buttons and D-pad directions are rejected. | UI smoke exercises remapping, conflict/navigation reservation, persistence, keyboard preservation, and default restoration. A dedicated input smoke dispatches joypad A/B/Menu/D-pad events through Godot and verifies Start, quantity adjustment, reversible navigation, Pause/Resume, a Medicine purchase, Toll Road commitment, Gatekeeper event resolution, and destination entry. Physical-device verification remains open. |
| Pointer targets | Selectors and utility actions use a 44-logical-pixel minimum, primary trade/journey controls are larger and wrapped, and settlement markers keep separate visible and expanded hit rectangles. | UI smoke asserts menu, Shop, Pause, and Departure control minimums, non-overlapping marker label bounds, and a 60-logical-pixel marker hit height, which scales to 45 px at the 960×540 browser target. |
| Focus continuity | Shop, Departure Desk, route decisions, and arrival each establish a predictable enabled focus target. Pause owns focus while open; Resume restores the prior control when it still exists and falls back safely when a save/load refresh rebuilt it. Changing text size re-reveals the currently focused control inside its scroll rail. | UI smoke assertions cover every transition, modal focus isolation, the dynamic-control lifetime case, and a large-text event-choice visibility regression. |
| Reduced motion | A persisted Main Menu option skips caravan interpolation and presents the completed route immediately without changing simulation time or outcome. | UI smoke test checks completed progress, no active animation, and settings-file round trip. |
| Text size/reflow | A persisted Main Menu option increases inherited, explicit, and custom-drawn map text by 25%; launch controls remain above optional settings, combined keyboard/controller labels and long dynamic actions wrap across lines, Shop/Departure details scroll vertically, primary trade/journey/arrival actions remain pinned, and the map reserves separate header/footer strips for its scaled legend text. | UI smoke checks map font scaling and non-overlapping instruction, heading, marker, route-key, and result bounds, plus wrapped binding controls, Buy, Plan, Commit, Return, Enter Settlement, focused event-choice visibility, scaling without campaign mutation, settings-file round trip, and scroll ancestors. CI run 200 adds 84 packaged-browser frames: the complete 14-state normal/Large text/event/result matrix at both 960×540 and 1280×720 in Chrome, Firefox, and Edge. |
| Color independence | Money, provisions, risk, crisis, current map location, settlement resilience, standing, escalation, disabled reasons, and outcomes are always written as text; color is supplementary. Disabled route-event prerequisites remain persistently visible rather than tooltip-only. | Static UI assertions plus 18 generated grayscale/protanopia/deuteranopia review frames for the constrained 960×540 Main Menu, Shop, Departure, event/result, and confirmation states. Manual inspection kept route names, `HERE`/resilience labels, focus borders, disabled explanations, and action text legible; the filters are approximate and do not replace testing with color-vision-deficient players. |
| Timing | No choice has a real-time deadline. Travel motion never blocks `Enter settlement`, and reduced motion can remove it. | Command/UI architecture and reduced-motion test. |
| Audio | Restrained generated cues distinguish successful commands/file operations, blocked actions/save failures, and committed travel. A persisted Main Menu switch disables them immediately; all essential outcomes remain available as text. | UI smoke checks cue setup, save/load/report outcomes, autosave warnings, mute behavior, and settings-file round trip. |
| Web assistive access | The Web export maintains a polite ARIA status region and descriptive canvas label for Main Menu, Shop, Departure, route-event, arrival, Pause, and destructive confirmation transitions. A visually hidden region becomes visible on focus and exposes current primary/safety-critical and generated Shop actions as real HTML buttons, Shop/Departure planning as labeled select/number controls, Main Menu presentation settings as native checkboxes, and keyboard remapping actions with live instructions. Labels, options, values, integer bounds, enabled states, linked descriptions, input bindings, and screen-specific ordering mirror Godot; interaction routes through the existing Godot controls and handlers. | Headless UI tests verify state-specific announcements and control inventories, invalid input rejection, bounds clamping, presentation-state changes, remapping conflicts/default restoration, and Shop/Departure synchronization. CI runs 224–227 progressively operate generated actions, presentation checkboxes, and keyboard remapping while requiring exact DOM/Godot parity and focus continuity in Chrome, Firefox, and Edge. The 960×540 journey also changes planning fields; 1280×720 retains independent canvas-pointer coverage. Hands-on assistive-technology and physical-controller review remain open. |
| Native rendered layout | A real-renderer Godot harness captures Main Menu, Shop, Pause, Departure, non-mutating return, Gatekeeper event/result, destination Shop, and new-game confirmation, including Large text coverage, at 960×540, 1280×720, and 1920×1080. It records display scale, viewport, UI state, and layout geometry and rejects wrong dimensions, missing states, visually unchanged transitions, or a map overlapping its instructions/result. | `MARKET_GODOT_BIN=/path/to/godot ./scripts/capture_native_ui.sh /tmp/market-of-ash-native-render`; the current local macOS/OpenGL run covers 42 frames at Retina display scale 2.0. CI run 205 adds 14 inspected Windows/ANGLE frames at the exact minimum 960×540 viewport. |
| Save recovery | Successful commands autosave through a temporary file and keep one backup generation; stale or failed temporary files are removed, while manual Save and Load expose day, settlement, save version, and content version. An autosave failure is promoted into the immediate command result with a warning cue instead of remaining below the fold. Oversized, invalid, or newer files are rejected before parsing into a candidate world and cannot replace the active run. | UI smoke tests missing, valid, corrupt-primary recovery, oversized, future-version, stale-temp replacement, successful autosave, and command-success/save-failure cleanup paths; core save normalization tests. |
| Pause | A modal layer stops the scene tree, reports current run/save context, and offers Resume, Save, Load, and Return to main menu. Event decisions remain pending underneath it; failed save/exit and load attempts keep the overlay open with their reason instead of discarding or obscuring the live session. | UI smoke checks paused state, Resume focus, successful-load focus, event preservation, and failed save/load protection. |
| Feedback capture | Shop and Pause export a versioned JSON report with exact packaged commit/run, platform, broad last-input type, active key/button mappings, viewport, presentation settings, session/first-trade timing, seed, state summary, contracts, events, route conditions, information, crew, ending context, commands, and game log; no personal or controller identifiers are collected. Pause displays success or failure and the local output path without closing. | UI smoke parses the report, verifies the environment, input mappings, and reconstruction evidence, and checks visible success/failure feedback while asserting no campaign mutation. |

## Manual input matrix

Run this against the packaged Windows build before sharing an alpha. Record device model, Windows version, display scale, build commit, and seed.

| Flow | Mouse | Keyboard | Controller | Pass condition |
| --- | --- | --- | --- | --- |
| Main Menu → Start | Click | Tab, Enter/Space | D-pad/stick, A | Starts in Shop with cargo selector focused. |
| Remap input | Click a binding, press a key or controller button | Focus a binding, accept, then press an unmodified key | Focus a binding, A, then press a non-D-pad button | The relevant keyboard or controller binding changes independently; conflicts and navigation inputs are rejected; Restore Defaults repairs both schemes. |
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

1. CI run 227 completed the latest fully certified cross-engine packaged Web matrix: 84 captures cover 14 normal/Large text/event/result states at exact 960×540 and 1280×720 viewports in Chrome, Firefox, and Edge, require matching app/ARIA/action/form/binding state and semantic order, operate semantic actions, a generated contract action, planning fields, presentation checkboxes, keyboard remapping, and default restoration at the minimum viewport, and use decoded pixels to reject superficial transitions. A local real-renderer matrix adds 42 inspected macOS/OpenGL frames across 960×540, 1280×720, and 1920×1080 at Retina display scale 2.0; CI run 205 adds 14 inspected Windows/ANGLE frames at 960×540. Remaining visual gates are Windows 125%, 150%, and 200% OS scaling plus hands-on browser shortcut and assistive-technology review.
2. Controller behavior is configured and headlessly asserted but has not been exercised on physical Windows hardware.
3. Web builds announce screen changes and expose primary/safety-critical buttons, generated Shop actions, Shop/Departure selectors and quantities, presentation checkboxes, keyboard remapping, and default restoration through semantic HTML. The mirror is automation-verified rather than screen-reader-verified. Controller remapping is automated but still needs physical-device verification; essential information remains available as text, and interface cues are supplementary and can be disabled.
4. CI structurally validates the packaged x86-64 Windows PE, while run 205 rendered and validated the full 14-state minimum-window UI journey through Windows ANGLE. Run 210 additionally launched the packaged GUI visibly, verified `Market of Ash` and `0.9.0.0` in its PE resources, captured the exact 960×540 client area, and produced a visually inspected neutral Main Menu without desktop leakage. Run 212 then built a single-file portable ZIP, rejected unexpected archive members, clean-extracted it outside the checkout, and ran both headless and visible-GUI checks from that extracted copy; manual release workflow run `33149086304` passed the same path. Physical antivirus/reputation, installer/storefront behavior, and the documented OS-scaling matrix remain manual Windows gates.

## Remapping plan

Gameplay code remains bound only to named actions. The Main Menu remapper changes either the keyboard or controller binding for Accept, Back, and Pause while preserving the other input family. It rejects modified/reserved/conflicting keys, conflicting controller buttons, and D-pad directions; writes both mappings to the separate user settings file; and offers Restore default inputs. Invalid persisted sets fall back atomically to the complete defaults. Campaign saves never contain device-specific mappings.

## Release-candidate record

For each candidate, attach:

- commit and artifact/run URL;
- Godot and content/save versions;
- seed(s) exercised;
- Windows clean-launch result;
- completed rows from both matrices;
- any clipping, focus loss, unreadable state, or save recovery defect with reproduction steps.
