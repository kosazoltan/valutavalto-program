# Compliance Audit Checklist — NGM 23/2014 + AML (2017. évi LIII. tv.) + GDPR

> **Hatókör:** Valutaváltó ERP (`excvaluta.com`), EBC Zrt. üzemeltetés.
> **Célközönség:** compliance officer, DPO, külső auditor, NAV/MNB ellenőrzésre felkészülés.
> **Utolsó frissítés:** 2026-05-06.
> **Felülvizsgálat:** éves teljes audit + negyedéves spot-check (lásd 5. szakasz).

> **Eredmény-jelölés:** PASS / PARTIAL / FAIL / VERIFY / GAP.
> **Acceptance kritérium:** minden FAIL azonnal P0-ra emelt incident, javítás a `CLAUDE.md` "AI Review Zero-Tolerance Mandate" szerint. PARTIAL-ok dokumentálandók a vault-ba (`D:\valutavalto-vault\feedback\compliance-<topic>.md`) megoldási dátummal.

---

## 1. NGM 23/2014. (VI. 30.) — Szigorú számadású bizonylatok

> **Forrás:** `D:\valutavalto-vault\references\ngm-szamadas-23-2014.md`.
> **Lényege:** folyamatos, hézag nélküli, egyedi sorszámozás, kiállítás pillanatában VÉGLEGES sorszám. NAV bírság: 500 000 Ft / nem-magán adófizető bizonylat-hiány esetén.

### 1.1 Bizonylat-sorszám folytonosság

| Ellenőrzés | Várt érték | Tényleges | Eredmény |
|---|---|---|---|
| Sorszám-formátum | `V<branchCode>NNNNNN` (Vétel), analóg E (Eladás), K (Konverzió) | Kód: `ReceiptSequenceService.java:91` `String.format("%s%s%06d", prefix, branchCode, nextSeq)` | **PASS** |
| PESSIMISTIC LOCK párhuzamos kiadás ellen | SELECT FOR UPDATE | `ReceiptSequenceService.java:46` PESSIMISTIC LOCK az UTOLSOBLOKKOK táblán | **PASS** |
| Kiállítás pillanatában végleges sorszám (NEM draft) | nincs `draft` / `temp-` prefix server-oldali tranzakcióban | szerver-oldal prefix V/E/K, draft `P-{id}-draft` Electron NEM kerül backendbe — javítva, lásd vault-ref | **PASS** |
| Sztornó sorszám-kezelés | EREDETI típus számlálójából, NEM külön S prefix | `ReceiptSequenceService.java:39` "Stornó: az EREDETI típus számlálójából kap új sorszámot" | **PASS** |
| Folytonosság (gap-detect) | napzárás során ellenőrzött | NavClosingService + napzárási service-ek (verify per branch) | **VERIFY** — manuális SQL: `SELECT branch_code, prefix, COUNT(*) c, MIN(seq), MAX(seq), MAX(seq)-MIN(seq)+1 expected FROM receipt_sequence GROUP BY 1,2 HAVING MAX(seq)-MIN(seq)+1 <> COUNT(*)` |

**Auditor által kérendő:** SQL export `transactions` táblából `receipt_number` szerint a vizsgált időszakra; sorszám-gap-ek listája.

### 1.2 Ügyfél-azonosítás (NGM + Pmt. együtt)

| Mező | Kötelezőség | Implementáció | Eredmény |
|---|---|---|---|
| Egyszerűsített azonosítás (név + igazolvány) | ≥ 100 000 Ft (Pmt. 7.§) | `AmlService.java:62` `SIMPLIFIED_IDENTIFICATION_LIMIT = 100000` + `AmlService.java:140-150` block | **PASS** |
| Teljes azonosítás | ≥ 300 000 Ft | `AmlService.java:65` `IDENTIFICATION_LIMIT = 300000` | **PASS** |
| Részletes azonosítás (bejelentés-köteles) | ≥ 1 500 000 Ft | `AmlService.java:71` `DETAILED_ID_LIMIT = 1500000` | **PASS** |
| Bejelentési küszöb (SAR) | ≥ 2 000 000 Ft | `AmlService.java:628` `REPORTING_THRESHOLD = 2000000` | **PASS** |
| Fokozott átvilágítás | ≥ 4 500 000 Ft | `AmlService.java:631` `ENHANCED_THRESHOLD = 4500000` + `ROLLING_WINDOW_LIMIT_HUF = 4500000` | **PASS** |
| Igazolvány-típusok elfogadott listája | személyi igazolvány / útlevél / vezetői engedély (NGM/Pmt.) | `documentType` mező az `AmlReport` és `Customer` entitásban — verify: `Customer.documentType` tényleges használata UI-ban | **VERIFY** |

### 1.3 PEP nyilatkozat (Politikailag kitett személy)

| Tétel | Várt | Tényleges | Eredmény |
|---|---|---|---|
| PEP screening | minden 300k+ tranzakció előtt | `AmlService.java:471` `Boolean.TRUE.equals(customer.getIsPep())` → TranzTipus 1 | **PASS** |
| PEP nyilatkozat nyomtatása bizonylaton | 300k+ Ft tranzakciónál | `EscPosReceiptService.java:635` "PEP (közszereplő) nyilatkozat — 300k+ Ft tranzakciónál kötelező" | **PASS** |
| Legacy referencia | BLOKNYOM/KozszerepNyilatkozat | `EscPosReceiptService.java:226, 636` | **PASS** |
| `Customer.isPep` NULL-safe handling | NULL → feltételezzük nem-PEP + log warn | `AmlService.java:474` `log.warn("AML: Ügyfél {} isPep=NULL — feltételezzük nem-PEP", customerId)` | **PARTIAL** — működik, de `isPep` NULL warn az ügyfél-felvitel során **kötelezővé** teendő (UI required field). Vault feedback ajánlott. |

### 1.4 Jogcím nyilatkozat

| Tétel | Várt | Tényleges | Eredmény |
|---|---|---|---|
| Jogcím nyilatkozat nyomtatása | bizonyos összeghatár felett (BLOKNYOM/Jogcimnyilatkozat legacy) | `EscPosReceiptService.java:648` referencia jelen | **VERIFY** — pontos összeg-küszöb a kódban dokumentálandó: jelenleg legacy comment, de a tényleges feltétel verify a `EscPosReceiptService` környező logikában |

### 1.5 Sztornó eljárás

| Tétel | Várt | Tényleges | Eredmény |
|---|---|---|---|
| 24 órán belüli indokolható sztornó | reason mező kötelező | `AuditLogService.logWithDetails(..., reason, ...)` támogatja, `AuditLog.reason` mező létezik | **PASS** (mező-szinten) |
| Supervisor jóváhagyás | `requiresApproval` flag a magas összegnél | `AmlService.java:179` `if (!SecurityUtils.isSupervisorOrAbove())` ág | **PASS** AML-szinten; **VERIFY** általános sztornóra (transaction storno service) |
| Göngyölés visszavonás | `AmlService.reverseAccumulation` éves összeg csökkentés + highRiskFlag clear | `AmlService.java:1232-1295` | **PASS** |
| Audit log a sztornóra | `AML_REVERSE_ACCUMULATION` action + entityId | `AmlService.java:1294` | **PASS** |

### 1.6 Napzárás kötelező napi

| Tétel | Várt | Tényleges | Eredmény |
|---|---|---|---|
| Napzárás minden iroda minden nap | NavClosingService napi futás | service létezik (lásd `NavClosingService VAT_RATE → tax_code`, CLAUDE.md "LEZÁRVA" lista) | **VERIFY** — auditor: `SELECT branch_id, MAX(closing_date) FROM nav_closing GROUP BY branch_id HAVING MAX(closing_date) < CURRENT_DATE - 1` |
| Napi AML cache reset | NAPZAR.DLL legacy parity | `AmlService.java:1214` `resetDailyCache()` (DB-alapú, in-memory cache nincs) | **PASS** |
| AML napi export hatóságnak | `AmlDailyExportDto` generálható | `AmlService.java:1067` `generateDailyExport(date)` | **PASS** (technikai), **VERIFY** napi automatikus küldés (vagy manuális admin export) |

### 1.7 5 + 8 éves archiválás

| Tétel | Várt | Tényleges | Eredmény |
|---|---|---|---|
| Üzleti retention financial-transactions | min. 8 év (NGM) | `application.properties:123` `retention.financial-transactions.years=8` | **PASS** (cél), VERIFY a tényleges archív policy futása |
| Hard delete kikapcsolva alapból | igen | `application.properties:124` `retention.financial-transactions.hard-delete-enabled=false` | **PASS** |
| Havi archiválás (`MonthlyArchiveService`) | aktív | `MonthlyArchiveService.java:57` `archiveMonth(branchId, yearMonth)` + retention log line `:127` | **PASS** |
| Daily closing archive | `archiveBeforeYear` aktív | `DailyClosingArchiveService.java:299` | **PASS** |
| Audit log retention | min. 5 év (NGM/MNB ajánlás), de NEM törlendő ameddig business retention | a `audit_log` tábla NEM tartalmaz expiry mechanizmust (verify), így indefinite | **PARTIAL** — nincs explicit policy a vault-ban. Javasolt: 8 év retention (üzleti összhang), utána szelektív exportálás archív storage-ba. |

---

## 2. AML (2017. évi LIII. tv. — Pmt.)

> **Forrás:** `AmlService.java` BIGCTRL.DLL parity + Pmt. küszöbök.
> **Hatóság:** NAV Pénzmosás Elleni Információs Iroda (FIU).

### 2.1 Szankciós lista ellenőrzés

| Tétel | Várt | Tényleges | Eredmény |
|---|---|---|---|
| Kötelező 1. ellenőrzés tranzakció előtt | minden ügyfél névnél | `AmlService.java:97-122` `if (customerName != null && !customerName.isBlank()) { sanctionScreeningService.screenCustomer(...) }` | **PASS** |
| Tranzakció elutasítása találat esetén | `approved=false` + rejection reason | `AmlService.java:104-108` | **PASS** |
| Belső tiltólista (ProhibitedPerson) | név + okmány alapján | `AmlService.java:113` `blacklistService.findActivePersonMatch(customerName, documentNumber)` | **PASS** |
| Szankciós lista naprakészen tartása | rendszeres frissítés | **VERIFY** — `SanctionScreeningService` lista forrás + frissítési policy nincs ebben a runbookban dokumentálva |

### 2.2 BIGCTRL 6 szintű kockázati besorolás

| TranzTipus | Küszöb | Tényleges (`AmlService.classifyTransaction`) | Eredmény |
|---|---|---|---|
| 6 (kiemelt) | heti göngyölt ≥ 50M Ft | `AmlService.java:425` | **PASS** |
| 5 (fokozott) | heti göngyölt ≥ 10M Ft | `AmlService.java:430` | **PASS** |
| 4 (negyedéves) | 4+ tranzakció ÉS ≥ 25M / negyedév | `AmlService.java:436-437` | **PASS** |
| 3 (éves ismétlődő) | éves max ≥ 8M ÉS heti göngyölt ≥ 8M | `AmlService.java:443-444` | **PASS** |
| 2 (külföldi) | `customer.isForeign=true` | `AmlService.java:457` | **PASS** |
| 1 (PEP) | `customer.isPep=true` | `AmlService.java:471` | **PASS** |
| -1 (külföldi+USD blokk) | `isForeign=true && currencyCode='USD'` | `AmlService.java:459-462` | **PASS** |
| 8 napos rolling window | ≥ 4.5M Ft (Pmt. 33.§) | `AmlService.java:639` `ROLLING_WINDOW_LIMIT_HUF = 4500000` | **PASS** |
| Manager jóváhagyás kötelező | TranzTipus ≥ 4 vagy rolling window túllépés | `AmlService.java:588` | **PASS** |

### 2.3 Magas kockázatú ügyfél (highRiskFlag)

| Tétel | Várt | Tényleges | Eredmény |
|---|---|---|---|
| Éves göngyölési limit | 3 600 000 Ft (természetes személy) | `AmlService.java:68` `ANNUAL_ROLLING_LIMIT = 3600000` | **PASS** |
| highRiskFlag automata beállítás | éves összeg eléri a limitet | `AmlService.java:958` `setHighRiskFlagIfNeeded()` | **PASS** |
| Audit log a flag-re | `AML_HIGH_RISK_SET` action | `AmlService.java:978` | **PASS** |
| Migration | V90 customer_high_risk_flag | `db/migration/V90__customer_high_risk_flag.sql` | **PASS** (létezik) |
| Sztornó utáni flag clear | göngyölési limit alá ese | `AmlService.java:1273-1278` | **PASS** |

### 2.4 Bejelentési kötelezettség (Pmt. 33.§)

| Tétel | Várt | Tényleges | Eredmény |
|---|---|---|---|
| Gyanús tranzakció jelzés | `suspiciousFlag` napi 900k+ kumulált | `AmlService.java:74` `DAILY_SUSPICIOUS_LIMIT = 900000` + `:192-196` flag setting | **PASS** |
| Structuring detektálás | 3+ tranzakció a limit 80%+-án | `AmlService.java:647-650` `STRUCTURING_MIN_TRANSACTIONS = 3, STRUCTURING_RATIO = 0.80` | **PASS** |
| AML bejelentés létrehozás | `AmlReport` entitás DRAFT státusszal | `AmlService.java:825-862` `submitReport()` | **PASS** |
| Bejelentési határidő | **2 munkanap** (Pmt. 33.§) | `AmlService.java:855-857` `calculateBusinessDayDeadline(createdNow, 2)` magyar munkaszüneti napokkal | **PASS** |
| Lejárt bejelentés (`OVERDUE`) automata jelölés | naponta scheduler | `AmlService.java:786` `checkAndMarkOverdueReports()` `@Scheduled` | **PASS** |
| Auto-trigger gyanús tranzakcióra | **GAP** — jelenleg manuális bejelentés (`submitReport(dto)` controller-en át) | nincs auto-detect → AML report DRAFT auto-create | **PARTIAL** — bejelentés-köteles (REPORTING_THRESHOLD ≥ 2M) tranzakciónál ajánlott auto-DRAFT létrehozás supervisor review-val |
| Hatósági benyújtás workflow | DRAFT → SUBMITTED → ACKNOWLEDGED | `AmlService.java:992-1057` állapot-géppel | **PASS** |

### 2.5 4 órás bejelentési határidő — VERIFY

A felhasználói tasklist említ "4 órás bejelentési határidő"-t. **A kódban NEM találtam 4 órás scheduler-t**: az aktív policy a Pmt. 33.§ **2 munkanap** (`AmlService.java:855` `calculateBusinessDayDeadline(createdNow, 2)`).

| Tétel | Eredmény |
|---|---|
| 4 órás határidő scheduler | **NINCS** a kódban — `AmlService.calculateBusinessDayDeadline` 2 munkanapot számol |
| Megfelelőség Pmt. 33.§-nak | **PASS** (2 munkanap a törvényi határidő) |
| Ha üzleti igényként kell 4 órás | **GAP** — implementálandó vagy az igény pontosítandó |

---

## 3. GDPR (EU 2016/679) — Adatvédelem

### 3.1 Személyes adatok retention

| Adattípus | Üzleti retention | GDPR-jog ütközés? | Eredmény |
|---|---|---|---|
| `customer.*` PII (név, igazolvány-szám, cím) | 8 év (NGM összhang) | "elfeledtetéshez való jog" ütközik az NGM kötelezettséggel | **PARTIAL** — jogszabályi alap (Pmt. 56-58.§) felülírja a GDPR 17.§-t (right to erasure), DE explicit írásbeli policy szükséges (DPO-nak elkészíteni) |
| `transactions.*` üzleti adat | 8 év (`retention.financial-transactions.years=8`) | jogszabályi alap erősebb | **PASS** (legitim érdek + jogi kötelezettség) |
| `audit_log.*` | indefinite (jelenlegi) | retention policy hiánya | **PARTIAL** — javasolt 8 év üzleti összhangra |
| `client_error_log.*` | 90 nap (V182 COMMENT) | nincs PII-szabad design — `user_identifier` mező Google email/worker code | **PARTIAL / VERIFY DEPLOY** — a 90 napos cleanup timer commitolva (`deploy/hetzner/scripts/setup-client-error-cleanup.sh`), élő systemd timer státusz SSH-val ellenőrizendő |
| Camera felvétel | 50 nap (`application.properties:112` `camera.retention-days=50`) | titkosított (AES-GCM) | **PASS** |
| `worker.*` (munkavállalói adatok) | aktív foglalkoztatás + 5 év | **VERIFY** — explicit retention konfig nincs a kódban |

### 3.2 Adatkezelési tájékoztató

| Tétel | Várt | Tényleges | Eredmény |
|---|---|---|---|
| Tájékoztató az ügyfél-felvitelnél | UI-on link/checkbox | **VERIFY** — `frontend-react/src/pages/Customers*` és `penztar-client` ügyfél-form ellenőrzendő |
| Bizonylaton lábjegyzet | adatkezelési hivatkozás | **VERIFY** — `EscPosReceiptService` footer szöveg ellenőrzendő |
| Munkavállalói tájékoztató | belső HR dokumentum | **VERIFY** — repón kívüli, EBC Zrt. HR feladata |

### 3.3 Munkavállalói adatok

| Tétel | Várt | Tényleges | Eredmény |
|---|---|---|---|
| `worker` tábla mezőlista PII-szempontból | csak szükséges adatok | **VERIFY** — DPO entity-review (név, email, telefon, iratazonosítók?) |
| Hozzáférés-szabályozás | `@PreAuthorize` minden controlleren | **PASS** projekt-szinten (`CLAUDE.md` Security szabály) |
| Login audit | minden login esemény | `AuditLogService.logSecurityEvent()` használt | **PASS** |
| Jelszó-titkosítás | bcrypt + reset token | implicit a `JwtService` + `WorkerService` reset flow-ban (`V184/V186` reset migration-ök) | **PASS** (technikai) |
| Google OAuth login (V178/V179) | Workspace `hd` claim + email whitelist | `application-production.properties:96-98` | **PASS** |

### 3.4 Kameraképek

| Tétel | Várt | Tényleges | Eredmény |
|---|---|---|---|
| Retention | 50 nap | `application.properties:112` | **PASS** |
| Titkosítás-at-rest | AES/GCM 256 | `application.properties:116-118` | **PASS** |
| Production-on bekapcsolva? | `camera.enabled=false` production-on | `application-production.properties:133` | **PASS** (server-on nincs webcam, csak kliens-oldal) |
| Kapcsolódó V97 seal_tracking + V98 led_display_config | migrations alkalmazva | `db/migration/V97__seal_tracking.sql`, `V98__led_display_config.sql` | **PASS** |

### 3.5 Adatkezelő/adatfeldolgozó szerződések (GDPR 28.§)

| Tétel | Eredmény |
|---|---|
| Hetzner Cloud (hosting) — DPA | **VERIFY** EBC Zrt. jogi |
| Cloudflare (DNS/CDN) — DPA | **VERIFY** EBC Zrt. jogi |
| Google (OAuth) — DPA | **VERIFY** EBC Zrt. jogi |
| Storage Box (off-site backup) — DPA | **VERIFY** EBC Zrt. jogi (Hetzner-en belül, de külön szerződés) |
| Neon (DB backup sync — alapból kikapcsolt) | nem releváns ha `app.neon-sync.enabled=false` |

---

## 4. Audit log integritás (cross-cutting)

| Tétel | Várt | Tényleges | Eredmény |
|---|---|---|---|
| Hash-lánc (tamper-evidence) | SHA-256 + previous_hash | `AuditLogService.java:135` `applyHashChain()` | **PASS** |
| Lánc folytonosság-ellenőrzés rendszeresen | havi cron | **GAP** — automatikus check nincs commit-olva |
| Multi-tenant company_id szűrés | minden lekérdezésen | `AuditLogService.java:30-36` `resolveCompanyId()` + minden query company-scoped | **PASS** |
| CSV export | hatósági / belső audit | `AuditLogService.java:232 exportLogsCsv` + `:375 exportFullCsv` | **PASS** |
| Logged események listája | RATE_CHANGE, AML_HIGH_RISK_SET, AML_REPORT_*, security events, transaction events | `AuditLogService.java:290-332` mind dedikált metódus | **PASS** |

---

## 5. Audit gyakoriság és lefutás

### 5.1 Éves teljes audit (november — NAV év-vége előtt)

Teljes checklist (1-4 szakasz) — minden tétel PASS / dokumentált PARTIAL / 0 db FAIL.

**Auditor által kérendő dokumentumok és kivonatok:**

1. **Bizonylat-folytonosság** SQL export `transactions.receipt_number` (1.1).
2. **AML báze** — éves `AmlReport` lista (`AmlService.generateDailyExport` aggregálva), DRAFT/SUBMITTED/ACKNOWLEDGED státusz-bontás.
3. **Audit log CSV** export az audit időszakra (`AuditLogService.exportFullCsv`).
4. **Hash-lánc verifikáció** SQL: `SELECT id, entry_hash, previous_hash FROM audit_log ORDER BY id` + külső script-tel re-hash + chain-check.
5. **Retention compliance** — `MonthlyArchiveService` + `DailyClosingArchiveService` log-jai.
6. **Magas kockázatú ügyfél lista** (`Customer.highRiskFlag=true`) + `AML_HIGH_RISK_SET` audit események.
7. **Rolling window audit** (`AmlService.getRollingWindowAudit()`, `:1151`).
8. **Szankciós szűrési riport** — találatok száma, false-positive arány.
9. **Munkavállalói login események** (`SecurityEvent` audit log szűrés).
10. **Backup integritás-bizonyíték** — utolsó 12 havi backup SHA-256 lista.
11. **Hetzner / Cloudflare / Google DPA** kópiák (jogi forrás).

### 5.2 Negyedéves spot-check

- 1.1 (sorszám-folytonosság random branch + dátum)
- 2.1 (szankciós szűrés napló random napon)
- 2.4 (`OVERDUE` AML report MUST = 0)
- 4 (audit hash-lánc 100 random sorra)
- `client_error_log` top 10 minta felülvizsgálat (`monitoring-runbook.md` 5.)

### 5.3 Havi review (DPO + üzemeltetés)

- Backup drill (`dr-backup-runbook.md` 8.)
- Top error patterns (`monitoring-runbook.md` 5.)
- AML overdue (azonnal incident, ha bármi)
- HighRiskFlag újonnan beállítva — manuális review kötelező?

---

## 6. Konklúzió és gap-list

### 6.1 Erős pontok (PASS, kód-szinten verifikált)

- Sorszám-folytonosság PESSIMISTIC LOCK-kal (NGM 23/2014).
- 8 szintű AML kockázati osztályozás teljes legacy parity.
- Szankciós lista szűrés MINDEN ügyfél-tranzakciónál első ellenőrzésként.
- Audit log SHA-256 hash-lánc (tamper-evidence).
- 8 év üzleti retention (NGM összhang) + soft archive default.
- Kamera AES-GCM titkosítás + 50 nap retention.
- 2 munkanapos AML bejelentési határidő magyar munkaszüneti napok kezelésével.

### 6.2 Gap-list — javítandó

| Gap | Szakasz | Prioritás | Javasolt fix |
|---|---|---|---|
| Sorszám-folytonosság havi automata SQL check | 1.1 | P1 | cron + email DPO |
| Igazolvány-típus enum a kódban | 1.2 | P2 | `Customer.documentType` enum (SZEMELYI/UTLEVEL/JOGOSITVANY) |
| `Customer.isPep` UI required field | 1.3 | P1 | frontend-react ügyfél-form validáció |
| Jogcím nyilatkozat összeg-küszöb dokumentálás | 1.4 | P2 | EscPosReceiptService kommentbe + audit |
| Általános sztornó supervisor jóváhagyás | 1.5 | P1 | TransactionStornoService verify, ha hiányzik → @PreAuthorize HAS_ROLE_SUPERVISOR |
| Napzárás-kimaradás daily cron alert | 1.6 | P0 | SQL: `MAX(closing_date) < CURRENT_DATE - 1` → DPO email |
| `audit_log` retention policy explicit | 1.7 / 4 | P1 | vault `feedback/audit-log-retention.md` + (lehet 8 év, indefinite is OK ha jogalap erős) |
| Auto-DRAFT AML report bejelentés-köteles tranzakciónál | 2.4 | P1 | `AmlService.checkAllThresholds` után automata `submitReport(dto)` ha `requiresEnhanced && !exists` |
| 4 órás bejelentési határidő (ha üzleti igény) | 2.5 | VERIFY | igényt pontosítani — Pmt. 33.§ szerint 2 munkanap a törvényi |
| Audit log hash-lánc havi automata verify | 4 | P1 | scheduled job + lánc törés detect → DPO incident |
| Adatkezelési tájékoztató UI-on | 3.2 | P0 | ügyfél-form checkbox + bizonylat lábjegyzet |
| `worker` retention explicit policy | 3.3 | P1 | DPO + HR konfig |
| Munkavállalói GDPR review (entity-mezőlista) | 3.3 | P2 | DPO entity-szintű audit |
| Hetzner / Cloudflare / Google DPA összegyűjtés | 3.5 | P0 | jogi feladat (auditor-által kérendő) |
| Szankciós lista frissítési policy dokumentálás | 2.1 | P1 | `SanctionScreeningService` forrás + cadence |
| `client_error_log` 90 napos cleanup timer élő verifikáció | 3.1 | P1 | `systemctl list-timers valuta-client-error-cleanup.timer` |

### 6.3 Acceptance

- **0 db FAIL** kötelező az éves audit lezárásához.
- **PARTIAL** csak akkor elfogadható, ha a vault-ban (`D:\valutavalto-vault\feedback\compliance-<topic>.md`) dokumentált megoldási dátum van, és a DPO aláírta.
- **VERIFY** tételeknél a felelős mellé személy + határidő rögzítendő.

---

## 7. Hivatkozások

**Kódbázis (tényalapú claim-ek):**

- `backend/src/main/java/hu/puzzleir/valuta/service/AmlService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/AuditLogService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/ReceiptSequenceService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/EscPosReceiptService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/MonthlyArchiveService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/DailyClosingArchiveService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/GitHubIssueAutoCreator.java`
- `backend/src/main/java/hu/puzzleir/valuta/controller/DiagnosticsController.java`
- `backend/src/main/resources/application.properties`
- `backend/src/main/resources/application-production.properties`
- `backend/src/main/resources/db/migration/V90__customer_high_risk_flag.sql`
- `backend/src/main/resources/db/migration/V97__seal_tracking.sql`
- `backend/src/main/resources/db/migration/V98__led_display_config.sql`
- `backend/src/main/resources/db/migration/V182__client_error_log_table.sql`

**Vault hivatkozások:**

- `D:\valutavalto-vault\references\ngm-szamadas-23-2014.md`
- `D:\valutavalto-vault\feedback\session-closing-protocol-mandatory.md`
- `D:\valutavalto-vault\feedback\own-server-data-access.md`

**Kapcsolódó runbook:**

- `docs/operations/dr-backup-runbook.md`
- `docs/operations/monitoring-runbook.md`

**Lezárás:** ez a checklist a 2026-05-06-i repo-állapotra tényalapú. A kód oldali compliance erős (NGM sorszámozás, AML 8 szint, szankciós szűrés, hash-lánc) — a fő gap-ek operatív/dokumentációs jellegűek (DPA-k, retention policy explicit dokumentálása, adatkezelési tájékoztató UI).
