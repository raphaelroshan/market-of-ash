# Market of Ash — Implementation Status

**Baseline branch:** `a0-command-result-boundary`  
**Baseline commit:** `5859d89` (`docs: add GPT agent alpha handoff roadmap`)  
**Roadmap status:** A0–A1 foundations are implemented. Begin B0 only after this audit.

## Implemented player-facing spine

- Main Menu starts a deterministic Ashgate day-one playtest state.
- Settlement Shop owns local price inspection, buying, selling, cargo context, and the handoff to travel planning.
- Departure Desk owns the regional map, legal destination/route selection, route forecast, return-to-shop navigation, and travel commitment.
- Successful travel presents an arrival report before the player enters the destination shop.
- Runtime goods, settlements, route endpoints, and planning assumptions load from validated `content/runtime_world.json`.
- Prices and route forecasts are deterministic and explain their current inputs.
- Buy, sell, and departure mutations pass through a serializable command/result boundary.
- Saves declare save version 1 and content version `0.4.1`; unversioned saves migrate to version 1 and future saves fail safely.
- A deterministic 100-seed policy simulation records opening-route incentives and forecast error.

## Current command IDs

| Command ID | Owner | Current behavior |
| --- | --- | --- |
| `buy_goods` | `MarketCommandProcessor` | Validates good, quantity, capacity, settlement, and affordability; then mutates money/cargo. |
| `sell_goods` | `MarketCommandProcessor` | Validates good, quantity, held cargo, and settlement; then mutates money/cargo. |
| `depart_route` | `MarketCommandProcessor` | Validates destination and canonical route endpoints, charges fee/provisions, advances time, resolves one deterministic incident roll, and moves the caravan. |

Successful and failed commands append to `command_history`, bounded to 100 records.

## Current serialized fields

- `save_version`
- `content_version`
- `seed`
- `day`
- `money`
- `provisions`
- `cargo_capacity`
- `cargo`
- `current_settlement`
- `reputation`
- `crisis_stage`
- `log`
- `command_history`

Derived `crisis_modifiers`, runtime settlements, and runtime routes are rebuilt from authoritative content after load.

## Current content validators

- `tools/policy_check.py`
- `tools/validate_content.py --manifest content/content_manifest.json`
- `tools/validate_political_geography.py --data content/political_geography.json`
- `tools/validate_tribal_conflict.py --data content/tribal_conflict.json`
- `tools/validate_economy_and_settlements.py --economy content/economy_framework.json --settlements content/settlement_actions.json`
- `tools/validate_runtime_world.py --data content/runtime_world.json`

## Current test scripts

- `tests/test_economy.gd`: content loading, prices, crisis modifiers, capacity, route forecasts, command success/failure/history, route topology, travel resources, saves, and migration.
- `tests/test_map_ui.gd`: main-menu start, non-mutating forecast/navigation, guided purchase command use, Shop → Departure Desk transition, legal route filtering, forecast presentation, and route geometry.
- `tools/simulate_trade_policies.gd`: read-only 100-seed opening-policy simulation through the production command boundary.

## Current UI transitions

| From | Action | To | Authoritative mutation |
| --- | --- | --- | --- |
| Main Menu | Start Game | Settlement Shop | Creates deterministic fresh world state. |
| Settlement Shop | Buy / Sell | Settlement Shop | Yes, through command processor. |
| Settlement Shop | Plan Departure | Departure Desk | None. Planning selection is preserved. |
| Departure Desk | Return to Shop | Settlement Shop | None. |
| Departure Desk | Commit Departure | Arrival Report on map layer | Yes, through `depart_route`. |
| Arrival Report | Enter Settlement | Destination Settlement Shop | None beyond the completed departure command. |

## Roadmap-to-code mismatches

1. **Forecast/resolution units differ.** `MarketEconomy.route_profit_preview` calculates expected loss as route risk multiplied by the entire destination sale total. `MarketCommandProcessor._depart_route` removes at most one cargo unit. Large loads therefore receive a structurally pessimistic forecast.
2. **The loss basis is not exposed.** The forecast result has `risk` and `expected_loss`, but no stable loss-model label, cargo unit/value basis, or risk-source field for UI and tests.
3. **Incident cargo selection is order-based.** `_remove_first_cargo_unit` removes the first held good in canonical content order, not a disclosed cargo/value basis. Mixed-cargo forecast and resolution behavior is therefore underspecified.
4. **One charter reference is stale.** `docs/gpt_agent_handoff_roadmap.md` references `docs/alpha_release_roadmap.md`, which is not present. The active roadmap is `docs/gpt_agent_handoff_roadmap.md`.
5. **Roadmap fixtures are not present.** `tests/fixtures/` and its campaign-state fixtures are planned but not yet implemented.
6. **Godot is not installed on the default shell `PATH`.** CI uses Godot 4.4.1 on Ubuntu and Windows. The baseline was verified locally with a temporary Godot 4.4.1 binary, so future sessions must either reuse/provision that version or report the limitation explicitly.

## Baseline verification commands

```bash
bash scripts/verify.sh
python3 tools/policy_check.py --repo raphaelroshan/market-of-ash
python3 tools/validate_content.py --manifest content/content_manifest.json
python3 tools/validate_political_geography.py --data content/political_geography.json
python3 tools/validate_tribal_conflict.py --data content/tribal_conflict.json
python3 tools/validate_economy_and_settlements.py --economy content/economy_framework.json --settlements content/settlement_actions.json
python3 tools/validate_runtime_world.py --data content/runtime_world.json
godot --headless --path . --editor --quit
```

The most recent GitHub run at this baseline passed repository policy, Ubuntu and Windows Godot tests, AI review, and source packaging. Local results must still be recorded for every subsequent slice.

## Baseline verification result

Verified locally with Godot `4.4.1.stable.official.49a5bc7b6`:

- Economy suite: `PASS: Market of Ash economy tests`
- Map UI suite: `Map UI smoke: PASS`
- Headless editor import: completed successfully; Godot emitted a non-fatal shutdown warning after its filesystem scan.
- Repository policy: pass, with expected warnings for local `.godot/` import metadata.
- Content manifest, political geography, tribal conflict, economy/settlement, and runtime-world validators: pass.
- `git diff --check`: pass.

## Next permitted task

Card B0a: decide and document one shared forecast/resolution loss model before changing gameplay or balance.
