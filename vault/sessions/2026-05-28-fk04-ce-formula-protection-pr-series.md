# 2026-05-28 — FK-04 C/E képletezés + árfolyamvédelem (PR-sorozat)

## Kritikus felfedezés
**Az FK-04/E.2 backend védelmi validáció (#885, v2.27.39) SOHA nem került a main-re.** A
`feat/fk-04-e2-protection-validation` feature-branch commitja (`7890ef0d2`) NEM ancestor-a a
main-nek (a squash-merge elmaradt). A main #884 (v2.27.38) után rögtön a Shipment-ekre ugrott.
A session-ledger tévesen állította, hogy merged. → helyreállítva a #899-ben.

Hasonlóan: az **FK-03 képletmotor** (`workgroupSheetFormula.ts`, #879) be VAN a main-en, de
**sehova nem volt bekötve** (csak a tesztje importálta). Ez a sorozat köti be (FK-04/C).

## Mit csináltam — komplett, tesztelt implementáció
1. **Backend FK-04/E.2** (recovery): `RatePublishService.validateRateProtection` + N+1-mentes
   (`findAllById`) + 0-skip parity. 8/8 teszt.
2. **FK-04/C compute mag** (`workgroupSheetCompute.ts`): reaktív Jacobi-fixpont, J–S/A–I/!FEUR/#NN
   feloldás, ciklus-detektálás. JPY→3 tizedes (0-s lap parity). 9/9 teszt.
3. **FK-04/C storage** (`workgroupSheetStorage.ts`): per-csoport localStorage képlet+érték, 0-s lap
   A–I beolvasás. 7/7 teszt.
4. **FK-04/E frontend** (`workgroupProtection.ts`): backend-azonos szabály, azonnali toast. 10/10.
5. **FK-04/C UI** (`RateCreationPage` + `RateGrid`): képletcellák (buffer-modell, hover=képlet, ƒ-jel),
   reaktív recompute, publish-előtti védelmi blokk. → **az UI-PR (F) a C/D/E merge után jön.**

Lokál gate: backend 1730/1730, frontend 1026/1026, typecheck/build/lint OK, verzió-sync 2.27.50.

## PR-sorozat (300-LOC/5-fájl kontraktus miatt bontva)
| PR | Tartalom | CI | Állapot |
|---|---|---|---|
| #898 | ShipmentNewPage teszt-fix (#897 pre-existing törés, piros main) | zöld | auto-merge ON |
| #899 | Backend FK-04/E.2 (recovery) | zöld | auto-merge ON |
| #900 | FK-04/C compute mag | zöld | auto-merge ON |
| #901 | FK-04/C storage | zöld | auto-merge ON |
| #902 | FK-04/E protection (pure) | zöld | auto-merge ON |
| **F (TODO)** | UI: RateCreationPage + RateGrid + verzió-bump 2.27.50 | — | **C/D/E merge után** |

Lokál teljes kód: `feat/fk04-ce-formula-protection` branch checkpoint `f499ad607` (a végleges
JPY/N+1 fixekkel a fenti modul-ágakon; a checkpoint a fix ELŐTTI compute/test-verziót tartalmazza —
F építésekor a main-ről kell venni a compute/storage/protection modult).

## BLOKKOLÓ — user-akció kell
A main branch-protection **1 kötelező jóváhagyó review-t** ír elő. A szerző (Junior AI) nem
hagyhatja jóvá saját PR-jét, és a `--admin` bypass-t a Claude Code guardrail (helyesen) tiltja
(production auto-deploy). **A 5 PR a user 1-1 jóváhagyására vár**, utána az auto-merge lefut.
A C/D/E merge után építem az F (UI) PR-t + verzió-bump.

## NEM ellenőrzött (őszinte)
A futó authentikált rate-maker flow böngésző-preview verifikációja NEM történt meg (teljes
ökoszisztéma + főértéktáros login kéne). A logikai mag unit/integration tesztekkel + typecheck +
build + saját subagent code-review-val verifikálva.
