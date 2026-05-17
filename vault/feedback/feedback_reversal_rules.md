# B.6 — Sztornó szabály invariáns mandate

**Hatály:** always, P0
**Forrás:** `claude-code-korrekcios-mandate-2026-05-17.md` 1.6 szakasz

## 5 alapszabály

1. **Csak ugyanazon a napon** — `transaction.createdAt::date = today()`.
2. **Csak ugyanazzal a worker-rel** — `transaction.workerId = currentWorker.id` (vagy SUPERVISOR_PIN override).
3. **Csak napzárás ELŐTT** — `dailyClosing.status != 'CLOSED'`.
4. **Bizonylat-sorszám megmarad** — audit trail integritás. NEM felülírható, NEM törölhető.
5. **Készlet visszaáll** atomikusan, `SUM(tranzakciók)` invariáns alapján (B.2 hivatkozás).

## Implementációs hivatkozás (illusztratív)

> **Megjegyzés:** Az alábbi Java-kód illusztráció — a `findByIdAndCompanyId` metódus jelen állapotban NEM létezik a `TransactionRepository`-ban. Hasonló metódus pl. `findByReceiptNumberAndCompanyId`. A valós implementáció a meglévő repository-metódusokat használja vagy újat ad hozzá. A `companyId` típusa `UUID`, NEM `Long`.

```java
// ReversalService.java (illusztratív minta, NEM kanonikus)
@Transactional
public Transaction reverse(UUID txId, UUID currentWorkerId, String reason) {
    Transaction original = transactionRepository.findById(txId)
        .filter(t -> t.getCompanyId().equals(SecurityUtils.getCurrentCompanyId()))
        .orElseThrow();

    // Rule 1: same day
    if (!original.getCreatedAt().toLocalDate().equals(LocalDate.now())) {
        throw new ValidationException("Sztornó csak aznapi tranzakcióra lehet");
    }
    // Rule 2: same worker (or SUPERVISOR override)
    if (!original.getWorkerId().equals(currentWorkerId) && !hasSupervisorPin()) {
        throw new ValidationException("Sztornó csak saját tranzakcióra (vagy SUPERVISOR_PIN)");
    }
    // Rule 3: before daily closing
    if (dailyClosingService.isClosed(getCurrentBranchId(), LocalDate.now())) {
        throw new ValidationException("Napzárás után már nem lehet sztornózni");
    }
    // Rule 4: preserve receipt number — NEM felülírjuk, csak status = REVERSED
    original.setStatus(TransactionStatus.REVERSED);
    original.setReversalReason(reason);
    // Rule 5: inventory recomputes from SUM (no explicit counter update)
    return transactionRepository.save(original);
}
```

## Negatív regressziós tesztek

```
backend/.../ReversalServiceTest.java
  - testReverse_DifferentDay_throws()
  - testReverse_DifferentWorker_throws()
  - testReverse_AfterClosing_throws()
  - testReverse_PreservesReceiptNumber()
  - testReverse_InventoryRecomputes()
```

## PR-template checklist

- [ ] Nem lazítok semelyik az 5 sztornó szabályon
- [ ] `ReversalServiceTest` 5 negatív teszte futott + zöld
- [ ] Új sztornó-flow esetén audit-log immutable
