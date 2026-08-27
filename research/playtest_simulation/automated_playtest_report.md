# Market of Ash — Automated First-Run Playtest Simulation

> **Scope note:** This is a deterministic, rule-based simulation of the current prototype, not a substitute for human playtests. It reveals what the implemented economy rewards under explicit policies; it does not measure player enjoyment, comprehension, or preference.

## Scope and Method

The run starts every simulated trader in the current quick-playtest state: Ashgate, day one, 120 ashmarks, twelve provisions, and empty cargo. It executes the existing buy, travel, and sell command boundary across **100 seeds**. Each policy is evaluated once per seed. The seed range covers the complete 100-value route-roll cycle produced by the current route incident formula for a fixed travel day.

| Policy | Decision rule |
| --- | --- |
| Guided grain delivery | Buys 2 grain; travels Ashgate → Reedwatch via Old Road. |
| Forecast maximizer | Chooses the feasible first trade with highest displayed expected net profit. |
| Gross-margin chaser | Chooses the feasible first trade with highest displayed gross margin. |
| Map-constrained forecast | Chooses the highest displayed net-profit trade, limited to a drawn route corridor. |
| Map-constrained gross-margin | Chooses the highest gross-margin trade, limited to a drawn route corridor. |
| Toll-road-only | Chooses the best displayed net-profit trade but only takes Toll Road. |
| No trade baseline | Takes no action; baseline for resource preservation. |

The simulator tests only the initial one-trade loop. It does not model crew, contracts, event choices, faction effects beyond existing price modifiers, market memory, route restrictions by location, or player learning over multiple runs.

> **Critical implementation caveat:** The simulator intentionally honors the current command processor, which accepts any selected route with any different destination. The map presentation shows the Toll Road as an Ashgate–Brine Cross corridor, yet the current processor permits the high-performing Water → Reedwatch / Toll Road combination. Treat this as an exposed route-topology rule gap, not as an intended strategic option.

## Results

| Policy                       | Runs   | Completed   | Incident rate   | Forecast net   | Realized economic   | Median realized   | Loss rate   | Forecast error   | Mean units   |
|:-----------------------------|:-------|:------------|:----------------|:---------------|:--------------------|:------------------|:------------|:-----------------|:-------------|
| Guided grain delivery        | 100    | 100.0%      | 35.0%           | -23.0          | -19.8               | -17.0             | 100.0%      | +3.2             | 2.0          |
| Forecast maximizer           | 100    | 100.0%      | 10.0%           | +80.0          | +98.8               | +102.0            | 0.0%        | +18.8            | 7.0          |
| Gross-margin chaser          | 100    | 100.0%      | 55.0%           | -16.0          | +89.4               | +75.0             | 0.0%        | +105.4           | 7.0          |
| Map-constrained forecast     | 100    | 100.0%      | 35.0%           | +32.0          | +98.8               | +110.0            | 0.0%        | +66.8            | 7.0          |
| Map-constrained gross-margin | 100    | 100.0%      | 35.0%           | +32.0          | +98.8               | +110.0            | 0.0%        | +66.8            | 7.0          |
| Toll-road-only               | 100    | 100.0%      | 10.0%           | +80.0          | +98.8               | +102.0            | 0.0%        | +18.8            | 7.0          |
| No trade baseline            | 100    | 0.0%        | 0.0%            | +0.0           | +0.0                | +0.0              | 0.0%        | +0.0             | 0.0          |

The **unconstrained forecast maximizer** earns a mean realized economic profit of **+98.8**, compared with **+89.4** for the unconstrained gross-margin chaser and **-19.8** for the guided Grain delivery. Once the drawn map corridors are enforced in the counterfactual, the forecast policy still averages **+98.8** but selects a different route with **35.0%** incidents instead of **10.0%**. Its displayed forecast falls from **+80.0** to **+32.0** despite the same mean realized payoff. This exposes both the route-topology defect and a risk-forecast calibration gap; it is not an intended player advantage.

![Policy outcome chart](policy_outcomes.png)

## Decision Patterns

| Policy                       | Chosen first trade            | Runs   | Share   |
|:-----------------------------|:------------------------------|:-------|:--------|
| Forecast maximizer           | water → reedwatch / toll_road | 100    | 100.0%  |
| Gross-margin chaser          | water → reedwatch / dry_cut   | 100    | 100.0%  |
| Guided grain delivery        | grain → reedwatch / old_road  | 100    | 100.0%  |
| Map-constrained forecast     | water → reedwatch / old_road  | 100    | 100.0%  |
| Map-constrained gross-margin | water → reedwatch / old_road  | 100    | 100.0%  |
| No trade baseline            | No trade                      | 100    | 100.0%  |
| Toll-road-only               | water → reedwatch / toll_road | 100    | 100.0%  |

The most concentrated actionable rule is **Forecast maximizer**, which selects **water → reedwatch / toll_road** in **100.0%** of its runs. The unconstrained forecast maximizer selects **water → reedwatch / toll_road** in **100.0%** of its runs; the map-constrained forecast policy selects **water → reedwatch / old_road** in **100.0%** of its runs. Both are fully concentrated in this linear, single-trade model. The unconstrained choice conflicts with the drawn Toll Road corridor; once topology is valid, remaining concentration becomes a balance question: the opening economy still risks resolving into one obvious legal answer rather than a meaningful trade-off.

![Choice concentration chart](choice_concentration.png)

## Forecast Calibration

| Policy                       | Forecast net   | Realized economic   | Mean error   | Mean absolute error   |
|:-----------------------------|:---------------|:--------------------|:-------------|:----------------------|
| Guided grain delivery        | -23.0          | -19.8               | +3.2         | +4.6                  |
| Forecast maximizer           | +80.0          | +98.8               | +18.8        | +20.8                 |
| Gross-margin chaser          | -16.0          | +89.4               | +105.4       | +105.4                |
| Map-constrained forecast     | +32.0          | +98.8               | +66.8        | +66.8                 |
| Map-constrained gross-margin | +32.0          | +98.8               | +66.8        | +66.8                 |
| Toll-road-only               | +80.0          | +98.8               | +18.8        | +20.8                 |

The displayed forecast is deliberately conservative when compared with realized economic profit because it deducts a percentage of the **entire expected sale value** as expected loss, whereas the actual route incident removes **one cargo unit**. This is a design and calibration issue rather than a simulation error: the current preview describes risk in value terms, but the resolver applies it in units. The gap becomes more visible as cargo loads grow.

## Economic Bottlenecks and Design Risks

| Finding | Evidence from this run | Why it matters | Suggested next test, not a balance change |
| --- | --- | --- | --- |
| **Route/destination permissiveness** | The unconstrained forecast maximizer selects Water → Reedwatch / Toll Road; enforcing the map selects Water → Reedwatch / Old Road. Both average +98.8 realized economic profit, but their displayed forecasts and incident rates differ materially. | A player can select a route fee and risk profile detached from the visible geography, undermining trust in route comparison and obscuring the valid risk/reward trade-off. | Add explicit origin/destination endpoints to route content and reject invalid departures, then rerun both the simulation and a human playtest. |
| **Opening-choice concentration** | The forecast maximizer is concentrated on one trade/route option for 100.0% of seeds. | Once topology is valid, repeated opening runs may still become rote. | Add bounded market memory (A2), then rerun this harness to measure whether recent deliveries produce meaningful but legible trade rotation. |
| **Forecast/resolution mismatch** | Mean forecast error ranges from +3.2 to +105.4 ashmarks-equivalent across active policies. | Players may interpret a risk-adjusted forecast as more pessimistic or inconsistent than actual outcomes, weakening trust in the explanation layer. | Make the forecast state that its loss estimate assumes cargo value at risk, or align its expected-loss formula with one-unit loss resolution before external testing. |
| **Capacity is a dominant early lever** | The profit-seeking policies load an average of 7.0 units against a 12-unit capacity. | The first decision may reward filling the hold more than choosing among goods, routes, or information. | Run a human observation test that asks players to explain their chosen quantity; then compare full-hold behavior against a lower cash/provision preset. |
| **Safe-route premium** | Toll Road realizes +98.8 at 10.0% incidents, while the map-valid Old Road forecast policy realizes +98.8 at 35.0% incidents. | The safe option currently changes risk exposure and displayed certainty more than mean realized payoff. It should be tested as an insurance choice, not assumed to be economically inferior. | Run paired first-run sessions where the risk display is hidden versus shown, and record route selection plus post-run explanation. |
| **Guided delivery as teaching case** | The preset Grain delivery has a mean realized economic result of -19.8. | The suggested first action must teach a legible trade-off even if it is not the globally best economic answer. | Ask first-time testers whether they can explain the Grain/Reedwatch rationale before purchase and whether the end result changes that understanding. |

## Recommended Human-Playtest Prompts

Use the refined quick-playtest with no assistance beyond the screen text. Ask the player to say aloud: **“Why did you choose this cargo, route, and quantity?”** After their first sale, ask: **“Did the outcome match what you expected from the forecast?”** Record their selected cargo, route, quantity, whether they noticed price reasons and expected loss, and whether they could name one alternative they rejected. Those observations will test comprehension and trust—the dimensions this automated pass cannot measure.

## Reproduction

The attached raw results were generated by `tools/simulate_trade_policies.gd` and summarized by this script. The simulator is read-only: it creates fresh world instances, runs only existing explicit commands, and does not alter the game’s content or balance data.

## Sources

| Source | Role |
| --- | --- |
| `content/runtime_world.json` | Implemented goods, settlement price modifiers, routes, and planning assumptions. |
| `src/core/economy.gd` | Implemented prices and forecast calculation. |
| `src/core/market_command_processor.gd` | Implemented buy, travel, incident, and sell resolution. |
| `research/playtest_simulation/policy_simulation.json` | Raw 500-run simulation output. |
