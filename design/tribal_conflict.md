# Market of Ash — Tribal Conflict and Arms Trade

## Design decision

Market of Ash should add two rival tribal powers whose strength grows through the same trading system the player already enjoys. The player can buy and sell weapons for excellent margins, but weapons are not abstract commodities. A delivered shipment changes who can protect roads, control water, intimidate settlements, or challenge the Ash Wardens.

The purpose is not to turn the game into a separate strategy-war layer. The purpose is to make trade more consequential. A weapon sale should remain a satisfying **buy-low, carry-risk, sell-high** decision, while the consequences appear on the map through new escorts, inspections, route closures, contract demand, and settlement fear.

> **Weapons should be the most politically consequential goods, not the only profitable goods.**

## The two rival powers

### The Cinder Riders

The Cinder Riders are mobile clans who know the Old Road, seasonal water points, and informal routes better than any official survey. Their public goal is to keep movement open for frontier families, escorts, and independent caravans. Their private need is to secure enough water, mounts, and weapons to prevent another displacement from becoming permanent.

They are not a noble band of freedom fighters. Their young war bands can convert protection into tolls and intimidation as their weapons accumulate. Their elders and mediators want a route compact; their route clans want control over the old paths; their younger fighters want the power to prevent anyone from closing them.

| Cinder Rider strength | Cinder Rider danger |
|---|---|
| Safer Old Road escorts and local route knowledge. | Armed escorts become coercive and can intimidate settlements. |
| Low-friction informal movement. | Checkpoints and rival patrols appear when power grows. |
| Strong frontier alliances. | Young war bands may turn a profitable shipment into open conflict. |

### The Salt Crown

The Salt Crown is a confederation of cistern houses, salt workers, and water guardians around Brine Cross. Its public goal is to restore the old cistern law, under which water, salt, and defense are held by a recognized basin authority. Its private need is to reclaim the wells and salt flats that were divided among merchants and Wardens after the ashfall.

They can genuinely stabilize water distribution and defend the wells. They can also turn that stability into a monopoly. Their cistern houses want predictable law, salt lords want exclusive tolls, and water priests want public obligations attached to every barrel.

| Salt Crown strength | Salt Crown danger |
|---|---|
| Stable water convoys and well security. | Water access becomes permission-based. |
| Strong defense around Brine Cross. | Cistern law can become a resource monopoly. |
| Ability to coordinate large contracts. | Armed power can be used to enforce rationing. |

## What makes the tribes different

The Cinder Riders should gain power through **movement**. Their benefits improve the Old Road, frontier escorts, and open contracts. Their danger is intimidation and route fragmentation.

The Salt Crown should gain power through **control**. Their benefits stabilize water, wells, and emergency convoys. Their danger is tolls, inspections, and monopoly access.

This gives the player a meaningful choice between two kinds of regional order without reducing the conflict to good versus evil.

## State model

The design uses four visible conflict axes. The existing Warden Control, Caravan Openness, and Settlement Resilience axes remain important. The tribal layer adds only the states necessary to make the new system understandable.

| State | Range | Meaning |
|---|---:|---|
| **Cinder Rider Armed Power** | 0–5 | Capacity to protect routes, coerce rivals, and act as a regional power. |
| **Salt Crown Armed Power** | 0–5 | Capacity to defend wells, enforce cistern law, and dominate water access. |
| **Tribal Conflict** | 0–5 | The region’s level of confrontation, from uneasy trade to open war. |
| **Tribal Legitimacy** | 0–5 | Whether settlements believe a tribe is protecting people rather than accumulating power. |

Armed power alone must not make a tribe a stable major faction. The threshold for major-faction status requires both **armed power** and **legitimacy**. A faction with power but no legitimacy creates fear, route closures, and emergency events rather than a sustainable new order.

## Weapon goods

Weapon goods use the ordinary Market of Ash trade loop. They have a source, inputs, bulk, price, buyers, route risk, and delivery outcome. The player can ignore them and still build wealth through water, grain, medicine, scrap, charcoal, and cloth.

| Good | Source | Profile | Effect when delivered |
|---|---|---|---|
| **Scrap Blades** | Cinderford | High margin, low bulk, modest risk. | +1 armed power and better local defense. |
| **Reed Bows** | Reedwatch | Medium margin, low bulk, frontier demand. | +1 armed power and stronger escorts. |
| **Salt-Crown Lamellar** | Cinderford | High margin, high bulk, serious commitment. | +2 armed power and stronger defensive control. |
| **Powder Components** | Hollow Market | Very high margin, high risk. | +3 armed power and substantial conflict escalation. |

Weapon prices should rise with conflict, but so should inspections, route danger, seizure risk, and the cost of maintaining neutral access. This prevents conflict from becoming an automatic money printer.

The player should see the buyer, shipment size, expected power change, route risk, likely rival response, and settlement or civilian risk before confirming a sale. After delivery, a report should explain whether the shipment strengthened escorts, stabilized wells, escalated the rivalry, or was diverted.

## Escalation model

Conflict should move through visible stages rather than jumping from peaceful trade to total war.

| Stage | Map changes | Arms behavior | Player alternatives |
|---|---|---|---|
| **Uneasy Trade** | Small camps, escort requests, missing-cargo rumors. | Both tribes seek small defensive shipments. | Sell arms, carry civilian goods, mediate. |
| **Armed Escorts** | Tribal escorts, weapon contracts, inspection marks. | Small arms improve protection and competition. | Split shipments, sell tools and armor, share warnings. |
| **Contested Routes** | Checkpoints, closed segments, refugee camps, patrols. | Large shipments alter route control. | Run risk, fund neutral escorts, mediate. |
| **Open War** | Burned markers, camps, displacement, water convoy demand. | High-risk arms become extremely profitable. | Choose a side, run relief, sell defensive goods only. |
| **Regional Emergency** | Rationing, delegations, mobilization, emergency contracts. | The stronger tribe may become a major faction. | Support power-sharing, protect refugees, build shared defense. |
| **New Order** | Banners, new toll rules, treaty or military rule. | The player sees the permanent market consequences. | Accept, publish the ledger, back a compact, or leave. |

The map must show escalation through patrol icons, banners, changed route profiles, refugee markers, demand changes, and settlement reports. A hidden conflict meter alone is not acceptable.

## Conflict events

### A Weapon Has a Buyer

The first weapon contract introduces the idea that the same shipment can support different political outcomes. The player can sell to the Cinder Riders, sell to the Salt Crown, split the shipment and disclose the competition, or sell tools instead.

The fourth option is essential. The player should always have a non-arms way to make a useful margin or improve resilience.

### The Escort That Wasn’t Neutral

After one tribe gains armed power, the player receives a cheaper escort offer from that side and a warning from a supposedly neutral escort. The cheaper option reduces immediate travel risk but gives the Old Road a political owner. A neutral escort costs more and lowers conflict.

This event makes the political consequence of arms visible through the ordinary travel loop.

### The Cistern Gate

When the Salt Crown reaches significant armed power during a water shortage, it offers protected water in exchange for exclusive access. The player can accept, fund a neutral convoy, or sell a very high-risk shipment to the Cinder Riders.

This event should force a meaningful comparison between margin, water access, resilience, and future route availability.

### The Basin Chooses

When conflict reaches open war or either tribe becomes strong enough to claim regional authority, delegations arrive in Ashgate. The player can back the Cinder Riders, back the Salt Crown, force a shared compact, or take one final arms contract and leave.

The final choice should use the player’s accumulated trading history. A player who delivered water and medicine should have more leverage than one who only sold arms. A player who maintained neutral routes should unlock a stronger compact option.

## Meta-game progression

The meta layer should feel inspired by the satisfying sense of persistent enterprise and political position found in strategy progression, but it must remain subordinate to the caravan loop. It should provide capacity, information, and optional commitments rather than passive wealth or a separate kingdom-management game.

### Caravan Enterprise

The Route Ledger reveals price history and faction demand. The Warehouse Lease stores one extra good between days. The Repair Wagon protects a selected cargo commitment from route obstacles. The Chartered Convoy reduces the risk of a high-value shipment without removing political consequences.

### Political Capital

The Public Manifest shows buyer and route consequences before a sale. Neutral Brokerage unlocks mixed escorts and mediation contracts. The Shared Storage Charter protects one shared reserve from faction seizure. The Regional Seat unlocks the power-sharing negotiation at the end of the conflict arc.

| Upgrade | What it adds | What it must not do |
|---|---|---|
| **Route Ledger** | Better price and demand information. | Guarantee profitable trades. |
| **Warehouse Lease** | More timing flexibility. | Create passive income. |
| **Repair Wagon** | More resilience on chosen routes. | Remove all obstacle risk. |
| **Chartered Convoy** | Safer high-value transport. | Make weapons consequence-free. |
| **Public Manifest** | Clearer political information. | Force one moral answer. |
| **Neutral Brokerage** | More mediation and mixed-escort choices. | Make every faction equally friendly. |
| **Shared Storage Charter** | One recovery reserve. | Prevent all seizures or shortages. |
| **Regional Seat** | Influence over the final settlement. | Turn the player into an omnipotent ruler. |

The long-term progression should unlock better questions. It should not make early trading obsolete or replace the route-and-cargo decisions with a passive upgrade tree.

## Major-faction outcomes

The Cinder Riders become a stable major faction when their armed power reaches 4 and their legitimacy reaches at least 2. The Old Road becomes open under escort culture, but water remains negotiated and prices volatile.

The Salt Crown becomes a stable major faction when its armed power reaches 4 and its legitimacy reaches at least 2. Water becomes stable inside the cistern system, but permissions and tolls grow more important.

A shared compact becomes possible when tribal legitimacy is at least 4, tribal conflict is at most 1, and settlement resilience is at least 3. Neither tribe dominates. Convoys and public measures reduce extreme volatility, but peak margins fall.

The player can also leave rich after taking a final arms contract. This should be a valid but morally and strategically costly ending: the caravan succeeds, while the region inherits higher conflict and lower resilience.

## Guardrails

The arms layer must preserve the pleasure of ordinary trade. A player should be able to become wealthy through non-weapon goods and still reach strong endings. Weapons should be more politically consequential, not categorically better.

The player should never be told only that “conflict increased.” They should see who received the shipment, how much power changed, which route became dangerous, and what the settlements expect next.

Tribes should have internal factions and agency. A shipment can be used for escorts, defense, coercion, or revenge depending on the current state. The player influences the political map but does not control every outcome.

The conflict layer should create more contracts, route choices, and map changes. It should never suspend trading to run a separate combat campaign. If the player wants to avoid arms dealing, the game should offer relief contracts, infrastructure work, neutral convoy work, and public distribution as viable alternatives.

The final test is simple: after every arms sale, the player should be able to answer **what profit did I make, who became stronger, what route or resource is now at risk, and what can I do next?**
