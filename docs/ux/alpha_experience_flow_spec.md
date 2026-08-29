# Market of Ash — Alpha Experience Flow and UX Polish Specification

**Author:** Manus AI  
**Status:** Approved implementation direction for the alpha playtest  
**Scope:** The five-settlement, single-region trade-and-travel loop. This document does not add factories, real-time combat, infinite maps, multiplayer, or weapons-first progression.

> **UX promise:** The player is always able to answer three questions without leaving the current decision context: **Where am I? What am I committing? What could this change?**

## 1. Design Thesis

Market of Ash should not feel like a spreadsheet placed over a map. It should feel like operating a small caravan through a region that remembers trade. The shop is the player’s **home state**: it is where a settlement has a face, a need, a market, and an immediate opportunity. The departure screen is the **commitment state**: it is where a load becomes a plan with a destination, a route, visible costs, and an uncertain consequence. Travel and arrival close the loop by returning a changed caravan to another human place.

This is inspired by the useful structure of Frontier-style play—local preparation, deliberate navigation, constrained commitment, and visible arrival—without inheriting the historical interface’s density. The player should be free, but never abandoned in a wall of unrelated controls.[1] [2]

| Non-negotiable | UX consequence |
| --- | --- |
| **Commerce is the main verb.** | The first actionable screen after launch and arrival is the shop. The map is entered to commit a planned trade, not to replace market decision-making. |
| **Every important number is explainable.** | Prices, capacity, money, provisions, route fees, risk, time, and expected outcome expose a plain-language reason and comparison. |
| **Cheap routes create vulnerabilities.** | The departure screen compares cost, time, exposure, and expected loss side by side before a player commits. |
| **Failure is recoverable.** | A bad trade or route incident returns an actionable arrival state with a next step, never a dead-end modal or unexplained loss. |
| **Politics and people deepen commerce.** | Contracts, faction leverage, crew, and local needs appear as trade modifiers, service offers, or route options—not as a separate lore menu. |
| **No forced weapons path.** | Escorts, route intelligence, negotiation, cargo choice, and relationship actions are parallel ways to manage risk. |

## 2. Experience Architecture

```mermaid
flowchart LR
    M[Main Menu] -->|New Game| I[Illustrated Introduction]
    M -->|Continue| S[Settlement Bazaar]
    I -->|Guided / Skip guidance| S
    S -->|Buy, sell, inspect prices| S
    S -->|Plan departure| D[Departure Desk and Regional Map]
    D -->|Edit destination or route| D
    D -->|Back to settlement| S
    D -->|Commit departure| T[Travel and Route Observation]
    T -->|Event choice, if present| E[Route Decision]
    E --> A[Arrival Report]
    T --> A
    A -->|Enter settlement| S
    A -->|Review route outcome| D
    S -->|Pause / save| P[Pause and Save]
    D -->|Pause / save| P
    P --> S
```

The player sees **one dominant question per screen**. The shop asks, *“What changes hands here?”* The departure desk asks, *“Is this trip worth taking?”* Travel asks, *“What will I give up, protect, or change now?”* Arrival asks, *“What changed, and what do I do with it?”*

## 3. Global Interaction Rules

The game uses a consistent information hierarchy. A stable top rail always shows **day, current settlement, ashmarks, provisions, hold used/capacity, crisis condition, and autosave state**. It uses both color and words: rust means exposed, faded blue means water pressure, bone means neutral, and gold marks the current recommended or selected action. No critical state is encoded by color alone.

Primary actions are singular and verbs-first. Each screen has one visually strongest action: **Plan Departure** in the shop, **Commit Departure** on the map, **Resolve Choice** during an event, and **Enter Settlement** at arrival. A secondary back action is always available. Destructive, expensive, or irreversible actions disclose their immediate cost immediately before confirmation.

Every response should acknowledge cause and effect in the same format: an outcome headline, a number delta, the reason, and the next available action. For example: *“Old Road incident — 1 water lost. The route’s exposed condition made a cargo loss possible. You reached Reedwatch with 6/7 water.”* This explanation belongs near the result, not buried in a log.

## 4. Screen Contracts

### 4.1 Main Menu

| Element | Purpose | Alpha behavior | Polish requirement |
| --- | --- | --- | --- |
| **New Game / Continue** | Begin the authored opening or validate and restore an existing campaign. | New Game opens the illustrated introduction; Continue is separately enabled when a save exists and shows save status. | Add multiple save slots only if playtesting demonstrates a need. |
| **Introduction** | Establish the crisis, caravan ledger, and route tradeoffs before controls become dense. | Three short illustrated cards lead to the guided campaign; Start without guidance enters the same world without objectives. | Replace the stable illustration hooks with final authored art while preserving layout and semantics. |
| **Settings** | Make comfort and control discoverable before play. | Main Menu exposes persisted large text, reduced motion, interface-sound, and keyboard/controller-remapping controls alongside mouse/keyboard/controller guidance. | Validate controller remapping on physical hardware and perform hands-on assistive-technology review of the current semantic Web mirror. |
| **Quit** | Give a conventional, safe exit. | Desktop-only. | Confirms only if unsaved changes exist; never presents an intrusive quit prompt during the first minute. |

### 4.2 Settlement Shop — the central screen

The shop is a quiet local scene with a readable market desk in the foreground. It carries settlement identity through a banner color, silhouette, ambient sound, two or three animated trade details, and a short **“today’s need”** sentence. It is not a pure inventory screen.

| Zone | Player question | Alpha content | Future polish |
| --- | --- | --- | --- |
| **Settlement header** | Where am I and why does it matter? | Settlement name, role, day, crisis state, local one-line need. | Market banner, local NPC portrait, faction mark, arrival animation, contextual ambient sound. |
| **Market ledger** | What is worth buying or selling? | Goods list, unit price, selected load cost, short price reason, regional comparison. | Icons, supply/demand arrows, price-change badges, rumors, stale-information markings, contract pins. |
| **Caravan load** | What do I hold and what room remains? | Hold used/capacity, cargo rows, selected quantity, ashmarks, provisions. | Drag/reorder option, cargo risk/spoilage tags, reserve-space indicator, clear estimated sale destinations. |
| **Local opportunities** | What else can I do here? | Not yet interactive; a compact placeholder label only if required. | Contracts, services, crew, rumors, faction permits, debt/obligation cards. One is spotlighted, never a wall. |
| **Action rail** | What is my next meaningful action? | Buy cargo, sell cargo, contextual tutorial objective, and **Plan Departure**. Save and Load live in Pause; debug utilities are hidden from release-facing navigation. | Disabled-state explanations, keyboard hints, controller glyphs, one-click repeat buy/sell, safe undo only before departure. |
| **Outcome ribbon** | What just changed? | Last command result and cargo summary. | Animated deltas, new rumor badges, world-change callouts, “why this mattered” expansion. |

**Shop interaction flow**

```mermaid
flowchart TD
    A[Arrive at settlement] --> B[Read local need and global status]
    B --> C[Inspect good price and reasons]
    C --> D{Trade now?}
    D -->|Buy| E[Choose quantity and validate money/space]
    E --> F[Load changes and market response]
    D -->|Sell| G[Choose held cargo and confirm sale]
    G --> H[Money, need, and relationship update]
    D -->|Not yet| I[Inspect regional comparison or opportunity]
    F --> J[Plan Departure]
    H --> J
    I --> J
    J --> K[Departure Desk]
```

The key alpha rule is **no map visible behind buying and selling controls**. The player can make a local trade decision without scanning a competing route image. The pinned departure button names the current planning context (for example, **Plan Water x2 to Reedwatch**); it does not execute travel.

### 4.3 Departure Desk — map and commitment screen

The departure desk is entered by a visible transition: the market foreground falls away, the regional map becomes the dominant surface, and the caravan ledger anchors the right side. The screen visually communicates that the player is no longer merely browsing; they are considering an action that consumes time and provisions.

| Zone | Player question | Alpha content | Future polish |
| --- | --- | --- | --- |
| **Map canvas** | Where can I actually go? | Five-Well Basin, settlement marks, canonical route corridors, caravan marker, selected destination highlight. | Zoom, pan, route condition overlays, faction borders, weather/ash visibility, discovered rumors, contract destinations. |
| **Route cards** | Which road fits this plan? | Destination selector, legal route selector, fee, days, risk, route description. | Route state chips: guarded, washed out, watched, scouted, toll raised, caravan traffic. |
| **Load context** | What am I risking? | Selected planning good and quantity; current cargo/hold. | Cargo-value-at-risk, spoilage, contract obligations, crew/escort mitigation, “leave behind” decision. |
| **Forecast ledger** | What do I expect to gain or lose? | Scenario purchase, expected sale, gross margin, route fee, provisions, time, expected loss, expected net, and an explicit comparison between selected quantity and cargo actually held. | Range/uncertainty bands, source of uncertainty, alternative route comparison, what changes the forecast. |
| **Commitment rail** | Am I ready to leave? | Pinned **Commit** and Return to Shop actions; Commit repeats the current ashmark/provision cost. Save/load remain in the scrollable detail rail. | One final summary sentence; hold-to-confirm option; pre-departure autosave; explicit irreversibility marker. |
| **Route outcome layer** | What happened on the road? | Caravan movement and command result. | Traveling audio, animated route pulse, event card, summary of resource deltas, pause/save policy. |

**Departure interaction flow**

```mermaid
flowchart TD
    A[Enter Departure Desk] --> B[Read planned load and current resources]
    B --> C[Choose a legal destination]
    C --> D[Inspect its available routes]
    D --> E[Compare fee, days, risk, and expected net]
    E --> F{Change load?}
    F -->|Yes| G[Return to Shop with selection preserved]
    G --> B
    F -->|No| H{Commit?}
    H -->|No| I[Return to Shop]
    H -->|Yes| J[Pre-departure confirmation summary]
    J --> K[Travel]
```

No departure should be blocked without explaining **why** and offering the next action. Examples include: *“The Toll Road connects Ashgate to Brine Cross, not Reedwatch. Select Reedwatch to take the Old Road.”* and *“You need 4 ashmarks for the Old Road fee after loading grain. Reduce the load or return to the shop.”*

### 4.4 Travel and Route Events

Travel must be short enough to respect the player’s time and rich enough to make a committed route memorable. The map animation is the container, not the entire experience. The alpha should show a route start, a midpoint observation, and an arrival result; later event cards pause only when a genuine decision exists.

| Moment | Player feedback | Required rule |
| --- | --- | --- |
| **Departure** | Route line lights, caravan leaves settlement, fee/provisions animate out. | Show the actual selected route, not a generic loading screen. |
| **Midpoint observation** | One short route condition message or event setup. | If no decision is available, it must still explain a visible risk/condition. |
| **Event choice** | A compact card with at least two plain-language choices and outcome stakes. | Use cargo, crew, money, reputation, or a deliberate sacrifice; do not add opaque random failure. |
| **Resolution** | Delta line plus causal reason; route continues or arrives. | Do not hide an important loss in flavor text. |
| **Arrival** | Settlement banner, final cargo, money/provisions/day changes, new local need. | Return to an actionable shop state, not a dead-end end card. |

For the alpha, confrontations are presented as a **Roadside Decision** rather than a separate combat mode. The card names the maximum disclosed cargo-loss chance and exposed asset, counts currently usable choices, and gives every response a certainty or risk roll, exact costs, travel result, and expected consequence. There is no hidden health damage or real-time combat state.

After resolution, the same rail becomes a **Journey Result** report. It compares the selected choice's expected resource, cargo, time, risk, and destination commitment with the arrival result, names whether the risk roll was avoided or realized, and lists any persistent route, settlement, information, contract, or faction effect before the player enters the settlement. The latest report remains available in the destination shop and is reconstructed from saved event history after loading.

### 4.5 Arrival and Reinvestment

Arrival should take less than five seconds to comprehend. The player sees: **where they are, what survived, what they gained/lost, what has changed locally, and the primary next action**. Pressing **Enter Settlement** returns to the central shop. A small expandable route report can remain available for players who want exact deltas.

The first arrival after a route incident must distinguish planning failure from pure bad luck. For example: *“You chose the exposed Old Road: its warning was visible, and the incident cost one grain. Reedwatch is still paying a premium for water.”* The message gives the player agency without moralizing.

## 5. Supporting User Flows

### 5.1 First-run learning path

The first run is guidance, not a script. New Game presents three short story cards, then offers one coherent two-journey campaign tutorial: accept Reedwatch Water Relief, buy four Water, choose the Old Road, resolve its roadside decision, recover and deliver, buy Grain for the return, sell what arrives, recruit and assign crew, then inspect Town Outlook. No step grants cargo or bypasses a command, every selection remains editable, and progress is reconstructed from authoritative state after loading. Start without guidance enters the same canonical campaign with the objective card disabled.

### 5.2 Returning-player loop

A returning player resumes in the settlement shop. The first implemented **Since your last visit** component is a saved-history conflict report that preserves the last tactic, disclosed plan, actual deltas, risk result, and persistent world effects. Regional crisis change, local market response, one active contract or rumor, and autosave time remain later extensions of the same strip. The player stays one click from either inspecting the selected market good or opening the departure desk.

### 5.3 Contract flow

A contract begins as a card in the local opportunity zone, not a modal interruption. It declares destination, deadline, minimum delivery, reward, relationship change, and visible failure condition. Accepting a contract pins its destination in the departure desk and adds a cargo marker to the ledger. Contract resolution occurs on arrival before ordinary sale, and the player can explicitly renegotiate when supported.

### 5.4 Crew and service flow

Crew and services are settlement-scoped offers. A player opens a compact panel from the shop, reads the cost and the trade consequence, commits or backs out, and returns to the same shop state. A scout should change route information; a quartermaster should change provisions; a fixer should change a social/contract option. The flow must not become a separate management game.

### 5.5 Recovery flow

After a route conflict realizes its disclosed cargo risk, the arrival and saved-history reports highlight **recovery options** that actually exist. The current implementation names the highest-value uncommitted surviving cargo stack and its full local sale value, then names the lowest-risk onward route affordable with current funds plus that sale. Contract-reserved cargo is not offered as recovery inventory. If neither option exists, the report points to the visible Local Opportunities blockers instead of implying that the run must restart. Future recovery extensions can add contract, contact, and useful waiting recommendations without changing this deterministic presentation boundary.

### 5.6 Save, pause, and settings flow

Pause is always available from the global rail. Save state is visible but quiet: an icon changes from *Saved* to *Saving* to *Saved at Reedwatch, Day 3*. Manual Save creates no surprise overwrite; Load presents settlement/day/cargo/money summaries. Settings use immediate preview for audio/text scaling and preserve focus/device selection when returning to play.

### 5.7 Invalid action and accessibility flow

When action preconditions fail, controls remain visible but communicate the reason in place. Keyboard focus, controller focus, and mouse hover surface the same tooltip. Error language names both the missing condition and a possible recovery step. Motion-reduction disables map camera movement and replaces travel animation with a legible progress sequence; text scaling preserves the action rail and never clips price reasons.

## 6. Alpha Navigation Model

| From | Primary action | To | State carried forward | Must not happen |
| --- | --- | --- | --- | --- |
| Main Menu | Start Game | Settlement Shop | Deterministic starting state | Map shown before the player understands the starting market. |
| Settlement Shop | Plan Departure | Departure Desk | Selected good, quantity, cargo, money, provisions | Buying/selling or travel accidentally executes. |
| Departure Desk | Return to Shop | Settlement Shop | Destination/route selection may persist; no resource changes | Player loses planning context. |
| Departure Desk | Commit Departure | Travel | Canonical route, destination, active cargo, forecast snapshot | Cost/risk differs from displayed route. |
| Travel | Resolve event / continue | Arrival Report | Command result and deltas | Generic loading screen hides an incident. |
| Arrival Report | Enter Settlement | Settlement Shop | Current settlement, resources, changed world state | Player is left without a clear next action. |
| Any gameplay screen | Pause | Pause/Save | Existing screen and selection | Save/load changes simulation outside command boundaries. |

## 7. UX Polish Backlog

The following sequence protects the core loop before visual scale.

| Priority | Slice | Definition of done | Validation question |
| --- | --- | --- | --- |
| **P0** | Shop/departure separation | No map behind trade controls; departure map is entered via a dedicated button; valid route forecast/commit controls live on the map screen. | Can a first-time player describe the difference between buying and committing travel? |
| **P0** | Arrival report | Every departure produces a clear route result and a one-click return to the destination shop. | Can a player name what changed after a trip without opening a log? |
| **P0** | Cost/risk explanation | Forecast is consistent with resolver; risks name source and consequence. | Does the player trust the forecast after an incident? |
| **P1** | Settlement identity | Each settlement has a banner, local need, icon language, and short arrival feedback. | Can the player identify where they are at a glance? |
| **P1** | Contracts and local opportunity cards | At least one trade-linked alternative objective per relevant settlement. | Does a relationship-driven plan coexist with profit seeking? |
| **P1** | One meaningful route event | Route event uses visible preparation and offers two understandable choices. | Does travel feel like more than a transition? |
| **P1** | Input/accessibility pass | Full keyboard/controller focus order, text scaling, tooltips, color-safe status. | Can a player complete a run without a mouse or color-only information? |
| **P2** | World reaction layer | Market, banner, route, and NPC reaction show consequences. | Does the player perceive regional memory before opening a report? |
| **P2** | Audio and microfeedback | Layered ambience and restrained purchase/travel/result sounds. | Does the game feel responsive without becoming noisy? |
| **P2** | Long-session polish | Autosave, safe save migration, error handling, analytics-free crash capture. | Can a player play 30–60 minutes without losing progress or context? |

## 8. Acceptance Criteria for the Implemented P0 Refactor

The playable prototype meets this UX slice when the following statements are true.

| Criterion | Verification |
| --- | --- |
| Launch presents a main menu and Start Game opens **Settlement Shop**, not the map. | UI smoke test and browser build visual check. |
| Shop contains only local trade, local context, cargo, the current market explanation, and a **Plan Departure** action. | UI smoke test verifies shop visibility and map hidden. |
| Plan Departure opens a dedicated **Departure Desk** with map, legal destinations/routes, selected load context, forecast, Return to Shop, and Commit Departure. | UI smoke test verifies visibility/state preservation. |
| Returning from the map changes no world resource or command history. | Serialization equality test. |
| Commit Departure retains authoritative route validation and begins presentation travel. | Economy test and UI smoke test. |
| Every arrival presents a clear result and an explicit path back to the settlement shop. | UI smoke test and manual interaction check. |
| No existing deterministic economy or save contract changes solely because of screen layout. | Existing headless economy suite remains green. |

## Sources

[1]: https://ffeartpage.com/pdf/ffestart.pdf "How To Start Frontier: First Encounters"
[2]: https://gamefaqs.gamespot.com/cd32/971966-frontier-elite-ii/faqs/80509/introduction "Frontier: Elite II — Guide and Walkthrough"
