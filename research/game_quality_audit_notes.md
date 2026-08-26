# Game Quality Audit Notes

## Scope
This audit extracts recurring failure cases from reviews and user feedback for the inspiration set. The findings are evidence for design safeguards, not claims that any one review represents the entire player base. The strongest signals are repeated across independent reviews or describe concrete, observable product problems.

## Market of Ash / Frontier-like references

### Frontier — Newgrounds
URL: https://www.newgrounds.com/portal/view/513305

Search-result review text identifies repetitive buying and selling, hit-or-miss combat, and presentation that could use more flair. Design implication: the remake needs more than a larger list of towns and goods; travel, trade, crew, and combat must alter one another. A route should create stories and consequences instead of reducing play to repeated arbitrage.

### Merchant of the Skies — independent reviews
URLs:
- https://www.nintendoworldreport.com/review/54498/merchant-of-the-skies-switch-review
- https://goldplatedgames.com/2019/08/07/review-merchant-of-the-skies/
- https://goombastomp.com/merchant-of-the-skies-review/

Recurring issues:
- The opening fuel constraint can bankrupt new players before they understand the system. The fuel gauge and recharge rules are difficult to grasp.
- The interface is functional but confusing. Information is spread across menus, quest requirements are not always visible where needed, and owned islands/buildings are hard to review at a glance.
- The economy becomes easier and less interesting after the player builds production and automatic routes; early buying-low/selling-high becomes less relevant.
- The game can feel short on content and variety, and the campaign/sandbox structure lacks a strong long-term endpoint for some players.
- The soundtrack is very short and repeatedly restarts when changing locations, damaging long-session comfort.
- Threats and opposition are limited, so the player’s main obstacle is often self-imposed resource management rather than a dynamic world.

Safeguards for Market of Ash:
- Explain fuel/provisions through a safe first route, forecast the cost of failure, and avoid save-deleting or bankruptcy mechanics in the opening hours.
- Create a single market ledger that shows price, cause, trend, rumor confidence, and the player’s relevant route information.
- Ensure trade remains meaningful after production begins by making local crises, faction policies, transport capacity, spoilage, contracts, and political consequences change the value of routes.
- Build a regional campaign arc with visible escalation and endings; do not rely on an endless sandbox as the sole source of motivation.
- Budget an adaptive music system and varied travel ambience from the beginning.

## Rebuild-like references

### The Last Spell — independent reviews
URLs:
- https://www.heypoorplayer.com/2023/03/25/the-last-spell-review-ps5/
- https://gideonsgaming.com/the-last-spell-review/

Recurring issues:
- The game is highly punishing and the early run can end before players understand the economy, gear, and recovery rules.
- Meta-progression can feel glacial, and a failed night can cause a snowball: damage and panic reduce future resources, which makes the next failure more likely.
- The first production phase has a clear optimal build order, especially around houses/workers, reducing early strategic variety.
- Boss encounters can produce abrupt difficulty spikes after hours of successful preparation.
- Controller navigation through character sheets, gear, stashes, and skills takes too many inputs; platform parity problems can make non-PC players feel like second-class customers.

Safeguards for a Rebuild-style game:
- Provide a low-pressure first district and a recovery path after a bad night. Failure should damage the run without making the next outcome nearly predetermined.
- Avoid making one early building or resource the obvious dominant choice. Use multiple viable openings and test them through simulation.
- Preview boss doctrines or let players gather intelligence so a boss feels like a test of preparation, not a surprise reversal.
- Design controller navigation at the same time as mouse navigation, with quick access to survivor information and contextual actions.
- Keep content and balance synchronized across storefront builds; define a single versioned ruleset and automate regression checks.

### Bad North — independent review
URL: https://xblafans.com/bad-north-review-couldve-been-worse-north-99797.html

Recurring issues:
- The compact tactical core is strong, but the roguelite structure forces players to repeat slow, easy opening islands before reaching the interesting battles.
- The simple upgrade system leaves little room for experimentation; all three unit classes become necessary, so choice can feel prescribed.
- Random maps and rewards do not sufficiently compensate for limited strategic variation.
- Midpoint difficulty rises sharply, and the player can lose everything without enough persistent progression or a way to retry a difficult island.
- The game has little narrative and many battles serve mainly as progression gates.

Safeguards:
- Let players skip or accelerate mastered early content, or start later runs with a meaningful selection of tools.
- Give survivors or districts several viable specialization paths rather than one required counter for each enemy.
- Make individual locations matter narratively or economically so battles are not only checkpoints.
- Add flexible recovery, scouting, or limited retreat so failure teaches rather than erases an entire evening.

## Creative tower-defense references

### Orcs Must Die! 3
URL: https://www.gamingnexus.com/Article/6139/Orcs-Must-Die!-3-Review/

Recurring issues:
- Later maps can feel designed for co-op, making solo play disproportionately difficult.
- Progression does not always feel correctly balanced; grinding earlier stages can become the solution to difficulty spikes.
- Story scenes are attractive but often function as connective tissue rather than meaningful narrative.

Safeguards for Pack the Keep:
- Balance single-player as a first-class mode, not as a reduced co-op experience.
- Ensure difficulty spikes are preceded by readable enemy intelligence and counterplay.
- Use commander stories and fort consequences that affect play rather than decorative cutscenes alone.

### Dungeon Warfare 2
URL: https://apps.apple.com/us/app/dungeon-warfare-2/id1453661259?see-all=reviews&platform=iphone

Recurring issues:
- Some players find the preparation layer too long relative to active play.
- Large numbers of items, runes, skills, trap variants, and percentage modifiers can feel like spreadsheet optimization rather than tactical experimentation.
- Mobile users report bad UI, crashes, broken or ineffective upgrades, and bugs that make outcomes uncertain.
- Very difficult maps can become frustrating when a trap or barricade does not behave consistently.

Safeguards:
- Keep pack selection fast and legible; show the tactical consequence of a pack before committing.
- Prefer a small number of expressive interactions over many percentage modifiers.
- Test every pack, upgrade, and building combination in automated fixtures; never ship an upgrade whose effect is hard to verify.
- Make construction and collision outcomes deterministic and visibly acknowledged.

### Ratropolis
URL: https://gideonsgaming.com/ratropolis-review-inspired-rodent-like-slays/

Recurring issues:
- Unlocking cards and advisors can feel grindy.
- Real-time card play creates clicking and targeting problems when units overlap or many units occupy one wall.
- Enemy waves can become predictable after players learn the fixed progression pattern.
- The combination of deckbuilding, real-time management, and defense can be frustrating for players who expect deliberation from a deckbuilder.

Safeguards:
- Make packs earnable at a satisfying cadence and ensure new content changes decisions, not only numbers.
- Provide clean unit selection, group commands, pause/speed controls, and a readable fort layout.
- Mix authored enemy doctrines with procedural variations so players can plan without solving a fixed script.
- State clearly whether the game is a real-time execution test or a planning game with pause; do not leave the control philosophy ambiguous.

### Isle of Arrows
URLs:
- https://www.148apps.com/isle-of-arrows/isle-of-arrows-tower-defense-review/
- https://mobigamescenter.substack.com/p/isle-of-arrows

Recurring issues:
- Random tile and enemy choices can create losses that feel outside the player’s control.
- The death-spiral problem is not solved: an early weak draw can doom a run long before the visible game-over moment.
- Campaign progress may reveal the tools needed to pass a hurdle only after the player has already failed it.
- Buildings can look similar enough that players need to click them to confirm their function.
- The game offers little story, so its replay value depends almost entirely on the procedural puzzle.

Safeguards:
- Use constrained randomness, guaranteed categories of options, and reroll or reserve mechanics so bad luck creates adaptation rather than helplessness.
- Show a run-health or recovery model and give players a way to repair a weak opening.
- Make every building silhouette and color role distinct at the normal zoom level.
- If there is no narrative, make the challenge structure unusually strong and transparent; otherwise add a light campaign frame.

### Rogue Tower
URL: https://howlongtobeat.com/game/103814/reviews/score/1

Recurring issues:
- Reviews cite unclear UI scaling and weak communication of mechanics.
- Random upgrades can leave players without the tools needed for a viable build.
- Fixed enemy-defense progression encourages similar upgrade paths each run.
- Bad path branching or card luck can make restarting preferable to adapting.
- Repetitive achievements and limited explanation reduce perceived polish.

Safeguards:
- Design for multiple viable answers to each enemy-defense type.
- Provide readable path previews, card odds, upgrade explanations, and a restart/recovery choice that does not waste the player’s time.
- Use UI scaling tests at multiple resolutions and display sizes before adding content.
- Avoid achievements that reward repetition without teaching a meaningful skill.

## Cross-cutting patterns identified so far

1. **Death spirals:** Early mistakes or bad random draws can make recovery impossible before the player knows it.
2. **Opaque information:** Players cannot see why they failed, what a resource does, or where a required item is located.
3. **Dominant openings:** One building, unit, or upgrade path becomes obviously correct, especially in early waves.
4. **Preparation overhead:** Inventory, packs, runes, menus, and setup take longer than the actual interesting decisions.
5. **Content flattening:** An initially exciting core loop becomes routine when production, enemy waves, or routes become predictable.
6. **Platform and control debt:** PC-first interfaces, poor scaling, clumsy controller support, crashes, or delayed patches damage otherwise strong games.
7. **Weak long-term framing:** A sandbox or roguelite can lack narrative, campaign escalation, or a satisfying endpoint.
8. **Randomness without agency:** Procedural variation is exciting only when the player can understand, influence, or recover from it.

## Additional Rebuild-adjacent findings

### Against the Storm — Eurogamer review
URL: https://www.eurogamer.net/against-the-storm-review-a-perfectly-chaotic-city-builder

The review is strongly positive, but its useful lesson is how the game prevents randomness from feeling arbitrary. Players know biome strengths, settlement modifiers, and impending hostility effects before committing. The review also shows the danger of complexity: resource pipelines can become chaotic, and an incomplete production chain can stall a settlement. The game succeeds because it gives the player information and multiple ways to recover or reroute the plan. It also provides resizable UI, togglable visual effects, remapping, and extensive autopause settings.

Safeguard: Rebuild should preview threats and consequences early enough for players to plan, and should offer more than one route to a goal. Complexity should be accompanied by clear causality, not merely more meters.

### Dome Keeper — independent review
URL: https://gideonsgaming.com/dome-keeper-review/

Recurring issues:
- The first upgrades are close to mandatory: drill, jet pack, carrying capacity, and dome health dominate early decisions.
- Artifacts can reduce agency by determining which upgrade path is optimal; finding an elevator, for example, changes the need for carrying-capacity upgrades.
- The most efficient mining pattern becomes obvious, causing later runs to feel systematic rather than exploratory.
- The compact game has charm and strong audio/animation, but its replay value falls off earlier than players expect from a roguelite.

Safeguards: A Rebuild-style game should avoid making the first construction choices obviously mandatory. If a special survivor, building, or discovery changes optimal play, it should open several new strategies rather than merely cancel one upgrade path. The game needs enough campaign variation and human consequences that the player is not only repeating the same efficient procedure.

## Additional cross-cutting finding

The most successful games in this set do not eliminate complexity; they **stage it**. Against the Storm gradually expands choice while preserving advance information. The Last Spell creates depth through combinations but risks punishing early confusion. The practical target for our games is staged complexity: reveal one new rule at a time, show its cause and consequence, and preserve a recovery option until the player has had a fair chance to understand the system.

## Automation and spatial-defense findings

### Mindustry — independent review
URL: https://tildesare.cool/2025/01/17/game-review-mindustry-steam/

The review is highly positive but identifies a steep learning curve, controls and mechanics that are not always intuitive, keyboard/mouse-only control, and a progression that can feel like a very long tutorial. Some interactions are effectively wiki-dependent. The game’s complexity and long sessions are a strength for its audience but a barrier for players seeking an approachable strategy game.

Safeguards for Pack the Keep: separate core defense decisions from optional optimization, use clear contextual explanations, support controller input if targeting Steam/Epic broadly, and make the first hour a complete game rather than a long prelude to the real system.

### Creeper World 4 — independent review
URL: https://saveorquit.com/2020/12/23/review-creeper-world-4/

The review identifies weak documentation for some mechanics, a tendency for many levels to follow the same high-level pattern once a stable base is established, and awkward pacing in which the opening is the hardest part and the rest becomes attritional. Missions intended to teach a unit sometimes fail to make its purpose clear, then later missions suddenly depend on that unit.

Safeguards: introduce each pack, building, or enemy in a scenario that makes its use legible; prevent a defense from becoming an automatic victory once the player reaches a stable state; use escalation, secondary threats, or timed objectives to keep the late phase active.

## Audit interpretation

A high review score does not mean a game has no failure cases. The most valuable lessons come from the specific reasons a positive game loses players: confusing onboarding, mandatory early choices, repetitive midgame, opaque random outcomes, platform-control debt, and content that does not justify the promised genre. The final report should therefore distinguish **core concept success** from **execution failure**.
