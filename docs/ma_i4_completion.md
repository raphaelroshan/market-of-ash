# MA-I4 completion — Glasswind Reach route depth

## Delivered behavior

- Glasswind Reach now contains three settlements and three roads. The new `emberglass_byway` directly connects Kiln Rest and Mirror Wells, closing the regional triangle.
- The byway costs 2 ashmarks and one day at 58% cargo risk. It is cheaper and faster than the licensed two-leg route through Sunfall Exchange, but more exposed than either licensed leg.
- Lamp oil remains a profitable ordinary Kiln Rest → Mirror Wells cargo without a contract. The existing Beacon Oil assignment remains optional.
- The Shardwind Tithe supplies paid, delayed, and disclosed-risk responses on the byway, so a mistake changes resources rather than ending the run.
- Every specialist has authored byway guidance, and the travel view uses a distinct copper furnace-vent and glassfall silhouette.

## Deterministic evidence

- `tests/test_second_region.gd` verifies the three-settlement/three-route manifest, local exit topology, exact route tradeoff, ordinary profit, pending-event restoration, no-loss recovery, changed-market restoration, optional contract, and Night Market failure-forward path.
- `tests/test_investment_economy_matrix.gd` completes 100 seeded ordinary-trade trials across four route/good strategies: 100 profitable completions, zero bankruptcies, ten cargo-loss trials recovered, 25% mean cargo utilization, a 3.75 mean arrival day, an even stage-0/stage-1 crisis split, and multiple event outcomes.
- Route use is balanced at 25 trials each. Aggregate net results are Emberglass 1,141, Mirror Run 807, Old Road 885, and Reedline 2,165 ashmarks; the richer March medicine run remains counterweighted by regional distance and return-cargo needs in the full campaign.
- The full repository suite passes on Godot 4.7.2. The release round-trip benchmark completes 25 worlds in 40.71 ms against a 5,000 ms budget.

## Visual evidence

The 1600×900 sequence in `docs/visual_evidence/v0.15.0-ma-i4-emberglass-2026-09-02/` records route comparison, the dedicated road stop, Shardwind choice, and arrival receipt. Semantic capture validation checks the 2-ashmark fee, one-day duration, 58% risk, furnace-road identity, event, and Mirror Wells arrival.

## Remaining boundary

The route art remains code-native production art and the exact margin/risk tuning still benefits from moderated human play. Neither blocks the deterministic investment gate.
