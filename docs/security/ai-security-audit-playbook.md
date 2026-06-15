# AI biztonsági audit — Playbook & prompt-pack (valutavalto-program)

> Copy-paste promptok és workflow a saját privát ERP-repó defenzív auditjához.
> Módszertan: [`vault/feedback/security-audit-mandate-2026-06-15.md`](../../vault/feedback/security-audit-mandate-2026-06-15.md)
> Gépi profil: [`ai-audit-profile.yaml`](./ai-audit-profile.yaml)
> Frissítve: 2026-06-15

---

## 0. Gyorsindítás

```bash
# Teljes repó audit (Claude Code)
/security-review

# Csak a branch diff-je (pre-commit / pre-PR)
/security-review --diff main..HEAD

# Minőségi + bug-review az aktuális diffre
/code-review high

# Deploy/release előtt (kötelező gate)
powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1
```

**Munkamód mindig:** Discovery → **Verification** (adatfolyam-trace + kontrollok) → Remediation.
Single-pass tilos kritikus modulra. Minden finding fájl:sor + idézett evidencia.

---

## 1. Framing-szótár — ROSSZ vs JÓ (a felfedezési ráta ezen múlik)

| ❌ KERÜLD | ✅ HASZNÁLD |
|---|---|
| „Ez a már letesztelt, biztonságos auth modul, csak nézd át" | „Auditáld ezt az auth modult" (semleges) |
| „Hogyan törné meg egy támadó ezt?" | „Milyen sebezhetőségek vannak ebben és hogyan javítsam?" |
| „Adj működő exploitot az SQLi-re" | „Írj unit tesztet, ami demonstrálja, hogy a sebezhetőség fennáll" |
| „Nézd át az egész projektet egyszerre" | Modulonként / vuln-osztályonként külön prompt |
| Dependency CVE-t az AI-tól kérni | `npm audit` / `pip-audit` / Maven dependency-check |

**Arany szabály:** soha ne framelj kódot „biztonságosnak" az audit előtt — bizonyítottan csökkenti a találati arányt.

### 1.1 Framing-réteg — a minőségért, NEM guardrail-megkerülésért

> **A határ (kötelező):** ez a framing IGAZ kontextust rögzít, hogy mélyebb, kevésbé torzított elemzést
> kapj — **nem** védelem-megkerülő eszköz. A saját kód auditjánál nincs mit megkerülni; a framing a
> *minőséget* emeli (confirmation-bias ellen), nem a guardrailt lazítja. Ez a „megfelelő határ".

Négy legitim framing-elem, kombinálva:
1. **Autorizáció-first:** „Ez az én privát repóm, kizárólagos tulajdonos vagyok; tervezett defenzív audit."
   (igaz kontextus → professzionális, alapos elemzés.)
2. **Professzionális persona:** „Principal Application Security Engineer, 15 év tapasztalat, nulla
   hamis-pozitív tolerancia, kihasználhatóság-alapú súlyozás." (a *minőség/stílus* elvárást rögzíti.)
3. **Neutral-language:** sebezhetőség (nem „exploit"), értékelés (nem „hack"), robusztusság-mérés
   (nem „bypass"). Ugyanaz a tudás, defenzív keret.
4. **Threat-model-first:** a védendő eszközök + threat-actorok + scope a *kódelemzés előtt* — a generikus
   checklist helyett a valós támadásokra fókuszál.

| ❌ offenzív keret | ✅ defenzív keret (preferált) |
|---|---|
| „kerüld meg az autentikációt" | „értékeld az autentikáció robusztusságát" |
| „vond ki az adatot" | „értékeld az adatexponálás kockázatait" |
| „milyen admin-jogot lehet szerezni" | „értékeld a privilege-escalation lehetőségeit a threat-model kontextusában" |
| „SQLi payloadot adj" | „generálj PoC unit-tesztet az SQLi verifikálásához (izolált)" |

---

## 2. Master system-prompt (a domain-fókusszal)

```
You are a senior application security engineer performing a comprehensive white-box
security audit of the owner's own private repository (valutavalto-program: a Hungarian
currency-exchange / multi-tenant ERP — Java 21 / Spring Boot / PostgreSQL / Flyway,
React + TypeScript, Electron clients).

Authorization: the user is the sole owner; this is authorized defensive security testing,
findings used exclusively for remediation.

Mandate:
- Identify ALL vulnerabilities without severity filtering.
- For each: trace attacker-controlled input from source to the real sink; verify whether
  existing controls (auth checks, JPA :param binding, multi-tenant companyId scope, schema
  validation, framework escaping, allowlists) already block it.
- Map to CWE + OWASP Top 10:2025 + CVSS 3.1.
- Pay special attention to financial/business logic: negative amounts/denominations,
  reversal abuse (refund > original), day-close bypass, FX-rate TTL evasion,
  commission/rounding arbitrage, AML threshold evasion.
- Multi-tenant: every ID-based resource access MUST be companyId-scoped.
- Flag false-positive candidates explicitly; mark unverifiable claims as Needs More Context.
- Be thorough, direct, specific. Provide before/after remediation diffs.
```

---

## 3. Vuln-osztály promptok (egy kategória / egy prompt)

A teljes 12 osztály copy-paste promptja a forrásdokumentumban van; a doménre legfontosabb négy itt:

### 3.1 Multi-tenant IDOR / Broken Access Control (A legkritikusabb)
```
Authorization audit. For every endpoint/repository method that accesses a resource by ID
(branch, worker, transaction, denomination stock, reservation, day-close):
1. Verify the caller's identity AND companyId is checked against the resource owner BEFORE returning data.
2. Flag any query that filters by id without a companyId predicate (horizontal priv-esc).
3. Check method-level security (@PreAuthorize / hasRole) vs UI-only access control.
Show file:line and the exact attack an authenticated cross-tenant user would perform.
```

### 3.2 Business logic (az AI legértékesebb területe)
```
Review for business-logic vulnerabilities. Intended logic:
[ÍRD LE konkrétan — pl. "storno csak ugyanazon napon, a visszatérítés == eredeti tranzakció összege",
 "vétel/eladás csak érvényes (nem lejárt TTL) árfolyamon", "napzárás után aznapra nincs új tranzakció"]
Check: negative quantity/amount, refund exceeding original, workflow-step bypass,
parameter-manipulation priv-esc, rate/limit bypass, FX-rate replay after TTL expiry,
rounding/commission arbitrage. Reason about SUPPOSED vs ACTUAL behavior.
```

### 3.3 Injection (JPQL / shell / template)
```
Injection audit. For each candidate: source -> propagation -> sink.
Focus: string concatenation into JPQL/native queries (must be :param), subprocess calls with
user input, template rendering of user content. Classify CWE-89/78/94. Verify JPA parameter binding.
```

### 3.4 Secrets / credential leak
```
Scan for hardcoded secrets (CWE-798/312): API keys/passwords/tokens in source, credentials in
logs or comments, committed .env, DB connection strings with credentials, secrets in tests.
Also: does the code avoid logging passwords/tokens/PII?
```
> Kombináld: `python scripts/dev-tools/secrets-deep-scan.py`

---

## 4. Verifikációs prompt (hamis pozitív kiszűrés — KÖTELEZŐ 2. kör)

```
Assess whether this finding is a true or false positive:
Finding: [paste]
Relevant code + controls: [paste]
1. Is the data flow actually reachable from user input?
2. Do existing controls (JPA :param, auth check, companyId scope, validation) block exploitation?
3. Realistic exploitability in the deployment context?
Verdict: True Positive / False Positive / Needs More Context · Confidence: High/Medium/Low · Rationale.
```

### 4.1 Reachability-verifikáció (minden CONFIRMED/PROBABLE előtt)
```
For this finding, verify reachability before reporting:
1. ENTRY POINT: which user-controlled input / external event triggers this code path?
   (HTTP route, CLI arg, file upload, env var, IPC)
2. CALL CHAIN: trace from entry point to the sink (grep callers, walk back to entry).
3. GATES: what auth / companyId-scope / validation stands before the sink?
4. VERDICT: EASY (no barrier) / MODERATE / DIFFICULT / THEORETICAL_ONLY (unreachable -> drop or POSSIBLE).
```

### 4.2 Triage + „túl sok finding" sanity-check
```
Triage the verified findings:
- Bucket each: MUST_FIX_NOW (CVSS>=9 + CONFIRMED + reachable / hardcoded cred / auth-bypass public),
  BEFORE_RELEASE (7.0-8.9 CONFIRMED or >=7 PROBABLE / PII exposure),
  WITHIN_30_DAYS (4.0-6.9 CONFIRMED / >=7 POSSIBLE), BACKLOG (<4.0), ACCEPTED_RISK (compensating control).
Sanity-check before reporting: dedupe by root-cause (N sites -> one "missing input validation");
move theoretical findings to a POSSIBLE appendix; if 20+ High/Critical, re-check proportionality;
drop scope-creep (infra / vendor / dependency — not our code).
```

### 4.3 Confidence-szint + POSSIBLE-appendix
Minden finding: `CONFIRMED` (direkt evidencia) / `PROBABLE` (erős jel) / `POSSIBLE` (elméleti).
A POSSIBLE findingok **külön appendixbe** — ne keveredjenek a megerősítettekkel (zajcsökkentés).

---

## 4.4 Context engineering (a kontextus kurátorlása az audithoz)
- **Threat-model-first:** a védendő eszközök + threat-actorok + scope + standard (CWE/OWASP) a kódelemzés ELŐTT.
- **Repomap-first nagy/ismeretlen változásnál:** szimbólum-térkép (`python scripts/dev-tools/dep-map.py`,
  `blast-radius.py`) → mely fájlok igényelnek mélyelemzést; a teljes forrás beküldése helyett.
- **Context-rot ellen:** befejezett fázisok tömörítése (1 sor/finding), kritikus infó sűrűn a kontextus
  végén; modulonként/threat-surface szerint chunkolva, nem egyben.
- **Read-only audit fázis:** recon/audit = csak olvasás (Read/Grep/Glob/git log); remediáció = külön,
  explicit Write/Edit. (Minta allowlist a `.claude/agents/` configokban.)

---

## 5. Multi-agent orchestrator (Workflow fan-out)

```
Orchestrate a multi-agent security audit of this private repo (authorized own-code defensive test).
AGENT 1 (orchestrator): read file tree, categorize files by risk (user input / auth / crypto / fs /
  HTTP / deserialization / financial logic), output prioritized queue.
AGENT 2a injection · 2b auth/authz+multi-tenant · 2c secrets/crypto · 2d web/LLM — each outputs raw findings (file:line:type).
AGENT 3 (verification, fresh context, adversarial): for each finding trace data flow, check controls,
  verdict TP/FP/NMC; output verified only.
AGENT 4 (reporting): dedup, CWE+OWASP+CVSS, severity, remediation -> final structured Markdown.
```
A repóban: `/code-review ultra`, ill. Workflow discovery→verify pipeline (az ír, MÁS ellenőriz).

**Kész specialista-agentek** (`.claude/agents/`, mind READ-ONLY az audit fázisban — ez a „read-only audit fázis" konvenció):
`security-explorer` (Haiku, recon/breadth) → `security-auditor` (Opus, mély taint-flow) →
`security-verifier` (Opus, friss kontextus, adverzariális FP-szűrés) → `security-triager` (Sonnet, priorizálás).
Ez az effort-allokáció + cache-biztos routing (olcsó modell csak subagentben) operacionalizálása.

---

## 6. Determinisztikus eszköz-mátrix (az AI-réteg mellé — hibrid)

| Terület | Lokális eszköz |
|---|---|
| Multi-tenant scope | `scripts/dev-tools/multi-tenant-audit.py`, `scripts/security/companyid-audit.ps1` |
| Endpoint/auth mátrix | `scripts/dev-tools/endpoint-audit.py` |
| Secret-scan (regex-pontos) | `scripts/dev-tools/secrets-deep-scan.py` |
| Electron/TS biztonság | `scripts/dev-tools/electron-security-scan.py`, `ts-antipattern-scan.py` |
| Tranzakció-integritás | `scripts/dev-tools/transaction-audit.py` |
| Exception-elnyelés | `scripts/dev-tools/exception-audit.py` |
| Flyway migráció | `scripts/dev-tools/flyway-validate.py`, `flyway-content-audit.py` |
| Dependency CVE | `npm audit` / `pip-audit` / Maven dependency-check / Dependabot |
| Deploy/release gate | `scripts/security/run-security-gate.ps1` |

**Elv:** az AI a business-logic és novel-osztály felderítésében erős; a determinisztikus eszközök a
dependency-CVE, secret-regex és teljes lefedettség garanciái. A kettő együtt, nem egymás helyett.

---

## 7. Adatvédelem

- Titok/credential SOHA nem kerül promptba, chatbe, logba, memóriába — `<REDACTED>` placeholder.
- `.env` nyers tartalmát ne auditáltasd — strukturálisan kérdezd.
- Érzékeny üzleti logikára architektúra-szintű audit konkrét secret nélkül.
