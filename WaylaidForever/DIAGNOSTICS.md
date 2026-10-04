# Optional diagnostics

Settings > Diagnostics (or `/wf diagnostics`) controls this feature. It is off
by default and independent of price sharing. Errors from before it was enabled cannot be recovered. A reload clears the
current UI state; an intermittent issue may need the same preceding actions to
recur. Leave diagnostics enabled while testing to capture the next occurrence.

Enabling it allows small automatic
reports without writing a chat message or filing a ticket each time.

Version notifications are separate: the addon exchanges its version number
with guild/group members and shows one chat notice per newer version detected.
The last notified version is saved across reloads. This does not enable telemetry
or send diagnostics. A version seen on another player is not proof that a file
is published on CurseForge; the notice asks you to check for an update.

The current receiver is **War Lune, Horde, Classic Beta PvP 2**. The receiver
list is in Telemetry.lua and must be reviewed before launch. There is currently
no Alliance or other-realm receiver; those characters collect no reports.

Reports include the addon version, game build, report time, faction, class,
level, map ID and coordinates, up to 12 active writ quest IDs, route duration,
whether the planner used a bounded estimate, unresolved-stop count, and counts
of known flight points and scanned departures. Event types are route summaries,
scanner completion/stopping, Waylaid blocked actions, and Waylaid Lua error
file/line references. Blocked-action reports include a bounded function name
(without arguments) and whether combat lockdown was active (C = combat, N = no
combat lockdown). The blocked function identifies where the restriction occurred,
not necessarily where taint began. Stopping a scan is not necessarily an error. Estimated
routing does not prove that a route was inefficient.

No raw Lua error text, chat, account identifiers, inventory, guild rosters or
arbitrary saved settings are transmitted. WoW exposes the sending character's
name to the receiving addon; it is used briefly for replies and rate limits,
but is not stored in the report inbox. These reports are not anonymous in transit.

Reports use the ordinary addon whisper API, never SendChatMessage. There is no
HTTP upload, external program, public-chat broadcast, relaying through unrelated
players, or automatic GitHub issue creation. The sender first requests a short
session with the configured receiver. Once acknowledged it sends at most one
report every three seconds, retrying until acknowledged or the session expires.
Offline contact attempts are limited to once per ten minutes. Realm messaging
restrictions are respected. Actual delivery requires in-game verification and
may be unavailable; no restrictions are bypassed.

The local account queue holds at most 40 reports for seven days. Repeated event
codes are suppressed for ten minutes. The receiving account retains at most 300
reports for fourteen days. Disabling diagnostics clears unsent reports and
stops new collection and transmission. Already delivered reports expire from
the receiving inbox independently. Received reports are untrusted diagnostic
data, not evidence of player misconduct, and must never be executed as code.

On the receiving character, `/wf diagnostics` shows the inbox count. Reload or
log out normally to save it. The developer can inspect that account's
WaylaidForever.lua SavedVariables file using:

    node tools/read-telemetry.mjs "path/to/SavedVariables/WaylaidForever.lua"

This development tool parses Lua as data without executing it. It is not shipped
to players. The inbox is under WaylaidForeverDB.telemetryInbox.

GitHub and CurseForge reports remain useful for screenshots, explanations and
issues automatic diagnostics cannot identify. The diagnostics panel provides a
copyable GitHub issue URL. Do not post your entire SavedVariables or WTF folder.
