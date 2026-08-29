# Market of Ash Quality Contract

Reviewers must treat this game as a deterministic single-player trade-and-route strategy prototype. Changes should preserve visible cause and effect: prices, shortages, route risk, crisis state, fuel, cargo, and settlement recovery must be explainable from state and events.

## Gameplay review criteria

A change is suspect when it makes fuel, bank balance, bankruptcy, or route danger opaque; rewards repetitive arbitrage without meaningful route consequences; makes production invalidate trade too quickly; scatters core decisions across unrelated menus; or removes a credible recovery path after a bad run. Review whether a player can understand why a transaction succeeded or failed and what the next recoverable action is.

The Frontier trade promise is a release-critical constraint. Review whether regional price differences remain visible and explainable; whether distant markets can be more profitable without always dominating nearby recovery trades; whether high and low demand respond to local causes and recent deliveries; whether supply saturation is bounded and readable; and whether the player can compare gross margin against route cost, provisions, risk, time, and opportunity cost before departure. Settlement services must deepen these choices rather than replace trading with a checklist. Buying and selling spot goods should remain immediately available, while contracts, recruitment, guards, reports, repairs, storage, diplomacy, and relief must show their costs, benefits, duration, and meaningful downside before confirmation.

## Architecture and QA criteria

Keep economy logic presentation-independent, deterministic under a fixed seed, serializable, and covered by focused headless tests. Prefer explicit commands and result objects over hidden mutation. Add regression tests for price changes, fuel/bankruptcy boundaries, route risk, crisis effects, invalid actions, and save/load round trips whenever those systems change.

The executable minimums live in `tests/test_game_quality.gd` and `tools/game_quality_metrics.gd`: the guided opening must complete across all 100 deterministic seeds with at least 60 ashmarks and 9 provisions remaining; at least three positive opening strategies across three goods and both road types must exist; authored staple, repair, medicine, and industrial trades must remain profitable without contracts; the best ordinary opening must retain at least 70% of the accessible relief contract's expected value; changing market/access state must rotate the best plan across three choices and both road types; a command-path cargo loss must recover starting cash within three outbound trades without reaching zero money or provisions; and the tutorial must reach its first cargo purchase within two authoritative commands. Any intentional threshold change requires updated evidence in `research/playtest_simulation/`.

## Release-quality criteria

Do not add storefront integrations, network requirements, or credentials to the simulation layer. Controller and keyboard/mouse paths should reach the same commands. A visual or UI change must not silently alter deterministic outcomes.
