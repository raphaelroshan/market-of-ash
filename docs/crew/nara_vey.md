# Nara Vey — First Crew Proof

Nara is a scout whose value is better route context, not guaranteed safety.

- Recruit in Ashgate for 20 ashmarks and one visit slot.
- Assign or refresh her for one visit slot. A successful assignment writes reports only for routes leaving the current settlement.
- Reports are `scout_informed` on the observed day and `stale` after time advances.
- The route forecast always retains its authored risk percentage. Nara adds a route-specific field note and confidence state; she does not change the random roll or suppress events.
- Recruited state, active assignment, and reports serialize. A settlement with no authored outgoing route blocks assignment without spending a slot.

This deliberately small contract proves recruitment, assignment, report freshness, and forecast presentation before adding crew trust, upkeep, disagreement scenes, or additional crew members.
