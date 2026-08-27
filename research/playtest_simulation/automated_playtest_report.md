# Market of Ash — Corrected Automated First-Run Playtest Simulation

> **Scope note:** This is a deterministic, rule-based simulation of the current prototype, not a substitute for human playtests. It reveals what the implemented economy rewards under explicit policies; it does not measure player enjoyment, comprehension, or preference.

## Corrected Topology

Routes now declare exactly two canonical endpoints in `runtime_world.json`. The command processor rejects a departure unless the selected route connects the caravan’s current settlement to the selected destination. The user interface filters destinations and routes from the same content. Consequently, every completed simulation row below is a legal endpoint-to-endpoint departure; there is no separate map-constrained counterfactual policy.

## Scope and Method

The run starts every simulated trader in the current quick-playtest state: Ashgate, day one, 120 ashmarks, twelve provisions, and empty cargo. It executes the existing buy, travel, and sell command boundary across **100 seeds**. Each policy is evaluated once per seed. The seed range covers the complete 100-value route-roll cycle produced by the current route incident formula for a fixed travel day.

| Policy | Decision rule |
| --- | --- |
| Guided grain delivery | Buys 2 grain; travels Ashgate → Reedwatch via Old Road. |
| Forecast maximizer | Chooses the legal first trade with the highest displayed expected net profit. |
| Gross-margin chaser | Chooses the legal first trade with the highest displayed gross margin. |
| Toll-road-only | Chooses the best displayed net-profit trade while using the legal Toll Road corridor only. |
| No trade baseline | Takes no action; baseline for resource preservation. |

The simulator tests only the initial one-trade loop. It does not model crew, contracts, event choices, faction effects beyond existing price modifiers, market memory, or player learning over multiple runs.

## Results

| Policy                | Runs   | Completed   | Incident rate   | Forecast net   | Realized economic   | Median realized   | Loss rate   | Forecast error   | Mean units   |
|:----------------------|:-------|:------------|:----------------|:---------------|:--------------------|:------------------|:------------|:-----------------|:-------------|
| Guided grain delivery | 100    | 100.0%      | 35.0%           | -20.0          | -19.8               | -17.0             | 100.0%      | +0.2             | 2.0          |
| Forecast maximizer    | 100    | 100.0%      | 35.0%           | +99.0          | +98.8               | +110.0            | 0.0%        | -0.2             | 7.0          |
| Gross-margin chaser   | 100    | 100.0%      | 35.0%           | +99.0          | +98.8               | +110.0            | 0.0%        | -0.2             | 7.0          |
| Toll-road-only        | 100    | 100.0%      | 10.0%           | +9.0           | +8.6                | +13.0             | 10.0%       | -0.4             | 3.0          |
| No trade baseline     | 100    | 0.0%        | 0.0%            | +0.0           | +0.0                | +0.0              | 0.0%        | +0.0             | 0.0          |

Under legal paths, the **forecast maximizer** selects **water → reedwatch / old_road** in every seed and averages **+98.8** realized economic profit. The **gross-margin chaser** selects **water → reedwatch / old_road** and averages **+98.8**. The **Toll-road-only** policy selects **medicine → brine_cross / toll_road** and averages **+8.6**. The guided Grain delivery remains a mechanically legible but deliberately lower-return teaching run at **-19.8**.

![Policy outcome chart](policy_outcomes.png)

## Decision Patterns

| Policy                | Chosen first trade                 | Runs   | Share   |
|:----------------------|:-----------------------------------|:-------|:--------|
| Forecast maximizer    | water → reedwatch / old_road       | 100    | 100.0%  |
| Gross-margin chaser   | water → reedwatch / old_road       | 100    | 100.0%  |
| Guided grain delivery | grain → reedwatch / old_road       | 100    | 100.0%  |
| No trade baseline     | No trade                           | 100    | 100.0%  |
| Toll-road-only        | medicine → brine_cross / toll_road | 100    | 100.0%  |

Every deterministic policy still concentrates on one legal initial trade in this linear, one-trip model. That is a genuine early-economy design signal after the topology fix: repeated opening runs may become rote unless market memory, information quality, or a meaningful inventory/risk trade-off produces legible rotation.

![Choice concentration chart](choice_concentration.png)

## Forecast Calibration

| Policy                | Forecast net   | Realized economic   | Mean error   | Mean absolute error   |
|:----------------------|:---------------|:--------------------|:-------------|:----------------------|
| Guided grain delivery | -20.0          | -19.8               | +0.2         | +3.7                  |
| Forecast maximizer    | +99.0          | +98.8               | -0.2         | +14.5                 |
| Gross-margin chaser   | +99.0          | +98.8               | -0.2         | +14.5                 |
| Toll-road-only        | +9.0           | +8.6                | -0.4         | +7.6                  |

The displayed forecast and resolver now share the **one exposed cargo unit** model. The forecast values the highest destination-value unit currently carried, multiplies that value by route risk, and the resolver removes that same unit when an incident occurs. Remaining error is bounded stochastic and integer-rounding variance rather than a structural whole-load-versus-one-unit mismatch.

### B0 before/after

| Policy                | Mean error before   | Mean error after   | MAE before   | MAE after   |
|:----------------------|:--------------------|:-------------------|:-------------|:------------|
| Guided grain delivery | +3.2                | +0.2               | +4.6         | +3.7        |
| Forecast maximizer    | +66.8               | -0.2               | +66.8        | +14.5       |
| Gross-margin chaser   | +66.8               | -0.2               | +66.8        | +14.5       |
| Toll-road-only        | +8.6                | -0.4               | +14.8        | +7.6        |

The forecast-maximizing policy's mean error fell from **+66.8** to **-0.2** ashmarks-equivalent. Its mean absolute error fell from **66.8** to **14.5**; the remaining absolute error is the expected spread between a rounded expected value and binary one-unit outcomes across individual runs.

## Economic Bottlenecks and Design Risks

| Finding | Evidence from corrected run | Why it matters | Suggested next test, not a balance change |
| --- | --- | --- | --- |
| **Route topology is now authoritative** | All completed runs use content-declared endpoints, and invalid Old Road → Brine Cross departures are rejected in regression coverage. | Route fees, risk, map presentation, and forecast now describe the same corridor. | Keep endpoint validation in future route-content review; no balance action is indicated by this implementation fix alone. |
| **Legal opening-choice concentration** | The forecast and gross-margin policies each select one legal opening trade in 100.0% of runs. | Once players learn the display, early trade can become routine rather than a meaningful choice. | Implement bounded market memory (A2) and rerun the harness to measure whether recent deliveries create readable trade rotation. |
| **Forecast/resolution calibration** | Mean forecast error ranges from -0.4 to +0.2 ashmarks-equivalent across active policies after both paths adopted the one-unit model. | Small residual error is expected across finite deterministic samples, but systematic drift would weaken trust. | Keep the shared loss helper under regression coverage and rerun this report after route, price, cargo-loss, or crisis changes. |
| **Capacity dominates the first decision** | The forecast policy loads an average of 7.0 units against a 12-unit capacity. | The opening may reward filling the hold more than comparing cargo, route, and information. | Observe first-time testers’ chosen quantities, then compare against a lower-cash or tighter-provision test preset. |
| **Guided delivery is not an economic optimum** | The Grain teaching run averages -19.8 realized economic profit. | The suggested first action should teach a visible trade-off without falsely implying that it is the best available profit path. | Ask testers to explain why they followed or rejected the suggested Grain move; retain it only if it reliably teaches the forecast model. |

## Recommended Human-Playtest Prompts

Use the refined quick-playtest with no assistance beyond the screen text. Ask the player to say aloud: **“Why did you choose this cargo, route, and quantity?”** After their first sale, ask: **“Did the outcome match what you expected from the forecast?”** Record their selected cargo, route, quantity, whether they noticed price reasons and expected loss, and whether they could name one alternative they rejected. Those observations will test comprehension and trust—the dimensions this automated pass cannot measure.

## Reproduction

The attached raw results were generated by `tools/simulate_trade_policies.gd` and summarized by this script. The simulator is read-only: it creates fresh world instances, runs only existing explicit commands, and does not alter the game’s content or balance data.

## Sources

| Source | Role |
| --- | --- |
| `content/runtime_world.json` | Implemented goods, settlement price modifiers, route endpoints, and planning assumptions. |
| `src/core/economy.gd` | Implemented prices and forecast calculation. |
| `src/core/market_command_processor.gd` | Implemented buy, endpoint validation, travel, incident, and sell resolution. |
| `research/playtest_simulation/policy_simulation.json` | Raw 500-run corrected simulation output. |
