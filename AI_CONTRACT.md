# AI_CONTRACT.md - hard korlatok AI coding agenteknek

> ## ⛔ KÖTELEZŐ ÉRVÉNYŰ SZABÁLY — TESZT-INTEGRITÁS (NINCS KIVÉTEL, MINDEN MODELLRE KÖTELEZŐ)
>
> **TILOS A TESZTET ÁTÍRNI AZÉRT, HOGY ZÖLD LEGYEN.** SEMMIKÉPPEN NEM LEHET EGY BUKÓ TESZTET
> ÁTÍRNI, GYENGÍTENI, TÖRÖLNI, SKIPPELNI VAGY KIKOMMENTEZNI CSAK A ZÖLD EREDMÉNYÉRT. HA EGY
> TESZT BUKIK, ÁT KELL NÉZNI A TELJES KÓDOT ÉS A SPECET, ÉS AZ IMPLEMENTÁCIÓT VAGY A SPECET
> KELL JAVÍTANI — **SOHA A TESZTET A BUKÁS ELFEDÉSÉRE.** (Új teszt írása vagy valódi,
> dokumentált spec-változás külön feladatként megengedett; a tilalom a meglévő teszt
> bukás-elfedő átírására vonatkozik.)

Ez a fajl csak a nem alku targya korlatokat tartalmazza. A munkamod reszleteit
az `AGENTS.md` szabalyozza.

## PR meret

- Plafon: ~400 sor diff per PR (SSOT: `AGENTS.md` agentic-qa blokk). Cel a kisebb,
  fokuszalt, vertikalisan teljes szelet (iranymutatas: ~5 funkcionalis fajl alatt).
- Ha a valtozas nagyobb, bontsd ertelmes, mukodo reszekre.
- Verzioszinkron, lockfile es generated artifact csak akkor lehet kivetel, ha a
  valtozas ezt tenylegesen megkoveteli.

## Teszt-integritas

Tilos:

- buko tesztet kikommentelni vagy torolni a zold eredmenyert;
- `skip`, `@Disabled`, `xfail` indok nelkul;
- assertiont gyengiteni ugy, hogy mar ne vedje a lenyegi viselkedest;
- coverage vagy CI kovetelmenyt gyengiteni az atjutasert.

## Git hygiene

Tilos:

- `git push origin main` vagy mas vedett agra kozvetlenul;
- force push vedett agra;
- `--no-verify` hasznalata;
- branch protection, ruleset vagy required check gyengitese uzleti PR-ben.

## Security tiltasok

Tilos commitolni vagy javasolni:

- hard-coded secretet, tokent, jelszot, privat kulcsot;
- SQL string-konkatot user inputbol;
- shell string-konkatot user inputbol;
- `eval`, `Function`, unsafe deserialization mintat;
- path traversal lehetoseget validacio nelkul;
- nema exception elnyelest;
- hamis mock adatot production valaszkent;
- ellenorizetlen uj csomagot vagy ismeretlen registryt.

## Dependency es release

- Manifest/lockfile elteres nem maradhat magyarazat nelkul.
- Release/deploy elott kell SBOM/attestation/container/security evidence, ha az
  adott release-tipus ezt hasznalja.
- Dependabot/CodeQL/secret scan high/critical jelzest release/deploy elott
  kezelni vagy bizonyitott false positive-kent dokumentalni kell.

## Allapotallitas

Tilos bizonyitek nelkul azt allitani, hogy kesz, deploy-ready vagy merge-ready.
Helyes forma: mi futott le, mi nem futott, milyen kockazat maradt.