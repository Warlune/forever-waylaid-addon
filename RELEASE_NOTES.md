# Forever Waylaid 0.10.0 preview

- Expanded selected roads and open-ground corridors from three maps to all 50 main zone/city maps in the revealed Forever atlas, including Riverglades, Zephras Isle, Mount Hyjal and Shen'dralas. Added explicit regional crossings and port approaches.
- Added **Safer: prefer roads** and **Fastest: allow shortcuts** in Route and Settings. Changes recalculate immediately and persist. The compass distinguishes open ground from roads; ETA reflects actual selected path length.
- Both modes filter faction-owned mapped branches and capitals by the actual character faction. Debug Alliance appearance does not change travel access. Existing faction-filtered boats, zeppelins and personal travel remain supported.
- Indexed nearby roads and cached destination searches for the larger network. Known disconnected roads cannot silently become a straight-line shortcut through terrain.
- Added production-data connectivity, faction, mode, distance and cache regression tests, plus generated-data validation in CI.

This remains a **0.x preview**. Map coverage is partial: no collision mesh, live enemy data, complete building interiors, lift geometry or guaranteed safe paths. Undercity currently covers only the surface approach. Some new-zone sections still lack verified connecting passages. Untraced approaches and zone handoffs remain direction-only, without a solid ground line. NPC danger warnings are deferred.

After updating, use `/reload`, then open **Route** or **Settings** to choose a routing preference. Full in-game travel testing is still required. No 1.0 release has been made.
