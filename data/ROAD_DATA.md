# Road data, 0.10.0 preview

`world-roads.json` contains independently traced map coordinates. Each map entry links to the revealed [Forever atlas](https://warcraftforever.games/maps) page and its client map artwork, build 1.60.1.69893, reviewed 2026-10-01. No map images or third-party routing code are distributed. The older, locally tested Orgrimmar/Durotar/Tirisfal traces remain in `RoadData.lua`.

The pass covers selected paths on 50 main zone/city maps, not all terrain. Battlegrounds and instance interiors are excluded. Regions with sparse or ambiguous artwork have less coverage. Undercity contains the surface entrance only; its floor transitions and lifts are not inferred. Hyjal and Shen'dralas have unconnected sections where passages still need verification. Public transport remains in `TransportData.lua`.

## Editing and verification

- Coordinates are `[uiMapID, xPercent, yPercent]`. Runtime world coordinates come from the client, never from the JSON atlas layout bounds. Those bounds are only research metadata from the published atlas layout.
- Junctions must share an identical coordinate. Crossing lines and nearby roads do **not** join automatically. Split a trunk at a new branch's junction.
- `road` is a traced road/street/trail. `corridor` is a reviewed approximate open-ground path; Fastest can choose it and Safer penalizes it. Both use actual path distance for ETA.
- `transition` is an explicit zone/boarding handoff whose interior geometry is untraced. It is not snapped to or drawn as a solid walking line. Do not turn a tunnel, lift or map-to-map handoff into a claimed surface road.
- `faction` is access (`Both`, `Alliance`, `Horde`), not a live enemy warning. Capital and settlement branches use the real player faction, never the debug appearance override. Outdoor throughroads can still contain hostile NPCs.
- `seams` join named regional paths. The builder rejects seams without exact endpoints in the trace set or the declared original-data junctions.
- Run `node tools/build-roads.mjs`, `pnpm test`, and `pnpm check`. Commit the generated `WorldRoadData.lua` with the data. CI checks regeneration.
- For visual review, run `node tools/preview-roads.mjs` and serve the `release` directory locally. The preview loads the original remote artwork; no image copying or redistribution is required. Wait for its “Ready” label before inspecting a newly selected map.

The tests exercise the production graph's regional connectivity, synthetic obstacles, faction restrictions, mode changes, physical ETA, bounded destination caching, nearby edge lookup, and the previously reported Durotar forecourt shortcut. These establish implementation behavior, not ground-level walkability. Map art cannot establish fences, stairs, collision, elevation or enemy safety. In-game reports are still needed to refine paths.

NPC danger warnings remain deferred. Do not label either routing mode enemy-free or promise a globally shortest walk through unknown terrain.
