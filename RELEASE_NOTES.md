# Forever Waylaid 0.13.10 preview

- Both tower views now show whether the pet is ready to fight, or the exact missing health, energy and food requirements.
- Hover Fight for recovery guidance. A rejected click explains what to do instead of only listing generic minimums.
- Fight still requires 40 health, 15 energy and 15 food; starting costs 15 energy and 5 food. Rest in Camp to restore energy. Balance and saved pets are unchanged.
- Regression checks exercise the actual Fight handlers in the large window and compass, including insufficient energy, exact-threshold starts, no resource cost on rejection and automatic battle turns.

Run `/reload` after updating. This remains a 0.x preview release.
