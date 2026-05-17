# B.3 — Multi-tenant izoláció mandate

**Hatály:** always, P0
**Forrás:** `claude-code-korrekcios-mandate-2026-05-17.md` 1.3 szakasz

## 3 alapszabály

1. **Cross-tenant integration test** minden új repository / service / controller esetén. 2 különböző `companyId`-val futtatott szcenárió: a B cég dolgozója NEM láthatja az A cég adatait.
2. **`@PreAuthorize` minden endpoint-on.** PR-review-ban explicit ellenőrizendő, hogy a worker `companyId`-ja a query-be be van injektálva.
3. **`SecurityContextHolder`-ból olvasott `companyId`** — soha NEM a kliens által küldött `companyId` paraméterből (akkor lenne IDOR vulnerability).

## Implementációs pattern

> **Megjegyzés (2026-05-17 audit):** A backend-ben a `companyId` típusa **`UUID`**, NEM `Long`. A `SecurityUtils.getCurrentCompanyId()` `UUID`-ot ad vissza. A példa-kód ennek megfelelően:

```java
@Service
public class TransactionService {
    public List<Transaction> findAll() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();  // SecurityContextHolder
        return transactionRepository.findByCompanyId(companyId);
    }
}

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, UUID> {
    List<Transaction> findByCompanyId(UUID companyId);  // EVERY query has it
}
```

## CI guard (TERVEZETT, business-invariant-guard.yml v2 PR-ben)

A `business-invariant-guard.yml` workflow még NEM létezik — a v2 mandate PR-ben (`claude-code-valutavalto-korrekcios-mandate-2026-05-17-v2.md`) készül el. Tervezett bash (helyes glob-pattern-nel):

```bash
# Minden repository-fájlban legalább 1 'companyId' / 'company_id' találat kötelező
find backend/src/main/java -name '*Repository.java' -print0 \
  | xargs -0 -I {} sh -c 'grep -q "companyId\|company_id" "{}" || { echo "::error::Multi-tenant guard sérül: {}"; exit 1; }'
```

## 9-fázisú zárási protokoll 2. lépésében

Lokális minőségkapunál explicit fut:
```bash
./mvnw -q test -Dtest='*MultiTenantTest,*CrossTenantTest,*TenantIsolationTest'
```

Piros → P0, nem lehet továbblépni.

## Tipikus hiba-minták

- ❌ `request.getCompanyId()` — kliens-controlled → IDOR
- ❌ `@GetMapping("/companies/{id}/...")` companyId @PreAuthorize nélkül
- ❌ JOIN-query company_id WHERE clause nélkül
- ❌ `findAll()` repository call companyId szűrés nélkül
