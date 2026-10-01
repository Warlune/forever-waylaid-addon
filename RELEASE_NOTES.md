# Forever Waylaid 0.11.3 preview

- Fixed the protected-action popup on login/reload caused by registering the old combat-log event for pet XP.
- Pet kill XP now listens to Forever's supported standalone `PARTY_KILL` event (attacker GUID, target GUID). It never registers `COMBAT_LOG_EVENT_UNFILTERED` or reads the secure combat log.
- Restricted/secret identities are skipped before comparison, parsing or storage. Kills with hidden identities do not award pet XP; tower XP remains available.
- Added a regression guard that fails if any addon module registers a restricted combat-log event, plus tests for the standalone payload and unreadable identities.

Updated to **0.11.3 preview**, still below 1.0. After installing, choose **Ignore** on the existing popup and `/reload`. If the addon was disabled, re-enable Forever Waylaid in the AddOns list first. Live kill-XP testing remains necessary.

API references: [Forever combat-log restrictions](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/CombatLogDocumentation.lua) and [standalone kill event](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua).
