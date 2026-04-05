# Legacy Delphi 7 Forráskód Elemzés — Konszolidált Összesítő

## Dátum: 2026-04-05
## Forrás: `Anti\SZERVER\_extracted\` (1102 .pas, 1099 .dfm, 17 MB Delphi forráskód)
## Modern: `backend/` (1192 Java, 4.6 MB) + `frontend-react/` (209 fájl, 1.7 MB) + `penztar-client/` (28 fájl, 377 KB)

---

## 1. Az elemzések áttekintése

| # | Szerző | Fókusz | Fájl | Méret | Főbb eredmény |
|---|---|---|---|---|---|
| 1 | **Junior** | Architektúra & Üzleti Logika Gap | `junior-architecture-gap-analysis.md` | 22 KB | 24 gap azonosítva (4 CRITICAL), modulszintű összerendelés |
| 2 | **Eszter** | Kódminőség & Üzleti Teljesség | `eszter-code-quality-completeness-analysis.md` | 22 KB | 35 üzleti szabály elemezve: 28 kész (80%), 4 részleges, 3 hiányzik |
| 3 | **Tamás** | Funkcionális Lefedettség & Tesztelhetőség | `tamas-functional-coverage-analysis.md` | 57 KB | 105 use case: 58 KÉSZ, 31 RÉSZLEGES, 10 HIÁNYZIK, 6 NEM_RELEVÁNS |
| 4 | **Bence** | Biztonsági & Compliance | `bence-security-compliance-analysis.md` | 32 KB | 20 biztonsági kontroll, legacy KRITIKUS / modern KÖZEPES kockázat |
| 5 | **Nóra** | Üzleti Folyamat & UX | `nora-business-workflow-ux-analysis.md` | 6 KB | Napi workflow rekonstruálva, 10 DFM form, Electron javaslatok |

---

## 2. Konszolidált lefedettségi kép

### 2.1 Összesített számok

| Metrika | Érték |
|---|---|
| Legacy use case-ek (Tamás) | 105 |
| Modern KÉSZ | 58 (55%) |
| Modern RÉSZLEGES | 31 (30%) |
| Modern HIÁNYZIK | 10 (9%) |
| NEM_RELEVÁNS (technológiai eltérés) | 6 (6%) |
| Üzleti szabályok (Eszter) | 35 azonosítva, 28 megvan (80%) |
| Biztonsági kontrollok (Bence) | 20 elemezve, 13 modern MEGOLDOTT, 7 nyitott |
| Architektúra gap-ek (Junior) | 24 (4 CRITICAL, 9 HIGH, 8 MEDIUM, 3 LOW) |

### 2.2 Mi az, amit a modern rendszer JOBBAN csinál a legacy-nél

Ezek a területek, ahol a migráció egyértelmű fejlődést hozott:

| Terület | Legacy | Modern | Forrás |
|---|---|---|---|
| **SQL biztonság** | String-konkatenáció MINDENÜTT, chr(39) quoting, 0 paraméterezés | JPA parameterized queries | Bence K-01 |
| **Hálózat** | Plaintext TCP, hardcoded IP (185.43.207.99), Firebird port 3050 | HTTPS + JWT + CORS | Bence K-02, K-03 |
| **Hitelesítés** | Nincs API auth, DLL közvetlen DB elérés | JWT Bearer, role-based, multi-tenant izolált | Bence K-15, K-16 |
| **Árfolyam precízió** | INTEGER (fillér, 100-szoros) | BigDecimal, tier-based árazás | Eszter 5.2 |
| **Kerekítés** | Csak HUF 5 Ft-os | Valutaspecifikus precízió (EUR 0.01, CZK 0.1, stb.) | Eszter 5.1 |
| **Szankciós szűrés** | Batch ENSZ XML, manuális, csak név LIKE | Real-time fuzzy match (Levenshtein ≤2), okmányszám is | Bence K-04 |
| **Strukturálási detekció** | Nincs | 3+ tranzakció az ID limit 80-99%-a között → automatikus flag | Bence K-09 |
| **PEP kezelés** | Manuális byte flag | Automatikus jelölés + workflow | Bence K-10 |
| **Kamera biztonság** | 3 napos titkosítatlan fájlok | AES-256/GCM, hash-lánc, 50 napos retenció | Bence K-13 |
| **Multi-tenant** | Nincs (fizikailag külön FDB) | companyId-alapú logikai izoláció minden query-ben | Bence K-16 |
| **Audit trail** | Flat text log, manipulálható | Strukturált DB, AuditLogService | Bence K-07 |
| **AML reporting** | Excel export, manuális | DRAFT→SUBMITTED→ACKNOWLEDGED lifecycle | Bence K-14 |
| **UX** | Modális ablak minden művelethez, billentyűzet-centrikus | Dashboard, responsive, async, nem-modális | Nóra 3 |
| **Offline** | Teljes (lokális Firebird) | Részleges (localQueue, SQLite) | Nóra 5, Junior 5 |
| **Multi-site szinkron** | FTP-alapú, napi | Real-time REST API | Junior 5 |

### 2.3 Mi az, amit a legacy JOBBAN csinált

| Terület | Legacy erőssége | Modern hiányossága | Forrás |
|---|---|---|---|
| **Billentyűzetes navigáció** | TELJES: Tab, Enter, F-gombok, hotkey minden DLL-ben | RÉSZLEGES: Tab/Enter van, F-gombok hiányosak | Nóra 4 |
| **Offline működés** | TELJES: lokális Firebird, 0 latencia | RÉSZLEGES: localQueue, de szerverfüggő | Nóra 4 |
| **Hardware integráció** | Közvetlen nyomtató/scanner/kijelző/pénztárgép COM port | Electron bridge (részleges) | Nóra 4 |
| **Pénztáros napi workflow teljessége** | 20 év fejlesztés: teljes workflow napnyitástól havi zárásig | Néhány lépés (év-nyitó, speciális blokktípusok) hiányzik | Nóra 1, Tamás 9.2 |
| **DLL plugin modularitás** | ~110 DLL, jól definiált interfészek | Monolitikus SPA | Junior 5 |

---

## 3. Konszolidált CRITICAL gap-ek (minden elemző egyezik)

### C1 — Negyedéves göngyölési kontroll + 6 szintű kockázati besorolás
- **Legacy**: `BIGCTRL.DLL` → `GetTranztip` function, 0-6 szintű risk assessment
  - Szint 0: normál | 1: PEP | 2: külföldi | 3: 2× váltott 8M+ | 4: **negyedév 4 tranzakció 25M+** | 5: 10M+ egyszer | 6: 50M+
- **Modern**: `AmlService.java` — éves göngyölés van, de negyedéves kontroll és a teljes 6 szintű rendszer HIÁNYZIK
- **Kockázat**: Pmt. 6.§ felügyeleti bírság, engedélyvonás
- **Hivatkozás**: Eszter C1+C2, Junior G2, Tamás nem külön azonosította (a BIGCTRL a VALUTA DLL-ben)

### C2 — 8 napos (heti) göngyölési ablak
- **Legacy**: `BIGCTRL.DLL` → `_hetiforint`, `if _diff < 8 then _hasforint += _hetiforint`
- **Modern**: Csak napi limit (900K `DAILY_SUSPICIOUS_LIMIT`), heti/8 napos összesítés NINCS
- **Kockázat**: Smurfing (tranzakció-darabolás) felismerése nem teljes → Pmt. 6.§ (2)
- **Hivatkozás**: Eszter C3, Bence K-09 (structuring részben van, de az 8 napos ablak nem)

### C3 — Év-nyitó folyamat
- **Legacy**: `evnyito/`, `expevnyito/` (SZERVER), `ERTEKTAR/newyear/` — teljes éves nyitási workflow
- **Modern**: HIÁNYZIK teljesen — nincs `YearOpeningController`
- **Kockázat**: Első évfordulónál (2027-01-01) emergency, visszamenőleg nem pótolható
- **Hivatkozás**: Tamás G01+G10, Junior G-kategória

### C4 — Trade modul mélysége
- **Legacy**: `TRADE/` unit1-14, **295 KB** komplex kereskedési logika (ÁFA-s számla, könyvelés, matricaküldés, partnerek)
- **Modern**: `TradeService` + `TradeController` **~11 KB** — töredéke a legacy-nek
- **Kockázat**: Ha értéktári kereskedés aktív üzletág, a modern rendszer nem képes azt ellátni
- **Hivatkozás**: Junior G2, Tamás S43/S44/V03/V04

### C5 — Teljes blokknyomtatási lefedettség
- **Legacy**: 15+ blokktípus — natúr személy, jogi személy, storno, nyilatkozat, napkönyv (kétpéldányos), dekád, napzáró, WU, ÁFA
- **Modern**: `EscPosReceiptService` alapok megvannak, de jogi személy nyilatkozat, orosz nyilatkozat, storno blokk, kétpéldányos napkönyv HIÁNYZIK
- **Kockázat**: Jogszabályi dokumentáció hiány → felügyeleti bírság
- **Hivatkozás**: Tamás G03, Junior implicit

---

## 4. Konszolidált HIGH gap-ek

| # | Gap | Legacy | Modern állapot | Megjegyzik |
|---|---|---|---|---|
| H1 | **Jelenléti nyilvántartás** | `jelenlet/` + `idbeiro/` (munkaidő, Excel) | Entity létezik, nincs Controller/frontend | Tamás G02 — jogszabályi kötelezettség (HR) |
| H2 | **MoneyGram integráció** | `monegram/` (fájl-alapú adatcsere) | HIÁNYZIK teljesen | Junior G1, Tamás G05 — partnerség-függő |
| H3 | **Metro integráció** | `METRO/` DLL (73 KB) | HIÁNYZIK | Junior G5, Tamás G07 — partnerség-függő |
| H4 | **Tesco integráció** | `TESCO/` DLL (55 KB) | HIÁNYZIK | Junior G6, Tamás G07 — partnerség-függő |
| H5 | **WU teljes integráció** | `WUNION/` + `UGYFELTMK/WUNION/` + szerver modulok | Stub állapotban | Junior G9, Tamás V29 |
| H6 | **AML bejelentési határidő tracking** | Deadline van | 2 munkanapra automatikus OVERDUE + supervisor email HIÁNYZIK | Bence K-14, Eszter implicit |
| H7 | **Szankciós lista automatikus frissítés** | Manuális batch | Automatikus scheduler + timestamp tracking HIÁNYZIK | Bence K-04 |
| H8 | **Külföldi ügyfél USD korlátozás** | `BIGCTRL.DLL` → `UsdAdhato` function | Modern kódban megvan (`return -1`), de **Eszter jelezte hogy ellenőrizni kell** | Eszter C4 |
| H9 | **Hardware dongle belépés** | `PROSBE.DLL` — fizikai kulcs | Csak szoftveres jelszó | Tamás G04 |
| H10 | **Adatgyűjtés (DataCollection) mélysége** | `server/unit29.pas` (77 KB) — forgalom, címlet, WU, bank, storno, Metro, Tesco | `DataCollectionService` — töredéke | Junior G3 |
| H11 | **Audit log tamper-evidence** | Flat text (manipulálható) | Hash-lánc csak kamerára van, pénzügyi audit logra NINCS | Bence K-07 |
| H12 | **PEP adatbázis forrás** | Manuális | HNB/ACAMS automatikus szinkron HIÁNYZIK | Bence K-10 |

---

## 5. Biztonsági összefoglalás (Bence elemzéséből)

### 5.1 Legacy rendszer — KRITIKUS megfelelési kockázat

A Delphi 7 rendszer 4 kritikus biztonsági hiányossága:
1. **SQL injection**: Minden .pas fájlban string-konkatenáció, 0 paraméterezés → teljes DB hozzáférés
2. **Plaintext hálózat**: Firebird TCP port 3050, nincs TLS → összes AML/szankciós adat olvasható
3. **Hardcoded IP**: 30+ fájlban `185.43.207.99` → újrafordítás kell IP-változásnál
4. **Debug build production-ban**: `\debug\` könyvtárak, `TerminateProcess` hack

**GDPR bírság kockázat**: 10M EUR vagy globális forgalom 2%-a (83. cikk)
**Pmt. szankció**: engedélyvonásig terjedhet (69. §)

### 5.2 Modern rendszer — KÖZEPES kockázat, kezelhető

A modern stack minden kritikus kontrollt implementálja. Nyitott hiányosságok:

| Prioritás | Hiány | Sprint igény |
|---|---|---|
| P2 (rövid távú) | Szankciós lista automatikus scheduler | 0.5 sprint |
| P2 | PEP lista forrás integráció | 0.5 sprint |
| P2 | AML bejelentési határidő tracking | 0.5 sprint |
| P2 | Audit log hash-lánc (pénzügyi) | 1 sprint |
| P2 | GDPR törlési kérelem workflow | 1 sprint |
| P3 (közép távú) | Swagger production kikapcsolás | trivális |
| P3 | Cross-branch structuring detekció | 1 sprint |
| P3 | JWT refresh token rotáció | 0.5 sprint |

---

## 6. Üzleti szabály részletek (Eszter elemzéséből)

### 6.1 A 35 azonosított üzleti szabály összefoglalása

| Kategória | Szabályok | Megvan | Részleges | Hiányzik |
|---|---|---|---|---|
| Tranzakciós alap (max 6 sor, HUF tiltás, készlet, konverzió) | 8 | 7 | 1 (EUA) | 0 |
| Árfolyam & kezelési díj (kerekítés, ezrelék/sávos, kedvezmény) | 9 | 8 | 0 | 1 (limit eltérés) |
| AML/Ügyfél (300K, terrorlista, göngyölés, PEP) | 12 | 7 | 3 | 2 (negyedéves + 6 szintű) |
| Sztornó (supervisor, limit, indoklás) | 3 | 3 | 0 | 0 |
| Bizonylat & napzárás (blokkstruktúra, 9 lépéses zárás) | 3 | 3 | 0 | 0 |
| **Összesen** | **35** | **28 (80%)** | **4 (11%)** | **3 (9%)** |

### 6.2 Fontos eltérések a legacy és modern között

| Szabály | Legacy | Modern | Probléma |
|---|---|---|---|
| Egyedi kezelési díj limit | **3/nap** | **5/nap** | Bevételkiesés (több kedvezmény adható) |
| Konverziónál dupla összeg az azonosításhoz | `_fizetendo := _fizetendo + _fizetendo` | Nem egyértelmű | AML gap — konverziónál alacsonyabb küszöb kellene |
| EUR érme (EUA) kezelés | Eladásnál tiltva, vásárlásnál speciális | Nincs explicit EUA tiltás | Helytelen pénznemkezelés |
| 100K-300K között „Nem azonosítom" gomb | Legacy letiltja | Modern nem tiltja | Compliance best practice hiány |

### 6.3 Tranzakciós formula egyezés

Eladás legacy formula:
```
netto = Σ(bankjegy[i] × árfolyam[i] / 100)   // JPY: /1000
kezelésidíj = GetKezelesidij(netto)             // ezrelék VAGY sávos
brutto = netto + kezelésidíj
fizetendo = Kerekito(brutto)                    // 5 Ft-ra kerekít
```

Modern formula (TransactionCalculationService.java):
```java
hufAmount = currencyAmount × appliedRate
handlingFee = HandlingFeeCalculator.calculate(hufAmount)
total = HungarianRounding.roundToFive(hufAmount + handlingFee)
```

**Azonos logika, a modern BigDecimal precízióval.**

---

## 7. Pénztáros napi workflow (Nóra elemzéséből)

### 7.1 A rekonstruált legacy workflow

```
Nap nyitás (NAPIKEZD) 
  → Árfolyam lekérdezés/módosítás (ARFREG/ARFDISP)
    → Tranzakciók ciklusa:
        Eladás (ELADAS) / Vásárlás (VASARLAS)
          → Ügyfél azonosítás ha kell (UGYFEL → BIGCTRL → TERROR)
          → Címlet bevitel (CIMLET)
          → Blokknyomtatás (BLOKNYOM)
          → Foglalás ha kell (FOGLALO)
          → WU/Metro/Tesco ha kell
    → Címletellenőrzés (CIMLCTRL)
  → Napi zárás (NAPZAR) / Esti zárás (ESTIZAR)
    → 9 lépéses ellenőrzési lánc
    → Napzáró nyomtatás (NZNYOMT)
    → Napi mentés (NAPIMENT)
  → Havi zárás (HAVIZAR) — hó végén
  → Évi nyitó (EVNYITO) — év elején
```

### 7.2 UX gap-ek ahol a modern JOBB

- **Dashboard**: Legacy-nek nincs, modern-ben központi napi státusz
- **Modális vs. nem-modális**: Legacy mindent blokkol, modern aszinkron
- **Hibakezelés**: Legacy: `ShowMessage` popup; Modern: toast/notification, undo lehetőség
- **Keresés**: Legacy: szűk dátum/idő filter; Modern: fulltext + advanced filter
- **Storno workflow**: Legacy: többablakos; Modern: wizard, egy helyen

### 7.3 UX gap-ek ahol a legacy JOBB

- **Nullás latencia**: Lokális Firebird → a pénztárosok hozzászoktak
- **Billentyűzetes workflow**: Minden F-gomb, hotkey rendszerszinten definiálva
- **Hardware közvetlen elérés**: COM port, nyomtató, scanner natívan

### 7.4 Electron fejlesztési javaslatok (top 5)

1. **Optimistic UI + lokális cache** — nullás érzetet adni REST API mellett
2. **Teljes billentyűzetes navigáció** — F-gombok, hotkey-k mint a legacy-ben
3. **Offline fallback SQLite-tal** — ha szerver elérhetetlen, a pénztáros dolgozhasson
4. **Hardware mock réteg** — printer, scanner, dongle → Electron IPC bridge
5. **"Okos" napzáró** — automatikusan felajánlja hol zárható (hiányzó tranzakciók, címleteltérés)

---

## 8. Tesztelhetőség (Tamás elemzéséből)

### 8.1 Legacy vs. Modern

| | Legacy (Delphi 7) | Modern (Spring+React+Electron) |
|---|---|---|
| Unit test | LEHETETLEN — UI és logika csatolt | KIVÁLÓ — service réteg izolálható |
| Integration test | LEHETETLEN — hardver-függő DLL-ek | KIVÁLÓ — Testcontainers + MockMvc |
| E2E test | LEHETETLEN — nincs automatizálás | JÓ — Playwright konfigurált |
| Electron | — | KÖZEPES — hardver mock szükséges |

### 8.2 Top 10 gap tesztelési stratégia

Tamás minden CRITICAL/HIGH gap-re részletes tesztelési tervet adott (unit + integration + E2E szinteken). Lásd: `tamas-functional-coverage-analysis.md` 8. fejezet.

Kulcs infrastruktúra igény:
- **Testcontainers PostgreSQL** — minden service integration testhez
- **WireMock** — MoneyGram, Posta, Metro/Tesco külső API mockhoz
- **ESC/POS byte assert helper** — nyomtatás lefedettséghez
- **Hardware mock layer** — printer, scanner, dongle, QR COM-port Electron IPC szinten

---

## 9. Fejlesztési sprint terv (konszolidált)

### Sprint 5 — AZONNALI (jogszabályi kötelezettség)
| # | Feladat | Forrás | Becsült méret |
|---|---|---|---|
| 1 | Negyedéves göngyölési kontroll (4 tranzakció / 25M Ft) | Eszter C1 | 2-3 nap |
| 2 | 6 szintű kockázati besorolás (BIGCTRL logika portolása) | Eszter C2 | 3-5 nap |
| 3 | 8 napos göngyölési ablak | Eszter C3 | 1-2 nap |
| 4 | AML bejelentési határidő tracking (2 munkanap → OVERDUE) | Bence K-14 | 1 nap |
| 5 | Év-nyitó workflow (backend + frontend) | Tamás G01 | 3-5 nap |

**Sprint 5 összes: ~10-16 fejlesztési nap**

### Sprint 6 — MAGAS (üzleti működés)
| # | Feladat | Forrás | Becsült méret |
|---|---|---|---|
| 6 | Trade modul mélyítés (295 KB legacy → részletes portolás) | Junior G2 | 5-8 nap |
| 7 | WU teljes integráció (stub → élő API) | Junior G9 | 3-5 nap |
| 8 | Teljes blokknyomtatás (jogi személy, nyilatkozatok, napkönyv) | Tamás G03 | 3-5 nap |
| 9 | Jelenlét-nyilvántartás (Controller + frontend) | Tamás G02 | 2-3 nap |
| 10 | Szankciós lista automatikus scheduler | Bence K-04 | 1 nap |
| 11 | PEP lista forrás integráció | Bence K-10 | 1 nap |

**Sprint 6 összes: ~15-23 fejlesztési nap**

### Sprint 7 — KÖZEPES (partnerség-függő + compliance finomítás)
| # | Feladat | Forrás |
|---|---|---|
| 12 | Metro integráció (ha aktív partnerség) | Junior G5, Tamás G07 |
| 13 | Tesco integráció (ha aktív partnerség) | Junior G6, Tamás G07 |
| 14 | MoneyGram (ha aktív) | Junior G1, Tamás G05 |
| 15 | Audit log hash-lánc (pénzügyi) | Bence K-07 |
| 16 | GDPR törlési kérelem workflow | Bence K-08 |
| 17 | Cross-branch structuring detekció | Bence K-09 |
| 18 | JWT refresh token rotáció | Bence K-15 |
| 19 | DataCollection mélyítés | Junior G3 |
| 20 | Hardware dongle belépés | Tamás G04 |

### Backlog (Sprint 8+)
- Retroaktív adat-pótló eszköz (Tamás G09)
- Verseny pontrendszer (Tamás G08, S46)
- Dekádos kezdeti nyomtatás (Tamás G11)
- EU akció kérdőív (Tamás G13)
- Vevő szegmentált összesítő (Tamás G20, S47)
- Értéktár-specifikus engedélykezelés (Tamás E03)
- DBF export kompatibilitás (Tamás G23)
- OpenOffice dokumentum-generálás (Junior G21)

---

## 10. Döntést igénylő kérdések Zoltán felé

1. **Metro/Tesco**: Aktív üzleti partnerségek? Ha igen → Sprint 7 helyett Sprint 6-ra előrehozni
2. **MoneyGram**: Használjuk? Ha igen → Sprint 6 CRITICAL
3. **Hardware dongle**: Compliance elvárás a fizikai kulcs, vagy elegendő a szoftveres jelszó + 2FA?
4. **WU**: A stub elegendő az átmeneti időszakra, vagy teljes API integráció kell azonnalra?
5. **Trade modul**: Az értéktári kereskedés mekkora része az üzletnek? Ez befolyásolja a Sprint 6 méretét
6. **Legacy rendszer párhuzamos üzemeltetése**: Meddig fut a Delphi rendszer? Amíg fut, a Bence által jelzett KRITIKUS biztonsági kockázatok fennállnak

---

## 11. Cross-referencia index

| Téma | Junior | Eszter | Tamás | Bence | Nóra |
|---|---|---|---|---|---|
| Negyedéves göngyölés | — | C1, C2 | — | K-05 | — |
| 8 napos ablak | — | C3 | — | K-09 | — |
| Trade modul | G2 | M2 | S43, V03-04 | — | — |
| Év-nyitó | G-kat. | — | G01, G10 | — | workflow |
| MoneyGram | G1 | — | G05 | — | — |
| Metro/Tesco | G5, G6 | — | G07, V93, V103 | — | — |
| WU mélység | G9 | — | V29, S31-32 | — | — |
| Blokknyomtatás | implicit | 34 | G03 | — | bizonylat gap |
| Jelenlét | G4 | — | G02 | — | — |
| AML bejelentés | — | — | — | K-14 | — |
| Szankciós lista | — | 22-23 | S33, V45 | K-04 | — |
| SQL injection | — | — | — | K-01 | — |
| Hálózat/titkosítás | arch.5 | — | — | K-02, K-03 | comm.5 |
| Audit trail | — | — | — | K-07 | — |
| Offline működés | arch.5 | — | tesztelhetőség | — | gap.4 |
| Billentyűzetes UX | — | — | — | — | gap.4 |
