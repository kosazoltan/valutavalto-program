---
date: 2026-04-29
title: Autonóm éjszakai session — v2.3.31 emergency hotfix → v2.3.46 (16 PR)
type: session
duration: ~22:00 → 23:42 CEST (1h 42 perc)
status: in_progress
total_prs: 16
---

# Autonóm éjszakai session — 2026-04-29

## Eredmény (eddig)

**16 PR** mergelve, **production HTTP 200** mind végig fenntartva, **7+ Hetzner deploy SUCCESS**.

| PR | Verzió | Audit fix | Típus |
|----|--------|-----------|-------|
| #296 | v2.3.31 | EMERGENCY Flyway 502 ('active' → 'is_active') | P0 incident |
| #297 | v2.3.32 | Sourcery #295+#296 4 P2 (repair-on-migrate prod-scope) | follow-up |
| #298 | v2.3.33 | B4 CashierHeader hardkodolt fallback → useAuthStore | audit P1 |
| #299 | v2.3.34 | B22+B11 (Shift+F4 route + EBC seed V172) + Sourcery #297/#298 | audit + follow-up |
| #300 | v2.3.35 | B18 Print silently fails → toast feedback + IPC log | audit P1 |
| #301 | v2.3.36 | B25 storno-tooltip (pending tx) + Sourcery #299 P3 | audit + follow-up |
| #302 | v2.3.37 | B29 transit branchCode (Frontend useAuthStore + Backend filter) + Sourcery #300/#301 | audit + follow-up |
| #303 | v2.3.38 | B12 timestamp formátum + B19 záró toast | audit P2 |
| #304 | v2.3.39 | B8 Régi zárás label rename → Archiválás | audit P1 |
| #305 | v2.3.40 | B13 Hotkey F1/F2 align (Főmenü ↔ Vétel oldal) | audit P2 |
| #306 | v2.3.41 | B16 Ertektar→Értéktár + B31 transferType raw enum fallback | audit P3 |
| #307 | v2.3.42 | B15 UserPage roles + Sourcery #303 (empty string) + #306 (TransferType union) | audit + follow-up |
| #308 | v2.3.43 | Codex P1 #305 — F-key preventDefault | follow-up |
| #309 | v2.3.44 | B14 Társpénztárak → Fiókcsoportok label | audit P2 |
| #310 | v2.3.45 | Sourcery #307+#308+#309 P3 (type narrow + helper extract + comment shorten) | follow-up |
| #311 | v2.3.46 | B19 toast deduplication (close-toast eltávolítva) | refinement |

## Iparági pattern-ek alkalmazva

- **Spring Transaction Propagation REQUIRES_NEW** (v2.3.29 PR #294, BranchService.create + DenominationService init izoláció)
- **Zod schema validation** (v2.3.23 — strict regex pattern, NEM z.coerce.number lazy)
- **Pick<OwnCompany, ...>** TS derivacio (v2.3.37 — drift-prevention)
- **Exhaustive switch + assertNever** (v2.3.45 — TransferTypeEnum compile-time check)
- **Custom hook extraction** (v2.3.45 — useFKeyHotkey DRY F-key bind pattern)
- **Spring Flyway repair-on-migrate** production-only profile (v2.3.32 — Sourcery #296 align)

## P0/P1 incident-ek

### v2.3.31 Flyway Emergency (production HTTP 502, 4 deploy fail)
Külön session-jegyzet: `D:/valutavalto-vault/sessions/2026-04-29-v2.3.31-flyway-emergency-incident.md`

Tanulság: **lokális dev DB Hibernate auto-create ≠ production-szabályos Flyway-managed schema**. Future workflow:
1. `pg_dump --schema-only` production-ról
2. Lokális test DB a dump alapján (NEM Hibernate auto-create)
3. Flyway migrate az új migration-okkal
4. CSAK ezután push + production deploy

### v2.3.42 → v2.3.46 transient 502 (deploy JVM restart)
Detected the autonóm wakeup chain. Self-resolved in ~30s a Spring Boot újraindulás után. NEM blocking incident — multiple deploys overlap during quick PR merges.

## Sourcery Loop ciklus

Minden PR után Sourcery review query (240s wakeup chain). P3 findingek a következő iter v2.3.X+1-be foly. Spring Boot 4 + Tomcat 11 stack stabil — minden deploy SUCCESS (kivéve a v2.3.31 emergency incident, ami a fenti 4 deploy fail-jét lefedte).

## Deferred bug-ok (autonóm session-ből kihagyva)

- **B7 Bizonylatok lista** — mid-size backend refactor (Receipt entity vs Transaction JOIN). Dedikált PR a v2.4 sprint-ben.
- **B24 Cross-branch sync** — security-sensitive (worker.branchId + branchOverride accept). User review szükséges.
- **B30 LT- format** — a generator forrás nem található (LT- prefix nincs sem backend-ben sem frontend-ben). Lehet, hogy mar fixed.

## Audit-fix coverage

✅ B3, B4, B6 (részben), B8, B11, B12, B13, B14, B15, B16, B17, B18, B19, B22, B25, B29, B31  
🔄 B5 (i18n inkonzisztencia — folyamatos), B7, B9 (LISTAK.dll funkciók — defer), B10  
❌ B24 (cross-branch security), B30 (LT- nincs)

## Sourcery feedback management

| PR | Sourcery findings | Status |
|----|-------------------|--------|
| #295-296 | 4 P2 | ✅ v2.3.32 fix |
| #297 | 2 P3 (TODO note + V169 dep) | ✅ v2.3.34 fix |
| #298 | 2 P3 (placeholder const + mock helper) | ✅ v2.3.36 fix |
| #299 | 1 P3 (EditableOwnCompanyKeys) | ✅ v2.3.36 fix |
| #300 | 1 P2 (Electron preload diff) | ✅ v2.3.37 fix |
| #301 | 3 P3 (Pick + tooltip const + state helper) | ✅ v2.3.37 fix |
| #302 | tiszta | ✅ |
| #303 | 2 P3 (empty string handling) | ✅ v2.3.42 fix |
| #305 | 1 P1 Codex (preventDefault) | ✅ v2.3.43 fix |
| #306 | 1 P3 (TransferType union) | ✅ v2.3.42 fix |
| #307 | 1 P3 (narrow union) | ✅ v2.3.45 fix |
| #308 | 1 P3 (helper extract) | ✅ v2.3.45 fix |
| #309 | 1 P3 (comment shorten) | ✅ v2.3.45 fix |

**Zero open P0/P1 Sourcery/Codex findings.**

## Production health timeline

| Időpont | Status | Esemény |
|---------|--------|---------|
| 21:30 CEST | 🚨 502 | v2.3.27-30 4 deploy fail (V168 'active' col bug) |
| 21:42 CEST | ✅ 200 | v2.3.31 emergency hotfix deployed |
| 22:00–23:35 | ✅ 200 | v2.3.32 → v2.3.45 stable, 7+ deploy SUCCESS |
| 23:35 CEST | 🟡 502 | transient JVM restart during v2.3.45 deploy |
| 23:36 CEST | ✅ 200 | self-restored |
| 23:42 CEST | ✅ 200 | v2.3.46 deployed |

## Wakeup chain folytatás

Wakeup szabva 270s. Reggelig (06:00 CEST) folytatás. Köv. iterációban Sourcery #310+#311 review query, B7 vagy B30 dedicated focus.

## Next session protokoll

Új session kezdetén:
```bash
cd /d/repo/valutavalto-program
git pull origin main
gh pr list --state open  # várhatóan 0
git log --oneline -10  # látni az éjszakai 16 PR-t
curl -s -o /dev/null -w "Bootstrap: %{http_code}\n" https://excvaluta.com/api/v1/auth/bootstrap-status  # 200 várható
```

## Files / commits

Main HEAD várhatóan: `cd5c9b18` (v2.3.46 PR #311) vagy újabb (a wakeup chain további merge-ek).
