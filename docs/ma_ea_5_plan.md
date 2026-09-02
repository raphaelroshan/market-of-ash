# MA-EA-5 — crew, event, and replay-depth acceptance plan

## Player-facing behavior

The two lighter regions gain one memorable specialist and one additional road
problem each. Mara Voss can be hired at Blackreed Post and turns carried scrap
into a permanent safer line through a Reedline wheel sink. Orin Bell can be
hired at Mirror Wells and turns carried lamp oil into permanent occlusion marks
when two beacon lines divide the Mirror Run.

Both encounters remain solvable without the matching specialist. The crew
response is visible but disabled with an exact prerequisite until that person
is assigned, and its material cost is enforced by the command layer. Money,
time, provisions, and disclosed cargo-risk alternatives preserve viable
recovery paths.

## Authored data shape

- Crew member: `mara_voss`, a Blackreed wheelwright whose one-scrap event
  response creates `reedline_split_axle_markers`.
- Event family: `reedline_wheel_sink`, with paid, delayed, risky, and
  crew-enabled deterministic branches.
- Crew member: `orin_bell`, a Mirror Wells signal reader whose one-lamp-oil
  response creates `mirror_run_occlusion_posts`.
- Event family: `mirror_beacon_split`, reached on later Mirror Run crossings
  after the existing Shardwind encounter, with licensed, delayed, risky, and
  crew-enabled deterministic branches.
- Runtime content version advances to `1.26.0`; save format remains version 12
  because roster, pending event, information, and route-condition persistence
  already use stable, data-driven identifiers.

## Acceptance gates

1. The runtime exposes five crew members and eight event families, meeting the
   Early Access breadth floor without adding passive stat-only recruits.
2. Each new crew member has a distinct portrait, home settlement, cost,
   limitation, route notes, and a resource-backed event response.
3. Every response is deterministic, visibly costed, and has a zero-resource
   fallback; unavailable specialist responses do not mutate journey resources.
4. Pending-event replay and completed route conditions survive save/load.
5. Native evidence at all four supported viewports shows both Caravan Yard
   offers, both encounters, and both persistent consequence receipts without
   developer UI.

