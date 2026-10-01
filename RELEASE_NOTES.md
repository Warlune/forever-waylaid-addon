## 0.9.12 — Traced road navigation preview

- Added manually traced road geometry for selected streets/roads in Orgrimmar, Durotar and Tirisfal.
- Use the same road bends for walking distance, compass targets, the world map, the compass map and the native minimap.
- Advance the compass to the next bend as you approach it.
- Stop drawing unverified straight ground lines through terrain. Unmapped or off-road approaches show Direction only / Join the mapped road, with a tooltip explaining the missing path.
- Prevent unused taxi/dock nodes from creating artificial straight walking shortcuts around the traced geometry.
- Retain immediate abandonment/turn-in rerouting and the full remaining delivery itinerary from 0.9.11.

Coverage is partial. Other zones, building interiors and tower ramps are not mapped, and road traces still need in-game verification. Transport lines remain schematic; untraced walking times remain direct-distance estimates.

Reload after installing; the addon should report v0.9.12. This remains a preview release.
