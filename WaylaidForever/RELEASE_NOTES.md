# Waylaid Forever 0.14.8 — beta

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
