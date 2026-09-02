# Post-release map legibility pass

## Player-facing change

The network map no longer paints route names beneath settlement cards. Its compact key shows only the current region's roads in a dedicated strip below the route field, while the map heading contains only the region name and stays clear of Mothlight Quay. The small destination detail card appears only during pointer hover instead of remaining pinned over the network; the selected itinerary card remains the persistent source of full road name, fee, duration, provision cost, risk, confidence, and expected net result.

Large Text deliberately hides the compact key because the fully labeled itinerary cards are the accessible source of route details at that scale.

## Verification

- `tests/test_map_ui.gd` checks every compact key slot, its board/result boundaries, the concise heading against the top-row marker, and Large Text fallback behavior.
- Both runtime validators require every route's `map_label` to contain 1–12 characters; the Python fixture rejects an oversized label.
- Native 1600×900 and minimum-window 960×540 evidence is in `docs/visual_evidence/v0.15.0-map-legibility-2026-09-02/`.
