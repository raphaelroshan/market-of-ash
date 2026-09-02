# MA-GPT56-1 — Complete Creative Vertical

**Status:** Complete  
**Evaluation path:** `gpt56_clean_investment_vertical`  
**Seed:** `1107`  
**Next packet:** MA-GPT56-2 presentation and map identity

## Player result

A clean campaign now has one reproducible, player-facing arc from New Game and Introduction through an ordinary Water purchase, route comparison, Old Road departure, the Three Riders contact, Reedwatch arrival and sale, a profitable Grain return, an optional Cinder Rider arms sale, a public-audit recovery, and the `Order at the Cistern` terminal receipt. The destination price changes after supply and the final receipt remembers the route response, side deal, recovery, crew, pressure, and ending.

The same seed also completes a contract-free, ordinary-trade-only Water-and-Grain circuit without arms pressure. The restricted-cargo branch is therefore an optional parallel economy rather than a progression requirement.

## Authoritative ownership

- `src/core/world_state.gd` and `src/core/market_command_processor.gd` remain the owners of money, cargo, market pressure, travel, events, side-deal pressure, recovery, endings, serialization, and command history.
- `src/ui/main.gd` only presents those snapshots and routes player intent through existing commands. Its Introduction body now uses a wrapping `RichTextLabel`, and responsive opening layout is selected from the physical/browser window width rather than the fixed logical canvas.
- `tools/capture_native_ui.gd` drives the normal UI handlers. It does not call a debug fixture or mutate an outcome into existence.

## Deterministic acceptance

`tests/test_investment_vertical.gd` executes both branches and round-trips serialized state at purchase, pending event, arrival, changed market, completed circuit, black-market consequence, recovery, every later road resolution, and terminal outcome. It verifies the named seed, profitable ordinary trade, optional arms pressure, disclosed Toll Road surcharge and recovery, and the causal terminal debrief.

`tools/validate_native_captures.py` requires distinct screenshots for departure, road stop, event, arrival, changed return Bazaar, black-market offer, visible arms pressure, and terminal receipt. It rejects missing or out-of-bounds Introduction body copy as well as incorrect journey semantics.

## Verification record

- `test_map_ui.gd`: `Map UI smoke: PASS`
- `test_investment_vertical.gd`: `Investment creative vertical: PASS (gpt56_clean_investment_vertical, seed 1107)`
- 1280×720 native capture: `Native UI captures: PASS (1280x720)`
- 1280×720 validator: `Native UI render validation: PASS`
- 1600×900 native capture: `Native UI captures: PASS (1600x900)`
- 1600×900 validator: `Native UI render validation: PASS`

The full repository gate remains `MARKET_GODOT_BIN=/path/to/godot ./scripts/verify.sh` and must pass before merge.

## Evidence and accessibility

The versioned evidence directory contains the 1600×900 introduction and complete investment journey. The temporary licensed audio and particle assets already documented by the project remain in use; this packet adds no generated or unlicensed asset.

Existing controller, keyboard, Large Text, and Reduce Travel Motion suites remain authoritative. The native manifest additionally records focused-control bounds and required control bounds for the opening and every journey state.

## Known deficiencies

- Presentation remains code-native production scaffolding; MA-GPT56-2 owns stronger authored settlement, route, risk, and arrival identity.
- The canonical fixture chooses one safe event response for repeatability and is not a balance claim.
- Human comprehension, physical-controller, assistive-technology, and high-DPI hardware testing remain release calibration rather than automated certification.

## Balance observation

The ordinary control finishes above its 120-ashmark starting cash with no contract and zero arms escalation. The side deal provides an 82-ashmark temptation, raises arms pressure by two, and makes the Toll Road visibly more expensive until the public audit reduces pressure. This creates a meaningful optional tradeoff without invalidating the ordinary circuit.
