## 0.9.13 — Live route-line tracking

- Anchor the current walking line to the player arrow instead of the last route calculation's starting point.
- Remove completed road segments as the player advances; preserve upcoming bends and later delivery routes.
- Increase world-map redraws to 20 per second, matching the minimap and expanded compass map.
- Advance corners only when reached or passed, reducing early corner cutting.
- Keep full itinerary calculations separate from inexpensive visual updates. Leaving the road does not draw a new shortcut through unmapped terrain.

Road coverage remains partial. Reload after installing; the addon should report v0.9.13. This remains a preview release.
