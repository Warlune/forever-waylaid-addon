# Forever Waylaid 0.10.3 preview

- Removed the Full journey panel and its Overview controls from the map. Restored flight-master and transport arrival/departure icons; delivery markers remain D1, D2, and so on.
- All remaining walking legs now stay visible on zone, city, world and minimap views. Mapped paths retain their bends; unmapped approaches and handoffs use dashed direction-only links.
- Future walking legs stay anchored to their transport arrival points. Before flying to Arathi, the map shows the walk from Hammerfall to the customer, independent of the player's current position.
- Boarding a flight removes the completed approach from the displayed journey while preserving the flight and all later walks. Landing restores walking guidance on the next half-second check.
- Added regression coverage for Org -> walk -> zeppelin -> walk to flight master -> flight -> walk to customer, including local-map rendering, future origins, boarding, landing and later writ removal.

Use `/reload` after updating. Automated checks pass; live multi-writ and transport testing remains necessary. Dashed lines are bearings through unverified terrain, not guaranteed traversable paths. This remains a 0.x preview; no 1.0 release has been made.
