# Market of Ash — Economy and Settlement Visits

## Design decision

Market of Ash must preserve the pleasure that makes Frontier memorable: buying low, selling high, spotting a distant shortage, carrying a valuable cargo through risk, and discovering that the market has changed by the time the caravan returns.

The game should not replace that loop with a strategy layer that merely awards contracts or reputation. **Commerce remains the main verb.** Politics, crisis, companions, guards, information, and infrastructure exist to make the trade decision richer and more consequential.

> The player should be able to open the map, see a price mismatch, understand why it exists, judge the cost of reaching it, and decide whether the expected margin justifies the risk.

## Frontier pillars to preserve

### Regional price differences

The same good should have different prices at different settlements. The difference comes from production, local demand, recent deliveries, crisis state, faction influence, route condition, and information quality. It must never feel like an arbitrary table of numbers.

Cinderford should make scrap and charcoal relatively cheap because of its furnaces. Reedwatch should produce grain but pay a premium for water and medicine. Brine Cross should have access to water while its wells remain healthy, but pay for medicine, grain, and repairs. Hollow Market should offer cloth and medicine with volatile prices because rumors and caravan arrivals move its market. Ashgate should be comparatively stable, but regulated.

The player does not need to know every formula. They do need to see a short explanation such as **“Medicine is expensive here because the last clinic shipment was intercepted”** or **“Charcoal is cheap because Cinderford’s furnaces are running below capacity.”**

### Distant places being more profitable

Distant trade should provide the largest possible margins before risk, but it should never dominate every nearby decision. A distant trip consumes money, provisions, days, cargo capacity, and attention. It can also expose the caravan to a changing crisis, a route obstacle, a deadline, and a market that no longer looks the same on arrival.

The route preview should display:

| Value | Meaning |
|---|---|
| Purchase total | Money tied up in the cargo. |
| Sale total | Expected revenue at the destination. |
| Route cost | Money required to travel. |
| Provisions | Food or water consumed by the journey. |
| Expected loss | Risk-adjusted value of damage, theft, or delay. |
| Time cost | What other markets or contracts may change while the caravan is away. |
| Expected net profit | The best current estimate, not a guarantee. |

Nearby trips should support reliable recovery. Regional trips should be the normal profitable play. Distant trips should create memorable commitments with high upside and a believable chance of arriving too late, overexposed, or politically entangled.

### High and low demand

Demand should have texture. A settlement may be hungry for grain, desperate for medicine, or quietly accumulating scrap for a bridge project. “High demand” should not be a permanent multiplier. It should have a cause, a visible duration, and a saturation response when the player supplies the market.

A successful delivery should change the market. The player can still profit from a high-demand sale, but the settlement becomes better supplied and the next cargo load may earn less. This creates a natural cycle: find a need, serve it, then search for the next mismatch.

### Market memory

The player’s actions should leave small, legible traces:

- A large grain delivery reduces the grain premium for a short time.
- A fair water distribution improves settlement resilience and stabilizes future demand.
- A failed shipment keeps a shortage active and may create a new emergency contract.
- A faction batch changes local patrols, permits, or escort offers.
- A repaired bridge opens a shared route and improves the value of several settlements.

Market memory should create new decisions rather than permanently solve an economy. It should be bounded, reversible, and visible in the settlement report.

## Goods and market personalities

| Good | Cheap or abundant near | Usually needed near | What makes the trade interesting |
|---|---|---|---|
| **Grain** | Reedwatch | Cinderford and Brine Cross | Steady demand, low-to-medium margin, strong crisis relevance. |
| **Water** | Brine Cross and Ashgate | Reedwatch and Hollow Market | High margin and high bulk; moral pressure and crisis sensitivity. |
| **Scrap** | Cinderford | Reedwatch and Ashgate | Project-driven demand from bridges, repairs, and weapons. |
| **Medicine** | Hollow Market | Brine Cross and Reedwatch | Low bulk and high emergency value; demand follows events. |
| **Charcoal** | Cinderford | Hollow Market and Reedwatch | Useful industrial cargo whose long-distance margin is limited by bulk. |
| **Cloth** | Hollow Market and Reedwatch | Ashgate and Cinderford | Stable, low-bulk cargo with refugee and workshop spikes. |

Weapons remain a separate politically consequential option through the tribal-conflict framework. They use the same trade rules, but delivery changes armed power and conflict state. The player can remain prosperous by trading ordinary goods, relief cargo, or infrastructure supplies.

## The settlement visit

A settlement visit should feel like a short, readable stop on the caravan’s journey. It should not be a large role-playing hub filled with disconnected menus.

On arrival, the player sees a regional report, a settlement snapshot, local and comparison prices, current demand reasons, route warnings, active contracts, and available service capacity. Browsing costs nothing. The player can compare prices and plan a route before confirming any action.

Trade is always available and consumes no service slot. Deeper services consume one or two service slots from a default visit budget of two. This creates a gentle opportunity cost without making normal buying and selling feel artificially limited.

### Primary visit tabs

| Tab | Player question | Typical actions |
|---|---|---|
| **Market** | What is cheap here and what is valuable elsewhere? | Buy goods, sell goods, compare trends. |
| **Contracts** | Can I reserve a buyer before I depart? | Accept delivery, relief, escort, or faction contract. |
| **People** | Who can make the next route safer or more capable? | Recruit companion, hire guard, hire specialist. |
| **Information** | What do locals know that the ledger does not? | Buy market report, ask witness, inspect route. |
| **Logistics** | Can I improve the caravan before taking risk? | Repair, store cargo, prepare provisions, improve capacity. |
| **Relations** | Who is asking for access or influence? | Meet faction representative, mediate, accept a political offer. |

Unavailable actions should remain visible with a clear explanation. For example, Ashgate may show “Recruit companion — no candidate currently available” or “Store cargo — no secure warehouse lease.” This teaches settlement identity without forcing the player through a tutorial window.

## Settlement-specific opportunities

### Ashgate — the regulated hub

Ashgate offers stable prices, official permits, Warden guards, market reports, and controlled storage. The player can apply for Toll Road access or challenge an official measure. Ashgate is a good place to understand the formal economy, but the player pays in time, fees, and visibility.

The important question is whether stability is worth becoming legible to the Wardens.

### Brine Cross — the water market

Brine Cross offers cheap water before crisis escalation, but demand for medicine, grain, scrap, and fair distribution is strong. The player can join the cistern queue, ask about well quality, organize a fair water sale, or accept a Salt Crown contract.

The settlement should make the difference between **selling water** and **improving water access** visible. The first makes money. The second improves resilience and legitimacy but earns less immediately.

### Cinderford — the foundry town

Cinderford offers cheap scrap and charcoal, repair services, forge hands, weapon inputs, and industrial contracts. It is the best origin for a cargo that becomes valuable elsewhere, but the settlement itself needs grain, water, and cloth to keep working.

Cinderford should make opportunity cost tangible: sell the cheap scrap now, reserve it for a bridge, use it to make weapon goods, or turn it into caravan repairs.

### Hollow Market — the volatile bazaar

Hollow Market offers the best information and the least reliable information at the same time. The player can buy a rumor, purchase a market report, hire Tess Oryn, store goods, fence politically awkward cargo, or negotiate with faction contacts.

Its unique value is not simply cheap goods. It is the ability to see several possible futures and decide how much confidence to buy.

### Reedwatch — the frontier settlement

Reedwatch offers cheap grain and expensive water, with high demand for medicine, scrap, and defensive tools. The player can recruit a frontier scout, hire an escort, open a supply shelter, or ask a local witness about raids and family movements.

Reedwatch should be the place where a profitable cargo becomes a visible human decision. A player can sell at the peak, distribute fairly, or keep the goods for another route. None should be a morality quiz; each should alter money, resilience, relationships, and future demand.

## Action design

### Buy and sell

Spot trade is immediate, flexible, and always available. Before confirmation, the player sees unit price, quantity, total, remaining capacity, the reason for the price, and the effect of the transaction on short-term local supply.

The sale panel should answer three questions: **What do I earn now? What market am I giving up? What does this delivery change?**

### Delivery contracts

Contracts reserve a buyer, quantity, guaranteed price, deadline, and failure consequence. They should not always be better than spot trade. The guarantee is valuable because it reduces uncertainty, but the deadline and cargo commitment can make the run fragile.

A contract can also be political. A Salt Crown water contract may guarantee a high price but require exclusive passage. A Reedwatch relief contract may pay less but improve settlement resilience and future access.

### Recruitment

Recruitment should add a small number of memorable capabilities, not a roster-management spreadsheet. Nara improves route information. Jorun improves provisions and exposes fragile cargo plans. Tess opens negotiation options. Future specialists should alter a small number of clear decisions.

Every recruit should show role, mechanical hook, upkeep, personal goal, fear, and relationship risk before joining.

### Guards

Guards reduce risk for a visible duration and identify their sponsor. They should not erase obstacles or guarantee cargo safety. A Cinder Rider escort can make the Old Road safer while making the caravan less neutral. An Ash Warden escort can reduce route risk while increasing inspection pressure.

The player should see risk before and after the guard, the covered routes, duration, sponsor, and political alignment.

### Information

The player can buy a market report, ask a local witness, inspect a route, or buy a rumor. Information should improve confidence rather than reveal a perfect future.

A report should name its source, markets covered, forecast window, confidence, and what would invalidate it. This makes uncertainty a decision rather than an arbitrary surprise.

### Logistics

Repairs, storage, provisions, and capacity upgrades turn money into future trading flexibility. They should compete with buying a larger cargo load.

Storage is particularly important because it supports speculation without making it free. Stored goods occupy money, have a security or spoilage risk, and may face a changed market when retrieved.

### Diplomacy and relief

Meeting a representative opens faction contracts, escorts, or political information. It makes the caravan’s position visible and can close other options.

Relief actions convert margin into stronger future markets. They can distribute water, open a supply shelter, support a bridge, or protect a shared reserve. The return is resilience, legitimacy, and future access rather than immediate profit.

## A sample settlement visit

The caravan arrives at Hollow Market with medicine from the previous run and enough capacity for one large cargo. The Market tab reports that Reedwatch is paying a premium for water and medicine, but the Information tab shows that an ash front may close the Dry Cut tomorrow.

The player can sell the medicine now for a reliable margin, buy cheap cloth for Ashgate, and leave. Alternatively, they can spend one service slot on a market report, accept a Reedwatch medicine contract, and hire a guard. The expected profit is higher, but the caravan now has a deadline and a political sponsor. A third option is to store the medicine, buy charcoal, and take a Cinderford contract that pays less but avoids the storm.

The important outcome is not that one option is correct. It is that each option creates a legible trade between margin, time, safety, information, and future opportunity.

## Progression and the meta layer

The persistent layer should add enterprise capacity and political leverage without replacing the trade loop.

| Upgrade | New possibility | Limitation |
|---|---|---|
| **Route Ledger** | Price history, comparison view, demand trends. | No guaranteed prices. |
| **Warehouse Lease** | Store one extra good between visits. | Storage costs money and carries risk. |
| **Repair Wagon** | Protect selected cargo from route obstacles. | Does not eliminate all loss. |
| **Chartered Convoy** | Move high-value cargo more safely. | Sponsor becomes visible and political. |
| **Public Manifest** | Preview buyer and settlement consequences. | Does not reveal the morally correct choice. |
| **Neutral Brokerage** | Unlock mixed escorts and mediation. | Lower peak margins than war contracts. |
| **Shared Storage Charter** | Protect one reserve from faction seizure. | Only one reserve and only under defined conditions. |
| **Regional Seat** | Influence the final water-and-road settlement. | Requires sustained legitimacy and resilience. |

These upgrades should make the player better at asking and answering trade questions. They should not create passive income, remove distance, or turn every market into a profitable vending machine.

## Implementation slices

### Slice 1 — Economy presentation

Expose the existing price modifiers, demand modifiers, crisis modifiers, and faction modifiers in a settlement market panel. Add regional comparison and a reason string. Preserve the current deterministic `price_for` and `projected_profit` functions while making their inputs visible.

### Slice 2 — Market memory

Add bounded settlement supply pressure and delivery memory. A completed sale changes the next offer within a predictable window. Add a deterministic test for saturation and recovery.

### Slice 3 — Route profit preview

Add route cost, provisions, expected loss, time cost, and expected net profit to the route preview. Keep nearby, regional, and distant route bands distinct.

### Slice 4 — Settlement service actions

Implement the settlement action registry with two service slots. Begin with recruitment, guards, reports, repairs, and one relief action. Every action must return a visible result and a deterministic state change.

### Slice 5 — Contracts and faction effects

Add contract reservation, deadlines, sponsor visibility, and the first Cinder Rider/Salt Crown contract effects. Connect weapon deliveries and escort choices to the existing tribal-conflict framework.

## Quality bar

A player should be able to identify the source of a price spread, see at least one profitable alternative, understand the route cost, and know what a settlement visit will consume before confirming an action.

A good market run should create a story in the player’s own words: **“I found cheap charcoal in Cinderford, but I chose medicine from Hollow Market because Reedwatch’s clinic contract was expiring. The Dry Cut was more profitable, but the Toll Road kept the cargo intact. Next time I can use the warehouse to wait for the water price to recover.”**

If the player can only say “the game gave me a high number,” the economy has failed. If the player can say why the number exists, what changed it, and what risk they accepted to exploit it, Market of Ash is preserving the Frontier inspiration.
