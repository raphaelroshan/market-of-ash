# Player-copy audit — 2026-09-04

## Scope and method

The `market-of-ash-writer` skill reviewed the release-facing path in player order: Main Menu, Introduction, Bazaar tutorial, Departure, moving road, road stop, encounter, arrival, return trade, and ending. The pass compared runtime content with its presenters and tests, then checked changed surfaces at the minimum supported window and with Large Text.

Severity describes player cost: blocker prevents a sound choice, major makes a choice or consequence materially harder to read, and polish affects tone without obscuring the decision.

## What already works

- Settlement and route names carry a consistent material identity: wells, brine, glass, peat, spans, and signal lines.
- Trade guidance names source, need, price, provisions, and exposure rather than requiring a contract.
- Encounter options preserve refusal and recovery paths while disclosing deterministic costs and uncertainty.
- Arrival comparisons retain the expected-versus-actual structure needed to learn the economy.

## Findings and corrections

| Severity | Surface | Finding | Correction |
| --- | --- | --- | --- |
| Major | Moving road and road stop | Copy referred to “presentation,” a “readable road stop,” and the “next authored encounter,” exposing implementation language during the most atmospheric transition. | Reframed the same state guarantees as paid passage, packed provisions, road signs, stopping places, and commitment until the next stop. |
| Major | Encounter dossier and responses | The interface repeated QA terms such as “disclosed” and “no hidden health,” and every choice listed zero ashmarks, provisions, cargo, and days. Rewards also appeared inside the cost line. | Kept the exact risk and exposed cargo, replaced the implementation disclaimers with a short terms boundary, omitted zero-value fields, and separated `COST` from `RECEIVE`. |
| Major | Arrival and recovery | Receipts called themselves “factual,” described threshold implementation, repeated every unchanged resource as zero, and ended with “No restart is required.” | Named the road roll and risk directly, omitted unchanged resources, then ended recovery with the viable caravan state or next trade. |
| Major | Ending summaries | Several endings narrated what “the player chose,” making the close read like analysis instead of a world outcome. | Led with the changed reserve, road, exchange, or market and retained the causal economic facts in fewer sentences. |
| Polish | Tutorial | Most steps repeated “compare,” named UI/system guarantees, or carried three instructions in one paragraph. | Reduced each beat to two short sentences: the economic reason first, the immediate action last. |
| Polish | Introduction note | The note described the tutorial implementation and save behavior before the player had entered the world. | Stated what guidance does and preserved player ownership of cargo, costs, and consequences. |
| Polish | Trade forecast | Departure still called a planned load a “scenario” and used the awkward phrase “exposed-unit risk.” | Recast it as a planned buy and full load, and named the percentage as cargo-loss risk. |

No blocker was found. The pass did not change numeric terms, stable IDs, encounter availability, authoritative outcomes, save data, or ordinary-trade viability.

## Remaining judgment

The utility copy is now more consistent, but most character voice still lives in choice outcomes rather than exchanges between people. That is an authorship opportunity, not a reason to expand every interface paragraph. A moderated first-time-player session should determine whether players understand cargo exposure, market response, and arrival recovery before further rewriting.

## Verification contract

- Validate the skill package.
- Validate runtime content.
- Run presenter, tutorial-flow, and map-UI tests.
- Run the full repository verification suite.
- Inspect normal and Large Text captures for clipping, hierarchy, and repeated information.

## Verification result

- Writer skill validation: PASS.
- Full `scripts/verify.sh` repository suite: PASS, including all three regions, campaign, game-quality, investment-economy, and release-readiness gates.
- Native 960×540 capture validation: PASS across 86 states.
- Manual visual check: Introduction, Bazaar, Departure, road, encounter, certain arrival, realized-loss recovery, endings, and the changed Large Text states remain usable. Long event and arrival rails still depend on their visible scrolling at the minimum window, as designed.
