# Forever Waylaid 0.13.2 preview

- Replaced the tower Retreat control with Heal in both pet views. Healing is manual, including healing abilities; automatic attacks never spend herbs or tokens.
- Heal queues the next pet action: ready healing ability, otherwise one herb, otherwise 4 tokens for 40% maximum HP. Costs apply only when the pet acts. Faster enemies can still strike first.
- Added a companion Store in the compass and large pet view for treats, toys and herbs. Buying adds stock without using it.
- Added happiness loss from tower hits.
- Added rare treats: 10% on first floor clears (never replays), or 1% on eligible personal NPC kills, capped at one per 30 minutes with a saved cooldown.
- Online income now requires a living equipped pet: 2 tokens per five minutes. Existing wallets remain unchanged.
- Documented hunger, energy and happiness at zero in the companion guide.

Run `/reload`. Tests cover manual healing/cost timing, faster fatal enemy turns, no auto-heal behavior, store purchases, needs thresholds, income and rare-drop boundaries/cooldowns, alongside existing addon regressions. Level-100 matchup and full-climb simulations now explicitly request healing. This remains a preview release.
