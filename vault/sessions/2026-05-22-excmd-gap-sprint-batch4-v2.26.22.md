# EXCMD gap-sprint 4. batch — v2.26.22 (2026-05-22)

## Kontextus
A v2.26.21 (G10/G14/G15/G16/G17/G23) batch után a felhasználóval egyeztetett döntési pontok mentén a fennmaradó, NEM dedikált-sprintbe sorolt gap-eket vittük végig: G13, G8, G11, G7. A G3 (architektúra-blokk) és G19/G20/G22 (nagy/migrációs/RFM-rács) tudatosan dedikált sprintbe halasztva.

## Egyeztetett döntések (AskUserQuestion, 2026-05-22)
- **Sorrend:** mindent prioritási sorrendben, PR-enként, szakaszos merge, a végén v2.26.22 telepítő.
- **G8:** spec szerinti 5% letét (5 Ft kerekítés), teljes pénzmozgással.
- **G11:** feature-flag warn (alap KI) — nem hard-block.
- **G3 / G19 / G20:** külön, dedikált sprint (most nem). + G22 ugyanide sorolva (azonos osztály).

## Merged PR-ek (mind admin-merged main-be, Hetzner auto-deploy, production HEALTHY)

| Gap | PR | Tartalom |
|-----|----|----|
| G13 | (verifikáció) | EU FSF `importEuSanctionList` (sanctionEntity = személy+szervezet) + `SanctionListScheduler` naponta UN+EU + screening minden bejegyzésre MÁR működik. A személy/szervezet típus-megkülönböztetést a spec maga TBD-nek jelöli. 12/12 SanctionServiceTest. Nem kellett új kód. |
| G8 | #785 | Foglaló-letét = round5(ft-érték × 5%) a 100% helyett (FR-9). A pénzmozgás többi része már részleges letétre volt tervezve (fulfill 95%, cancelByCustomer 5% bukás, cancelByCompany 5%×2). ReservationServiceTest 10/10. |
| G11 | #786 | 10M+/fokozott (requiresManagerApproval) enforcement az AML_HIGH_VALUE_APPROVAL_ENFORCEMENT SystemParameter mögött. Default false → WARN-only; true → ValidationException. Statikus highValueApprovalBlockReason() helper, 6/6 teszt. Nincs migráció. |
| G7 | #787 | RFM árfolyam-irány validáció kiküldés előtt (FR-RFM-25): eladási ≥ elszámoló ÉS vételi ≤ elszámoló. Tiszta `rateDirectionRules.ts` (11 teszt) + MainRateSheetPage publish-confirm figyelmeztetés. |

## AI-review tanulságok (mind javítva merge előtt)
- **G8**: tisztább kassza-helper + pénzmozgás-asszerció a tesztben (Copilot).
- **G11**: flag-kulcs konstansba, blank-indok `isBlank()` fallback, pontosabb WARN-log, 4-szem-elv komment (Sourcery+Copilot).
- **G7**: `Number.isFinite` védőőrök (NaN/Infinity), `window.confirm` szándékos választás dokumentálva (Sourcery).

## Verzió + telepítő (v2.26.22, UNSIGNED build, Downloads-ban)
- `Penztar-Setup-2.26.22-20260522.exe` — 283.86 MB, SHA-256 `0E5869FF5961FD40F7AC4DD13D68E0F4B7888F342333C348C76792971C800C6F`
- `Kozponti-Iranyitokozpont-Setup-2.26.22.exe` — 101.06 MB, SHA-256 `D5BAFC6FE6974160374E4C98D7C4B6194E222455077BCC69F38E0E5FB8528417`
- `Arfolyamkeszito-Setup-2.26.22.exe` — 101.06 MB, SHA-256 `4E74837037E06243CABEA27F7A435C97065729629FC5F4C47590C8963857F98D`
- `Penztar-Eltavolito-2.26.22-20260522.exe` — verzió-független, SHA-256 `5D84BE6AA024D9543B5B13F9E846255A6E05F700D8AE4750007E97539B5BDFB4`

## Gap-backlog állapot: 19/23 KÉSZ (+G11 részben)
- **KÉSZ (19):** G1, G2, G4, G5, G6, G7, G8, G9, G10, G12, G13, G14, G15, G16, G17, G18, G21, G23 + G11 (részben: feature-flag).
- **BLOKKOLT (1):** G3 — wizard↔NavClosing architektúra-link kell.
- **HALASZTVA dedikált sprintbe (3):** G19 (munkavállaló al-nyilvántartások), G20 (beállítás-képernyők), G22 (teljes RFM-rács újraépítés — 54-csoport entitás + migráció + képletmotor). Futó-app (Electron) verifikációt igényelnek.
- **G11 hátralévő:** a hard-block tényleges bekapcsolása a pénztáros supervisor-approval UI-jával (Buy/Sell + DTO) — külön kliens+szerver kör.

Részletes backlog: `EXCMD/_compare/00-KONSZOLIDALT-GAPS.md`.

## Build-megjegyzés
A Penztar-Setup makensis lzma-tömörítése után a build-installer.ps1 "BUILD COMPLETE" markere / a háttér-task befejezési értesítése nem flush-ölt (hosszú background task), de az exe 33 percig stabil maradt (283.86 MB = 297 644 426 byte, a 2.26.21-gyel azonos méretosztály, +22 KB a kódváltozásokból), nincs makensis/powershell-build process → a build érvényes és teljes.
