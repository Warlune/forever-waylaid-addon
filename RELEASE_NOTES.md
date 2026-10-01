# Forever Waylaid 0.12.0 preview

- Redesigned the companion game around illustrated pixel scenes, with separate Horde and Alliance camps and tower arenas. The faction debug preview also switches the scene.
- Replaced the care button grid with four icon controls, hover details and supply costs. Empty supplies can be replenished with pet tokens directly from a care action; no real gold is used.
- Added animated automatic tower fights in both compass and large views: lunging sprites, hit feedback, damage numbers and health bars. Choose a floor and Fight; Pause and Retreat are always available. One floor per click, no automatic next floor. Hidden tower views pause combat; long loading gaps never fast-forward it. Defeat remains permanent death.
- Added a strict combat-XP level gate: enemy must be within five levels of your character and not gray. Unknown, stale or restricted levels are skipped. Kill XP still uses the supported standalone Forever event, not the restricted combat log.
- Kept the personal stable, memorial and opt-in pet inspection. No leaderboard.
- Tested gray/out-of-range boundaries, unknown and restricted levels, automatic boss combat, hidden/explicit pause, loading gaps, faction scenes and both UI sizes. Live client layout, animation and XP testing still needed.

After updating, use `/reload`, then **Pet** on the compass or **Pets** in the ledger. This is still a **0.x preview**, not 1.0.
