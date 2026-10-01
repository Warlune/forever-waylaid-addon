## 0.9.11 — Replan remaining writ deliveries

- Immediately remove abandoned and turned-in writs from the compass and route overlay, then replan remaining turn-ins from the current position.
- Prevent delayed quest-log updates from restoring a removed writ. Reaccepting it adds it back normally.
- Remove the single-writ compass lock so it follows the planner's next customer and displays the full remaining itinerary.
- Rename the tracking button to Follow route. Clear the compass when the final writ is removed.

Route selection uses the existing travel estimates and known flight data. Personal-travel itineraries and sets above nine stops still use estimated visit ordering; map lines remain schematic.

Reload after installing; the addon should report v0.9.11. This remains a preview release.
