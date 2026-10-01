## 0.9.14 — Shorter zeppelin approach

- Added the missing northern forecourt connection outside Orgrimmar, fixing the southward detour from Durotar 46.5, 13.9 toward the zeppelin approach.
- Recalculate the active leg twice per second after meaningful player movement, rather than waiting for the five-second itinerary refresh.
- Skip extra path calculations while stationary or on a booked flight. Visual lines continue updating at up to 20 frames per second.

The new connection is based on the player's in-game screenshot; road coordinates and tower access remain approximate. This does not add a general terrain navigation mesh.

Reload after installing; the addon should report v0.9.14. This remains a preview release.
