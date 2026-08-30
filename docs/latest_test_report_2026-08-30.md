# Market of Ash — Basin Vertical-Slice Test Report

## Candidate

| Field | Result |
|---|---|
| Release | `v0.13.0-alpha-basin-vertical-slice` |
| Engine | Godot 4.4.1 |
| Content | Runtime content `1.22.0`; save schema `12` |
| Desktop target | Windows x86-64 portable executable and ZIP |
| Verification surfaces | macOS real renderer, Linux/Windows headless CI, Windows packaged GUI, Chrome, Firefox, and Edge |
| Release claim | Public prerelease for limited alpha testing; not storefront-ready |

## Result

The automated M1–M10 vertical-slice scope passes. A clean player path can move from the title through the illustrated introduction, ordinary Bazaar trade, selectable itinerary comparison, a mandatory road beat, an authored encounter, arrival, a changed destination market, and a causal campaign debrief. The same systems retain the optional-contract path, adaptive Well Commons response, save/load and backup recovery, keyboard/controller navigation model, reduced motion, Large text, privacy-safe report export, and deterministic replay evidence.

The final local real-renderer run produced and validated 25 states at 1280×720 and the same 25 states at 1600×900. The curated 1600×900 sequence and constrained Large text checks are stored under [`docs/visual_evidence/v0.13.0-alpha-basin-vertical-slice/`](visual_evidence/v0.13.0-alpha-basin-vertical-slice/). The two native manifests preserve the complete state inventory, requested and captured viewport, platform, display scale, focus rectangle, required-control bounds, and UI state for every frame.

## Representative flow

![Main menu](visual_evidence/v0.13.0-alpha-basin-vertical-slice/01_main_menu_1600x900.png)

![Bazaar](visual_evidence/v0.13.0-alpha-basin-vertical-slice/03_bazaar_1600x900.png)

![Departure comparison](visual_evidence/v0.13.0-alpha-basin-vertical-slice/04_departure_1600x900.png)

![Road encounter](visual_evidence/v0.13.0-alpha-basin-vertical-slice/06_event_1600x900.png)

![Campaign debrief](visual_evidence/v0.13.0-alpha-basin-vertical-slice/09_campaign_debrief_1600x900.png)

## Verification performed

- `python3 tests/test_windows_export_validation.py` — PASS.
- Godot `tests/test_map_ui.gd` — PASS with the new game-version assertion.
- `scripts/capture_native_ui.sh` at 1280×720 and 1600×900 — PASS, 50 validated frames total.
- The repository-wide `scripts/verify.sh` gate covers policy, content schemas and fixtures, economy, UI, tutorial, controller, save migration/recovery, campaign, deterministic replay, privacy-safe report, and release validators.
- Pull-request CI additionally clean-extracts and launch-smokes the Windows ZIP, validates the visible Windows GUI and version resources, packages Web output, and traverses the browser build in Chrome, Firefox, and Edge.

## Honest limitations

- The art and animation are original procedural alpha presentation, not final commercial art.
- The package is portable and unsigned; there is no installer, auto-update path, Steam/Epic integration, or code-signing reputation yet.
- Physical-controller feel, Windows high-DPI hardware, screen-reader use, antivirus reputation, and storefront behavior still require human device testing.
- Automated traversal proves deterministic operation and visible bounds, not player comprehension or fun. Moderated first-time-player sessions remain the next evidence gate.
- This is one basin: five settlements, three route families, seven goods, four authored route-event families, and five endings. It is a strong vertical slice, not the complete campaign.

## Release interpretation

This report supports publishing a prerelease test artifact. It does not make a commercial-readiness claim. The release manifest, packaged Windows metadata, source archive, and SHA-256 file bind the downloadable artifact to its exact tagged commit and CI run.
