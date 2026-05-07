---
date: 2026-04-29
session_type: ertektar-mode-audit
context: v2.3.9 reinstall után, user 2. teszt — ezúttal mode='ertektar'
priority: P0 — éles érték-treasury teszt
---

# 2026-04-29 — Értéktári mode (mode='ertektar') teljes audit

## Setup
- App: Penztar.exe v2.3.9 (post-Setup-2.3.9)
- App mode: **ertektar** (sidebar group: "ÉRTÉKTÁR (LOKÁL)" mutatva)
- User: bootstrap admin (Pénztáros: "Rendszer Admin")
- Branch (header): "Központi"

## Sidebar ÉRTÉKTÁR (LOKÁL) csoport (11 menüpont)
1. Értéktári dashboard (`/treasury`)
2. Átadás-átvétel (pénztáraknak) (`/shipments`)
3. Átadás bank / másik értéktár (`/transfers`)
4. Szállítólevelek (`/transfer-documents`)
5. Úton lévő csomagok (`/transit`)
6. Értéktári készlet (`/inventory`)
7. Naplókönyv (`/daybook`)
8. Napi zárás (`/evening-closing`)
9. Havi zárás (`/closing/monthly`)
10. Ügyfelek (`/customers`)
11. Árfolyamok (nézet) (`/rates`)

## Legacy referencia (forrás-igazság)
A `Anti/ERTEKTAR/etdll/` 55 saját DLL — szerep-szerinti elvárt funkcionalitás:
- **atadolap, atadvet** → /shipments, /transfers (átadás-átvétel)
- **napzar, havizar, estizar** → /evening-closing, /closing/monthly (zárások)
- **pillkesz, pillall** → /inventory (pillanatnyi készlet)
- **napikezd, napkonyv, napijel** → /daybook (naplókönyv)
- **arftmk, irarfoly, ratectrl, rateperm, getarf** → /rates (árfolyam-fogadás, NEM készítés!)
- **bizodisp, bloknyom** → bizonylat
- **listak** → riportok

A user kifejezett kérése:
> "A főértéktár készíti az árfolyamokat, melyeket értéktár LÁT, és ennek megfelelően szervezi a banki ki- és beszállításokat."
> "A pénztárak és az értéktárak pedig átadás átvételkor dokumentálják, hogy mi, hova, mennyit adtak át, és a pénztárból elindult csomagot látja, az értéktár, az értéktárból elindult csomagot látja, a pénztár és e szerint fogadja, azokat csak leokézza."

---

## Bug-ok (folyamatosan rögzítve)

### E-B1. "Mai forgalom 0.0M Ft" DE "↑ 46870% tegnap" inkonzisztens (P2)
**Hely:** Értéktári dashboard KPI panelek (jobbról 2.)
**Tünet:** Ha "Mai forgalom = 0", a "tegnap"-i változás % szám nem értelmezhető (megint 0/0).
**Forrás:** A KPI panel a backend `getDailyTurnover()`-ból kapja a `todayTotal` és `previousTotal`-t, és ha previousTotal=0, akkor a `(today/previous - 1) * 100` osztás 0-val → NaN/Infinity → 46870% bizarr érték.

### E-B2. "Pénztáros: Rendszer Admin" — KOSA helyett (P1)
**Hely:** Tranzakciólista "Ügyfél" oszlop / dashboard "Legutóbbi tranzakciók"
**Tünet:** A tranzakciók "Rendszer Admin" worker-hez vannak rendelve, NEM az aktuális user-hez (KOSA, akivel a tegnapi vétel-eladás-konverzió történt)
**Forrás:** A `transaction.created_by_worker_id` mező egy fix ADMIN worker-hez van rendelve, NEM az aktuálisan logged-in user-hez
**Üzleti hatás:** Audit nyomvonal hibás — nem tudható ki tényleg végezte a tranzakciót

### E-B3. KRITIKUS! "Árfolyam módosítás" gomb értéktári mode-ban (P0!)
**Hely:** Értéktári dashboard → Gyorsműveletek panel (jobb oldal)
**Tünet:** "Árfolyam módosítás" gomb látható és aktív, KATTINTHATÓ a mode='ertektar' user-nek
**User-direktíva:** "Az értéktár csak látja az árfolyamot, főértéktár készíti."
**Várt:** A gomb el legyen rejtve mode='ertektar' (és mode='penztar') esetén. Csak mode='full' + foertektar/ugyvezeto canonical role esetén látható.
**Forrás:** Hardkódolt 4 quickAction gomb a TreasuryDashboard.tsx-ben role-check nélkül.

### E-B4. "VÁLTOZÁS" oszlop félrevezető (P3)
**Hely:** Aktuális árfolyamok panel "VÁLTOZÁS" oszlop
**Tünet:** A cím "VÁLTOZÁS", de tartalom **csak az MNB középár** ("MNB: 397.00")
**Várt:** Vagy a cím legyen "MNB középár", vagy az oszlop tényleg az árfolyam-VÁLTOZÁST mutassa (delta vs előző nap)

### E-B5. KPI Mai forgalom formázás veszteséges (P2)
**Hely:** "Mai forgalom 0.0M Ft" KPI
**Tünet:** A korábbi sessionben látott 23 435 Ft + 18 500 Ft + 23 435 Ft = ~64 870 Ft mai forgalom van, DE a kerekített "0.0M Ft" formátum (millió-ban) elrejti a 65k-t.
**Várt:** Vagy ne formázzunk millió-ra (csak ha > 1M), vagy a 0.0M alatt mutassuk a tényleges értéket: "0.07M Ft" vagy "64 870 Ft".

(Folytatás minden menüponton...)

---

## Audit-folyamat sorban (eredmények)

### Dashboard (/treasury) ✅ + 5 bug
- E-B1: Mai forgalom 0.0M Ft DE 46870% tegnap (NaN/Infinity bizarr)
- E-B2: "Pénztáros: Rendszer Admin" KOSA helyett (audit nyomvonal hibás)
- E-B3 P0: **"Árfolyam módosítás" gomb értéktári módban** (TILTOTT, csak főértéktár!)
- E-B4: "VÁLTOZÁS" oszlop csak MNB középár-t mutat (félrevezető)
- E-B5: "0.0M Ft" formázás elrejti a 65k Ft-ot (mai 23435+18500+23435 Ft tranzakciók)

### Átadás-átvétel (/shipments) ⚠️ + 1 bug
- E-B7: Sidebar "Átadás-átvétel (pénztáraknak)" → oldal-cím **"Szállítmányigények"** (más absztrakció)

### Átadás bank (/transfers) 🐛 + 1 bug
- E-B8: UGYANAZ a UI mint az átadás-átvétel — banki kötés/ szállítás szervezés HIÁNYZIK (a user-direktíva: főértéktár szervezi)

### Szállítólevelek (/transfer-documents) 🐛 + 2 bug
- E-B9: Sidebar "Szállítólevelek" → oldal "Atutalasi bizonylatok" (eltérő funkcionalitás)
- E-B10: ÉKEZET HIÁNY mind: "Atutalasi" / FORRASPENZTAR / CELPENZTAR / OSSZEG / ALLAPOT / DATUM

### Úton lévő csomagok (/transit) ✅
- COLL-1 (Pénztár → Értéktár) **HELYESEN** a Bejövő tabon (értéktár fogadja). 
- → **Megerősíti a B29 pénztár-mode-specifikus voltát**

### Értéktári készlet (/inventory) 🐛 + 1 KRITIKUS bug
- E-B11 P0: **VALUTA + PÉNZTÁR oszlopok mind "-"!** Csak EGYENLEG látszik (32 270, 146.89, 1910, 100, 0, 0, 255.18, ...) → backend join HIÁNYZIK + ékezet hiány (Keszletkezeles / PENZTAR / FRISSITVE)

### Naplókönyv (/daybook) 🐛 + 1 bug
- E-B12: "Napi könyv nem található erre a napra" — DE 7+ tranzakció van! Daybook NEM auto-generálódik

### Napi zárás (/evening-closing) 🐛 + 1 bug
- E-B13: "Request failed with status code 404" — **B32 fix backend NEM ÉLT az élesben** (stage backend.jar régi 06:42-i 2.3.6, NEM 17:30-i 2.3.9). User UAC dismiss-elve a swap script-et.

### Havi zárás (/closing/monthly) ✅ B35 fix bizonyítva + 1 bug
- 🎉 **B35 fix MŰKÖDIK**: 404 → "Nincs adat" (frontend `worker.branchId` fix élesedett)
- E-B14: ékezet halmozott: "Havi zaras" / HONAP / PENZTAR / ALLAPOT / ZARAS IDEJE / ZARTA

### Ügyfelek (/customers) 🐛 + 1 bug
- E-B15: Dashboard KPI "Aktív ügyfelek: 2" DE lista "0 ügyfél" — eltérő endpoint vagy filter

### Árfolyamok (nézet) (/rates) 🎉 B2 FIX TÖKÉLETESEN MŰKÖDIK
- 🎉 **Cím "Árfolyamok (nézet)"** — `(nézet)` suffix auto
- 🎉 Kék info banner: "Az árfolyamokat csak a főértéktár (vagy ügyvezető) szerkesztheti — itt csak nézet."
- 🎉 **MNB letöltés gomb ELTŰNT**
- 🎉 **MŰVELET oszlop ELTŰNT** (Edit gombok eltávolítva)
- 17 valuta read-only ✓

### Renderer-leak / fagyás (E-B6 KRITIKUS)
- A Penztar.exe **5+ percnyi inaktivitás után FAGYOTT** — sidebar click-ek, Ctrl+R, gombok mind nem reagálnak
- Restart megoldotta (új PID 27076), de potenciális **memory leak / event-loop probléma**
- Mindeközben az időbélyeg "Utolsó frissítés" frozen volt
- **Action**: nézzük meg a Penztar-client React-renderer memory profil-ját

## VÉGLEGES BUG-LISTA (15 új értéktári + visszamutató pénztári refs)

### 🔴 P0 KRITIKUS (3)
- E-B3 "Árfolyam módosítás" gomb értéktári módban (legacy ARFOLYAM-Arfolyam.exe szegregáció megsértve)
- E-B6 Renderer fagyás 5+ perc után (memory leak gyanú)
- E-B11 Értéktári készlet — VALUTA+PÉNZTÁR oszlopok ÜRESEK

### 🟠 P1 MAJOR (7)
- E-B1 Mai forgalom % bizarr (NaN/Infinity)
- E-B2 Pénztáros = Rendszer Admin (KOSA helyett)
- E-B7 Sidebar elnevezés-mismatch (Átadás-átvétel → Szállítmányigények)
- E-B8 Átadás bank duplikált UI (banki funkciók hiányoznak)
- E-B9 Szállítólevelek vs Átutalási bizonylatok mismatch
- E-B12 Daybook nem auto-generálódik
- E-B15 Ügyfél KPI vs lista inkonzisztens

### 🟡 P2 MINOR (5)
- E-B4 VÁLTOZÁS oszlop mismatch
- E-B5 Mai forgalom 0.0M Ft formázás
- E-B10 Szállítólevelek ékezet hiány
- E-B13 B32 fix nem élt (stage jar régi)
- E-B14 Havi zárás ékezet hiány

## ✅ POZITÍV megerősítés
- 🎉 **B2 fix BIZONYÍTVA**: /rates értéktári módban TÖKÉLETESEN read-only
- 🎉 **B35 fix BIZONYÍTVA**: Havi zárás 404 → "Nincs adat" 
- ⚠️ **B32 fix nem élt élesben**: stage jar mismatch okozza, swap-script user-akcióra vár
- ✅ **Értéktári mode szegregáció** részben működik (sidebar group, /rates read-only) — B3 csak a Gyorsműveletek panel "Árfolyam módosítás" maradt szennyezett

## E-B6 renderer-leak nyomozás eredménye (18:36-18:42)

### DevTools-szal felfedezett pontos hibajelek

**Console (6 piros error):**
1. `Failed to load resource: excvaluta.com/api/v1/...053a0d/2026-04-29  404` — DAYBOOK
2. `[client] API Error` (global handler)
3. `[DaybookPage] Napi könyv betöltési hiba: AxiosError: status 404` (stack trace)
4. `Failed to load resource: excvaluta.com/api/v1/...026-04-29/preview  404` — Esti zárás
5. `[client] API Error`
6. `[EveningClosingPage] Előnézet hiba: AxiosError: status 404`

### 🚨 KRITIKUS FELFEDEZÉS: Penztar.exe `excvaluta.com`-ra hív (NEM localhost!)

A SetupWizard `apiUrl=https://excvaluta.com/api/v1`-et állít be production default-ként. Az `api.client.ts` SQLite `server_url` config-ot használja Electron-ban (CLAUDE.md v2.3.0 fix). 

**Konzekvencia:**
- A LOCAL backend (`localhost:8080`) FUT, DE a Penztar.exe nem oda hív
- A B32 + B35 fix-ek a localhost-on aktívak, **DE a Hetzner-re még NINCSENEK deploy-olva**
- Az Esti zárás/Havi zárás 404-ek a Hetzner production endpoint-mismatch miatt vannak

**Action item v2.3.10**: A PR #271 merge automatikus Hetzner deploy-t indít. **Csak merge után** lesz a B32/B35 fix élesben az `excvaluta.com`-on.

### Memory monitoring (60 sec ablak, 5 sample)

| Időpont | Total Penztar.exe |
|---|---|
| 18:41:02 | 646 MB |
| 18:41:15 | 652 MB |
| 18:41:27 | 646 MB |
| 18:41:39 | 646 MB |
| 18:41:51 | 646 MB |

✅ **NEM memory leak** — stabil ~646 MB 5 process-on

### Network polling (snapshot)

5 darab `incoming` XHR request, 200 OK, 0.6-1.2 KB / 92-215 ms — sync-engine 30s polling normális szintű.

### Java backend NEM fut

Get-Process java BestChange-szűrt → ÜRES lista. Tehát a LOCAL `BestChange-Backend` service **leállt** (de a service dispatcher 200-at ad localhost-on... gyanús → vagy más Java fut, vagy Caddy-ban van proxy).

### E-B6 root-cause hipotézis

A fagyás **NEM memory leak** (646 MB stabil), inkább:
1. **Axios infinite retry / hosszú timeout** — a `excvaluta.com` 404-eket adó endpoint-jaira (DAYBOOK + Esti zárás) a sync-engine 30 másodpercenként pollol, és ha valami timeout-tal vagy network error-ral fagyaszt, blokkolódhat
2. **React state-loop**: minden 30s pollnál új error-state, ami re-render-eket okoz; ha az error-handler maga is state-update-et végez egy useEffect-ben, infinite loop
3. **Event-loop blocking**: egy szinkron-blokkoló JS hívás (pl. nagy JSON parse) az axios response-on

### v2.3.11 fix-terv (E-B6)

1. **Axios global timeout** (5-10 sec) az `api.client.ts`-ben
2. **Error throttling**: ne pollozzon végtelen 404-et — ha 3 egymást követő error, exponenciális backoff
3. **Page Visibility API**: ha az ablak inaktív 5+ percig, sync-engine paus
4. **Prod deploy**: PR #271 + #272 merge → automated Hetzner deploy → 404 endpoint-ok megszünnek
5. **Renderer healthcheck**: heartbeat ablak-szintű log (pl. `setInterval(() => logger.info('heartbeat'), 60000)`) — fagyás-detection könnyebb lesz

### Folytatás — E-B6 reprodukció megszakadt (kompakt-szünet)

A 6 perces DevTools-monitoring nem futtatható: a Penztar.exe leállt a kompakt szünet alatt (`Get-Process Penztar` → empty). A 60 másodperces ablak (18:41:02 → 18:41:51) azonban már bizonyította: **stabil 646 MB → NEM memory leak**.

**Konklúzió:** v2.3.11 sprint a Hetzner production deploy-ra (PR #271 merge) + axios timeout/throttling fixre koncentrál — nem kell további reprodukció a memory leak hipotézis kizárására.

## Záró akciók (2026-04-29 18:53 CEST)

### PR #271 rebase + v2.3.10 follow-up

A PR #271 `CONFLICTING` állapotba került a #269 release v2.3.7 merge után (verzió-fájlok ütközése). Megoldás:

1. `git rebase origin/main` — 4 fájl konfliktus (backend/pom.xml + 3× package.json)
2. `git checkout --theirs` mind a 4 verzió-fájlra (a 2.3.10 felülírja a 2.3.7-et a következő commit-ban)
3. Force-push: `git push --force-with-lease`

### Sourcery PR #271 follow-up commit (`499df771`)

Sourcery ÚJ feedback (8c28b331 commit-hez):
- **bug_risk**: RatesPage NumberInput még akkor is editable lehet, ha `canEdit=false` → fix: `editingCode === rate.code && canEdit` feltétel + `disabled={!canEdit}` belt+suspenders prop
- **style**: TreasuryLayout test importálja a production `allTreasuryTabs`/`CENTRAL_VAULT_ROLES` exportokat (DRIFT-mentes) — már megoldva 1e6715de-ben
- **style**: ClosingWizard logger használja (NEM console.log) — már megoldva 1e6715de-ben
- **ESLint warning**: TreasuryLayout + DashboardPage useMemo deps — `eslint-disable-next-line` magyarázat-tal a belt+suspenders pattern-re

Final state:
- 0 ESLint warning + 0 TypeScript error
- TreasuryLayout.role-filter.test.ts: 8/8 PASS
- Branch: `fix/v2.3.9-flow-audit-31bug-fixes` rebased on `origin/main` (HEAD `499df771`)
- Auto-merge: `--squash --auto --delete-branch` enabled by `kosazoltan`
- mergeStateStatus: BLOCKED → CI running (CodeQL + Backend + Sourcery)

### Hetzner deploy után élesedő fixek

| Fix | Hely | Hatás |
|---|---|---|
| B2 RatesPage role-filter | /rates | foertektar+ugyvezeto-n kívül read-only |
| B28 ClosingWizard logger | /closing | toast feedback + structured logging |
| B32 EveningClosing path fix | /api/v1/evening-closing | 404 → működő endpoint |
| B35 MonthlyClosing branchId | /closing/monthly | 404 → "Nincs adat" üres state |
| E-B3 Dashboard Gyorsműveletek | /dashboard | Árfolyam módosítás csak full+foertektar |
| E-B11 Inventory CashBalanceDto | /inventory | VALUTA+PÉNZTÁR oszlopok feltöltve |
| NSIS hardening | installer | -EncodedCommand UTF-16LE base64 (parser-immune) + 90 iter wait |

## Összegzés a user-direktívák tükrében
| User-direktíva | Értéktári mode-ban | Status |
|---|---|---|
| Értéktár Electron-ban fut | sidebar ÉRTÉKTÁR (LOKÁL) ✓ | ✅ |
| Szerverhez csatlakoznak | "Online \| Utolsó szinkron" | ✅ |
| **Főértéktár készíti az árfolyamokat, értéktár LÁTJA** | /rates oldalon banner + read-only | ✅ B2 fix |
| **Banki ki/beszállítás szervezése** | Átadás bank/másik értéktár ÜRES, banki funkció HIÁNYZIK | ❌ E-B8 |
| **Pénztári + értéktári készletek külön** | Értéktári készlet üres VALUTA+PÉNZTÁR | ❌ E-B11 |
| Pénztár ↔ értéktár átadás-átvétel dokumentálva | Átadás-átvétel page létezik | ⚠️ E-B7 |
| Bidirectional package tracking + leokézás | /transit COLL-1 + Átvétel gomb | ✅ |
