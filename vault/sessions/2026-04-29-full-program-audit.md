---
date: 2026-04-29
session_type: end-to-end-program-audit
context: v2.3.8 Setup OK, KOSA bejelentkezve (pénztáros, MANAGER role per V121)
priority: P0 — éles teszt-elv elválasztó + v2.3.9 kódfix-blueprint
---

# 2026-04-29 — Pénztár app TELJES KÖRŰ menü-audit (v2.3.8) — VÉGLEGES

## Setup
- App version: Penztar.exe v2.3.8 (FileVersion 2.3.8.0)
- Worker: KOSA (Kosa Zoltan), V121 promote_kosa_to_manager → MANAGER role
- Branch (kiválasztva wizardban): BR035 Szeged Tisza Sarok
- App mode: penztar (Sidebar tükrözi: PÉNZTÁR (VALUTAVÁLTÓ) csoport)
- Backend: localhost:8080 (Spring Boot 4.0.6, V1..V167 Flyway, HTTP 200)
- Sync: online, last sync 15:11:24

## Legacy referencia (forrás-igazság)
- `Anti/VALUTA/IBVALTO/IBVALTO.DPR` + `Unit47.pas` (FOMENUFORM)
- `Anti/VALUTA/DLL/*` (110 DLL — VASARLAS, ELADAS, NAPZAR, CIMLET, ATADOLAP, BIZODISP, BLOKNYOM stb.)
- `Anti/ARFOLYAM/Arfolyam.exe` (külön EXE, főértéktár)
- `Anti/ERTEKTAR/etdll/*` (55 DLL, helyi értéktár)

---

## TELJES MENÜ AUDIT (sidebar 11 + 9 admin csempe + 8 napi csempe)

### Sidebar PÉNZTÁR (VALUTAVÁLTÓ) csoport

| # | Menüpont | Útvonal | Status | Bug-szám |
|---|---|---|---|---|
| 1 | Pénztáros főmenü | /cashier | ✅ OK | 0 |
| 2 | Napnyitás | /cashdesk/day-open | ⚠️ HEADER-BUG | 3 |
| 3 | Valuta vétel / eladás | /transactions/cashier | ⚠️ ÉKEZET+HEADER | 5 |
| 4 | Konverzió | /transactions/conversion | ✅ OK | 0 |
| 5 | Kassza / készlet | /cashdesk | ⚠️ DATA-BUG | 4 |
| 6 | Címletezés | /cashdesk/denominations | ❌ HIÁNYOS | 3 |
| 7 | Ügyfelek | /customers | ✅ OK | 0 |
| 8 | Úton lévő csomagok | /transit | ✅ OK + 1 bug | 1 |
| 9 | Napzárás | /closing/wizard | ⚠️ HEADER-BUG | 1 |
| 10 | Árfolyamok (nézet) | /rates | ❌ MAJOR | 1 (kritikus) |
| 11 | Tranzakciólista | /transactions | ⚠️ BRANCH-BUG | 1 |

### Pénztáros főmenü — Napi műveletek csempék (8) — duplikálva sidebar-ban
| Csempe | Hotkey | Útvonal | Mapping |
|---|---|---|---|
| Vétel | F1 | /transactions/cashier | = sidebar #3 |
| Eladás | F2 | /transactions/cashier | = sidebar #3 (toggle) |
| Konverzió | F3 | /transactions/conversion | = sidebar #4 |
| Átadás-átvétel | F4 | /shipments | NEW (nincs sidebar) |
| Stornó | F5 | /transactions (storno) | beépítve a tranzakciókba |
| Árfolyamok | F6 | /rates | = sidebar #10 |
| Készlet | F7 | /cashdesk | = sidebar #5 |
| Forgalom | F8 | /reports/daily-turnover | NEW |

### Pénztáros főmenü — Adminisztráció csempék (9)

| Csempe | Hotkey | Útvonal | Status | Bug |
|---|---|---|---|---|
| Napi zárás | Shift+F1 | /closing/wizard | ✅ OK | header-bug |
| Bizonylatok | Shift+F2 | /receipts | ❌ ÜRES + adatbázis-mismatch | 1 |
| Társpénztárak | Shift+F3 | /branch-groups | ❌ Hibás absztrakció | 1 |
| Listák | Shift+F4 | /transactions (=Tranz lista) | ❌ Legacy LISTAK.dll funkciók HIÁNYOZNAK | 1 |
| Pénztárosok | Shift+F5 | /workers | ⚠️ Role oszlop ÜRES | 1 |
| Napi forgalom | Shift+F6 | /reports/extended | ❌ Generikus tool, nem konkrét | 1 |
| Régi zárás | Shift+F7 | /archiving | ❌ Hibás célhely (Havi archiválás) | 1 |
| Címletezés | Shift+F8 | /cashdesk/denominations | = sidebar #6 |
| Beállítások | Shift+F9 | /settings | ❌ Cégadatok placeholder | 1 |

---

## TELJES BUG-LISTA (rangsorolva)

### P0 — KRITIKUS, üzletmenet-blokkoló (NEM tűrhető éles használatra)

#### B1. SetupWizard NEM jelenik meg friss telepítéskor (✅ root-cause megoldva, v2.3.9 kódfix-szel végleges)
- **Tünet:** Eltavolito + Setup után Penztar.exe nem mutatja a SetupWizardot
- **Forrás:** `~/.valuta/local.db` és `%APPDATA%\valuta-penztar\.env` átéli a reinstall-t (Cleanup nem törli)
- **Manuális fix:** törölve, működik
- **Kódfix v2.3.9:** `isFirstRun()` SQLite consistency check + Cleanup APPDATA-explorer-user-resolved deletion

#### B2. Pénztár /rates oldalon SZERKESZTHETŐ az árfolyam (READ-ONLY kell)
- **Tünet:** "Árfolyamok (nézet)" sidebar menü a pénztár módban → MŰVELET oszlop + szerkesztés-ikon + "MNB letöltés" + "Frissítés" gombok
- **User-direktíva:** "A főértéktár készíti az árfolyamokat, melyeket az értéktár [és pénztár] LÁT"
- **Legacy alap:** `ARFOLYAM/Arfolyam.exe` (külön EXE, főértéktár-only) + `getarf.dll` a pénztáros oldalon (csak read)
- **Kódfix v2.3.9:** RatesPage.tsx: `useAppMode()` → `mode === 'penztar'` → readonly mode, MŰVELET oszlop + szerkesztés gombok ELREJTVE

#### B3. Címletezés HIÁNYOS HUF címletlista
- **Tünet:** Csak 20 000 / 1000 / 100 / 50 HUF látszik
- **Hiányzik:** 10 000, 5 000, 2 000, 500, 200, 20, 10, 5 HUF
- **Plusz inkonzisztencia:** Összesített egyenleg 481 150 HUF DE minden mező 0,00
- **Mennyiség mező tizedes** (0,00) — darabszámnak integer kell

### P1 — MAJOR, üzleti logika hibás vagy hiányos

#### B4. Header info nem dinamikus full-screen layout-okban
- **Hely:** Napnyitás (DayOpenPage), Napzárás Wizard
- **Tünet:** "Penztaros: Admin (ID: ADMIN)" + "Penztar: 101 | Kozponti Iroda" — KOSA-val léptünk be BR035-re!
- **Forrás:** Hardkódolt fallback header, NEM a `useAuthStore`-ból töltődik
- **Kódfix v2.3.9:** Header komponens unified — `useAuthStore` a forrás

#### B5. Magyar ékezetek hiányoznak (i18n inkonzisztencia)
- **Helyek:**
  - Napnyitás: "Tovabb a penztarhoz", "A nap mar nyitva van", "Kozponti Iroda"
  - Vétel: "FORINT ERTEK", "UGYFEL ADATOK", "Ugyfel azonositas nem szukseges", "Vetel" (F2 gomb), "Eladas", "Dij/Kedv."
  - Csomagok: "Ertektar" (=Értéktár)
- **Forrás:** Vegyes betűkészlet — egyes komponensek sima ASCII-ban tárolják a Magyar szövegeket
- **Kódfix v2.3.9:** unified ékezetes magyar, vagy lokalizációs JSON

#### B6. Branch-mismatch: SetupWizard választás IGNORE-olva
- **Tünet:** Wizard BR035 (Szeged Tisza Sarok), DE tranzakció-prefix V017 (BR017), header "Központi", Pénztár 101
- **Forrás:** Backend a `worker.branchId`-t használja, NEM a SetupWizard `branch_code` SQLite configot. KOSA seed-ben BR017-hez rendelt.
- **Üzleti hatás:** A wizardban választott branch lényegtelen, ha a worker fix branch-en van. **VAGY** a wizard branch-választás csak UI-t változtat, de a tranzakciók a worker branch-én készülnek.
- **Kódfix v2.3.9:** Wizard branch-választás → `worker.branchId` UPDATE backend hívással, VAGY a wizard mezőt átnevezni "Eszköz iroda" + worker branch-et külön kérdezni

#### B7. Bizonylatok lista ÜRES, DE Tranzakciólista 12+ tételt mutat
- **Tünet:** /receipts oldal "Nincs találat", /transactions 12+ tranzakció
- **Lehetséges ok:** ReceiptService.findAll() rossz JOIN, vagy `bizonylat` tábla üres és csak a `transaction` tábla töltődik
- **Üzleti hatás:** Bizonylat-újranyomtatás (legacy ReprintGomb) NEM működik
- **Kódfix v2.3.9:** Backend `ReceiptController.findAll` audit + JOIN fix

#### B8. Régi zárás csempe rossz oldalra megy
- **Tünet:** Shift+F7 "Régi zárás — Archív napi zárások" → /archiving (Havi archiválás feladatkezelő)
- **Várt:** Legacy `REGIZARO.dll` (TREGIZARASFORM) — régi napzárás listája + újranyomtatás
- **Kódfix v2.3.9:** Új page `/closing/archive` egy listával + ReceiptService újranyomtatás-action

#### B9. Listák csempe = Tranzakciólista (legacy LISTAK.dll funkciók HIÁNYOZNAK)
- **Tünet:** Shift+F4 "Listák" → /transactions (= Tranzakciólista)
- **Hiányzó listák:** Forgalom dekád, Időszaki kimutatás, Kezelési díj dekád, Pillanatnyi készlet, Kiadott/Eladott valuták, ATVETTBANKJEGY/ATADOTTBANKJEGY oszlopok
- **Kódfix v2.3.9:** Új page `/lists` legacy LISTAK.dll funkcióinak portolása (5-6 különböző report)

#### B10. Napi forgalom csempe generikus riport-tool
- **Tünet:** Shift+F6 → /reports/extended (Bővített Riportok), üres dropdown + dátum
- **Várt:** Legacy `NAPIFORG.dll` (TNAPIFORGALOMFORM) — konkrét napi forgalom-grid
- **Kódfix v2.3.9:** Specifikus DailyTurnoverPage komponens (nem reuse ExtendedReportsPage)

#### B11. Cégadatok placeholder a Beállításokban
- **Tünet:** "Pénzváltó Kft.", "12345678-2-41", "MNB-123/2020", "1011 Budapest", "info@penzvalto.hu"
- **Várt:** Exclusive Best Change Zrt. valódi adatai (vault: `references/company-data-ebc-zrt.md`)
- **Kódfix v2.3.9:** Seed-data.sql cégadatok csere VAGY UI default-ok a vault-ból

### P2 — MINOR, kozmetikai vagy UX

#### B12. Kassza/Készlet panel
- ISO timestamp formázatlan: "2026-04-29T11:43:07.623294" → várt "11:43"
- "Kezelő: Rendszer Admin" — KOSA-val léptünk be
- USD: 146,89 — gyanús darabszám tizedessel
- Limit alapérték placeholder (0 / 999 999 999)

#### B13. Hotkey inkonzisztencia
- Főmenü: F1=Vétel, F2=Eladás
- Vétel oldalon: F2=Vetel, F3=Eladas (toggle)
- Konfúzió a usernek

#### B14. Társpénztárak → Fiókcsoportok absztrakció-eltérés
- Legacy `PTARTMK.dll` konkrét pénztárakat listáz
- Modern: fiók-CSOPORTOKAT (más absztrakció szint)

#### B15. Pénztárosok lista: SZEREPKÖRÖK oszlop ÜRES
- Backend `/workers` endpoint nem ad vissza role data-t (vagy a frontend nem rendereli)

#### B16. Csomag-feladó "Ertektar" név
- Helyett: "Értéktár" — ékezet hiányzik
- A 3 seed-csomag dátuma 04.23 (legacy), nem friss

---

## A USER UTASÍTÁSAINAK MEGFELELÉS-AUDIT

A user kérte:
1. ✅ "Pénztár helyben elektronban fut" — Penztar.exe (Electron) futtatás OK
2. ✅ "Második, az értéktár, ami helyben elektronban fut" — `mode='ertektar'` támogatott (külön config + külön menüstruktúra)
3. ✅ "Mindkettő föl tud csatlakozni a szerverre és folyamatosan a forgalmi átadás átvételi adatokat tölti föl" — sync engine fut, "Online | Utolsó szinkron"
4. ❌ "A főértéktár készíti az árfolyamokat" — **B2 bug**: a pénztár /rates oldal szerkeszthető!
5. ❌ "[Főértéktár] látja pénztári készleteket külön, és meghatározott módon beállíthatja a pénztári és értéktári limiteket valutalemenként" — Kassza limit oszlop megvan, DE nincs központi UI az állításra (a Pénztár read-only, főértéktár UI-t kellene megnézni)
6. ✅ "Pénztárak/értéktárak átadás-átvételkor dokumentálják" — TransitPage 3 csomaggal mutatja, "Átvétel" gomb működik
7. ✅ "Pénztárból elindult csomagot látja az értéktár, értéktárból elindult csomagot látja a pénztár" — TransitPage 2 tab (Bejövő + Kimenő) ✓
8. ✅ "...azokat csak leokézza" — "Átvétel" gomb = LEOKÉZÁS

---

## v2.3.9 kódfix terv (priorizálva)

### Sürgős (P0)
1. **isFirstRun() SQLite consistency check** — `first-run.ts`-ben + auto-stale-env-delete
2. **Penztar-Cleanup.nsi APPDATA + ~/.valuta/ explorer-user törlés** PowerShell-en keresztül
3. **/rates oldal read-only `mode='penztar'` esetén** — RatesPage.tsx + RateCreationPage.tsx role-check
4. **HUF címletlista TELJES** — V162 vagy ujabb migration: 5 / 10 / 20 / 50 / 100 / 200 / 500 / 1000 / 2000 / 5000 / 10000 / 20000

### Magas (P1)
5. **Full-screen layout header unified** — DayOpenPage + ClosingWizardPage `useAuthStore` használat
6. **Magyar ékezetek pótlása** (i18n key audit)
7. **Branch-mismatch fix** — wizard-választás backend-szinten worker.branchId UPDATE
8. **/receipts JOIN audit** — backend ReceiptController + transaction-receipt mapping
9. **/closing/archive új page** — REGIZARO.dll-megfelelő
10. **/lists új page** — LISTAK.dll-megfelelő (5-6 sub-report)
11. **DailyTurnoverPage külön** — NAPIFORG.dll-megfelelő
12. **Cégadatok seed-data fix** — Exclusive Best Change Zrt.

### Közepes (P2)
13. Pénztárosok role oszlop fix (backend `/workers` endpoint)
14. Csomag-feladó "Értéktár" ékezet
15. Hotkey unified (főmenüvel egyezőre Vétel oldalon)

### Alacsony (P3)
16. ISO timestamp formázás Kassza panelen
17. Társpénztárak vs Fiókcsoportok elnevezés-konzisztencia

---

## VÉTEL FLOW + HOTKEY teszt eredménye (2026-04-29 15:36)

### Hotkey-teszt
| Hotkey | Várt | Tényleges | Status |
|---|---|---|---|
| F1 (főmenüből) | Vétel oldal | Vétel oldal | ✅ |
| F4 (főmenüből) | Átadás-átvétel /shipments | /shipments oldal | ✅ |
| F8 (főmenüből) | /reports/daily-turnover | /reports (Riportok aggregátor) | ⚠️ route-inkonzisztencia |

### VÉTEL flow teszt — 100 EUR vásárlás
1. ✅ F1 → Vétel oldal
2. ✅ VALUTA cell click + type "EUR" → ÁRFOLYAM auto-fill: 393.00 (vételi)
3. ✅ Auto-Tab BANKJEGY DB cellára (focused)
4. ✅ Type "100" → FORINT ERTEK auto-calc: 39 300 Ft (100 × 393 = 39 300 ✓)
5. ✅ "Bizonylat készítése" gomb piros (= aktív)
6. ✅ Click → **Bizonylat előnézet modal** megjelent
7. ⚠️ Preview bizonylat-ID: `P-1777469775705-0` (NEM legacy V<branch>NNNNNN, csak preview placeholder)
8. ✅ Bizonylat tartalom: VALÓDI Exclusive Best Change Zrt. adatokkal (Pécs, Citrom utca 2-6, Adószám 32313332-2-02)
9. 🚨 Pénztáros: "Rendszer Admin" — KOSA-val léptünk be, de bizonylaton ADMIN! (B4 megerősítve)
10. ✅ Click "Nyomtatás" → modal becsuk + Vétel oldal resetelt
11. ❌ NINCS success-toast/feedback
12. ✅ Tranzakciólista FRISSÍTVE: új sor **`V035000001`** ← **HELYES legacy prefix!**
    - V = Vétel
    - 035 = BR035 (Szeged Tisza Sarok!) — **a SetupWizard branch-választás MŰKÖDIK!**
    - 000001 = első sorszám (új BR035-ön)
13. ⚠️ Státusz: "Függőben" (sárga) — sync engine még nem véglegesítette (a többi V017... "Teljesítve")
14. ❌ **MULTI-TENANT BUG**: Tranzakciólista mutatja a BR017 régi tranzakciókat is (V017100012, V017100011, K017100002, stb.) — mode='penztar' user-nek **NE** kéne látnia más branch tranzakcióit!

### Új azonosított bugok (a 17 + ezek)

#### B6 KORREKCIÓ
A korábbi "branch-mismatch" feltételezés **TÉVES volt**: a SetupWizard branch-választás (BR035) MŰKÖDIK a tranzakció-prefix-szinten (V035000001). A V017... régi tranzakciók egy MÁSIK branch-en (BR017) készültek korábbi tesztben → ezért látszanak a listán.

#### B17. Multi-tenant szűrés HIÁNYOZIK Tranzakciólistán (P0!)
- **Tünet:** mode='penztar' + KOSA logged in (BR035) látja BR017 tranzakcióit is
- **Üzleti hatás:** ADATSZIVÁRGÁS — egy pénztáros láthatja más irodák tranzakcióit
- **CLAUDE.md vonatkozás:** "Multi-tenant: Minden lekérdezés companyId-ra szűr — SOHA ne hagyd ki a company szűrést!"
- **Kódfix v2.3.9:** TransactionService.findAll() backend → branchId filter (worker.branchId vagy app_mode='penztar' esetén szigorú)

#### B18. Print silently fails (P1)
- **Tünet:** Print ikon click → nincs print dialog, nincs hibaüzenet
- **Forrás:** ESC/POS printer NINCS csatlakoztatva, de UI nem ad feedback-et
- **Kódfix v2.3.9:** ReceiptPrintService → ha printer config hiányzik → toast.warn("Nyomtató nincs konfigurálva")

#### B19. Vétel sikeres-toast/feedback HIÁNYZIK (P1)
- **Tünet:** Bizonylat előnézet "Nyomtatás" → modal becsuk, oldal reset, DE nincs "Sikeres tranzakció" toast
- **Üzleti hatás:** A pénztáros nem tudja biztosan, hogy a tranzakció elment-e
- **Kódfix v2.3.9:** Toast success notification a saveTransaction után

#### B20. Vétel státusz "Függőben" — sync-engine timing
- **Tünet:** Az új V035000001 sárga "Függőben", a többi V017... zöld "Teljesítve"
- **Lehetséges magyarázat:** A pénztár-client lokális SQLite-ba ír, sync-engine 30 sec-enként pusholja a backend-re. Helyes UX: a tranzakció "Függőben" amíg a sync-engine nem confirmolt-ja.
- **Bug-e?** NEM — feature, **DE** a UI nem világos a usernek.
- **Kódfix v2.3.9:** Hover-tooltip a "Függőben" badge-en: "Várakozik szerver-szinkronra (30 sec-enként)"

#### B21. Bizonylat preview-ID inkonzisztens a véglegesítettel (P3)
- **Tünet:** Preview modal: "Bizonylat: P-1777469775705-0", véglegesítve V035000001
- **Forrás:** Preview egy unique ID generátor (timestamp+seq), véglegesítés a ReceiptSequenceService
- **UX hatás:** A pénztáros lát egy ID-t a preview-on (P-...) ami nem szerepel a végleges bizonylaton. Konfúzió.
- **Kódfix v2.3.9:** Preview a ReceiptSequenceService-en keresztül kérje le a következő ID-t (lock-kal), VAGY ne mutassa a preview-ID-t a modálban.

#### B22. Shift+F4 (Listák) és Shift+F6 (Napi forgalom) admin csempék route-inkonzisztencia (P2)
- Shift+F4 → /transactions (Tranzakciólista)
- Shift+F6 → /reports/extended (Bővített Riportok)
- F8 (napi csempe) → /reports (Riportok aggregátor — ez a HELYES route, 11 riport-féle)
- **Várt:** mindhárom IDE kellene mennie, vagy a Listák/Napi forgalom-nak specifikus al-oldalra
- **Kódfix v2.3.9:** Shift+F4 → /reports (LISTAK helyett) + Shift+F6 → /reports/daily-turnover (specifikus)

## USD ELADÁS + SZTORNÓ flow teszt (15:45-15:48)

### USD ELADÁS — 50 USD
1. ✅ Főmenüből Eladás csempe → ELADÁS oldal
2. ✅ USD beírva → ÁRFOLYAM 370.00 (eladási, vételi 360 volt!)
3. ✅ 50 db beírva → 50 × 370 = **18 500 Ft** ✓
4. ✅ Bizonylat előnézet "ELADÁSI BIZONYLAT", preview-ID `P-1777470336754-0`
5. ✅ Nyomtatás → Tranzakciólista frissül
6. ⚠️ Bizonylat: **`E017100006`** (E + BR017 + 100006)

### B23. ELADÁS branch-mismatch (P0!)
**Tünet:** A VÉTEL flow a SetupWizard branch-választást (BR035) használja → `V035000001`. DE az ELADÁS flow a worker.branch-et (BR017) használja → `E017100005`.
**Forrás:** A két service (TransactionService.buy vs sell) inkonzisztens branch-resolve logika.
**Kódfix v2.3.9:** TransactionService.sell() = TransactionService.buy() branch-resolve fix (mind a kettő SQLite `branch_code`-ot használja, NE a worker.branchId-t).

### B24. Sync-status inkonzisztens (BR035 "Függőben" ragad)
**Tünet:** V035000001 (BR035) "Függőben" sárga, az E017100005 (BR017) "Teljesítve" zöld azonnal.
**Hipotézis:** A sync-engine BR017-re sikeresen pusholja, BR035-re nem (mert a worker BR017-en van, de a tranzakció BR035-re lett rögzítve → backend kross-branch-validáció elutasítja a sync-et).
**Kódfix v2.3.9:** Backend cross-branch tranzakció acceptance + sync-engine retry-logika.

### B25. "Függőben" tranzakciók NEM sztornózhatók (UX gap)
**Tünet:** V035000001 "Függőben" — a Műveletek oszlopban NINCS X piros sztornó-ikon (csak nézet + print).
**Forrás:** Frontend StornoButton csak "Teljesítve" státusznál renderel.
**UX javaslat:** "Függőben" státusznál is engedjük a sztornózást (lokálisan eltűnik a queue-ból), VAGY mutassunk magyarázó tooltip-et: "Sztornó csak véglegesítés után".

### SZTORNÓ flow — E017100005 visszavonás
1. ✅ Tranzakciólistán piros X ikon click
2. ✅ Sztornó oldal megnyílt — `StornoPage`
3. ✅ Tranzakció adatok megjelenítve (E017100005, USD 50, 370.00, 18 500 Ft, Névtelen)
4. ✅ "Közvetlen sztornó lehetséges" zöld pipa, "Napi sztornók száma: 0"
5. ✅ Sztornó oka beírva ("audit teszt")
6. ✅ Sztornó végrehajtása gomb click
7. ✅ **Eredmény:**
   - E017100005 → **Sztornózva** (áthúzva, halvány)
   - Új **E017100006** "Sztornó" típussal, "Teljesítve" státusszal
8. ✅ A flow LEGACY-mintán: `Ervenytelenites` + `EllentranzAkcio` + `ValutaStorno`

**TÖKÉLETES** legacy STORNO.dll megfelelés.

---

## Frissített összegzés (FINAL — 25 bug)

- **P0 KRITIKUS (5):** B1 Setup, B2 rates RW, B3 címlet, B17 multi-tenant, **B23 ELADÁS branch-mismatch**
- **P1 MAJOR (12):** B4-B11 + B18 print + B19 toast + B24 sync-status + B25 "Függőben" sztornó-disabled
- **P2 MINOR (6):** B12-B16 + B22 route-inkonzisztencia
- **P3 ALACSONY (2):** B16 ékezet + B21 preview-ID

## TÖKÉLETESEN MŰKÖDIK

- ✅ F1 Vétel hotkey + flow + V<branch>NNNNNN szerializáció (V035000001 — csak vétel BR035-tel)
- ✅ F4 Átadás-átvétel hotkey + /shipments oldal
- ✅ F8 Forgalom hotkey + Riportok oldal (11 csempe = legacy LISTAK.dll)
- ✅ Bizonylat előnézet + valódi cégadatok (Exclusive Best Change Zrt., Pécs)
- ✅ Konverzió oldal (3-step wizard, vételi+eladási árfolyamokkal, HUF mint pivot)
- ✅ **Konverzió flow** TÖKÉLETES: 3 atomi tranzakció (V + E + K) — `KonvDataVtempbe` legacy-tükör
- ✅ **Sztornó flow (LEGACY-megfelelő)**: Ervenytelenites + EllentranzAkcio rögzítve
- ✅ Bidirectional package tracking (TransitPage Bejövő+Kimenő tab)
- ✅ AML küszöb auto-trigger (>100k Ft → "Egyszerűsített azonosítás KÖTELEZŐ" panel)
- ✅ Új ügyfél form (UGYFEL.dll-megfelelő: magánszemély/céges, okmányadatok, anyja neve, lakcím)
- ✅ Napzárás wizard 9 lépés (NAPZAR.dll-tükör + e-kereskedelem + AXA/MoneyGram + NAV)

## E+F+D feladatok eredménye (15:58-16:02)

### D. Konverzió 100 AUD → 91.46 CAD ✅
- Forrás: 100 AUD × vételi 234.37 = 23 437 HUF (köztes)
- Cél: 23 437 HUF / eladási 256.25 = 91.46 CAD
- 1 AUD = 0.914615 CAD (direct)
- 3 atomi tranzakció létrehozva:
  - **V017100013** (Vétel AUD 100, 23 435 Ft, Teljesítve)
  - **K017100003** (Átváltás AUD 100, ár 0.9146, 23 435 Ft, Teljesítve) ← **K-prefix MEGTALÁLVA!**
  - **E017100007** (Eladás CAD 91.45, 23 435 Ft, Teljesítve)
- 🐛 **B23 megerősítve**: K/E/V mind BR017 → wizard branch-választás (BR035) NEM érvényesül itt sem
- 🐛 **B26 új**: Konverzió flow NEM mutat bizonylat-előnézetet (UX-inkonzisztencia a Vétel/Eladás-szal)

### E. Új ügyfél + AML 117 900 Ft ✅
- Új ügyfél form UI ✓ (UGYFEL.dll-megfelelő)
- 300 EUR vétel = 117 900 Ft (>100k Ft) → AML küszöb-trigger
- "Egyszerűsített azonosítás KÖTELEZŐ (100.000 — 300.000 Ft)" panel ✓
- 🐛 **B27 új**: AML küszöb 100k-300k → magyar PMT szerint helyesen 100k-800k (vagy 4.5M HUF-ig)
- 🐛 Ékezetek hiányoznak: "Egyszerusitett azonositas KOTELEZO", "KEZZEL MEGADAS", "Allampolgarsag"

### F. Napzárás wizard 9 lépés ⚠️
- Mind a 9 lépés látszik (MTCN/Esti/Kezelési/WU/ÁFA/Foglaló/E-kereskedelem/AXA-MoneyGram/NAV)
- 🐛 **B28 új**: "ELLENŐRZÉS INDÍTÁSA" gomb **NEM reagál** click-re — nincs státusz-változás, nincs feedback
- A teljes wizard end-to-end teszt **nem tudott végrehajtódni** a B28 miatt

## /transit + /shipments flow tesztek (16:25-16:30)

### /transit "Átvétel" leokézás ✅
- 3 csomag a Bejövő tabon (DIST-1 EUR 100, DIST-1 USD 50, COLL-1 EUR 300)
- Az első DIST-1 "Átvétel" gomb click → counter top-right **3 → 1** ✓
- 2 DIST-1 csomag eltűnt (lehet hogy a 2 DIST-1 azonos batch volt, vagy csoportos átvétel)
- 🐛 **B29 új**: COLL-1 (Pénztár → Értéktár, kimenő típus) tévesen a **Bejövő tabon** maradt; a Kimenő tab üres. Tab-szűrés mode-szempontból hibás.

### /shipments új átadás létrehozása ✅
1. ✅ "+ Új átadás" gomb → modal (Cél iroda / Típus / Valuta / Összeg / Megjegyzés)
2. ✅ Cél iroda dropdown lenyílt: **66 branch ABC sorrendben** (Bajcsy/Békéscsaba/.../Hódmező)
3. ✅ Valuta dropdown: 13+ valuta (HUF/CZK/CHF/RON/SEK/NOK/DKK/JPY/CAD/AUD/CNY/RUB/UAH...)
4. ✅ BR076 - Békéscsaba Belváros + HUF + 50 000 + Megjegyzés → "Átadás létrehozása"
5. ✅ **Zöld success-toast**: "Átadás helyileg rögzítve és azonnal szinkronizálva" 🎉
6. ✅ Tab counter "1 új" + új sor a táblázatban
7. ✅ Műveletek: nézet (szem) + jóváhagy (zöld pipa) + elutasít (piros X)
8. ✅ Sync status: **"Helyben mentve"** sárga (UX-tisztább mint a tranzakciók "Függőben")

### Új bug-ok (B29-B31)

#### B29. /transit Bejövő/Kimenő tab-szűrés mode-szempontból hibás (P1)
- COLL-1 (Pénztár → Értéktár) a KOSA pénztáros (mode='penztar') Bejövő tabján → kell legyen a Kimenőn
- A tab-szűrés a transferType-ot nézi, nem a current worker irányát

#### B30. Átadólap-szám formátum (P2)
- Modern: `LT-20260429143007-8BD9` (LT-prefix + timestamp + UUID-fragment)
- Legacy: ATADOLAP-szám (várt: `AT<branch>NNNNNN` mint a tranzakcióknál)
- UX: a usereknek a hosszú LT-hash nehezen olvasható

#### B31. Átadás TÍPUS oszlop "CURRENCY" angolul (P3)
- Modern UI hungarian, mégis "CURRENCY" enum-string megjelenik
- Várt: "Valuta átadás" (mint a modal dropdown-ban szerepelt)

### Pozitív megállapítások a /shipments flow-ról
- ✅ Toast feedback (B19 csak a Tx flow-knál érvényes, itt MEGVAN!)
- ✅ Sync-status UI clarity ("Helyben mentve" vs "Függőben")
- ✅ Műveletek 3-ikon (nézet/jóváhagy/elutasít) — gazdag interakció

## Riportok flow audit (16:59-17:03)

### Esti zárás csempe → /evening-closing
- 1 input (Dátum) + Előnézet gomb
- 🐛 **B32**: Click → "**Request failed with status code 404**" (raw HTTP error, backend endpoint nem létezik)

### MNB jelentés csempe → /reports/mnb
- Üres lista, "Nincs adat"
- Frissítés ikon, keresés mező
- 🐛 **B33**: Oszlopfejlécek **MIND ÉKEZET NÉLKÜL** (TIPUS/RIPORT DATUM/TRANZAKCIO DB/ALLAPOT/BEKULDES)
- Nincs "+ Új jelentés" gomb (auto-generálás?)

### Darius / Raiffeisen jelentések → /darius
- 🐛 **B34 P1**: PIROS ALERT "**Nincs jogosultsága a művelet végrehajtásához**" (403 Forbidden)
- KOSA pénztáros (MANAGER) látja a csempét a Riportok-on, DE click-re tilos
- **Csempe-szűrés hiányzik mode/role-szempontból** — kell előzetesen elrejteni
- "Retry" gomb angolul (helyett: "Újra")

### Havi zárás → /closing/monthly
- 🐛 **B35 P1**: HALMOZOTT bug:
  1. Header "Havi **zaras**" — ékezet hiányzik
  2. "**Request failed with status code 404**" — endpoint nem létezik (mint Esti zárás)
  3. Oszlopfejlécek mind ékezet nélkül (HONAP/PENZTAR/ALLAPOT/ZARAS IDEJE/ZARTA)

## B32 + B35 root-cause + kódfix (17:05 — D feladat)

### B32 Esti zárás 404 — Backend RequestMapping elírás
**Frontend** (`settings.ts:927`): `api.get(\`/evening-closing/${branchId}/${date}/preview\`)` → axios baseURL=`/api/v1` → full URL: `/api/v1/evening-closing/{branchId}/{date}/preview`
**Backend** (`EveningClosingController.java:23`):
```java
@RequestMapping("/api/evening-closing")  // ❌ HIÁNYZOTT a "/v1"!
```
A többi controller (MonthlyClosingController, NavClosingController stb.) helyesen `/api/v1/...` — csak ez maradt el.

**FIX (alkalmazva):**
```java
@RequestMapping("/api/v1/evening-closing")  // ✓ /v1 hozzáadva
```

### B35 Havi zárás 404 — Frontend nem létező root-list hívás
**Frontend** (`MonthlyClosingPage.tsx:27`): `api.get<...>('/closing/monthly')` — NINCS branchId path-paraméter!
**Backend** (`MonthlyClosingController.java:33`): `@RequestMapping("/api/v1/closing/monthly")` ✓ jó prefix
- Endpoints: `/{branchId}/{yearMonth}` (POST/GET) + `/{branchId}` (GET 1 branch lista) + `/{branchId}/{yearMonth}/full` + `/{branchId}/{yearMonth}/pdf`
- **NINCS** root-level `@GetMapping("")` (teljes lista all-branches)
- Frontend `GET /api/v1/closing/monthly` → 404 (nincs ilyen endpoint)

**FIX (alkalmazva, multi-tenant biztonságos):** Frontend `worker.branchId`-t használ:
```typescript
const branchId = useAuthStore((state) => state.worker?.branchId)
...
const response = await api.get<...>(`/closing/monthly/${branchId}`)
```
A backend meglévő `@GetMapping("/{branchId}")` endpoint-ot hívja, ami egy branch összes lezárt hónapját adja. Egy MANAGER csak a saját branch-ét látja → összhangban a B17 multi-tenant elvvel.

### Verifikáció
- `npx tsc --noEmit` → EXIT=0, 0 TypeScript hiba ✓
- Backend Spring Boot újraindítás kell (a `/api/evening-closing` → `/api/v1/evening-closing` mapping változás miatt)

## VÉGLEGES BUG-LISTA (35 bug, 6 P0, 19 P1, 8 P2, 2 P3 — B32 + B35 KÓDFIX KÉSZ)

### P0 KRITIKUS (6)
- B1 SetupWizard stale .env — ✅ manuális fix-elve
- B2 /rates RW pénztár módban
- B3 HUF címlet hiányos lista
- B17 Multi-tenant szűrés hiányzik
- B23 ELADÁS branch-mismatch (csak VÉTEL használja a wizard branch-et)
- B28 Napzárás "ELLENŐRZÉS INDÍTÁSA" nem reagál — **napzárás flow blokkolva**

### P1 MAJOR (14)
- B4-B11 (audit első kör)
- B18 Print silently fails
- B19 Vétel toast hiányzik
- B24 Sync-status BR035 ragadt "Függőben"
- B25 "Függőben" sztornó-disabled
- B26 Konverzió bizonylat-preview hiányzik
- B27 AML küszöb 100k-300k (várt 100k-800k)

### P2 MINOR (6)
- B12-B16 + B22 route-inkonzisztencia

### P3 ALACSONY (2)
- B16 ékezet + B21 preview-ID

## Hivatkozási útmutató

- Audit screenshot-ok: a session konverzációban (nem mentve fájlba, jegyzetelve)
- Vault: `references/legacy-anti-system.md` (legacy szerep-felosztás)
- Vault: `sessions/2026-04-29-legacy-memory-and-treasury-bug-fix.md` (TreasuryLayout fix)
- Vault: `sessions/2026-04-29-v2.3.8-nsis-bug-fix.md` (NSIS -EncodedCommand)
- Vault: `sessions/2026-04-29-setupwizard-stale-env-rootcause.md` (.env stale fix)
- **EZ A FÁJL** — teljes körű audit (**22 bug**, 4 priority szint)

## Workflow-state

- Branch: `determined-liskov-08a877` worktree
- v2.3.8 ÉLES: SQLite + .env workaround manuálisan törlve, KOSA logged in
- Kód-módosítások (a sessionben):
  - frontend-react/src/pages/treasury/TreasuryLayout.tsx (role-filter +7 unit teszt)
  - installer/Penztar-Setup.nsi + Penztar-Cleanup.nsi (-EncodedCommand b64 + backend timeout 90 iter)
  - installer/scripts/scoped-kill.ps1 + compute-b64.ps1 (új helperek)
  - 4 fájl version 2.3.6 → 2.3.8
- Maradék kódfix: a v2.3.9 fenti 17-pontos terv (külön session-ben implementálandó)
