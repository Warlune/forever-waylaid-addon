## 0.4.1 — Show the scanner when other scanners are disabled

- The built-in scanner is visible when Auctionator and Auctioneer Advanced are disabled or absent.
- It stays hidden when either scanner is enabled for the current character.
- Known disabled states take precedence over globals left in memory before a reload.
- Scanning remains manual. Opening or closing the auction house never starts a scan.

Install the ForeverWaylaid folder in Interface/AddOns, then /reload.
