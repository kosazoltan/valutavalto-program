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
