## 0.4.0 — Personal scans and opt-in peer prices

- Removed the external price feed, bundled snapshot, market selector and companion helper. Existing personal scan prices are retained. New users remain unpriced until they scan or receive peer prices.
- Added a manual Scan AH prices button, progress and Cancel. Opening/closing the AH never starts a scan. Full snapshots use a 15-minute cooldown; interrupted scans retain previous observations.
- Built-in scan controls are hidden when Auctionator or Auctioneer Advanced is installed. Their existing scan integrations remain available.
- Added peer sharing, off by default. Opted-in guild/party/raid members on the same realm and faction exchange directly observed item prices, quantities and scan timestamps using throttled addon messages.
- Peer prices are labeled unverified, keep their original age and expire after 24 hours. Personal scans win ties. Opting out stops sharing and excludes received prices.
- No automatic AH requests, purchases, public chat messages or external helper.

Install the ForeverWaylaid folder in Interface/AddOns, then /reload. Live exchange with a second opted-in player and actual accepted-writ deliveries still need testing.
