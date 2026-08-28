# Alpha Arms-Trade Boundary

**Status:** Approved implementation contract; no gameplay behavior is introduced by this document.

## Player promise

Arms are optional, profitable cargo that make sponsors, routes, and regional consequences more visible. They do not unlock combat, armies, tactical equipment, or a hidden morality score. A player who refuses arms must retain commercially viable contracts and campaign progress.

## Smallest data model

Add one good, `sealed_arms_crate`, with tags `arms`, `regulated`, and `high_value`. Add one bounded regional value, `arms_escalation`, from 0 through 6. Content may declare only numeric deltas, stable IDs, visible warning text, and named follow-up IDs; executable conditions remain in core code.

The first proof contains exactly two authored offers:

1. A Cinder Rider buyer pays a high spot premium at Cinderford or an accessible proxy settlement.
2. A non-arms relief/logistics alternative offers comparable expected economic value through water, medicine, scrap, or route-service work.

No additional weapon types, crafting inputs, combat stats, or equipment slots belong in this slice.

## State and ordering

`arms_escalation` is serialized and deterministic. It changes only from named successful commands or event outcomes.

1. Preview the transaction and all immediate/persistent consequences.
2. Validate cargo, location, capacity, faction prerequisites, and visit budget.
3. Apply money/cargo changes.
4. Apply the declared escalation and faction deltas.
5. Record one structured history entry and refresh all affected UI explanations.

Failed or cancelled actions change nothing. Replay from the same save and command must produce the same result.

## Escalation stages

| Value | Label | Visible consequence |
| --- | --- | --- |
| 0–1 | Quiet manifests | Arms remain a private opportunity; no route modifier. |
| 2–3 | Noticed traffic | Toll Road inspection warning appears; arms cargo pays a disclosed inspection surcharge or may take another route. |
| 4–5 | Armed corridor | One exposed-route risk or fee changes and a non-arms de-escalation action becomes available. |
| 6 | Open pressure | The regional summary names the armed trade, but the player retains at least one recoverable non-combat route and one non-arms progress path. |

Crossing a threshold must update the shop/departure explanation immediately. No threshold may confiscate all money/cargo, close every route, or force combat.

## Political consequences

- Cinder Rider arms sales can grant named Rider access or information while increasing `arms_escalation`.
- Ash Wardens react through a disclosed inspection, fee, or standing change; they do not silently alter all prices.
- Salt Crown consequences must be attached to a named buyer, contract, or route condition rather than inferred morality.
- Free Caravan standing may fall when a sale endangers open routes, but public logistics or warning-sharing provides a visible alternative.

Every faction delta appears in the confirmation text and command result before/after values.

## Warnings and counterplay

Before an arms sale or delivery, show:

- buyer/sponsor;
- cargo quantity and payout;
- exact escalation delta and resulting stage;
- immediate faction changes;
- route/service consequence unlocked at the next threshold;
- one named non-arms alternative.

Recovery must be possible through at least two routes: a material public-safety contribution and a time/information action. Recovery lowers escalation gradually and cannot erase already archived decisions.

## Non-arms viability gate

Across the same fixed seed set and starting resources:

- a no-arms policy must reach the implemented campaign objective/ending without debug grants;
- its median final resources or progress score must be at least 80% of the best arms policy;
- the arms policy may earn a higher early cash peak, but cannot dominate expected campaign progress, route access, and recovery simultaneously;
- at least one water/medicine relief route and one scrap/infrastructure route remain legal at every escalation stage.

These are tuning gates, not guarantees about human preference.

## Validation rules

- Arms-tagged goods use stable lower-snake-case IDs, positive base price/weight, and an explicit `arms` tag.
- Escalation minimum is 0; maximum is 6; thresholds are ordered, unique, and within bounds.
- Every arms offer declares quantity, payout, escalation delta, faction deltas, warning, and non-arms alternative ID.
- Every threshold declares visible text and at least one recovery action at stage 2+.
- Referenced goods, settlements, routes, factions, contracts, and actions must exist.
- No content field contains executable expressions.

## Automated tests

- Valid schema plus invalid IDs, bounds, unordered thresholds, missing warnings, and missing recovery references.
- Sale success, capacity/cargo/location/faction blocks, and no mutation on failure.
- Below/at/above every escalation threshold.
- Save/load and version migration at every stage.
- Equivalent replay of sale, inspection, and recovery commands.
- Arms and non-arms policy simulations across 100 seeds, including ruin rate, route concentration, median progress/resources, and recovery time.
- UI smoke coverage for confirmation warning, threshold transition, faction deltas, route effect, and a visible non-arms alternative.

## Human playtest gates

Before expanding arms content, at least five first-time testers must be able to state:

1. who is buying the arms;
2. what immediate profit they receive;
3. which escalation threshold will change next;
4. one likely route/faction consequence;
5. one viable non-arms alternative;
6. one way to reduce pressure afterward.

No tester should believe arms are mandatory for progression or that choosing them starts a combat game.

## Explicitly deferred

- combat and tactical encounters;
- equipping weapons or crew combat roles;
- multiple arms commodities;
- procedural buyers or live markets;
- armies, territory control, and settlement destruction;
- secret morality scoring;
- irreversible campaign failure from one shipment.
