# Waylaid companions — 0.13.9 preview

Open **Pets → Adopt**, choose a adoption crate, then select the new companion in the stable and click **Equip**. Browsing a pet does not change the equipped companion. The first living companion is equipped automatically. The compass and large window share the same pet and battle.

## Adoption crates and collection

All 100 species are Warcraft creatures. The 84 regular species are equally likely within every adoption crate. The remaining 16 are raid rewards. Rarity is rolled separately from species; duplicates are possible. Adoption crates use only virtual pet tokens, never real money or in-game gold.

| Adoption crate | Tokens | Common | Uncommon | Rare | Epic | Legendary |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Traveler's Adoption Crate | 25 | 90% | 10% | — | — | — |
| Scout's Adoption Crate | 40 | 75% | 20% | 5% | — | — |
| Adventurer's Adoption Crate | 55 | 50% | 35% | 10% | 5% | — |
| Veteran's Adoption Crate | 70 | 25% | 45% | 20% | 9% | 1% |
| Champion's Adoption Crate | 85 | 10% | 40% | 30% | 17% | 3% |
| Azeroth's Adoption Crate | 100 | — | 30% | 40% | 25% | 5% |

Earned adoption crates are opened free before charging tokens for that adoption crate type. If no living pets remain, **Free common rescue** supplies a common companion without spending tokens. Old pets, rarity, progress and memorial records are preserved. The stable holds 100 living pets and 512 total living/memorial records.

## Compact care and status cues

The compass camp shows Health, Food, Happy (happiness), and Energy in two rows without increasing the compass height. All meters are out of 100; hover for their full labels.

Both camp scenes show floating pixel Zs while the pet rests, a yellow stomach zigzag below 25 food, and a red anger mark below 25 happiness. These cues can appear together, have explanatory tooltips, and clear when the need is met. Reduced motion keeps the symbols stationary. They are hidden during the tower display so they do not cover battle information.

## Stats and abilities

Every pet has max HP, attack, armor (percentage damage reduction), and speed. These depend on its creature family, rarity and level; reopening the addon never rerolls them. Higher speed acts first; ties favor the pet. Common and Uncommon pets only have basic attacks, guard and supplies. Rare, Epic and Legendary pets also have their family's ability, with a three-round cooldown. Damage abilities fire automatically; healing abilities require the Heal button:

| Family | Ability | Effect |
| --- | --- | --- |
| Beast / Demon | Savage Bite / Fel Strike | 180% attack damage |
| Swift | Flurry | 165% attack damage |
| Dragon / Elemental | Dragon Breath / Elemental Nova | 90% attack damage to every enemy |
| Nature | Wild Growth | 80% attack damage, restore 18% maximum HP |
| Undead | Life Drain | 110% attack damage, heal for 60% of the hit |
| Guardian / Mechanical | Iron Hide / Emergency Plating | Strike, reduce subsequent hits that round by 55% |

## Tower and income

Each pet starts with only floor 1 open. Defeat that floor to unlock the next, up to 100. Floors 1–33 have one opponent, 34–66 have two, and 67–100 have three. Every tenth floor (10 through 100) has an elite leader: its encounter gets 55% more health and 25% more attack than the ordinary formula for that floor. The leader has 3 extra armor and a 185% heavy attack every third round (ordinary enemies use 160%). Later elite floors include one or two weaker supporting enemies. Health and attack are split across the group rather than multiplied by its size, with the elite receiving the largest share. The elite is larger and has a gold dragon around its portrait and an ELITE label. Tower unit frames use the client's target-frame artwork, green health bars, percentage and current HP, round portraits and level badges (tower floor for enemies). Hover for full names and current / maximum HP. Each living actor gets a speed-ordered turn. The battle display animates those turns in sequence.

The auto strategy guards each third round's heavy attacks, uses an available non-healing special, otherwise strikes. It never automatically heals or spends healing supplies/tokens. Click **Heal** to use a ready healing ability first, otherwise one healing herb, otherwise 4 tokens. The request replaces the next pet action, and herbs/token healing restores 40% maximum HP. Faster enemies can act first. Only one heal can be queued; supplies/tokens are consumed when the pet acts, not when queued. **Pause** lets you plan; Retreat has been removed from the controls. The next floor never starts automatically. Hidden tower views pause combat; reloading retreats. **Defeat and starvation are permanent death.** Stabled and offline pets do not decay.

- Starting wallet: 25 tokens (existing wallets unchanged).
- Time online: 2 tokens per five minutes with a living equipped pet. Empty stables earn nothing; the free common rescue remains available. Loading-screen gaps are capped, and offline time earns nothing.
- First floor clear: `5 + floor(floor number / 10)` tokens and `30 + 6 × floor number` XP.
- Repeated floor: 1 token and 40% of the first-clear XP.
- Store prices: treats 2 tokens; toys 3; healing herbs 4. Purchases add stock without using it. Prepare between floors rather than entering injured. The store is available in the compass and large pet view.
- Player killing blows: 3 XP for NPCs, 10 for players. Targets must be non-gray and within five character levels. Existing observation, repeat-target and rate limits still apply.

Automated preview checks cover all 500 species/rarity combinations at level 100 on floor 100, plus a common Murloc's full first-clear climb with full care between floors and simulated explicit Heal requests. The deterministic final-floor checks used at most eleven herbs per final-floor encounter. These checks establish viability, not a guarantee of survival or final tuning.

## Dungeon and raid rewards

These are **virtual addon rewards**, separate from WoW loot. A matching `ENCOUNTER_START` and successful `ENCOUNTER_END` in a dungeon or raid are required. Wipes, outdoor elites, unpaired events and changing instances do not count.

- Dungeon boss: 3 tokens, with a 20% chance for a free adoption crate. That adoption crate is Scout's (60%), Adventurer's (30%), or Veteran's (10%). One reward roll per boss per 24 hours.
- Raid boss: 10 tokens, with a 5% chance for that boss's **Epic** companion when it is in the supported roster. One reward roll per boss per seven days.
- The local reward cooldown is independent of the game's raid reset. Successful and failed rolls both consume it. It survives reload.
- Boss companions wait in **Adopt → Claim raid companion** until claimed, including if the stable was full or a tower fight was active. Hover the button for the next waiting boss's name.

Supported raid companions: Ragnaros, Onyxia, Nefarian, C'Thun, Kel'Thuzad, Hakkar, Ossirian the Unscarred, Lucifron, Magmadar, Gehennas, Garr, Baron Geddon, Shazzrah, Sulfuron Harbinger, Golemagg the Incinerator, and Majordomo Executus. These use English encounter names. Unknown encounters can earn tokens but never award a guessed boss pet. Forever must emit those encounter events; live dungeon/raid verification is still needed.

## Sharing

Opt-in inspection shows the equipped pet's species, rarity, level, stats, lifespan and tower progress. Both players need 0.13.0 or later. This is a personal collection game: no leaderboard, anti-cheat claims or real-game combat automation.

## Victory and completed floors

Defeated enemies fade out after their lethal hit (or disappear immediately with Reduced motion). Once all enemies are down, both tower views show a victory panel with the cleared floor and earned XP/tokens. **Next floor** selects the next challenge without starting combat. Floor 100 instead shows **Tower conquered** and a **Done** button. Cleared floors are marked **Completed** for the equipped pet, even after reloading; their Fight button becomes **Replay**. Replaying resets the arena and keeps the reduced repeat rewards.

## Rare treats and needs

Treats primarily come from the token store. First-time tower clears have a 10% chance for one treat; replaying a completed floor has no treat roll. Eligible personal NPC killing blows have a 1% chance for one treat, capped at one success per 30 minutes with a saved cooldown. PvP, combat-pet killing blows, gray/out-of-range or unreadable targets do not drop treats. A living equipped pet is required; level-100 pets can still get treats. Existing repeat-target checks apply. These are virtual companion supplies, not WoW loot.

Each tower hit lowers happiness by `min(5, damage / maximum HP * 20)` points; winning still restores 8 happiness. The limits remain 0–100.

- Hunger below 10, including zero, drains health by about one point per minute outside battle and can eventually cause permanent death. Feed to stop starvation.
- Energy at zero prevents another battle until it recovers to 15. It recovers naturally, faster while resting; zero energy does not kill a pet or interrupt a current fight.
- Happiness at zero currently has no combat-stat or death penalty. Play with a toy to restore it.
- Stabled and offline pets do not lose needs.
