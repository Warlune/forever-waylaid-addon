# Waylaid Forever 0.14.8 — beta

- Improved multi-writ route planning and connecting-flight handling.
- Reduced temporary allocations during route planning and map updates.
- Added routing beta notices and broader Horde/Alliance journey tests.
- Added optional diagnostics, off by default, and one-time notices for newer versions reported by other addon users.
- Removed the Alliance debug preview and added saved ledger window positions. Existing settings, prices, flight data and compass positions are preserved.
- Added an isolated local development build for testing alongside the public install.

See [Waylaid Forever's release notes](WaylaidForever/RELEASE_NOTES.md) for details and testing limitations. This remains a beta; large route orders and live diagnostic delivery still need player testing.

## Previous update: Waylaid Forever 0.14.2 and Companions Forever 0.1.1 — beta

- Renamed both addons to put their name before Forever, including windows, addon titles, tooltips, minimap buttons, price labels, folders, saved variables and ZIP files.
- New commands: `/wf` for Waylaid Forever and `/cf` for Companions Forever. Existing `/fwl`, `/fcp`, `/waylaid` and `/companions` commands still work.
- Tiny compatibility folders load existing saves. The renamed addons import copies once and retain the originals. Current standalone pet progress takes precedence over older bundled pets.
- The pet game remains fully separate. Removed the remaining pet tab, compass button, command and references from Waylaid Forever. Use /cf for Companions Forever. Gameplay balance is unchanged.

Extract all folders in each ZIP, replacing old TOCs. Restart WoW and enable the main addons plus their saved-data compatibility entries once on each character to migrate. The compatibility entries can be disabled after all characters have migrated. They contain no game engine.

Both releases remain beta, below 1.0. In-game migration and guild testing are still needed.
