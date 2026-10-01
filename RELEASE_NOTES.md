## 0.5.1 — Smoother scribes and clearer scan counts

- Doubled both faction scribes from four to eight animation frames.
- Fixed the bottom Scan tab overlapping the Auctions tab by matching native tab spacing.
- Added an All item types counter alongside auctions read, relevant items, prices saved, and elapsed time.
- Re-read unidentified auction rows locally before committing prices. If item IDs remain missing, keep the previous prices and report an incomplete snapshot.
- Scanning remains manual, with one server snapshot request and the existing 15-minute cooldown.

The earlier verified scan read 76,812 auction rows and saved 273 relevant item prices. Saved prices only cover writs, crates, goods, and crafting ingredients; they are not a count of all items scanned. No matched-snapshot comparison with Auctionator or Auctioneer has been performed.

Install the ForeverWaylaid folder in Interface/AddOns, then /reload.
