# Forever Waylaid — v0.3.4 preview

A Classic-style crate and writ companion for **WoW Forever beta**, targeting interface `16001` and catalogue build `1.60.1.70009`. It is not a Retail, Season of Discovery, or Classic Era catalogue. The ledger, minimap launcher, and fold-out map have been checked in the Forever `1.60.1.70124` client; live delivery and auction integration testing remains ongoing.

## Install

1. Download the `ForeverWaylaid-0.3.4.zip` asset from Releases.
2. Extract the `ForeverWaylaid` folder into your Forever client's `Interface/AddOns` folder. The resulting path must be `Interface/AddOns/ForeverWaylaid/ForeverWaylaid.toc`.
3. Start WoW, enable **Forever Waylaid**, and click the crate bubble beside the minimap or enter `/fwl`.
4. In **Settings**, choose PvP, Normal, or RP to match your realm. The faction comes from your character. No market is guessed automatically.

The folder includes an AHledger snapshot. Its actual observation date appears in the window. Empty RP markets remain unpriced until a scan is available. Auctionator, Auctioneer and TomTom are optional and are not bundled.

## What is in this version

- A merchant's field ledger with native Classic borders, red buttons, gold headings, item portraits, and parchment detail pages.
- Search crates and writs by name or material; filter crate tiers or owned cargo; sort by value, total cost, or name. Inspect required materials, bag counts, observed auction stock, price source/age, favor, reputation, and purchase totals.
- All 30 crates and 150 writs from the existing [Forever Waylaid Ledger](https://warlune.github.io/forever-waylaid-ledger/).
- Tooltips with configurable **cheapest fill**, **include crate purchase price**, and **all material fill costs**. Known low-stock options cannot win cheapest-fill selection. Prices are estimates: quantity is total observed stock, not a guarantee that every unit can be bought at the minimum price.
- Personal Auctionator full/incremental scans captured while this addon is enabled at recognized faction capitals. Neutral and unidentified auction houses are excluded. Older Auctionator history is not relabeled as a fresh scan.
- Auctioneer Advanced's home-faction scan image, read when the auction house closes or when you click **Read personal prices**. Versions lacking that API are ignored safely.
- Price selection per item: the newest dated observation wins; AHledger wins ties. Missing AHledger items can use personal prices. Newer AHledger observations supersede older personal prices after the next import and `/reload`.
- Accepted writ tracking, material progress, automatic completed-quest waypoints when exposed by the client, and manual destination pins.
- Numbered deliveries and flight-master pins on Blizzard's world map: gold travel legs and blue flight legs. Select a delivery and click **Track delivery** or **Show on map**. Optional TomTom waypoint support.
- A movable **Courier's Compass** that stays available when the ledger and main map close: direction arrow, distance, current writ, recipient information, and destination coordinates. Its down-arrow button unfolds a small map using the game's actual map artwork.
- Route lines on the native minimap, clipped to its circular edge and adjusted for zoom and rotating-map settings. The compass guides to a flight master, keeps the arrival target during flight, then points toward the customer.
- Flight points and directed routes learned by opening flight masters. Unlearned routes are not invented. Visit order is optimized for up to nine located stops, with a nearest-next estimate for larger sets.

## Buy or craft your cargo

The top **Goods: Buy at AH / Goods: Craft** button is independent of tooltip settings. Both modes keep the auction price of the writ or crate separate from the goods cost. Every row shows **Writ/Crate, Goods, and Total**, using full purchase value even for owned items. Missing either price always places an entry after fully priced entries, including when sorting by name. Green-to-red row colors match the website's relative cost-per-reward bands; unpriced, unverified-reward, and short-stock entries stay gray. Bands are calculated before filters, so searching does not change an item's value color.

Craft mode uses the website's 208 verified recipes and 143 raw materials. The selected bundle's required professions and highest skill ranks appear at the top, including specialization notes. The header shows the writ/crate's required item level from the catalogue; this is separate from a recipe's profession skill rank. Unknown recipe ranks are explicitly labeled unverified. Each option includes a raw-material shopping list, bag counts and quantities still needed, vendor or auction sources, and an ordered crafting list with profession and skill requirements. Shared intermediate ingredients are combined before rounding to whole crafts. Variable yields use the guaranteed minimum; faction-only recipes are excluded for the other faction. Alternate root recipes are compared by stock availability and cost.

Hover only the **picture** of a required good, reagent, crafted step, writ, or crate to see the normal in-game item tooltip. The faction theme follows your character: warm Horde tones or Alliance blue with a native crest.

Craft costs value the full batch, including materials you already own; bag counts are shown separately. Vendor values are undiscounted base prices, and recipes are not assumed to be learned. These are planning lists: the addon does not craft, buy, or consume items for you. Gathered goods keep their purchase cost instead of inventing a recipe.

## Auction searches and flight setup

With the auction house open, click the search text box so its cursor is blinking, then **Shift-click an item picture** in the ledger. The item name fills that focused box, with the cursor at the end. The addon does not choose Shopping, change tabs, reset filters, or submit the search. The ledger stays open. With no focused text box or with the AH closed, Shift-click quietly does nothing. Ordinary clicks still select entries, and hovering text does not show item tooltips.

Until a flight-master map has been recorded, the ledger, compass, and login message warn that flight paths are unscanned. **Talk to a flight master and open their map; no flight purchase is needed.** The warning clears after a successful scan, even if that character has no reachable destinations yet. Visit more flight masters to build route coverage. Turning off flight routing also hides the warning.

## AHledger updates

**The helper is optional.** Use bundled AHledger prices and your own supported scans without running anything else. WoW addons cannot fetch web APIs directly, so automatic web refreshes require the companion tool **outside WoW**, using Node.js 22 or newer. It downloads public prices only: no token, account details, or scan upload is needed.

From this repository, run:

```powershell
node tools/sync-prices.mjs --addon-dir "C:\path\to\World of Warcraft\_classic_beta_\Interface\AddOns\ForeverWaylaid"
```

Use your actual client path. Run `/reload` in game afterward. Optional flags:

```powershell
# Fetch one market only
node tools/sync-prices.mjs --addon-dir "C:\path\to\AddOns\ForeverWaylaid" --market forever.pvp.horde.us
# Keep the helper running; check at most every 30 minutes
node tools/sync-prices.mjs --addon-dir "C:\path\to\AddOns\ForeverWaylaid" --watch
```

The updater honors longer server cache lifetimes, validates market and timestamp, retains previous prices on failures, and writes `Prices.lua` atomically. It never edits the game's SavedVariables. Running without `--addon-dir` updates the repository's addon folder. No scheduled task is installed.

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

**Route limits:** lines are travel estimates, not terrain-aware roads or turn-by-turn instructions. Mountains, water, hazards, mounts, boats, zeppelins, portals, and hearthstones are not modeled. Cross-continent deliveries stay unresolved until you travel there. Flight estimates use distance, not measured flight durations. The exact visit ordering is exact only within this estimated travel model. Navigation requires your clicks; the addon never moves your character or chooses a flight for you.

## Development and verification

```text
pnpm install --frozen-lockfile
pnpm test
pnpm check
node tools/build-recipes.mjs
```

The Lua suite loads the addon and renders every panel against a simulated API. It tests cost arithmetic, market isolation, scan timestamps, directed flights, unknown destinations, and route ordering against brute-force permutations. It also checks route clipping, cardinal bearings, rotating minimap coordinates, material filtering, compass independence, launcher controls, and departure/in-flight/customer guidance. Node tests cover AHledger parsing, cache limits, and failed/older download retention. CI also runs the Lua suite with Lua 5.1. Crafting tests compare all 246 catalogue requests with the website engine for both factions (492 comparisons), plus nested batching, vendor fallback, shortages, and item-hover binding. Simulated checks do not replace real delivery tests.

Before calling the preview stable, verify in Forever: each tooltip toggle; Auctionator full/incremental completion; an Auctioneer home-faction scan; accepting and completing a writ; learning two flight masters; map pins at zone and continent zoom; `/reload`; and a second character/faction. Report the game build and full Lua error if one occurs.

The website's separate vendor-location catalogue remains on the website. Recursive crafting plans and material shopping lists are included in this addon.

## License and sources

Original addon code is [MIT licensed](LICENSE). Price data is credited to [AHledger](https://ahledger.com/) and follows its [developer terms](https://ahledger.com/developers). Game names, data, and built-in UI assets belong to their respective owners; MIT does not relicense those assets or third-party addons. This project is not affiliated with Blizzard Entertainment.

The catalogue was imported from Warlune's MIT-licensed [forever-waylaid-ledger](https://github.com/Warlune/forever-waylaid-ledger) at `6a7913d`; its metadata records the original data sources. WoW API signatures were checked against the [Forever UI source](https://github.com/Gethe/wow-ui-source/tree/forever). Auctioneer integration calls the [scan-image API](https://gitlab.com/norganna-wow/auctioneer/auc-advanced/-/blob/master/CoreScan.lua); Auctioneer source is not included.
