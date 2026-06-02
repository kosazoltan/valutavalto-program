# Doc↔kód konformancia-reverifikáció — Körlevelek/Compliance + Munkavállaló-nyilvántartás

Dátum: 2026-06-02
Scope: `EXCMD/b9-korlevelek-compliance.md` + `EXCMD/b9-munkavallalo-nyilvantartas.md`
Módszer: követelmény-egyenkénti kód-bizonyítás (file:line). „IMPLEMENTED" csak konkrét hivatkozással.

---

## A) b9-munkavallalo-nyilvantartas.md

### Adatmodell — al-táblák (G19 kiemelt fókusz)

| Elem | Doc | Kód-bizonyíték | Státusz |
|---|---|---|---|
| `employee` törzs | data_structure | `V53__employee_hr_module.sql:15-99`; `entity/Employee.java` | ✅ IMPLEMENTED |
| `employee_address` | data_structure | `V53__employee_hr_module.sql:102-115`; `entity/EmployeeAddress.java` | ✅ IMPLEMENTED |
| `employee_bank_account` | data_structure | `V53__employee_hr_module.sql:118-124`; `entity/EmployeeBankAccount.java` | ✅ IMPLEMENTED |
| **`employee_occupational_health` (üzemorvosi, FR-05)** | data_structure | `V256__employee_subrecords.sql:9-19`; `entity/EmployeeOccupationalHealth.java` | ✅ IMPLEMENTED |
| **`employee_vacation` (szabadság, FR-04)** | data_structure | `V256__employee_subrecords.sql:22-36` (uq_employee_vacation_year:34); `entity/EmployeeVacation.java` | ✅ IMPLEMENTED |
| **`employee_child` (gyerekek)** | data_structure | `V256__employee_subrecords.sql:39-46`; `entity/EmployeeChild.java` | ✅ IMPLEMENTED |

> **G19 baseline VERIFIKÁLVA**: a 3 MUST al-tábla (üzemorvosi / szabadság / gyerekek) MOST teljesen le van implementálva — migráció + entity + repository (`EmployeeOccupationalHealthRepository`, `EmployeeVacationRepository`, `EmployeeChildRepository`) + service (`EmployeeSubRecordService.java`, multi-tenant `loadScoped()`:42-50) + controller (`EmployeeSubRecordController.java`, `/api/v1/employees/{employeeId}/{occupational-health|vacations|children}`) + frontend (`EmployeeSubRecordsModal.tsx:37-39`). A G19 „OUT" baseline (okmány/bizonyítvány 1:N feltöltés) változatlanul OUT — lásd FR-03 alább.

### Funkcionális követelmények

| FR | Leírás | Kód-bizonyíték | Státusz |
|---|---|---|---|
| FR-01 | Egységesített füles adatlap | be: `EmployeeController.java` (`/api/v1/employees`), `EmployeeSubRecordsModal.tsx` 3 fül (occ-health/vacations/children) | ✅ IMPLEMENTED |
| FR-02 | Worker bejelentkezési adatok | `entity/Worker.java`, `V2__create_worker_tables.sql` (uk_worker_company_code) | ✅ IMPLEMENTED |
| FR-03 | **Szakmai bizonyítványok 1:N (Becsüs/Eladói/Valutapénztáros, külön checkbox+dátum)** | NINCS dedikált 1:N tábla; csak `employee.vocational_qualification` (egy szabad-szöveg) + `certificate_date` (`V53:71-73`). Külön becsüs/eladói/valutapénztárosi checkboxok + számok = nincs. Keresve: `certificate`, `bizonyítvány`, `vocational` | ⚠️ PARTIAL (egy szöveg-mező; a doc FR-03 „külön checkboxokkal és dátumokkal" leírása NEM teljesül; megegyezik a G19 „OUT" baseline-nal) |
| FR-04 | Szabadságok évenként | lásd `employee_vacation` fent; `EmployeeSubRecordService.addVacation:98-120` (év-validáció + duplikátum-guard) | ✅ IMPLEMENTED |
| FR-05 | Üzemorvosi vizsgálatok | lásd `employee_occupational_health` fent; `EmployeeSubRecordService.addOccupationalHealth:61-72` | ✅ IMPLEMENTED |
| FR-06 | Offline hitelesítés (worker SQLite, HR nem) | `penztar-client/electron/sync-engine.ts` worker-sync (HR al-táblák nincsenek mirror-ölve — konzisztens a doc-kal) | ✅ IMPLEMENTED (HR-mirror tiltás by-design) |
| FR-07 | Kétlépcsős Google OAuth (challenge→dolgozóválasztó→jelszó→JWT) | `GoogleAuthController.java:57` (`/google-login`), `:109` (`/google-vault/select-worker`); `GoogleLoginService.java` | ✅ IMPLEMENTED |
| FR-08 | Szűkített értéktári dolgozó-felvétel (`POST /api/v1/vault-workers`) | `VaultWorkerController.java:27,41`; `VaultWorkerService.java` | ✅ IMPLEMENTED |

### NFR / integráció

| Elem | Doc | Kód-bizonyíték | Státusz |
|---|---|---|---|
| NFR-03 | Keresés/szűrés/lapozás + **CSV/Excel export** az üzemorvosi és szabadság táblákon | `EmployeeSubRecordController` csak GET-list/POST/DELETE — **nincs** szűrés/lapozás/export végpont; `EmployeeSubRecordsModal.tsx` — nincs CSV/Excel. Keresve: `medical-checks`, `export`, `csv` | ❌ MISSING (export + szűrés/lapozás) |
| Integráció | `GET /api/employees/medical-checks` (üzemorvosi szűrés+export) | NEM létezik. A tényleges út `GET /api/v1/employees/{id}/occupational-health` (per-employee lista, export nélkül) | ❌ MISSING (doc-beli endpoint hibás/nem létező) |
| Integráció | `POST /api/employees` / `GET /api/employees/{id}` útvonal | Tényleges prefix `/api/v1/employees` (`EmployeeController.java:31`) — a doc `/api/employees` elírás | ⚠️ DOC-ELTÉRÉS (verzió-prefix hiányzik a doc-ban) |

---

## B) b9-korlevelek-compliance.md

### Adatmodell

| Elem | Doc | Kód-bizonyíték | Státusz |
|---|---|---|---|
| `circular` (metaadatok) | data_structure | `entity/Circular.java` (registration_number:125, title:40, valid_from:114, valid_to:120, archived:166, category:180, attachment_path:108) | ✅ IMPLEMENTED |
| `circular` mező-eltérés | doc: `circular_type`,`target`,`priority` | kód: `circular_type` (Circular.java:60), `target`:68, `priority`:76 — egyezik | ✅ IMPLEMENTED |
| `circular_acknowledgment` | data_structure (worker_id, acknowledged_at, ip_address, acknowledger_role, UNIQUE) | `entity/CircularAcknowledgment.java`; acknowledger_role rögzítés: `CircularService.acknowledgeByWorker:219-229` | ✅ IMPLEMENTED (lásd ip_address lent) |
| `circular_acknowledgment.ip_address` | doc szerint rögzítendő (workflow 2. lépés) | `CircularService.acknowledgeByWorker:224-229` NEM tölti az ip_address-t (builder csak workerId+ack_at+role). A workflow-leírás „rögzíti az IP címet" → kód nem teszi | ⚠️ PARTIAL (ip_address mező létezhet, de a kód nem írja) |
| **SQLite mirror: `circular` + `circular_acknowledgment`** | data_structure: „IGEN, offline kikényszerítés" | `penztar-client/electron/sync-engine.ts:1471-1513` csak `cached_circulars`-t hoz létre (id,subject,body,sender,sent_at) — **eltérő séma**, és **NINCS** `circular_acknowledgment` mirror. `sqlite.ts`-ben nulla circular-találat | ❌ MISSING (ack-mirror + offline kényszerítés nincs) |

### Funkcionális követelmények

| FR | Leírás | Kód-bizonyíték | Státusz |
|---|---|---|---|
| FR-01 | Körlevél metaadatok + verzió-követés | `Circular.java` (lásd fent); `CircularController.java` CRUD+archive+attachment | ✅ IMPLEMENTED |
| FR-02 | **Kötelező visszaigazolás + tranzakció-BLOKKOLÁS (403, ha van olvasatlan)** | Lekérdezés: `CircularService.findUnacknowledgedForCurrentWorker:258`; UI lista+ack: `CircularPage.tsx:114-157`. **DE**: `TransactionService.java`-ban NULLA circular/unacknowledged-ellenőrzés; semelyik tranzakciós végpont nem ad 403-at olvasatlan körlevélre. A penztar-client sem blokkol (nincs ack-mirror). Keresve: `unacknowledged`,`403`,`block` a TransactionService-ben | ❌ MISSING (a blokkoló kényszer — a FR magja — nincs implementálva sem backend, sem kliens oldalon) |
| FR-03 | Bankkártyás-csalás gyanú → SUSPENDED + `customer_screening_log` | `entity/CustomerScreeningLog.java` létezik (result: CLEAR/FLAGGED/BLOCKED:33), de **nincs SUSPENDED állapot**, nincs tranzakció-felfüggesztés („SUSPENDED" tranzakció-státusz a csalásgyanúra) és nincs gyanús-jel rögzítő flow. Keresve: `SUSPENDED`,`customer_screening_log` | ⚠️ PARTIAL (screening-log infra megvan; a 7. körlevél kártyacsalás-specifikus SUSPENDED flow nincs) |
| FR-04 | FATF többszintű besorolás (1/a blokk, 1/b EDD, 2 warning) | Besorolás: `FatfCountryRiskService.classify` (`:106`, tier-ek `:35-46`, LIST_VERSION `:33`). Bekötés: `SanctionScreeningService.screenCustomer(...country...):83` → eredmény `fatfTier`+`fatfRiskCountry` mezőkben (`:90,141`). **DE a tier nem vált ki rendszer-intézkedést**: nincs 1/a-blokk (approved=false), nincs 1/b-EDD-kényszer, nincs 2-warning. Keresve `getFatfTier`/`isHighRisk` a TransactionService-ben: nincs találat | ⚠️ PARTIAL (osztályozás kész + visszaadott label; a doc 3 társuló intézkedése — blokk/EDD/warning — NINCS kódba kötve) |
| FR-04 mellék-bug | AML-flow ország-átadás | `AmlService.checkTransaction:101-102` a `screenCustomer(name,doc,null,null,null,null)` **country-nélküli** overload-ot hívja → a tranzakciós AML-úton a FATF `classify` mindig NONE-t kap (ország nem jut át). Csak a külön `/sanctions/screen` endpoint (`SanctionScreeningController:55`) ad át nationality-t | 🔴 BUG (a fő AML-tranzakcióúton a FATF de facto inaktív) |
| FR-05 | **50M HUF feletti pénzszármazás-igazolás (teljes biz. erejű magánokirat; tanús magánokirat TILT; banki bizonylat ≤3 év)** | NINCS implementáció. Sem dokumentum-feltöltés (származási okirat), sem PUBLIC_DEED/közjegyző/ügyvéd validáció, sem tanús-nyilatkozat elutasítás, sem 3-éves banki bizonylat dátum-check. Keresve: `PUBLIC_DEED`,`teljes bizonyító`,`közjegyző`,`ügyvéd`,`két tanú`,`minusYears(3)`,`originProof`,`fundsOrigin` → 0 releváns találat. Az egyetlen 50M = `AmlService` BIGCTRL TranzTipus 6 küszöb (`:329,440`), ami enhanced-DD jelzés, NEM a doc szerinti okirat-validáció | ❌ MISSING (teljes FR hiányzik) |

### NFR

| NFR | Leírás | Kód-bizonyíték | Státusz |
|---|---|---|---|
| NFR-01 | FATF-ellenőrzés a tranzakció előtt fut | Részben: `/sanctions/screen` előhívható; de a fő AML-úton (`AmlService`) country=null (lásd FR-04 bug) → tranzakció-mentés előtt a FATF nem garantáltan fut éles besorolással | ⚠️ PARTIAL |
| NFR-02 | Megváltoztathatatlan ack-bejegyzés (auditálható) | `CircularAcknowledgment` insert-only + UNIQUE(circular_id,worker_id); acknowledger_role+timestamp | ✅ IMPLEMENTED (ip_address kivételével, lásd fent) |
| NFR-03 | FATF lista verziózás visszakereshető | `FatfCountryRiskService.LIST_VERSION = "FZS-9/2024 (2024-02-27)"` (`:33`) | ✅ IMPLEMENTED |

### Integráció

| Endpoint | Doc | Kód | Státusz |
|---|---|---|---|
| `GET /api/circulars/unacknowledged` | integration | tényleges: `GET /api/v1/circulars/my-unacknowledged` (`CircularController:145`) + `/unacknowledged` (`:68`, company-szintű) | ⚠️ DOC-ELTÉRÉS (prefix + endpoint-név) |
| `POST /api/circulars/{id}/acknowledge` | integration (IP+role rögzítés) | `POST /api/v1/circulars/{id}/acknowledge-worker` (`CircularController:138`); IP NEM rögzül (lásd fent) | ⚠️ PARTIAL |
| `FatfCountryRiskService.classify(String)` | integration | `FatfCountryRiskService.java:106` | ✅ IMPLEMENTED |
| `FatfCountryRiskService.LIST_VERSION` | integration | `:33` | ✅ IMPLEMENTED |

---

## Záró statisztika

- ✅ IMPLEMENTED: 16 (munkavállaló: 9 — beleértve a 3 G19 MUST al-táblát; körlevél: 7)
- ⚠️ PARTIAL / DOC-ELTÉRÉS: 8 (FR-03 bizonyítvány, ip_address, FR-03 SUSPENDED, FR-04 tier-intézkedés, NFR-01, 3 endpoint/path-eltérés)
- ❌ MISSING: 4 (NFR-03 export+szűrés; medical-checks endpoint; körlevél SQLite-ack-mirror + blokkoló kényszer; FR-05 50M okirat-validáció)
- 🔴 BUG: 1 (AML-tranzakcióút country=null → FATF inaktív)

**G19 al-tábla baseline: VERIFIKÁLVA — a 3 MUST (üzemorvosi/szabadság/gyerekek) KÉSZ; az okmány/bizonyítvány 1:N feltöltés továbbra is OUT/PARTIAL (FR-03).**
