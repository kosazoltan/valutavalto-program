# Lessons Learned — Valutavalto ERP

> **KOTELEZO ERVENYU** minden agent-nek: programozas elott olvasd el. A listahoz minden uj hiba
> hozzaadando, hogy soha tobbe ne ismetelodjon.

Lista dokumentalva: 2026-04-21 session-tol kezdve. Kategoriak szerint. Minden tetel
tartalmaz: **hiba**, **megoldas**, **gyors-check** (hogyan kerulod el legkozelebb).

---

## 1. PowerShell / Shell scripting

### 1.1 `$pid` read-only PowerShell-ben
**Hiba:** `foreach ($pid in $pids)` -> "Cannot overwrite variable PID because it is read-only or constant."
**Megoldas:** Hasznalj mas nevet: `$procId`, `$process`, `$killId`.
**Check:** PowerShell auto-variables listazva: `$$, $?, $^, $_, $args, $error, $event, $foreach, $home, $host, $input, $matches, $myinvocation, $null, $pid, $profile, $pshome, $stacktrace, $switch, $this`.

### 1.2 `sed`-alapu refactor blokk-alapu JS/TS-ben vezelyes
**Hiba:** `sed -i '/pattern/d'` brace-parity eltorhet (PR #84-ben inner `}` zarojelek elvesztek -> `node --check` fail).
**Megoldas:** Blokk-refactor-ra hasznalj **Write tool** (teljes fajl rewrite) vagy **Edit tool** (AST-aware). sed csak egysoros helyettesitesekre.
**Check:** Minden `.js` / `.ts` / `.mjs` modositas utan: `node --check FILE` kotelezo commit elott.

### 1.3 `Start-Process` long-running gyerekre nem alkalmas script-bol
**Hiba:** `powershell -File start.ps1` inditja a launcher-t, de a Start-Process-szel inditott gyerek processek terminate-oldnak, amikor a parent script kilep.
**Megoldas:** Bash-bol `command &` + `disown` hatter-indit a shell-bol. Vagy PowerShell-ben `Start-Job` vagy `Register-ScheduledTask`.
**Check:** Launcher-nek teszteljek: futtass + wait 60mp + `Get-Process` — megvannak-e a gyerekek?

### 1.4 Magyar kommentek + PowerShell heredoc-ok
**Hiba:** `$a + "magyar szoveg" + $nl + "`$markdown`"` — a `` ` `` escape es az ekezetek osszegabalyodnak, parser errort dob.
**Megoldas:** Heredoc `@' ... '@` (single-quote = no expansion) hasznalj. Tartalmazhat `$var`-t escape nelkul.
**Check:** Ha a stringben $ van -> hasznalj `@'...'@`-t. Ha interpolacio kell -> `@"..."@`.

---

## 2. Vite / Webpack / Dev servers

### 2.1 Vite default csak IPv6 `localhost`-ra bindol
**Hiba:** `npm run dev` -> Vite hallgatja `localhost:3000`-t, de IPv4 `127.0.0.1:3000` eleretetlen.
**Megoldas:** `npm run dev -- --host 0.0.0.0` — mindket family-re bindol.
**Check:** Ha az Electron / kliens `127.0.0.1:3000`-re csatlakozik, `curl http://127.0.0.1:3000/` teszt kotelezo indulas utan.

### 2.2 Electron dev renderer URL `127.0.0.1:3000`, Vite `localhost` -> EADDRUNREACH
**Hiba:** `A renderer nem tudott csatlakozni a dev szerverhez: http://127.0.0.1:3000`.
**Megoldas:** 2.1-et alkalmazd (Vite `--host 0.0.0.0`). VAGY Electron `devServerUrl` override `http://localhost:3000`.
**Check:** `grep -nE "devServerUrl|loadURL" penztar-client/electron/main.ts` — latsz-e `127.0.0.1` hardcoded?

---

## 3. GitHub Actions / CI

### 3.1 `claude-code-action@v1` OIDC token kotelezo
**Hiba:** `Could not fetch an OIDC token. Did you remember to add id-token: write to your workflow permissions?`
**Megoldas:**
```yaml
permissions:
  id-token: write
  actions: read
```
(A `anthropic_api_key` mellett is kell.)

### 3.2 `claude-code-action@v1` bot blocking default
**Hiba:** `Workflow initiated by non-human actor: sourcery-ai (type: Bot). Add bot to allowed_bots list`.
**Megoldas:**
```yaml
with:
  allowed_bots: 'sourcery-ai,chatgpt-codex-connector'
```
Szigorubb mint `'*'` (csak specifikus botok).

### 3.3 Dependabot major version bumps auto-merge veszelyes
**Hiba:** Spring Boot 3.5.13 -> 4.0.5, Tailwind 3.4 -> 4.2, Flyway 10 -> 12 — breaking changes, production regression.
**Megoldas:** Major bumps-okat CLOSE-olni, varni a project-kontextusban (pl. Spring Boot 3.5.14 LTS path).
**Check:** PR title-ben `from N -> N+1` SEMVER major ugras? -> manual review kotelezo.

---

## 4. Java / Spring / JPQL

### 4.1 Hardcoded string literal enum-ok JPQL-ben
**Hiba:** `AND t.status = 'COMPLETED'` — refactor (rename enum) eltori.
**Megoldas:** `AND t.status = hu.puzzleir.valuta.entity.TransactionStatus.COMPLETED` (FQN enum).
**Check:** Sourcery AI flag-eli P1-kent.

### 4.2 `(Long) r[0]` unsafe cast PostgreSQL aggregation-bol
**Hiba:** `COUNT(DISTINCT t.customerId)` Hibernate-tol `BigInteger`-t adhat -> ClassCastException.
**Megoldas:**
```java
Long workerId = r[0] instanceof Number n ? n.longValue() : null;
```
**Check:** Minden `Object[]` aggregation result-hoz `toLong()` / `toBigDecimal()` helper.

### 4.3 Silent `BigDecimal.ZERO` unsupported type-nal
**Hiba:** `toBigDecimal(Object o)` default return `ZERO`, elrejt adata hibakat.
**Megoldas:** Minimalisan `log.warn(...)` a fallback elott.

### 4.4 Multi-tenant query companyId hianya
**Hiba:** `findByBranchAndDate(branchId, date)` — branch implicit company-hoz tartozik, de manipulalt branchId cross-tenant leak-et okozhat.
**Megoldas:** Minden multi-tenant entity query `AND entity.company.id = :companyId` explicit szures.
**Check:** `docs/security/multi-tenant-repository-audit-*.md` riport.

### 4.5 `spring.datasource.url` nested `${...:default}` fallback ertelmezhetetlen beallitasnal
**Hiba:** `${DATABASE_URL:jdbc:postgresql://${LOCAL_DB_HOST:localhost}:${LOCAL_DB_PORT:5433}/${LOCAL_DB_NAME:valuta}}` default port **5433**, de `docker-compose.yml` 5432:5432 mapping -> fresh dev setup connection refused.
**Megoldas:** Default port a repo konvencioja szerint (itt 5432). Ha masik port kell, `.env`-ben expliciten.

### 4.6 `@PostConstruct` VAT-coverage validacio hianya
**Hiba:** `DEFAULT_VAT_RATES.getOrDefault(taxCode, BigDecimal.ZERO)` — ha uj enum value jon, silent ZERO.
**Megoldas:** `@PostConstruct validateVatRateCoverage()` — startup IllegalStateException ha coverage hianyzik.

### 4.7 OWASP XXE vedelme reszleges
**Hiba:** `factory.setFeature("disallow-doctype-decl", true)` + `external-general-entities` + `external-parameter-entities` nem eleg — `XIncludeAware` + `ExpandEntityReferences` + `FEATURE_SECURE_PROCESSING` meg hianyzik.
**Megoldas:** 6 feature teljes OWASP-compliant setup (ld. `ExchangeRatePollingService.parseMnbXml`).

---

## 5. React / TypeScript

### 5.1 `lucide-react` komponensek NEM tamogatjak a `title` prop-ot
**Hiba:** `<Shield title="info" />` -> TS2322 "Property 'title' does not exist".
**Megoldas:** Wrap `<span title="...">...</span>`-be.

### 5.2 `noUncheckedIndexedAccess` + `array[0]` reduce initial
**Hiba:** `data.rows.reduce((max, r) => ..., data.rows[0])` — `data.rows[0]` lehet `undefined`.
**Megoldas:** `const first = data.rows[0]; if (!first) return null; reduce(..., first)`.

### 5.3 `as any` / `@ts-ignore` TILOS uj kodban
**Szabaly:** 0 uj `as any`, `@ts-ignore`, `@ts-nocheck`. Regi kodnal meghagyhato, uj PR-be NE.

### 5.4 useEffect race condition async fetch-nel
**Hiba:** `useEffect(() => { api.get(...).then(setData) }, [deps])` — gyors dep valtoztatasnal regi response felulirja az ujat.
**Megoldas:** `let cancelled = false; ... if (!cancelled) setData(...)` + `return () => { cancelled = true }`.

### 5.5 React template literal + PowerShell escape
**Hiba:** `$c = $c.Replace('...\${w.id}...')` PowerShell a `${...}` interpolaciot megprobalja — template literal eltorik.
**Megoldas:** PowerShell-ben single-quote string + backtick escape.

---

## 6. Test mocking / ADMIN handling

### 6.1 `hasCanonicalRole` ADMIN bypass hianya (INKONZISZTENS)
**Hiba:** `hasRole`, `hasPermission`, `isSupervisorOrAbove` mind ADMIN-fallback, DE `hasCanonicalRole` nem — menu filter-ben ADMIN nem lat semmit.
**Megoldas:** `if (effectiveRole === 'ADMIN') return true` kezdetben. **Szabaly:** minden role-check helper KONZISZTENS admin-bypass-szal.

### 6.2 Mockito `@Mock` hianyzo field a tesztben
**Hiba:** `NullPointerException` service hivas kozben tesztben.
**Megoldas:** Uj service field bevezetese utan minden hasznalo test-et @Mock-oltnak kell lennie. `mvn test` commit elott.

### 6.3 Unittest stub `findByCompanyIdAndIsActiveTrue` helyett `findByIsActiveTrue`
**Hiba:** Service migrated company-scoped query-re, test mock meg regi.
**Megoldas:** Service change -> test mock update kotelezoen egyutt.

---

## 7. Dev environment / Local setup

### 7.1 Worktree-ben nincs `.env`, a main repo-ban van
**Hiba:** `$envFile = Join-Path $RepoRoot ".env"` worktree root -> NINCS, konfiguracio hianyzik.
**Megoldas:** `cp ../../../../.env ./.env` (a main repo gyokerebol, ha kulonalloan letezik).
**Check:** Launcher scriptben elso lepes: `if (!exists .env) copy from ../../..`.

### 7.2 Lokalis DB migration lag
**Hiba:** Security preflight: "Missing in local DB: 145, 146, ..., 154".
**Megoldas:** `mvn flyway:migrate -Dflyway.url=... -Dflyway.user=... -Dflyway.password=...`
**Check:** Backend indulas elott minden commit utan.

### 7.3 `existsSync(dangling_symlink) = false` -> broken cleanup
**Hiba:** `if (existsSync(dst)) rmSync(dst)` skip-elodik dangling symlink eseten -> `symlinkSync EEXIST`.
**Megoldas:** **Unconditional** `rmSync(dst, { force: true })`.

---

## 8. AI Code Review workflow

### 8.1 Sourcery + Codex review commenteket MINDEN PR-nel lekerni kell
**Szabaly:** CLAUDE.md "Kotelezo AI code review workflow". Amint review comment erkezik, P1 (bug_risk) priorities > P2 (suggestion) > P3 (style) sorrendben javitani, `fix(ai-review): ...` prefix-szel.

### 8.2 Self-healing demo: Claude Code Action MAGA is javit
**Tanulsag:** Ha a workflow-ban bug van, a claude-code-action@v1 a kovetkezo PR review-jabol SAJAT magat javithatja (PR #91 peldaul). Bizonytalansag eseten hagyd, hogy automatizmus beragassa a fix-et.

---

## Gyorsreferencia — ha ezt latod, figyelj!

| Tunet | Lessons 1-8 |
|---|---|
| "$pid cannot overwrite" | 1.1 |
| `node --check` parse error sed utan | 1.2 |
| "renderer nem tud csatlakozni 127.0.0.1-re" | 2.1 / 2.2 |
| "OIDC token could not fetch" | 3.1 |
| "non-human actor blocked" | 3.2 |
| "ClassCastException BigInteger -> Long" | 4.2 |
| "Property 'title' does not exist" (lucide) | 5.1 |
| menu ures ADMIN-nal | 6.1 |
| local DB migration mismatch | 7.2 |
| EEXIST dangling symlink | 7.3 |

## Szabaly: uj hiba -> uj bejegyzes
Amint egy agent egy uj hibaba fut bele:
1. **Javitsa** az alkalmazasban.
2. **Dokumentalja** itt a megfelelo szekcioban (1-8 vagy uj).
3. **Kommit** ugyanabban a PR-ben.
4. **CLAUDE.md** szabaly hivatkozik erre a fajlra -> a kovetkezo agent olvassa.

Valaha, semmilyen hiba ne tertjen vissza. Mindenki tanuljon az elozo tevedesbol.