# Forever Waylaid 0.11.2 preview

- Added **Pets** and `/fwl pets`: a larger Classic-style companion screen with a stable, memorial, tower and social panel. Click **Pet** in the compass header for the compact game beneath your route directions.
- The compass game includes care, supplies, adoption, switching pets and tower battles. **Open** switches to the larger screen; **Compass view** returns. Map and pet views share the expanding area, and scaling keeps it on screen.
- Adopt four pixel creatures (Murloc, Whelp, Wolf pup and Owl) with Common–Legendary rarity. Feed, play, rest and heal using pet tokens and care supplies; no real gold is spent.
- **Permanent death** from tower defeat or prolonged starvation. Dead pets stay in the memorial; offline and stabled pets do not lose needs. Lifespan records active online time. A replacement is free when no living pets remain.
- Added 100 turn-based tower floors, bosses every ten floors, guard, special attacks, healing and retreat. Victories earn XP and tokens; repeated floors award reduced XP.
- NPC killing blows give 3 pet XP; PvP killing blows give 10. Your character and its combat pet qualify. Only your living active companion gains XP. Combat gains are limited to 60 XP per minute and the same target once per five minutes; the level cap is 100. Hover the pet XP readout for details.
- Optional pet sharing is off by default and separate from auction-price sharing. Social is an alphabetical pet viewer with portraits and stats, without leaderboards or cheating labels. Guild/group members share automatically when opted in; **Inspect targeted player** requests a pet directly from another opted-in addon user. Both players need this version.
- Removed preview integrity flags and save checksums. Unreadable saves are still backed up for recovery, and malformed network messages are ignored.
- Added regression coverage for rarity, care, persistence, permanent death, tower progression, NPC/PvP XP, duplicate/rate limits, opt-in direct inspection, alphabetical browsing and UI construction.

Use `/reload`, then **Pets** or `/fwl pets`. Adopt a companion before earning pet XP. This remains a **0.x preview**, not 1.0. Live Forever combat-event, layout and balance testing is still needed. Existing auction and route systems are unchanged.
