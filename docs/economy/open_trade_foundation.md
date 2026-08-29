# Open Trade Foundation Contract

This contract implements Feed A of the nonlinear-trade addendum. It protects ordinary caravan trade as a complete game loop before adaptive crisis factions are added.

## Player promise

The player can inspect a settlement, choose cargo because one place produces it and another place needs it, compare the full journey burden, and make a profitable trip without accepting a named contract. Contracts remain optional commitments with distinct access and consequences.

## Authoritative data

Each runtime settlement owns a `trade_profile`:

- `produces`: goods with a player-facing reason they are locally available.
- `consumes`: goods with a player-facing reason demand recurs.
- `ordinary_trade_note`: the settlement's concise market identity.

Every runtime good must have at least one producer and one consumer. A settlement cannot list the same good on both sides. Both the Godot loader and Python validator enforce this schema.

`market_memory` owns three replenishment multipliers applied to its daily decay:

- Producers: `0.75`, so added supply clears slowly where supply is already established.
- Neutral markets: `1.0`.
- Consumers: `1.5`, so recurring local need returns faster after a delivery.

Delivery pressure remains bounded, deterministic, serialized, and price-visible.

## Economy API

`MarketEconomy.market_role` exposes the authored source and need roles. `market_pressure_decay_rate` derives replenishment without adding mutable state. `ordinary_trade_story` composes source, need, spread, route costs, risk, and expected net from the existing authoritative price and route-preview functions.

The UI does not recalculate economy values.

## Bazaar presentation

The Trade stall leads with `ORDINARY TRADE — NO CONTRACT REQUIRED` and shows:

1. Selected cargo, origin, destination, and route.
2. Authored source and destination-need explanations.
3. Buy price, sell price, unit spread, and selected-load margin.
4. Route fee, provisions, exposed-unit risk, and expected net value.
5. Current price reasons, market memory, and comparison prices.

This preserves detail while moving the decision story ahead of diagnostic factors.

## Executable balance gates

The deterministic quality suite protects four non-contract patterns:

| Family | Fixture | Expected net |
| --- | --- | ---: |
| Staple | Water, Ashgate to Reedwatch via Old Road | +14 |
| Repair | Scrap, Cinderford to Ashgate via Toll Road | +4 |
| Medicine | Medicine, Hollow Market to Reedwatch via Dry Cut | +13 |
| Industrial | Charcoal, Cinderford to Brine Cross via Toll Road | +16 |

All must remain positive and contract-free. The strongest ordinary opening must also retain at least 70% of the accessible Reedwatch relief contract's expected net value. Current evidence is 99 ordinary versus 70 contract ashmarks.

## Failure and save behavior

Invalid profiles fail content loading before a campaign starts. Existing saves need no migration because trade profiles and replenishment rates are runtime rules; persisted market pressure continues to load under save version 11 and follows the current validated content rules when time advances.
