# Forever Waylaid 0.13.6 preview

- Disabled advanced road routing for writs everywhere, including Orgrimmar. Removed the street graph/data from the loaded addon and retired safer/fastest controls. Walking now uses direct dotted bearings; transport and multiple-delivery planning remain active.
- Reduced runtime installation from about 71.39 MiB to 46.35 MiB by excluding unused source PNGs, retired animations and archived road code. Active artwork is unchanged. Sources remain in the repository.
- Avoided rebuilding item lists while the ledger is closed. Reused map-pin event handlers and released their old delivery references when clearing overlays.
- Added `/fwl memory` to report actual client Lua memory (not textures), stored prices and pet/peer record counts. No forced collection or save deletion.
- Security review: tightened empty sender/price-record validation, fixed malformed `/fwl pin` coordinates causing an error, and clear pet reply tracking when sharing is toggled. Existing opt-in, packet-size, rate, scope and numeric limits remain active. Peer values are still unverified; personal pet saves are not tamper-proof.
- Audited runtime message handling, auction actions, packaging and dependencies. No dynamic evaluation of peer input or automatic purchases were found. Dependency audit reported zero known advisories across six development dependencies on 2026-10-01. This is a code review and automated audit, not a guarantee of security.
- Packaging uses an explicit runtime file list. Test runner now detects Lua assertion failures even when the emulator returns exit code zero.

Run `/reload`. Automated checks cover direct routes despite legacy settings, transport/writ progression, hidden-ledger work, reused pins, malformed inputs, peer validation, pets and existing addon behavior. In-game memory and multi-writ travel still need user observation. This remains a preview release.
