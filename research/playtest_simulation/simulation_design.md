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

The simulation has no persistent market memory, crew, contracts, decision events, or multi-run learning. Route endpoint validation is now authoritative: the simulator reads canonical endpoints from runtime content and executes only departures that the command processor accepts. This removes the earlier mismatch between the visible map corridors and selectable route/destination pairs.

The preview and route resolver share a one-exposed-unit model: the highest destination-value carried unit supplies the forecast value basis and is the unit removed by a resolved incident. Forecast-versus-realized comparison therefore measures bounded stochastic and rounding error rather than a mismatch in loss units. Human observation remains necessary to answer whether the model is comprehensible, trusted, and enjoyable.
