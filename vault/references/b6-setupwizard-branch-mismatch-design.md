---
title: B6 SetupWizard branch-mismatch — security-aware design proposal
status: design
created: 2026-04-30
type: design-doc
---

# B6 SetupWizard branch-mismatch — security-aware design

## Probléma (audit)

> "B6. Branch-mismatch: SetupWizard választás IGNORE-olva
> Tünet: Wizard BR035 (Szeged Tisza Sarok), DE tranzakció-prefix V017 (BR017),
> header 'Központi', Pénztár 101"

A pénztár-kliens SetupWizard-ban a felhasználó kiválasztja a fiókot (pl. BR035). A backend tranzakció rögzítéskor azonban a `worker.branchId`-t (pl. BR017, ahova a worker fixen van rendelve) használja a tx.branchId-nek, NEM a wizard választást. Eredmény:
- bizonylat-szám prefix: V017... (a worker branch-éje)
- header: BR017 (a worker branch-éje)
- a wizard-választás csak UI-szinten van, nincs üzleti hatása

## Üzleti kontextus

A multi-branch worker-ek (pl. Best Change Zrt. Cashier-supervisor szerep) több fiókban dolgoznak naponta. Egy worker bejelentkezik a kihelyezett kioszk-on, a kioszk a fiókot a SetupWizard-ban tartja (lokális SQLite config). A worker JWT a `worker.branchId`-t hordozza.

## Security-sensitive kérdés

A frontend NEM tudja egyoldalúan átállítani a backend-szintű branch-et, mert akkor egy worker a saját JWT-jével **bárhol szabadon dolgozhatna**, ami **multi-tenant tenant isolation breach** lenne (cross-branch transaction injection).

## Industry pattern (javaslat)

### 1. Backend: `worker_branch_access` table

Új M:N kapcsolat: worker × branch, "ALLOWED" rekordokkal.

```sql
CREATE TABLE worker_branch_access (
  worker_id BIGINT REFERENCES worker(id),
  branch_id UUID REFERENCES branch(id),
  granted_at TIMESTAMP DEFAULT NOW(),
  granted_by_worker_id BIGINT REFERENCES worker(id),
  PRIMARY KEY (worker_id, branch_id)
);
```

A `worker.branchId` (default branch) megmarad backward-compat-ből. A `worker_branch_access` az engedélyezett branch-listát tartja.

### 2. Backend: JWT optional `branchOverride` claim

A login response-ban + a JWT-ben opcionálisan szerepel `branchOverride: UUID` (a SetupWizard választása). Ha jelen van, a backend validálja:

```java
public UUID resolveTransactionBranch(WorkerAuthenticationDetails auth) {
    UUID overrideBranch = auth.getBranchOverride();
    if (overrideBranch != null) {
        // Verify worker has access to override branch (multi-tenant safety)
        if (!workerBranchAccessRepository.existsByWorkerIdAndBranchId(
                auth.getWorkerId(), overrideBranch)) {
            log.warn("[BRANCH_GUARD] worker {} attempted unauthorized branch override to {}",
                    auth.getWorkerId(), overrideBranch);
            throw new SecurityException("Branch access denied: " + overrideBranch);
        }
        return overrideBranch;
    }
    return auth.getDefaultBranchId(); // worker.branchId fallback
}
```

### 3. Frontend: SetupWizard → branch-override flow

- Wizard kiválasztáskor: `auth.setBranchOverride(branchId)` lokál
- Login flow: a frontend a SetupWizard branch-et JWT request-ben átadja
- Backend visszaadja a JWT-t `branchOverride` claim-mel (csak ha worker_branch_access engedélyezi)
- Minden tx-recorder a `resolveTransactionBranch()`-et hívja, NEM közvetlenül `auth.getBranchId()`-t

### 4. Audit trail

- WORKER_BRANCH_ACCESS_GRANTED / REVOKED — ki, mikor, milyen branch-re
- `[BRANCH_GUARD] worker X attempted unauthorized branch override to Y` — WARN log

## Migrációs út

1. **v2.4 sprint** new feature (NEM patch — ARCHITECTURE CHANGE):
   - Flyway: `worker_branch_access` table + seed worker-default-branch (1 worker → 1 branch initial)
   - Backend: `WorkerBranchAccessService` + JWT `branchOverride` claim
   - Frontend: SetupWizard → login.branchOverride field
   - Tests: cross-branch tx without access → REJECT
2. **Backward compat**: meglévő tranzakciók NEM érintettek (ddl `worker_branch_access` opcionális — branchOverride NULL eseten worker.branchId fallback)

## Felhasználói review szükséges

Ez egy **architecture change**, NEM patch. Felhasznáoi mandate:

- Engedélyezi-e a multi-branch worker pattern-t (HR/business policy)?
- Ki adminisztrálja a `worker_branch_access` rekordokat (admin UI)?
- A meglévő SetupWizard-választás backward-compat-ben legyen (ignore-olva, ahogy most), vagy a v2.4 deploy után automatikusan migráljon (worker_branch_access seed minden meglévő wizard-pár-ra)?

## Status

- ❌ NEM auto-fix v2.3.X-ben (security-sensitive, breaking change)
- 📋 Design doc kész, várja user review-ot
- 🔄 Defer to v2.4 sprint planning

## Related audit-bug

- B6 (this) — frontend wizard branch ignored
- B24 — sync-status BR035 ragad ("Függőben") — same root cause: cross-branch tx not accepted
- Both fix ugyanez az architecture change

## References

- OWASP A01 Broken Access Control — multi-branch tenant isolation
- Spring Security JWT custom claims pattern
- OAuth 2.0 RFC 9068 (JWT Profile for OAuth 2.0 Access Tokens) — optional claim conventions
- Hungarian banking compliance: each transaction must have **legitimate** branch attribution (not arbitrary worker preference)
