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

## New play

A four-charcoal Ashgate-to-Reedwatch Old Road fixture changes from `-10` expected net before the response to `+7` afterward. This is ordinary spot trade: no contract or faction action is required.

## Persistence and validation

Save version 12 stores `scenario_states` and `emergent_factions`. Older saves initialize missing adaptive state, then evaluate it against their current day and contract history. Current saves reject unknown scenario/faction references and impossible state timestamps. Runtime and Python validators enforce the authored trigger, response, market effect, and opportunity schema.
