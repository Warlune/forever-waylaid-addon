# Forever Waylaid 0.10.4 preview

- Walking now uses dotted guides throughout world, city, zone and minimap views. Known road, gate and pass bends are retained; unverified approaches use fainter, wider-spaced dots.
- Added a coarse city-gate fallback when an endpoint cannot attach to mapped streets. Existing reviewed gate waypoints cover Orgrimmar, Stormwind, Ironforge and Darnassus, in both directions. Same-city trips do not force an exit, and faction restrictions remain enforced.
- The compass names the city-gate step when an unverified approach leads there. All future transport and arrival-to-customer legs remain visible. No map itinerary panel has been added.
- Added regression checks for gate entry/exit, same-city trips, distance estimates and faction restrictions.

Use `/reload` after updating. This is simple waypoint guidance, not collision-aware navigation: unknown walls, mountains, interiors, lifts and stairs may still obstruct faint direction-only links. Live route testing remains necessary. This remains a 0.x preview.
