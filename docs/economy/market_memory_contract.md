# Bounded Market Memory Contract

**Roadmap slice:** B1a

**Status:** Implemented in B1b

**Player behavior in B1a:** No gameplay behavior changes.

## Objective

A completed sale should temporarily soften the delivered good's price in that settlement. The effect must be finite, deterministic, explainable, recover toward baseline with time, compose predictably with the water crisis, survive save/load, and never make a settlement permanently solved.

## Authored configuration

`content/runtime_world.json` owns one `market_memory` record:

| Field | Meaning | Validation |
| --- | --- | --- |
| `pressure_min` | Resting supply-pressure value. | Number equal to `0.0`. |
| `pressure_max` | Maximum temporary price relief. | Number greater than `pressure_min` and less than `1.0`. |
| `sale_impact_per_unit` | Pressure added for each unit sold. | Positive number no greater than `pressure_max`. |
| `daily_decay_per_day` | Pressure removed per elapsed day. | Positive number no greater than `pressure_max`. |
| `crisis_effectiveness` | Delivery-impact multiplier by crisis stage. | Object containing stages `0`–`3`, each greater than `0.0` and no greater than `1.0`. |
| `max_delivery_history` | Maximum audit/feedback records retained. | Integer from 1 through 100. |

Initial alpha values are deliberately legible rather than final balance:

```json
{
  "pressure_min": 0.0,
  "pressure_max": 0.35,
  "sale_impact_per_unit": 0.04,
  "daily_decay_per_day": 0.03,
  "crisis_effectiveness": {"0": 1.0, "1": 0.85, "2": 0.7, "3": 0.55},
  "max_delivery_history": 12
}
```

## Runtime state

`AshWorldState` will add:

```gdscript
market_pressure = {
    "reedwatch": {"water": 0.0}
}

market_delivery_history = [
    {
        "settlement_id": "reedwatch",
        "good_id": "water",
        "quantity": 4,
        "day": 2,
        "pressure_before": 0.0,
        "pressure_after": 0.16
    }
]
```

The pressure dictionary may remain sparse; a missing settlement/good entry means `pressure_min`. Writes reject unknown settlement or good IDs. History retains only the newest `max_delivery_history` records.

## Price composition

The order is fixed:

```text
raw price = base × settlement × demand × crisis × faction
memory multiplier = 1 - clamped pressure
final price = max(1, round(raw price × memory multiplier))
```

Memory is applied after crisis and faction modifiers so the explanation can distinguish the underlying shortage from the player's temporary relief. Pressure cannot exceed `pressure_max`, so a delivery cannot erase the authored market identity or crisis premium.

## Sale effect

The sale price is calculated before the sale changes pressure. A successful sale then applies:

```text
impact = quantity × sale_impact_per_unit × crisis_effectiveness[current crisis stage]
pressure_after = clamp(pressure_before + impact, pressure_min, pressure_max)
```

A failed sale changes neither pressure nor history. Contract deliveries may later multiply this effect, but B1 does not add contracts.

The crisis effectiveness multiplier is smaller at later stages because the same delivery relieves a smaller share of a more severe regional shortage. Crisis price modifiers and memory remain separate, visible components.

## Recovery

Whenever time advances:

```text
pressure_after = max(pressure_min, pressure_before - days × daily_decay_per_day)
```

Decay is deterministic, applies to every known pressure entry, and occurs after the elapsed days are added. It cannot create negative pressure. At the initial values, a four-unit stage-zero delivery adds `0.16` pressure and fully recovers after six elapsed days (`ceil(0.16 / 0.03)`).

## Player-facing explanation

Price details expose:

- `market_pressure`
- `market_memory_modifier`
- a reason when pressure is non-zero: “your recent deliveries increased local supply”
- the most recent matching delivery record when available
- a recovery statement based on the configured daily decay

The shop renders a short sentence such as:

> Your last 4 water delivered here eased supply pressure by 16%. The effect recovers by 3% per day.

This is explanatory state, not narrative scripting.

## Command and save contract

- `sell_goods` remains the only B1 command that adds pressure.
- The state delta records settlement, good, quantity, pressure before/after, and effective impact.
- `advance_day` applies decay exactly once for the elapsed interval.
- Save version increments from 1 to 2.
- Migration from version 1 initializes empty pressure and delivery history without changing existing cargo, money, day, crisis, reputation, or command history.
- Save/load and equivalent replay must produce identical prices and pressure.

## Tests and fixtures

- Valid runtime configuration passes both Python and GDScript validation.
- `tests/fixtures/market_memory_invalid.json` covers invalid bounds, impact, decay, crisis stages, and history size.
- Repeated sales clamp at `pressure_max`.
- A failed sale writes no pressure/history.
- Buying never changes destination supply pressure.
- Time advancement decays pressure to, but never below, `pressure_min`.
- Crisis effectiveness changes new delivery impact without merging crisis and memory modifiers.
- Price detail composition and reason text are exact.
- Version-1 migration, version-2 round trip, command history, and delivery history are preserved.
- The policy simulation expands to repeated trips and reports loop concentration and recovery time before any balance tuning.

## Non-goals

B1 does not add contracts, visit actions, crew, factions, new goods, perishable cargo, production, autonomous markets, or random price movement.
