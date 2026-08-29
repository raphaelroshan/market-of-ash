# Well Commons Adaptive Response Contract

This contract implements Feed B of the nonlinear-trade addendum: one complete failure chain whose outcome creates new play.

## Scenario states

`reedwatch_water_relief` starts `offered` on Day 1.

| State | Trigger | Result |
| --- | --- | --- |
| `offered` | No commitment before Day 4 | No hidden penalty; ordinary trade and all other actions remain open. |
| `accepted` | Reedwatch Water Relief accepted and still on time | Frozen contract terms remain authoritative. |
| `delayed` | Accepted contract passes its deadline | The local response activates while the late contract remains formally resolvable. |
| `failed` | The overdue contract is resolved | The bounded contract penalty applies; the replacement response remains active. |
| `resolved` | Relief is completed on time | The Well Commons response does not activate. |
| `expired` | Day 4 arrives without acceptance | The old offer closes as history and the replacement response activates. |

## Replacement response

The Well Commons is based on household ration tallies, shared cistern labor, and public boiling fires. Residents support it because water kept moving when official relief did not arrive.

Activation is idempotent and does four durable things:

1. Adds one bounded Reedwatch resilience.
2. Stabilizes Reedwatch water prices with a `0.9` response multiplier.
3. Applies a `1.3` charcoal multiplier for boiling and pump work.
4. Records the active emergent faction and named exchange in save state.

The stale relief offer becomes disabled with a causal explanation. The regional map hover names the active exchange, Town Outlook marks the Commons response, and Web diagnostics expose the scenario state, actor, and trade summary.

## Interaction paths

- `Fuel the Commons boilers`: spend two charcoal for one Reedwatch resilience, one Free Caravan standing, and one Commons support.
- `Publish the Commons ledger`: spend eight ashmarks, one day, and one visit slot for one Commons support, one Free Caravan standing, and three points less Dry Cut risk.
- `Buy a Warden cistern permit`: spend ten ashmarks for one Warden standing and minus one Commons support; the ordinary market remains available.

Commons support is bounded from -3 to +3. Positive support strengthens the charcoal premium and further stabilizes water; opposition weakens those effects without deleting them. A later cooperation action can reverse a prior bypass.

## New play

A four-charcoal Ashgate-to-Reedwatch Old Road fixture changes from `-10` expected net before the response to `+7` afterward. This is ordinary spot trade: no contract or faction action is required.

## Alternate ending

`The Wells Belong to Those Who Carry` is reachable only after official relief expires or fails. The caravan must then sell at least four charcoal into Reedwatch after the Commons activates, raise Commons support above zero, and bring Reedwatch resilience to at least two while keeping arms escalation contained. This makes the replacement actor, the ordinary market delivery, and direct cooperation all necessary parts of the outcome. Earlier deliveries and contract/event transfers do not count. Qualifying totals are stored on the Commons record, so later trading cannot erase the earned outcome when the bounded market-history log rolls over.

## Persistence and validation

Save version 12 stores `scenario_states` and `emergent_factions`, including bounded support, completed interaction IDs, and durable ordinary-delivery totals. Older saves initialize missing adaptive state, then evaluate it against their current day and contract history. Current saves reject unknown scenario/faction references, impossible state timestamps, and invalid delivery ledgers. Runtime and Python validators enforce the authored trigger, response, market effect, and opportunity schema.
