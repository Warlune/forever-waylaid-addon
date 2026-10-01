# Forever Waylaid 0.13.9 preview

- Rebuilt tower health displays with Forever's native target-frame artwork: colored nameplates, round pet portraits, level badges, green health bars, percentage and actual current HP.
- Elite enemies use the full native gold dragon around their portrait. Their health stays green, and the lower strip identifies them as ELITE. Enemy badges show the tower floor; pet badges show the pet level.
- Hover a frame for the full creature name and current / maximum HP. The pet's lower strip shows its energy; enemies do not display a fake mana bar.
- Supporting enemies get separate frames in a second row. The compass grows only in Tower view to leave room for the frames and battle animation; Camp keeps its compact layout.
- Damage and defeated-enemy visibility follow the displayed battle turns. Elite difficulty, rewards, manual healing and permanent death are unchanged.

Run `/reload` after updating. Addon tests, Lua 5.1 syntax and runtime packaging checks pass. Native artwork positioning still needs an in-game visual check. This remains a 0.x preview, not a 1.0 release.
