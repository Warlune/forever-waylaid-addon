# Forever Waylaid 0.13.1 preview

- Added a victory panel to both tower views, showing the completed floor and earned XP/tokens after the final hit and enemy fade.
- Defeated enemies fade out individually and remain gone. Reduced motion hides them immediately after their lethal hit.
- Marked cleared floors Completed for the equipped pet, including after reload. Their Fight button now reads Replay.
- Next floor selects the next challenge without starting combat. Floor 100 shows Tower conquered and Done.
- Replay resets enemy visibility; retreat never shows victory. Rewards are granted once by combat, never by the victory display.

Installed users: run `/reload`.

Validation: Lua 5.1 syntax and full regression suite, including timed fades, reduced motion, both victory views, persistent completion, replay reset and no duplicate rewards or automatic next battle. This remains a preview release.
