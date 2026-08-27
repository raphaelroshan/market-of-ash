# Open Routes, Shared Wells — Ending Proof

The first-priority deterministic campaign ending is evaluated at crisis stage 3 (day 10 or later).

Required state:

- `reedwatch_water_relief_01` is archived as completed;
- Reedwatch resilience is at least 2;
- arms escalation is at most 1.

When all predicates hold, the save records `ending_id = open_routes_relief` and the authored regional summary. The ending is stable once reached. If both current endings qualify, shared relief wins by authored list order. Missing all ending predicates leaves the campaign in `Settlement decision` with its objective visible, allowing continued recovery and trade.

The four visible crisis stages are Ordinary pressure, Thin wells, Empty reservoir, and Settlement decision. Stage changes occur only from elapsed days and recompute the existing crisis price modifiers deterministically.
