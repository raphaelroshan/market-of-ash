# Market of Ash: Open Trade, Adaptive Basin, and Non-Railroaded Progression

**Status:** Design addendum and implementation contract  
**Applies to:** `0.13.0-alpha-basin-vertical-slice` and later  
**Relationship to the roadmap:** This document amends the game-quality vertical-slice roadmap. It does not replace the deterministic economy, the command boundary, or the Five-Well Basin scope.

> **Product decision:** Market of Ash must be a trade-and-travel RPG in which ordinary buying and selling is a satisfying primary play style. Authored contracts, faction situations, and crisis scenarios should create opportunities and information, not a prescribed sequence of correct errands.

## 1. Why this addendum is binding

The current vertical-slice roadmap correctly emphasizes a readable first journey, local needs, route comparison, disclosed consequences, and arrival debriefs. There is a risk, however, that a well-presented first journey becomes a hidden railroad: the player learns that the “real” game is to accept the highlighted contract, buy the named good, take the intended road, and deliver it on time.

That would undermine the central Frontier inspiration. The pleasure of the game should come from noticing a spread, remembering a place, judging a road, and deciding whether a profitable load is worth the exposure. Contracts and scenarios should enrich that pleasure by changing the information available and the shape of the market. They must not make conventional arbitrage feel like an inferior activity.

This is also consistent with broader economy-design guidance. A player-driven economy is valuable when different ways of playing serve a role in the wider ecosystem rather than when one reward path dominates all others.[^1] Sources and sinks should be distributed according to the amount of agency the game intends to provide, with currency-per-time used as a balancing instrument rather than as a reason to force one activity.[^3] For a trade game specifically, recurring producer and consumer behavior creates the “entropy” that keeps ordinary arbitrage alive after the player has equalized a pair of markets.[^2]

## 2. The recommended structure: three overlapping games

Market of Ash should be structured as three overlapping but independently viable layers.

| Layer | Player question | Primary reward | Design role |
|---|---|---|---|
| **Open trade** | “Where is a good cheap, and where will it be needed next?” | Ashmarks, market knowledge, route mastery | The evergreen core. It must remain profitable and interesting without accepting a contract. |
| **Authored opportunities** | “Is this person, contract, or crisis worth prioritizing over my current plan?” | Access, information, relationships, special terms, bounded financial upside | Adds texture and asymmetry. It should improve a trade plan, not replace it. |
| **Adaptive basin** | “What changed because nobody solved this problem, or because I solved it differently?” | New markets, factions, routes, risks, and endings | Converts omission and failure into world change rather than dead ends. |

The layers should overlap in the same screens. A player may discover a high water price through ordinary market inspection, hear about it from a contract, or infer it from a faction’s growing influence. These are different sources of information about the same living basin, not separate progression tracks.

### 2.1 The target player experience

A successful session should support all of the following decisions:

1. The player ignores every contract and still finds at least two plausible profitable trades.
2. The player accepts a contract because it changes the risk/reward calculation, not because ordinary trade is unprofitable.
3. The player fails to meet a scenario and sees a legible consequence: a market changes, an actor moves, a route closes or opens, or a replacement offer appears.
4. The player can pivot back to ordinary trading after a failed or completed scenario.
5. Two players who make different early choices can reach distinct but coherent basin states without requiring bespoke branch content for every combination.

## 3. Open trade must be valuable on its own

### 3.1 Market breadth target

The current five-node, six-good foundation is appropriate for the first slice. It should be made deep before it is made large. The recommended production target is a basin with **eight to ten settlements, ten to twelve core goods, and two to four meaningful trade relationships per settlement**. The first five-node slice should expose at least three profitable trade patterns at any stable crisis stage.

| Breadth dimension | Vertical-slice target | Later basin target | Acceptance principle |
|---|---:|---:|---|
| Settlements | 5 | 8–10 | Every node has a distinct production/consumption profile and a reason to revisit it. |
| Goods | 6–7 | 10–12 | Every good has at least one source, one consumer, one route risk, and one non-price use or consequence. |
| Viable loops | 3 | 6–8 | No loop is always dominant after fees, provisions, time, risk, and market memory. |
| Direct connections | 2–3 per node | 2–4 per node | A player can pivot without crossing the entire map. |
| Price signals | Local price, reasons, distant comparison | Trends, memories, known shocks | Information should improve decisions without becoming perfect prediction. |
| Ordinary trade income | Reliable baseline | Reliable baseline | Contracts may spike value, but should not be required to maintain a caravan. |

A market is not interesting merely because it has a high number. Each settlement needs a recognizable role: producer, consumer, transshipment point, repair/permit hub, information node, or contested frontier. A place may have more than one role, but its role must be visible in the UI and reflected in prices, route conditions, and available services.

### 3.2 Trade pattern families

The economy should deliberately support several kinds of ordinary trade rather than one universal buy-low/sell-high loop.

| Pattern | Example | What makes it interesting |
|---|---|---|
| **Staple relief** | Water or grain from a replenishing source to a stressed settlement | Low-to-medium margin, dependable demand, strong resilience effect. |
| **Repair arbitrage** | Scrap from a salvage settlement to a repair or bridge hub | Medium margin, weight pressure, route and maintenance exposure. |
| **Medical urgency** | Medicine from a clinic or caravan stock to a fever-affected node | High price volatility, information value, social consequences. |
| **Industrial shortage** | Charcoal or cloth into a settlement whose local production has been disrupted | Moderate margin, changing demand, good repeat-trade potential. |
| **Restricted cargo** | Arms or sealed equipment between politically distinct markets | High margin, faction visibility, escalating inspection and conflict risk. |
| **Information arbitrage** | A known route condition or market memory creates a temporary spread | The reward is better timing and knowledge, not a new currency. |

At least two of these families should be available without a contract in every early campaign. The player should be able to discover them through price comparisons, market explanations, settlement outlooks, crew observations, or prior run memory.

### 3.3 A practical profitability rule

The player should evaluate a trade using an explicit expected-value frame:

```text
expected trade value
= destination sale value
− origin purchase cost
− route fee
− provision cost
− time opportunity cost
− expected loss value
− recovery reserve
```

This need not be shown as a single authoritative number in every context, but each term must be inspectable before commitment. The game should avoid making ordinary trades profitable only when the player ignores provisions, repairs, time, or risk. If a load is profitable only on paper, the forecast must say why.

The economy should preserve the current deterministic per-unit and market-memory rules. A market must not be exploitable by buying a whole stock, waiting for a recalculation, and selling it back. The trade system should make money primarily from **differences between locations and time states**, while local trading changes the price in a visible, bounded way.[^2]

### 3.4 A stable baseline and a volatile edge

The basin should have a two-speed economy.

The **stable baseline** consists of recurring production, consumption, and replenishment. It guarantees that a player who studies the map can always find modest, understandable opportunities. The **volatile edge** consists of crisis effects, faction pressure, route closures, market memory, contracts, and events. It creates the exceptional margins and meaningful risk.

The baseline prevents the player from needing authored scenarios to recover. The volatile edge prevents the game from becoming a static spreadsheet. The design target is not constant maximum profit; it is a dependable floor plus changing reasons to alter the plan.

## 4. Authored scenarios as invitations, not rails

### 4.1 Contract parity

A contract should usually provide one or more of the following:

- A guaranteed buyer, reducing sale uncertainty.
- A route discount, escort, permit, or information advantage.
- A relationship or faction consequence unavailable through anonymous trade.
- A time-limited opportunity with a clear alternative cost.
- A bounded premium for accepting a risk the player might otherwise avoid.

A contract should not simply pay more than ordinary trade for the same cargo with no additional decision. If its reward is higher, it must also consume attention, capacity, time, political capital, or route flexibility. Conversely, the ordinary trade alternative must remain viable.

**Recommended balance rule:** in the first hour, ordinary trade should provide roughly **70–100% of the expected ashmark progress** of the best available contract route, while contracts provide differentiated access, information, and consequences. This is a tuning band, not a permanent formula. The important rule is that contracts should be attractive because they are interesting, not because they are the only solvent choice.

### 4.2 Offer presentation

The UI should label opportunities by what they change:

| Label | Meaning |
|---|---|
| **Guaranteed buyer** | Reduces destination price uncertainty. |
| **Route advantage** | Changes fee, provisions, risk, or access. |
| **Political exposure** | Changes faction visibility, standing, or future pressure. |
| **Civic consequence** | Changes settlement resilience or available services. |
| **Information lead** | Reveals a condition, trend, or possible route. |
| **Ordinary trade** | No contract accepted; the player is choosing market spread and timing. |

The Bazaar should present ordinary trade first as a complete verb, then show jobs and faction situations as optional modifiers to the same loop. The player should never have to decline a contract through a warning that implies they are playing incorrectly.

## 5. Adaptive substitution: failure changes the basin

### 5.1 The core rule

If an initial scenario is not met, the game should not pretend nothing happened and should not force the player to repeat the same task. Instead, the unmet need becomes an input to the basin simulation.

```text
scenario offered
→ player accepts, ignores, delays, or fails
→ authored clock advances deterministically
→ need remains, worsens, or is partially solved
→ another actor responds
→ market, faction, route, or settlement state changes
→ replacement opportunities become available
```

The replacement should be caused by the same world facts that made the first scenario possible. A replacement faction must not appear as arbitrary punishment. It should have a source of legitimacy, a material interest, and a visible way to interact with it.

### 5.2 Scenario state machine

Each authored scenario should expose a compact state machine rather than a one-shot quest flag.

| State | Player action | World result | Replacement behavior |
|---|---|---|---|
| **Offered** | Ignore, inspect, accept, or decline | No hidden penalty | Opportunity remains visible until its clock changes. |
| **Accepted** | Attempt delivery or complete terms | Contract and relationship state become active | Failure terms are disclosed before departure. |
| **Delayed** | Spend days or pursue another route | Reward, demand, or access changes | A local actor begins solving the gap. |
| **Partially met** | Deliver some value or choose a compromise | Need improves but does not clear | A smaller follow-up or competing offer appears. |
| **Failed** | Miss deadline, lose cargo, or refuse final choice | Need persists or worsens; reputation may change | Replacement actor, emergency market, route change, or civic response appears. |
| **Resolved** | Complete through any valid path | Need, resilience, market memory, and faction state change | Follow-up is optional and should not block ordinary trade. |
| **Expired** | Clock passes without a player commitment | Scenario closes as an historical fact | The resulting world state creates new information and alternatives. |

The player must be able to tell which state they are in, what changed, and which new options are now available. Expiry is not failure of the game; it is a world transition.

### 5.3 Replacement response types

A replacement response should be selected from a small data-driven vocabulary.

| Response | Example | New play possibility |
|---|---|---|
| **Local self-organization** | Well committees ration water and pay in services instead of cash | Low-margin civic trade, future resilience, new information. |
| **Commercial opportunism** | A Free Caravan convoy buys up the shortage and resells at a premium | New price spread, escort offer, or competitive market memory. |
| **Political takeover** | Ash Wardens impose a permit regime around the failed relief corridor | Safer official route, higher fees, inspection and reputation choices. |
| **Tribal consolidation** | A warring tribe controls a bridge or water source after arms sales and failed mediation | Dangerous but profitable route, arms diplomacy, new faction ending path. |
| **Smuggling network** | Unlicensed carriers move goods through a neglected settlement | Hidden or risky trade, information chain, later crackdown or legalization. |
| **Settlement decline** | A market loses resilience and becomes cheaper to buy from but poorer to sell to | Salvage, repair, migration, and recovery opportunities. |
| **Third-party intervention** | A new neutral broker or religious/civic group opens a temporary corridor | Alternative access and a distinct ending vector. |

A replacement can be beneficial, harmful, or mixed. It must always create at least one actionable option unless the intended state is a short-term crisis spike. The game should favor **new trade geometry** over simple stat penalties.

## 6. Replacement factions and faction ecology

### 6.1 Faction design requirements

A faction that emerges from an unmet scenario must have:

1. **Material basis:** what it controls or provides.
2. **Legitimacy claim:** why settlers, traders, or workers might support it.
3. **Trade footprint:** which goods, services, routes, or prices it affects.
4. **Player relationship:** at least two ways to cooperate and one way to oppose or bypass it.
5. **Failure mode:** what happens if it becomes too powerful or collapses.
6. **Ending contribution:** a distinct value or condition in the final basin outcome.

The player does not need to conquer or permanently ally with every faction. The player should be able to profit from, assist, evade, expose, or outlast them.

### 6.2 Recommended emergent factions

These should be introduced only when their material conditions occur, not all at the start as a faction list.

| Emergent faction | Emergence trigger | Trade footprint | Possible endings |
|---|---|---|---|
| **The Well Commons** | Repeated water shortages are partially solved by local organizers rather than official relief | Water, grain, medicine, resilience projects, shared route information | Basin commons, decentralized recovery, or fragmented local autonomy. |
| **The Iron Compact** | Arms traffic and tribal conflict rise while official protection fails | Sealed arms, scrap, escorts, inspections, contested routes | Militarized order, negotiated ceasefire, or merchant-backed peace. |
| **The Ledger Houses** | Repeated profitable deliveries create a network of private credit and information | Contracts, loans represented as obligations rather than a new currency, price intelligence | Commercial reconstruction, oligarchic basin, or public audit. |
| **The Ash Pilgrims** | Crisis and settlement decline create a mobile relief and rumor network | Medicine, water, safe passage, information, temporary camps | Humanitarian corridor, migration of the basin, or a remembered refuge. |

The first vertical slice does not need all four. It should implement one replacement faction as a deterministic proof: **The Well Commons** for neglected water relief or **The Iron Compact** for escalating arms trade. The data model should still allow later additions without changing the command processor’s shape.

### 6.3 Faction pressure should alter opportunities, not remove play

Faction escalation should change prices, access, risk, and available offers before it changes whether the player can act at all. A faction may make a route expensive, require a permit, increase inspection, or create a new premium. It should not silently delete the player’s only profitable loop.

A hard closure is acceptable only when the map has at least one clearly signposted alternative. If all alternatives are worse, the UI must explain whether the player is choosing safety, time, profit, or political exposure.

## 7. Alternate endings as a composition of basin conditions

The existing multiple-ending foundation should be extended as a **vector of world outcomes**, not a branching quest tree.

### 7.1 Ending dimensions

Track a small number of interpretable dimensions:

| Dimension | What it measures | Examples of player influence |
|---|---|---|
| **Prosperity** | Whether goods, markets, and trade access recovered | Ordinary arbitrage, contracts, repairs, market memory management. |
| **Resilience** | Whether settlements can withstand future shocks | Water, medicine, civic actions, local self-organization. |
| **Legitimacy** | Which institutions people trust | Warden support, public audits, fair permits, contract behavior. |
| **Militarization** | How much security depends on arms and coercion | Arms sales, tribal conflict, escorts, inspections. |
| **Mobility** | Whether recovery is local or carried by caravans and migrants | Free Caravan support, route opening, relief networks. |
| **Transparency** | Whether the basin’s hidden failures become public knowledge | Information purchases, reports, audits, faction choices. |

A final ending should be selected from a weighted or thresholded combination of these dimensions plus a small number of specific facts. For example, “Open Routes Relief” may require high resilience and mobility, while “Ash Merchant” may require high prosperity but low transparency. No ending should require completing one named contract chain exactly.

### 7.2 Replacement factions must be ending-capable

When a player misses the initial scenario, the replacement faction should be able to contribute to at least one alternate ending. This ensures that failure opens a different authored possibility instead of merely lowering the score.

```text
missed relief contract
→ Well Commons organizes ration exchange
→ water trade becomes lower-margin but more stable
→ local resilience rises while Warden legitimacy falls
→ a commons-led ending becomes available
```

The player should be able to later support, exploit, expose, or undermine that replacement. The first consequence is not the final verdict.

### 7.3 No “correct ending” economics

The game should not treat the most humane ending as economically irrational or the richest ending as morally bad by default. Each ending should represent a coherent tradeoff. The player should be able to value stability, freedom, prosperity, transparency, or local autonomy, and the simulation should remember how that outcome was achieved.

## 8. Anti-railroading rules for implementation agents

The following rules are acceptance criteria for future agents.

| Rule | Acceptance test |
|---|---|
| **Ordinary trade is first-class** | From a clean save, a tester can complete a profitable non-contract trade and use the proceeds to continue. |
| **No mandatory named load** | The first journey can be completed with at least two different goods or two materially different plans. |
| **Offers are optional** | Declining or ignoring the first contract does not prevent departure, ordinary selling, recruitment, information, or recovery. |
| **Scenarios disclose opportunity cost** | Every time-limited offer states what changes if the player delays or declines. |
| **Failure is causal** | A missed scenario creates an inspectable state change rather than a generic “quest failed” flag. |
| **Replacement creates agency** | Every material replacement state offers at least one new route, market, service, faction interaction, or trade spread. |
| **No single dominant loop** | Scenario fixtures show at least three viable early trade patterns after fees, provisions, risk, and time. |
| **Faction pressure is reversible or bypassable** | The player can improve, evade, negotiate with, or route around a rising faction. |
| **Endings are compositional** | Alternate endings can be reached through more than one authored sequence. |
| **State is explainable** | Arrival and outlook screens summarize what the player carried, what changed, who benefited, and what is now possible. |

## 9. Deterministic data model additions

The authoritative model should remain in `src/core/`. Add data before adding UI.

### 9.1 Scenario outcome schema

```json
{
  "id": "water_relief_ashgate",
  "clock": {"start_day": 1, "deadline_day": 5},
  "states": ["offered", "accepted", "delayed", "partially_met", "failed", "resolved", "expired"],
  "failure_response": {
    "type": "emergent_faction",
    "faction_id": "well_commons",
    "trigger_stage": 1,
    "market_effects": [{"settlement_id": "reedwatch", "good_id": "water", "demand_delta": 0.08}],
    "new_opportunities": ["commons_water_exchange"],
    "ending_dimensions": {"resilience": 1, "legitimacy": -1}
  }
}
```

The exact schema may change, but the implementation must separate **scenario state**, **world effects**, **replacement content**, and **ending dimensions**. It must not encode replacement logic as a chain of UI button callbacks.

### 9.2 Trade-pattern fixtures

Add deterministic fixtures for:

- A staple-relief trade that is profitable without a contract.
- A repair-arbitrage trade with a weight tradeoff.
- A volatile medicine trade whose value changes with crisis state.
- A restricted cargo trade whose margin is offset by faction exposure.
- A market-memory case where selling changes the next price but does not erase destination profit.
- A failed scenario that creates a replacement actor and a new ordinary-trade opportunity.

## 10. Recommended implementation order

### Feed A — Protect ordinary trade

First, add or validate settlement production/consumption profiles, recurring replenishment, and the UI language that presents ordinary trade as the main Bazaar verb. Tune the first five-node slice until three non-contract trade patterns are viable.

**Implemented foundation:** Runtime content `1.17.0` gives every settlement explicit production, consumption, and ordinary-market context. Producer, consumer, and neutral markets now replenish recent-delivery pressure at different authored rates. The Bazaar leads with a source-to-need ordinary-trade story and states that no contract is required. Four deterministic non-contract fixtures—staple, repair, medicine, and industrial—must remain profitable, while an executable parity gate protects ordinary trade from being eclipsed by the opening relief contract. See `docs/economy/open_trade_foundation.md`.

### Feed B — Add one adaptive failure chain

Implement one complete scenario state machine with a visible failure response. The recommended first chain is water relief: if the player ignores or fails the relief offer, the Well Commons appears, Reedwatch’s market and resilience change, and a new commons-mediated trade opportunity opens.

### Feed C — Add replacement faction interaction

Give the emergent faction at least two cooperation paths and one bypass or opposition path. Ensure its presence changes the map and outlook rather than adding another isolated dialogue screen.

### Feed D — Rebalance authored rewards

Compare ordinary trade, contract, civic, and faction income per ten-minute fixture. Adjust rewards so contracts are attractive but not mandatory. Track ashmarks, provisions, capacity, standing, and time separately; do not introduce a new currency to compensate for a broken baseline.

### Feed E — Compose endings

Connect the replacement faction and ordinary trade outcomes to existing ending dimensions. Add one alternate ending fixture reachable through scenario failure followed by ordinary trading.

## 11. Final recommendation

The best structure for Market of Ash is a **deterministic systemic sandbox with authored pressure, not a quest-led trading campaign**. The player should begin with a broad economic playground, receive situations that tempt them to specialize or intervene, and see the basin reorganize itself when they do something else. The world should remember trade volume, delays, shortages, political exposure, and local recovery. That memory should create new geography of value.

The most important commercial-quality signal is not whether the player completed the intended first contract. It is whether they can explain why their own route worked, what their omission changed, and what they want to try next. If the player says, “I ignored the relief run, so the Well Commons took over and now I want to trade into their new water market,” the game has achieved the intended non-railroaded identity.

## References

[^1]: [Raph Koster, “Player-driven economies,” 2021](https://www.raphkoster.com/2021/04/01/player-driven-economies/)
[^2]: [Game Development Stack Exchange, “Designing a trade / market system,” 2016–2018](https://gamedev.stackexchange.com/questions/134095/designing-a-trade-market-system)
[^3]: [GDKeys, “Keys to Economic Systems,” 2021](https://gdkeys.com/keys-to-economic-systems/)
