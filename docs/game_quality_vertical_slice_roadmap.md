# Market of Ash — Game-Quality Vertical-Slice Roadmap

**Project:** Market of Ash
**Current baseline:** `0.13.2-alpha-basin-vertical-slice`
**Completed milestone:** `0.13.0-alpha-basin-vertical-slice` deterministic vertical-slice scope
**Next target:** Game-quality private-alpha presentation and complete-flow gate
**Platform:** Windows desktop first, Web as a verification surface
**Engine:** Godot 4.4.1, GDScript
**Development model:** Agent-first, deterministic, content-driven, private alpha

> **Purpose:** Turn the current technically validated trade-and-consequence prototype into a convincing, replayable, human-playtestable game-quality slice of the Five-Well Basin without rewriting the economy or expanding the game into an uncontrolled campaign.
>
> **Status clarification (2026-08-30):** The deterministic Five-Well Basin vertical-slice milestone is complete and verified. The project is **not** complete as a game-quality or commercial alpha. The current main build still shows horizontal clipping in the Main Menu and Introduction at 1280×720, and the visual evidence does not yet establish a polished complete player journey. Continue with the open game-quality execution plan.

This document is an implementation contract for GPT coding agents, visual agents, audio agents, test agents, and the product lead. It is intentionally narrower than the full Market of Ash design. The goal is not to implement every faction, good, settlement, or event. The goal is to make the **existing first basin journey feel like a game**.

**Binding addendum:** [Open Trade, Adaptive Basin, and Non-Railroaded Progression](design/nonlinear_trade_and_adaptive_basin_addendum.md) clarifies that ordinary buying and selling must remain a complete play style, and that ignored or failed scenarios must create causal replacement opportunities rather than a prescribed quest path.

---

## 1. Product decision

Market of Ash should be a compact trade-and-travel RPG about a caravan crossing a recovering ashland. The player turns local needs into money, access, trust, and obligations, knowing that every profitable route exposes the caravan to a different vulnerability.

The current code already proves the mechanical spine:

```text
inspect a market
→ identify a local need
→ buy a cargo
→ choose destination and route
→ commit the journey
→ face a disclosed roadside consequence
→ arrive with altered resources or standing
→ deliver, sell, recover, and reinvest
```

The vertical slice now needs to prove the emotional and presentational version of the same loop:

```text
I understand this place.
I know why this good matters here.
I can see what this road costs.
I chose what risk to carry.
The caravan moved through a world.
The consequence changed something I care about.
I know what I would try next time.
```

### 1.1 What this milestone is and is not

| This milestone is | This milestone is not |
|---|---|
| One polished Five-Well Basin journey. | A complete continent campaign. |
| A coherent market → route → road → event → arrival → reinvestment loop. | A collection of disconnected menus. |
| A visually distinctive, readable, replayable alpha slice. | Final commercial art or final storefront production. |
| A demonstration of trade, route risk, crisis pressure, factions, and recovery. | A full simulation of every political group. |
| A safe foundation for future events, meetings, and regional developments. | A generic procedural narrative generator. |
| A human-playtest target. | Evidence that the game is already fun for everyone. |

### 1.2 Product-quality definition

The slice is game-quality when a new tester can start from a clean profile, understand the premise, complete a first trade, compare two routes, resolve a roadside event, arrive at a destination, see the consequence of the choice, and voluntarily begin another run with a different plan—without developer explanation.

The player must remember at least one place, one good, one road, one person or faction, and one consequence after the session. That is a better quality signal than the number of implemented records.

---

## 2. Current foundation and constraints

The current latest implementation is a strong alpha systems base. The roadmap must extend it rather than replace it.

### 2.1 Implemented foundation

| System | Current baseline |
|---|---|
| Economy | Six goods, local pricing, needs, destination value, cargo capacity, provisions, cash, and trade validation. |
| World | Five nodes/settlements, two route families, regional pressure, settlement resilience, and a three-stage water crisis. |
| Factions | Eight political groups, two tribal factions, Ash Wardens, Free Caravans, escalation stages, and conflict consequences. |
| Events | Four implemented event families with typed choices, disclosed costs, deterministic outcomes, save/load, and event history. |
| Campaign | Multiple endings, crisis progression, contracts, crew, information, and post-crisis trading. |
| UI | Main Menu, Introduction, Bazaar, Departure Desk, road observation, roadside event, arrival handoff, settings, accessibility, controller, and browser semantic mirror. |
| Persistence | Versioned saves, autosaves, backup recovery, malformed/future-save handling, isolated settings, and reset/recovery flows. |
| Verification | Content validators, economy tests, map UI smoke, tutorial flow, controller smoke, campaign smoke, game-quality metrics, browser capture validation, and packaged build checks. |
| Visual identity | Restrained warm parchment, ash, brown-black, ochre, and muted route colors; procedural map/market artwork and original placeholder assets. |

### 2.2 Binding constraints

1. **Preserve the deterministic core.** Economy, route, crisis, event, faction, and save rules remain authoritative in `src/core/`.
2. **Preserve the command boundary.** UI emits commands and formats results. It does not calculate prices, mutate faction state, resolve events, or decide route outcomes.
3. **Preserve the trade loop.** The market remains the main verb. Politics, crew, events, and crisis exist to deepen the next trade or route decision.
4. **Preserve explainability.** Costs, risks, price reasons, and consequences must be written before or immediately after commitment.
5. **Preserve recovery.** Loss may cost money, provisions, cargo, time, access, or standing, but the first hour must not be ruined by hidden randomness.
6. **Preserve small budgets.** Do not add currencies merely to create more progression screens.
7. **Preserve the basin scale.** Do not add a second continent, online economy, multiplayer, factories, crafting chains, permadeath, or live-service systems in this slice.
8. **Preserve honest status.** Procedural visuals, placeholders, automated evidence, and pending human tests must remain labeled accurately.

---

## 3. Target player experience

### 3.1 The first five minutes

The title screen should establish:

```text
Market of Ash
A trade route is a promise you make to the road.
Choose what the basin needs, then decide what risk you can afford.
```

The first-time player should have one obvious action: **New Game** or **Begin Guided Trade**. Continue, Settings, Credits, and developer scenarios must not compete with the first action.

The introduction should teach only three ideas:

1. Settlements need different goods.
2. Roads trade safety, cost, time, and exposure.
3. The caravan must return with enough provisions and value to continue.

### 3.2 The first fifteen minutes

The player should:

1. Enter a specific settlement with a local identity.
2. See a contract, need, or opportunity that gives the first cargo purchase purpose.
3. Compare at least two routes.
4. See the expected cargo value, fee, provisions, time, and disclosed risk.
5. Commit the route deliberately.
6. Watch a compact departure/travel beat.
7. Resolve one roadside choice with at least two credible responses.
8. Arrive and see a reward, loss, standing change, or settlement development.

### 3.3 The first thirty minutes

The player should complete one full short journey and begin a second decision. They should encounter one of the following:

- A profitable but exposed trade.
- A safe but low-margin delivery.
- A relationship or faction choice that changes a later option.
- A crisis-related opportunity that makes the basin feel unstable.

The first full run should end with a concise debrief:

```text
What you carried
Where you went
What the road cost
What changed
What remains possible
What to try next
```

### 3.4 Intended post-session thoughts

Good post-session thoughts include:

- “I should have bought water instead of grain.”
- “The Toll Road was worth it because I had a contract.”
- “I want to know what happens if I support the Wardens.”
- “The tribe did not attack me immediately, but the route became harder.”
- “I lost cargo, but I still had a recovery plan.”
- “I understand why Reedwatch paid more.”

Bad post-session thoughts include:

- “I clicked the biggest number.”
- “I had no idea what the road would do.”
- “The event stopped the game for flavor text.”
- “The market was just a spreadsheet.”
- “I lost because of an invisible roll.”
- “Nothing I did changed the next screen.”

---

## 4. Screen and flow contract

### 4.1 Main Menu

**Purpose:** Establish identity and launch the correct journey.

**Required hierarchy:**

```text
visual title / basin image
premise line
New Game or Guided Trade
Continue
Field Guide / Learn
Settings
Credits
Quit
small build/status text
```

**Work:**

- Make the New Game action unambiguously primary on a clean profile.
- Keep Continue available only when a validated save exists.
- Shorten save-replacement confirmation while preserving explicit protection.
- Separate first-launch, returning-player, and reset-state captures.
- Add a small “current journey” receipt only when Continue is valid.

**Acceptance:**

- A first-time tester chooses the intended start within five seconds.
- A returning tester knows exactly what Continue will restore.
- Save replacement never occurs silently.
- Keyboard/controller focus follows the same visible order.

### 4.2 Introduction

**Purpose:** Teach the market, route, and consequence model.

**Required cards:**

| Card | Message |
|---|---|
| The Basin | The basin is recovering; needs and prices are local. |
| The Caravan | You earn by carrying a useful thing to a place that needs it. |
| The Road | Cheap, guarded, and fast roads expose different costs. |
| The Promise | A contract pays more because it creates an obligation. |

Do not use a long lore wall. Every card should contain one image or diagram, one sentence, and one short “what to do next” line.

### 4.3 Bazaar

**Purpose:** Make the local market feel like a place and make the next cargo legible.

**Primary question:**

> What does this settlement need, and what can I afford to carry there?

**Required visible elements:**

- Settlement name and one-line identity.
- Local need and reason.
- Selected good with local price, destination comparison, weight, and risk.
- Cash, provisions, cargo hold, crisis stage, and visit slots.
- Contract or opportunity connected to the selected good.
- Buy/sell result preview.
- One clear next action: accept contract, buy cargo, inspect route, or depart.

**Visual work:**

- Give each good a simple silhouette or mark: water vessel, grain sack, medicine bundle, scrap bundle, weapon crate, charcoal/industrial bundle.
- Give each settlement a color accent, landmark, banner, or architectural motif.
- Replace repeated large tabs with subtle stall/desk identities while retaining accessible text.
- Show a small “cargo story” sentence such as `Water for Reedwatch: high need, safe margin, one exposed unit if the Old Road turns hostile.`

**Acceptance:**

- A tester can state why the selected cargo is useful before buying.
- The buy button shows exact cash and hold change.
- The Bazaar never requires opening several panels to understand the basic trade.

### 4.4 Departure Desk

**Purpose:** Turn trade into a route commitment.

**Route card contract:**

```text
Destination
Route name
Travel days
Fee
Provision cost
Expected cargo value
Risk source
Contract relevance
Pressure/faction consequence
Recovery availability
```

**Required work:**

- Add a compact side-by-side comparison for two or three legal routes.
- Keep the map visible, but give the selected route a stronger visual highlight.
- Show one sentence of recommendation or tension, not a calculated “best route.”
- Make the selected cargo and destination appear in the same decision band.
- Put the commit action directly under the route consequence.
- Keep “return to shop” clearly different from “commit departure.”

**Acceptance:**

- A tester can explain why one route is cheaper or safer.
- The player can compare routes without scrolling through unrelated controls.
- A committed route cannot be changed without an explicit, authoritative reversal rule.

### 4.5 Travel / road observation

**Purpose:** Make the caravan feel like it is moving through a basin.

**Required beats:**

1. Departure receipt: `Ashgate → Reedwatch, carrying Water x4.`
2. Short route movement or illustrated transition.
3. One landmark, weather, road, or faction cue.
4. Updated cash/provisions/day/pressure.
5. Roadside event or arrival handoff.

Transitions must be skippable after first viewing and must not resolve gameplay twice.

**Acceptance:**

- The player can identify origin, destination, current road, and travel status.
- The screen does not look like the Departure Desk with one label changed.
- Reduced-motion mode replaces movement with a clear static state transition.

### 4.6 Roadside events

**Purpose:** Make travel produce a human or operational problem.

Every event card must present:

```text
who/what is here
where it is happening
what the caravan risks
available choices
exact costs
expected result
unavailable prerequisites
what may be remembered later
```

**Visual treatment:**

- One event-specific illustration, silhouette, landmark, or color treatment.
- A route strip showing the caravan’s current position.
- A compact risk banner.
- Choice cards that lead with the action verb: Pay, Detour, Wait, Share, Refuse, Escort, Hide, Sell, Reserve.

**Acceptance:**

- A tester can predict the immediate cost before selecting.
- The event choice changes a later state, not only the event text.
- The event is resolvable without reading a long narrative paragraph.
- Event history or a later receipt shows the consequence when it matters.

### 4.7 Arrival handoff

**Purpose:** Pay off the journey and re-open the local economy.

Replace the current repeated report density with:

```text
ARRIVED AT REEDWATCH
Delivered Water x4
Earned 150 ashmarks
Free Caravans standing +1
Road cost: 1 day, 1 provision
Event result: paid escort; cargo preserved
NEXT: Enter Reedwatch
```

A “details” section may contain the full event report, but the player should understand the outcome above the fold.

### 4.8 Settlement return

**Purpose:** Show that the destination changed because the caravan arrived.

The settlement should visibly acknowledge:

- Delivered cargo.
- Contract completion or failure.
- Updated local need/resilience.
- New or removed opportunities.
- Faction or crew reaction.
- Available next destinations.

The first destination should not simply look like Ashgate with a different label.

### 4.9 Terminal debrief

**Purpose:** Close a journey and create replay motivation.

Required sections:

1. Outcome headline.
2. Route timeline.
3. Cargo and cash journey.
4. Provisions/time cost.
5. Event decisions.
6. Faction/settlement consequences.
7. Biggest causal lesson.
8. One concrete replay experiment.
9. Continue, replay, title, and feedback actions.

---

## 5. Visual transformation plan

### 5.1 Visual promise

Market of Ash should look like a **quiet, illustrated caravan ledger laid over a recovering ashland**. The visual language should combine:

- Warm parchment and brass for commerce.
- Charcoal, rust, and ash for the damaged world.
- Desaturated regional colors for water, scrub, stone, and salt.
- Small human marks: flags, chalk, crates, wells, carts, lamps, ropes, signs, and shelter cloth.
- Strong silhouettes for goods, settlements, routes, and caravan states.

The current graphic restraint is an asset. The solution is not to add a maximalist interface. It is to add **specificity and place**.

### 5.2 Asset priority

| Tier | Assets | Reason |
|---:|---|---|
| 1 | Settlement landmarks, caravan silhouette, goods marks, route/road textures | Makes the core loop visible. |
| 2 | Event-specific silhouettes and roadside landmarks | Makes consequences memorable. |
| 3 | Faction banners, crew portraits, contract marks | Makes politics and people legible. |
| 4 | Regional sky/ground/water treatments | Differentiates basin locations. |
| 5 | Decorative particles, weather, small animations | Adds atmosphere after readability works. |

Do not spend the first art pass on menu decoration. The market, route, caravan, and settlement should carry the identity.

### 5.3 Asset registry

Every asset needs:

```text
stable asset ID
role
source/provenance
license or generated status
logical dimensions
light/dark treatment
state variants
fallback treatment
reduced-motion behavior
color-safe shape or label companion
```

All generated or placeholder assets must remain replaceable. No asset should become an untracked dependency of the simulation.

### 5.4 Visual state grammar

Use shape, label, and color together:

| State | Visual treatment |
|---|---|
| Available | Warm outline and clear action label. |
| Selected | Strong outline, filled accent, and explicit inspector. |
| Forecast | Dashed or muted route treatment plus `FORECAST`. |
| Unscouted | Hazy/partial treatment plus a written clue. |
| Risk | Ochre/red accent plus named risk. |
| Completed | Stable green/blue accent plus result receipt. |
| Blocked | Muted treatment plus exact reason. |
| Crisis | Basin-wide pressure treatment, not only a number. |

Never rely on color alone for a route, good, faction, or risk distinction.

---

## 6. Audio and game feel

### 6.1 Audio scope

The vertical slice does not need a full soundtrack. It needs a small, consistent sound language:

- Bazaar ambient bed.
- Departure/route commit cue.
- Caravan movement cue.
- Roadside event arrival cue.
- Choice confirmation and blocked-action cue.
- Cargo purchased/sold cue.
- Contract accepted/completed cue.
- Crisis escalation cue.
- Arrival and debrief cue.

Audio must remain presentation-only and must have a visual equivalent. Interface sounds must remain muteable.

### 6.2 Timing principles

- No transition delays a decision longer than necessary.
- Event text appears before choice controls become active.
- Currency/provision/cargo deltas animate or update once, not repeatedly per frame.
- A consequence should remain visible long enough to be read.
- Reduced motion removes travel interpolation and screen shake, not information.

---

## 7. Content expansion inside the slice

The vertical slice should deepen the current basin using content that makes existing mechanics more visible.

### 7.1 Settlements

Give three core settlements distinct identities first:

| Settlement | Identity | Game-quality role |
|---|---|---|
| Ashgate | Regulated departure hub with contracts and information. | Teaches the market and route promise. |
| Reedwatch | Frontier water settlement under pressure. | Teaches delivery, scarcity, and recovery. |
| Cinderford or Brine Cross | Competing economic/political node. | Teaches margin versus standing or faction access. |

Each settlement needs:

- A landmark.
- A local phrase or visible need.
- A unique service/opportunity.
- A different risk profile.
- At least one route consequence.
- At least one development state.

### 7.2 Goods

Use the existing six goods as distinct economic stories rather than adding many more.

| Good family | Player question |
|---|---|
| Water | Who is desperate enough to pay, and what route exposes the load? |
| Grain | Is ordinary demand worth the safe margin? |
| Medicine | Do I fulfill a contract, sell to a crisis, or preserve it for leverage? |
| Scrap/charcoal | Can material help a settlement or generate a fast profit? |
| Weapons | Which faction gains capacity if I make this sale? |
| Future specialty good | What new route or settlement identity does it unlock? |

A new good should enter only when it creates a new route, crisis, or faction decision. Do not add a good that only fills another price column.

### 7.3 Events and occurrences

Prioritize authored events before broad random scheduling.

Recommended first game-quality event set:

1. **The Gatekeeper’s Chalk** — pay for certainty, detour for exposure, or wait for information.
2. **The Span at Cinderford** — sell material now, reserve it for a public crossing, or carry measurements.
3. **The Last Clean Barrel** — emergency sale, fair distribution, or keep cargo sealed for the contract.
4. **Workshop Can Wait** — repair the caravan now or preserve cash for a better route.
5. **The Three Lanterns** — choose which faction’s warning network to trust.
6. **The Family Under the Tarpaulin** — carry people, cargo, or neither; alter provisions, capacity, and standing.
7. **A Mark on the Crate** — discover that a weapon sale has a visible political owner.
8. **The Quiet Tollhouse** — take the profitable shortcut or make the legal road safer for future caravans.

Each event must have a visible practical consequence and a later callback if the consequence persists.

### 7.4 Factions

Do not expose all eight political groups at once. Introduce them in layers:

1. Free Caravans: baseline trade and trust.
2. Ash Wardens: regulated roads, safety, and weapon oversight.
3. One tribal faction: escalation, arms sales, and local retaliation.
4. A settlement coalition: resilience, water, or refuge.

Faction values must affect at least one visible price, route, contract, event option, service, or settlement development. A faction meter with no visible consequence is forbidden.

### 7.5 Developments

A development is a persistent state change that alters a later decision. Good first developments include:

- Public span repaired: Old Road risk falls; material profit is lost.
- Water distributed fairly: settlement resilience rises; contract leverage changes.
- Weapons sold to a faction: a later route becomes more dangerous; an arms buyer becomes available.
- Wardens supported: toll road becomes safer but less profitable.
- Free Caravans protected: more caravan opportunities appear, but regulated access weakens.
- Refugees carried: provisions and hold pressure increase; a later settlement opens a service.
- Signal network built: forecasts improve, but the caravan becomes more visible.

Developments should be bounded, named, saved, and shown on the map or settlement screen.

---

## 8. Data and implementation framework

### 8.1 Authoritative ownership

```text
content/*.json
    ↓
MarketContent / loaders / validators
    ↓
AshWorldState
    ↓
MarketCommandProcessor / economy helpers
    ↓
structured command result
    ↓
UI presentation / visual feedback / audio
```

UI may never directly change:

- Cash.
- Provisions.
- Cargo.
- Prices.
- Route risk.
- Crisis stage.
- Faction values.
- Settlement resilience.
- Contract state.
- Event resolution.
- Save migration.

### 8.2 Command shape

Every new state-changing command should return:

```gdscript
{
    "ok": true,
    "reason": "",
    "message": "Delivered 4 Water to Reedwatch.",
    "state_delta": {
        "cash": {"before": 60, "after": 196},
        "cargo": {"water": {"before": 4, "after": 0}},
        "standing": {"free_caravans": {"before": 0, "after": 1}}
    },
    "presentation": {
        "headline": "Water delivered",
        "next_action": "enter_settlement"
    }
}
```

The `presentation` section may help the UI but must not become a second source of truth. State deltas should be derived from authoritative state transitions.

### 8.3 Event record shape

Future event records should support:

```json
{
  "id": "family_under_tarpaulin",
  "title": "The Family Under the Tarpaulin",
  "locations": ["old_road", "reedwatch"],
  "eligibility": {
    "min_day": 2,
    "requires_cargo_space": 2
  },
  "choices": [
    {
      "id": "carry_people",
      "label": "Carry them",
      "requires": {"free_hold": 2},
      "cost": {"provisions": 2, "days": 1},
      "effects": {"refugees": 2, "free_caravans": 1},
      "result_key": "carried_people"
    }
  ],
  "history_key": "family_under_tarpaulin_resolved"
}
```

Narrative text must not contain executable formulas. Effects must be typed data mapped to explicit commands.

### 8.4 Settlement identity data

Add display and gameplay fields without duplicating rules in the UI:

```json
{
  "id": "reedwatch",
  "identity": {
    "role": "frontier_water_settlement",
    "tagline": "The wells are low and the gates stay open.",
    "landmark_asset": "settlement_reedwatch_gate",
    "accent": "#8AAFA2"
  },
  "local_need": "water",
  "signature_action": "public_distribution",
  "development_hooks": ["water_resilience", "free_caravan_standing"]
}
```

### 8.5 Deterministic occurrence selection

When the general occurrence scheduler expands, selection must derive from:

```text
run seed
region ID
current day
route ID
settlement ID
crisis stage
faction state
contract state
resolved event history
named event stream
content version
```

Requirements:

- Filter eligibility before selecting.
- Use a named stream such as `event_occurrence`.
- Keep one primary roadside event per travel phase.
- Enforce cooldowns and repeat policy.
- Preserve pending event state in saves.
- Keep a bounded event history.
- Guarantee at least one valid response.
- Never silently remove the only recovery path.

---

## 9. Staged implementation roadmap

### Phase A — Baseline and instrumentation

**Objective:** Establish measurable before/after evidence.

Tasks:

- Add a clean-profile visual harness.
- Capture Main Menu, Introduction, Bazaar, Departure, road, event, arrival, and settlement states.
- Record first-action time, first purchase, route commit, event choice, and arrival.
- Add a local-only playtest session record with explicit consent.
- Confirm 1280×720 logical and 1600×900 desktop behavior.

**Exit gate:** Every later UX change has a comparable capture and test path.

### Phase B — First-session flow

**Objective:** Make the opening understandable and inviting.

Tasks:

- Reduce title competition.
- Refine introduction cards.
- Make the first contract and purchase purpose explicit.
- Shorten save-replacement confirmation.
- Separate clean profile and returning-player paths.
- Add current-order guidance.

**Exit gate:** Five uncoached testers can reach the first route plan and explain their cargo choice.

### Phase C — Bazaar quality

**Objective:** Make the market feel like a place and a decision.

Tasks:

- Add settlement identity treatments.
- Add good marks/silhouettes.
- Add a compact cargo story.
- Add local/destination price comparison.
- Clarify contract connection.
- Reduce tab/form repetition.
- Add buy/sell delta receipts.

**Exit gate:** A tester can answer “why this good, why here, why now?” without opening a debug view.

### Phase D — Route quality

**Objective:** Make route choice the game’s signature decision.

Tasks:

- Build compact route comparison cards.
- Add route landmarks and route-specific visual identity.
- Make fee, provisions, days, risk, cargo value, and faction consequence readable together.
- Improve selected route and destination emphasis.
- Add route commitment receipt.

**Exit gate:** Testers choose different routes for understandable reasons and can state the trade-off.

### Phase E — Travel and event feel

**Objective:** Make the caravan appear to move through a living basin.

Tasks:

- Add departure/travel/arrival beats.
- Add one landmark or weather cue per route family.
- Add event-specific silhouettes.
- Stage event arrival, choice, and resolution.
- Preserve reduced-motion and instant-state alternatives.

**Exit gate:** Testers can describe where the caravan was, what it encountered, and how the choice changed the journey.

### Phase F — Arrival, settlement, and consequence

**Objective:** Make the world acknowledge the caravan.

Tasks:

- Build compact arrival receipt.
- Add destination-specific acknowledgment.
- Show contract, cargo, price, standing, resilience, and faction changes.
- Make one development visible on the map or settlement.
- Add one later callback to a prior choice.

**Exit gate:** A delivered cargo or faction decision changes a later option and the player can see why.

### Phase G — Dedicated debrief and replay

**Objective:** Turn outcomes into learning and replay motivation.

Tasks:

- Build terminal debrief panel.
- Show cargo/money/provisions journey.
- Show event decisions and route timeline.
- Name the decisive causal chain.
- Offer one concrete replay experiment.
- Preserve replay identity without pretending a seed alone reproduces commands.

**Exit gate:** Testers can explain their outcome and choose a specific alternative plan.

### Phase H — One complete content slice

**Objective:** Demonstrate the future content pipeline.

Implement one complete slice:

```text
one event
+ one settlement identity
+ one visible development
+ one faction consequence
+ one debrief callback
+ one test fixture
+ one visual capture set
```

Recommended slice: **The Last Clean Barrel → fair distribution → Reedwatch resilience development → later water opportunity**.

**Exit gate:** Content is data-driven, save-safe, deterministic, visually presented, and replayable.

### Phase I — Human private alpha

**Objective:** Replace assumptions with player evidence.

Run structured sessions using:

- Clean Guided Trade.
- Quick Start.
- One route-risk comparison.
- One event choice.
- One arrival/debrief.
- One replay.

Fix the top three comprehension failures before adding a second crisis or large faction layer.

### Phase J — Packaging and release hardening

**Objective:** Make repeated external testing safe.

Tasks:

- Clean install.
- Upgrade over an older save.
- Backup recovery.
- Settings reset.
- Browser/Web smoke.
- Windows packaging.
- High-DPI and minimum-window checks.
- Controller and keyboard checks.
- Offline boundary verification.
- Privacy-safe report verification.

**Exit gate:** A tester can install, start clean, trade, travel, save, close, resume, finish, export feedback, and replay without developer assistance.

---

## 10. Test framework and acceptance gates

### 10.1 Core deterministic tests

Maintain or extend tests for:

| Domain | Required assertions |
|---|---|
| Economy | Price reason, buy/sell, capacity, cash, provisions, route forecast, and transaction rejection. |
| Routes | Endpoint validity, route fees, time, provisions, risk, closure, and recovery paths. |
| Contracts | Acceptance, delivery, deadline, reward, failure, and repeated contract behavior. |
| Events | Eligibility, disclosed costs, choice outcomes, unavailable reasons, event history, and callback state. |
| Factions | Bounds, escalation, threshold, visible effects, and deterministic conflict outcomes. |
| Crisis | Stage transitions, recovery, ending predicates, and no hidden soft lock. |
| Save | Fresh, active trade, route plan, moving, event, arrival, crisis, development, malformed, future-version, and backup. |
| Replay | Same seed and commands yield identical canonical state and report. |

### 10.2 Content validators

Every new content schema requires:

1. One valid record.
2. One invalid fixture.
3. Loader/accessor support.
4. Cross-reference validation.
5. Range and bound validation.
6. Stable ID test.
7. Save/replay consideration.
8. UI copy or presentation path.

### 10.3 UI tests

Every major flow needs:

- A scripted command path.
- A no-mutation navigation path.
- A blocked/invalid case.
- Controller focus path.
- Keyboard path.
- Scaling path.
- Reduced-motion path if motion exists.
- Save/return path.
- Visual capture at supported viewport.

### 10.4 Game-quality metrics

Continue the existing quality metrics and add:

| Metric | Target |
|---|---:|
| Clean-profile first action | Under 30 seconds after launch. |
| First meaningful trade | No more than three intentional actions after tutorial completion. |
| Route comparison | Tester can state one difference between routes. |
| Event prediction | Tester can state the immediate cost before choosing. |
| Arrival comprehension | Tester can name what changed after arrival. |
| Replay intent | At least half of testers identify a concrete next experiment. |
| Safe opening | No hidden first-hour campaign-ending state. |
| Strategy variety | At least three viable opening plans in measured seed set. |
| Dominant route | No route wins all tested scenarios without a disclosed reason. |

These are playtest targets, not claims until measured.

### 10.5 Visual evidence requirements

Capture:

```text
clean Main Menu
Introduction card
Bazaar with selected good
Departure route comparison
Departure committed
Road observation
Event before choice
Event after choice
Arrival receipt
Destination settlement
Terminal debrief
```

Record:

- Logical viewport.
- Window size.
- Text-size setting.
- Reduced-motion setting.
- Input path.
- Clean or returning profile.
- Whether evidence is automated or human-observed.

A screenshot proves visibility, not comprehension or fun.

---

## 11. Human playtest protocol

### 11.1 Session structure

Each session should last 20–40 minutes:

1. Explain that the build is a private alpha and the player may stop.
2. Start from a clean profile.
3. Ask the player to narrate what they believe the game is asking.
4. Do not explain the intended route unless they are blocked by a defect.
5. Observe first purchase, route comparison, event choice, and arrival.
6. Ask prediction questions before commitment.
7. Ask causal questions after resolution.
8. Let the player replay once.
9. Record the player’s proposed alternative.

### 11.2 Questions to ask

Before purchase:

- What does this settlement need?
- Why are you buying this good?
- Where do you expect to sell or deliver it?

Before route commitment:

- Which route seems safer?
- What makes the cheaper route cheaper?
- What do you think you could lose?

Before event choice:

- What will this option cost?
- What do you expect to happen?
- Which option preserves your plan best?

After arrival:

- What changed?
- Did the result match your expectation?
- What would you do differently?

After replay:

- What was the specific experiment?
- Did the game make that experiment understandable?

### 11.3 Do not overinterpret

Completion rate alone does not establish quality. A player may complete the journey while misunderstanding every important decision. Record hesitation, mistaken beliefs, ignored information, and post-choice explanations.

---

## 12. AI-agent execution protocol

### 12.1 Required task shape

Every agent receives one bounded task:

```text
Task:
Change one player-facing Market of Ash behavior.

Baseline:
Start from current remote main. Read AGENTS.md, README.md,
design/design_prompt.md, docs/gpt_agent_handoff_roadmap.md,
docs/implementation_status.md, this document, and the relevant source/test files.

Player question:
What should the player understand or feel after this change?

Authority:
Which core class owns the rule? Which UI class only presents it?

Allowed files:
List exact files.

Non-goals:
List excluded systems and content.

Acceptance:
Visible behavior, invalid case, deterministic test, save/input/accessibility,
visual capture, and documentation.

Verification:
Focused test, complete scripts/verify.sh, parser/import, git diff --check.

Report:
Intent, changed files, exact commands/results, captures, limitations,
and exactly one next task.
```

### 12.2 First ten agent feeds

#### Feed 1 — clean first-session baseline

Capture and instrument the clean Main Menu → Introduction → Bazaar → Departure path. Do not change economy behavior.

#### Feed 2 — compact Bazaar cargo story

Add a compact explanation connecting selected good, local need, destination value, and route risk. Preserve all calculations in core.

#### Feed 3 — settlement identity

Give Ashgate and Reedwatch distinct data-driven visual and textual identities. Do not add a new settlement.

#### Feed 4 — route comparison

Create a clear side-by-side route comparison showing fee, days, provisions, value, risk, and practical consequence. Do not select the route automatically.

#### Feed 5 — departure/travel/arrival beat

Add presentation-only travel transitions and an arrival receipt. Preserve exact command timing and reduced-motion behavior.

#### Feed 6 — event visual treatment

Give one existing event a route landmark/silhouette and compact choice hierarchy. Preserve deterministic outcome and event schema.

#### Feed 7 — destination acknowledgment

Make one settlement acknowledge delivered cargo and show one existing state change. Do not add a new currency or reputation meter.

#### Feed 8 — terminal debrief

Replace generic terminal presentation with a route/cargo/event/consequence debrief and replay experiment. No new gameplay math.

#### Feed 9 — one complete event-development slice

Implement The Last Clean Barrel or Workshop Can Wait through data, command, save, UI, development, callback, tests, and capture.

#### Feed 10 — moderated playtest fixes

Run five sessions and fix the top three comprehension problems. Do not add a new major system during this feed.

---

## 13. Release gates

### Local gate

Before a pull request:

```bash
bash scripts/verify.sh
godot --headless --audio-driver Dummy --path . --editor --quit
git diff --check
```

Also run the focused test for the changed system and capture the affected visual state.

### Pull-request gate

The change must pass:

- Repository policy.
- Content manifest and runtime validators.
- Validator fixtures.
- Ubuntu and Windows Godot tests.
- AI review.
- Web/browser capture checks where relevant.
- Packaging checks where relevant.

### Alpha-candidate gate

Before a private alpha tag:

- Clean install tested.
- Upgrade path tested.
- Save and backup recovery tested.
- Controller and keyboard tested.
- Large text and minimum viewport tested.
- Reduced motion tested.
- Offline behavior tested.
- Feedback export privacy checked.
- Human playtest evidence recorded.
- Known limitations written honestly.

No storefront or commercial-readiness claim should be made until the human and packaging gates are complete.

---

## 14. Definition of done for the vertical slice

The Market of Ash game-quality vertical slice is complete when:

1. The first screen clearly communicates the caravan trade premise.
2. The first contract or need gives the first purchase purpose.
3. The Bazaar makes a good’s local reason and destination opportunity visible.
4. The Departure Desk makes route trade-offs legible before commitment.
5. Travel feels like a caravan moving through the basin.
6. A roadside event presents a practical dilemma with disclosed costs.
7. Arrival clearly reports what happened and what changed.
8. At least one settlement has a memorable identity.
9. At least one faction or crisis choice changes a later visible opportunity.
10. The terminal debrief explains the journey and proposes a replay experiment.
11. New events and developments use stable IDs, typed effects, saves, replay tests, and UI tests.
12. Five or more uncoached players complete or meaningfully attempt the first journey.
13. The top three comprehension failures have been fixed or explicitly accepted.
14. The current economy remains deterministic and validated.
15. No new feature is included merely because it makes the feature list longer.

> **The slice is successful when the player remembers a road and a consequence, not when the repository contains the most content.**

---

## 15. Product-lead decision log

### Decision: polish the basin before adding another region

**Reason:** The economy, map, factions, and crisis already provide enough systemic material. More geography would hide rather than solve the current presentation gap.

### Decision: improve place before adding complexity

**Reason:** Settlements and routes are mechanically distinct but visually similar. Place identity will make existing decisions more meaningful.

### Decision: use authored events before generalized randomness

**Reason:** Authored events can teach the consequence language and establish quality. A scheduler should expand only after event cards, history, persistence, and pacing are proven.

### Decision: keep explicit disclosure even when it reduces surprise

**Reason:** Market of Ash depends on trust. The game can preserve uncertainty through forecasts, not through hidden costs or unannounced rolls.

### Decision: make faction consequences bounded

**Reason:** A small number of visible developments is more meaningful than a large invisible reputation simulation.

### Decision: keep audio and animation subordinate to causality

**Reason:** The player must understand the trade and route result before the game asks them to admire presentation.

### Decision: treat human playtesting as a product requirement

**Reason:** Automated tests can prove deterministic correctness and safe boundaries, but only players can show whether the market, route, and crisis are understandable and compelling.

---

## References

[1] [`README.md`](../README.md) — current implementation surface and run instructions.
[2] [`design/design_prompt.md`](../design/design_prompt.md) — product identity, economy, route, crisis, art, and architecture contracts.
[3] [`docs/gpt_agent_handoff_roadmap.md`](gpt_agent_handoff_roadmap.md) — dependency-ordered implementation roadmap and deterministic command contract.
[4] [`docs/implementation_status.md`](implementation_status.md) — current verification evidence and manual gates.
[5] [`docs/ux/alpha_experience_flow_spec.md`](ux/alpha_experience_flow_spec.md) — current UX flow and accessibility requirements.
[6] [`docs/playtest_guide.md`](playtest_guide.md) — current tester workflow and privacy boundary.
[7] [`content/content_manifest.json`](../content/content_manifest.json) — canonical content counts and stable IDs.

This is an internal development roadmap. It does not claim that future visual, audio, event, settlement, or human-playtest work is already implemented.
