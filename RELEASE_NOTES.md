# Forever Waylaid 0.13.3 preview

- Renamed all six token adoption options to Adoption Crates and gave them crate icons. Prices, rarity odds, saved pets and earned crates are unchanged.
- Moved the Pets window above the ledger so their contents no longer interleave. Adoption and Store panels sit above Pets and block clicks through their backgrounds.
- Restored scene drawing above the panel fill and below the characters. Re-exported the existing Horde and Alliance artwork as uncompressed, opaque RGBA TGA textures with explicit texture paths.

Run `/reload`. Addon regressions, window-layer checks and Lua 5.1 syntax checks pass; texture checks validate both scene exports. The final appearance still needs an in-game check. This remains a preview release.
