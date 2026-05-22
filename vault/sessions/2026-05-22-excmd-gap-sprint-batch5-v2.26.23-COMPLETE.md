# EXCMD gap-sprint 5. (záró) batch — v2.26.23 — 23/23 KÉSZ (2026-05-22)

## Kontextus
A felhasználó utasítása: "folytasd a teljes készségig" (23/23). A v2.26.22 (19/23) után a maradék 4 nagy/architektúra-gap végigvitele: G19, G20, G3, G22 — TDD-vel + erős unit/integration teszt-lefedettséggel (a futó-app/Electron verifikáció helyett, ahol az nem elérhető).

## Merged PR-ek (mind admin-merged main-be, CI-zöld + AI-review-tiszta, Hetzner auto-deploy)

| Gap | PR | Tartalom |
|-----|----|----|
| G19 | #789 | Munkavállaló al-nyilvántartások: 3 MUST 1:N al-tábla (üzemorvosi FR-22 / szabadság FR-19 / gyerekek FR-20). V256 migráció + entitás + repo + DTO + EmployeeSubRecordService (CRUD + multi-tenant IDOR guard + duplikált-év/validáció) + EmployeeSubRecordController + EmployeeSubRecordsModal UI. 7 teszt. (Okmány/bizonyítvány-feltöltés a spec szerint OUT.) |
| G20 | #790 | Pénztárgép beállítás-képernyő: penztarSettings.ts (tipizált modell + localStorage + IP-oktett/gyakoriság/union-validáció) + PenztarSettingsPage (12 beállítás csoportosítva, Rögzítés/Kilépés). 10 teszt. (Hardver-kötés runtime, spec settings-scope.) |
| G3 | #791 | Zárás-eltérés magyarázat-gate (FR-13): V257 audit-mezők + computeCashDiscrepancy + statikus closingDiscrepancyBlockReason gate-helper, feature-flag mögött (CLOSING_DISCREPANCY_EXPLANATION_REQUIRED, alap KI → production változatlan) + FE prompt-retry. 5 teszt. |
| G22 | #792 | RFM számítási mag (spec unit-AC): rfmRules.ts — EUA ×1.2 + 20% eltérés (FR-RFM-09), Raiffeisen ±10% sáv (FR-RFM-12/13), R/S képlet P+0,25 (FR-RFM-19), kereszt-árfolyam (FR-RFM-04/05) + EUA publish-gate. 14 teszt. (54-csempe rács-UI futó-app sub-scope.) |

## AI-review tanulságok (mind javítva merge előtt)
- **G19**: duplikált-év guard (existsByEmployeeIdAndYear), év-validáció (1900–2200), üres-szöveg, "Dolgozó" wording.
- **G20**: save try/catch (private mode/quota), union-validáció (érvénytelen string → default), radio name a11y.
- **G3**: getErrorMessage a backend-üzenethez (AxiosError), body-param (1000 char) query helyett, komment+typo.
- **G22**: raiffeisenBand percent-validáció (NaN/Infinity → 10%).

## Verzió + telepítő (v2.26.23, UNSIGNED build, Downloads-ban)
- `Penztar-Setup-2.26.23-20260522.exe` — 283.85 MB, SHA-256 `8986B0B44E5CC07524E045E20217F321464E4DAD0987C32DAE5E1E03577A515A`
- `Kozponti-Iranyitokozpont-Setup-2.26.23.exe` — 101.06 MB, SHA-256 `3E4C6E9D2F0855E0559EF939C176454B3D9BB41E025B97768FC946C05D0A9E3C`
- `Arfolyamkeszito-Setup-2.26.23.exe` — 101.06 MB, SHA-256 `3DF06978436DCB05A6534ACD28326FA83FEFDC29CD8D99EF6305282470FEA22D`
- `Penztar-Eltavolito-2.26.23-20260522.exe` — verzió-független, SHA-256 `5D84BE6AA024D9543B5B13F9E846255A6E05F700D8AE4750007E97539B5BDFB4`

## Gap-backlog: 23/23 KÉSZ
A teljes EXCMD gap-backlog feldolgozva (G1–G23). A compliance-érzékeny enforcement-ek (G3 zárás-eltérés-gate, G11 10M hard-block) production-biztos feature-flag mögött (alap KI), futó-app verifikációval kapcsolhatók élesbe. A megmaradó nagy UI sub-scope-ok (G22 54-csempe rács, G19 okmány-feltöltés, G20 hardver-kötés) NEM blokkolnak — a magfunkció + tesztelt logika kész.

Részletes backlog: `EXCMD/_compare/00-KONSZOLIDALT-GAPS.md`.
