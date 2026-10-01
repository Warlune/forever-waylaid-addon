# Forever Waylaid — v0.1.0 preview

A Classic-style crate and writ companion for **WoW Forever beta**, initially targeting interface `16001` and catalogue build `1.60.1.70009`. It is not a Retail, Season of Discovery, or Classic Era catalogue. This first version needs testing in the actual Forever client; automated checks use a simulated WoW API.

## Install

1. Download the `ForeverWaylaid-0.1.0.zip` asset from Releases.
2. Extract the `ForeverWaylaid` folder into your Forever client's `Interface/AddOns` folder. The resulting path must be `Interface/AddOns/ForeverWaylaid/ForeverWaylaid.toc`.
3. Start WoW, enable **Forever Waylaid**, and enter `/fwl`.
4. In **Settings**, choose PvP, Normal, or RP to match your realm. The faction comes from your character. No market is guessed automatically.

The folder includes an AHledger snapshot. Its actual observation date appears in the window. Empty RP markets remain unpriced until a scan is available. Auctionator, Auctioneer and TomTom are optional and are not bundled.

## What is in this version

- Native Blizzard dialog borders, buttons, fonts, gold text, and tooltips.
- All 30 crates and 150 writs from the existing [Forever Waylaid Ledger](https://warlune.github.io/forever-waylaid-ledger/).
- Tooltips with configurable **cheapest fill**, **include crate purchase price**, and **all material fill costs**. Known low-stock options cannot win cheapest-fill selection. Prices are estimates: quantity is total observed stock, not a guarantee that every unit can be bought at the minimum price.
- Personal Auctionator full/incremental scans captured while this addon is enabled at recognized faction capitals. Neutral and unidentified auction houses are excluded. Older Auctionator history is not relabeled as a fresh scan.
- Auctioneer Advanced's home-faction scan image, read when the auction house closes or when you click **Read personal prices**. Versions lacking that API are ignored safely.
- Price selection per item: the newest dated observation wins; AHledger wins ties. Missing AHledger items can use personal prices. Newer AHledger observations supersede older personal prices after the next import and `/reload`.
- Accepted writ tracking, material progress, automatic completed-quest waypoints when exposed by the client, and manual destination pins.
- Numbered deliveries on Blizzard's world map: gold travel legs, blue flight legs. Click a route row to navigate. Optional TomTom waypoint support.
- Flight points and directed routes learned by opening flight masters. Unlearned routes are not invented. Visit order is optimized for up to nine located stops, with a nearest-next estimate for larger sets.

## AHledger updates

WoW addons cannot fetch web APIs directly. The companion tool runs **outside WoW** using Node.js 22 or newer. It downloads public prices only: no token, account details, or scan upload is needed.

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

Before a writ is ready, the game's quest pointer may lead to materials rather than the customer. Such quests remain visible with material progress; their delivery location is not guessed. Once ready, the addon uses the client-provided waypoint or quest POI. If a destination is missing, or you know it early, use:

```text
/fwl pin QUEST_ID MAP_ID X Y
/fwl unpin QUEST_ID
```

Coordinates use 0–100. The Route tab shows the quest ID for unresolved writs. A manually pinned writ can be included before its materials are ready, and is labeled accordingly.

**Route limits:** lines are travel estimates, not terrain-aware roads or turn-by-turn instructions. Mountains, water, hazards, mounts, boats, zeppelins, portals, and hearthstones are not modeled. Cross-continent deliveries stay unresolved until you travel there. Flight estimates use distance, not measured flight durations. The exact visit ordering is exact only within this estimated travel model. Navigation requires your clicks; the addon never moves your character or chooses a flight for you.

## Development and verification

```text
pnpm install --frozen-lockfile
pnpm test
pnpm check
node tools/build-catalog.mjs
```

The Lua suite loads the addon and renders every panel against a simulated API. It tests cost arithmetic, market isolation, scan timestamps, directed flights, unknown destinations, and route ordering against brute-force permutations. Node tests cover AHledger parsing, cache limits, and failed/older download retention. CI also runs the Lua suite with Lua 5.1. These checks do not establish in-game compatibility.

Before calling the preview stable, verify in Forever: each tooltip toggle; Auctionator full/incremental completion; an Auctioneer home-faction scan; accepting and completing a writ; learning two flight masters; map pins at zone and continent zoom; `/reload`; and a second character/faction. Report the game build and full Lua error if one occurs.

The website's crafting calculator and vendor shopping catalogue remain on the website; this initial addon quotes purchases of requested items, not recursive crafting recipes.

## License and sources

Original addon code is [MIT licensed](LICENSE). Price data is credited to [AHledger](https://ahledger.com/) and follows its [developer terms](https://ahledger.com/developers). Game names, data, and built-in UI assets belong to their respective owners; MIT does not relicense those assets or third-party addons. This project is not affiliated with Blizzard Entertainment.

The catalogue was imported from Warlune's MIT-licensed [forever-waylaid-ledger](https://github.com/Warlune/forever-waylaid-ledger) at `6a7913d`; its metadata records the original data sources. WoW API signatures were checked against the [Forever UI source](https://github.com/Gethe/wow-ui-source/tree/forever). Auctioneer integration calls the [scan-image API](https://gitlab.com/norganna-wow/auctioneer/auc-advanced/-/blob/master/CoreScan.lua); Auctioneer source is not included.
