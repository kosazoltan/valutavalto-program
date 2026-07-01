# GitHub Copilot Instructions

> ## ⛔ KÖTELEZŐ ÉRVÉNYŰ SZABÁLY — TESZT-INTEGRITÁS (NINCS KIVÉTEL, MINDEN MODELLRE KÖTELEZŐ)
>
> **TILOS A TESZTET ÁTÍRNI AZÉRT, HOGY ZÖLD LEGYEN.** SEMMIKÉPPEN NEM LEHET EGY BUKÓ TESZTET
> ÁTÍRNI, GYENGÍTENI, TÖRÖLNI, SKIPPELNI VAGY KIKOMMENTEZNI CSAK A ZÖLD EREDMÉNYÉRT. HA EGY
> TESZT BUKIK, ÁT KELL NÉZNI A TELJES KÓDOT ÉS A SPECET, ÉS AZ IMPLEMENTÁCIÓT VAGY A SPECET
> KELL JAVÍTANI — **SOHA A TESZTET A BUKÁS ELFEDÉSÉRE.** (Új teszt írása vagy valódi,
> dokumentált spec-változás külön feladatként megengedett; a tilalom a meglévő teszt
> bukás-elfedő átírására vonatkozik.)

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