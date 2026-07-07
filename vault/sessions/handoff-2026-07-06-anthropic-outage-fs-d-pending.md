# Handoff — 2026-07-06 FS-GAP program, D-szelet PENDING (Anthropic hozzáférés kiesett)

> Oka: az Anthropic hozzáférés (Opus orchestrator + Fable planner) kikerült a
> session végén. A 4-szerepes pipeline nem folytatható (Fable tervezés + GLM
> review még elmegy OpenRouter/Nous úton, de az Opus orchestrátor nélül a
> minőségi szabvány nem tartható). A user explicit utasítása: álljunk meg,
> írjunk handoffot, várjuk az Anthropic visszatértét.

## EZ a fájl az EGYETLEN megbízható forrás egy fresh sessionnek

A háttér-subprocessek (planner/coder/review) egy gateway-drop vagy compaction
után ELVESZNEK, de az ON-DISK artefaktumok túlélnek. Minden állítást ebből a
fájlból + a git/Flyway/BACKLOG tényekből igazolj vissza — sose a beszélgetés
memóriájából.

---

## 1. AKTUÁLIS ÁLLAPOT (ellenőrizve a handoff írásakor)

- **Munkakönyvtár:** `D:\repo\valutavalto-program`
- **Aktív branch:** `feat/fs-d-versioning-review` (HEAD = `403fd2b2`, azonos a
  main-nel — a D-szelet **NINCS commitolva**).
- **Working tree:** NEM tiszta — a D-szelet (FS-3) teljes implementációja
  unstaged ` M` fájlokként áll a working tree-ben. Nem commitoltam, nem
  pusholtam, nem reviewoltam. A coder jelentése szerint FULL suite + typecheck
  + lint zöld volt, de ezt egy fresh sessionnak **ÚJRA kell futtatnia** a
  reviewer előtt (verify-don't-trust).
- **Main HEAD:** `403fd2b2` = PR #1347 (FS-C, központi üzenetküldés) merge.
- **Legutolsó Flyway a branchen:** `V343__customer_company_versioning_review.sql`
  (létezik a lemezen, de unstaged — a D-szelet része).
- **Prod:** excvaluta.com = **2.28.29**, Hetzner buildTime `2026-07-06T18:37:12Z`
  (a #1347 deployjából, friss). Scaleway hot-standby: a #1347 deployjának
  `Sync JAR to Scaleway` job-ja zöld volt (service_version 2.28.29, recovery=t).

## 2. A D-SZELET (FS-3) — IMPLEMENTÁLVA, DE PENDING (review előtt állunk)

**Feladat (Fable-5 HIGH terv, 1098 sor):** ügyfél/cég adat-verziózás +
compliance "Átnézve" jóváhagyási workflow.

**Kulcs-döntések (a planner kódszintű verifikációval):**
- **D1 verziózás:** `CustomerVersion` + `CompanyVersion` entitások **jsonb
  snapshot** tárolással (a repo meglévő AuditLog/SyncOutbox mintájára, NEM
  tükör-tábla — a Customer tábla 4× változott 2 hónap alatt, a tükör-tábla
  dupla-ALTER + drift-veszélyes lenne). V343 migráció baseline-seed soraival.
- **D2 reviewStatus:** DEFAULT `REVIEWED` a meglévő sorokon +
  `@Builder.Default REVIEWED` (backward-compat: a régi ügyfélbázis nem ömlik a
  compliance-várólistára + a tucatnyi @InjectMocks fixture nem törik). Pénztári
  (CASHIER) módosítás → PENDING_REVIEW; compliance-módosítás → auto REVIEWED.
- **D3:** a tranzakció-snapshot MÁR MEGVAN (Transaction denormalizált
  customerName/Address/DocumentNumber) — a terv do-not-touch-ként kezeli.
- **D4:** a penztar-clientben NINCS élő customer-sync csatorna (cached_customers
  halott DDL) → D3 csak DTO+typegen propagáció, sync-engine-t nem érinti.

**Coder (gpt-5.5) által jelentett verifikáció (FRESH SESSION: újra kell futtatni!):**
- `mvnw.cmd -q test` → exit 0 (FULL backend suite, ~2261 teszt)
- `npm run typegen` + `npm run typecheck` (4 kliens) → exit 0
- `npm test` → exit 0 (frontend 1907 + penztar all green)
- `npm run lint` → exit 0
- Flyway V0→V343 validate OK

**MI KELL MÉG a D-szeletre (Anthropic visszatérés után, sorrendben):**
1. **Verifikáció újrafuttatása** (full backend suite + typegen + typecheck +
   lint) — a coder állítását függetlenül igazolni.
2. **GLM-5.2 review** — a diff + plan alapján. A reviewer-charter mostantól
   SecOps-tudással bővítve (tenant-izoláció IDOR, authz, money-path fail-closed,
   injection — lásd lejjebb).
3. **DeepSeek aspect-security** (külön szűk security-pass) — ha a diff 3+ fájl
   vagy auth/security/crypto/money/tenant felületet érint (a D-szelet IGEN).
4. **Holdout** — a `.hermes/plans/fs-d-versioning-review-holdout.md` 3 black-box
   check (upsert-ág, aggregátum-útvonal, cross-tenant 404) futtatása
   append-and-revert módszerrel, commit előtt.
5. Commit + PR + CI + merge + deploy + **both-origin freshness check**
   (Hetzner origin-pin curl + Scaleway deploy-job log: service_version +
   recovery=t).

**A plan fájl:** `.hermes/plans/2026-07-06-fs-d-versioning-review.md`
**A holdout fájl:** `.hermes/plans/fs-d-versioning-review-holdout.md`

## 3. MAI NAP MERGELT PR-ek (main, 2026-07-06, időrendben)

| PR | SHA | Típus | Tartalom |
|---|---|---|---|
| #1321 | 33ed9813 | fix(ha) | audit-leletek A1-A7 (pre-flight guard + jelszó-redaction + chmod + rate-limit) |
| #1322 | 7a25fc23 | fix(ha) | A1 guard edge-case — psql race/üres recovery is ABORT |
| #1323 | 40bde5e8 | test(mapper) | 7 mapper teszt + ExchangeRateMapper NPE fix |
| #1324 | 59b39e59 | test(retry) | OptimisticLockRetry teljes teszt-lefedettség (unit + valós PG IT) |
| #1325 | cd5e166c | chore(release) | v2.28.28 verzió-bump (11-way) |
| #1334 | 0c6657ab | fix(installer) | NSIS VerifyElectronFile label-feloldás hiba (release-build blokkoló) |
| #1335 | ae71c7f4 | fix(audit) | F1-F3 audit-fixek (adjust idempotencia+audit, EmailAccount null-role 4xx, rate-print guarded fail-fast) |
| #1336 | 04a8d854 | hotfix(deploy) | RP-HA secret auto-provision (a #1335 pre-check fail-closed blokkolta a deployt) |
| #1337 | 9f9f8232 | feat(deploy) | Scaleway hot-standby JAR-sync reaktiválás (user-mandátum 2026-07-06) |
| #1338 | 12b6b769 | fix(ci) | AI Review Auto-Fix stabilizálás (CI-INFRA-AUTOFIX) |
| #1339 | 2fda9fef | fix(idempotency) | IdempotencyGuard kulcs-validáció + cache-hit audit (IDEM-KEYLEN + IDEM-CACHEHIT-AUDIT) |
| #1340 | 6235eae3 | chore(release) | v2.28.28 → 2.28.29 verzió-bump (11-way) |
| #1343 | 38efb0c1 | feat(fs-a) | ügyfél kockázati besorolás (FS-2) + okmány-lejárat enforcement (FS-4) |
| #1344 | f19b244a | fix(test) | flaky ContributionPage detail-panel assertion (MAIN STAYS GREEN) |
| #1345 | 116efb5a | feat(fs-b) | konfigurálható értéksávok (FS-8) + cégjegyzék-lejárat (FS-6) |
| #1346 | 4d4cce7a | fix(test) | flaky BranchPage branch-code-result assertion (MAIN STAYS GREEN) |
| #1347 | 403fd2b2 | feat(fs-c) | központi üzenetküldés kétirányú válasszal (FS-1) |

**Release:** v2.28.29 publikálva, telepítők a Downloads-ban, valós telepítés +
vizuális ellenőrzés megtörtént (a user gépén is telepítve+belépve).

## 4. FALSE ALARMS / cáfolt gyanúk (ma)

- **AML-írás duplikáció a retry-n:** cáfolva — az AmlService REQUIRED
  propagációja miatt együtt gördül vissza, nem duplikál.
- **HoldoutCheck.java "unverified" rendszer-flag (többször):** szándékosan
  törölt holdout-próba, 3/3 PASS a törlés előtt — nem valós teendő.
- **auto-fix CI bukás (#1324-en):** third-party claude-code-action belső hibája
  ("directory mismatch"), nem required check, diff-független.
- **ContributionPage/BranchPage flaky:** nem az FS-szeletek okozták (pre-existing
  flaky, szinkron getByTestId async render előtt) — gyökérok-fix findByTestId-re,
  assertion változatlan (MAIN STAYS GREEN).

## 5. A FOLYAMAT ÁLTAL TALÁLT ÚJ DEFECTEK (backlogba téve, javítandó)

- **FS-VISUAL-A:** CustomerDetailPage risk-badge + MANAGER/ADMIN risk-modal
  BÖNGÉSZŐS vizuális ellenőrzése — blokkoló: `browser_*` toolset nem elérhető,
  computer_use-flow-t az OAuth-login blokkolja. Komponens teszt-fedett
  (12/12), de pixel-verify hiányzik.
- **FS-VISUAL-B:** ValueBandSettingsPage edit/delete gombjai dead-UI (backend
  API kész, gomb-bekötés hiányzik) + frontend todayIso/tomorrowIso UTC vs
  szerver CET off-by-one (backend fail-closed, nem money-risk).
- **FE-FLAKY-SWEEP:** rendszerszintű frontend flaky-minta (`getByTestId` `await
  waitFor(mock)` után) — ~15 gyanús hely; külön verifikált PR, nem vak sed
  (per-file async/sync ítélet kell).
- **IDEM-KEYLEN + IDEM-CACHEHIT-AUDIT:** ✅ MEGOLDOVA (#1339) — de a
  BACKLOG.md-ben még 🏗️ státuszban lehet, frissítsd ✅-re.

## 6. HÁTRALEVŐ BACKLOG (FS-GAP program, D után)

A `BACKLOG.md` FS-GAP táblázata a mérvadó. Röviden:
- **FS-3 (D-szelet):** 🏗️ IMPLEMENTÁLVA, pending review/merge (l. fent).
- **FS-5:** okmány elő/hátlap + engedélyezett nagyítás (törvényi).
- **FS-7:** 10M jövedelemforrás-doksi workflow (scan→email→azonnali törlés).
- **FS-9:** címletképek (center→pénztár szinkron).
- **FS-10:** compliance-kérdések ügyfélhez (center→pénztáros→válasz sync).
- **FS-11:** szűrő-sablonok + keresés-audit (PDF).
- **FS-12:** gyanús-ügyfél dashboard-szűrők (multi-branch minta!).
- **FS-14:** kamera ellenőri workflow (2 kamera, időpont-jelölés, "átnézve").
- **FS-15:** .imp Raiffeisen napi export (recon: mi van már a Darius/BankApi-ban).
- **KIHAGYVA:** Keycloak SSO (saját JWT+Google marad).

Mindegyik teljes pipeline-on megy: Fable-5 HIGH terv → gpt-5.5 coder → GLM-5.2
(+SecOps) review → DeepSeek aspect → holdout → PR → CI → merge → deploy →
both-origin check. A szeleteket SORRENDENKÉNT, a megelőző szelet merge-je UTÁN
indítsd a következő plannerét (az A↔B küszöb-ütközés mintája miatt: ha két
szelet közös config/threshold-forrást használ, a későbbi csak a korábbi merge
után tervezendő).

## 7. KEY FACTS egy fresh sessionnek

- **Pipeline-modellek:** orchestrator=Opus-4.8 high; planner=Fable-5 HIGH
  (dedicated `planner` profil, `hermes -p planner chat`); coder=gpt-5.5
  (`--provider openai-api`); reviewer=GLM-5.2 (`--provider openrouter`,
  **reasoning high** — a `z-ai/` prefix patch a run_agent.py-ban MINDEN pull
  után újra-applikálandó, lásd hermes-update-maintenance skill).
- **Merge convention:** `glm-5.2-review` commit-status stamp + admin-squash-merge.
- **Backlog:** `.hermes/dev-loop/BACKLOG.md` (élő commitment-queue, 🔜→🏗️→✅).
- **Planes/holdout-ok:** `.hermes/plans/2026-07-06-fs-*.md` (+ `-holdout.md`).
- **Prod HA ops:** `dev-loop/references/prod-ha-ops.md` — Scaleway CSAK GitHub
  Actions SSH-val; standby HOT (standdown nem steady-state); both-origin check
  a deploy-job logból (Scaleway direct curl üres dev-gépről, az NEM leállás).
- **Release-chain:** `dev-loop/references/release-chain.md` — 11-utas bump,
  signed build (Azure Key Vault HSM + DigiCert EV), kötelező valós telepítés +
  vizuális ellenőrzés.
- **Pre-flight:** minden provider kredit-check pipeline-indításkor
  (`hermes auth list` + 1-tokenes próba mind a 4 szerepre); 402 után
  `hermes auth reset`.
- **Anthropic kiesés (EZ a session):** ha az Anthropic provider nem elérhető,
  a pipeline NEM futtatható minőségileg (Opus orchestrátor + Fable planner
  hiányzik). Várni kell a visszatérésre; NE próbálj meg AGY-megoldásként
  GLM-5.2-vel orkesztrálni + review-zni (ugyanaz a modell = önkéntes
  vakfolt-korreláció, a minőségi szabvány feladása).

## 8. Ma módosított SKILL-ek / kontroll-fájlok (nem rész a kódnak, de tartós)

- **SOUL.md:** új "WHO YOU ARE — core identity" szekció (nagyon tapasztalt,
  önálló, okos programozó ügynök; legtökéletesebb kód; magas minőségi
  elvárás a csapattól). Teljes Hermes-restart kell az élesedéshez.
- **dev-loop/references/reviewer-charter.md:** SecOps review-diszciplína
  beépítve — a biztonság ELSŐDLEGES review-tengely minden review-nál
  (tenant-izoláció/IDOR, authz/mass-assignment, money-path fail-closed,
  injection, secrets/PII, XSS, Electron-IPC, supply-chain). A külön DeepSeek
  aspect a 2. háló, nem kiváltó.
- **release-chain.md + prod-ha-ops.md:** both-origin freshness check +
  hot-standby mandate + probe-method (Scaleway job-log a mérvadó, nem a
  direct curl).
- **Memória konszolidálva:** 98%→63% — a részletes prod/HA/env pitfall-ok
  átkerültek a megfelelő skillekbe (windows-terminal-bash-fix,
  hermes-update-maintenance, hermes-multiprovider-config, dev-loop references),
  a memóriában csak magas szintű pointerek maradtak.
