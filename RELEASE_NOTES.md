# Forever Waylaid 0.10.2 preview

- Added a collapsible **Full journey** panel to the main map: numbered walk, boat/zeppelin, flight and personal-travel stages for all remaining writs. Road bends are grouped into walking stages; intermediate boat ports are retained.
- **Overview** opens the map containing the entire journey. Click a stage row or numbered marker to view that section; hover for departure, destination and writ details. Delivery markers are labeled **D1, D2…**.
- World/continent overviews show unmapped walking as dashed direction-only links. Local zone maps and the minimap continue to hide these unverified ground links. Mapped road bends and schematic transport connections remain visible.
- Added mixed-transport, multiple-writ, completed-walking, removal, overview, stage-focus and display regression tests.

Use `/reload`, open the main map, then click **Overview** in **Full journey**. Automated checks cover mixed journeys; live multi-writ travel testing is still needed. This remains a **0.x preview**, not a 1.0 release.

## Included from 0.10.1

- Fixed routes and departure markers being covered by zone-map exploration artwork and fog. The overlay now follows the map's layer ordering, above terrain and below normal POI/player icons.
- Added regression coverage for zone/city/world view changes, changing provider layers, transport markers and the route visibility setting.

Use `/reload` after updating, then check the Durotar zone map. This fix has automated coverage; live in-game visual confirmation is still needed.

## Included from 0.10.0

- Expanded selected roads and open-ground corridors from three maps to all 50 main zone/city maps in the revealed Forever atlas, including Riverglades, Zephras Isle, Mount Hyjal and Shen'dralas. Added explicit regional crossings and port approaches.
- Added **Safer: prefer roads** and **Fastest: allow shortcuts** in Route and Settings. Changes recalculate immediately and persist. The compass distinguishes open ground from roads; ETA reflects actual selected path length.
- Both modes filter faction-owned mapped branches and capitals by the actual character faction. Debug Alliance appearance does not change travel access. Existing faction-filtered boats, zeppelins and personal travel remain supported.
- Indexed nearby roads and cached destination searches for the larger network. Known disconnected roads cannot silently become a straight-line shortcut through terrain.
- Added production-data connectivity, faction, mode, distance and cache regression tests, plus generated-data validation in CI.

This remains a **0.x preview**. Map coverage is partial: no collision mesh, live enemy data, complete building interiors, lift geometry or guaranteed safe paths. Undercity currently covers only the surface approach. Some new-zone sections still lack verified connecting passages. Untraced approaches and zone handoffs remain direction-only, without a solid ground line. NPC danger warnings are deferred.

After updating, use `/reload`, then open **Route** or **Settings** to choose a routing preference. Full in-game travel testing is still required. No 1.0 release has been made.
