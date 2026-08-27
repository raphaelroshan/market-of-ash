# Market of Ash — Event, Meeting, Occurrence, and Regional Development Catalogue

**Author:** Manus AI  
**Status:** Content direction and implementation backlog; not a request to activate every entry in alpha  
**Purpose:** Give the game a region that feels inhabited, interdependent, and capable of remembering trade without burying the player in random interruptions.

> **Core content rule:** Every major occurrence changes at least one of **route access, available information, cargo or money, faction reputation, crew trust, settlement resilience, or crisis stage**. It does not exist merely to add flavor.[1]

The desired player story is not “a random event happened.” It is: *“I carried water through a road I knew was exposed; at the chalk gate I paid an unfair fee because the medicine contract would expire; the fee made me postpone the bridge repair; Cinderford remembered.”* The region should create this kind of causal chain through compact, legible scenes.

## 1. Use the Catalogue as a Controlled Content System

The catalogue is divided into **travel events**, **settlement occurrences**, **market developments**, **people and chance meetings**, **political pressure**, **crisis beats**, and **persistent regional projects**. A single trip or visit should not sample every category. The game uses them to add texture around trade, not to replace trade.

| Frequency band | What it does | Maximum cadence | Content rule |
| --- | --- | --- | --- |
| **Observation** | Adds context, rumor, visual change, or a small forecast update. | One per travel leg or settlement arrival. | Never blocks movement; can be dismissed after reading. |
| **Decision event** | Presents a real cost, risk, or relationship choice. | Normally one per journey; rarely two in a crisis peak. | At least two understandable options, stated prerequisite, and recoverable result. |
| **Meeting** | Introduces a person, offer, warning, or future thread. | One per settlement visit at most. | Must connect to a cargo, route, service, faction, or later event. |
| **Market pulse** | Changes an opportunity, price cause, supply pressure, or contract lead. | At arrival/day change; summarized rather than modal. | Gives a reason and duration, never unexplained price volatility. |
| **Regional development** | Changes a route, settlement, crisis state, or ending variable over multiple actions. | Several campaign beats, not random. | Must become visible on the map/shop and be testable from state. |

### Event selection principles

An event should be selected by explicit predicates: origin, destination, route, cargo tags, cargo value, crew, faction tier, settlement resilience, crisis stage, contract status, prior decisions, and a deterministic roll. The selector should prefer **unseen relevant content**, suppress repetitions, and never trigger a scene that cannot change the current plan. A player carrying no valuable cargo on a safe route does not need a robbery scene; they may instead see a route-marker observation or an opportunity at arrival.

The standard output contains a title, one concrete setup paragraph, two to four choices, exact preconditions, a short “what is at stake” line, a structured result, and a visible follow-up. Result copy uses nouns and verbs: barrels, seals, axle pins, cups, names, bridge planks, permit stamps. It avoids destiny, corruption, suffering, or freedom as abstract concepts when a more concrete consequence can be named.

## 2. Authoring Schema and Tags

The GPT agent should represent entries as data plus core resolver functions, never executable prose. The early implementation only needs the four canonical events; this catalogue supplies variants after the event seam is proven.

```json
{
  "id": "old_road_wagon_of_glass",
  "category": "travel_decision",
  "scope": "old_road",
  "priority": "core_variant",
  "weight": 3,
  "cooldown_days": 4,
  "trigger": {
    "origin_ids": ["ashgate", "cinderford"],
    "destination_ids": ["reedwatch", "hollow_market"],
    "route_ids": ["old_road"],
    "cargo_tags_any": ["fragile", "medicine"],
    "crisis_stage_min": 0
  },
  "setup_text_key": "event.old_road_wagon_of_glass.setup",
  "choices": ["pay_to_help", "trade_for_passage", "leave_them"],
  "effects": ["money", "cargo", "route_condition", "settlement_resilience", "crew_trust"],
  "follow_up_ids": ["reedwatch_glass_shortage", "nara_witness_note"],
  "test_tags": ["route", "cargo", "money_block", "follow_up", "save_replay"]
}
```

| Tag family | Examples | Why it matters |
| --- | --- | --- |
| **Cargo** | `water`, `medicine`, `grain`, `scrap`, `charcoal`, `cloth`, `fragile`, `high_value`, `arms`. | Ensures cargo changes the scene rather than being a cosmetic inventory count. |
| **Route** | `old_road`, `toll_road`, `dry_cut`, `exposed`, `regulated`, `provision_heavy`, `bridge`. | Ensures the map route has a specific personality. |
| **Social** | `warden`, `free_caravan`, `cinder_rider`, `salt_crown`, `neutral`, `sponsor_visible`. | Converts affiliation into practical access, cost, or risk. |
| **Crew** | `nara`, `jorun`, `tess`, `unsettled`, `trusted`, `committed`. | Gives a person a useful, imperfect hook. |
| **Regional** | `resilience_low`, `water_shortage`, `furnace_dim`, `market_volatile`, `route_closed`, `infrastructure_project`. | Makes ongoing developments visible and testable. |
| **Outcome** | `information`, `delay`, `loss`, `access`, `debt`, `goodwill`, `market_pressure`, `escalation`. | Lets tests assert a specific player-facing result category. |

## 3. The Four Canonical Alpha Events

These are the first implementation events. Each has a core version, variants, and durable follow-through. Do not implement every variant at once; build the core truth table and resolver, then add variants only after the event is understandable in playtests.

| ID and title | Setup and trigger | Player choices | Immediate result | Persistent follow-through |
| --- | --- | --- | --- | --- |
| **E01 — The Gatekeeper’s Chalk** | On Toll Road, an Ash Warden clerk has marked the caravan wheels with a fresh chalk circle. Triggered by regulated cargo, visible contract, or Warden scrutiny. | Pay the posted toll; request a stamped review; let Tess challenge the rate; take a delayed detour. | Money/time loss, information, faction change, or route-risk change. | The route may acquire a raised-fee, cleared, watched, or “informal passage” condition. |
| **E02 — The Span at Cinderford** | A bridge crew has a failed support and recognizes scrap/charcoal in the caravan. Triggered near Cinderford or on an infrastructure route. | Sell scrap at premium; donate/reserve materials; carry a repair message; turn back and preserve cargo. | Cargo/time/resilience change and possible market pressure effect. | The span becomes patched, load-limited, reopened, or worse; future route fee/risk/market access changes. |
| **E03 — The Last Clean Barrel** | A water queue at Brine Cross or Reedwatch is down to its final sealed barrel. Triggered by water/medicine cargo and shortage stage. | Peak-price sale; fair distribution; reserve the cargo for a contract; expose a hoarder. | Money, resilience, faction standing, route/market response. | A relief lead, angry private buyer, water-ration marker, or changed water premium follows. |
| **E04 — Three Riders, No Banner** | An unmarked escort offers passage on an exposed route, especially with high-value or arms-tagged cargo. | Pay for escort; refuse; ask Nara to read the route; ask Tess who hired them; accept a faction-visible convoy. | Route risk, money, information, faction exposure, or later contact. | The sponsor is revealed or remains a future liability; access to a rider route or Warden inspection changes. |

## 4. Travel Events and Road Occurrences

Travel content must make each route feel distinct. The Old Road creates exposure, improvisation, and informal mutual aid. The Toll Road creates safety, paperwork, queues, and the cost of being legible. The Dry Cut creates urgency, provision arithmetic, heat, and private shortcuts. Every entry below assumes the player sees a route forecast before departure; events should amplify the stated risk rather than introduce a completely unrelated punishment.

### 4.1 Old Road — exposed, cheap, remembered by travelers

| ID | Event | Trigger and setup | Choices | Result and development thread |
| --- | --- | --- | --- | --- |
| **OR01** | **The Wagon of Glass** | A wagon loaded with clinic glass has overturned in an ash ditch. Medicine/fragile cargo or Nara increases relevance. | Help right the wagon; trade a rope/repair part for their route note; pass; take a risky shortcut while they block the road. | Help creates Reedwatch clinic goodwill and a medicine demand lead; trade reveals a temporary dry patch; shortcut adds axle risk. |
| **OR02** | **Borrowed Axle** | A caravan wheel has been patched with three different woods and fails at a marker. Scrap/charcoal or Cinderford ties. | Sell a spare part; offer labor for a delayed escort; buy their remaining cargo cheaply; leave a note at the next post. | Can create cheap cloth/grain opportunity, Cinderford relationship, or a later accusation that the caravan profited from a breakdown. |
| **OR03** | **Roadside Ledger** | A dead courier’s waterproof ledger is pinned under a stone. | Read and share the delivery list; sell the information at Hollow Market; deliver it unopened; burn it after noticing names. | Gives market confidence/contract lead, faction suspicion, or a named family meeting. Nara dislikes selling it during shortage. |
| **OR04** | **Ash Bloom** | A pale fungus has erupted across the roadside after rain, making the route smell of metal and fruit. | Detour for safety; gather a small sample for a healer; press on with reduced visibility; pay a local guide. | Introduces temporary medicine demand, visibility/risk modifier, and a later Hollow Market buyer. Never causes hidden poisoning. |
| **OR05** | **The Shared Fire** | Three caravans have formed a night fire around a broken milestone. | Join and share a rumor; trade provisions for an escort tomorrow; keep moving; tell a useful lie. | Information confidence changes, provision change, social debt, and a chance meeting recurrence. Jorun favors stopping when reserves allow. |
| **OR06** | **Fence of Bells** | A line of tin bells has been strung across the road by unknown hands. | Ring through; inspect with Nara; cut the line; pay a child watching from the scrub. | Reveals a raid/inspection warning, draws attention, or identifies a new local route condition. |
| **OR07** | **Basin Funeral** | The road passes a cart carrying a wrapped water worker to Reedwatch. | Slow and join the procession; deliver a condolence packet; offer water quietly; pass on. | Time, goodwill, and a later Reedwatch contact change. The event never assigns moral points; the player sees the cost in schedule/cargo. |
| **OR08** | **The White Flag Cart** | A trader displays a white cloth, claiming a convoy behind them is armed. | Trust and follow; inspect goods for a clue; keep distance; bribe them for a name. | A risk forecast becomes better/worse with stated confidence; may seed Three Riders or a Free Caravan contact. |
| **OR09** | **Milepost Auction** | Travelers have tied small useful objects to an old signpost and are bargaining before dusk. | Buy route map; sell a spare good; swap information; ignore. | Small asset/information shift with a memorable low-stakes market scene. Useful early when full decision events would be too punishing. |
| **OR10** | **Rain on the Old Ash** | Rare rain turns old ash into sticky black slurry across a low section. | Wait and lose a day; unload weight into paid storage; hire local pullers; risk the ford. | Time, money, cargo/route condition, and possible settlement storage lead. Shows cargo weight as a physical consequence. |

### 4.2 Toll Road — safe, costly, controlled

| ID | Event | Trigger and setup | Choices | Result and development thread |
| --- | --- | --- | --- | --- |
| **TR01** | **The Seal That Smears** | A permit’s ink begins to run in heat; the escort sees it before the player does. | Pay for reissue; ask Tess to validate it; accept an inspection delay; take the Old Road back. | Time/money/access change; a valid permit becomes a reusable route condition. |
| **TR02** | **Cistern Inspection** | Wardens halt water cargo to test for contamination. | Submit and wait; pay laboratory fee; distribute under observation; refuse and carry onward. | Safety/reputation/time and water market impact. A passed inspection improves later contract confidence. |
| **TR03** | **The Queue Beyond the Gate** | Protected passage is backed up by refugees, traders, and a fuel cart. | Keep place; sell provisions at fair/peak price; surrender slot for goodwill; take an unguarded night crossing. | Time, money, resilience, or a changed risk. The “safe” road costs attention as well as fees. |
| **TR04** | **Guard With a Broken Clock** | The patrol captain’s timepiece is broken, making a deadline dispute ambiguous. | Trust their word; show contract timestamp; let Tess negotiate; pay for priority. | Contract timer interpretation, faction relationship, and a later favor/debt. |
| **TR05** | **Official Weights** | A Warden scale claims the cargo is heavier than the manifest. | Reweigh publicly; accept fee; produce Jorun’s ledger; unload a unit. | Money/time/cargo and visibility. It teaches that capacity, paperwork, and fees have different reasons. |
| **TR06** | **The Ashgate Choir** | A ration petition has occupied part of the gatehouse; guards ask caravaners to witness. | Sign; decline; carry a message to Brine Cross; use the crowd to slip a private deal. | Warden/Free Caravan standing, future access, and a non-combat political memory. |
| **TR07** | **Quarantine Lanterns** | Blue lanterns mark a potential fever camp along the road. | Detour; deliver medicine through the cordon; buy verified passage; hide the cargo route. | Medicine demand, health-risk explanation, time, and future clinic contract. |
| **TR08** | **The Second Receipt** | Two officials present receipts for the same bridge maintenance fee. | Pay neither and request audit; pay one; ask Tess to identify the seal; pay both to keep moving. | Money/time/information and a later corruption/maintenance development. |

### 4.3 Dry Cut — fast, provision-heavy, hard to read

| ID | Event | Trigger and setup | Choices | Result and development thread |
| --- | --- | --- | --- | --- |
| **DC01** | **Salt Wind** | A dry gale removes the far markers and drives grit into water seals. | Spend extra provisions; follow Nara’s line; anchor and wait; race the wind. | Provision/time/risk changes; water cargo may gain a visible contamination concern, never a hidden automatic wipe. |
| **DC02** | **The Shade Tax** | A family controls the only shade awning between two hot stretches. | Pay water/provisions; trade cloth; share shade as a service; press into heat. | Supplies, goodwill, low-level settlement resilience, and a repeat route condition. |
| **DC03** | **Mirror Flats** | A salt pan reflects a false road and a distant caravan signal. | Follow the signal; use compass/route note; stay on known markers; hire a child guide. | Time/information/risk, opportunity for a meeting, and Nara route-intelligence teaching. |
| **DC04** | **The Dry Well Choir** | Travelers sing at an empty well to test whether a buried cistern resonates. | Stop to help dig; sell a water cup; take their map fragment; leave. | Water, time, resilience/project progress, and a possible shortcut once the cistern is restored. |
| **DC05** | **Heat Ledger** | Jorun identifies that the departure forecast undercounted consumption because of an ash front. | Slow and ration; discard low-value cargo for water; pay for a guide cache; push hard. | Provision/debt/cargo and a calibration flag. This must never contradict the displayed forecast without saying why conditions changed. |
| **DC06** | **Blue Lizard Caravan** | Children tow painted scrap lizards carrying message tubes between wells. | Pay to send a message; buy a fake route rumor; hire them as guides; trade cloth. | Contact, rumor confidence, small cost, and a light comic note without breaking tone. |
| **DC07** | **The Buried Gate** | Wind has uncovered a sealed maintenance hatch from before the ashfall. | Open with scrap tools; mark and report it; sell location privately; move on. | Supplies, route intelligence, faction attention, and a later infrastructure project. |
| **DC08** | **Night Water** | Another caravan offers a midnight water swap to avoid Warden records. | Trade; refuse; ask who needs anonymity; report them; buy only information. | Water/cash/reputation/black-market access. The player should understand this is about visibility and scarcity, not a binary moral choice. |

## 5. Settlement Occurrences and Local Meetings

Settlement occurrences happen at the central shop, on arrival, or after a trade. They should make a town distinct in under two sentences and give the player a concrete next decision. Most are cards or banners, not full-screen dialogues.

### 5.1 Ashgate — rules, seals, and stable prices with hidden costs

| ID | Occurrence | Player decision | Persistent result |
| --- | --- | --- | --- |
| **AG01** | **The Clerk’s Missing Stamp** | Return a missing stamp, use it to accelerate one permit, or sell it to Tess’s contact. | Permit trust, gate queue, Tess relationship, and a possible future audit. |
| **AG02** | **Ration Chalk on the Gate** | Publicly list available water, make a private sale, or sponsor a shared reserve. | Water demand, Warden visibility, settlement resilience, and a visible chalk mark. |
| **AG03** | **The Weighmaster’s Apprentice** | Teach a fair measure, pay for a faster inspection, or accept a cheap but suspicious reading. | Future fee accuracy, informal favor, or inspection risk. |
| **AG04** | **Permit Auction at Dawn** | Bid for a Toll Road window, share a slot, or take a Free Caravan lead instead. | Route access/time, social debt, and competing approach to regulation. |
| **AG05** | **A Quiet Warehouse** | Lease secure storage, help inventory reserves, or expose a hoarded cargo list. | Storage, money, resilience, Warden/Free Caravan tension. |
| **AG06** | **Tess at the Tea Counter** | Hire Tess for fee reduction, ask for a contract lead, or decline a too-convenient deal. | Tess availability/relationship and one future social option. |

### 5.2 Brine Cross — water commerce, salt, and fairness under pressure

| ID | Occurrence | Player decision | Persistent result |
| --- | --- | --- | --- |
| **BC01** | **The Cistern Queue** | Wait, pay to reserve, distribute a barrel fairly, or use an informal broker. | Time/money/resilience/black-market access. |
| **BC02** | **Salt on the Ledger** | A medic says the well tests are being diluted with brine. | Buy a test, carry medicine samples, expose the report, or sell water before the panic. | Future water confidence, medicine demand, Salt Crown attention, and crisis pressure. |
| **BC03** | **The Empty Jar Bells** | Children hang empty jars to announce a dry well. | Fund repairs with scrap, sell cloth for labor, buy a rumor, or move on. | Project progress, local need, and sound/visual world change. |
| **BC04** | **The Private Cistern** | A household offers premium water with no questions. | Buy/resell, report, negotiate public access, or refuse. | Cash, reputation, availability, and a later buyer/accuser. |
| **BC05** | **The Salt Crown’s Cup** | A Salt Crown representative asks for exclusive water carriage. | Accept, negotiate a public quota, ask Tess for terms, or refuse. | Contract/faction access with visible route and social costs. |
| **BC06** | **The Last Cooper** | A barrel-maker can repair seals, teach an apprentice, or sell their last hoops. | Water spoilage protection, money, and a local craft survival variable. |

### 5.3 Cinderford — furnaces, repairs, and the cost of materials

| ID | Occurrence | Player decision | Persistent result |
| --- | --- | --- | --- |
| **CF01** | **Furnace Three Goes Dark** | Sell charcoal to the foundry, buy discounted scrap, fund a repair, or carry the news. | Charcoal/scrap price shift, resilience, bridge capacity, and visual furnace state. |
| **CF02** | **Jorun’s Audit** | Accept a reserve plan, pay for repairs, or ignore a cargo warning. | Jorun availability/trust, provision forecast quality, and a future breakdown modifier. |
| **CF03** | **The Bridge Bolt Board** | Allocate scrap to public bridge, private repair, or arms buyer. | Route condition, caravan durability, escalation, and Cinderford goodwill. |
| **CF04** | **Night Shift Wages** | Deliver grain/cloth relief, lend cash, or buy output while workers are desperate. | Labor stability, prices, future contract/access, and social consequence. |
| **CF05** | **The Forgemaster’s Son** | Carry a sealed tool parcel, ask what it is, report it, or refuse. | Information, arms/infrastructure thread, faction attention. |
| **CF06** | **Soot Wedding** | Attend briefly, provide a gift of cloth, hire a worker, or keep schedule. | Local relationship, labor/repair discount, time, and a human recurring face. |

### 5.4 Hollow Market — information, ambiguity, and useful lies

| ID | Occurrence | Player decision | Persistent result |
| --- | --- | --- | --- |
| **HM01** | **Three Prices for the Same Medicine** | Buy the certified batch, the cheap unmarked batch, a market report, or no medicine. | Cost, risk/information confidence, clinic trust, and a future dispute. |
| **HM02** | **Nara’s Free Note** | Share a route warning, sell it exclusively, verify it, or ignore it. | Nara relationship, route confidence, rival caravan behavior. |
| **HM03** | **The Mirror Broker** | Trade an honest ledger, a false ledger, a rumor, or a favor. | Information quality, reputation, future price volatility. |
| **HM04** | **Cloth With No Maker’s Mark** | Sell openly, fence it, trace the origin, or use it as relief cloth. | Money, faction/crew trust, contract lead, or future accusation. |
| **HM05** | **The Weather Reader’s Debt** | Pay for forecast, accept uncertain favor, help collect debt, or leave. | Forecast confidence, money, social exposure. |
| **HM06** | **A Table Set for Six** | A vanished caravan’s table is still rented at the bazaar. | Ask, buy the abandoned manifest, reserve their slot, or notify family. | Missing-caravan thread, contracts, rumor, or an ethical but material choice. |

### 5.5 Reedwatch — visible needs, frontier trust, and the cost of distant choices

| ID | Occurrence | Player decision | Persistent result |
| --- | --- | --- | --- |
| **RW01** | **The Clinic’s Cold Stove** | Sell medicine at spot price, fill a relief order, donate charcoal, or reserve cargo. | Money, resilience, future medicine price, and clinic contract. |
| **RW02** | **Names Beside the Well** | Read missing-person notices, carry a letter, hire a scout, or post a route warning. | Nara lead, road intelligence, local trust, and later meeting. |
| **RW03** | **The Grain Measure** | Sell grain by official weight, accept a family’s old measure, or audit the mill. | Money, Warden/Free Caravan standing, grain memory, and market trust. |
| **RW04** | **The Dry Shelter** | Fund roof repair with scrap, rent storage, let travelers use caravan shade, or refuse. | Resilience, storage, time, relationship, and a visual shelter state. |
| **RW05** | **The Frontier Scout** | Recruit a local guide, buy one route reading, sponsor shared notes, or decline. | Nara-adjacent route intelligence, money, future recruitment. |
| **RW06** | **A Child Counts Cups** | Sell water, distribute a ration, trade for a family map, or preserve supply. | Money/resilience/information and a later recognition line. |

## 6. Market Pulses and Economic Developments

Market pulses are summarized by settlement report, price reason, map symbol, or contract card. They should normally not stop a player with a modal. Every pulse includes a visible cause, duration/decay rule, and a next decision.

| ID | Development | Cause or trigger | Mechanical effect | What the player sees |
| --- | --- | --- | --- | --- |
| **MP01** | **Grain Silo Cracked** | Rain/maintenance failure at Reedwatch. | Grain supply falls; scrap/charcoal repair demand rises. | “Reedwatch’s north silo is leaking. Grain is no longer cheap; scrap may buy a repair.” |
| **MP02** | **Clinic Shipment Intercepted** | Travel incident, route pressure, or crisis stage. | Medicine premium rises at affected settlement; escort/route lead appears. | “Medicine is expensive because the last clinic shipment did not arrive.” |
| **MP03** | **Cinderford Furnace Restarts** | Charcoal/scrap delivery or project completion. | Charcoal/scrap premium softens; cloth/grain demand rises with labor. | One furnace row lights on map; price reason changes. |
| **MP04** | **False Water Report** | Hollow Market rumor, Salt Crown action, or Tess interaction. | Water forecast confidence falls; volatility band appears until verified. | “Reports conflict. Price is not unknown; confidence is low because sources disagree.” |
| **MP05** | **Bridge Crew Paid** | Scrap/charcoal/coin project contribution. | Route fee/risk changes; Cinderford/nearby prices adjust. | “The span carries loaded wagons again. Old Road weight limits are lifted.” |
| **MP06** | **Ration Week** | Crisis escalation at Ashgate/Brine Cross. | Water/grain access restrictions, relief contracts, price cap/exceptions. | Gate chalk, public board, and clear date/condition. |
| **MP07** | **Cloth Caravan Arrives** | Hollow Market traffic or Free Caravan lead. | Cloth supply rises; frontier/worker demand can shift. | Colored banners appear; regional comparison marks the influx. |
| **MP08** | **Repair Tool Shortage** | Cinderford labor event or bridge damage. | Scrap value rises; repair costs rise; route wear increases. | “Every usable bolt has a name on it.” |
| **MP09** | **Well Tests Posted** | Player buys/shares information. | Water price confidence/risk changes; Warden/Salt Crown response. | Public test board with source and expiry, not a hidden buff. |
| **MP10** | **Convoy Season** | Route condition favorable for several days. | More competition: certain margins narrow, escort availability rises. | Caravan icons and “traffic high” route state. |
| **MP11** | **Night Market Ban** | Warden crackdown or violence escalation. | Informal contract/rumor access shrinks; official routes strengthen. | Hollow Market lamps dim, notice appears, Tess reacts. |
| **MP12** | **Shared Reserve Opened** | Relief/infrastructure threshold. | Emergency price spikes soften; resilience improves; private high-margin sale becomes less attractive. | A reservoir icon and “public cups available” status. |

## 7. Random Meetings and Recurring People

These are not collectible quest-givers. A meeting must alter information, access, a future choice, or a relationship. Each person can recur in changed circumstances, allowing small continuity without a large branching-narrative burden.

| ID | Person or meeting | First appearance | What they offer | Recurrence / resolution |
| --- | --- | --- | --- | --- |
| **PM01** | **Mara Quill, the barrel counter** | Brine Cross queue; she counts every seal twice. | Barrel inspection, water-loss warning, cooper lead. | Later asks for scrap hoops; becomes a fair-distribution witness or a private-cistern critic. |
| **PM02** | **Siv, the milepost painter** | Old Road repainting erased route marks. | Route condition note, marker repair service. | Their paint code reveals who has been altering public signs. |
| **PM03** | **Belo and the blue lizards** | Dry Cut messenger children. | Short message delivery, imperfect rumor, guide discount. | A missing message becomes a route/event thread; they can open a harmless shortcut only after trust. |
| **PM04** | **Ilan Dross, former Warden medic** | Clinic issue or Toll Road quarantine. | Medicine quality check, official process insight. | Their old report connects to reservoir concealment and Tess’s history. |
| **PM05** | **Hessa, the unlicensed map seller** | Hollow Market. | Cheap map, expensive verified map, provenance clue. | A map may be wrong but never silently; verification reveals a new condition or a deliberate fraud. |
| **PM06** | **The Knot Sisters** | Reedwatch shelter, tying water ration cords. | Relief distribution, fabric trade, family route information. | They remember fair/peak-price water sales and influence a local support option. |
| **PM07** | **Orren Vale, bridge accountant** | Cinderford span event. | Project ledger, audit of public materials, toll receipt clue. | Can expose theft, regularize a project, or become complicit depending on player action. |
| **PM08** | **The Quiet Driver** | Any road; wagon has no banner and no visible cargo. | A paid ride/escort, a silent trade, or a warning. | Their sponsor is revealed through Three Riders/arms content, not by arbitrary betrayal. |
| **PM09** | **Kett, the ash beekeeper** | Old Road rain/ash bloom. | Minor medicine ingredient, weather observation, wax-seal repair. | Their hives become a small resilience project or a hazard if neglected. |
| **PM10** | **The One-Page Poet** | Ashgate or Hollow Market. | A cheap notice that shifts rumor/market attention; a short human break. | A player can fund a public route notice; later it changes information availability. |
| **PM11** | **Dena Voss, the contract widow** | Ashgate permit queue or Reedwatch noticeboard. | A failed delivery’s unused contract terms, not a free reward. | Helps create a recovery contract, expose deadline cruelty, or preserve a missing caravan’s reputation. |
| **PM12** | **Rook, the retired convoy horse** | Cinderford stable or roadside. | A small capacity/tempo flavor hook with no automatic economic engine. | Can become a repair-wagon visual symbol if player funds care; no mandatory animal-management system. |

## 8. Political Pressure and Faction Developments

Faction content is practical. It should alter permits, safety, information, access, contracts, escort availability, inspections, informal fees, or settlement resilience. It should not be a morality scorecard.

| ID | Development | Trigger | Choice | Lasting consequence |
| --- | --- | --- | --- | --- |
| **FP01** | **Warden Road Census** | Higher Warden visibility or crisis stage one. | Register routes, submit partial ledger, support Free Caravan protest, pay a clerk to delay. | Official forecast/permit access versus scrutiny and informal distrust. |
| **FP02** | **Free Caravan Open Ledger** | Hollow Market/Old Road traffic and Free Caravan standing. | Share prices, contribute a rumor, withhold information, publish a false lead. | Better regional comparison/market resilience versus reduced private advantage or lost trust. |
| **FP03** | **Salt Crown Cistern Lease** | Brine Cross scarcity. | Back exclusive lease, negotiate public quota, expose terms, sell water privately. | Water access rules, future price ceiling/floor, and faction leverage. |
| **FP04** | **Cinder Rider Safe-Conduct** | Exposed route/arms or Cinderford contact. | Buy escort, carry a message, refuse, request neutral passage. | Old Road risk changes and sponsorship visibility. |
| **FP05** | **The Permit Is a Promise** | Contract deadline with route closure. | Use Warden permit, call in a Free Caravan favor, break contract openly, ask Tess for alternate terms. | Contract fate, standing, future access, and crew reaction. |
| **FP06** | **Two Flags at the Bridge** | Infrastructure project completion. | Give maintenance to Wardens, joint committee, Free Caravans, or private toll. | Route fee/risk/access and ending variable; bridge visual changes. |
| **FP07** | **Public Accusation at Market** | Arms delivery, false ledger, or exposed hoarding. | Answer openly, pay damages, enlist a witness, leave. | Trust, money, market access, and a future meeting. No hidden reputation collapse. |
| **FP08** | **The Neutral Convoy Charter** | Player has cross-faction trust and repair capacity. | Sign, decline, negotiate terms, share with a settlement. | Mixed escort/contract option with lower margin but resilience/access benefits. |
| **FP09** | **Warden Amnesty Window** | After a crackdown or minor violation. | Pay fixed fine, surrender contraband, testify, or remain informal. | Clears or deepens route friction; terms are visible and time-bound. |
| **FP10** | **Free Caravan Night School** | Player shares route knowledge or supports Hollow Market. | Fund it, give a route lesson, sell notes, refuse. | Information quality/resilience, Nara trust, and a small future informed-traveler benefit. |

## 9. Crisis Escalation Beats

Crisis beats are authored regional developments, not random events. The player sees a visible objective, observes what changed, and can infer which actions matter. The underlying state machine must remain deterministic and fixture-testable.

| Stage | Beat | Visible changes | Decision pressure | Next developments unlocked |
| --- | --- | --- | --- | --- |
| **0 — Ordinary pressure** | **The Ledger Does Not Agree** | Subtle price differences; Hollow Market rumor conflicts with Ashgate notice. | Learn comparison and choose first route. | First crew contact, toll/bridge core event. |
| **1 — Thin wells** | **Jars on the Lines** | Brine Cross bells, Reedwatch cup counts, water/medicine reasons change. | Profit from scarcity, secure contract, or support resilience. | Last Clean Barrel, well-test, relief/hoarding developments. |
| **1 — Information fracture** | **Two Forecasts, One Road** | Official and informal forecast confidence split. | Pay for information, choose sponsor, accept stated uncertainty. | Nara/Tess hooks, Warden census, open ledger. |
| **2 — Empty reservoir** | **The Reservoir Door** | A buried gate/hatch or failed inspection becomes known. | Carry scrap/charcoal/water, choose access/control posture. | Infrastructure project, Salt Crown lease, hidden report meeting. |
| **2 — Traffic hardens** | **Roads Become Arguments** | Route color/condition, inspection/escort availability, gate queue visibly change. | Safe cost versus open risk versus neutral service. | Two Flags at Bridge, Safe-Conduct, Neutral Charter. |
| **2 — The last dangerous run** | **Before the Ash Front** | A short window for a high-value delivery; routes can close/change. | Reserve cargo, make a risky run, protect reserve, complete a contract. | Crew confrontation, final contract. |
| **3 — Settlement decision** | **Who Holds the Valve?** | Water stability, route openness, wealth concentration shown together. | Invest, regulate, open access, broker privately. | Ending-specific regional report. |
| **3 — Consequence report** | **What Remains** | Each settlement shows material state and named relationships. | Reflect, continue sandbox trade, begin another strategy. | Ending archive/replay prompt. |

## 10. Persistent Regional Projects

Projects are long-form developments created by repeated decisions. They turn cargo into regional change without creating a city-builder. A project has three visible stages, one active contribution choice, a competing private use for the same cargo, and a maintenance/recovery condition.

| ID | Project | Contributions | Tradeoff | Completion effect |
| --- | --- | --- | --- | --- |
| **RP01** | **Cinderford Span** | Scrap, charcoal, coin, labor/contract delivery. | Sell materials at premium or reserve them for public route capacity. | Route becomes safer/cheaper for heavy loads; Cinderford resilience rises. |
| **RP02** | **Reedwatch Supply Shelter** | Scrap, cloth, grain, water, time. | Immediate margin versus safer storage/relief capacity. | Recovery options expand; certain cargo losses/shortages become less punishing. |
| **RP03** | **Brine Cross Test House** | Medicine, clean water, glass, coin, information. | Private water trade versus public confidence. | Forecast confidence improves; hoarding/contamination paths become legible. |
| **RP04** | **Hollow Market Notice Wall** | Cloth, coin, rumor verification, Nara support. | Sell exclusive route knowledge versus create shared information. | Better market/route intelligence; Free Caravan/Warden response differs. |
| **RP05** | **Ashgate Shared Storehouse** | Grain, water, permits, Warden/neutral backing. | Stable reserve versus controlled access and fees. | Crisis peaks soften; Warden ending potential grows. |
| **RP06** | **Dry Cut Shade Line** | Cloth, scrap, water, labor. | Spend cargo/time for access versus preserve high-margin fast route scarcity. | Provision cost/risk decreases; new meeting/route option opens. |
| **RP07** | **The Reservoir Audit** | Evidence, Tess contact, official access, coin. | Expose truth, sell leverage, negotiate repair, suppress report. | Reveals root crisis condition and affects final control/open-access options. |
| **RP08** | **Neutral Convoy Charter** | Shared ledger, mixed faction trust, repair wagon, coin. | Lower peak private margin versus resilient access across crises. | Unique safe-ish mixed route and shared-wells/open-roads ending support. |

## 11. Companion Arcs as Occurrences

Crew arcs should appear at the moment a current trade decision makes them relevant. They are short checks or conversations, not campfire interruptions after every trip.

| Character | Occurrence | Trigger | Player decision | Mechanical and relationship result |
| --- | --- | --- | --- | --- |
| **Nara** | **The Route Note Everyone Wants** | Nara has a valuable route observation and player reaches Hollow Market. | Share, sell exclusively, give to Reedwatch, keep private. | Route information/resilience/Free Caravan trust/Nara trust. |
| **Nara** | **Names Missing From the Ledger** | After road incident or Reedwatch arrival. | Carry names forward, pay for search, dismiss concern, seek Warden records. | Future rescue/route info; no mandatory rescue mission. |
| **Nara** | **Marker Under the Ash** | Dry Cut/Old Road visibility issue. | Spend time restoring marker, use it privately, report it, move on. | Route condition/information/community access. |
| **Jorun** | **The Reserve Argument** | Player loads near capacity with low provisions or takes a high-risk contract. | Keep reserve, dismiss warning, buy provisions, change cargo. | Forecast/update trust; Jorun’s value is preparation, not a veto. |
| **Jorun** | **The Empty Crate** | After a lost shipment or relief delivery. | Sell crate timber, use it for shelter, carry it back, leave. | Money/resilience/cargo space and relationship. |
| **Jorun** | **The Ledger With No Names** | Player repeatedly maximizes profits during shortage. | Record destination impact, keep private books, donate audit time, reject premise. | Market visibility/crew trust/ending variable. |
| **Tess** | **The Familiar Seal** | Toll receipt/permit event. | Let Tess call in favor, refuse, ask terms, report the seal. | Access/money/Warden trust/Tess debt. |
| **Tess** | **A Door With Two Hinges** | Contract/faction lock blocks a profitable route. | Negotiate open access, take a private deal, seek neutral help, walk away. | Contract terms/faction visibility/future price. |
| **Tess** | **The Reservoir Report** | Crisis stage two with audit evidence. | Publish, sell, negotiate repair, let it disappear. | Crisis progress/ending path/Tess relationship. |

## 12. Opportunity Chains and Causal Examples

The catalogue should generate recognizable chains, not an undifferentiated pile of cards. The examples below are design targets for authored combinations and automated scenario fixtures.

### Chain A — The bridge that changes a market

The player sees **Furnace Three Goes Dark** at Cinderford. Scrap is cheap because the foundry is stalled, but charcoal is suddenly useful. On the Old Road, **The Span at Cinderford** asks for bolts and charcoal. The player can sell scrap at a better price elsewhere, donate enough material to patch the span, or buy the crew’s delayed cargo. If the bridge is repaired, **Bridge Crew Paid** shifts route cost and makes Reedwatch’s grain more accessible. The follow-up is not “good deed completed”; it is a new network geometry and a changed trade plan.

### Chain B — Profiting from water without erasing choice

At Brine Cross, **Salt on the Ledger** casts doubt on a water test. The player can buy the test and sell verified water at a lower but reliable margin, buy unverified water and risk a clinic dispute, or help create the **Test House**. At Reedwatch, **The Last Clean Barrel** lets the player sell at peak price, distribute a portion, or preserve cargo for a contract. Each option changes money, confidence, resilience, or access. None is presented as morally clean; all state who bears the cost.

### Chain C — Safe road, expensive visibility

The player accepts a medicine contract with a deadline. Toll Road is safe, but **The Gatekeeper’s Chalk** exposes a rate dispute, then **The Queue Beyond the Gate** threatens the deadline. Tess can challenge the stamp; a Warden permit may guarantee passage but increases official visibility; the Old Road is cheap and may be informed by Nara’s shared note. The player is deciding between money, time, certainty, faction position, and future access—not simply a green profit number.

### Chain D — A neutral caravan becomes valuable

The player refuses both a suspicious escort and a private cistern deal, invests in the **Hollow Market Notice Wall**, shares route information with Nara, and later helps finish the **Neutral Convoy Charter**. The immediate margins are lower, but the player gains a mixed-access route when factions harden. This is a commercially viable, non-weapons political route; it is not a hidden “good ending” meter.

## 13. Content Budget and Implementation Order

The full catalogue is a library. The alpha should implement a selective spine before variation. The first task is to make one event format pleasant and reliable, not to populate 70 content records.

| Tier | Include | Do not add yet |
| --- | --- | --- |
| **Alpha core** | E01–E04; one Ashgate, Brine Cross, Cinderford, Hollow Market, and Reedwatch occurrence; four market pulses; one recurring contact per crew; two regional projects; first three crisis beats. | Arms-specific branches, every route variant, more than one contract type per settlement. |
| **Alpha variation** | Two variants per canonical event; one Old Road, Toll Road, and Dry Cut observation; contracts/factions that change a live route or market. | Multiple low-stakes flavor meetings with no follow-up. |
| **Beta expansion** | Remaining route events, recurring contacts, project variants, further crisis paths, richer settlement visual/audio states. | Infinite procedural event generator or content that requires a second region. |
| **Launch / post-launch only** | Carefully added rare chains after real playtest data supports them. | Live-event cadence, time-limited FOMO, online economy responses. |

## 14. Event Test Contract

A GPT agent should not add a scene because the prose is appealing. Each implemented event needs a compact truth table and tests.

| Required test | Assertion |
| --- | --- |
| **Eligibility** | Trigger predicates match route, location, cargo, crisis, crew, faction, contract, cooldown, and history rules. |
| **No false interruption** | An ineligible event cannot be selected on an unrelated trip; a suppression/cooldown behaves deterministically. |
| **Choice precondition** | Every blocked choice exposes its reason and makes no authoritative state mutation. |
| **Resolution** | Each choice applies exact named deltas, writes structured history, and creates declared follow-up state. |
| **Determinism** | Same seed, world state, event ID, choice ID, and roll reproduce same result. |
| **Recovery** | Approved early-game failure outcomes leave a legal action that can restore progress. |
| **Save/load** | Pending event, selected options, cooldown, follow-up flags, and resolved history survive a round trip. |
| **UI clarity** | Setup, stakes, choices, disabled reasons, outcome, and next action appear on the correct screen with keyboard/controller focus. |
| **Balance** | Policy simulation includes relevant cargo/route/event combinations after a rule changes. |

## 15. Writing and Presentation Checklist

| Do | Avoid |
| --- | --- |
| Name the material fact: “three barrels,” “a six-ashmark toll,” “two days late,” “one grain sack lost.” | Vague language such as “your choices have consequences” with no stated consequence. |
| Give each choice a compact verb and visible cost: **Pay 6**, **Take the detour**, **Share the route note**. | Choice labels such as **Be kind**, **Be cruel**, or **Do the right thing**. |
| Reveal uncertainty source: stale report, ash front, unknown sponsor, untested water, conflicting seals. | Surprise randomness that a player could not prepare for or understand. |
| Make local people capable, funny, tired, and specific. | Grimdark spectacle, universal misery, or disposable victims used only to prompt a sale. |
| Show regional change in map/shop art, route status, price explanation, or availability. | Consequences that exist only in buried log prose. |
| Let the player decline an offer and continue trading. | Mandatory quest chains or a single correct moral route. |

## 16. First Implementation Queue for the GPT Agent

1. Implement a single event data schema, pending-event state, deterministic selector seam, `resolve_event` command, event-card UI, save/replay support, and complete truth table for **E01 — The Gatekeeper’s Chalk**.
2. Add **E02 — The Span at Cinderford** as the first cargo-to-regional-project bridge. Prove that public infrastructure changes a later route/margin.
3. Add **MP01 — Grain Silo Cracked** and **MP03 — Cinderford Furnace Restarts** with bounded market memory after B1 is complete.
4. Add **HM02 — Nara’s Free Note** only once the first crew/information hook exists.
5. Add **E03 — The Last Clean Barrel** only once settlement resilience and relief/contract state have a tested mechanical outcome.
6. Add **E04 — Three Riders, No Banner** after faction/escort state is implemented; do not add combat.

The agent should finish the current truth table, tests, and user-facing result before advancing to the next entry. The catalogue is intended to produce **variety through state and follow-through**, not volume without memory.

## References

[1]: [Market of Ash Content Bible](../../design/content_bible.md)  
[2]: [Economy and Settlement Visits](../../design/economy_and_settlements.md)  
[3]: [Full Agent Design Prompt](../../design/design_prompt.md)  
[4]: [GPT Agent Development Handoff Roadmap](../gpt_agent_handoff_roadmap.md)
