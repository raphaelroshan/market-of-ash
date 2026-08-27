# Forecast and Route-Incident Resolution Contract

**Roadmap slice:** B0a  
**Status:** Approved design for B0b implementation  
**Decision owner:** `MarketEconomy`

## Player-facing objective

Before committing travel, the player sees the same cargo-loss model that the route resolver will apply. The forecast names the exposed unit, its destination value, the route risk, and the source of that risk. A route incident remains bounded to one unit so an early unlucky journey creates a setback rather than a campaign-ending loss.

## Current mismatch

The current forecast calculates:

```text
expected_loss = round(destination sale value of the whole selected load × route risk)
```

The current resolver instead removes at most one cargo unit. The forecast therefore becomes increasingly pessimistic as quantity rises even though resolved loss remains fixed at one unit.

## Compared choices

### Choice A — Preserve one-unit incidents

```text
exposed unit = highest destination-value unit currently carried
expected_loss = round(route risk × exposed unit destination value)
resolved incident loss = exactly that exposed unit
```

- **Inputs:** held cargo, destination price context, route risk, canonical good order.
- **Player wording:** “One Medicine unit is exposed, valued at 52 ashmarks at Reedwatch. At 35% risk, expected cargo loss is 18.”
- **Determinism:** select the carried good with the highest destination unit value; break equal-value ties using canonical `MarketContent.good_ids()` order.
- **Mixed cargo:** one unit of the highest destination-value carried good is exposed and named before departure.
- **Zero cargo:** no unit is exposed, expected cargo loss is zero, and travel remains legal.
- **Low quantity:** one carried unit remains the maximum incident loss.
- **High-value cargo:** the higher unit value is visible and raises expected loss without threatening the entire load.
- **Save/replay:** no new authoritative state is required. Cargo, day, crisis modifiers, destination, route, seed, and command history already serialize. The resolved result records the chosen basis and value.
- **Trade-off:** always exposing the highest-value unit is conservative and predictable. It is not a physical cargo-position simulation, but it avoids hidden order-dependent loss.

### Choice B — Preserve whole-load value forecasting

```text
expected_loss = round(destination sale value of the whole selected load × route risk)
resolved incident loss = enough cargo value to make the conditional incident loss match the forecast model
```

- **Inputs:** full held manifest, destination prices, route risk, a deterministic removal ordering, and partial-value rounding rules.
- **Player wording:** “Approximately 35% of this load’s value is exposed.”
- **Determinism:** requires a stable algorithm for removing several whole cargo units until a target value is met.
- **Mixed cargo:** needs policy for over/under-shooting the target value and selecting among goods.
- **Zero cargo:** expected and resolved loss are zero.
- **Low quantity:** matching the forecast often means losing the entire load on an incident.
- **High-value cargo:** preserves the existing calculation but produces severe early losses unless route risk and recovery systems are retuned.
- **Save/replay:** resolved removal order and value target must be recorded to make incidents auditable.
- **Trade-off:** larger implementation and balance change; materially increases punishment and conflicts with the alpha recovery principle.

## Decision

Use **Choice A: one exposed unit**.

`MarketEconomy` owns two pure helpers:

1. `incident_loss_basis(cargo, destination, world)` selects and values the exposed unit.
2. `expected_incident_loss(route, loss_basis)` calculates the rounded expected loss.

Both `route_profit_preview` and `MarketCommandProcessor._depart_route` call these helpers. The command processor performs mutation only after all route preconditions pass. It does not independently choose cargo or calculate value.

## Data returned to UI and command history

Every valid route forecast exposes:

```gdscript
{
    "loss_model": "one_exposed_unit",
    "loss_good_id": "medicine",
    "loss_quantity": 1,
    "loss_unit_value": 52,
    "loss_value_basis": "destination_unit_price",
    "expected_loss": 18,
    "risk": 0.35,
    "risk_source": "Cheap, exposed, and watched by opportunists."
}
```

With no cargo, `loss_good_id` is empty, `loss_quantity`, `loss_unit_value`, and `expected_loss` are zero, and the UI says that no carried cargo is at risk.

The successful departure result records the same loss-model fields plus `risk_roll` and the actual cargo delta. This makes a replay or bug report explain both what could have been lost and what was resolved.

## Timing and price basis

The loss basis is captured immediately before `world.travel()` advances the day. It uses the same current crisis modifiers shown in the departure forecast. A crisis transition caused by the journey may change arrival prices, but it does not retroactively change the disclosed value of the unit that was exposed when the caravan departed.

## Tests

1. Old Road with two carried water has destination unit value 32, expected loss 11, and a one-water incident loss valued at 32.
2. Toll Road with carried medicine has destination unit value 44 and expected loss 4.
3. Zero cargo returns the `one_exposed_unit` label with zero quantity/value/loss and travel still succeeds.
4. Mixed water and medicine exposes the higher destination-value unit; equal values use canonical good order.
5. A low quantity never produces more than one unit of cargo loss.
6. A high-value unit increases expected loss from its unit value, not total load value.
7. Forecast components still sum exactly to expected net profit.
8. Incident and non-incident departure results both record risk model, source, unit basis, and deterministic roll.
9. Save/load and equivalent seed/state/command preserve the same resolved result.
10. UI smoke coverage asserts the explicit “one unit at risk” explanation and the no-cargo explanation.

## Simulation gate

Rerun the 100-seed policy simulation before and after implementation. Record mean forecast error and mean absolute forecast error for each policy. The gate is not zero stochastic error; it is removal of the structural quantity-dependent error. In particular, the seven-unit Water → Reedwatch policy should no longer carry an expected-loss assumption for 35% of all seven units when the resolver can remove only one.

No route risk, price, starting-resource, or capacity values change in B0.
