# Waylaid launch readiness — November 4, 2026

Scope: small launch preparation only; no feature additions or route-engine changes.

## Verified

- Published item snapshot 1.60.1.70755, generated November 3 at 18:52 UTC: 30 crate and 150 writ item IDs, names and required levels match. All crate bundle quantities match. See catalog-audit-2026-11-04.json. Source: https://daybreakforever.com/static/forever/datamine.json
- Existing transport endpoints/topology agree with the published guide for Stormwind/Auberdine, Menethil/Southshore/Auberdine, Steamwheedle/Powderfuse, Valanaar services and the Deeprun Tram. This is a reference comparison, not live verification of coordinates, faction/race access or timing. Guide updated October 14: https://classicwowforever.com/boats-and-zeppelins/
- Independent Waylaid Lua 5.1 simulation suite passed: fresh initialization, upgrade preference/data preservation, auction-addon compatibility fixtures, tooltip choices/reminders, both-faction routing, missing flight scans, twelve-writ handling, telemetry and version checks.
- Production ZIP contains only Waylaid runtime, documentation and legacy save loader; no developer tools or companion code. Syntax and archive integrity checked.

## Outstanding before claiming live release verification

- User confirmed launch receiver War Lune, Alliance. Exact realm/ruleset identifier is still unknown. Removed retired Horde beta receiver and paused diagnostic collection/delivery; stored opt-in preferences retained.
- Fresh quest source returned HTTP 403. Writ quest IDs, objectives and reputation rewards were not freshly revalidated. Server-side crate rewards are also unverified.
- Test on the live launch client with guildmates: AH scanning plus Auctionator/TSM and bag addons; both-faction boat/tram approaches and timings; daily reset; actual diagnostic delivery once configured.
- Intermittent protected-action warning when using food remains unreproduced; not claimed fixed.
- No SavedVariables modified and no production addon installation overwritten. Remain on 0.x with route beta warnings.

## Repeat checks

Run `python tools/validate-waylaid.py` with Lua 5.1 available through lupa (the local validation runtime is supported). Run `python tools/check-package.py release/WaylaidForever-0.14.19.zip WaylaidForever` for the upload archive. Tests simulate WoW APIs and cannot establish live-client compatibility.
