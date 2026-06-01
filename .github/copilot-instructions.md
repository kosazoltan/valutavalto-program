# GitHub Copilot Instructions

Forras: `AGENTS.md`. Ez a fajl csak Copilot-specifikus rovid index.

## Viselkedes

- A cel mukodo kod es celzott javitas, nem vegtelen onellenorzes.
- Olvasd a relevans fajlokat, kodolj, majd futtasd a kockazataranyos ellenorzest.
- Ne javasolj hard-coded secretet, SQL/shell string osszefuzest user inputbol,
  `eval`-t, nema catch-et, path traversal mintat vagy teszt/CI gyengitest.
- Push/PR/deploy elott kell szelesebb ellenorzes; normal szerkeszteshez celzott
  teszt/typecheck eleg.

## Kontextus

Ne tolts be minden mandate-et automatikusan. Hosszu repo-dokumentumot csak akkor
olvass, ha a feladat konkretan igenyli.