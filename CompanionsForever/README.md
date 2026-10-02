# Companions Forever — v0.1.1 beta

A standalone pixel companion game for WoW Forever. Adopt Warcraft creatures, keep them fed and happy, and climb a 100-floor tower together. No other addon is required.

## Install and open

1. Extract **both** folders in `CompanionsForever-0.1.1.zip` into your Forever client's `Interface/AddOns` directory. `CompanionsForever` is the game. `ForeverCompanions` is its tiny saved-data compatibility loader; allow it to replace the old TOC. The main file is `Interface/AddOns/CompanionsForever/CompanionsForever.toc`.
2. Restart the game client so it discovers the new addon, then enable **Companions Forever** and its **saved-data compatibility** entry.
3. Click its paw icon beside the minimap or use `/cf` (also `/companions`). Right-click the icon or use `/cf small` for a movable compact window.
4. Use **Settings** in the large window or `/cf settings` for separate window sizes, minimum text size, high contrast, reduced motion and Alliance artwork preview. `/cf reset` restores the compact window's position.

## Bring your existing pets

If you already played the standalone **Forever Companions 0.1.0**, the included compatibility loader reads that save. **Companions Forever** copies it once into `CompanionsForeverDB` and `CompanionsForeverCharDB`, including your pet collection, equipped pet, health, needs, age, memorials, tokens, supplies, tower progress and settings. This newer standalone save takes priority over older pets bundled with Waylaid. Original saves are never edited or removed by the importer.

If your pets are still in the combined Waylaid addon, also install **Waylaid Forever 0.14.1** with its included compatibility folder. Enable the two main addons and their saved-data compatibility entries once on each character. The pet game imports the old collection if it does not have a current stable. New saves take priority on every subsequent login, so progress cannot be rolled back by an older copy.

An interrupted tower battle ends as a retreat, as on a normal reload; damage remains. If you already started a new stable before enabling the old save, it will not be replaced automatically. **Import old Waylaid pets** in Settings asks for confirmation and backs up the current stable to `beforeLegacyImport` before copying it. Unreadable pet saves remain available in `petQuarantine`.

Keep compatibility entries enabled until you have logged into every character you want to migrate. They can then be disabled. They contain no pet or delivery gameplay. Do not keep old versions of their TOCs: the renamed addons refuse to start alongside an old running engine. WoW only loads a disabled addon's data when its compatibility entry is enabled.

`/cf` is the new short command. `/fcp` and `/companions` remain available for existing macros. Appearance settings are now independent from Waylaid.

## Playing

Collect **100 Warcraft species**, including 16 raid-boss companions. Open **Adopt** for six adoption crates costing 25–100 tokens with exact rarity odds. Select a pet to preview it; click **Equip** to make it your traveling companion. Four care icons handle feeding, play, rest and healing; hover for descriptions, supply counts and costs. If an item runs out, clicking its care icon buys one with pet tokens and uses it. No real gold is involved. A free common rescue is available when no living pets remain. Earn two tokens per five minutes online with a living equipped pet, and more from tower victories and boss encounters. The Store sells treats, toys and herbs. Eligible personal NPC kills have a 1% treat chance, capped at one per 30 minutes; first tower clears have a 10% chance. Earned dungeon adoption crates open free. See the [companion guide](PET_GUIDE.md) for all adoption crate odds, abilities, income and drop rules.

**Death is permanent.** Tower defeat or prolonged starvation kills the active pet, retaining its level and active lifespan in the memorial. Stabled and offline pets do not age or lose needs. The stable holds 100 living pets; the stable and memorial together hold 512 records.

The tower has 100 floors, unlocked one at a time, with a boss every ten floors. Floors 1–33 have one enemy, 34–66 have two, and 67–100 have three. Pets have HP, attack, armor and speed, with speed determining turn order. Rare and higher pets also have family abilities; Common and Uncommon pets rely on basic actions and stats. Select a floor and press the sword **Fight** icon to watch one automated battle: your companion attacks, guards heavy blows and uses eligible non-healing specials. Healing is manual: click Heal to queue a ready healing ability, otherwise one herb, otherwise a 4-token heal, for its next turn. Sprites lunge, hits show damage and health bars track both fighters. Defeated enemies fade away, then a victory panel shows XP and tokens. Completed floors are marked for the equipped pet and offer Replay; Next floor selects a new challenge without starting it. **Pause** remains available; the old Retreat button is now **Heal**. Neither herbs nor tokens are spent automatically. Combat pauses when neither tower view is visible. It never starts the next floor automatically or fast-forwards after a loading screen. A reload retreats with damage and supply costs retained. Reduced motion removes lunges and hit flashes but keeps health and damage information.

Tower victories earn pet XP; repeated floors give reduced XP. NPC killing blows give 3 pet XP, player killing blows give 10, and your combat pet's kills count. Enemies must be **within five levels of your character and not gray**. The addon observes readable target/focus/mouseover levels and uses the client's gray-difficulty range. Unknown, stale (over 60 seconds), skull and restricted levels or identities give no XP. Only a living active companion gains XP, capped at pet level 100. Combat gains are limited to 60 XP per minute and the same target once per five minutes. The supported standalone `PARTY_KILL` event is used, never the restricted combat log. Live Forever kill-XP testing remains necessary.

**Inspect pets** has a separate, default-off sharing toggle. Browse guild/group pets alphabetically, or target an opted-in addon user and click **Inspect target**. Both players need this version and sharing enabled; normal game messaging restrictions apply. Shared portraits include rarity, level, stats, active lifespan and tower progress. Records expire after about ten minutes. There are no rankings, cheating flags or obfuscated code. Unreadable saves are backed up and malformed messages ignored.

Original generated artwork, export details and prompts are documented in `Art/PETS.md` and `Art/PET_SCENES.md`. Text sizing, high contrast and faction previews apply to these panels. Gameplay balance and live layout testing remain ongoing.


## Open independently

Use `/cf`, `/cf small`, or this addon's minimap button. Waylaid Forever no longer has pet buttons or commands. Both addons can still run side by side, and legacy save import remains available.

## Beta testing

This is still a beta. Test importing your current stable, care actions, store and adoption panels, combat in both window sizes, and pet inspection with a guildmate. Balance has not changed as part of this split. Pet death remains permanent. There is no leaderboard, real-money currency or in-game gold cost.
