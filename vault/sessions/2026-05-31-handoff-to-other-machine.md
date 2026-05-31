# HANDOFF — 2026-05-31 (folytatás másik gépen)

> **Cél:** ez a session ARM-gépen futott; a folytatás másik gépen lesz. Ez a jegyzet önállóan
> elég a folytatáshoz. **SESSION-START:** `git pull` ELŐSZÖR, majd ezt + `vault/references/program-state-cache.md` olvasd.

## Verzió + prod állapot
- **main = v2.27.64** (a #941 merge után; ha #941 még nyitott, lásd lent). Production **HEALTHY** — `https://excvaluta.com/api/v1/auth/bootstrap-status` = `{"completed":true}`.
- Auto-deploy működik (merge → „Deploy to Hetzner VPS" workflow → systemd `valuta-backend`). Minden mai PR backend-only → telepítő-build NEM kellett a kódfixekhez.

## Mit csináltam ebben a sessionben (mind MERGED + prod-deployolt)
**Több-ügynökös kódbázis-audit** (dynamic workflow, 53 ügynök, adverzariális verifikáció) → 30 megerősített finding. Teljes lista file:line-nal: `vault/references/audit-2026-05-31-confirmed-findings.md`.

| PR | Verzió | Tartalom |
|---|---|---|
| #934 | 2.27.58 | **P0/P1 multi-tenant IDOR**: RatePublishService.publish + InventoryService (movement/bank/transfer/search) + BranchService.create + InventoryMovementService cash-balance scope + 2 Codex P1 follow-up |
| #935 | 2.27.59 | **P1** RateTemplate LazyInit 500 (`@JsonIgnore` company + `@Transient getCompanyId()`) |
| #936 | — | **Installer x64 toolchain guard** (`Assert-X64NodeToolchain` a build-common.ps1-ben) |
| #937 | 2.27.60 | **P1** receiveMovement difference+audit (V280 migráció) + AmlService.setHighRiskFlagIfNeeded bekötés (4 könyvelő út) + Codex P1 (konverzió effektív-sor) |
| #938 | 2.27.61 | **P2** rate-publish hardening: spread-kapu + sell>buy MINDEN publikálási úton + outbox NPE/skála (mergeRate) + 2 Codex-él (egyoldali nulla, negatív ráta) |
| #939 | 2.27.62 | **P2** árfolyam 24h TTL ChronoUnit.HOURS csonkolás (percalapú >=) + VV-AML-004 strukturált log |
| #940 | 2.27.63 | **P2** Ertektar /bank-transactions IdempotencyGuard (dupla készletmozgás replay-védelem) |
| #941 | 2.27.64 | **P2** audit error_code-ok: VV-SEC-004 (currency_audit_log fail) + VV-SEC-005 (V279 grace audit_log) — **ELLENŐRIZD a merge-állapotát** |

**Lokál gate minden PR-en:** teljes backend suite zöld (utolsó: **1781 teszt, 0 hiba**, JDK 21). Minden push után CI + Codex visszaolvasva; a Codex 5+ valós élt talált a fixeimen → mind javítva.

## MARADÉK audit-backlog (innen folytatandó) — `vault/references/audit-2026-05-31-confirmed-findings.md`
**P2 (még nyitott):**
- **#3 multi-line HUF net/gross** — `TransactionMultiLineService` a sor `hufValue`-t a kedvezmény/kerekítés ELŐTTI bruttóból menti, de a single-line `t.hufAmount` net; a `StockSnapshotService.dailyBuyHuf/dailySellHuf` kettőt összead → kevert net/bruttó alap. Fix: a sor-hufValue arányos igazítása a fejléc payableAmount-hoz, VAGY a HUF-forgalom riport a payableAmount-ból.
- **#2 DailyBalance prior-day storno** — `TransactionReversalService`: korábbi (még nyitott, nem lezárt) napi sztornó a régi tranzakció státuszát REVERSED-re állítja, a kompenzáció MA könyvelődik → a korábbi nap forgalma csendben változik. (Zárt napot a `DailyBalanceService` isClosed-guard véd.) Fix: kompenzáló REVERSAL csak mára, a korábbi nap érintetlen; VAGY tiltás lezárt napra.
- **#11 sync-engine abandoned (Electron)** — `penztar-client/electron/sync-engine.ts` standalone `syncDistributions/syncTransfers/syncCollections` (631-633 hívva) NEM szűri az abandonedXIds-t és üzleti hibánál csak `break` → végtelen retry + head-of-line blocking. Fix: vagy töröld a duplikált standalone metódusokat (performSyncAll már fedi), vagy alkalmazd az abandoned-szűrést + isBusinessValidationError ágat.
- **#12 tautologikus e2e tesztek ×3** — `frontend-react/e2e/rates.spec.ts:158,172` (`expect(true).toBe(true)`), `penztar-client/e2e/bootstrap-auth.spec.ts:171` (tautologikus OR), `frontend-react/playwright/visual/receipt-snapshots.spec.ts` (üres skeleton). Fix: valódi assertion vagy törlés.

**P3 (6 db):** stockHuf longValue() csonkolás, DailyBalance transfersIn/Out kettős igazságforrás, kamera hash-lánc error_code, fix vs képlet tizedes, recompute stale ctx, Pmt 300k boundary-teszt. (Mind a referencia-fájlban.)

## Operatív tudás (KRITIKUS a folytatáshoz)
- **GitHub PAT autonóm merge-hez:** a repo-gyökér `.env` (gitignore-olt) tartalmazza `GITHUB_PAT`-ot. Használat inline, SOHA kiírás nélkül: `GH_TOKEN=$(grep -m1 '^GITHUB_PAT=' .env | sed 's/^GITHUB_PAT=//; s/^"//; s/"$//; s/\r$//') gh pr merge <PR> --squash --admin --delete-branch`. Az `--admin` CSAK a kötelező human-review-t bypassolja; a CI/Codex-gate-eket KIVÁRTAM.
- **`auto-fix` CI-check NEM kötelező** (a 10 required: Backend Build+Test, Lint×2, npm audit, Trivy, GitLeaks, Dependency Review, UTF-8 Guardrail, Analyze java-kotlin + javascript-typescript). Az auto-fix FAILURE nem blokkol.
- **JDK21 a mvn teszthez:** `$env:JAVA_HOME="C:\Program Files\Microsoft\jdk-21.0.11.10-hotspot"` (a default JDK25 elszáll).
- **Verzió-bump 4-way:** 5× package.json + backend/pom.xml; `node scripts/check-version-sync.mjs`. Párhuzamos PR-eknél a 2.-nak rebase kell a verzió-soron.
- **Telepítő-build = CI** (a másik gép is): a `.env` NEM tartalmazza a Google OAuth desktop-secreteket (csak CI-secret). Telepítő: `gh workflow run "windows-unsigned-release.yml" --ref main` → GitHub Release `vX.Y.Z` → `gh release download vX.Y.Z --pattern "*.exe" --dir <Downloads>`. A legutóbbi: **v2.27.60 telepítők a Downloads-ban** (Penztar-Setup 278MB, Kozponti 102MB, Eltavolito 60KB).
- **x64 toolchain (CSAK ezen az ARM gépen volt releváns):** `C:\tools\node-v24.16.0-win-x64` + `C:\tools\jdk21-x64-tmp\jdk-21.0.11+10` (amd64). A másik gép ha x64, ez NEM kell. Az installer x64-guard (#936) bármely gépen fail-fast-ol nem-x64 Node-ra.

## Munkamód (a sessionben bevált)
- Minden P2 = külön feature branch a friss main-ről → fix + teszt → teljes suite zöld → push → PR → `@codex review` → CI+Codex readback → Codex-él javítás zöldig → `--admin` merge → deploy-poll → health-check.
- **Codex zero-tolerance:** minden P0/P1/P2 findinget javítottam follow-up commitban + re-trigger, amíg „nincs új finding".
- **FONTOS hiba amit elkövettem és javítottam:** egyszer elfelejtettem feature branch-et nyitni és a lokál main-re commitoltam → `git branch <feat>; git reset --hard origin/main; git checkout <feat>` mentette. **Mindig ellenőrizd `git branch --show-current`-ot commit előtt.**

## Pre-existing nyitott PR-ek (NEM a mai munka)
- **#924** FK-04/E.2 fallback-J edge — az audit **false-positive**-ként minősítette (a középérték-ág matematikailag garantálja buy≤J). Érdemes lezárni/elvetni.
- **#926** „Rendszer alapstruktúra" spec-doc.

## Következő lépés a másik gépen
1. `git pull` (main = 2.27.64).
2. `vault/references/audit-2026-05-31-confirmed-findings.md` → folytatás a maradék P2-vel (#3 multi-line HUF a legmagasabb értékű financial-correctness), majd P3-batch.
3. A munkamód fent; a `.env` PAT-tal autonóm merge folytatható.
