# Market of Ash Quality Contract

Reviewers must treat this game as a deterministic single-player trade-and-route strategy prototype. Changes should preserve visible cause and effect: prices, shortages, route risk, crisis state, fuel, cargo, and settlement recovery must be explainable from state and events.

## Gameplay review criteria

A change is suspect when it makes fuel, bank balance, bankruptcy, or route danger opaque; rewards repetitive arbitrage without meaningful route consequences; makes production invalidate trade too quickly; scatters core decisions across unrelated menus; or removes a credible recovery path after a bad run. Review whether a player can understand why a transaction succeeded or failed and what the next recoverable action is.

## Architecture and QA criteria

Keep economy logic presentation-independent, deterministic under a fixed seed, serializable, and covered by focused headless tests. Prefer explicit commands and result objects over hidden mutation. Add regression tests for price changes, fuel/bankruptcy boundaries, route risk, crisis effects, invalid actions, and save/load round trips whenever those systems change.

## Release-quality criteria

Do not add storefront integrations, network requirements, or credentials to the simulation layer. Controller and keyboard/mouse paths should reach the same commands. A visual or UI change must not silently alter deterministic outcomes.
