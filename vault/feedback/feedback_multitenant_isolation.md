# B.3 — Multi-tenant izoláció mandate

**Hatály:** always, P0
**Forrás:** `claude-code-korrekcios-mandate-2026-05-17.md` 1.3 szakasz

## 3 alapszabály

1. **Cross-tenant integration test** minden új repository / service / controller esetén. 2 különböző `companyId`-val futtatott szcenárió: a B cég dolgozója NEM láthatja az A cég adatait.
2. **`@PreAuthorize` minden endpoint-on.** PR-review-ban explicit ellenőrizendő, hogy a worker `companyId`-ja a query-be be van injektálva.
3. **`SecurityContextHolder`-ból olvasott `companyId`** — soha NEM a kliens által küldött `companyId` paraméterből (akkor lenne IDOR vulnerability).

## Implementációs pattern

```java
@Service
public class TransactionService {
    public List<Transaction> findAll() {
        Long companyId = SecurityUtils.getCurrentCompanyId();  // SecurityContextHolder
        return transactionRepository.findByCompanyId(companyId);
    }
}

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, Long> {
    List<Transaction> findByCompanyId(Long companyId);  // EVERY query has it
}
```

## CI guard

A `business-invariant-guard.yml` workflow ellenőrzi:
```bash
grep -rn 'company_id\|companyId' src/main/java/.*Repository.java
# Minden repository-fájlban legalább 1 találat kötelező
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
