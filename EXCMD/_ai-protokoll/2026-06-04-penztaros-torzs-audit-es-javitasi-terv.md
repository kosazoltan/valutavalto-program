# Pénztáros (Worker/Employee) törzsadatbázis audit + javítási terv

**Dátum:** 2026-06-04
**Hatókör:** A pénztáros/dolgozó (`Worker` = login/jogosultság entity, `Employee` = HR/bér PII törzs)
mesteradatbázis biztonsági + funkcionális auditja, **ugyanolyan mélységben**, mint a korábbi Pénztár
(Branch) Törzs audit (#1025). Builder-mód: a talált valódi hibák **javítva** lettek, nem csak elemezve.
**Módszer:** ground-truth — kód, repo-tény, fordítás (`mvnw compile`), célzott teszt-suite (`131` zöld),
saját adverszariális self-review subagent. Hazugság/hallucináció nélkül, kizárólag a kód tényeire alapozva.

---

## Összefoglaló tábla

| Azon. | Súly | Terület | Állapot | Megjegyzés |
|-------|------|---------|---------|------------|
| P0-1 | KRITIKUS | Multi-tenant IDOR | ✅ JAVÍTVA | Employee cross-tenant PII (TAJ/adóazonosító/bér/bankszámla) szivárgás |
| P0-2 | KRITIKUS | Multi-tenant IDOR | ✅ JAVÍTVA | Worker-kötés idegen céghez (create+update) |
| B1   | KÖZEPES  | Multi-tenant IDOR | ✅ JAVÍTVA | `GET /workers/{id}/roles` cross-tenant role-kód szivárgás (self-review találat) |
| P1-2/3 | KÖZEPES | Funkcionális | ✅ JAVÍTVA | `Worker.region` sosem állt be → publikus dolgozó-kereső üres listát adott |
| P2-1 | ALACSONY | Validáció | ✅ JAVÍTVA | Hiányzó `@Email` (4 DTO) |
| P2-2 | ALACSONY | Validáció | ✅ JAVÍTVA | Hiányzó `@Size` PII-mezőkön (Employee) |
| P2-3 | KÖZEPES  | Jelszó-policy | ✅ JAVÍTVA | `resetPassword` nem kérte a create-kori komplexitást → gyenge élő jelszó |
| P3-1 | ALACSONY | Robusztusság | ✅ JAVÍTVA | NPE-biztos `"MANAGER".equals(...)` |
| P3-2 | ALACSONY | Megfigyelhetőség | ✅ JAVÍTVA | bulk-email catch szerver-oldali log (PII nélkül) |
| P1-1 | — | Auth-gate | ⛔ HAMIS POZITÍV | WorkerController read-endpointok: a service companyId-scope-olt + `/active` pénztáros-kritikus |
| P2-4 | — | Import-mapping | ⛔ ELVETVE | `mapJsonToEmployee` 2 mező — dormant import, élő DTO-út helyes, forrás-fejléc nem verifikált |
| changePwd | — | Jelszó-policy | ℹ️ DOKUMENTÁLVA | `changePassword` sincs komplexitás — meglévő, külön kör |

---

## Valódi hibák és javítások (bizonyítékkal)

### P0-1 — Employee cross-tenant PII IDOR (KRITIKUS)
**Bizonyíték:** `EmployeeService.findEmployeeOrThrow` korábban `employeeRepository.findById(id)`-t hívott
companyId-ellenőrzés nélkül; a `getById`/`updateEmployee`/`deleteEmployee` ezen át idegen cég dolgozójának
`EmployeeDto`-ját adta vissza, ami érzékeny PII-t tartalmaz (TAJ, adóazonosító, bér, bankszámla, anyja neve)
→ GDPR/Pmt. sértés.
**Fix:** `findEmployeeOrThrow` most `SecurityUtils.getCurrentCompanyId()` alapján guardol; idegen cég → 404
(`EmployeeSubRecordService.loadScoped` azonos mintája).

### P0-2 — Worker-kötés cross-tenant (KRITIKUS)
**Bizonyíték:** `createEmployee`/`updateEmployee` a `dto.getWorkerId()`-t `workerRepository.findById`-vel
oldotta fel → idegen cég workere köthető volt egy dolgozóhoz.
**Fix:** `workerRepository.findByIdAndCompanyId(workerId, companyId)` mindkét ágon (a repo-metódus létezik).

### B1 — `GET /api/v1/workers/{id}/roles` cross-tenant role-kód szivárgás (KÖZEPES, self-review találat)
**Bizonyíték:** `WorkerRoleService.getRoleCodesForWorker` → `assignmentRepository.findByWorkerId(workerId)` —
**nincs companyId-scope**, a `Worker.id` szekvenciális `Long` (felsorolható). Egy A cég felhasználója B cég
workerId-jére lekérhette annak operatív szerepkör-kódjait.
**Fontos:** a service-be tett companyId-guard **eltörné a bejelentkezést** — a `getRoleCodesForWorker`-t
login/first-time-setup/Google flow-k hívják auth-kontextus NÉLKÜL (AuthController, GoogleLoginService,
WorkerFirstTimeSetupService, SetupGoogleIdentificationService).
**Fix:** kizárólag a controller-úton, `WorkerController.getWorkerRoles` előbb a companyId-scope-olt
`workerService.findById(id)`-vel kényszeríti ki a tenancy-t (idegen cég → hiba). Login/setup érintetlen.

### P1-2/P1-3 — `Worker.region` sosem állt be (KÖZEPES, funkcionális)
**Bizonyíték:** `createWorker`/`updateWorker` nem állította a `region` mezőt → API-n létrehozott worker
region-je NULL. A publikus dolgozó-azonosító (`PublicBranchController` →
`findByCompanyIdAndRegionAndActiveTrue`) region nélkül ÜRES listát ad → az ilyen worker láthatatlan.
**Fix:** a dolgozó régiója = az **irodája** régiója (auto-derivált, mindig szinkronban):
`createWorker` builder `.region(branch.getRegion())`; `updateWorker` iroda-váltáskor
`worker.setRegion(branch.getRegion())`. (Egyetlen más kódhely sem állítja kézzel a `Worker.region`-t →
nincs felülírt manuális érték.)

### P2-1 / P2-2 — Validációs hardening (ALACSONY)
**Fix:** `@Email` a `CreateWorkerDto`/`UpdateWorkerDto`/`CreateEmployeeDto`/`UpdateEmployeeDto` email-mezőin;
`@Size(max=…)` a PII-mezőkön (Employee: taxId 20, ssn 20, email 200, phone 30, feor 10 — pontosan a
DB-`@Column(length)` értékek). Így túlcsordulás tiszta 400-at ad nyers 500 helyett. **Nincs regresszió:**
a Bean Validation `@Email`/`@Size`/`@Pattern` null-toleráns, a `@Size(max)` = oszlophossz nem utasíthat el
perzisztálható meglévő értéket. **Szigorú `@Pattern` (TAJ/adóazonosító jegyszám) SZÁNDÉKOSAN nincs:** a 196
importált dolgozó tárolt formátuma nem verifikált, és a teljes DTO újra-validálódna minden részleges
módosításnál → regresszió-kockázat.

### P2-3 — `resetPassword` jelszó-komplexitás (KÖZEPES)
**Bizonyíték:** `WorkerManagementController.resetPassword` csak hosszt (8–128) ellenőrzött; a
`WorkerManagementService.resetPassword` `passwordChangedAt = now()`-ot állít, **nincs kényszerített csere**
→ a reset-jelszó azonnal élő, korlátlanul használható login-jelszó. Egy MANAGER `"12345678"`-ra resetelhetett
(a create-út `@Pattern`-je ezt tiltja). **Valódi inkonzisztencia.**
**Fix:** a create-tel bitre azonos komplexitás (`^(?=.*[A-Z])(?=.*[0-9]).*$`). A teszt frissült: a 8-karakter
hossz-határ szándékát komplexitás-kompatibilis jelszóval (`Pass1234`) őrzi, + új teszt a `"12345678"`
elutasítására (a teszt korábban egy bizonytalan, gyenge elvárást kódolt).

### P3-1 / P3-2 — Robusztusság + megfigyelhetőség (ALACSONY)
**P3-1:** `WorkerService` role-csere ellenőrzés `!"MANAGER".equals(getCurrentRole())` (literal-first,
NPE-biztos, konzisztens a `isSupervisorOrAbove` null-check-jével).
**P3-2:** `WorkerController` bulk-email catch most `@Slf4j` + `log.warn(workerCode, ok)` — a hiba a válaszban
is megjelenik, de admin bulk-mutációnál szerver-oldali audit-nyom is marad. **PII (email) NEM kerül logba.**

---

## Elvetett / hamis pozitívok (indokkal)

- **P1-1 (HAMIS POZITÍV):** „A WorkerController read-endpointok @PreAuthorize nélkül vannak." → blanket
  SUPERVISOR+ gate (a) eltörné a pénztáros tranzakció + forgalmi riport flow-t (`/workers/active`-et a
  `frontend-react/transactions.ts` és a `CashierTurnoverReportPage` hívja), (b) felesleges, mert a
  `WorkerService` MINDEN read-metódusa (`findById`, `findAllByCompany`, `findActiveWorkers`, `findByBranch`)
  service-rétegben companyId-scope-olt → **nincs cross-tenant szivárgás**. (A `getWorkerRoles` volt az
  egyetlen kivétel → lásd B1, külön javítva.)
- **P2-4 (ELVETVE):** `mapJsonToEmployee` nem mappel `employmentEndDate`/`workHoursPerDay`-t. Az **élő**
  DTO-út (`createEmployee`/`updateEmployee`) ezt **helyesen** mappeli; a JSON-import egyszeri, lefutott
  historikus művelet, a forrás-fejléc nevek nem verifikáltak → guessed kulcs csendben null-t adna
  (no-guessing elv).
- **changePassword komplexitás (DOKUMENTÁLVA):** a `ChangePasswordDto` szintén nem kér `@Pattern`-t. Valós,
  de **meglévő** inkonzisztencia, nem ennek a körnek a regressziója — külön körben zárható.

---

## Ellenőrzés

- `mvnw -o compile` → **BUILD SUCCESS**
- Célzott teszt-suite (`*Worker*,*Employee*,*PublicBranch*,*Auth*,*GoogleLogin*`) → **131 teszt, 0 hiba**
- Saját adverszariális self-review subagent → B1 megtalálva + javítva, többi javítás megerősítve helyesnek
- Érintett fájlok: 8 main + 1 test (lásd PR diff)
