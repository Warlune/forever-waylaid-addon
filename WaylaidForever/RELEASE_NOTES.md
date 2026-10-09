# Waylaid Forever 0.14.17 — beta

- Added an Item tooltips dropdown: Show both, Only crates / writs, Only materials, or None. Hide duplicate material prices when another auction addon already shows them.
- None hides all Waylaid tooltip additions without disabling ledger prices or scanning. Unrelated-item AH prices require Show both and the existing checkbox; auction-addon auto-hide still applies.
- Existing users default to Show both, preserving their previous tooltip preferences. Settings, saved prices and window positions are preserved.

## Previous update: Waylaid Forever 0.14.16 — beta

- Skip route rendering and position queries while the minimap is hidden or route drawing is disabled; release old route references and reuse zoom-radius tables.
- Avoid repeated tooltip price lookups and duplicate hook registration. Tooltip bookkeeping now uses private weak-key tables instead of fields on shared tooltip frames.
- Fixed a potential nil-value error when reading profession requirements during an in-progress skill scan.
- Simulated regression checks passed. Live memory/FPS improvement is not measured; the intermittent food-item blocked-action issue remains unconfirmed. Saved settings, prices and positions are preserved.

## Previous update: Waylaid Forever 0.14.15 — beta

- Opt-in diagnostics now identifies the blocked function and combat-lockdown state instead of reporting only “blocked.” Function arguments and raw error text are excluded.
- Enabled diagnostics starts before login UI setup. Clarified that errors from before opt-in cannot be recovered.
- Improves investigation of an intermittent blocked action when using food from a bag; the original cause has not yet been reproduced or confirmed fixed.

## Previous update: Waylaid Forever 0.14.14 — beta

- Neatened the compass header: Hide has more room for its label, an inset right-edge anchor, and a matching-height header background. Shortened the heading to COMPASS • BETA and spaced route text below it.
- Compass position, visibility and map expansion remain saved as before.

## Previous update: Waylaid Forever 0.14.13 — beta

- Replaced the combined stock/value warning with specific labels: Not enough AH stock, Missing prices, Reward unverified, or Stock unverified when availability cannot be established.
- Short crafting materials now show the scanned AH quantity against the full craft requirement in the detail panel. Costs remain full-purchase estimates; stock warnings do not change sorting or saved prices.
- Checked the published 1.60.1.70205 item data and current writ quest list on October 3. All 30 crates and 150 writs are already included. No item/quest IDs, names, required character levels, crate bundles, or listed writ reputation rewards differed.
- Published data can lag the live server. Writ objective quantities and server-side crate rewards were not revalidated. The audit is recorded in data/catalog-audit-2026-10-03.json in the repository; research files are not shipped with the addon.

## Previous update: Waylaid Forever 0.14.12 — beta

- Evenly spaced Crates, Writs, Route, Settings and Travel compass across the full header width, with matching button sizes and alignment to the filter row.
- Existing WoW styling, accessibility options and saved data are unchanged.

## Previous update: Waylaid Forever 0.14.11 — beta

- Removed the Show: All / Available / My cargo control and its filtering rules.
- Moved Goods: Buy at AH / Craft into the filter row beside Sort on Crates and Writs.
- Hide completed today remains the single completion filter. Writ states, value sorting and saved settings are unchanged.

## Previous update: Waylaid Forever 0.14.10 — beta

- Writ names now show one of three states: In Bag, On Quest, or Completed today. Ready-to-deliver writs use On Quest; the detail panel still shows delivery readiness.
- Status stays beside the name, with space reserved so longer names cannot hide the marker. Value ratings remain on the reward line and sorting is unchanged.
- Added a saved Hide completed today checkbox beside Sort. It hides only completed writs and leaves In Bag/On Quest visible. Clear filters restores all entries.
- Added a Hide button to the compass header. Reopen it through Travel compass in the ledger or by right-clicking the minimap button. Position and map expansion are preserved.

Simulated checks cover item/quest/completion precedence, daily reset, sorting, filtering, saved preferences and compass hide/reopen. Existing user data is preserved; no new scan or reset is required.

## Previous update: Waylaid Forever 0.14.9 — beta

- The Writs list follows the selected sort. Accepted writs no longer jump above better-value options; the Route tab keeps your active deliveries together.
- Writ rows and item tooltips show Accepted, Ready to deliver, or Completed today. Completed rows use a neutral background and remain in their price-sorted position.
- Abandoning a writ removes its accepted mark. Accepting it again restores the mark. Only turning it in counts as a daily completion.
- Completion is per character and writ type, using the client's completion flags and server daily reset. Saved local turn-ins cover delayed quest updates without changing existing settings or prices.
- The Writs Show button cycles through All, Available, and My cargo. Available excludes active and completed writs without changing value ratings.

Simulated tests cover sorting, abandon/reaccept/turn-in, reload persistence, character isolation and daily reset. Actual server reset behavior still needs an in-game check. Without readable reset data, the addon relies on the game's completion flags after a short turn-in grace period.

## Previous update: 0.14.8

- Removed the Alliance preview debug setting; appearance follows the character's faction.
- Ledger dragging now saves its position. Existing compass position, scale, minimap angle, prices and flight data remain intact during updates.

- A one-time chat notice for each newer addon version detected through guild/group version messages or the diagnostics receiver. The notice persists across reloads; it does not directly query CurseForge.

- Optional automatic diagnostics in Settings > Diagnostics, off by default and separate from price sharing.
- Small queued route summaries, scan outcomes, blocked actions and Waylaid Lua error locations can reach the developer through addon messages.
- Current beta receiver: War Lune, Horde, Classic Beta PvP 2. Other factions and realms pause collection until a receiver is configured.
- Bounded queues, duplicate suppression, expiry, acknowledgements and immediate opt-out. No raw error text, public-chat messages or website uploads.
- Added a copyable GitHub reporting link and a developer inbox reader. See DIAGNOSTICS.md for fields, limits and delivery requirements.

Automatic delivery has been tested with simulated clients; actual Forever realm delivery still needs a two-player test. Routing calculations are unchanged.

## Previous update: 0.14.7

- Added a routing beta notice to the Route tab, settings, delivery details and compass.
- Clarified that larger delivery rounds can miss a shorter order and dotted walking lines are directional guidance.
- Expanded development tests for Horde and Alliance, incomplete flight scans, 1–6 and 12 writs, boats, tram, travel resources and delivery removal.

This update makes the limitations clearer; it does not change route calculations. No automatic feedback collection or log transmission has been added.

## Previous update: 0.14.6

Reduced temporary memory use while planning routes and drawing maps.

- Store walking-connection costs more compactly during route calculations.
- Reuse map-route buffers instead of rebuilding every row on every redraw.
- Clear unused route references when deliveries disappear or an overlay is disabled.

Local Lua 5.1 benchmarks showed about 71% fewer temporary allocations for active-route calculations, 50% fewer for a six-delivery plan, and 86% fewer for map-route rebuilding. These are benchmark allocation reductions, not a claim about total in-game RAM usage.

The runtime package still excludes development tools, source PNGs and the archived road engine. Saved prices, known flight paths and delivery data are retained. This remains a beta release.
