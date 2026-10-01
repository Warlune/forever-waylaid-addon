# Forever Waylaid — v0.13.3 preview

A Classic-style crate and writ companion for **WoW Forever beta**, targeting interface `16001` and catalogue build `1.60.1.70009`. It is not a Retail, Season of Discovery, or Classic Era catalogue. The ledger, minimap launcher, and fold-out map have been checked in the Forever `1.60.1.70124` client; live delivery and auction integration testing remains ongoing.

## Install

1. Download the `ForeverWaylaid-0.13.3.zip` asset from Releases.
2. Extract the `ForeverWaylaid` folder into your Forever client's `Interface/AddOns` folder. The resulting path must be `Interface/AddOns/ForeverWaylaid/ForeverWaylaid.toc`.
3. Start WoW, enable **Forever Waylaid**, and click the crate bubble beside the minimap or enter `/fwl`.
4. In **Settings**, use your own scans or enable optional peer sharing. Realm and faction are taken from your character automatically.

The addon has no bundled auction prices or external price service. Until you scan or receive opted-in peer prices, items remain unpriced. Existing personal scans survive upgrades. Auctionator, Auctioneer and TomTom are optional and are not bundled.

## What is in this version

- A merchant's field ledger with native Classic borders, red buttons, gold headings, item portraits, and parchment detail pages.
- Search crates and writs by name or material; filter crate tiers or owned cargo; sort by value, total cost, or name. Inspect required materials, bag counts, observed auction stock, price source/age, favor, reputation, and purchase totals.
- All 30 crates and 150 writs from the existing [Forever Waylaid Ledger](https://warlune.github.io/forever-waylaid-ledger/).
- Tooltips with configurable **cheapest fill**, **include crate purchase price**, and **all material fill costs**. Known low-stock options cannot win cheapest-fill selection. Prices are estimates: quantity is total observed stock, not a guarantee that every unit can be bought at the minimum price.
- Personal Auctionator full/incremental scans captured while this addon is enabled at recognized faction capitals. Neutral and unidentified auction houses are excluded. Older Auctionator history is not relabeled as a fresh scan.
- Auctioneer Advanced's home-faction scan image, read when the auction house closes or when you click **Read personal prices**. Versions lacking that API are ignored safely.
- Price selection per item: the newest dated observation wins; personal scans win ties. Peer prices are considered only while sharing is enabled and expire after 24 hours. Each quote keeps its original observation age and source.
- Accepted writ tracking, material progress, automatic completed-quest waypoints when exposed by the client, and manual destination pins.
- The map shows every remaining walking and transport leg, with departure/arrival icons and **D1, D2…** delivery markers. Dotted gold guides show walking, blue lines show flights and purple lines show other transport. Fainter, wider-spaced walking dots indicate unverified direction-only links. Optional TomTom waypoint support.
- A movable **Courier's Compass** that stays available when the ledger and main map close: direction arrow, distance, current writ, recipient information, and destination coordinates. Its down-arrow button unfolds a small map using the game's actual map artwork.
- Route lines on the native minimap, clipped to its circular edge and adjusted for zoom and rotating-map settings. The compass automatically guides to the next flight master, boat/zeppelin dock, personal teleport or customer. It keeps the arrival target during a booked flight and recalculates from your current position every five seconds.
- Flight points and directed routes learned by opening flight masters. Unlearned routes are not invented. Visit order is optimized for up to nine located stops, with a nearest-next estimate for larger sets. The warning icon beside Known flight points lists Eastern Kingdoms and/or Kalimdor when no recorded flight-master departure exists for that continent. Hover it for details; open a flight master's map there without buying a flight. A recorded visit does not mean every route on the continent is known.

## Waylaid companions (new preview)

Click **Pet** in the compass header for the compact game, or **Pets** in the ledger (`/fwl pets`) for the larger camp, stable and inspection screen. Horde and Alliance each have their own pixel camp and tower scenes; the Alliance debug preview switches these too. **Open** and **Compass view** move between the two sizes. The route arrow remains above the compact game, which shares the expandable area with the route map.

Collect **100 Warcraft species**, including 16 raid-boss companions. Open **Adopt** for six adoption crates costing 25–100 tokens with exact rarity odds. Select a pet to preview it; click **Equip** to make it your traveling companion. Four care icons handle feeding, play, rest and healing; hover for descriptions, supply counts and costs. If an item runs out, clicking its care icon buys one with pet tokens and uses it. No real gold is involved. A free common rescue is available when no living pets remain. Earn two tokens per five minutes online with a living equipped pet, and more from tower victories and boss encounters. The Store sells treats, toys and herbs. Eligible personal NPC kills have a 1% treat chance, capped at one per 30 minutes; first tower clears have a 10% chance. Earned dungeon adoption crates open free. See the [companion guide](ForeverWaylaid/PET_GUIDE.md) for all adoption crate odds, abilities, income and drop rules.

**Death is permanent.** Tower defeat or prolonged starvation kills the active pet, retaining its level and active lifespan in the memorial. Stabled and offline pets do not age or lose needs. The stable holds 100 living pets; the stable and memorial together hold 512 records.

The tower has 100 floors, unlocked one at a time, with a boss every ten floors. Floors 1–33 have one enemy, 34–66 have two, and 67–100 have three. Pets have HP, attack, armor and speed, with speed determining turn order. Rare and higher pets also have family abilities; Common and Uncommon pets rely on basic actions and stats. Select a floor and press the sword **Fight** icon to watch one automated battle: your companion attacks, guards heavy blows and uses eligible non-healing specials. Healing is manual: click Heal to queue a ready healing ability, otherwise one herb, otherwise a 4-token heal, for its next turn. Sprites lunge, hits show damage and health bars track both fighters. Defeated enemies fade away, then a victory panel shows XP and tokens. Completed floors are marked for the equipped pet and offer Replay; Next floor selects a new challenge without starting it. **Pause** remains available; the old Retreat button is now **Heal**. Neither herbs nor tokens are spent automatically. Combat pauses when neither tower view is visible. It never starts the next floor automatically or fast-forwards after a loading screen. A reload retreats with damage and supply costs retained. Reduced motion removes lunges and hit flashes but keeps health and damage information.

Tower victories earn pet XP; repeated floors give reduced XP. NPC killing blows give 3 pet XP, player killing blows give 10, and your combat pet's kills count. Enemies must be **within five levels of your character and not gray**. The addon observes readable target/focus/mouseover levels and uses the client's gray-difficulty range. Unknown, stale (over 60 seconds), skull and restricted levels or identities give no XP. Only a living active companion gains XP, capped at pet level 100. Combat gains are limited to 60 XP per minute and the same target once per five minutes. The supported standalone `PARTY_KILL` event is used, never the restricted combat log. Live Forever kill-XP testing remains necessary.

**Inspect pets** has a separate, default-off sharing toggle. Browse guild/group pets alphabetically, or target an opted-in addon user and click **Inspect target**. Both players need this version and sharing enabled; normal game messaging restrictions apply. Shared portraits include rarity, level, stats, active lifespan and tower progress. Records expire after about ten minutes. There are no rankings, cheating flags or obfuscated code. Unreadable saves are backed up and malformed messages ignored.

Original generated artwork, export details and prompts are documented in `ForeverWaylaid/Art/PETS.md` and `ForeverWaylaid/Art/PET_SCENES.md`. Text sizing, high contrast and faction previews apply to these panels. Gameplay balance and live layout testing remain ongoing.

## Buy or craft your cargo

The top **Goods: Buy at AH / Goods: Craft** button is independent of tooltip settings. Both modes keep the auction price of the writ or crate separate from the goods cost. Every row shows **Writ/Crate, Goods, and Total**, using full purchase value even for owned items. Missing either price always places an entry after fully priced entries, including when sorting by name. Green-to-red row colors match the website's relative cost-per-reward bands; unpriced, unverified-reward, and short-stock entries stay gray. Bands are calculated before filters, so searching does not change an item's value color.

Craft mode uses the website's 208 verified recipes and 143 raw materials. The selected bundle's required professions and highest skill ranks appear at the top, including specialization notes. The header shows the writ/crate's required item level from the catalogue; this is separate from a recipe's profession skill rank. Profession requirements compare your trained skill with the required rank: green when met, red with the missing points otherwise. Required character levels use the same colors and shortfall. These refresh on skill and level changes; unlearned professions are labeled, and unavailable readings stay unknown. High contrast keeps these comparisons in white with written status. Meeting a rank does not mean the recipe is learned. Unknown recipe ranks are explicitly labeled unverified. Each option includes a raw-material shopping list, bag counts and quantities still needed, vendor or auction sources, and an ordered crafting list with profession and skill requirements. Shared intermediate ingredients are combined before rounding to whole crafts. Variable yields use the guaranteed minimum; faction-only recipes are excluded for the other faction. Alternate root recipes are compared by stock availability and cost.

Hover only the **picture** of a required good, reagent, crafted step, writ, or crate to see the normal in-game item tooltip. The faction theme follows your character: warm Horde tones or Alliance blue with a native crest. **Settings → Debug: preview Alliance appearance** switches the colors, crest, heading, compass accent and scribe immediately. This preview changes appearance only; prices, recipes, routes and peer sharing still use your real faction. Turn it off to restore your character's theme.

Craft costs value the full batch, including materials you already own; bag counts are shown separately. Vendor values are undiscounted base prices, and recipes are not assumed to be learned. These are planning lists: the addon does not craft, buy, or consume items for you. Gathered goods keep their purchase cost instead of inventing a recipe.

## Accessibility

Open **Settings → Accessibility**, or type `/fwl accessibility`.

- **Ledger size** and **Compass size** dropdowns offer 100%, 115%, 130% and 150%, capped to fit the screen.
- **Minimum text size** offers Default, 12, 13, 14 and 16 points. Larger headings retain their size. The former Larger text preference migrates to 13 points. At 16 points, lists show five taller rows; long item names may still truncate, with full names in the detail panel.
- For **color filters**, use WoW's **Settings → Accessibility → Colors**. These game-wide filters also affect the addon. Value ratings retain written labels.
- **High contrast** uses white text on dark surfaces, removes parchment and colored value fills, and keeps the written value ratings. Icon rarity borders remain colored.
- **Reduced motion** pauses the decorative scribe animation. The directional arrow and scan progress continue to update.
- **Reset accessibility** restores these controls to their defaults without changing prices, routes or other preferences.

Settings apply immediately and are saved account-wide. These controls affect this addon's interface, not the game's global font size, native item tooltips or other addons. They do not provide screen-reader or full keyboard navigation support.

## Built-in auction scanner

The built-in **Scan** tab appears along the bottom of the auction house, beside Buy / Sell / Auctions. By default, another recognized auction addon enabled for your character hides our AH tab and unrelated item tooltips. Installed but disabled copies do not hide them. Open an auction house in your faction capital, choose **Scan**, then click **Scan auction house**. Opening the tab never starts a scan.

**Scan AH prices** also appears at the bottom of every ledger page. Auctionator and Auctioneer hide this fallback when auto-hide is enabled because they have supported personal-price integrations. TSM and other addons without an import integration leave it available. Away from the AH it is disabled with an instruction to open a faction-capital auction house. While the AH is open, a gold twenty-cell XP bar displays scan progress beside a small animated Horde or Alliance scribe. Cancel appears only during an active scan. Both scan views share one scan, progress report and cooldown. Reduced motion pauses both scribes.

An animated orc (Horde) or human (Alliance) scribe copies prices into a ledger. The original four-frame orc and human sprites are restored, with their original timing: 0.48 seconds per pose while idle and 0.22 seconds while scanning. Alliance panels use dark slate with a subdued blue-gray header gradient. Beneath the scribe, live counters show auctions read, all distinct item IDs encountered (including bid-only and unrelated items), relevant items with buyouts, prices saved, and elapsed time. The progress bar reflects records processed, not a simulated timer. Prices saved stays at zero until a complete snapshot is committed; the final report remains visible until the next scan. Keep the AH open until completion. **Cancel** or closing the AH discards any unfinished scan. The scanner requests one full snapshot, reads it in small batches, and saves the lowest unit buyout and total buyout stock for **every item with a valid buyout**, including items unrelated to Waylaid deliveries. It makes no purchases and does not run automatically.

**Comparing scan counts:** every auction row in Blizzard's returned snapshot is read, and prices are retained across the entire market. All item types counts distinct item IDs; Relevant items counts the Waylaid subset; Prices saved counts valid price observations committed by this scan. Bid-only listings do not supply buyout values. Prices are grouped by base item ID, so differently enchanted or random-suffix versions share a lowest-price estimate. This scanner does not reproduce Auctionator/Auctioneer's broader shopping, selling, or historical valuation tools. We have not measured accuracy or counts against both addons on a matching market snapshot, so no parity claim is made.

Hover an item in your bags, equipment, chat links, or other normal item tooltips to see **AH buyout (each)** when a price is available. Unrelated items show only that single line. Waylaid-related items retain their source, scan age and delivery details. Tooltip costs use white numbers with native gold, silver and copper icons. The value is per item, not a stack total. With auto-hide enabled, another supported auction addon suppresses our tooltip additions for unrelated items; writs, crates, required goods, and crafting ingredients retain Waylaid information. Installed but disabled scanners do not suppress it. Missing prices are not invented. Scan again after upgrading from 0.5.x to populate unrelated item prices; old Waylaid quotes remain available.

### Other auction addons and settings

**Auto-hide extras with another AH addon** is on by default. Turn it off to keep our manual scanner and general tooltip additions available alongside another auction addon. **AH tooltips on unrelated items** independently disables our general price tooltips; Waylaid details remain. Re-enabling auto-hide during our scan cancels that scan and preserves previous prices. Settings display the first detected auction addon.

Detection recognizes these addon identifiers, based on their maintainers' projects:

| Addon | Identifier |
| --- | --- |
| [Auctionator](https://www.curseforge.com/wow/addons/auctionator) | `Auctionator` |
| [Auctioneer](https://www.curseforge.com/wow/addons/auctioneer) | `Auc-Advanced`, `Auctioneer` |
| [TradeSkillMaster](https://www.curseforge.com/wow/addons/tradeskill-master) | `TradeSkillMaster` |
| [Aux](https://github.com/shirsig/aux-addon) | `aux-addon` |
| [AuctionLite](https://www.curseforge.com/wow/addons/auctionlite-classic) | `AuctionLite` |
| [AuctionFaster](https://github.com/kaminaris/AuctionFaster) | `AuctionFaster` |
| [AHDB](https://github.com/mooreatv/AuctionDB) | `AuctionDB` |
| [AuctionMaster](https://www.curseforge.com/wow/addons/auctionmaster) | `AuctionMaster` |
| [AuctionBuddy](https://github.com/MarcLF/AuctionBuddy) | `AuctionBuddy` |
| [Midas](https://www.curseforge.com/wow/addons/midas) | `Midas` |
| [GoldCap](https://goldcap.gg/addon) | `GoldCap` |

This is a known-addon list, not a guarantee that every fork is covered or that every project supports Forever (GoldCap currently targets Retail, for example). For an unrecognized price-tooltip addon, turn off our unrelated-item tooltips manually. Blizzard's auction UI and standalone helpers such as `TradeSkillMaster_AppHelper` do not count as competing auction addons. Detection does not import prices: third-party price imports remain limited to Auctionator and Auctioneer. No third-party addon implementation is bundled.

The v0.5.0 Horde page and animation were checked in the Forever client, including a complete manual scan of 76,812 auctions that saved 273 relevant item prices in 11 seconds. Alliance artwork selection, tab switching, cancellation, cooldowns, and disabled-scanner detection also have automated coverage; the Alliance page has not yet been checked on a live Alliance character.

The v0.5.1 Horde artwork, five-counter layout, native tab spacing, and reload were also checked in-game. The existing cooldown was preserved; the new incomplete-record behavior is covered by automated tests, not a second live scan.

Full snapshots have a 15-minute local cooldown, including a known Auctionator snapshot cooldown. Server throttling can also delay a response. Missing listings retain their previous price and original age; incomplete rows do not replace valid prices. Rows missing item IDs are re-read locally up to three times, without another server snapshot request. If any remain unidentified, the scan is rejected and previous prices are kept. Items with invalid quantities or buyouts are excluded from the update. Newer eligible peer observations can win while sharing is enabled. Personal scan prices must be enabled in Settings. Opening or closing the AH never initiates a scan.

## Auction searches and flight setup

With the auction house open, click the search text box so its cursor is blinking, then **Shift-click an item picture** in the ledger. The item name fills that focused box, with the cursor at the end. The addon does not choose Shopping, change tabs, reset filters, or submit the search. The ledger stays open. With no focused text box or with the AH closed, Shift-click quietly does nothing. Ordinary clicks still select entries, and hovering text does not show item tooltips.

Until a flight-master map has been recorded, the ledger, compass, and login message warn that flight paths are unscanned. **Talk to a flight master and open their map; no flight purchase is needed.** The initial no-flights warning clears after a successful scan, even if that character has no reachable destinations yet. The compass and warning tooltip continue listing Eastern Kingdoms and/or Kalimdor until a departure has been recorded on each continent, and explain that incomplete flight coverage may produce a slower route. Visit more flight masters to build route coverage. Turning off flight routing also hides the warning.

## Optional peer sharing

**Off by default.** Enable **Settings → Opt in: share scan prices with guild / party / raid** to send your observations and receive prices from other opted-in users. The addon periodically requests updates through your guild or current group, then responders send compact addon whispers. Both players must be online, share a guild/group, and match realm and faction. This is not a realm-wide network. No ordinary chat messages, custom channels, web service, or external helper are used.

Peer sharing and third-party scan imports remain limited to Waylaid items and ingredients; the expanded all-item price store is local. Messages contain the protocol version, realm/faction, item IDs, unit prices, quantities and original scan timestamps. WoW also supplies the sending character's name. No bags, gold balance, quests, flight paths, or other character details are shared. Only your directly observed Auctionator, Auctioneer, or built-in scans are sent; received prices are not relayed. Unknown-age and older-than-24-hour observations are not shared.

Received quotes are labeled **Peer scan (unverified)**. Payloads are size/rate limited and checked for known item IDs, scope, numeric bounds, age, and request tokens. These checks cannot prove that another user's price is truthful. Turning sharing off immediately clears pending messages, ignores incoming data and excludes cached peer prices from calculations. Your own scan data is retained.

Updates are requested roughly every five minutes, with staggered timing and limited response rates. A group change schedules discovery without rapid polling. Until a suitable peer responds, only your own available prices can be shown. Cross-client peer exchange still needs live testing with a second opted-in player.

## Delivery routes

Accept writs normally; they appear in the Writs and Route tabs. Open each flight master you want the planner to learn. The planner cannot retrieve a complete historical flight network from a newly installed addon.

Left-click the minimap crate bubble to open the ledger; right-click it to toggle the compass. Drag the bubble around the minimap edge or drag the compass by its frame. `/fwl compass` toggles the compass and `/fwl reset` restores its position. Map overlays and the compass have separate switches in Settings.

Recipient information comes from the quest's directions, a named manual pin, or an NPC learned when opening that writ's completion dialog. Learned names are reused only when the current destination matches. Unknown NPC names are shown as unknown rather than guessed.

Before a writ is ready, the game's quest pointer may lead to materials rather than the customer. Such quests remain visible with material progress; their delivery location is not guessed. Once ready, the addon uses the client-provided waypoint or quest POI. If a destination is missing, or you know it early, use:

```text
/fwl pin QUEST_ID MAP_ID X Y [NPC name]
/fwl unpin QUEST_ID
```

Coordinates use 0–100. The Route tab shows the quest ID for unresolved writs. A manually pinned writ can be included before its materials are ready, and is labeled accordingly.

### Travel options

The planner compares walking, your recorded flights on **both continents**, and Forever's public transport. The new routes include **Stormwind Harbor–Auberdine**, the one-way **Menethil → Southshore → Auberdine → Menethil** boat, and neutral **Steamwheedle Port–Powderfuse Port (Riverglades)**. Multi-stop journeys include intermediate dock time without charging another boarding wait. The compass tooltip and delivery details name ports where you should stay aboard.

Horde characters can use the **Skywatcher Plateau–Valanaar** skycutter. The **Dalaran–Valanaar** skycutter is currently offered only to Alliance Skyborne: the zone guide reports that Dalaran's guards are hostile to other characters. This is a conservative access filter, not a restriction on physically boarding the vessel. Existing faction-appropriate zeppelins, ferries and the Deeprun Tram remain available.

Personal travel is considered only when available to your character:

- **Hearthstone:** carried item, readable cooldown and a recorded home location. Bind at an inn or successfully hearth once with the addon enabled to record that position. A changed bind invalidates the old position. Until recorded, the Route details explain why Hearthstone is excluded.
- **Engineering:** carried Gadgetzan or Everlook transporter, Engineering 260 and its matching learned specialization. Equip and use it yourself when directed. Malfunctions are not predicted.
- **Mage teleport/portal:** mage characters only, a learned Classic capital spell, its required rune in your bags and a readable cooldown. Portal routes allow extra time to enter the portal. No other player's portal is assumed.

Waiting for a cooldown is included in the estimate; the planner uses ordinary travel when that is faster. For multiple writs it reserves runes and limits each Hearthstone/engineering device to one use in the itinerary. Personal travel makes visit ordering an estimate rather than an exact optimization. The route recalculates as you travel, use items, learn flights or change your accepted writs. Abandoning or turning in a writ immediately removes its compass step and map pin, even if the quest log has not refreshed yet. The remaining turn-ins are reordered from your current position. Selecting a writ no longer locks the compass to that single customer; it follows the planned multi-writ itinerary. Reaccepting a writ adds it back, and removing the final writ clears the route. It does not model warlock summons or Forever-specific teleports.

The compact compass map has **+ / −** buttons to step between world, continent and your current zone. Hover a button to see the next map. Your chosen zoom level stays in place while the route updates and follows your location when you change zones.

The map has no itinerary panel. It shows the complete remaining route directly: walk to transport, ride, walk to the next transport, fly, and walk from the arrival flight master to the customer. Only the active walking leg follows your player arrow. Future walks remain anchored to their arrival points, so inspecting Arathi before departure shows the Hammerfall-to-customer walk. Boarding a flight removes its completed walking approach; landing restores walking guidance on the next half-second check. Walking uses dotted guides with known gate/pass bends preserved. Fainter dots are unverified bearings, not guaranteed obstacle-free paths.

When a city trip cannot attach to the mapped streets, the fallback aims through an existing gate waypoint before continuing outside. This currently covers Orgrimmar, Stormwind, Ironforge and Darnassus, in either direction, with faction restrictions retained. Same-city destinations do not force a gate detour. Unknown buildings, stairs, lifts and obstacles still require the player to follow the terrain; the addon has no collision detection.

**Road navigation:** selected roads and open-ground corridors now cover all 50 main zone/city maps in the revealed Forever atlas, including Riverglades, Zephras Isle, Mount Hyjal and Shen'dralas. Coverage varies by map; it does not mean every street, building or walking connection is known. Named zone handoffs connect regional backbones, and the existing Forever boat/zeppelin network connects continents and ports.

Choose **Safer: prefer roads** or **Fastest: allow shortcuts** above the Route list or in Settings. Safer favors roads over reviewed open-ground corridors. Fastest compares their lengths without that preference. Both respect faction restrictions on mapped settlement branches, capitals and public transport. Neither tracks enemy positions yet. A road can contain hostile NPCs; “Safer” is not a guarantee of safety. The compass labels open-ground sections separately. Switching modes immediately recalculates the itinerary and saves the preference for your account.

Walking distance, compass bends and all three map overlays use the same chosen geometry. ETA uses physical length, without inflating it by the road preference. The active leg recalculates every half-second after at least three yards of movement; standing still and booked flights skip this extra work. The visible walking line starts at the live player position and drops completed segments; overlays refresh up to 20 times per second. A spatial edge index and bounded destination-search cache keep the larger network from repeating a world-wide search for every movement update. Unmapped approaches and untraced zone passages show direction-only guidance, not a solid terrain line. A known disconnected road component cannot be replaced by a fictional straight shortcut. Flight and public-transport lines remain schematic.

**Route limits:** road coverage is partial, not a complete terrain navigation system. Undercity currently has only its surface approach; interior floors, lifts and tower stairs remain untraced. Some Hyjal and Shen'dralas sections are disconnected until their passages are verified. Map artwork does not establish collision, floor height, tower stairs or safe access through buildings; traced roads still need in-game verification. Walking uses a base running-speed estimate, flights use distance, and public transport uses approximate leg/dock times plus an average boarding wait. These are not live departure schedules. Transport endpoints were checked against published Forever build 1.60.1.70124 data and revealed maps; complete journeys still need in-game testing. The retained tram approaches and mage landing points also need verification against expanded city maps. Missing flight data can make the suggested route slower. Navigation requires your clicks; the addon never moves your character, buys a flight, casts a spell or consumes an item for you.

Road sources and maintenance notes are in [data/ROAD_DATA.md](data/ROAD_DATA.md). Transport evidence, coordinate methods and remaining verification work are recorded in [data/route-research.json](data/route-research.json). Sources include [Blizzard's Forever recap](https://worldofwarcraft.blizzard.com/en-us/news/24304071/world-of-warcraft-forever-found-photos-panel-recap), [the revealed map atlas](https://warcraftforever.games/maps), [published transport data](https://forever-codex.com/zones/?zone=riverglades), and [the Zephras Isle guide](https://www.wowhead.com/forever/guide/zephras-isle-zone-overview).

Travel reference data was checked against [Nauticus route pairs](https://github.com/Road-block/Nauticus/blob/master/data.lua), [Leatrix map locations](https://github.com/WowInterfaces/leatrix-maps-wrath/blob/main/Leatrix_Maps_Icons.lua) (Classic-era routes only), and the local Forever client data for item/spell requirements. No third-party routing implementation is included.

## Development and verification

```text
pnpm install --frozen-lockfile
pnpm test
pnpm check
node tools/build-recipes.mjs
node tools/build-roads.mjs
```

The Lua suite loads the addon and renders every panel against a simulated API. It tests cost arithmetic, market isolation, scan timestamps, directed flights, unknown destinations, and route ordering against brute-force permutations. It also checks route clipping, cardinal bearings, rotating minimap coordinates, material filtering, compass independence, launcher controls, and departure/in-flight/customer guidance. Scanner tests cover manual starts, batching, cancellation, timeouts, cooldowns and visibility based on whether third-party scanners are enabled for the current character. Peer tests cover opt-in/out, scopes, freshness, malformed messages, response throttling and direct-only sharing. CI also runs the Lua suite with Lua 5.1. Crafting tests compare all 246 catalogue requests with the website engine for both factions (492 comparisons), plus nested batching, vendor fallback, shortages, and item-hover binding. Simulated checks do not replace real delivery tests.

Before calling the preview stable, verify in Forever: each tooltip toggle; Auctionator full/incremental completion; an Auctioneer home-faction scan; accepting and completing a writ; learning two flight masters; map pins at zone and continent zoom; `/reload`; and a second character/faction. Report the game build and full Lua error if one occurs.

The website's separate vendor-location catalogue remains on the website. Recursive crafting plans and material shopping lists are included in this addon.

## License and sources

Original addon code is [MIT licensed](LICENSE). Game names, data, and built-in UI assets belong to their respective owners; MIT does not relicense those assets or third-party addons. This project is not affiliated with Blizzard Entertainment.

The catalogue was imported from Warlune's MIT-licensed [forever-waylaid-ledger](https://github.com/Warlune/forever-waylaid-ledger) at `6a7913d`; its metadata records the original data sources. WoW API signatures were checked against the [Forever UI source](https://github.com/Gethe/wow-ui-source/tree/forever). Auctioneer integration calls the [scan-image API](https://gitlab.com/norganna-wow/auctioneer/auc-advanced/-/blob/master/CoreScan.lua); Auctioneer source is not included.

## Release policy

Keep releases on 0.x. Do not publish version 1.0 until the project owner explicitly authorizes it.
