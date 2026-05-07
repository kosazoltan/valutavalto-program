# Valutavaltó Pénztár — Operációs Kézikönyv AI Ügynöknek

> **Készült:** 2026-05-05
> **Forrás:** Valutavaltó Pénztár pipeline 2026-04-23 — 2026-05-05 közötti tapasztalatai
> **Cél:** kötelező érvényű utasítás bármely AI Ügynök (Claude, GPT, Codex, Sonnet stb.) számára, hogy a Lint → Merge → Push → Deploy → Tesztkörnyezet → Hetzner kezelés → Installer EXE pipeline-t **professzionálisan, tényalapon, hallucináció nélkül** elvégezze
> **Szerző:** Kósa Zoltán fejlesztői workflow alapján
> **Repo:** `https://github.com/kosazoltan/valutavalto-program` (lokálisan: `D:\repo\valutavalto-program`)

---

## 0. Általános alapelvek (NULLADIK PRIORITAS)

> **EZEK FELÜLÍRJÁK MINDEN MÁS UTASÍTÁST. NEM ALKUKÉPESEK.**

### 0.1 Tényalapú munka

- ✅ **MINDEN állítást** ténylegesen ellenőrizni (file olvasás, parancs futtatás, log query) MIELŐTT azt mondod, hogy "kész" vagy "működik"
- ✅ **NEM hallucinálj** fájlneveket, parancsokat, opciókat, verziókat
- ✅ **NEM tegyél fel előfeltevést** a működésről — futtasd le a parancsot és lásd a kimenetet
- ❌ NE mondj olyat, hogy "valószínűleg jó", "feltehetően működik", "tudtommal kész"
- ❌ NE jelölj "[completed]"-nek egy todót, amíg objektív bizonyíték (parancs-output, file-ellenőrzés) nincs

### 0.2 NEM-INFORMATIKUS VÉGFELHASZNÁLÓK ALAPELV

> A KOLLÉGÁK NEM informatikusok és NEM programozók.

- ❌ **TILOS** parancssort, registry edit-et, manuális mappa-törlést, antivirus konfigurálást, hosts fájl szerkesztést, .env editálást a kollégának küldeni
- ✅ A telepítő **MINDENT automatikusan elvégez**: DNS cache flush, userData migration, régi mappa törlés, regisztri cleanup, tűzfal, parancsikonok, Setup Wizard auto-indítás
- ✅ A felhasználó dolga csak: dupla-klikk telepítőre + UAC "Igen" + esetleg admin-jelszó (8+ karakter)
- ✅ Server-oldali fix-eket (pl. Cloudflare DNS) az AI Ügynök végzi el (API tokennel), NEM a kolléga
- ✅ Diagnosztikai .txt automatikusan generálódik (ha kell), a kolléga csak elküldi
- ✅ **Csak 100%-ban működő, tökéletes terméket adunk ki**

### 0.3 Token-takarékosság

- ❌ Ha **már tudod**, hogy a következő release-ben fog még javítás történni → **NE indíts el felesleges build-et most**
- ✅ Állítsd le a futó buildet (`TaskStop`, vagy ekvivalens), majd egy menetben commit-old az összes fixet és buildelj
- ✅ Ne pollold a háttér-task állapotát — várd meg az automatikus completion notification-t

### 0.4 Munkafolyamat

Minden új feladatnál:

1. **Olvasd el a `CLAUDE.md`-t** (vagy ekvivalens platform-utasítás fájlt) a repo gyökerében
2. **Olvasd el az `AI_CONSTITUTION.md`-t** (ha létezik)
3. **Ellenőrizd a git állapotot:** `git status`, `git log --oneline -10`
4. **Vegyél figyelembe minden korábbi user-direktívát** (vault `feedback/`, ha létezik)
5. Csak ezután kezdj módosítani

---

## 1. Lint pipeline

> **Cél:** minden commit ELŐTT ellenőrizzük, hogy a kód lint-clean és typecheck-clean, így a CI nem fail-el.

### 1.1 Frontend admin (React + Vite + TypeScript)

```bash
cd frontend-react

# Tisztán typecheck (NEM fordít, csak ellenőriz)
npm run typecheck     # tsc --noEmit

# Lint i18n-gate (a max-warnings threshold a package.json-ben van rögzítve)
npm run lint:i18n-gate
# Eredmény: ✖ N problems (0 errors, N warnings)
# A threshold-ot ne lépd túl — vagy javítsd a warning-ot, vagy bumpold a threshold-ot
# (csak ha az új warning szándékosan hozzáadott UX szöveg).

# Test (ha van változtatás)
npm test

# Production build (ellenőrizd hogy fordít)
npm run build
```

### 1.2 Penztar-client (Electron 33 + React)

```bash
cd penztar-client

# Tisztán typecheck (Electron main + renderer közös tsconfig)
npm run typecheck     # tsc --noEmit -p tsconfig.json

# Lint
npm run lint

# Test (Vitest + Playwright IPC contract)
npm test
```

### 1.3 Backend (Java 21 + Spring Boot 4.0.6 + Maven)

```bash
cd backend

# Compile + test
./mvnw test          # JUnit 5

# Package without tests (csak build, NEM teszt)
./mvnw package -DskipTests -q

# Verify (lint-szerű check + tests)
./mvnw verify
```

### 1.4 Pre-push gate

A push ELŐTT futtasd a teljes pipeline-t a saját gépeden. Ha a CI-n bukna, jobb itt elcsípni.

```bash
# Egy menetben (gyors válogatás)
cd backend && ./mvnw package -DskipTests -q && cd ../frontend-react && npm run typecheck && npm run lint:i18n-gate && cd ../penztar-client && npm run typecheck && npm run lint && cd ..
```

### 1.5 Lint-i18n-gate threshold

A `frontend-react/package.json` `lint:i18n-gate` script tartalmaz egy `--max-warnings N` küszöböt (~2867-2870 jelenleg). Ha új literal stringet adsz hozzá a UI-ban (magyar szöveg), és ez a warning számot túllépi, **bumpold** a threshold-ot:

```json
"lint:i18n-gate": "eslint src --rule \"...\" --max-warnings 2870"
```

A threshold csak akkor bumpolható, ha az új warning **szándékos UX-szöveg** (NEM lehet i18n key-be tenni). Egyébként javítsd ki.

---

## 2. 4-way Version Sync (KÖTELEZŐ minden release-nél)

> A repo négy különálló helyen tárol verziószámot. Mind a 4-nek **EXACT EGYEZŐ** értéken kell lennie, különben a build-installer.ps1 gate exit 2-vel failel.

### 2.1 A 4 hely

| Fájl | Példa |
|---|---|
| `package.json` (root) | `"version": "2.5.24"` |
| `frontend-react/package.json` | `"version": "2.5.24"` |
| `penztar-client/package.json` | `"version": "2.5.24"` |
| `backend/pom.xml` | `<version>2.5.24</version>` |

### 2.2 Bump parancs (4-way)

```bash
# 1-3: a 3 npm projekt (root + frontend-react + penztar-client)
cd /repo/root
npm version 2.5.24 --no-git-tag-version
cd penztar-client && npm version 2.5.24 --no-git-tag-version
cd ../frontend-react && npm version 2.5.24 --no-git-tag-version
cd ..

# 4: a backend pom.xml — manuális Edit (NEM tudja az npm version)
# Megjegyzés: <version>X.Y.Z</version> a 20. sor körül van (a parent után)
```

Vagy egyetlen Edit művelet a `backend/pom.xml`-en:
```xml
<artifactId>valuta-backend</artifactId>
<version>2.5.24</version>     <!-- itt -->
```

### 2.3 Verifikáció

```bash
grep '"version"' package.json frontend-react/package.json penztar-client/package.json
grep -E '<version>\d+\.\d+\.\d+</version>' backend/pom.xml | head -1
# Mind a 4-nek ugyanazt a verziót kell mutatnia.
```

### 2.4 Auto-patch a build során

A `build-installer.ps1` rendelkezik egy "Version Bump Gate"-tel, ami AUTO-PATCH bumpolja a verziót a következő release-számra, ha:
- a `package.json`-ben rögzített verzióhoz már létezik build artifact (pl. `Penztar-Setup-2.5.24-...exe`)
- vagy a 4 hely közül bármelyik elcsúszott

Tehát ha **2.5.24-re bumpoltál**, és a build elindul, **2.5.25**-re patchelheti automatikusan. Ezt CSAK akkor hagyd, ha tudatos. Egyébként: a 4 hely manuális egyszinkronozása + verzió ellenőrzés.

---

## 3. Push protocol

> Minden commitnak **megfelelő scope-ban** és **conventional commit-magyar formátumban** kell lennie.

### 3.1 Pre-push checklist

```bash
# 1. Stage csak a megfelelő fájlokat (NE git add . vagy git add -A!)
git add -- backend/src/main/java/.../FixedFile.java backend/pom.xml package.json package-lock.json
# stb. — minden módosított fájlt explicit add, hogy ne kerüljenek be véletlen fájlok

# 2. Ellenőrizd, mit fogsz commitolni
git status --short
git diff --staged | head -50

# 3. Lint + typecheck lokálisan (ne kerüljön CI-re fail)
# (lásd 1.4 fejezet pre-push gate)

# 4. Commit conventional + magyar magyarázat
git commit -m "$(cat <<'EOF'
fix(component): rovid angol leiras

Magyar magyarazat:
- Mit javit
- Miert
- Hogyan
- Hivatkozasok (PR #N, Issue #M, vault feedback)
EOF
)"

# 5. Push
git push -u origin <branch-name>
```

### 3.2 Conventional Commits formátum

```
<type>(<scope>): <rovid leiras>

<reszletes magyarazat>
```

| `<type>` | Mikor használod |
|---|---|
| `feat` | Új funkció |
| `fix` | Bug fix |
| `docs` | Csak dokumentáció |
| `chore` | Build/dep update |
| `refactor` | Refaktor (no behavior change) |
| `test` | Csak teszt |
| `perf` | Performance fix |

Példa:
```
fix(auth): main-process Google + jelszavas login + retry-logic Borsi/Zsuzsa-tunet (v2.5.21)
```

### 3.3 Branch naming

```
fix/v<verzió>-<rövid-fix-leírás>      # fix/v2.5.20-google-login-main-process-and-retry
feat/v<verzió>-<feature-leírás>       # feat/v2.5.0-vault-only-filter
chore/v<verzió>-<chore-leírás>        # chore/v2.5.13-jackson3-migration
```

### 3.4 GitLeaks pre-commit hook

A repo `.git/hooks/pre-commit`-ben van GitLeaks scanner (vagy GitHub Actions secrets job). Pre-commit fail esetén:
- Ne committolj secret-eket (API key, password, token) a kódba
- Az `.env`-ben tárold (gitignored)
- Build-time injection-nel olvasd be (pl. `installer/build-installer.ps1` `Generate-EnvProduction` function)

### 3.5 Defensive flags

- ❌ **NE használj** `--no-verify` flag-et (kihagyja a pre-commit hook-okat)
- ❌ **NE használj** `git push --force` main branch-re
- ❌ **NE használj** `git reset --hard` user-direktíva nélkül

---

## 4. Pull Request workflow

### 4.1 PR létrehozás

```bash
# A push után automatikus URL jön: https://github.com/.../pull/new/<branch>
# Vagy explicit PR open:

gh pr create \
  --title "fix(component): rovid leiras (v<verzió>)" \
  --body "$(cat <<'EOF'
## Summary

<Mit javit ez a PR — 1-3 mondat>

## Root cause

<Miert tortent a hiba — diagnozis>

## Fix

<Hogyan oldja meg — file path-okkal>

## Test plan

- [ ] Lokalis typecheck zöld
- [ ] Lokalis lint zöld
- [ ] CI lint + typecheck + test + build zöld
- [ ] Build v<verzió> installer + smoke teszt
- [ ] Verifikalva (kollega gepen, vagy dev gepen)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

### 4.2 CI ellenőrzés

A PR megjelenik egy CI workflow set-tel (~15 check). **Mind ZÖLD** kell legyen mielőtt mergelsz:

```bash
gh pr checks <PR_NUMBER>
```

Tipikus check-list:
- `Analyze (actions/java-kotlin/javascript-typescript)` — CodeQL SAST
- `Auth Reload Smoke (Playwright)` — E2E
- `Backend Build + Test` — mvn package + JUnit
- `frontend-react Lint + TypeCheck` — eslint + tsc
- `penztar-client Test + Lint + TypeCheck + IPC Contract` — Vitest + Playwright
- `npm audit (frontend + penztar-client)` — security advisories
- `GitLeaks Secret Scan` — committed secret detection
- `Trivy Backend SCA` — container vuln scan
- `GitHub Dependency Review` — Dependabot
- `Sourcery review` — AI code review
- `UTF-8 Guardrail Check` — charset enforcement

### 4.3 CI failure-fix loop

1. `gh run view <run-id> --log-failed | head -50`
2. Olvasd ki a hibát (TS error, lint warning, test fail, audit advisory)
3. Javítsd lokálisan
4. Új commit + push
5. Várd meg a CI újrafutást
6. Ismétlés zöldig

### 4.4 AI review

Sourcery, Codex, Copilot review-k automatikusan jönnek a PR-re. Lekérdezés:

```bash
# Reviews (top-level review submissions) — Codex auto + Sourcery + Copilot
gh api "/repos/<OWNER>/<REPO>/pulls/<PR>/reviews" \
  --jq '.[] | select(((.user.login | ascii_downcase | contains("codex")) or (.user.login | ascii_downcase | contains("sourcery")) or (.user.login | ascii_downcase | contains("copilot"))) and ((.body // "") | (contains("create a Codex account") | not)) and ((.body // "") | (contains("weekly rate limit") | not))) | {reviewer:.user.login,state,body}'

# Inline comments (file:line specific findingek)
gh api "/repos/<OWNER>/<REPO>/pulls/<PR>/comments" \
  --jq '.[] | select((.user.login | ascii_downcase | contains("codex")) or (.user.login | ascii_downcase | contains("sourcery")) or (.user.login | ascii_downcase | contains("copilot"))) | {user:.user.login,path,line,body}'
```

A `(contains("create a Codex account") | not)` és `(contains("weekly rate limit") | not)` szűrők kizárják a noise-t (Codex setup-prompt, Sourcery weekly rate-limit).

**MINDEN P0/P1/P2 findingot KÖTELEZŐ javítani** a mergelés előtt. Új cumulative commit a meglévő PR-be:

```bash
git add <fixed-files>
git commit -m "fix(ai-review): P1 ${TYPE} ${SHORT_DESC} (Sourcery/Codex/Copilot #${PR})"
git push
```

### 4.5 Merge

```bash
# Ha a CI mind ZÖLD ÉS minden P0/P1/P2 fixed:
gh pr merge <PR> --squash --delete-branch

# Ha branch protection blokkol (default branch protected):
gh pr merge <PR> --squash --delete-branch --admin

# Helyi cleanup
git checkout main
git pull --ff-only origin main
git branch -d <merged-branch-name>     # ha még nem törlődött
```

### 4.6 Post-merge

- A `--delete-branch` flag a remote branch-et törli
- Helyi: `git branch -d <branch>` (ha mergelve)
- Hetzner auto-deploy elindul (lásd 5. fejezet)

---

## 5. Deploy to Hetzner VPS

> A push to main automatikusan triggereli a `.github/workflows/deploy.yml` workflow-t, ami SCP-vel áttölti a backend JAR-t a Hetzner VPS-re és újraindítja a service-t.

### 5.1 GitHub Actions secrets (előfeltétel)

| Secret | Jellege |
|---|---|
| `HETZNER_SSH_PRIVATE_KEY` | SSH ed25519 kulcs PEM |
| `HETZNER_SERVER_IP` | IP cím (pl. `<HETZNER_IP>`) |
| `HETZNER_SSH_USER` | `root` (vagy dedikált user) |
| `GITHUB_ISSUE_AUTO_CREATE_TOKEN` | fine-grained PAT (repo+issues+pulls scope) |
| `GOOGLE_DESKTOP_CLIENT_ID/SECRET` | Google Cloud Console Desktop OAuth |

### 5.2 deploy.yml minta

```yaml
name: Deploy to Hetzner VPS
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5

      - uses: actions/setup-java@v5
        with:
          distribution: temurin
          java-version: 21

      - name: Build backend
        working-directory: backend
        run: ./mvnw package -DskipTests

      - name: SCP JAR to Hetzner
        env:
          SSH_KEY: ${{ secrets.HETZNER_SSH_PRIVATE_KEY }}
          SERVER: ${{ secrets.HETZNER_SERVER_IP }}
          USER: ${{ secrets.HETZNER_SSH_USER }}
        run: |
          mkdir -p ~/.ssh && echo "$SSH_KEY" > ~/.ssh/id_deploy && chmod 600 ~/.ssh/id_deploy
          scp -i ~/.ssh/id_deploy -o StrictHostKeyChecking=no \
              backend/target/valuta-backend-*.jar \
              ${USER}@${SERVER}:/opt/valuta/valuta-backend.jar
          ssh -i ~/.ssh/id_deploy -o StrictHostKeyChecking=no ${USER}@${SERVER} \
              "systemctl restart valuta-backend"
```

### 5.3 Deploy verifikáció

A push után 2-5 percen belül:

```bash
# 1. Workflow status
gh run list --workflow deploy.yml --limit 3

# 2. Health check (új JVM PID, új verzió)
curl -sI https://excvaluta.com/api/v1/auth/bootstrap-status
# expected: HTTP/2 200

curl -s https://excvaluta.com/api/v1/auth/bootstrap-status
# expected: {"completed": true}

# 3. Backend journalctl (csak ha SSH-zhatsz)
ssh -i <SSH_KEY> <USER>@<HETZNER_IP> "journalctl -u valuta-backend.service -n 30 --no-pager | tail -30"
```

### 5.4 Deploy hiba esetén

- `gh run view <run-id> --log-failed` — workflow log
- Ha `mvn package` fail: lokális reproduce + javítás
- Ha SCP fail: SSH key vagy connectivity probléma → user-direktíva
- Ha service restart fail: `journalctl -u valuta-backend -n 100` SSH-zal

---

## 6. Tesztkörnyezet

### 6.1 Lokális dev stack

> **Production-first** szabály (Valutavalto-specifikus): a normál fejlesztés a Hetzner production backendhez (https://excvaluta.com) csatlakozik. Lokális stack csak unit-szintű debug-ra.

#### Backend (Spring Boot)

```bash
cd backend
./mvnw spring-boot:run
# Listens on localhost:8080
# Application properties: application-dev.properties (ha van)
```

#### Frontend admin (Vite)

```bash
cd frontend-react
npm install
npm run dev
# Listens on localhost:3000 (vagy 5173)
# Vite proxy: /api -> http://localhost:8080
```

#### Penztar-client Electron (dev mód)

```bash
cd penztar-client
npm install
npm run dev:main
# Electron main process indul
# A renderer a frontend-react :3000-on lévő dev szerverét tölti be
```

### 6.2 Komplex ökoszisztéma indítás (egy paranccsal)

```powershell
powershell -ExecutionPolicy Bypass -File scripts\start-valuta-ecosystem.ps1
```

Ez:
1. Lokális PostgreSQL ellenőrzés + Flyway migration alkalmazás
2. Backend `./mvnw spring-boot:run`
3. Frontend `npm run dev`
4. Penztar-client `npm run dev:main`
5. Health check minden komponensen
6. Log path-ok kilistázva

#### Leállítás

```powershell
powershell -ExecutionPolicy Bypass -File scripts\stop-valuta-ecosystem.ps1
# vagy:
Get-Process java,node,electron | Stop-Process -Force
```

### 6.3 Production smoke test

A deploy UTÁN:

```bash
# 1. Bootstrap-status
curl -s https://excvaluta.com/api/v1/auth/bootstrap-status
# expected: {"completed":true}

# 2. Public branches (multi-tenant smoke)
curl -s "https://excvaluta.com/api/v1/public/branches?companyCode=EBC" | head -10

# 3. Diagnostics POST E2E (auto-error-reporting verify)
curl -X POST -H "Content-Type: application/json" \
  -d '{"component":"electron-main","version":"2.5.24","errorMessage":"deploy smoke test"}' \
  https://excvaluta.com/api/v1/diagnostics/error-report
# expected: {"ok":true,"id":<N>}
```

### 6.4 Penztar-client E2E (Playwright)

```bash
cd penztar-client
npm run test:e2e
# A Playwright spec-ek a penztar-client/e2e/ alatt vannak
# Konfiguracio: playwright.config.ts vagy playwright.live.config.ts
```

---

## 7. Hetzner kezelés (server-oldali ops)

### 7.1 SSH access

```bash
# SSH config (~/.ssh/config) ajánlott
Host hetzner-valuta
    HostName <HETZNER_IP>
    User root
    IdentityFile ~/.ssh/<SSH_KEY_FILENAME>
    StrictHostKeyChecking no

# Ezután:
ssh hetzner-valuta
```

Vagy explicit:

```bash
ssh -i ~/.ssh/<SSH_KEY_FILENAME> -o ConnectTimeout=10 -o StrictHostKeyChecking=no \
    root@<HETZNER_IP>
```

### 7.2 systemd service

```bash
# Service status
systemctl status valuta-backend

# Restart (deploy után automatikus)
systemctl restart valuta-backend

# Stop / start
systemctl stop valuta-backend
systemctl start valuta-backend

# Enable on boot
systemctl enable valuta-backend
```

### 7.3 journalctl backend log

```bash
# Utolsó 50 sor
journalctl -u valuta-backend.service -n 50 --no-pager

# Utolsó 1 óra
journalctl -u valuta-backend.service --since "1 hour ago" --no-pager

# Élő követés
journalctl -u valuta-backend.service -f

# Hiba-szűrés
journalctl -u valuta-backend.service --since "1 hour ago" --no-pager | \
    grep -iE 'error|exception|fail' | tail -30

# Specifikus tárgyú szűrés
journalctl -u valuta-backend.service --since "1 hour ago" --no-pager | \
    grep -iE 'GitHubIssueAutoCreator|client-error|google-login'
```

### 7.4 PostgreSQL queries

```bash
# Kliens-oldali hibanapló (utolsó 90 perc)
sudo -u postgres psql -d valuta -P pager=off -c "
SELECT id, created_at AT TIME ZONE 'Europe/Budapest' as cet,
       component, version, os_info,
       LEFT(error_message, 100) as err, client_ip
FROM client_error_log
WHERE created_at > NOW() - INTERVAL '90 minutes'
ORDER BY created_at DESC
LIMIT 50;"

# Worker táblák ellenőrzése (multi-tenant)
sudo -u postgres psql -d valuta -P pager=off -c "
SELECT id, code, branch_id, role, password_changed_at IS NOT NULL as has_pw
FROM worker
WHERE company_id = 1
ORDER BY id;"

# Flyway migration status
sudo -u postgres psql -d valuta -c "SELECT version, description, success FROM flyway_schema_history ORDER BY installed_rank DESC LIMIT 10;"
```

### 7.5 nginx / Caddy reverse proxy

A Valutavalto setup-ban nginx van:

```bash
# nginx config (Caddy is használható, akkor /etc/caddy/Caddyfile)
cat /etc/nginx/sites-enabled/valuta.conf

# Reload (no downtime)
nginx -t && systemctl reload nginx

# Access log szűrés
tail -n 5000 /var/log/nginx/access.log | grep -iE 'google-login|/auth/login' | tail -30

# Error log
tail -n 100 /var/log/nginx/error.log
```

### 7.6 Cloudflare DNS / API ops

```bash
# IPv6 OFF (kötelező magyar ISP-knél!)
curl -X PATCH "https://api.cloudflare.com/client/v4/zones/<ZONE_ID>/settings/ipv6" \
     -H "Authorization: Bearer <CF_API_TOKEN>" \
     -H "Content-Type: application/json" \
     -d '{"value":"off"}'

# DNS records lekérése
curl "https://api.cloudflare.com/client/v4/zones/<ZONE_ID>/dns_records" \
     -H "Authorization: Bearer <CF_API_TOKEN>" | jq '.result[] | {type, name, content}'

# Zone ID megszerzése (ha nem ismered)
curl "https://api.cloudflare.com/client/v4/zones?name=<DOMAIN>" \
     -H "Authorization: Bearer <CF_API_TOKEN>" | jq '.result[0].id'
```

### 7.7 Backend env vars frissítés

```bash
# /etc/valuta/valuta.env
sudo nano /etc/valuta/valuta.env
# (chmod 600 + chown valuta:valuta)

# Service restart hogy az új env-et felvegye
systemctl restart valuta-backend
```

Tipikus tartalom:
```
DB_PASSWORD=<DB_PASS>
JWT_SECRET=<JWT_HEX_64_CHAR>
GOOGLE_WEB_CLIENT_ID=<WEB_CLIENT_ID>.apps.googleusercontent.com
GOOGLE_DESKTOP_CLIENT_ID=<DESKTOP_CLIENT_ID>.apps.googleusercontent.com
GITHUB_ISSUE_AUTO_CREATE_ENABLED=true
GITHUB_ISSUE_AUTO_CREATE_TOKEN=<GITHUB_PAT>
GITHUB_ISSUE_AUTO_CREATE_REPO=<OWNER>/<REPO>
```

---

## 8. Installer EXE készítés (NSIS, Windows)

> A Valutavalto installer 2 különálló .exe-ből áll: **Setup** (telepítő) és **Eltavolito** (uninstaller). Mindkettőt külön build-script gyártja.

### 8.1 Pre-build checklist

1. **4-way version sync** (lásd 2. fejezet) — mind a 4 helyen ugyanaz a verzió
2. **Lokális lint + typecheck zöld** (lásd 1. fejezet)
3. **NSIS telepítve** (3.10+ ajánlott): `C:\Program Files (x86)\NSIS\makensis.exe`
4. **Maven Wrapper működik** (`mvnw.cmd`)
5. **Node 20.19+** (LTS)
6. `.env` (gitignored) tartalmazza a build-time injection változókat: `VITE_GOOGLE_DESKTOP_CLIENT_ID`, `VITE_GOOGLE_DESKTOP_CLIENT_SECRET`, stb.

### 8.2 Setup build (a fő telepítő)

```powershell
Set-Location 'D:\repo\valutavalto-program'   # vagy a saját repo gyökér

powershell -ExecutionPolicy Bypass -File "installer\build-installer.ps1" -SkipDownloads
```

Lépések amit a build-installer.ps1 csinál:
1. **0/6 — Env injection:** generálja `installer/build/stage/.env.production`-t a repo `.env`-ből
2. **1/6 — Version Bump Gate:** ellenőrzi a 4-way sync-et + AUTO-PATCH bumpolást ha kell
3. **2/6 — Backend build:** `./mvnw package -DskipTests -q` → JAR
4. **3/6 — Frontend admin build:** `npm ci && npm run build` (frontend-react)
5. **4/6 — Penztar-client build:** `npm ci && npm run build` (Electron + renderer)
6. **5/6 — Stage dir + asset másolás:** stage dir-be összegyűjti a fájlokat (Postgres binaries, Java JBR, dist-ek)
7. **6/6 — NSIS makensis:** `Penztar-Setup.nsi` → `installer/build/Penztar-Setup-<VERZIÓ>-<DÁTUM>.exe`

Eredmény:
```
KESZ: Penztar-Setup-2.5.24-20260505.exe - 280 MB
   Helye: D:\repo\valutavalto-program\installer\build\Penztar-Setup-2.5.24-20260505.exe
   Verzio: 2.5.24 (20260505)
=== BUILD COMPLETE ===
```

Tipikus időtartam: 15-25 perc (mvn package + npm install + NSIS LZMA tömörítés).

### 8.3 Eltavolito build

```powershell
powershell -ExecutionPolicy Bypass -File "installer\build-cleanup.ps1"
```

Lépések:
1. NSIS makensis a `Penztar-Cleanup.nsi`-vel
2. Eredmény: `installer/build/Penztar-Eltavolito-<VERZIÓ>-<DÁTUM>.exe` (~60 KB)

A Cleanup .exe **verzió-független** — ugyanaz minden release-en, csak a fájlnévben tükrözi a verziót.

### 8.4 Background build (long-running)

A teljes build 15-25 perc — ne vard meg synchron-on:

```powershell
# PowerShell háttérben (notification jön befejezéskor)
Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File installer\build-installer.ps1 -SkipDownloads" -NoNewWindow -RedirectStandardOutput "C:\Temp\build.log"
```

Vagy AI Ügynök esetén: `run_in_background: true` flag a Bash/PowerShell tool-on.

### 8.5 Build verifikáció

```bash
# 1. EXE fájlok létrejöttek
ls -la installer/build/Penztar-Setup-*.exe installer/build/Penztar-Eltavolito-*.exe | tail -2

# 2. SHA256 hash (Windows: certutil)
certutil -hashfile installer/build/Penztar-Setup-2.5.24-20260505.exe SHA256

# 3. Verzió a fájl Properties-ben
# (Windows Explorer: jobb klikk → Tulajdonságok → Részletek → ProductVersion)
```

### 8.6 Másolás a Downloads mappába (kollégai küldéshez)

```bash
cp installer/build/Penztar-Setup-2.5.24-20260505.exe "/c/Users/<USER>/Downloads/"
cp installer/build/Penztar-Eltavolito-2.5.24-20260505.exe "/c/Users/<USER>/Downloads/"
```

### 8.7 NSIS encoding rule

> **KÖTELEZŐ**: a `.nsi` fájlokat **Windows-1252 ASCII**-ban kell menteni, **NEM UTF-8**.

- ❌ ékezetek (ő, é, á, ó, ú) → **mojibake** vagy installer crash
- ❌ em-dash (—) → ASCII kötőjel (-)
- ✅ "Pénztár" → "Penztar"
- ✅ "Üzemmód" → "Uzemmod"

### 8.8 Silent install (telepítés UAC nélkül)

```powershell
# A NSIS /S flag silent install-t enged
$setup = "C:\Users\<USER>\Downloads\Penztar-Setup-2.5.24-20260505.exe"
Start-Process -FilePath $setup -ArgumentList "/S" -Verb RunAs -Wait
```

Megjegyzés: a `-Verb RunAs` UAC promptot indít, ami nem kerülhető meg interaktív gépen.

### 8.9 Smoke test az installer-en

```powershell
# 1. Eltavolito (silent + admin)
Start-Process -FilePath "C:\Users\<USER>\Downloads\Penztar-Eltavolito-2.5.24-20260505.exe" -ArgumentList "/S" -Verb RunAs -Wait

# 2. Setup (silent + admin)
Start-Process -FilePath "C:\Users\<USER>\Downloads\Penztar-Setup-2.5.24-20260505.exe" -ArgumentList "/S" -Verb RunAs -Wait

# 3. Verify
$exe = "C:\Program Files\Valutavalto Penztar\Penztar.exe"
(Get-Item $exe).VersionInfo.ProductVersion
# expected: 2.5.24

# 4. Indítás + log ellenőrzés
Start-Process -FilePath $exe -PassThru
Start-Sleep 12
$log = Join-Path $env:APPDATA 'valuta-penztar\logs\main.log'
Select-String -Path $log -Pattern '\[App\]' | Select-Object -Last 10
# expected: "Error reporter initialized", "SyncEngine elindítva", stb.
```

---

## 9. Auto error-reporting + monitoring

### 9.1 Hetzner client_error_log lekérdezés

```bash
ssh -i <SSH_KEY> root@<HETZNER_IP> \
    "sudo -u postgres psql -d valuta -P pager=off -c \"
SELECT id, created_at AT TIME ZONE 'Europe/Budapest' as cet,
       component, version, os_info,
       LEFT(error_message, 100) as err, client_ip
FROM client_error_log
WHERE created_at > NOW() - INTERVAL '90 minutes'
ORDER BY created_at DESC LIMIT 50;\""
```

### 9.2 GitHub auto-reported issues

```bash
gh issue list -R <OWNER>/<REPO> \
    --label client-error --label auto-reported \
    --state open --limit 20 \
    --json number,title,state,createdAt \
    --jq '.[] | "#\(.number) [\(.state)] \(.createdAt) - \(.title[:80])"'
```

### 9.3 Komment egy auto-reportolt issue-ra

```bash
gh issue comment <ISSUE_NUMBER> -R <OWNER>/<REPO> --body "$(cat <<'EOF'
## Klasszifikáció

**Kategoria:** <axios timeout / Network Error / uncaughtException / DB / API contract>
**Forras:** <kollega gepe — IP, OS, verzio>

## Diagnozis

<Mit talaltal a logban / DB-ben / nginx-ben>

## Fix

<v<verzió> tartalmaz fix-et: PR #<N>>
EOF
)"
```

### 9.4 Hourly auto-triage routine (lokális Claude Code scheduled-task)

A `mcp__scheduled-tasks__create_scheduled_task` tool-lal hozz létre egy óránkénti routine-t, amelyik:
- `gh issue list` (last 90 perc)
- SSH SQL lekérdezés
- Klasszifikálja
- Kommentál
- Opcionálisan <20 LOC fix PR-t nyit

Cron: `13 * * * *` helyi idő (8 perc jitter → ~`:21`-kor).

---

## 10. Hibajavítási ciklus (release-loop)

### 10.1 Egy iteráció lépései

1. **Hibajelentés érkezik** (kollégától, GitHub Issue-n, DB-ben)
2. **Diagnózis** — log + DB query + nginx access log + kód
3. **Fix branch** — `git checkout -b fix/v<N>-<rovid-leiras>`
4. **Kód-módosítás** — minimum scope, NEM unrelated cleanup
5. **Lokális verify** — typecheck + lint + (lehetőleg) smoke teszt
6. **4-way version bump** (lásd 2. fejezet)
7. **Commit + push** (lásd 3. fejezet)
8. **PR + CI** (lásd 4. fejezet)
9. **AI review fix loop** (lásd 4.4)
10. **Merge** (lásd 4.5)
11. **Hetzner auto-deploy** (lásd 5. fejezet)
12. **Installer build + Downloads** (lásd 8. fejezet)
13. **Smoke test** (lásd 8.9)
14. **Kollégai küldés** (NEM technikai instrukcióval — lásd 0.2)

### 10.2 Cumulative fix-ek egy PR-ben

Ha mid-release több hibát találsz egymás után (pl. CI fail-ek vagy AI review-k), **NEM nyitsz új PR-t**, csak commit-olsz a már nyitott PR ágára:

```bash
git add <fixed-files>
git commit -m "fix(<scope>): <rovid leiras>"
git push    # ugyanaz a remote branch
```

A PR title-t frissítheted ha a verzió változott:
```bash
gh pr edit <PR_NUMBER> --title "fix(<scope>): <new-title> (v<new-verzió>)"
```

### 10.3 Token-takarékos build management

> Ha **mid-build** új hibajelentés érkezik vagy kiderül hogy lesz további javítás — **AZONNAL állítsd le a futó buildet**.

```python
# AI Ügynök eszköz: TaskStop a futó build task ID-jával
TaskStop(task_id="<BUILD_TASK_ID>")
```

A build folytatásával felesleges token-elhasználás (mvn + npm + NSIS = ~15-25 perc CPU/idő). Inkább:
1. Stop build
2. Hozzáadod a fix-et
3. Egy menetben commitolod
4. Egy build futtatva minden fix-szel

---

## 11. Pitfalls — KÖTELEZŐ olvasni

> Az alábbi 15 anti-pattern-be **TILOS** belesétálni. Mindegyikből órákat veszítettünk korábban.

| # | Hiba | Megelőzés |
|---|---|---|
| 1 | PostgreSQL `INET` típus + Hibernate String mapping | Mindig `VARCHAR(45)` IP cím tárolásra |
| 2 | `JsonNode` field a Spring Boot 4 + Jackson 3 stack-en | `Map<String, Object>` használata |
| 3 | `@PreAuthorize("permitAll()")` ÖNMAGÁBAN nem elég | `requestMatchers().permitAll()` is kell a SecurityConfig-ban |
| 4 | IdempotencyFilter blokkolja a stateless endpointokat | EXCLUDED_PREFIXES list (`/auth/`, `/diagnostics/`, `/public/`) |
| 5 | userData `.env` malformált `VITE_API_URL="https://"` | main.ts startup-on regex check + auto-overwrite |
| 6 | Setup Wizard `bootstrapPassword` ≠ `currentPassword` | NE küldd a step 4 jelszót `currentPassword`-ként |
| 7 | axios `timeout: 15000` túl rövid ESET MITM-mel | 30000 ms minimum, plus retry interceptor |
| 8 | IPv6 happy-eyeballs hang Cloudflare AAAA-n | Cloudflare IPv6 OFF (server-side) + `--disable-features=EncryptedClientHello` |
| 9 | electron-updater 404 a `latest.yml`-re | Manuális latest.yml a build-installer.ps1-ben + GitHub Release-be uplod |
| 10 | Renderer axios POST ESET MITM-mel leesik | Main-process `electron.net.request` (Windows cert store) |
| 11 | Google OAuth Web SDK `app://localhost` reject | Desktop OAuth client + RFC 8252 loopback |
| 12 | GitHub Push Protection blokkolja a committed secret-eket | `.env` gitignored + build-time injection |
| 13 | 4-way version drift → build gate exit 2 | `npm version X.Y.Z --no-git-tag-version` 3 helyen + Edit pom.xml |
| 14 | NSIS encoding (Windows-1252 ASCII only) | Ne használj ékezetet, em-dash-t a `.nsi` fájlokban |
| 15 | Penztar.exe locked during reinstall | LockedList plugin + `taskkill /im Penztar.exe /f` az .onInit-ben |

A részleteket lásd: `valuta-program-bootstrap-guide.md` 10. szekció (vagy a vault-ban a `references/` alatt).

---

## 12. Daily / Hourly checklist (AI Ügynök rutin)

### 12.1 Session-eleji (minden új munkamenet kezdetén)

- [ ] `cat CLAUDE.md` — projekt mandátum
- [ ] `cat AI_CONSTITUTION.md` — alkotmány (ha létezik)
- [ ] `git status` + `git log --oneline -10` — repo állapot
- [ ] Vault `feedback/` skim — user-direktívák
- [ ] Aktuális branch ellenőrzés (`git branch --show-current`)

### 12.2 Munka közbeni

- [ ] Minden hibajelentésre azonnal reagálj (DB query + Issue komment)
- [ ] Több AI review finding cumulative commit-ban a meglévő PR-be
- [ ] Mid-build új hiba → STOP build, fix, restart
- [ ] Nem-informatikus kollégának SOSEM küldj parancssort

### 12.3 Session-zárás

- [ ] Minden módosítás commit-olva + push-olva
- [ ] PR-ek mergelve VAGY work-in-progress label-lel
- [ ] Vault `sessions/YYYY-MM-DD-<rovid-leiras>.md` írása (mit csináltál, mit tanultál)
- [ ] Build artifacts (Setup + Eltavolito) Downloads-ban (ha készültek)
- [ ] Status report a usernek: mit tettél, mi a következő, blokkoló-e bármi

---

## 13. Példa: full release loop (Borsi-fix v2.5.24, 2026-05-05)

Időrendben, ahogy ténylegesen történt:

1. **Hibajelentések érkeztek** — Borsi laptop + Zsuzsa "Network Error" / "timeout 30000ms" a Google login-on
2. **DB lekérdezés** — `client_error_log` 40+ row, mindegyik 84.0.40.124 (Borsi) vagy 85.66.145.53 (Zsuzsa) IP-ről
3. **Diagnózis** — nginx access log szerint a `/auth/google-login` POST néha NEM érkezik be → ESET MITM TLS-handshake leejti a connection-t
4. **Fix terv** —
   - Renderer axios retry interceptor (auth + sync polling)
   - Main-process Google login + sima jelszavas login (electron.net.request, 3× retry)
   - Setup Wizard 5. lépés worker-szinkron
   - Setup Wizard 4. lépés "Teszt jelszó" mező eltávolítva
5. **Branch** — `git checkout -b fix/v2.5.20-google-login-main-process-and-retry`
6. **Kód-módosítás** — `frontend-react/src/services/api/client.ts`, `penztar-client/electron/google-oauth.ts`, `penztar-client/electron/main.ts`, `penztar-client/electron/preload.ts`, `frontend-react/src/types/electron.d.ts`, `frontend-react/src/pages/auth/LoginPage.tsx`, `frontend-react/src/pages/setup/SetupWizard.tsx`
7. **4-way version bump** — 2.5.19 → 2.5.20 → 2.5.21 → 2.5.22 → 2.5.23 → 2.5.24 (kumulatívan, mid-iteration token-takarékos stop+fix+resume miatt)
8. **Lokális verify** — `npm run typecheck` + `npm run lint:i18n-gate` mindkét frontend projektre PASS
9. **Commit-ok** — 5 commit a branch-re, mindegyik conventional + magyar magyarázat
10. **Push** — `git push -u origin fix/v2.5.20-google-login-main-process-and-retry`
11. **PR #422** — `gh pr create` a fenti template-tel
12. **CI kerekek** — első kerek 3 fail (typecheck + lint + npm audit), kumulatív fix commit-tal mind ZÖLD
13. **AI review** — Sourcery + Codex + Copilot review (PR #422 page-en), nincs P0/P1/P2 finding
14. **Admin-merge** — `gh pr merge 422 --squash --delete-branch --admin` (branch protection miatt admin)
15. **Pull main** — `git checkout main && git pull --ff-only`
16. **Hetzner auto-deploy** — GitHub Actions deploy.yml lefutott ~3 perc alatt, smoke test 200 OK
17. **Installer build** — `installer/build-installer.ps1` 22 perc → `Penztar-Setup-2.5.24-20260505.exe` (280 MB)
18. **Eltavolito build** — `installer/build-cleanup.ps1` 30 sec → `Penztar-Eltavolito-2.5.24-20260505.exe` (60 KB)
19. **Másolás Downloads-ba + SHA256**
20. **Smoke test** dev gépen: silent uninstall + silent install → Penztar.exe v2.5.24.0 indul, log mutat `Error reporter initialized` + `SyncEngine elindítva`
21. **Küldés a kollégáknak** — NEM technikai instrukció, csak dupla-klikk + UAC + admin jelszó

A teljes ciklus időtartama: ~3 óra (több commit + 2 build).

---

## 14. Záró megjegyzések

### 14.1 Mit csinálj minden alkalommal

- ✅ Olvasd el a CLAUDE.md-t és AI_CONSTITUTION-t
- ✅ Minden állítást ellenőrizd (parancs, log, DB query)
- ✅ 4-way version sync minden release-nél
- ✅ AI review zero-tolerance — minden P0/P1/P2 fix kötelező
- ✅ Cumulative commits a meglévő PR-be (NE új PR új fix-szel)
- ✅ Mid-build új hiba → STOP build, javítás, restart
- ✅ Kollégai üzenet: NEM technikai (csak dupla-klikk + UAC)

### 14.2 Mit SOHASE csinálj

- ❌ NE találgass — futtasd le a parancsot
- ❌ NE használj `git push --force` main-re
- ❌ NE használj `--no-verify` (kihagyja a hook-okat)
- ❌ NE bumpold a version-t csak 3 helyen a 4 közül
- ❌ NE küldj parancssort a kollégának
- ❌ NE adj ki "valószínűleg jó" telepítőt — smoke teszt pass után küldd
- ❌ NE pollozz háttér-task-ot (várd meg a notification-t)

### 14.3 Hivatkozások

- **Repo:** `https://github.com/<OWNER>/<REPO>`
- **Vault:** `<VAULT_PATH>` (Obsidian)
- **CLAUDE.md** és **AI_CONSTITUTION.md** a repo gyökerében
- **Bootstrap guide** (új projekt indításához): `valuta-program-bootstrap-guide.md`

### 14.4 Záró elv

> **Hallucináció nélkül, tényalapon, nem-informatikus felhasználó-barát terméket adunk ki — csak 100%-ban működőt.**

Ez a kézikönyv pontosan olyan az AI Ügynöknek, amilyen a folyamat ténylegesen kikísérletezve működik a Valutavalto Pénztár projektben. Minden parancs, minden lépés bizonyítottan működött a 2026-04-23 és 2026-05-05 közötti release-ciklusokban.

Sok sikert!

---

*Készült Claude Code-ban a 2026-05-05-i Valutavalto session tapasztalatai alapján.*
*Source repo: D:\\repo\\valutavalto-program @ main HEAD 70c719de + (release v2.5.24).*
