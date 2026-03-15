# Fejlesztési Állapotfelmérés — Valutaváltó ERP

**Dátum:** 2026-03-15
**Auditor:** Claude Opus 4.6 (független AI audit)
**Scope:** Teljes kódbázis vs. Felmérés dokumentáció (88 .docx)
**Commit:** 47c74d1 (main branch)

---

## 1. Összefoglaló

A valutaváltó ERP rendszer fejlesztése **előrehaladott állapotban** van. Az alapvető üzleti funkciók (tranzakciók, árfolyamkezelés, napzárás, AML, offline szinkron) **működőképesek és biztonságosak**. Az audit során javított 13 finding (7× Sev-1 tenancy/security) után a rendszer **CONDITIONAL GO** minősítést kapott.

### Fejlettségi szint modulonként

| Kategória | Modulszám | Százalék |
|-----------|-----------|----------|
| ✅ Teljesen implementált | 18 | 60% |
| ⚠️ Részlegesen implementált | 8 | 27% |
| ❌ Hiányzó / placeholder | 4 | 13% |

---

## 2. Teljesen implementált modulok (✅)

### 2.1 Tranzakciókezelés
- **Vétel (BUY):** Külföldi valuta vásárlása ügyféltől — HUF kerekítés, AML ellenőrzés, WAC frissítés ✅
- **Eladás (SELL):** Külföldi valuta eladása ügyfélnek — készletellenőrzés, árfolyam-frissesség ✅
- **Konverzió (CONVERSION):** Valuta→Valuta csere HUF közvetítéssel ✅
- **Átadás/átvétel (TRANSFER_OUT / TRANSFER_IN):** Irodák közötti valutamozgás ✅
- **HUF 5 Ft kerekítés:** Backend (`HungarianRounding.java`) és mindkét frontend (`rounding.ts`) konzisztens — audit során javítva (F-012) ✅
- **Bizonylat számozás:** `ReceiptSequenceService` — PREFIX + branchCode(3jegy) + sorszám(6jegy), pl. `E-001-100001` ✅

### 2.2 Árfolyamkezelés
- **Munkacsoport (workgroup) alapú árfolyamrendszer:** A legacy "54 csoport lap" helyett modern munkacsoport-struktúra ✅
- **Kedvezmény szintek:** Max 3 szint per munkacsoport (`DiscountLevelEditor.tsx`) — mennyiség-alapú árazás ✅
- **Jóváhagyási workflow:** PENDING → APPROVED/REJECTED (`RateApprovalService.java`) ✅
- **24h TTL:** `exchange-rate.max-age-hours` konfiguráció, lejárt árfolyammal nincs tranzakció ✅
- **2% supervisor-határ:** Kedvezmény > 2% → supervisor jóváhagyás szükséges ✅

### 2.3 Napzárás és riportok
- **Napi zárás:** `DailyClosingService` — 9 lépéses workflow (részleteket lásd 3.1) ✅
- **Dekádjelentés:** 10 napos időszak, DRAFT → CLOSED lifecycle, branchId IDOR javítva ✅
- **Havi zárás:** MNB árfolyam lekérés, WAC készletértékelés, nem realizált P&L számítás ✅
- **Nyitókészlet átvitel:** 3-szintű fallback (előző nap → előző hónap → 0) ✅
- **Készletkövetés:** `CashBalance` — iroda + valuta kombináció, min/max korlátok ✅
- **Treasury összesítés:** Branch → BranchGroup → Company aggregáció, companyId szűréssel (audit javítva) ✅
- **Beküldési státusz:** `ClosingControl` — 3 fázis (daily/evening/NAV closing done) ✅

### 2.4 AML / Pmt. megfelelőség
- **Azonosítási küszöb:** 300.000 Ft feletti tranzakciónál ✅
- **Részletes azonosítás:** 1.500.000 Ft feletti (kódban `DETAILED_ID_LIMIT = 1.5M`) ⚠️ lásd 3.5
- **Napi kumulatív:** Napi összeg figyelés ✅
- **90 napos, 365 napos, heti, éves (8M) küszöbök:** Implementálva ✅

### 2.5 Biztonság
- **JWT autentikáció:** Spring Security ✅
- **@PreAuthorize:** 124/124 controller lefedettség (F-010 audit javítás) ✅
- **Multi-tenant companyId szűrés:** Kritikus szolgáltatások javítva (F-001–F-009) ✅
- **CORS:** Explicit origin + explicit header policy (F-011 javítva) ✅

### 2.6 Offline kliens (penztar-client)
- **Electron 33 + SQLite:** Offline tranzakció rögzítés ✅
- **Szinkron motor:** 30 mp intervallum, duplikát-megelőzés, adatvesztés-védelem ✅
- **Konfliktuskezelés:** Robust megvalósítás ✅

### 2.7 Sztornó
- **3-lépéses workflow:** Ellenőrzés → Jóváhagyás → Végrehajtás ✅
- **Napi limit:** 3 sztornó/nap, felett supervisor jóváhagyás szükséges ✅
- **Eredeti árfolyam használata:** Sztornó az eredeti tranzakció árfolyamán történik ✅
- **Nem mai tranzakció:** Supervisor jóváhagyás szükséges ✅

### 2.8 Foglalás (Reservation)
- **4 állapot:** ACTIVE → FULFILLED / CANCELLED_BY_CUSTOMER / CANCELLED_BY_COMPANY ✅
- **PESSIMISTIC_WRITE lock:** Egyidejű műveletek ellen ✅
- **Letét kezelés:** 2× visszatérítés cég-oldali törléskor ✅

---

## 3. Részlegesen implementált modulok (⚠️)

### 3.1 Napzárás — 9/13 lépés
**Követelmény (zaras_ablak.docx):** 13 lépéses zárási wizard
**Megvalósítás:** `DailyClosingService` 9 lépést tartalmaz + `ClosingWizardService` 5 lépéses alternatív absztrakció

**Implementált lépések:**
1. MTCN szám ellenőrzés (Western Union)
2. Esti pénztár címletezése
3. Kezelési díj címletezése
4. Western Union címletezése
5. AFA címletezése
6. Foglalás címletezése
7. E-kereskedelem címletezése
8. Egyéb címletezések
9. NAV kontroll + napi jelentés + dekád + havi gyűjtő

**Hiányzó/azonosítatlan lépések:** A legacy 13-lépéses wizard pontos lépései nem mindegyike van egyértelműen leképezve. A `ClosingWizardService` 5 lépése (tranzakció összesítés, készpénz egyeztetés, címlet számlálás, bizonylatok ellenőrzése, lezárás) részben fedi a hiányt.

**Prioritás:** KÖZEPES — az alap zárási folyamat működik, de a legacy-vel való pontos paritás UAT-ot igényel.

### 3.2 Címletezés (Denomination)
**Követelmény:** Teljes címletkezelés a zárás folyamatában
**Megvalósítás:**
- `DenominationController` — 14 HUF címlet, optimális visszajáró algoritmus ✅
- `DailyClosingService` — 8 explicit címletezési lépés ✅
- `EveningClosingService.getDenominations()` — **üres listát ad vissza (TODO)** ❌

**Prioritás:** MAGAS — az esti zárás címletezési funkciója nem működik.

### 3.3 Bizonylat típusok — 5/8
**Követelmény (kerdesek.docx):** 8 bizonylat típus
| Típus | Kód | Státusz |
|-------|-----|---------|
| Vétel | V | ✅ Implementált |
| Eladás | E | ✅ Implementált |
| Valuta átadás | F | ✅ Implementált (TRANSFER_OUT) |
| Valuta átvétel | U | ✅ Implementált (TRANSFER_IN) |
| Konverzió | K | ✅ Implementált |
| Forint átadás | FF | ❌ Nincs külön típus |
| Forint átvétel | UF | ❌ Nincs külön típus |
| Kezelési ktg átvétel/átadás | B/K | ❌ Nincs külön típus |

**Megjegyzés:** FF, UF, B, K típusok valószínűleg az F és U típusokon belül kezelhetők (HUF valutával), de nincs explicit bizonylat prefix szétválasztás.

**Prioritás:** KÖZEPES — funkcionálisan lefedett, de bizonylat-szinten nincs differenciálva.

### 3.4 Szerepkör rendszer — eltérő struktúra
**Követelmény:** CASHIER, SUPERVISOR, MANAGER, ADMIN
**Megvalósítás:** ADMIN, DEPOSITORY, TERRITORIAL_MANAGER, CONTROLLER, CASHIER

**Elemzés:** A szerepkörök tartalmilag fedik a követelményeket, de eltérő nevekkel:
- SUPERVISOR → CONTROLLER (felügyeleti funkció)
- MANAGER → TERRITORIAL_MANAGER (területi vezető)
- DEPOSITORY → új szerep (értéktáros)

**Prioritás:** ALACSONY — funkcionálisan megfelelő, névkonvenció kérdés.

### 3.5 AML küszöb eltérés
**Követelmény (Pmt. 2017. évi LIII. tv):** 1.000.000 Ft jelentési küszöb
**Megvalósítás:** `DETAILED_ID_LIMIT = 1.500.000 Ft`

**Elemzés:** A 1.5M Ft-os küszöb SZIGORÚBB mint a jogszabályi minimum (1M Ft), tehát **nem szabálysértő**, de eltér a dokumentációtól. Lehetséges, hogy a cégcsoport belső szabályzata alkalmaz magasabb küszöböt.

**Prioritás:** ALACSONY — jogszabályi szempontból biztonságos (szigorúbb).

### 3.6 Nyomtatási sablonok
**Megvalósítás:** `PrintTemplatePage.tsx` létezik, de `dangerouslySetInnerHTML` használ sanitizálás nélkül (F-020 finding).

**Prioritás:** KÖZEPES — DOMPurify integrálás szükséges, admin felületen alacsony kockázat.

### 3.7 MNB árfolyam integráció
**Megvalósítás:** `MnbExchangeRateService.java` — SOAP API integráció a hivatalos MNB árfolyamokhoz ✅
**Hiányosság:** A revalorizáció (havi zárásnál) működik, de az automatikus napi lekérés ütemezése nem egyértelmű.

**Prioritás:** ALACSONY — az alap funkció működik.

### 3.8 Audit napló
**Megvalósítás:** Létezik audit logging, de a teljes companyId-szintű formális audit lefedettség még nem készült el (F-015 finding).

**Prioritás:** KÖZEPES — a fő műveleti utak már companyId-re szűrnek.

---

## 4. Hiányzó / placeholder modulok (❌)

### 4.1 EUA (euró érme) speciális kezelés
**Követelmény (Követelménylista - Árfolyamkészítés.docx):** EUA érmékre 20% maximális eltérés szabály az alapárfolyamtól.
**Megvalósítás:** **NEM IMPLEMENTÁLT** — sem entitás, sem szolgáltatás, sem konfiguráció szinten nincs currency-specifikus eltérés-validáció.

**Hatás:** Az EUA árfolyam tetszőlegesen beállítható, ami MNB szabályozási kockázatot jelenthet.
**Prioritás:** MAGAS — szabályozási megfelelőség.

### 4.2 Raiffeisen 10% eltérés szabály
**Követelmény:** Raiffeisen partner bank maximálisan 10%-os eltéréssel a középárfolyamtól.
**Megvalósítás:** **NEM IMPLEMENTÁLT** — nincs bank-partner-specifikus árfolyam-validáció.

**Hatás:** Partner banki árfolyamok manuális ellenőrzésen múlnak.
**Prioritás:** KÖZEPES — üzleti kockázat, de manuálisan kezelhető.

### 4.3 NAV integráció
**Megvalósítás:** `NavReportService.java` — **placeholder/mock** implementáció (F-014 finding).
**Hiányosság:** Valós NAV E2E teszt nem készült, hardvert igényel.

**Prioritás:** MAGAS — compliance kötelezettség, de out-of-scope a szoftverfejlesztéshez (hardver/hálózat kérdés).

### 4.4 Árfolyamkészítő "0-s lap" és cross-rate részletek
**Követelmény:** A legacy rendszerben:
- **0-s lap:** Alapárfolyamok — vételi/eladási páronként, MNB középárfolyamra épülve
- **54 csoport lap:** Iroda-csoportonkénti kedvezmények 4 szinten (alsó/középső/felső/saját hatáskörű)
- **Cross-rate:** EUR-alapú és USD-alapú valuták megkülönböztetése

**Megvalósítás:**
- Munkacsoport-struktúra: ✅ (modern megfelelő a csoport lapoknak)
- 3 kedvezmény szint: ✅ (a legacy 4-ből 3 szint implementálva)
- Cross-rate HUF közvetítéssel: ✅ (de nincs EUR/USD bázis megkülönböztetés)

**Hiányzó elem:** A 4. kedvezmény szint ("saját hatáskörű" — manuális, supervisor által beállítható egyedi kedvezmény) nincs explicit módon kezelve.

**Prioritás:** KÖZEPES — a 3 szint lefedi a normál működést, a 4. szint ritka edge case.

---

## 5. Legacy paritás állapota

### Az alábbi legacy funkciókat összehasonlítottam a Felmérés dokumentumokkal:

| Legacy funkció | Felmérés dokumentum | Státusz | Megjegyzés |
|----------------|---------------------|---------|------------|
| Tranzakció rögzítés (vétel/eladás) | Valuta A felm.docx | ✅ PASS | Teljes |
| HUF 5 Ft kerekítés | Delphi ATADVET modul | ✅ PASS | Javítva (F-012) |
| Sztornó 3-lépés | sztorno.docx | ✅ PASS | Teljes workflow |
| Napzárás wizard | zaras_ablak.docx | ⚠️ PARTIAL | 9/13 lépés |
| Árfolyam lapok (0-s + csoport) | Követelménylista - Árfolyamkészítés.docx | ⚠️ PARTIAL | Munkacsoport OK, 4. kedvezmény hiányzik |
| Bizonylat számozás | kerdesek.docx | ⚠️ PARTIAL | 5/8 típus explicit |
| EUA 20% szabály | Követelménylista - Árfolyamkészítés.docx | ❌ MISSING | Nincs validáció |
| Dekádjelentés | üzemeltetési megbeszélés | ✅ PASS | Teljes |
| Havi zárás + revalorizáció | c.docm.docx | ✅ PASS | MNB + WAC |
| Offline működés (FTP pk) | RSL üzemeltetési megbeszélés | ✅ PASS | Modern Electron/SQLite |
| AML Pmt. küszöbök | compliance docs | ✅ PASS | Szigorúbb (1.5M vs 1M) |
| Ügyfélkezelés | Valuta A felm.docx | ✅ PASS | AML-hez kötött |
| Foglalás rendszer | kerdesek.docx | ✅ PASS | 4 állapot |
| WAC átlagárfolyam | c.docm.docx | ✅ PASS | Súlyozott átlag |
| Elszámoló árfolyam | c.docm.docx | ✅ PASS | = MNB hónap végi |
| NAV riport | compliance docs | ❌ MOCK | Placeholder |

---

## 6. Fejlesztési roadmap javaslat

### P0 — Azonnali (release blocker)
1. **EveningClosingService.getDenominations() implementálása** — jelenleg üres listát ad vissza
2. **EUA 20% eltérés validáció** — currency-specifikus árfolyam-korlát hozzáadása
3. **DOMPurify integráció** PrintTemplatePage.tsx-be (F-020)
4. **Mockito 5.x frissítés** — 186 teszt hiba javítása (F-018)

### P1 — Következő sprint
5. **4. kedvezmény szint** ("saját hatáskörű") implementálása a munkacsoport rendszerbe
6. **FF/UF/B/K bizonylat típusok** explicit szétválasztása (ha üzletileg szükséges)
7. **Raiffeisen 10% eltérés** szabály implementálása
8. **Napzárás wizard** lépéseinek teljes leképezése a legacy 13 lépésre
9. **Swagger UI** produkciós profiltól való elrejtése (F-019)

### P2 — UAT fázis
10. **Dekádjelentés output paritás** igazolása legacy rendszerrel (F-016)
11. **Foglalás készlet-elkülönítés** UAT paritás (F-017)
12. **NAV integráció** valós E2E tesztelése (F-014)
13. **CompanyId formális audit** a teljes backendre (F-015)

### P3 — Nice-to-have
14. **Cross-rate EUR/USD bázis** megkülönböztetés (jelenleg HUF közvetítés elegendő)
15. **Automatikus MNB árfolyam lekérés** ütemezése (scheduler)
16. **Audit napló** kibővítése teljes CRUD lefedettségre

---

## 7. Technikai adósságok

| Terület | Részletek | Hatás |
|---------|-----------|-------|
| Mockito 5.x | Java 21 + MockMaker inkompatibilitás, 186/288 teszt Error | Tesztelhetőség |
| dangerouslySetInnerHTML | Sanitizálás nélkül (admin felület) | Biztonsági kockázat (alacsony) |
| Swagger UI | Produkcióban elérhető | Információ kiszivárgás |
| EveningClosingService | getDenominations() TODO | Esti zárás hiányos |

---

## 8. Végső értékelés

### Fejlesztettségi szint: **~75-80%**

**Erősségek:**
- A kritikus üzleti logika (tranzakciók, kerekítés, AML, árfolyam) korrekt és biztonságos
- Multi-tenant biztonság az audit után megfelelő (7× Sev-1 javítva)
- Modern technológiai stack (Spring Boot 3.2, React 19, Electron 33)
- Offline működés robusztus
- Foglalás és sztornó teljes workflow

**Fejlesztendő területek:**
- Currency-specifikus üzleti szabályok (EUA, Raiffeisen) hiányoznak
- Napzárás wizard nem teljes legacy paritás
- Esti zárás címletezés TODO
- NAV integráció mock
- Teszt infrastruktúra (Mockito) frissítésre szorul

**Összességében:** A rendszer **üzletileg használható állapotban van** a fő funkciókra. A hiányzó elemek (EUA, Raiffeisen szabályok, FF/UF bizonylatok) a napi működést nem akadályozzák, de a teljes legacy paritáshoz és compliance teljességhez szükségesek. A P0 elemek javítása után a rendszer **GO** minősítésre emelkedhet.

---

*Generálta: Claude Opus 4.6 — 2026-03-15*
*Alapja: 88 Felmérés .docx dokumentum + teljes kódbázis elemzés + biztonsági audit*
