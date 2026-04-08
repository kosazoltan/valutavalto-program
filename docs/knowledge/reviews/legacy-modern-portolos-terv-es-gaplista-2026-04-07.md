# Legacy → Modern Portolási Terv és Összevont Gap-lista
> Dátum: 2026-04-07 | Készítette: Junior (6 elemzés összevonása)
> Források: Junior, Eszter, Gábor, Nóra, Tamás, Bence elemzései

---

## 1. AZONNALI JAVÍTÁSOK (P0 — production kockázat)

Ezek NEM portolási feladatok — ezek a MEGLÉVŐ modern kódban lévő hibák/stubbok, amiket azonnal javítani kell.

| # | Hiba | Forrás | Fájl | Kockázat |
|---|------|--------|------|----------|
| P0-1 | **BackupService fake pg_dump** | Bence | BackupService.java:70 | Adatvesztés — nincs valódi mentés |
| P0-2 | **NAV pénztárgép fake integráció** | Tamás+Bence | NavIntegrationService.java | Adóhatósági megfelelőség sérül |
| P0-3 | **POS Borgun/Worldline fake driver** | Tamás+Bence | PosTerminalService.java:412,426 | Bankkártyás tranzakciók elveszhetnek |
| P0-4 | **VatRefund sorszám ütközés** | Bence | VatRefundService.java | nanoTime() % 100000 = duplikált NAV bizonylat |
| P0-5 | **ArchivingService stub** | Bence | ArchivingService.java:52 | DB végtelen növekedés, téves sikerstátusz |
| P0-6 | **LicenseService nincs kényszerítve** | Bence | TransactionService.java | Lejárt licenccel is fut tranzakció |
| P0-7 | **Dashboard mock KPI-k** | Nóra | DashboardPage.tsx | Vezető hamis napi képet lát |
| P0-8 | **Notification/email stub** | Bence | ClosingControlService.java:75 | Operátorok nem értesülnek eltérésekről |
| P0-9 | **AML munkaszüneti nap** | Bence | AmlService.java:646 | AML határidők hibás számítás |

---

## 2. PORTOLÁSI GAP-LISTA (Legacy → Modern hiányzó modulok)

### Tier 1 — Napi működéshez KÖTELEZŐ (üzletileg blokkoló)

| # | Legacy Modul | Legacy Form/DLL | Méret | Leírás | Modern állapot |
|---|-------------|-----------------|-------|--------|----------------|
| T1-1 | **Értéktár** | ERTEKTAR/* (penztarak 97KB, atadvet 85KB, pillkesz 63KB) | ~250KB pas | Értéktári készlet, átadás, pillanatnyi készlet, esti zárás | HIÁNYZIK teljesen |
| T1-2 | **Átadás/Átvétel (inter-branch)** | ATADVET DLL (135KB!) | 135KB | Irodák közötti készlet átadás — a LEGNAGYOBB üzleti logika | TransferService létezik, de nem teljes |
| T1-3 | **Bizonylat nyomtatás** | TBLOKKNYOM, TNyomtatoForm, TCIMLETNYOM | ~30KB | Nyugta, blokk, címlet nyomtatás | RÉSZLEGES (receipt generálás van, nyomtatás nem) |
| T1-4 | **WU frontend teljes** | TWesternUnionForm | 89KB | Create/Edit/Storno formok | Backend kész, frontend csak lista (Tamás C3) |

### Tier 2 — Operatív hatékonyság (fontos, de nem blokkoló)

| # | Legacy Modul | Legacy Form/DLL | Méret | Leírás | Modern állapot |
|---|-------------|-----------------|-------|--------|----------------|
| T2-1 | **Excel export / riportok** | TEXCELFORM, TMAKEEXCEL, TEXPRESSEXCEL | ~40KB | Átfogó Excel generálás minden modulhoz | HIÁNYZIK |
| T2-2 | **Havizárás** | THAVIZARAS | ~15KB | Havi zárási folyamat | HIÁNYZIK |
| T2-3 | **Haszon kimutatás** | THASZONFELVIVOFORM | ~11KB | Profitabilitás számítás | HIÁNYZIK |
| T2-4 | **Jutalék rendszer** | TJUTALEK, TJUTALEKFORM, TJUTALEKSZAZALEK | ~25KB | Pénztáros jutalék kalkuláció | HIÁNYZIK |
| T2-5 | **Foglalás UI** | TFOGLALO (81KB) | 81KB | Backend kész (ReservationService), frontend csak lista | Frontend hiányos (Tamás S4) |
| T2-6 | **Darius transport** | — | — | Backend logika kész, de tényleges külső transport hiányzik | RÉSZLEGES (Nóra) |

### Tier 3 — Kiegészítő funkciók

| # | Legacy Modul | Legacy Form/DLL | Leírás | Modern állapot |
|---|-------------|-----------------|--------|----------------|
| T3-1 | **Limit állítás** | TLIMITALLITOFORM | Tranzakciós limit beállítás | HIÁNYZIK |
| T3-2 | **Engedélyezés** | TENGEDELYADAS | Supervisor engedélyezés | RÉSZLEGES |
| T3-3 | **Szünet kijelző** | TSZUNETKIJELZO | Pénztáros szünet kezelés | HIÁNYZIK |
| T3-4 | **Telefon modul** | TTELEFONFORM | Telefonos ügyintézés | HIÁNYZIK |
| T3-5 | **Archívum** | TARCHIVEFORM | Adatarchiválás | STUB (Bence) |
| T3-6 | **Metro** | TMETROFORM / METRO DLL (73KB) | Metro partner integráció | HIÁNYZIK |
| T3-7 | **Paysafe** | TPAYSAFEFORM | Paysafe integráció | HIÁNYZIK |
| T3-8 | **OTP terminál legacy** | TOTPTERM | OTP terminál (modern TCP van) | KÉSZ |
| T3-9 | **Tesco** | TTESCOFORM | Tesco partner integráció | HIÁNYZIK (speciális) |
| T3-10 | **Személyi** | TPERSONALBEDOLGOZAS | HR modul | HIÁNYZIK |
| T3-11 | **Rendszer adatok** | TRENDSZERADATOK | Rendszeradminisztráció | RÉSZLEGES |
| T3-12 | **MNB listák teljes** | TMNBLISTAK, TMNBLISTADISPLAY | MNB lista megjelenítés | RÉSZLEGES |

---

## 3. BEFEJEZETLEN FEJLESZTÉSEK A MODERN RENDSZERBEN

| # | Terület | Fájl | Probléma | Forrás |
|---|---------|------|----------|--------|
| BF-1 | features/ modul | frontend-react/src/features/ | Tervezett compliance + export modul, implementálatlan | Tamás S1 |
| BF-2 | Szinkronizáció | SyncService | Nincs konfliktuskezelés, last-write-wins | Tamás S2 |
| BF-3 | Rate approval 4-szemes elv | RateCreationService | Frontend-en nincs kötve | Tamás S3 |
| BF-4 | Neon replikáció | SyncService | 10 tábla szinkronizál, customer/AML/WU hiányzik | Tamás |
| BF-5 | DailyReport kezelési díj | DailyReportService.java:360 | Nyitó egyenleg hardkódolt 0 | Bence |
| BF-6 | Kamera ffmpeg | CameraService | Extern ffmpeg függőség, nincs fallback | Tamás |

---

## 4. ARCHITEKTÚRA ÖSSZEHASONLÍTÁS

| Szempont | Legacy (Delphi 7) | Modern (Java+React) |
|----------|-------------------|---------------------|
| Form/Screen | 200+ | ~30 page |
| Tranzakció típusok | 10+ DLL (izolált) | 1 TransactionService (unified) |
| DB | Firebird (lokális) | PostgreSQL 16 (VPS) |
| Integráció | DLL load, COM, file marker | REST API, WebSocket |
| Nyomtatás | LPT1, direct printer | Részleges receipt |
| UI | VCL forms, natív | React SPA + Electron |
| Felhasználók | ~200+ aktív form | ~30 aktív route |

---

## 5. SPRINT TERV JAVASLAT

### Sprint 5 — P0 azonnali javítások (1-2 hét)
- P0-1: BackupService → valódi pg_dump
- P0-2: NAV integráció → valódi COM/serial vagy NAV Online API
- P0-3: POS Borgun/Worldline → valódi driver vagy explicit TODO/disable
- P0-4: VatRefund sorszám → AtomicLong + DB sequence
- P0-5: ArchivingService → valódi implementáció vagy explicit kikapcsolás
- P0-6: LicenseService → TransactionService-ben kényszerítés
- P0-7: Dashboard → valódi API hívások mock helyett
- P0-8: Notification → email/push bekötés
- P0-9: AML munkaszüneti nap → magyar ünnepnap tábla

### Sprint 6 — Tier 1 portolás (2-4 hét)
- T1-1: Értéktár modul (TreasuryService + UI)
- T1-2: Inter-branch átadás/átvétel teljesítése
- T1-3: Bizonylat nyomtatás (thermal printer + PDF)
- T1-4: WU frontend (Create/Edit/Storno formok)

### Sprint 7 — Tier 2 portolás (2-3 hét)
- T2-1: Excel export engine
- T2-2: Havizárás
- T2-3: Haszon kimutatás
- T2-4: Jutalék rendszer
- T2-5: Foglalás UI teljesítése
- T2-6: Darius transport véglegesítés

### Sprint 8+ — Tier 3 és finomítás
- Partner integrációk (Metro, Paysafe, Tesco — ha szükséges)
- HR modul
- Szünet, engedélyezés, limit, archívum
- Befejezetlen fejlesztések (BF-1..BF-6)

---

## 6. ÖSSZEFOGLALÓ METRIKÁK

| Metrika | Érték |
|---------|-------|
| Legacy form/class | 200+ |
| Modern service/page | ~30 |
| Portolási gap (hiányzó modul) | 23 |
| P0 azonnali javítás | 9 |
| Befejezetlen fejlesztés | 6 |
| Becsült teljes portolás | 6-10 sprint |
| Legacy kód lefedettség modern-ben | ~40% |

---

## 7. VALÓS ÁLLAPOT FRISSÍTÉS (2026-04-07 15:00)

A gap-lista felülvizsgálata után kiderült hogy a modern rendszer SOKKAL többet tartalmaz mint az eredeti elemzések jelezték:

### Létező modulok (tévesen hiányzónak jelölve):
| Modul | Service | Állapot |
|-------|---------|---------|
| Értéktár | VaultTerritoryService + 5 szolgáltatás | LÉTEZIK |
| Inter-branch | TransferService + TransferController | LÉTEZIK |
| Bizonylat/nyomtatás | ReceiptController + PrintTemplateService | LÉTEZIK |
| Excel export | ReportExportService + StockSnapshotExcelService | LÉTEZIK (CSV + Excel) |
| Havizárás | MonthlyClosingService + MonthlyReportService + PDF | LÉTEZIK |
| Haszon kimutatás | ProfitCalculationService | LÉTEZIK |
| Jutalék | CommissionCalculationService + 2 másik | LÉTEZIK |
| Archiválás | MonthlyArchiveService (valódi, nem stub) | LÉTEZIK |
| Dashboard | Valódi API hívások (nem mock) | LÉTEZIK |
| Notification | NotificationService (DB + in-app) | LÉTEZIK |

### Ténylegesen javított P0 hibák:
- P0-1: BackupService → valódi pg_dump (JAVÍTVA)
- P0-4: VatRefund sorszám → AtomicLong (JAVÍTVA)
- P0-6: LicenseService → tranzakció előtt kényszerítve (JAVÍTVA)
- P0-9: AML munkaszüneti nap → magyar ünnepnapok (JAVÍTVA)
- T1-4: WU frontend → teljes CRUD modal (JAVÍTVA)

### Valós legacy lefedettség: ~70-75% (nem 40%)
