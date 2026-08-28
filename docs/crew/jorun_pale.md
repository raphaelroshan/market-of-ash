# Jorun Pale — Logistics Crew Proof

Jorun is a quartermaster whose value is visible resource efficiency, not faster travel or immunity from route risk.

- Recruit in Ashgate for 18 ashmarks and one visit slot.
- Assign or refresh him for one visit slot. His plan covers only routes leaving the current settlement and is current for that day.
- A current plan reduces route provision use by one, never below one. Route days, fees, risk, event eligibility, and cargo exposure are unchanged.
- Departure forecasting and `depart_route` read the same provision-cost helper.
- Recruiting Jorun does nothing until the player assigns him; assigning him replaces Nara as the active route specialist.

This creates a direct choice between Nara's route context and Jorun's supply efficiency without adding morale, upkeep, skill trees, or passive hidden bonuses.
