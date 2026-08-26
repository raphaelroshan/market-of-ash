# Three-Game Quality Audit

## Purpose and method

This audit reviews the strongest reference games behind **Market of Ash**, **The Cartographer’s Siege**, and **Pack the Keep**. The goal is not to reproduce their features mechanically. It is to identify the failure cases that repeatedly appear in critical reviews and player feedback, then convert those cases into concrete design, usability, production, and testing safeguards.

The evidence is qualitative rather than statistical. It combines independent reviews, historical portal feedback, and accessible user-review excerpts. A repeated complaint across more than one source is treated as a stronger signal than a single negative opinion. Positive reviews are also useful: they reveal where a game successfully manages complexity, randomness, pacing, and presentation.

> The central lesson is that these games rarely fail because their core idea is weak. They fail when the player cannot understand the idea, cannot recover from an early mistake, spends too long preparing instead of playing, or reaches a repetitive state before the game has delivered enough variation.

## Executive conclusion

All three projects should adopt a **staged-complexity philosophy**. Introduce one rule, resource, unit, or threat at a time; show its cause and consequence; then give the player a meaningful chance to use it before adding another layer. The games should be difficult because choices matter, not because the interface, randomness, or undocumented interactions create accidental difficulty.

The most important quality gates are shared across the portfolio. Each game needs a readable first hour, a recovery path after failure, multiple viable strategic openings, a strong midgame that does not collapse into routine, and storefront-quality controls and presentation. Because the release target is Steam and Epic Games Store, Windows controller support, display scaling, cloud-safe saves, crash reporting, and build parity should be tested as core features rather than late polish.

| Priority | Portfolio-wide safeguard | Why it matters |
| --- | --- | --- |
| 1 | Prevent unrecoverable early death spirals | Several reference games punish players before they understand the rules. |
| 2 | Make information actionable and contextual | Players should see what a resource, enemy, route, or upgrade means at the moment of decision. |
| 3 | Test for dominant openings | A single optimal first build makes a strategy game feel solved and reduces replay value. |
| 4 | Keep preparation shorter than the interesting play | Menus, packs, runes, inventories, and setup must not overwhelm the actual game. |
| 5 | Design for the late game | A stable economy or defense must create new problems rather than simply guaranteeing a slow win. |
| 6 | Treat controls and platform parity as design | A strategy game with poor scaling, controller navigation, crashes, or delayed patches feels unfinished. |

## 1. Market of Ash

### Reference failures

The original **Frontier** has a compelling trade-and-travel premise, but historical player feedback describes the buying-and-selling loop as repetitive and the combat as inconsistent. That is a warning against interpreting “more towns and more commodities” as sufficient modernization. A commercial version must make travel, trade, crew, conflict, and reputation alter one another so that the player is making decisions rather than repeating arbitrage.[1]

**Merchant of the Skies** demonstrates both the appeal and the danger of the format. Independent reviews praise its accessible trading, production chains, discovery, and whimsical world, but identify several concrete weaknesses. Its early fuel system can bankrupt new players before they understand it; the interface scatters important information across menus; the economy becomes less interesting once production and automatic routes are established; the content and long-term endpoint can feel thin; and the soundtrack is too short for extended sessions.[2] [3] [4]

The underlying failure pattern is an economy that is initially tense but later becomes procedural. Once the player discovers the best routes, the main question becomes how long to repeat them. A second danger is a mismatch between mood and punishment: a relaxed trading fantasy can feel hostile if fuel bankruptcy is opaque or if failure is disproportionate to the information the player had.

### Design safeguards for Market of Ash

Market of Ash should make **trade a source of changing situations**, not merely a source of money. Prices should move because of visible causes such as harvests, blockades, faction laws, seasonal demand, war, weather, or rumors. The player should be able to take a safe but low-margin route, a risky high-margin route, or a politically useful contract. There should be no single permanently correct circuit.

The first expedition should be deliberately safe. The game should forecast travel cost, show the consequence of running short, and provide a rescue or fallback option. Early bankruptcy should never delete a save or end a campaign. If the game wants meaningful financial danger, it should introduce it after the player has completed enough successful routes to understand the model.

The information architecture should revolve around a **single market and route ledger**. It should show current price, recent trend, the reason for the trend, rumor confidence, route hazards, cargo capacity, travel cost, and outstanding commitments. A player should not need to memorize which town sells what or search through several screens to discover that a contract requires an item they cannot carry.

Production and automation should expand the player’s choices rather than obsolete trading. A factory can create stable supply, but it should also create exposure: it needs workers, fuel, protection, maintenance, or access to a route. Factions can restrict exports, pirates can disrupt a safe corridor, and local crises can make an apparently inferior good strategically valuable. The late game should turn the player from a route optimizer into a political and logistical operator.

| Failure case observed in references | Market of Ash prevention | Release test |
| --- | --- | --- |
| Fuel or travel rules bankrupt newcomers | Safe first route, clear forecasts, rescue option, and no early save deletion | New players complete the first three routes without external help; record confusion points. |
| Repetitive buy-low/sell-high loop | Volatile causes, faction policy, contracts, risk, spoilage, and route events | Simulate 100 route cycles; confirm that no single route dominates across seasons and world states. |
| Important information buried in menus | Unified route ledger with contextual explanations | Usability test: players answer “what should I carry and why?” within 15 seconds. |
| Production makes trade irrelevant | Factories create dependencies and strategic exposure | Midgame playtesters still choose between at least three materially different economic strategies. |
| Thin content or weak endpoint | Regional campaign arc, escalating crises, visible goals, and multiple endings | Players can describe their next meaningful objective after the first five hours. |
| Poor long-session audio | Layered ambient sound, route-specific music, and non-restarting transitions | Two-hour comfort test with repeated travel and menu transitions. |

### High-quality target

Market of Ash should feel **calm on the surface and consequential underneath**. The ideal moment is not “I found the best price.” It is “I can make a profit here, but doing so will empower a faction, expose my convoy, and leave another settlement short of medicine.” The art can remain 2D and economical, but the simulation must generate stories that the original loop could not.

## 2. The Cartographer’s Siege

### Reference failures

The Cartographer’s Siege is the most exposed to the interaction between route planning, map construction, defense, and procedural uncertainty. **Isle of Arrows** is a useful reference because it makes the board itself part of the strategy, but reviews identify a persistent death spiral: weak tile or tower draws can doom a run long before the visible defeat, and campaign progression can reveal the tool needed for a challenge only after the player has failed it.[10] [11]

**Bad North** shows a different problem. Its minimalist island defense is tactically clear, but its roguelite structure forces players to repeat slow, easy opening islands before reaching the interesting battles. The upgrade space is narrow, some classes become mandatory counters rather than genuine choices, and the midpoint difficulty can rise sharply.[5]

**Creeper World 4** demonstrates how a distinctive enemy can still produce attritional pacing. One review notes that a stable opening can make the rest of a level feel like a slow, nearly guaranteed victory; missions sometimes introduce a unit without teaching its purpose, then later depend on it.[13] The lesson is important for a cartography game: a clever map system is not enough if the player solves the map early and then waits.

### Design safeguards for The Cartographer’s Siege

The core promise should be **drawing a road that creates opportunity and vulnerability**. A cheap road should open trade and shorten travel, but it should also be harder to defend, easier to raid, or more exposed to weather and terrain. A fortified road should be safer but expensive, slow to build, and politically visible. The tradeoff must be legible on the map before the player commits.

Road construction should create a controlled risk rather than a hidden trap. The player should see likely enemy approaches, maintenance cost, supply distance, and defensive coverage. If a route is doomed, the game should communicate why and offer a retreat, reroute, toll, escort, or emergency fortification. The player should lose because the chosen risk did not pay off—not because an unseen rule invalidated the plan.

Procedural maps should be **constrained rather than purely random**. Every expedition should guarantee access to the broad categories of tools needed to respond to threats: mobility, scouting, economy, fortification, and combat. Randomness can decide which version arrives and when, but it should not remove an entire strategic category. A reserve card, redraw, scouting action, or emergency construction order can preserve agency without making the game easy.

The midgame needs active disruption. Once a road network reaches a stable state, introduce caravans with different requirements, enemy doctrines that attack infrastructure rather than only endpoints, changing weather, map claims, bridge failures, political tolls, or cartographic misinformation. The player should be forced to redraw the network rather than merely add more defenses to a solved corridor.

| Failure case observed in references | Cartographer’s Siege prevention | Release test |
| --- | --- | --- |
| Bad procedural draw makes a run unwinnable | Guaranteed strategic categories, reserve options, and constrained map generation | Run thousands of seeded maps; verify that losses are attributable to decisions, not missing tool categories. |
| Early mistakes create invisible death spirals | Show route health, supply risk, defense coverage, and recovery actions | Ask testers to identify the moment a route became unsafe and what alternatives existed. |
| Repeated early content delays the interesting game | Fast-forward mastered travel, persistent cartographic knowledge, or varied starting contracts | Measure time-to-first-meaningful-map-decision across repeated runs. |
| One class becomes a required counter | Threats should have several counter families, including terrain and logistics answers | Balance review: no single unit or defense should be mandatory in more than a small minority of scenarios. |
| Stable defense turns the late game into waiting | Escalating infrastructure threats, active objectives, and changing routes | Observe whether players continue making consequential decisions after reaching initial stability. |
| New mechanics are not taught by the level that introduces them | Use authored teaching scenarios with low stakes and explicit feedback | A first-time player should correctly use each new road or map tool in its introduction scenario. |

### High-quality target

The Cartographer’s Siege should feel like **a beautiful planning problem that becomes a crisis of geography**. The player should look at a road and immediately understand its economic value, defensive cost, and strategic consequence. The 2D presentation is well suited to layered parchment maps, hand-inked routes, moving weather fronts, readable elevation bands, and animated trade flows. The art direction should make risk visible rather than decorate it.

## 3. Pack the Keep

### Reference failures

Pack the Keep sits closest to the creative tower-defense references. **Orcs Must Die! 3** shows the strength of combining direct hero control with trap layouts, but a review notes that later maps can feel designed for co-op, making solo play disproportionately difficult, and that grinding earlier stages can become the solution to progression spikes.[6]

**Dungeon Warfare 2** offers extensive traps, runes, skills, and modifiers, but user reviews identify a recurring preparation problem: the setup layer can take longer than the board itself, percentage-heavy optimization can feel like spreadsheet work, and bad UI or unreliable upgrades undermine trust.[7]

**Ratropolis** demonstrates the creative potential of leaders, cards, real-time defense, and settlement management. Its weaknesses are equally instructive: unlocking can feel grindy, overlapping units are difficult to select, and predictable enemy waves can reduce the surprise that justifies a hybrid system.[8]

**Rogue Tower** and **Isle of Arrows** highlight two more risks. Poor UI scaling and weak explanation can make a promising system feel unfinished, while random upgrades or tile draws can leave the player without a viable build.[9] [10] **Mindustry** shows the opposite extreme: its automation and defense systems are powerful but can become a very long tutorial with unintuitive controls and wiki-dependent interactions.[12]

### Design safeguards for Pack the Keep

Pack the Keep should be built around a clean fantasy: **choose a commander, open a pack, place a small number of meaningful defensive pieces, and watch the keep express that doctrine under pressure**. Packs should not be collectible clutter. Each pack should represent a coherent answer to a problem: militia defense, fire control, engineering, beasts, alchemy, scouts, counter-siege, or deception.

The top-down keep must remain readable at normal play distance. Buildings, walls, units, hazards, and attack indicators need distinct silhouettes and color roles. Selection must work through direct clicking, marquee selection, keyboard shortcuts, and controller navigation. If units overlap, the player should still be able to select the intended group and understand its current assignment.

Preparation must be short enough that the player looks forward to opening the next pack. A commander should receive a small set of choices with clear previews: “this pack adds pikemen, a repair station, and a narrow-gate doctrine.” Avoid stacking cards, runes, passive skills, equipment, and percentage modifiers until the core defense is already satisfying. Complexity should be earned by play and revealed in layers.

The game should support a **planning mode with pause and speed controls**, even if the real-time defense is energetic. This preserves strategic accessibility without removing urgency. The player should be able to pause, inspect an enemy, queue an order, and resume. If the game later adds optional challenge modes with less pause control, those should be explicit variants rather than the default experience.

Commanders should change the keep’s doctrine, not simply provide different bonuses. One commander might specialize in compact layered defenses; another might sacrifice walls for mobile counterattacks; a third might turn civilian buildings into decoys and traps. The key quality criterion is that each commander changes what the player notices and values, while remaining balanced in solo play.

| Failure case observed in references | Pack the Keep prevention | Release test |
| --- | --- | --- |
| Solo maps feel tuned for co-op | Balance every mission for solo first; treat co-op as an extension | Complete every campaign map with a solo difficulty pass and telemetry on abandoned attempts. |
| Setup takes longer than the battle | Cap pack decisions, provide loadout templates, and allow fast confirmation | Track average preparation time; investigate whenever setup exceeds the intended target. |
| Too many modifiers obscure the real strategy | Use a small number of expressive pack effects with plain-language previews | Ask testers to predict the effect of a pack before opening it; target high agreement. |
| Selection and targeting fail under pressure | Group selection, priority targeting, pause, speed control, and clear feedback | Stress test with overlapping units and simultaneous attacks at multiple zoom levels. |
| Broken upgrades destroy trust | Data-driven effects, deterministic simulation, automated fixtures, and visible before/after feedback | Test every pack against every enemy family and assert expected outcomes. |
| Waves become predictable or solved | Authored enemy doctrines plus controlled variation and counter-intelligence | Test whether players can explain the threat without knowing the exact spawn script. |
| Randomness removes agency | Offer reserve, discard, redraw, scouting, or commander-based mitigation | Review loss reports and classify each as decision failure, execution failure, or luck failure. |
| Automation games become inaccessible | Keep optimization optional; make the first hour a complete defense game | New testers should win or meaningfully understand a first scenario without a wiki. |

### High-quality target

Pack the Keep should feel **fast to read, satisfying to arrange, and dramatic to recover**. The pleasure should come from seeing a coherent defensive idea work: a commander’s doctrine, a pack’s identity, a fort layout, and a last-second intervention all becoming visible in the battlefield. The art direction can use a 2D illustrated top-down style with strong silhouettes, chunky architectural shapes, animated banners, readable pack icons, and expressive impact effects. The visual language must prioritize tactical legibility over decorative density.

## Shared testing and commercial-polish gates

The three games should share a common quality process even though their designs remain separate. Every major mechanic should have a written design contract: its player-facing purpose, inputs, outputs, edge cases, failure message, save behavior, and test fixtures. This is especially important for an agent-first workflow, because a written contract gives coding agents something more reliable than an ambiguous feature request.

### Prototype gates

| Gate | Required evidence before adding more content |
| --- | --- |
| Core loop | A new player can explain the game’s central decision after one short session. |
| Failure clarity | After losing, the player can state what caused the loss and name at least one alternative. |
| Recovery | A bad decision damages the run but does not automatically determine the next hour. |
| Variety | At least three openings or strategies are viable on the prototype content. |
| Midgame | Reaching a stable economy, route, or defense creates a new decision rather than a waiting period. |
| Interface | Mouse, keyboard, controller, high-DPI scaling, and common aspect ratios are usable before content production accelerates. |
| Performance | Repeated waves, large inventories, route graphs, and save/load cycles remain stable on target hardware. |
| Storefront | Steam and Epic builds launch cleanly, save safely, support the planned achievements and cloud behavior, and produce useful crash logs. |

### Playtesting plan

Testing should begin with **observational playtests**, not surveys. Watch where players hesitate, what they misread, what they click repeatedly, and when they stop making decisions. Ask them to think aloud only after the session if doing so would distort play. Record the first-confusion event, first irreversible mistake, first moment of delight, and first point at which the player starts repeating a solved procedure.

The second layer should be **instrumented simulation**. Market of Ash needs route and economy simulations to detect dominant trade loops. The Cartographer’s Siege needs seeded map tests to detect unwinnable generation and overpowered road patterns. Pack the Keep needs combination tests for packs, commanders, buildings, and enemy types. Agents are particularly useful here because the simulation rules can be expressed as structured data and run headlessly in continuous integration.

The third layer should be **content and usability review**. Every new mechanic needs a teaching scenario, every menu needs a controller path, every important number needs a readable explanation, and every visual state needs a recognizable icon or animation. A system is not finished when it works internally; it is finished when a player can predict it, use it, and recover from it.

## Commercial polish checklist

The Steam and Epic versions should ship with a single authoritative ruleset and synchronized content builds. Saves should be versioned and migrate safely. Cloud saves should contain only the necessary player state, not machine-specific settings or large temporary files. The game should support offline single-player play wherever platform requirements permit it, while storefront services remain behind thin adapters.

The store page should communicate the distinctive hook in one sentence and demonstrate it in the first trailer beat. The screenshots should show the actual decision-making interface, not only scenic art. The demo should reach the core loop quickly and include enough progression to show why the game is more than a nostalgic remake. The launch build should include rebinding, display scaling, windowed and fullscreen modes, readable text, color-safe cues, autosave clarity, and a way to report a problem without leaving the game.

For commercial trust, avoid promising a deep simulation, huge content volume, or multiplayer mode unless those features are demonstrable in the first public build. A smaller, coherent game with excellent feedback and clear scope will outperform a broader game whose systems feel unfinished. The portfolio should favor **one polished signature interaction per game** over three underdeveloped genres inside each title.

## Final quality bar

The three projects should be approved for full production only when external testers independently demonstrate the intended fantasy. A Market of Ash tester should voluntarily compare routes, anticipate consequences, and care about the people or factions affected by commerce. A Cartographer’s Siege tester should deliberately choose between cheap exposure and expensive safety, then redraw routes in response to changing pressure. A Pack the Keep tester should identify with a commander, understand a pack’s doctrine, and feel responsible for the keep’s layout rather than merely placing generic towers.

If the testers instead ask “what does this number mean?”, “why did I lose before I could respond?”, “what is the correct build order?”, “why am I repeating this same section?”, or “why did that upgrade not work?”, the project is not ready for more content. Those questions are not minor polish issues; they indicate that the core promise is being obscured by execution.

## References

[1]: <https://www.newgrounds.com/portal/view/513305> “Frontier — Newgrounds.”
[2]: <https://www.nintendoworldreport.com/review/54498/merchant-of-the-skies-switch-review> “Merchant of the Skies — Nintendo World Report.”
[3]: <https://goldplatedgames.com/2019/08/07/review-merchant-of-the-skies/> “Review: Merchant of the Skies — Gold-Plated Games.”
[4]: <https://goombastomp.com/merchant-of-the-skies-review/> “‘Merchant of the Skies’ Is An Experiment That Will Fly or Dive — Goomba Stomp.”
[5]: <https://xblafans.com/bad-north-review-couldve-been-worse-north-99797.html> “Bad North review: could’ve been worse north — XBLAFans.”
[6]: <https://www.gamingnexus.com/Article/6139/Orcs-Must-Die!-3-Review/> “Orcs Must Die! 3 Review — Gaming Nexus.”
[7]: <https://apps.apple.com/us/app/dungeon-warfare-2/id1453661259?see-all=reviews&platform=iphone> “Dungeon Warfare 2 — Ratings & Reviews — Apple App Store.”
[8]: <https://gideonsgaming.com/ratropolis-review-inspired-rodent-like-slays/> “Ratropolis Review: Inspired Rodent-like Slays — Gideon’s Gaming.”
[9]: <https://howlongtobeat.com/game/103814/reviews/score/1> “Rogue Tower — Reviews — HowLongToBeat.”
[10]: <https://www.148apps.com/isle-of-arrows/isle-of-arrows-tower-defense-review/> “Isle of Arrows — Tower Defense review — 148Apps.”
[11]: <https://mobigamescenter.substack.com/p/isle-of-arrows> “Isle of Arrows Review — Mobile Games Center.”
[12]: <https://tildesare.cool/2025/01/17/game-review-mindustry-steam/> “Game Review: Mindustry — Steam — Tildes on the Side.”
[13]: <https://saveorquit.com/2020/12/23/review-creeper-world-4/> “REVIEW: Creeper World 4 — Save or Quit.”
[14]: <https://www.heypoorplayer.com/2023/03/25/the-last-spell-review-ps5/> “The Last Spell Review: Brutal And Beautiful SRPG Action — Hey Poor Player.”
[15]: <https://gideonsgaming.com/the-last-spell-review/> “The Last Spell Review — Gideon’s Gaming.”
[16]: <https://www.eurogamer.net/against-the-storm-review-a-perfectly-chaotic-city-builder> “Against the Storm review — Eurogamer.”
[17]: <https://gideonsgaming.com/dome-keeper-review/> “Dome Keeper Review — Gideon’s Gaming.”
