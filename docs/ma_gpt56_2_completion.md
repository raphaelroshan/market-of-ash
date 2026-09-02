# MA-GPT56-2 — Presentation and Map Identity

**Status:** Complete  
**Next packet:** MA-GPT56-3 market breadth and non-railroaded play

## Player result

Every authored settlement now resolves through one visual registry for its landmark motif, market accent, and arrival treatment. Every road resolves through the same registry for its scene, texture vocabulary, accent, and readable low/guarded/high exposure cue. Arrival markers now inherit their destination identity instead of using one generic treatment.

The Bazaar canvas is isolated in `src/ui/bazaar_scene.gd`; the network and road canvas is isolated in `src/ui/journey_map_panel.gd`; and `src/ui/journey_panel_view.gd` owns the read-only presentation state for planning, departure, road stop, event, approach, and arrival. `main.gd` remains the interaction coordinator. No extracted view can spend money, mutate cargo, roll risk, resolve an event, or write a save.

## Acceptance contract

- `tests/test_visual_registry.gd` rejects missing settlement motifs, accents, arrival treatments, regional patterns, risk symbols, route scenes, or route textures.
- `tests/test_presenters.gd` checks the extracted journey view across departure, road, event, and arrival states.
- `tests/test_map_ui.gd` preserves keyboard/controller focus and Large Text behavior after extraction.
- Native capture manifests publish `settlement_motif`, `arrival_treatment`, `route_texture`, and `risk_cue`; the investment screenshots require the correct Old Road, Reedwatch, and Ashgate identity.
- The same journey is captured at 1280×720 and 1600×900 from source Bazaar through return Bazaar.

The durable capture sequence is in `docs/visual_evidence/v0.15.0-ma-gpt56-2-2026-09-03/`, separated by viewport.

## Temporary assets and deficiencies

The existing CC0 departure dust and interface cues remain documented in `assets/temporary/manifest.json`. No new temporary asset was introduced. Settlement and road scenes are still procedural placeholders; their stable registry identifiers are the replacement seam for later commissioned art.

## Verification

Run `MARKET_GODOT_BIN=/path/to/godot ./scripts/verify.sh`, followed by `scripts/capture_native_ui.sh` for the 1280×720 and 1600×900 evidence matrix.
