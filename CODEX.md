# CODEX.md - Codex kiegeszites

Codex ebben a repoban az `AGENTS.md` rovid SSOT szerint dolgozik.

## Munkaszabaly

- Eloszor kodolj vagy javits a feladat celja szerint, ne indits automatikus
  teljes gate-ciklust.
- Celzott ellenorzes normal kodjavitasnal; teljes gate csak push/PR/deploy vagy
  magas kockazatu security/dependency/CI valtozasnal.
- Ha ugyanaz a hiba ket kor utan marad, ne valts kenszeresen modot: keszits
  minimal reprot vagy olvasd vissza a konkret forrast, majd celzottan javits.

## Deploy gate

Deploy/release elott futtatando:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1
```

`FAILED` vagy `BLOCKED` status eseten nincs deploy-ready allitas.

<!-- CODEX_SHARED_QUALITY_RULES_START v1 -->
## Kikényszerített közös Codex minőségkapu

Ez a blokk minden repo-ban kötelező minimumszabály Codex/AI-agent munkához. A
repo-specifikus szabályokat nem helyettesíti, hanem kikényszerített módon
kiegészíti. Repo-specifikus szabály csak szigoríthatja vagy pontosíthatja ezt a
blokkot; nem gyengítheti, nem kapcsolhatja ki és nem írhatja felül. Ütközésnél
mindig a szigorúbb, biztonságosabb, jobban verifikálható szabály érvényes. Ha a
repo-specifikus szöveg enyhébb mércét engedne, azt Codex-munkánál érvénytelen
kivételként kell kezelni.

Repo-specifikus szabályok betöltése kötelező. Minden munkamenetben azonosítsd
és olvasd el a legközelebbi repo-vezérlő fájlt (AGENTS.md, CLAUDE.md, CODEX.md,
GEMINI.md), valamint csomag/alrepo munka esetén a közelebbi vezérlő fájlokat is.
Csak a közös blokk alapján dolgozni tilos, ha a repo saját szabályt tartalmaz. A
telepített közös blokk a repo saját szövegét nem törölheti és nem írhatja át
kézzel; csak markerelt blokkban frissíthető.

- Magyarul kommunikálj a felhasználóval, kivéve ha a repo vagy a feladat más
  nyelvet kér a végtermékben.
- Tényből dolgozz: ne találj ki fájlt, API-t, route-ot, teszteredményt, logot,
  buildet, deployt, review-t vagy külső forrást. Ha nem ellenőrizted, írd le,
  hogy nem ellenőrzött.
- Munka előtt olvasd el a legközelebbi vezérlő fájlt (AGENTS.md, CLAUDE.md,
  CODEX.md, GEMINI.md), az adott repo/alrepo saját kiegészítő szabályait és az
  érintett forrás/teszt fájlokat. Nagy dokumentumot eleje-közepe-vége
  mintavétellel olvass, ne ess Lost in the Middle hibába.
- 3+ fájlt, architektúrát, adatmodellt, migrációt, authot, pénzügyi/üzleti
  logikát, deployt vagy agent/CI szabályt érintő munkánál előbb rövid contract:
  cél, nem-cél, érintett fájlok, edge case-ek, elfogadási feltételek.
- Minimális, célzott változtatást készíts. Ne overpolisholj, ne refaktorálj
  mellékesen, és ne keverd össze a feladatot más nyitott munkával.
- Tesztet gyengíteni, törölni, skipelni, snapshotot kozmetikázni vagy
  test-only kerülőutat betenni tilos. A bukó teszt okát javítsd, ne a mércét.
- Minden érdemi változtatás után futtasd a legszűkebb hasznos ellenőrzést:
  célzott teszt, lint, typecheck, build, smoke vagy diff-check. Kész állapotot
  csak valós parancskimenettel vagy pontosan dokumentált blockerrel állíts.
- UI/megjelenítési változásnál a renderer/unit teszt nem elég. Kötelező valós,
  teljes képernyős Browser/Playwright render ellenőrzés, amely nézi az átfedést,
  levágott szöveget, váratlan scrollbart, viewport overflow-t és a javított
  felhasználói állapotot.
- Titkot, tokent, privát kulcsot, személyes adatot vagy secret-like azonosítót
  ne írj chatbe, logba, commitba, dokumentációba vagy fájlnévbe. Használj
  placeholdert vagy secret-store/environment hivatkozást.
- Destruktív művelet, adatbázis-migráció, tömeges törlés, deploy, release,
  credential/cert kezelés vagy külső rendszer módosítása előtt legyen explicit
  kockázatkezelés és visszaállási pont; ha nincs biztonságos default, állj meg.
- Dirty worktree-ben ne revertáld és ne írd felül más munkáját. Státusz alapján
  különítsd el a saját szeletet, user/unknown munkát és generált zajt.
- Windows hoston parancsoknál preferáld az explicit futtatókat (npm.cmd,
  npx.cmd, pwsh/powershell -ExecutionPolicy Bypass), ne támaszkodj olyan
  shimre, amely szerkesztőben nyílhat meg.
- Záró válaszban sorold fel: módosított fájlok, futtatott ellenőrzések
  PASS/FAIL eredménnyel, nem futtatott ellenőrzések oka és maradó kockázat.
<!-- CODEX_SHARED_QUALITY_RULES_END v1 -->
