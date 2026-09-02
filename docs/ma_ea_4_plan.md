# MA-EA-4 — faction and adaptive-ending acceptance plan

## Player-facing behavior

The Causeway Bellkeepers become the fourth standing faction. Paying their road
guides or funding a current bell chart builds trust; ignoring their line in a
whiteout costs trust. Trusted caravans pay less on the Salt Causeway, while the
road's cargo risk remains visible and unchanged.

The existing Night Market becomes a complete alternate political path rather
than only a replacement shop. After the official beacon offer expires or
fails, the player can support, oppose, and later reconcile with the local
guides. Positive support, Mirror Wells resilience, and a post-activation
ordinary saltglass delivery can produce a distinct ending. Contract and event
transfers cannot satisfy that delivery requirement.

## Authored data shape

- Standing faction: `bellkeepers`, with bounded reputation, a trusted
  threshold, and a named Salt Causeway discount.
- Night Market interactions: the existing beacon support plus a public signal
  ledger and a Consortium license opposition path.
- Adaptive ending: `ending_night_market_network`, expressed with the same
  generic scenario-state, faction-support, settlement-resilience, ordinary-
  delivery, reputation, and escalation requirements as the Commons ending.
- Runtime content version advances to `1.25.0`; save format remains version 12
  because standing is already dynamically keyed and adaptive state already
  persists through the current schema.

## Acceptance gates

1. Bellkeeper standing changes only through authored commands/events, clamps to
   faction bounds, survives save/load, and discounts only the Salt Causeway at
   the trusted threshold.
2. Night Market support can move positive, negative, and back toward neutral
   without closing ordinary trade.
3. The Night Market ending requires post-activation ordinary saltglass trade;
   pre-activation, contract, and event transfers do not qualify.
4. Both adaptive endings use the shared evaluator and preserve deterministic
   priority when multiple outcomes qualify.
5. Native evidence shows Bellkeeper route terms, Night Market cooperation and
   opposition, and the resulting alternate-ending debrief with no debug UI.
