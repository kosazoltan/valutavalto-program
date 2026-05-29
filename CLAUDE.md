# Valutaváltó ERP — Claude Code kontextus

Magyar valutaváltó / pénzváltó ERP. Multi-tenant (több iroda), offline-képes. A domain magyarul:
vétel (buy), eladás (sell), sztornó (storno), napzárás (daily closing), címletezés (denomination),
árfolyam (exchange rate), átadás-átvétel (transfer), foglaló (reservation).

> **Karcsúsítva 2026-05-27.** A teljes mandátum-szövegek a kanonikus fájlokban élnek (lent hivatkozva);
> a v2.5.x–v2.27.25 release-történet: [vault/sessions/release-history-archive-through-2.27.25.md](vault/sessions/release-history-archive-through-2.27.25.md).
> **WHEN IN DOUBT:** a repo-tény (kód, Flyway-migráció, AI_CONSTITUTION.md, git log) erősebb, mint az AI emlékezet.

## SESSION-START kötelező olvasmány (sorrendben)

1. `vault/elvi/vv-elvi-mirror.md` — VV-ELVI kanonikus tükör
2. `vault/feedback/_active_mandates.md` — aktív mandate-index
3. `AI_CONSTITUTION.md` (repo gyökér) — 10 nem-alkuképes szabály + 7 tiltás + 7 réteg, **L2** érettség. Konfliktusban FELÜLÍR mindent.
4. `CLAUDE.md` (ez a fájl) — mérnöki workflow
5. `~/.claude/projects/<hash>/memory/MEMORY.md` — auto-memory index
6. `vault/sessions/` — legfrissebb session-jegyzet

---

## ⚠️ NULLADIK PRIORITAS — nem-informatikus végfelhasználó alapelv (2026-05-05, MINDEN más felett)

A kollégák **NEM informatikusok**. **TILOS** nekik küldeni: parancssort (`ipconfig`/`netsh`/`Stop-Process`),
manuális mappa-törlést, `.env`/`hosts`-szerkesztést, registry/antivírus-konfigot. **A telepítő MINDENT
automatikusan elvégez** (DNS-flush, userData-migráció, régi-bundle-törlés, registry-fix, tűzfal, parancsikon,
diagnosztika). A felhasználó dolga: dupla-klikk + UAC „Igen" (+ esetleg admin-jelszó). Server-oldali fixet
(pl. Cloudflare DNS) **én** végzem API-tokennel. **Csak 100%-ban működő terméket adunk ki.** Tilos:
hallucináció, lustaság, halogatás, „feltételezem hogy jó". Teljes szöveg: `vault/feedback/auto-installer-everything-mandatory.md`.

## Kötelező mandátumok (teljes szöveg a kanonikus fájlban — kötelező betartani)

- **Session-zárási protokoll** (9 lépés: workspace→lokál gate→fix zöldig→merge-sync→push-check→KÜLSŐ CI/AI visszaolvasás→fix-ciklus→runtime-check→tényszerű záró jelentés). `.cursor/rules/mandatory-session-closing-protocol.mdc` + `vault/feedback/session-closing-protocol-mandatory.md`. Tilos a „valószínűleg jó" / CI-visszaolvasás nélküli „kész".
- **Folyamatos tesztelési protokoll** (4 lépés: tesztkörnyezet azonosítás→célzott teszt írás+futtatás kódolás közben→suite-bővítés→újrafuttatás). Tilos: teszt skip/törlés a zöldért, assertion-gyengítés, „működik" teszt nélkül. `.cursor/rules/mandatory-continuous-testing-protocol.mdc`.
- **Memória-protokoll** (session-eleji olvasás → munka közbeni frissítés → session-zárási mentés a `vault/`-ba). Csak ellenőrzött tény, NEM találgatás; titok soha. `.cursor/rules/mandatory-memory-protocol.mdc`.
- **Research-first hibajavítás**: dokumentáció + GitHub-forrás + Context7 MCP olvasása ELŐSZÖR; javítás csak bizonyított root cause alapján (forrás→diagnózis→minimális célzott fix→ellenőrzés). Próba-szerencse tilos. Context7 kulcs: `D:\openclaw\.openclaw\.env` (`CONTEXT7_API_KEY`) — soha ne írd chatbe/commitba.
- **Hallucináció-megszüntetés**: iparági standard libek (Zod, electron-log, TanStack stb.) ad-hoc megoldás helyett; komplex feature előtt brainstorming, implementáció előtt TDD. `vault/feedback/hallucinacio-megszuntetese.md`.
- **Security gate** minden feladatnál: `.cursor/rules/mandatory-security-gate.mdc` + `.cursor/skills/security-deploy-gate/SKILL.md`. Deploy előtt: `scripts/security/run-security-gate.ps1` (FAILED/BLOCKED → deploy tiltott).
- **V234 belső log+audit**: minden `LOG.error()`/`vvLogger.error()` KÖTELEZŐ `error_code`-dal (`VV-<KAT>-<3jegy>`). Új hibatípus → előbb `packages/shared-logging/error-codes.yaml` (ai_fix_hint + user_impact), csak utána a hívás. `audit_log` immutable (UPDATE/DELETE tiltott trigger).
- **Régi hibák azonnali javítása**: audit/review közben talált scope-on kívüli hibát is azonnal javítani (kivéve több-napos refaktor → GitHub issue + kód-komment).
- **Fejlesztési irány-audit (F.1, P0)**: tényalapúság (út+sor+idézet) · nulla halucináció/lustaság (futtass-mérj-igazolj) · research-first · folyamatos root-cause hurok teljes zöldig · Definition of Done · szállítás-előtti kötelező parancslánc (`agent:guard` → `self-check:before-*` → `github-signal-check.ps1 <PR>` → `ci:errors` → security-gate) · token-ökonómia (nincs felesleges PR). Teljes szöveg: `FEJLESZTESI_IRANY_AUDIT.md` (repo gyökér, az AGENTS.md/AI_CONSTITUTION.md precedence-lánc alatt).

## GitHub minőségbiztosítás (KÖTELEZŐ minden PR-en, automatikusan)

- **SSOT:** `AGENTS.md` (10 kapu, modellfüggetlen) + `AI_CONTRACT.md` (300 LOC plafon, test-manipuláció tilos) + `REVIEW.md` (push/merge/deploy self-review + **5-szempontú kód-tartalom review**). Multi-model mandate (Claude+Codex+Gemini), global memory: `OPUS_GITHUB_QUALITY_MANDATE.md`.
- **Minden push után KÖTELEZŐ az agent MAGA kéri le** (NEM email-másolás): CI checks + Codex + Sourcery + Copilot review + Dependabot + CodeQL + secret scanning. Query a `REVIEW.md`-ben + `scripts/github-signal-check.ps1 <PR>`.
  - Codex/Sourcery findingek: `gh api .../pulls/{N}/reviews` + `/comments` (NE `/issues/...` — ott csak mention-zaj). Zaj-szűrő: `contains("create a Codex account")|not` + `contains("weekly rate limit")|not`.
- **Minden P0/P1/P2 findinget KÖTELEZŐ javítani** (új follow-up commit) VAGY dokumentált defer-indoklás a vaultban. A Copilot EGYENÉRTÉKŰ Codex/Sourcery-vel. Tilos új feladat amíg finding nyitva. `vault/feedback/ai-review-mandate-zero-tolerance.md`.
- **2 ellenőrzési kör merge előtt**: CI gate + GitHub AI gate zöld + SAJÁT subagent kétkör self-review. `vault/feedback/two-rounds-before-merge-mandatory-2026-05-19.md`.
- **Proaktív polling minden push után** (T+60/120/180/300s, NEM passzív email-várás): `vault/feedback/proactive-ai-review-polling-mandatory-2026-05-19.md`.
- **push = commit + merge + BRANCH DELETE azonnal**: `gh pr merge <PR> --squash --auto --delete-branch` + lokál `git branch -d`. Nem maradhat nyitott PR/feature branch. Dependabot: heti batch. Heti cleanup ha aktív remote branch > 5. `.github/workflows/ai-review-auto-fix.yml` minden merge után triggerel.

## Production-first fejlesztés

- A produktum: Hetzner HA **https://excvaluta.com** (Scaleway warm standby). Frontend+Electron a production API-ra mutat.
- **Lokál DB seed TILOS**, ami nincs a produktum DB-n → új seed = **Flyway migráció** (`backend/src/main/resources/db/migration/V{N}__{name}.sql`) → commit → push → Hetzner auto-deploy. Kézi `psql INSERT` csak reprodukcióhoz, utána azonnal rollback.
- **Session-kezdő health-check (kötelező):** `curl -s https://excvaluta.com/api/v1/auth/bootstrap-status` (≥200) + `.../public/branches?companyCode=EBC` (non-empty). Ha DOWN: előbb helyreállítás.
- `docker-compose up postgres` csak `mvn test` + lokál debughoz.

## Verzió- és telepítő-build stratégia (2026-05-23)

`merge ≠ telepítő`. A frontend-react + backend minden mergelt PR után auto-deploy Hetznerre; a webes/backend
javítás telepítő-build nélkül a kollégáknál van. **Telepítő-build CSAK** ha: (1) Electron-natív réteg változik
(`*/electron/*`, natív dep, bundled JRE, auto-update baseline), VAGY (2) milestone (minor/major) lezárul.

| Szint | Mikor | Telepítő? |
|---|---|---|
| PATCH (2.27.**x**) | minden mergelt PR | ❌ csak merge + auto-deploy |
| MINOR (2.**27**.0) | tesztelhető csomag / Electron-natív változás | ✅ 1 build a batch végén |
| MAJOR (**3**.0.0) | teljes revízió/refaktor vége | ✅ 1 build |

Döntési teszt release-záráskor: `git diff main~N..main --name-only` → ha CSAK `backend/**` és/vagy `frontend-react/**` (nincs `*/electron/**` v. natív dep) → **NINCS build**. Telepítők: **Penztar-Setup** (pénztár+értéktár) + **Kozponti-Munkaallomas-Setup** (összevont központi+árfolyamkészítő, mód-választóval, v2.27.0+) + uninstaller. UNSIGNED a DigiCert EV CS cert kiadásáig (4-way version sync kötelező: `scripts/check-version-sync.mjs`).

## Memória-workflow (Obsidian vault — egyetlen aktív rendszer)

📍 `D:\repo\valutavalto-program\vault\` (sessions/ feedback/ references/ procedures/ operations/). Deprecated: `.memory/` SQLite, Cognee, Bence/Eszter/Tamás-koncepció, OpenClaw refek. Új session-jegyzet → `vault/sessions/YYYY-MM-DD-*.md`; quick-state → `.remember/remember.md`.

## Komplex ökoszisztéma indítás

„Indítsd a programot / teljes rendszer" → MINDIG az összes komponens: lokál PostgreSQL (5432) + backend (8080) + frontend-react (3000) + penztar-client Electron. Launcher: `scripts/start-valuta-ecosystem.ps1`, leállító: `scripts/stop-valuta-ecosystem.ps1`. Külön indítás csak debughoz, explicit megerősítéssel.

---

## Tech stack

- **Backend:** Java 21, **Spring Boot 4.0.6** (Tomcat 11, Servlet 6.1, Jackson 2 stop-gap), Spring Security (JWT), Spring Data JPA + Hibernate (**OSIV kikapcsolva** — `spring.jpa.open-in-view=false`), PostgreSQL, Flyway. — `backend/`
- **Frontend (admin):** React 19 + TypeScript (strict), Tailwind CSS 3, Zustand, Vite. — `frontend-react/`
- **Desktop kliensek (Electron 33, local-first SQLite + outbox sync):** `penztar-client/` (pénztáros), `kozponti-client/` (központi+árfolyamkészítő), `arfolyam-keszito-client/`.
- **Build:** Maven (backend), npm + Vite (frontend + kliensek).

## Könyvtárstruktúra (backend `src/main/java/hu/puzzleir/valuta/`)

`config/` (security, websocket, cors, rate-limit) · `controller/` (~113) · `dto/` · `entity/` (~165) ·
`mapper/` · `repository/` · `security/` (JWT, SecurityUtils) · `service/` (~122) · `util/` ·
`resources/db/migration/` (Flyway V1–V269+). Frontend: `frontend-react/src/{pages(~51),services/api.ts,utils/rounding.ts}`. Kliens: `penztar-client/electron/{sync-engine,sqlite,scanner}.ts`.

## Build és tesztek

```bash
cd backend && ./mvnw spring-boot:run                # backend (8080)
cd frontend-react && npm install && npm run dev     # admin (3000)
cd penztar-client && npm install && npm run dev     # pénztáros kliens
cd backend && ./mvnw test                           # JUnit 5
cd frontend-react && npm test                       # Vitest
cd penztar-client && npm test
```

## Fontos konvenciók

- **Multi-tenant:** MINDEN lekérdezés `companyId`-ra szűr (`SecurityUtils.getCurrentCompanyId()`) — hiányzó szűrés = IDOR. Single-id load után ellenőrizd a tulajdonost (tenant-idegen → 404, id-enumeráció ellen).
- **OSIV=false:** ha service entity-t ad vissza controllernek és a mapper lazy asszociációt olvas (`getBranch().getName()` stb.) → `LazyInitializationException` 500. Fix: JOIN FETCH a repo-query-ben VAGY `Hibernate.initialize(...)` a `@Transactional` metóduson belül.
- **HUF kerekítés:** 5 Ft-os kerekítés minden HUF összegnél (`roundHuf` / `HungarianRounding`); kliens: `roundFin`.
- **AML/Pmt.:** ellenőrzés tranzakció előtt; azonosítási küszöbök 100k (SIMPLIFIED) / 300k (FULL). Árfolyam 24h TTL — lejárt rátával nincs tranzakció.
- **Security:** `@PreAuthorize` minden védett controlleren; CORS nem wildcard; secret soha kódba/chatbe.

## Aktuális release-horgony

- **Verzió: v2.27.26** (2026-05-27). Production **HEALTHY 200**. Friss munka: élő-API kereszt­metszet bug-hunt (11 hiba, #865–#869) + architect-mode audit IDOR/LazyInit batch (#870). Teljes release-történet: [vault/sessions/release-history-archive-through-2.27.25.md](vault/sessions/release-history-archive-through-2.27.25.md).
- Folyó: architect-mode audit follow-up PR-ek (frontend SIMPLIFIED doc-number, AML reverseAccumulation, Electron HA failover sync-URL, PoliceRequest multi-tenant migráció).
