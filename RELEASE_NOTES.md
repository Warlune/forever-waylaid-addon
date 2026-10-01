## 0.7.0 — Faction preview and auction addon controls

- Added **Debug: preview Alliance appearance** in Settings. Colors, crest, heading, compass accent and the human scribe switch immediately; actual faction pricing, crafting, routing and peer scope stay unchanged.
- Expanded auction addon detection to TSM, Aux, AuctionLite, AuctionFaster, AHDB, AuctionMaster, AuctionBuddy, Midas and GoldCap, alongside Auctionator and Auctioneer. Detection is based on enabled addon identifiers; installed but disabled copies do not hide our controls.
- Added **Auto-hide extras with another AH addon**, on by default. It hides our native Scan tab, scan controls and unrelated-item tooltip additions. Turning it off allows those extras alongside another addon.
- Added **AH tooltips on unrelated items** for independent control of general price tooltips. Waylaid crates, writs, goods and ingredients retain their details.
- Settings show the detected auction addon. Enabling auto-hide during a native scan cancels it without replacing saved prices.

All scans remain manual. Third-party price imports still support Auctionator and Auctioneer only; detection of other addons does not add import support or certify their Forever compatibility. Original slower scribe artwork is preserved.

Install the ForeverWaylaid folder in Interface/AddOns, then /reload. Open /fwl → Settings for the new controls.
