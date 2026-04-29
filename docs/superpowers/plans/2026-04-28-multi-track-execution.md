# Multi-track execution plan: A + B + C 2026-04-28

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Maradék 2026-04-27 defer Dependabot MAJOR PR-ek lezárása + Spring Boot 4 önálló sprint, miután a CLAUDE.md TODO listájában szereplő feladatok nagy része 04-23 / 04-24 / 04-27 ciklusban már mergelve.

**Architecture:** Három független subsystem, sorrendben: **C2 (eslint 10) → C3 (react 19) → A (SB4)**. Mind külön feature branch + külön PR + külön merge + külön Hetzner deploy. A SB4 magas kockázatú (2026-04-27-én production outage volt Jackson 3 namespace bind miatt) → önálló sprint, friss session-be is átvihető.

**Tech Stack:** ESLint 10 (frontend + penztar), React 19 + react-dom 19 (frontend + penztar), Spring Boot 4.0.6 + Jackson 3 (backend), springdoc 3 (csak SB4 után).

**Hatály:** Minden lépésnél `AI_CONSTITUTION.md` 10 szabálya érvényes (TDD, külső verifikáció, fail loud). Minden PR merge után **kötelező** `scripts/post-merge-signal-check.ps1 <PR>` (15-perces iteratív polling, AI_CONSTITUTION.md L150 szerint).

---

## Előfeltétel: gh CLI auth

A user **manuálisan** futtassa:

```powershell
gh auth login
# 1. GitHub.com
# 2. HTTPS
# 3. Yes (git auth)
# 4. Login with a web browser
# (browser-ben confirm 8-jegyű OTP)
```

**Verifikáció:**

```bash
gh auth status                                            # logged in to github.com as kosazoltan
gh repo set-default kosazoltan/valutavalto-program        # default repo
gh pr list --state open --limit 20 --json number,title    # 4 PR várt: #205, #196, #213, #201
```

Minden további lépés feltételezi, hogy a `gh` autentikálva van.

---

## Track 1: CLAUDE.md TODO cleanup (already done)

**Branch:** `docs/cleanup-todo-list-2026-04-28`

**Files modified:** `CLAUDE.md` (361-410. sorok átírva)

A CLAUDE.md "Aktuális release-állapot" szekciója 2026-04-28 állapotra frissítve. Lezárt feladatok jelölve, valódi maradék kifejtve.

- [ ] **Step 1: Verify final CLAUDE.md state**

Run: `head -1 D:/repo/valutavalto-program/CLAUDE.md && tail -20 D:/repo/valutavalto-program/CLAUDE.md`
Expected: első sor `# Valutaváltó ERP — Claude Code kontextus`, utolsó sor a `LEZÁRVA (történelmi):` blokk.

- [ ] **Step 2: Commit + push**

```bash
cd D:/repo/valutavalto-program/.claude/worktrees/determined-liskov-08a877
git add CLAUDE.md docs/superpowers/plans/2026-04-28-multi-track-execution.md
git commit -m "$(cat <<'EOF'
docs(claude-md): 2026-04-28 cleanup - elavult TODO-k lezárva, valódi maradék tisztázva

- Verzió v2.3.2 → v2.3.6 (PR #251 audit-iter5 + #252 release + #253 V165 guard)
- Main HEAD 1b92eccc → 0949a656
- 04-27 marathon (15 PR + 2 hotfix) és 04-28 release dokumentálva
- LEZÁRVA jelöles: CB-016 (V143 mergelve), Production URL SSOT (PR #173+#174 mergelve), Cognee MCP (vault aktiv)
- Maradék 4 defer Dependabot MAJOR konkretizálva: #205, #196, #213, #201
- Master execution plan: docs/superpowers/plans/2026-04-28-multi-track-execution.md

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
git push -u origin docs/cleanup-todo-list-2026-04-28
```

- [ ] **Step 3: Open PR + merge (gh required)**

```bash
gh pr create --title "docs(claude-md): 2026-04-28 cleanup - 04-27/04-28 munka dokumentálva" --body "$(cat <<'EOF'
## Summary
- CLAUDE.md `Aktuális release-állapot` szekció 04-28 állapotra frissítve
- Lezárt P2 feladatok jelölve: CB-016, Production URL SSOT, Cognee MCP, Obsidian vault sync
- Valódi maradék Dependabot defer: #205 (SB4), #196 (springdoc 3), #213 (eslint 10), #201 (react 19)
- Master execution plan a maradékhoz: docs/superpowers/plans/2026-04-28-multi-track-execution.md

## Test plan
- [x] CLAUDE.md tartalmilag friss (head + tail check)
- [x] No code change — docs-only PR

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"

gh pr merge --squash --auto --delete-branch
```

---

## Track 2: C2 — ESLint 9 → 10 upgrade (PR #213 alternatív)

**Goal:** ESLint 10 + flat config v3 (ha szükséges) frontend-react és penztar-client-en. A meglévő `eslint-plugin-react-hooks 7.x` és `typescript-eslint 8.59` kompatibilis ESLint 10-zel.

**Branch:** `chore/eslint-10-upgrade`

**Risk:** Közepes — flat config breaking changes (ha a `eslint.config.mjs` a régi formátumot használja). Plugin-kompatibilitás `eslint-plugin-react-refresh 0.5.x`-szel ellenőrizendő.

**Files:**
- Modify: `frontend-react/package.json` (`eslint ^9.39.1` → `^10.0.0` vagy `^10.x` aktuális)
- Modify: `frontend-react/eslint.config.mjs` (ha a flat config v3 syntax-ot követeli)
- Modify: `penztar-client/package.json` (ugyanígy)
- Modify: `penztar-client/eslint.config.mjs` (ha van)

### Subtask 2.1: Verifikáció (open PR vagy nem)

- [ ] **Step 1: Check #213 state**

Run: `gh pr view 213 --json state,mergeable,headRefName,headRefOid`
Expected: `state: OPEN`. Ha CLOSED — preempt local branch.

- [ ] **Step 2: Read frontend-react/eslint.config**

Run: `ls frontend-react/eslint.config*`
Expected: `eslint.config.mjs` (flat config). Ha `.eslintrc.cjs` (legacy) — flat config conversion is also part of this task.

### Subtask 2.2: Frontend-react bump

- [ ] **Step 3: Bump eslint version**

Edit `frontend-react/package.json` devDependencies:
```diff
-    "eslint": "^9.39.1",
+    "eslint": "^10.0.0",
```

(Aktuális 10.x version: `npm view eslint version` futtatandó az aktuális verzió ellenőrzésére.)

- [ ] **Step 4: npm install**

Run: `cd frontend-react && npm install eslint@^10`
Expected: lockfile updated, no peer dep conflicts. Ha lucide-react / @typescript-eslint peer issue — chase upstream issue.

- [ ] **Step 5: Run lint**

Run: `cd frontend-react && npm run lint`
Expected: 0 error vagy a meglévő baseline szám (a flat config v3 új rule defaultok-at is hozhat). Ha új error: kategorizálni (P0/P1/P2/style).

- [ ] **Step 6: Run typecheck + tests**

Run: `cd frontend-react && npm run type-check && npm test`
Expected: typecheck 0 error, tests 505/505 zöld.

### Subtask 2.3: Penztar-client bump (azonos lépések)

- [ ] **Step 7-12: Ugyanaz a folyamat penztar-client-re**

A `penztar-client/package.json`-ben ugyanígy bumpolni, lint+test futtatás.

### Subtask 2.4: Build + commit + PR

- [ ] **Step 13: Build mindkét csomag**

Run: `cd frontend-react && npm run build && cd ../penztar-client && npm run build:electron`
Expected: dist + dist-electron létrejön, 0 error.

- [ ] **Step 14: Pre-push gate**

Run: `powershell -ExecutionPolicy Bypass -File scripts/pre-push-quality-gate.ps1`
Expected: exit=0.

- [ ] **Step 15: Commit + push + PR + merge**

```bash
git add frontend-react/package.json frontend-react/package-lock.json frontend-react/eslint.config.mjs   penztar-client/package.json penztar-client/package-lock.json penztar-client/eslint.config.mjs
git commit -m "chore(deps-dev): eslint 9 → 10 upgrade (frontend-react + penztar-client)"
git push -u origin chore/eslint-10-upgrade
gh pr create --title "chore(deps-dev): eslint 9 → 10 upgrade" --body "..."
gh pr merge --squash --auto --delete-branch
```

- [ ] **Step 16: Close defer #213**

Run: `gh pr close 213 -c "Replaced by chore/eslint-10-upgrade — co-bumpolt frontend-react + penztar-client + lint config v3 audit"`

- [ ] **Step 17: Post-merge signal check**

Run: `powershell -File scripts/post-merge-signal-check.ps1 -PR <new-PR-num>`
Expected: 0 P1 finding.

---

## Track 3: C3 — React 18 → 19 migration (PR #201 alternatív)

**Goal:** React 19 + react-dom 19 + @types/react 19 + @types/react-dom 19, frontend-react és penztar-client renderer.

**Branch:** `feat/react-19-migration`

**Risk:** Közepes-magas. **React 19 breaking changes:**
- `useFormState` → `useActionState` rename
- `forwardRef` → ref-as-prop (deprecated, de még működik)
- `defaultProps` removed function components
- Strict mode dupla render mock-ok kezelése
- `react-dom/test-utils` → `react-dom/client` (vitest setup)
- `<Provider>` legacy context API removed (csak ha még valahol használjuk)

**Pre-migration audit (kötelező):**

```bash
# forwardRef usage:
grep -rn "forwardRef" frontend-react/src penztar-client/src
# defaultProps usage:
grep -rn "defaultProps" frontend-react/src penztar-client/src
# react-dom/test-utils usage:
grep -rn "react-dom/test-utils" frontend-react/src penztar-client/src
# useFormState usage:
grep -rn "useFormState" frontend-react/src penztar-client/src
```

**Files (várhatóan):**
- Modify: `frontend-react/package.json`, `frontend-react/package-lock.json`
- Modify: `penztar-client/package.json`, `penztar-client/package-lock.json`
- Modify: `frontend-react/src/test-setup.ts` (vagy hasonló)
- Modify: meghatározhatatlanul sok `*.tsx` fájl (ha forwardRef / defaultProps audit eredmény)

### Subtask 3.1: Pre-migration audit

- [ ] **Step 1: Run grep audit**

(parancsok fent)

Output dokumentálása az PR description-ben.

- [ ] **Step 2: Check #201 state**

Run: `gh pr view 201 --json state,mergeable,body`
Expected: OPEN, body release notes review szükséges.

### Subtask 3.2: Frontend-react bump

- [ ] **Step 3: Bump react+react-dom+types**

Edit `frontend-react/package.json`:
```diff
     "react": "^18.2.0",
     "react-dom": "^18.2.0",
     ...
     "@types/react": "^18.2.56",
     "@types/react-dom": "^18.2.19",
+    "react": "^19.0.0",
+    "react-dom": "^19.0.0",
+    "@types/react": "^19.0.0",
+    "@types/react-dom": "^19.0.0",
```

- [ ] **Step 4: npm install**

Run: `cd frontend-react && npm install react@^19 react-dom@^19 @types/react@^19 @types/react-dom@^19`
Expected: lockfile updated.

- [ ] **Step 5: Run typecheck**

Run: `cd frontend-react && npm run type-check`
Expected: ha forwardRef / defaultProps issue → fix per audit.

- [ ] **Step 6: Run tests**

Run: `cd frontend-react && npm test`
Expected: 505/505 zöld. Ha test util breaking → fix `test-setup.ts`.

- [ ] **Step 7: Run dev server + manual smoke test**

Run: `cd frontend-react && npm run dev`
Expected: dev server fut, login page elérhető, console zöld.

### Subtask 3.3: Penztar-client bump (azonos lépések)

- [ ] **Step 8-13: Ugyanaz a folyamat penztar-client renderer-re**

Megjegyzés: a penztar-client renderer a frontend-react-et symlink-eli (lásd `penztar-client/package.json` `dev:renderer`). Tehát a react-19 a frontend-react-en keresztül látszik.

### Subtask 3.4: Build + commit + PR

- [ ] **Step 14: Pre-push gate**

Run: `powershell -ExecutionPolicy Bypass -File scripts/pre-push-quality-gate.ps1`

- [ ] **Step 15: Commit + push + PR + merge**

```bash
git checkout -b feat/react-19-migration
git add frontend-react/package*.json penztar-client/package*.json
git commit -m "feat(deps): react 18 → 19 migration (frontend-react + penztar-client)"
git push -u origin feat/react-19-migration
gh pr create --title "feat(deps): react 18 → 19 migration"
gh pr merge --squash --auto --delete-branch
```

- [ ] **Step 16: Close defer #201**

Run: `gh pr close 201 -c "Replaced by feat/react-19-migration"`

- [ ] **Step 17: Post-merge signal check**

Run: `powershell -File scripts/post-merge-signal-check.ps1 -PR <new-PR-num>`

- [ ] **Step 18: Hetzner deploy verify**

```bash
sleep 600  # 10 min auto-deploy
curl -s -o /dev/null -w "%{http_code}\n" https://excvaluta.com/api/v1/auth/bootstrap-status   # 200
```

Smoke test login + dashboard a böngészőben (https://excvaluta.com).

---

## Track 4: A — Spring Boot 4 sprint (PR #205 alternatív)

**Goal:** Spring Boot 3.5.13 → 4.0.6, Jackson 2 → Jackson 3, springdoc 2 → 3 (csak utána). **Ez egy önálló 1-2 napos sprint, magas kockázat. 2026-04-27 production outage Jackson 3 namespace bind FAIL miatt — KRITIKUS, hogy minden lépés alaposan tesztelt legyen LOKÁLISAN ÉS production-szerű környezetben mielőtt mergelni.**

**Branch:** `feat/spring-boot-4-sprint`

**Risk:** **Magas.** A 04-27 PR #205 azért bukott meg, mert a Spring Boot test runner Jackson 2 ObjectMapper-rel ment, de production a default Jackson 3 binding-gal indult, és a `spring.jackson.*` enum string-binding nem konvertálható Jackson 3 enum-okra. **Lokális mvn test ≠ production.** Ezért ennél a sprint-nél kötelező:
1. **Staging environment** (külön Hetzner VPS staging.excvaluta.com? vagy localhost-on `mvn package` + `java -jar` futás production profile-lal)
2. **End-to-end smoke test** mielőtt main-re mergelnénk
3. **Rollback plan** elkészítve (revert commit ready)

### Subtask 4.1: Pre-migration audit

- [ ] **Step 1: Jackson import-audit**

```bash
grep -rn "com.fasterxml.jackson" backend/src --include="*.java" | wc -l
# Várt: ~39 fájl
grep -l "com.fasterxml.jackson" backend/src --include="*.java" -r
```

- [ ] **Step 2: spring.jackson.* property audit**

```bash
grep -n "spring.jackson" backend/src/main/resources/application*.properties
# Várt:
# application.properties:49: spring.jackson.serialization.write-dates-as-timestamps=false
# application.properties:50: spring.jackson.time-zone=UTC
# application.properties:51: spring.jackson.default-property-inclusion=non_null
```

- [ ] **Step 3: ObjectMapper API audit**

```bash
grep -rn "writeValueAsString\|readTree\|ObjectMapper" backend/src --include="*.java"
```

- [ ] **Step 4: Check #205 state**

Run: `gh pr view 205 --json state,body`
Expected: OPEN. A wip(spring-boot-4) commit-ok történelmi reference-ek (cherry-pick lehetséges).

### Subtask 4.2: pom.xml + property migration

- [ ] **Step 5: Bump Spring Boot version**

Edit `backend/pom.xml`:
```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>4.0.6</version>  <!-- volt 3.5.13 -->
</parent>
```

- [ ] **Step 6: Add spring-boot-jackson2 stop-gap (deprecated, de szükséges átmenetnek)**

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-jackson2</artifactId>
</dependency>
```

VAGY: tényleges Jackson 3 migráció (ajánlott — long-term).

- [ ] **Step 7: Bump flyway-database-postgresql to 12.x (re-attempt #239)**

```xml
<dependency>
    <groupId>org.flywaydb</groupId>
    <artifactId>flyway-database-postgresql</artifactId>
    <version>12.4.0</version>  <!-- volt 10.10.0 -->
</dependency>
```

(Spring Boot 4 hozza a flyway-core 12.x-et, ami kompatibilis a flyway-database-postgresql 12.4-gyel.)

- [ ] **Step 8: Migrate spring.jackson.* property namespace**

Edit `backend/src/main/resources/application.properties`:
```diff
-spring.jackson.serialization.write-dates-as-timestamps=false
-spring.jackson.time-zone=UTC
-spring.jackson.default-property-inclusion=non_null
+spring.jackson2.serialization.write-dates-as-timestamps=false
+spring.jackson2.time-zone=UTC
+spring.jackson2.default-property-inclusion=non_null
```

VAGY: Jackson 3 enum-okra port (preferált, de minden enum value-t check-elni kell — `WRITE_DATES_AS_TIMESTAMPS` még létezik?).

### Subtask 4.3: Java import migration (OpenRewrite recipe)

- [ ] **Step 9: Run OpenRewrite Spring Boot 4 migration recipe**

```bash
cd backend
./mvnw -U org.openrewrite.maven:rewrite-maven-plugin:run   -Drewrite.activeRecipes=org.openrewrite.java.spring.boot4.UpgradeSpringBoot_4_0
```

(Ha nincs ilyen recipe még közzétéve, a recipe `org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_5` mintájára vannak community recipe-k. Ha végül NINCS recipe, a 39 fájlt manualis Edit-tel migráljuk.)

- [ ] **Step 10: Verify import migration**

```bash
grep -rn "com.fasterxml.jackson" backend/src --include="*.java" | wc -l
# Várt: 0 (vagy minimal, csak ha valamelyik komponens Jackson 2 stop-gap-ot használ)
```

### Subtask 4.4: Spring Messaging convertAndSend cast (PR #205 wip-ben volt)

- [ ] **Step 11: Cherry-pick a #205 wip commits**

```bash
git fetch origin pull/205/head:pr-205-history
git log --oneline pr-205-history | head -10
git cherry-pick <commit-sha>  # for each: pom.xml, properties, EntityScan/Flyway package, Messaging cast, SyncInbound payload, flyway-starter
```

(Vagy: rederive lokalitásból a leírt 6 lépés alapján.)

### Subtask 4.5: Local verify

- [ ] **Step 12: mvn clean install**

```bash
cd backend && ./mvnw clean install
```
Expected: BUILD SUCCESS, 978/978 test PASS.

- [ ] **Step 13: Production-profile smoke test**

```bash
# AI review fix (Codex P1 #254): -D... a -jar ELŐTT kell, JVM options csak ott parsing-olódnak.
java -Dspring.profiles.active=production -jar target/valuta-backend-*.jar
# Külön terminálban:
curl http://localhost:8080/api/v1/auth/bootstrap-status   # 200
curl http://localhost:8080/api/v1/public/branches?companyCode=EBC   # non-empty array
```

(Ha a local DB-n a production profile dolgozik, a `JWT_SECRET` env-et beállítani.)

- [ ] **Step 14: Jackson serialization smoke test**

```bash
# AI review fix (Sourcery P2 #254): valós endpoint, ami LocalDateTime-ot serializál.
# /auth/bootstrap-status válasza tartalmaz `serverTime: LocalDateTime` field-et,
# ami a Jackson 3 enum bindingot teszteli. Ha 5xx vagy NULL serverTime → bind FAIL.
curl -s http://localhost:8080/api/v1/auth/bootstrap-status | jq -r '.serverTime // "FAIL"'
# Várt: ISO-8601 timestamp (pl. "2026-04-29T10:00:00.123"). FAIL → Jackson bind error.
```

### Subtask 4.6: Push + staging deploy + production merge

- [ ] **Step 15: Push to feature branch**

```bash
git push -u origin feat/spring-boot-4-sprint
```

- [ ] **Step 16: Wait for CI green**

```bash
gh pr checks <PR-num> --watch
```

- [ ] **Step 17: Open PR + EXPLICITLY do NOT auto-merge**

```bash
gh pr create --title "feat(backend): Spring Boot 3.5.13 → 4.0.6 sprint" --body "..."
# NE legyen --auto, mert ennél a PR-nél manuális mergelés kell
```

A PR description-ben dokumentálni a #205 04-27 outage tanulságát + a végrehajtott migráció lépéseit + a smoke test eredményeket.

- [ ] **Step 18: Post-CI manual merge (után minden review jóváhagyva)**

```bash
gh pr merge <PR-num> --squash --delete-branch
```

- [ ] **Step 19: Hetzner deploy monitoring**

```bash
# 5-10 perc auto-deploy
for i in {1..10}; do
  curl -s -o /dev/null -w "%{http_code}\n" https://excvaluta.com/api/v1/auth/bootstrap-status
  sleep 60
done
```

**Ha 502 vagy 5xx → AZONNAL revert:**
```bash
git revert <merge-commit-sha>
git push origin main
# Hetzner ismét deploy-olja a Spring Boot 3.5.13-at
```

- [ ] **Step 20: Close #205**

Run: `gh pr close 205 -c "Replaced by feat/spring-boot-4-sprint"`

### Subtask 4.7: A2 — springdoc 2 → 3 (csak SB4 mergelve után)

- [ ] **Step 21: Bump springdoc**

```xml
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
    <version>3.0.3</version>  <!-- volt 2.8.17 -->
</dependency>
```

- [ ] **Step 22: Verify Swagger UI**

```bash
./mvnw spring-boot:run
# Külön terminálban:
curl http://localhost:8080/api-docs   # OpenAPI 3.0 JSON
curl http://localhost:8080/swagger-ui.html   # 200
```

- [ ] **Step 23: PR + merge + close #196**

Standard flow.

---

## Self-Review

Coverage check:
- [x] CLAUDE.md cleanup — Track 1 covers
- [x] eslint 10 — Track 2 covers (close #213)
- [x] react 19 — Track 3 covers (close #201)
- [x] Spring Boot 4 — Track 4 covers (close #205)
- [x] springdoc 3 — Subtask 4.7 covers (close #196)

Placeholder check:
- Track 4 Step 9 OpenRewrite recipe TBD (community recipe függ) — fallback: manuális 39 fájl Edit
- Track 4 Step 14: a smoke test endpoint **konkretizálva** (`/auth/bootstrap-status` `.serverTime` LocalDateTime field) — AI review fix Codex P1 (Step 13 `-D... -jar` order) + Sourcery P2 (Step 14 valós endpoint).

Type consistency:
- Branch nevek konzisztensek (`chore/eslint-10-upgrade`, `feat/react-19-migration`, `feat/spring-boot-4-sprint`).
- PR titles imperative form-ban.

---

## Execution Handoff

Plan saved to `docs/superpowers/plans/2026-04-28-multi-track-execution.md`.

**Választás:**
1. **Inline execution** (executing-plans skill) — én magam haladok lépésenként, minden track végén checkpoint-ot kérek a usertől.
2. **Subagent-driven** (subagent-driven-development skill) — fresh subagent-et dispatch-elek minden track-hez, két-stage review.

**Mindkettő feltételezi a `gh auth login`-t a user-től.** Amíg az nincs, csak a Track 1 (CLAUDE.md cleanup commit + push) és a Track 2/3/4 lokális kód-munkák mehetnek (a `gh pr create + merge` később).

**Ajánlás:** Inline execution Track 2 + 3-hoz (közepes scope), subagent Track 4-hez (nagy scope, friss kontextus segít a Jackson 3 enum-bind szubtilitásokon).
