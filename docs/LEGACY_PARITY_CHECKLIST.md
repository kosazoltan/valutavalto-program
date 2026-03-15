# Legacy Parity Checklist es Keszultsegi Riport

Frissitve: 2026-03-15

Forrasok:
- `docs/LEGACY-FULL-AUDIT.md`
- `docs/LEGACY-VS-NEW-COMPARISON.md`
- `docs/API-OVERVIEW.md`
- `docs/LEGACY_PARITY_EVIDENCE_MATRIX.md`
- `docs/LEGACY_PARITY_P1_ACTION_PLAN.md`
- `docs/LEGACY_PARITY_EXEC_STATUS.md`
- Kod-ellenorzes (service/controller letezes es implementacios mintak)

Statusz jeloles:
- `[x]` Kesz / igazolt
- `[ ]` Nyitott / meg nem igazolt

---

## 1. Snapshot Keszultsegi Riport (aktualis allapot)

### 1.1 Technikai release gate-ek
- [x] Backend celzott regresszios tesztek lefutottak (`InventoryControllerTest`, `ClosingFlowTest`, `CommissionCalculationServiceTest`, `SyncServiceTest`, `RatePublishServiceTest`, `SyncInboundControllerTest`, `OutboxSyncWorkerServiceTest`)
- [x] Backend teljes tesztfutas sikeres (`backend`: `mvnw.cmd -q test`)
- [x] `penztar-client` teszt + typecheck + IPC kontrakt ellenorzes sikeres
- [x] `frontend-react` ESLint: 0 error / 0 warning
- [x] `penztar-client` ESLint: 0 error / 0 warning
- [x] Git allapot tiszta, `main` szinkronban van az `origin/main` aggal

### 1.2 Legacy parity KPI (audit-alapu)
- Legacy-uzletileg relevans teruletek: 84
- Teljesen implementalt: 57
- Reszlegesen implementalt: 23
- Hianyzo: 4
- N/A (deprecated): 38

Mutatok:
- Szigoru parity arany: `57 / 84 = 67.9%`
- Sulyozott keszultseg (reszleges = 0.5): `(57 + 0.5 * 23) / 84 = 81.5%`

Megjegyzes:
- A technikai gate-ek zold allapota nem egyenlo a teljes legacy uzleti parity bizonyitasaval.

---

## 2. Go/No-Go Kriteriumok (kritikus)

- [x] Tranzakcio alapfolyamatok (vetel/eladas/storno) stabilan mennek
- [x] Foglalo modul kodszinten jelen van (`ReservationController/Service/Repository`)
- [ ] Foglalo keszlet-elkulonites legacy-egyezosege UAT-tal bizonyitva
- [x] Dekad riport modul kodszinten jelen van (`DecadeReportController/Service`)
- [ ] Dekad riport + napzaras egyuttes E2E parity igazolt
- [x] Nyitokeszlet automatikus atvitel kodszinten implementalt
- [x] BranchGroup / korzet szintu treasury aggregacio kodszinten implementalt
- [x] KFT-szintu (Company) treasury aggregacio kodszinten implementalt
- [ ] NAV integracio valodi (nem placeholder/mock)
- [ ] Bizonylat fizikai nyomtatas parity (nem csak entity/adatrogzites)
- [x] AML heti gongyoles kodszinten implementalt
- [x] AML 8M eves kuszob kodszinten implementalt

No-Go trigger:
- Ha barmelyik nyitott kritikus pont uzemelesi blokkolo a cel uzleti modellben, nem tekintheto teljes legacy parity-nek.

---

## 3. Teljes Legacy Parity Checklist (modulonkent)

### 3.1 Tranzakcio, penztar, kezelesi dij
- [x] Eladas (ELADAS) funkcio implementalva
- [x] Vasarlas (VASARLAS) funkcio implementalva
- [x] Tranzakciotetel tobb soron kezelve (nem 6 sor limit)
- [x] Kezelesi dij savos + ezrelekes logika implementalva
- [x] Kedvezmeny tipologia implementalva
- [ ] Legacy-specifikus konverzios hiba workflow parity bizonyitott
- [ ] Fizikai bizonylatnyomtatas parity bizonyitott

### 3.2 AML, ugyfel, compliance
- [x] Ugyfel torzs es azonositasi alapok implementalva
- [x] Alap AML kuszobok (napi/90 nap/365 nap) implementalva
- [x] Tiltolista / szankcio endpoint-ek elerhetok
- [x] Heti forint gongyoles kodszinten implementalva
- [x] 8M eves AML kuszob kodszinten implementalva
- [ ] Jogi vs termeszetes szemely kulon legacy logika parity bizonyitott
- [ ] 4-bol-2 legacy azonositasi logika szuksegessege veglegesitve

### 3.3 Napnyitas, napzaras, idoszakok
- [x] Napi nyitas implementalva
- [x] Napi zaras wizard implementalva
- [x] Dekad riport service implementalva
- [x] Havi zaras endpoint/service implementalva
- [ ] Dekad zaras riport output parity bizonyitott (legacy formatum + tartalom)
- [ ] Havi gyujto masolas parity bizonyitott
- [ ] Napkonyv riport parity bizonyitott
- [x] Nyitokeszlet-automatikus meghatarozas kodszinten implementalva

### 3.4 Arfolyamkezeles, kalkulator, polling
- [x] Arfolyam CRUD + kijelzes implementalva
- [x] Arfolyam jovahagyasi folyamat implementalva
- [x] MNB/ECB polling es fallback implementalva
- [x] Arfolyam historizalas implementalva
- [ ] Legacy irany-specifikus edge-case parity (ELADAS/VASARLAS szamitasi irany) UAT-tal igazolt
- [ ] Arfolyam tabor / display parity minden uzleti scenarioban igazolt

### 3.5 Ertektar, keszlet, kozponti osszesites
- [x] Inventory mozgasok (bank be/ki) implementalva
- [x] Cegszintu osszesito dashboard implementalva
- [x] Irodaszintu osszehasonlitas implementalva
- [x] Bankflow osszesites implementalva
- [x] Korzet (BranchGroup) aggregacio kodszinten implementalva
- [x] KFT/Company aggregacio kodszinten implementalva
- [ ] Legacy SUMBANKFORGALOM egyenloseg riporttal igazolt

### 3.6 Foglalo
- [x] Foglalo CRUD/esemenyek implementalva
- [x] Foglalo statuszok (fulfill/cancel tipusok) implementalva
- [ ] Foglalo keszlet-elkulonites parity bizonyitott
- [ ] Foglalo lejart/hataridos edge-case parity bizonyitott

### 3.7 Riportok, exportok, jelentek
- [x] Daily report endpoint-ek es service alapok implementalva
- [x] Decade report endpoint-ek implementalva
- [x] MNB/NAV riport endpoint-ek leteznek
- [ ] Riportok tartalmi parity (osszegu / sorozat / mezoszintu) bizonyitott
- [ ] Konyvelesi export parity bizonyitott

### 3.8 Integraciok, hardver, partnermodulok
- [x] POS, LED, scanner, NAV, Western Union endpoint-ek leteznek
- [x] Western Union service/controller kodszinten jelen van
- [ ] NAV valodi eszkoz-integracio parity bizonyitott (nem mock)
- [ ] POS terminal valodi napi zaras parity bizonyitott
- [ ] Scanner/nyomtato valodi hardver E2E parity bizonyitott
- [ ] Western Union uzleti folyamat parity bizonyitott (ha uzletileg kotelezo)

### 3.9 Szinkron, offline, stabilitas
- [x] Sync endpoint-ek es alap workflow implementalva
- [x] penztar-client IPC kontrakt ellenorzes bevezetve
- [x] Idempotens backend feldolgozasok kritikus pontokon erosodtek
- [ ] Offline konfliktusfeloldas parity teljes UAT-csomaggal igazolt
- [ ] Helyreallasi forgatokonyvek (disconnect/retry/replay) parity igazolt

### 3.10 Security, multi-tenant, audit
- [x] JWT + auth endpoint-ek implementalva
- [x] Audit log endpoint/controller implementalva
- [ ] `companyId` szures teljes, bizonyitott repo-szintu auditja lezarva
- [x] Osszes controller `@PreAuthorize` lefedettsege ellenorzotten 100% (124/124)
- [ ] CORS/security policy parity es production hardening checklist lezarva

---

## 4. Deprecated / NEM kotelezo parity scope (elfogadott N/A)

- [x] Western Union teljes legacy csomag N/A, ha uzletileg mar nem kovetelmeny
- [x] Metro/Tesco/OTP aru hazmodulok N/A, ha nincs ilyen uzleti csatorna
- [x] Helga konyvelesi legacy modulok N/A, ha kulon rendszer marad
- [x] FTP/pk file alapu mozgasok N/A, ha REST + PostgreSQL a celarchitektura
- [x] Hardver setup legacy modulok N/A, ha modern konfiguracios mechanizmus valtotta ki

Megjegyzes:
- N/A csak formalis uzleti dontessel es dokumentalt jovahagyassal fogadhato el.

---

## 5. Keszultsegi riport sablon (kipipalhato releasehez)

### 5.1 UAT bizonyitek blokk
- [ ] UAT-TRX-01 vetel/eladas normalkor
- [ ] UAT-TRX-02 sztorno teljes flow
- [ ] UAT-AML-01 kuszobatlepes es vizsgalat
- [ ] UAT-AML-02 tiltolista/szankcio talalat
- [ ] UAT-CLS-01 napzaras 9/9 PASS
- [ ] UAT-CLS-02 dekadzaras es riport generalas
- [ ] UAT-TRS-01 treasury osszesites egyezik legacy kontrollal
- [ ] UAT-RATE-01 arfolyam frissites + alkalmazas tranzakcioban
- [ ] UAT-RES-01 foglalo teljesites/visszafizetes
- [ ] UAT-INT-01 NAV/POS hardver E2E (ha scope-ban van)

### 5.2 Release dontes
- [ ] GO: minden kritikus parity pont lezarva
- [ ] GO: minden kotelezo UAT eset PASS
- [ ] GO: uzleti tulajdonosi jovahagyas rogzitve
- [ ] GO: rollback terv dokumentalva es validalva

Vegso minosites:
- [ ] `TELJES LEGACY PARITY` (csak minden kritikus es kotelezo bizonyitek utan jelolheto)

---

## 6. Javasolt kovetkezo lepesek (automatikus vegrehajtasi sorrend)

1. Kritikus nyitott pontokhoz feature-by-feature bizonyitek gyujtes (`P1` lista).
2. UAT esetek futtatasa valos adatokkal, modulonkenti PASS/FAIL rogzites.
3. Nyitott parity pontok lezarasa vagy formalis N/A dontes dokumentalasa.
4. Vegso GO/NO-GO review az uzleti tulajdonossal.

## 7. Evidencia dokumentumok

- Reszletes kod- es tesztbizonyitekok: `docs/LEGACY_PARITY_EVIDENCE_MATRIX.md`
- P1 gap-ek vegrehajtasi terve: `docs/LEGACY_PARITY_P1_ACTION_PLAN.md`
- Vezetoi GO/NO-GO snapshot: `docs/LEGACY_PARITY_EXEC_STATUS.md`
