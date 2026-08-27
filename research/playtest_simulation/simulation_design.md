# Automated First-Run Simulation — Design Decision

## Decision

Use a **one-off, deterministic, read-only simulation** that invokes the same buy, travel, and sell command boundary as the quick-playtest build. The analysis evaluates 100 seeds, which cover the implemented 100-value route-roll cycle for a fixed travel day, under five explicitly labelled decision policies. The simulation starts every run from the exact quick-playtest preset: Ashgate, day one, 120 ashmarks, twelve provisions, and empty cargo.

## Representative policies

| Policy | Purpose | Rule |
| --- | --- | --- |
| Guided grain delivery | Test the authored first-run recommendation | Buy two Grain, travel to Reedwatch through Old Road, then sell remaining Grain. |
| Forecast maximizer | Test the visible route-profit preview as a decision aid | Choose the feasible first trade with the highest displayed expected net profit. |
| Gross-margin chaser | Identify the consequence of ignoring full journey costs | Choose the feasible first trade with the highest displayed gross trade margin. |
| Toll-road-only | Test the safe-route premium in isolation | Choose the best displayed net-profit trade while using Toll Road only. |
| No-trade baseline | Preserve a non-action reference point | Take no action. |

## Design rationale

The objective is to expose **mechanical incentives**, such as dominant first choices, profitability differences, risk exposure, and forecast calibration. The simulation intentionally does not imitate human cognition. It does not claim that a forecast maximizer or gross-margin chaser represents a real player population.

The policy sweep checks only quantity boundaries of one and the largest legal affordable quantity for each good-route pairing. Under the current linear first-run price and forecast rules, an interior quantity cannot outperform both boundaries for a fixed pairing. This reduces execution cost while preserving the candidate choices relevant to the current model.

## Trade-offs and limitations

The simulation has no persistent market memory, crew, contracts, decision events, route endpoint validation, or multi-run learning. In particular, it faithfully reveals that the current command processor accepts a selected route with any different destination, even if the map presentation implies a different corridor. Results involving that gap must be treated as an implementation finding, not an intended economic balance result.

The preview’s expected loss is value-based, while the route resolver removes one cargo unit. Consequently, forecast-versus-realized comparison is a calibration diagnostic, not a proof that either risk system is correct. Human observation remains necessary to answer whether the forecast is comprehensible, trusted, and enjoyable.
