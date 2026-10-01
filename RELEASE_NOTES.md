# Forever Waylaid 0.13.5 preview

- Added Happiness and Energy alongside Health and Food in the compact camp view, with two rows of meters and the same overall compass height.
- Added pixel status cues in both camp views: floating Zs while resting, a hunger zigzag below 25 food, and an anger mark below 25 happiness. Hover each symbol for details.
- Cues clear after care, stay hidden for absent companions and tower battles, and remain still with reduced motion enabled.

Run `/reload`. Addon regressions and Lua 5.1 checks pass, including need thresholds, care clearing, animation movement, reduced motion and tower visibility. The final layout and animation still need an in-game check. This remains a preview release.
