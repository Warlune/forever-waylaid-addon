## 0.2.0 — The merchant's field ledger

- Rebuilt the crate and writ browser with Classic borders, gold headings, native item icons, red buttons, and parchment details.
- Added material search, tier/cargo filters, value/cost/name sorting, bag counts, auction stock, price age/source, favor, reputation, and purchase totals.
- Added a draggable minimap crate bubble: left-click for the ledger, right-click for the travel compass.
- Added the movable Courier's Compass with direction, distance, current writ, recipient information, and destination coordinates. Unfold its small map with the down-arrow button.
- Added route lines and flight-master pins to the world map, compass map, and native minimap. Gold indicates travel; blue indicates flights. Guidance continues with the ledger closed.
- Added named manual pins and recipient learning from writ completion dialogs.
- Kept the AHledger helper optional; bundled prices and supported personal scans work without it.

Extract `ForeverWaylaid` into the client's `Interface/AddOns` folder. On first use, select your AHledger market in Settings. `/fwl` opens the ledger; `/fwl compass` toggles guidance; `/fwl reset` restores the compass position.

Checked the ledger, launcher, and fold-out map in Forever 1.60.1.70124. Automated tests cover pricing, routing, clipping, compass bearings, and flight guidance. Real accepted-writ deliveries and auction integrations still need live testing. Routes are estimates, not terrain-aware roads; unknown destinations need a manual pin, and only learned flight connections are used. See README for details.
