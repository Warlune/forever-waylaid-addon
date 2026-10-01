# Forever Waylaid 0.13.0 preview

- Added 100 Warcraft creature designs, including 16 supported raid bosses, with transparent pixel sprites.
- Added an Adopt screen with six 25–100 token packs, visible exact odds, free earned packs and a common rescue when no pets survive.
- Stable clicks now preview; Equip explicitly selects the traveling pet. HP, attack, armor, speed and rare-or-higher family abilities are visible.
- Tower floors unlock sequentially. Higher floors have up to three opponents, with speed-ordered turns animated in the compass and large arena.
- Retuned XP, token income, family stats and encounter budgets. Permanent death remains; prepare between floors and retreat when needed.
- Added virtual dungeon pack rewards and supported raid-boss companion rewards from successful paired encounter events, with persistent reward cooldowns.
- Preserved existing companions and memorials. Expanded stable limits and updated opt-in inspection for the new roster.

Run `/reload`, then `/fwl pets` and choose Adopt. Selecting a pet previews it; Equip makes it the active companion. Boss drops depend on Forever emitting encounter events and still need live dungeon/raid testing. See `ForeverWaylaid/PET_GUIDE.md` for odds, costs and limitations.

Validation: Lua 5.1 syntax, addon regression suite, all six pack boundaries, 500 level-100 species/rarity final-floor matchups, a 100-floor common-pet climb with care, multi-enemy turn ordering, boss event/cooldown tests, and UI smoke checks. Live animation/layout and reward pacing still need player testing. This remains a preview, not a 1.0 release.
