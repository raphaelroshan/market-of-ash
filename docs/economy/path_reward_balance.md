# Cross-Path Reward Balance — Feed D

## Player-facing behavior

The Ashgate Job Board shows Reedwatch Water Relief as a commitment with a small cash premium, not as the only rational route. Its card reports expected net, provisions, hold commitment, standing, travel time, and visit-slot cost on one `PATH VALUE` line. Ordinary Bazaar trade remains slot-free and contract-free; civic and Commons actions name resilience, route, standing, and support outcomes directly.

## Ten-minute fixture

The deterministic fixture uses the Day 1 Ashgate state and the best legal ordinary opening. It compares four representative paths without translating every reward into ashmarks:

| Path | Expected net | Provisions | Hold | Standing | Time | Visit slots | Other durable value |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| Ordinary Water trade to Reedwatch | 99 | 1 | 7 | 0 | 1 day | 0 | Renewable spot-market income |
| Reedwatch Water Relief | 100 | 1 | 4 | Free Caravan +1 | 1 day | 1 | Guaranteed 180-ashmark payout and relief completion |
| Reedwatch supply shelter | 0 | 0 | 0 | Free Caravan +1 | 1 day | 1 | Reedwatch resilience +1 |
| Fuel the Commons boilers | 0 | 0 | 2 charcoal | Free Caravan +1 | 0 days | 1 | Reedwatch resilience +1 and Commons support +1 |

The contract-to-ordinary expected-net ratio is 101%, inside the authored 100–120% band. This pays for commitment without making ordinary trade a knowingly inferior fallback.

## Executable acceptance criteria

- Runtime content defines a positive ten-minute fixture and an ordered contract premium band.
- All four vectors contain ashmarks, expected net, provisions, capacity, standing, time, and visit slots.
- Civic and faction vectors expose resilience and support separately instead of assigning them a fake cash value.
- The opening contract remains at least as profitable as the best ordinary opening but no more than 20% stronger.
- The best ordinary opening remains positive and retains at least 70% of contract expected net.
- The Job Board renders the authoritative contract vector.

The gate lives in `GameQualityMetrics.path_reward_balance`, is asserted by `tests/test_game_quality.gd`, and is exported into `research/playtest_simulation/quality_gate_summary.csv`.
