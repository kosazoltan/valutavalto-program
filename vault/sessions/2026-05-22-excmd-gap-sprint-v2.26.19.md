# Session 2026-05-22 — EXCMD gap-sprint → v2.26.19

## Mit csináltunk

A felhasználó utasítása: a `Felmérés/Valuta` forrásdokumentumokból **egyenként** AI-utasítás MD-fájlok az `EXCMD/` mappába (SABLON 2), majd ezek alapján szakaszonkénti összevetés a programmal, és a hiányok javítása — szakaszonkénti merge-ekkel, a végén telepítő.

### 1. fázis — EXCMD MD-szet (commit `817141a1f`, PR #764)
27 forrás-spec (`EXCMD/b1..b10`) + `_SABLON2-INSTRUKCIO.md`: régi Delphi képernyőképek, Árfolyamkészítő követelménylista, sztornó/zárás/Bank-API/hibalista, Foglaló+bizonylatok, beállítások, igényfelmérés/interjúk, riport/adat-minták, munkavállaló-nyilvántartás, körlevelek, hardver/zálog scope-out katalógus. 0 hallucináció, FR-ek forrás-hivatkozással, PII redaktálva.

### 2. fázis — szakaszonkénti összevetés (PR #764)
6 verifikációs riport (`EXCMD/_compare/c1..c6`) + konszolidált backlog (`00-KONSZOLIDALT-GAPS.md`), kód-bizonyítékkal. Eredmény: a program érett; 23 verifikált gap.

### 3. fázis — javítás (szakaszonkénti merge)
| Gap | PR | Tartalom | Teszt |
|---|---|---|---|
| G5/G6 | #764 | Szankció-szűrő hardening: NFD-normalizálás, ENTITY-import, Locale.ROOT, üres-név guard | SanctionServiceTest 12/12 |
| G1 | #765 | Foglaló UI a valós backend kontraktushoz igazítva | ReservationPage.test 2/2 |
| G2 | #766 | Sztornó a pénztáros által megadott aktuális árfolyammal (díj-megőrző különbözet) | Reversal 8/8, Storno 7/7 |
| G4 | #767 | FATF többszintű ország-kockázati lista (FZS-9/2024) a szankció-szűrésben | Fatf 6/6 |
| verzió | #768 | 4-way (6 fájl) bump → 2.26.19 | CI zöld |

Minden PR: CI zöld + AI-review (Codex/Sourcery/Copilot) findingek javítva (PII, Locale, @Transactional self-invocation, putAll fail-fast, CI-mock 7-arg, offline-fallback FATF spy). Production HEALTHY (auto-deploy minden merge után).

### 4. fázis — záró telepítő (v2.26.19, UNSIGNED — DigiCert cert pending)
- `Penztar-Setup-2.26.19-20260522.exe` (297 MB) — SHA-256 `57FE2D709F70D9D0CED41BE0856A6EF6BA44F536A49AF93F038447023A66230F`
- `Kozponti-Iranyitokozpont-Setup-2.26.19.exe` (106 MB) — `3B893A1F5B0017023662ABBBE5F8E4679D3D98ED6426977A6682C76C560F759A`
- `Arfolyamkeszito-Setup-2.26.19.exe` (106 MB) — `34C0C197023A31659936E8B5143BD2ECD7B34D61136F7A2AE617E02D870BCCCA`
- `Penztar-Eltavolito-2.26.19-20260522.exe` (verzió-független) — `5D84BE6AA024D9543B5B13F9E846255A6E05F700D8AE4750007E97539B5BDFB4`
- Build: `ALLOW_UNSIGNED_BUILD=1` (a code-sign gate enélkül `CODE_SIGN_ENABLED=(unset)` hibával áll meg). Mind Downloads-ba másolva.

## Tanulság / nyitott

- **G3 (NAV zárás-eltérés gate) BLOKKOLT:** a `ClosingWizardService.finalizeClosing` nem hivatkozik NavClosing-ra — a zárás-wizard és a NavClosing **architekturálisan külön folyamat** (nincs `wizardId↔navClosingId` link). Tiszta bekötés backend-restrukturálást + futó-ökoszisztémás böngészős verifikációt igényel. Külön fókuszált kör javasolt.
- **Hátralévő backlog (P1/P2):** G7 (RFM validáció-irány), G9 (pillanatnyi pénztárállás kasszanézet), G10 (zárás-típusválasztó), G11 (10M engedélyező-blokk), G12 (sztornó-engedély értesítés), G14-G23 (riport/UI). Részletek: `EXCMD/_compare/00-KONSZOLIDALT-GAPS.md`.
- A 4-way installer build CSAK a Penztart építi a `build-installer.ps1`-gyel; a kozponti/arfolyam külön `npm run package:unsigned`; az Eltavolito verzió-független (reuse).
