# Claude Code korrekciós mandate — valutaváltó ERP

**Készítette:** Perplexity Computer (Kósa Zoltán kérésére)
**Készült:** 2026-05-17
**Célja:** A `claude-code-mukodes-leiras-2026-05-16.md` (Claude Code önleírás) és a `valutavalto-program-mukodes-leiras-2026-05-16.md` (program-specifikáció) összevetése után konkrét, végrehajtható javítások a Claude Code-nak, hogy a tényleges üzleti / biztonsági / szabályozási követelményeket valósítsa meg, ne csak a fejlesztői workflow-t kövesse.

---

## 0. Vezetői összefoglaló — mi a fő probléma

A Claude Code önleírása **technikailag korrekt fejlesztői workflow-t** ír le. DE **kritikus üzleti / szabályozási dimenziókat NEM ír le explicit ellenőrzési pontként**:

1. **Pmt. (2017. évi LIII. tv.) compliance** — 100k / 300k HUF küszöbök, PEP, AML — nincs külön mandate.
2. **Pénzügyi adatintegritás** — `készlet = SUM(tranzakciók)` invariáns, idempotency, sorszámozás, HUF-kerekítés.
3. **Multi-tenant data leak** — a `company_id` szűrés minden repository-n kötelező. Nincs cross-tenant test mandate.
4. **Local-first + offline + outbox** garanciák — a pénztáros nem veszíthet adatot.
5. **NGM / MNB / NAV jelentések** — szabályozási kimenetek, határidőkkel (MNB 14:30).
6. **Production-first elv** részben sérülhet a "TDD lokál teszt" lépés miatt.
7. **Sztornó szabályok** — "csak ugyanazon a napon + ugyanazzal a worker-rel".
8. **Code signing függő release** — DigiCert EV CS HSM kiadásig TILOS unsigned `Penztar-Setup.exe`-t publikálni.
9. **Az "AI önminősítés" gyengesége** — a "vakfoltok" szakasz saját bevallás, ellenőrzési mechanizmus nélkül.

---

## 1. Új, kötelező mandate-szabályok (9 db)

### 1.1 Pmt. (AML) invariáns mandate — `feedback_pmt_aml_invariants.md`

A Pmt. (2017. évi LIII. tv.) küszöbértékei **kódban hard-coded, backend-szinten enforced** invariánsok. Soha NEM szabad:
- a 100 000 HUF identifikáció-küszöböt frontend-only validációvá gyengíteni,
- a 300 000 HUF PEP + saját-név küszöböt opcionálissá tenni,
- a napi aggregáció szabályt kikapcsolni,
- a sanction-list ellenőrzést cache-only módban végrehajtani backend revalidáció nélkül,
- a SAR (suspicious activity report) flag-et automatikus → manuálissá tenni.

**Kötelező regressziós tesztek:** `AmlThresholdTest`, `PepDeclarationTest`, `SanctionListEnforcementTest`, `DailyAggregationTest`, `SarAutoFlagTest`.

Ha bármelyik P0/P1 finding a fenti területet érinti, **automatikusan eskalálni** kell a felhasználónak (Kósa Zoltán) **a merge ELŐTT**, NEM után. A 9-fázisú zárási protokoll 9. lépésében (záró jelentés) explicit ki kell mondani: "Pmt. invariáns sértetlen — `AmlThresholdTest` + 4 további zöld".

### 1.2 Pénzügyi adatintegritás invariáns — `feedback_financial_invariants.md`

1. **`készlet = SUM(tranzakciók)` — semmi külön counter.** Bármelyik PR, amely független `cashCounter` mezőt vezet be, **P0 reject**.
2. **Idempotency-Key kötelező minden write-on** (kivéve `/auth/`, `/public/`, health, OAuth callback, telemetria). Új write endpoint esetén a whitelist NEM bővíthető jóváhagyás nélkül.
3. **Bizonylat-sorszám atomic + monoton + iroda-szintű no-skip.** `V<3-jegyű iroda><6-jegyű sorszám>` formátum sosem ugorható, sosem duplikálható. DB-szekvencia vagy `SELECT ... FOR UPDATE`, nem alkalmazás-szintű counter.
4. **HUF kerekítés (`roundHuf`)** kötelező minden HUF display + print + bizonylat előtt.
5. **Árfolyam validity (`Rate.validTo > now()`)** ellenőrzés a tranzakció **belépésekor** kötelező, NEM a végén.
6. **Spring `@Transactional` minden write servicen.** PR-review-ban explicit ellenőrizendő.
7. **Készlet-korrekció** kizárólag MAIN_TREASURY szerepkörrel + audit-log + indoklás kötelező.

### 1.3 Multi-tenant izoláció mandate — `feedback_multitenant_isolation.md`

Minden új repository / service / controller esetén kötelező:
1. **Cross-tenant integration test** — 2 különböző `companyId`-val futtatott szcenárió, ahol a B cég dolgozója NEM láthatja az A cég adatait.
2. **`@PreAuthorize` minden endpoint-on** — review-ban explicit ellenőrizendő.
3. **`SecurityContextHolder`-ból olvasott `companyId`** — soha NEM a kliens által küldött paraméterből.

A 9-fázisú protokoll 2. lépésében explicit kell futnia egy `MultiTenantIsolationTest`-csomagnak.

### 1.4 Local-first + offline + outbox garancia mandate — `feedback_offline_outbox.md`

A pénztáros NEM veszíthet adatot. Kötelező:
1. **Local SQLite write FIRST** — minden tranzakció ELŐSZÖR a lokál DB-be, csak utána outbox.
2. **Outbox queue 3× retry** (ESET TLS proxy miatt).
3. **Heartbeat 60s alapértelmezett, Zod-validált.** Config-séma változása P1 finding ha Zod-validáció gyengül.
4. **Outbox replay test** — minden release előtt: 100 tranzakció lokál SQLite-ba mentve offline állapotban, majd online → mind 100 megérkezik a backend-re, idempotency-key alapján duplikáció nélkül.
5. **Konfliktus-feloldás:** last-write-wins **csak** ha az időbélyegek 5s-en belül vannak; egyébként manual review queue.

### 1.5 Szabályozási kimenetek határidő-mandate — `feedback_regulatory_deadlines.md`

| Jelentés | Címzett | Határidő | Hibakor |
|---|---|---|---|
| MNB napi árfolyam | MNB | minden munkanap **14:30** | P0 escalation, manuális azonnal |
| NGM havi tranzakció-aggregátum | NGM | tárgyhó+15. munkanap | P1, batch retry + manuális |
| NAV NPG online pénztárgép | NAV | real-time | P0, fallback off-line bizonylat |
| SAR (gyanús ügylet) | Pénzügyi Hírszerző Egység | 5 munkanap | P0, manager review kötelező |

`scripts/regulatory/` mappa kötelezően tartalmazza: `mnb-publish.sh` (cron 14:00), `ngm-monthly-export.sh` (hó 14-én 06:00), `sar-notify.sh` (webhook AML hit-re). Sikertelen futás email/Slack alert.

### 1.6 Sztornó szabály invariáns — `feedback_reversal_rules.md`

1. **Csak ugyanazon a napon** — `transaction.createdAt::date = today()`.
2. **Csak ugyanazzal a worker-rel** — `transaction.workerId = currentWorker.id` (vagy SUPERVISOR_PIN override).
3. **Csak napzárás ELŐTT** — `dailyClosing.status != 'CLOSED'`.
4. **Bizonylat-sorszám megmarad** — audit trail integritás.
5. **Készlet visszaáll** atomikusan, `SUM(tranzakciók)` invariáns alapján.

`ReversalServiceTest`-ben mind az 5 szabályra negatív teszt. Lazítás = P0 finding.

### 1.7 Code-signing függő release mandate — `feedback_release_signing.md`

DigiCert EV CS HSM kiadásig (várható 2026-05-19/21):
1. **TILOS unsigned `Penztar-Setup-*.exe`-t** publikus GitHub Release-be feltölteni.
2. **TILOS auto-update channel-re unsigned bináris.**
3. Engedélyezett: pre-release tagben, `internal-test` mappába, kizárólag a fejlesztő gépén futtatva.
4. Az `internal-test` belső osztogatás **kollégáknak TILOS** (SmartScreen + nem-informatikus user mandate).

`windows-signed-release.yml` workflow `require-signed: true` flag v2.5.54-től aktív. Kikapcsolása P0 reject.

### 1.8 Production-first vs. TDD reconciliation — `feedback_prodfirst_vs_tdd.md`

1. **Teszt-fixture-ök NEM seed-adatok.** `@TestConfiguration`-ban definiált fixture csak a test-runner JVM-jében létezik.
2. **Reproduction-teszt psql-INSERT-tel** csak a fejlesztő lokál Postgres-én, utána ROLLBACK / DROP kötelező.
3. **Flyway migráció a séma forrása** — ha új tábla / oszlop kell, migration. Code-review P0 lehet.
4. **Lokál Postgres CSAK Hetzner-replikából feltöltve** (anonimizált dump), soha NEM kézi seed.

### 1.9 Önminősítés-ellenőrzés mandate — `feedback_self_review_audit.md`

1. Minden session ZÁRÁSAKOR `vault/sessions/YYYY-MM-DD-name.md` jegyzet:
   - **Vakfolt-checklist** (claude-code-mukodes 12. fejezet 8 pontja, `[ ]` / `[x]`).
   - **Mandate-checklist** (1.1–1.8 + minden aktív mandate, `[ ]` / `[x]`).
   - **Eltérés-jelentés** ha bármelyik `[x]` nem 100%.
2. `vault/feedback/_active_mandates.md` index fájl az AKTÍV mandate-ket sorolja fel.
3. **Heti meta-review** (vasárnap, a Drill 1 után) az aktív mandate-k betartási arányáról.

---

## 2. A 9-fázisú zárási protokoll kiegészítése

### 2.1 Új 2.5. lépés — Üzleti invariáns kapu

A 2. (lokális minőségkapuk) UTÁN, a 3. (hibajavítás) ELŐTT:

```bash
cd backend && ./mvnw -q test -Dtest='*InvariantTest,*AmlTest,*MultiTenant*,*ReversalRulesTest'
```

Piros invariáns-teszt → P0, nem lehet továbblépni.

### 2.2 Új 8.5. lépés — Szabályozási health check

A 8. (runtime ellenőrzések) UTÁN, a 9. (záró jelentés) ELŐTT:

```bash
curl https://excvaluta.com/api/v1/health/regulatory
# Várt: { mnb: { lastSubmitted: "...", status: "OK" },
#         ngm: { lastExport: "...", status: "OK" },
#         sar: { pending: 0 } }
```

Nem-OK státusz → deploy NEM kész, escalation.

### 2.3 9. lépés bővítése — invariáns-tényállítás

Záró jelentés kötelező mondata:

> "Pmt. invariáns: zöld (AmlThresholdTest + 4). Multi-tenant izoláció: zöld (CrossTenantTest). Local-first outbox: zöld (OutboxReplayTest). Sztornó szabályok: zöld (ReversalRulesTest). HUF kerekítés: zöld (RoundHufTest). Bizonylat-sorszám: zöld (ReceiptSequenceTest). Code-signing: signed/unsigned-internal-only. Szabályozási health: OK."

---

## 3. AI bot review-loop kiegészítése

### 3.1 Üzleti invariáns regex-ellenőrzés workflow (`business-invariant-guard.yml`)

Trigger: minden PR. Lépések:
1. `grep -rn 'cashCounter\|cash_counter\|inventoryCount'` → találat = P0.
2. `grep -rn 'amlThreshold = [0-9]'` → magic number ellenőrzés.
3. `grep -rn '\.skip()\|@Disabled\|@Ignore' src/test/` → találat = P0 (test-skip tilos).
4. `grep -rn 'company_id\|companyId' src/main/java/.*Repository.java` → min 1 találat per repository (multi-tenant guard).

Piros workflow → `gh pr merge` blokkolva.

### 3.2 Pmt. compliance PR-checklist

`.github/PULL_REQUEST_TEMPLATE.md` új szakasz:

```markdown
## Pmt. / AML / Compliance impact
- [ ] Ez a PR nem érinti az AML-küszöböket (100k / 300k HUF)
- [ ] Ez a PR nem érinti a sanction-list ellenőrzést
- [ ] Ez a PR nem érinti a PEP nyilatkozat flow-t
- [ ] Ez a PR nem érinti a SAR auto-flag-et
- [ ] Ez a PR nem érinti a bizonylat-sorszámozást
- [ ] Ez a PR nem érinti a HUF kerekítést
- [ ] Ez a PR nem érinti a multi-tenant izolációt
- [ ] Ez a PR nem érinti a sztornó szabályokat
```

Üres template = PR-leírás hiányos.

---

## 4. Memória-rendszer korrekció

### 4.1 `_active_mandates.md` index

Lásd `vault/feedback/_active_mandates.md` — minden aktív mandate listája.

### 4.2 Auto-memory `MEMORY.md` korrekció

Tetején:
```markdown
# CRITICAL MANDATES (read FIRST)
- vault/feedback/_active_mandates.md
- vault/feedback/claude-code-korrekcios-mandate-2026-05-17.md

# WHEN IN DOUBT: a repo-tény erősebb mint az AI emlékezet.
```

---

## 5. Kontrollkérdések (sikermérés)

A jelen mandate betöltésének sikere a következő 3 kérdés helyes válaszával ellenőrizhető:

**Q1:** Mi a Pmt. 100 000 HUF küszöb? Hol enforced? Melyik teszt fedi? Mely PR-checklist pont vonatkozik rá?

**Q2:** Mit csinálsz, ha egy PR-ben `cashCounter` mező megjelenik a `Branch` entitásban?

**Q3:** Hányadik vakfoltot szegted meg legutóbb? Hivatkozz a legutóbbi session-jegyzetre.

A válaszok a `vault/sessions/2026-05-17-business-mandate-load.md`-ben szerepelnek.

---

## 6. KPI-k (30 napos siker)

1. 0 db merge P0 invariáns-sértéssel.
2. 100% session-jegyzet vakfolt + mandate checklisttel.
3. 0 db unsigned binary publikus Release-re.
4. MNB napi 14:30 sosem csúszik.
5. Cross-tenant integration test minden új repository-hoz.
6. Heti meta-review jelentés vasárnap.

---

## 7. Forrás

A 2 korábbi dokumentum (Claude Code önleírás + valutaváltó program-spec) Perplexity Computer általi auditja, 2026-05-17. A teljes szöveg eredetileg a felhasználó chatben adta át; jelen vault-jegyzet a kanonikus verzió.
