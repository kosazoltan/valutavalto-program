# Reservation Fulfill Implementation Plan
> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix four bugs in `ReservationService`: (1) `fulfillReservation()` only changes status but never hands out the currency from cash balance; (2) `getReservedStock()` uses a non-currency-specific active count; (3) `autoExpireReservations()` has no idempotency check; (4) add a `@Scheduled` pre-expiry warning notification 1 day before deadline.

**Architecture:** `fulfillReservation()` gains the same `addHufBalance` / `subtractBalance` calls that `createReservation()` already does in reverse. `getReservedStock()` gets the count fixed to a per-currency query. `autoExpireReservations()` gains an idempotency guard. A new `@Scheduled` method creates `Notification` entities 1 day before expiry.

**Tech Stack:** Java 21, Spring Boot 3.2, JPA, PostgreSQL, JUnit 5

---

## Context

- **ReservationService:** `backend/src/main/java/hu/puzzleir/valuta/service/ReservationService.java`
- **Reservation entity:** `backend/src/main/java/hu/puzzleir/valuta/entity/Reservation.java`
  - `status`: `ReservationStatus` enum (ACTIVE, FULFILLED, CANCELLED_BY_CUSTOMER, CANCELLED_BY_COMPANY, EXPIRED)
  - `reservedAmount`: BigDecimal — valuta mennyiség
  - `depositAmount`: BigDecimal — befizetett HUF letét
  - `currencyCode`: String
  - `expiresAt`: LocalDateTime
- **ReservationRepository:** `backend/src/main/java/hu/puzzleir/valuta/repository/ReservationRepository.java`
  - `findActiveByBranch(UUID branchId)` ✓
  - `findByStatusAndExpiresAtBefore(status, datetime)` ✓
  - `getReservedStockByBranch(branchId)` — returns `List<Object[]>` with `(currencyCode, totalAmount)` ✓
  - **BUG**: `countByBranchAndStatusAndCreatedAtBetween()` — counts ALL active reservations regardless of currency
- **CashBalanceRepository:** has `findByBranchIdAndCurrencyIdForUpdate()` with PESSIMISTIC_WRITE ✓
- **CashBalance entity:** has `addBalance()` and `subtractBalance()` helper methods ✓
- **Notification entity:** `backend/src/main/java/hu/puzzleir/valuta/entity/` — check if exists

### Bug details

#### Bug 1: fulfillReservation() does not move cash
`fulfillReservation()` (lines 185-224) sets status to FULFILLED and refundAmount = depositAmount — but NEVER:
- Deducts the reserved currency amount from the cash register (it was set aside at `createReservation()`)
- Adjusts the HUF balance (the deposit stays as-is, but the HUF cash that goes out for the exchange is not tracked)

The correct sequence for `_visszatipus=1` (legacy FOGLALO.DLL):
1. Currency: the reserved stock was already SUBTRACTED in createReservation → no change needed on fulfill (the valuta is "handed out" — it was already set aside)
2. HUF: The deposit (depositAmount) was ADDED to HUF balance in createReservation. On fulfillment, the deposit converts to the exchange value — effectively the customer pays the difference: `(reservedAmount × currentRate) − depositAmount`. This is complex: simplest correct model is: the deposit was payment, no further HUF movement needed on pure fulfillment.

**ACTUAL BUG (simpler):** The currency was subtracted from stock when the reservation was created. On fulfillment, the currency is physically handed to the customer — which is already reflected by the missing stock. What IS missing: the `fulfillReservation()` does not subtract the HUF that represents the REMAINING PAYMENT. In the legacy system, on fulfillment:
- ügyfél fizet: `reservedAmount × currentRate − depositAmount` HUF (a maradék rész)
- Ez kerül be a kasszába HUF-ként

For this plan: implement the missing HUF balance adjustment (add the remaining payment):
```
remainingPayment = reservedAmount × exchangeRate − depositAmount
hufBalance += remainingPayment  (ügyfél befizeti a maradék összeget)
```

#### Bug 2: getReservedStock() count is wrong
Line 424-426:
```java
long count = reservationRepository.countByBranchAndStatusAndCreatedAtBetween(
    branchId, ReservationStatus.ACTIVE,
    LocalDateTime.of(2000, 1, 1, 0, 0),
    LocalDateTime.now().plusYears(100));
```
This counts ALL ACTIVE reservations for the branch regardless of currency. The result is assigned to each currency row — so every currency gets the same (total) count.

#### Bug 3: autoExpireReservations() idempotency
If the scheduler runs twice in quick succession (race condition or manual trigger), the same reservation could be processed twice. The `setStatus(EXPIRED)` on the in-memory object protects only within the same loop run — a second concurrent call will re-fetch ACTIVE records from DB and process them again.

Fix: Re-check status inside the loop with a fresh DB fetch (or use `findByIdForUpdate`).

#### Bug 4: No pre-expiry warning
Reservations that expire tomorrow should trigger a Notification so the cashier can proactively contact the customer.

---

## Task 1: Fix fulfillReservation() — remaining payment HUF adjustment

- [ ] Edit: `backend/src/main/java/hu/puzzleir/valuta/service/ReservationService.java`

Replace the `fulfillReservation()` method body:

```java
public Reservation fulfillReservation(Long reservationId) {
    Long workerId = SecurityUtils.getCurrentWorkerId();
    UUID branchId = SecurityUtils.getCurrentBranchId();

    // PESSIMISTIC_WRITE lock — párhuzamos feldolgozás megakadályozása
    Reservation reservation = reservationRepository.findByIdForUpdate(reservationId)
        .orElseThrow(() -> new ResourceNotFoundException("Foglaló nem található: " + reservationId));
    validateActive(reservation);
    validateBranch(reservation, branchId);

    // 1. Maradék fizetés számítása
    //    Ügyfél a létrehozáskor letétet fizetett (depositAmount).
    //    Teljesítéskor befizeti a maradékot: reservedAmount × exchangeRate − depositAmount
    //    (5-re kerekítve, mint az eredeti letétnél)
    BigDecimal fullPrice = roundToFive(
        reservation.getReservedAmount()
            .multiply(reservation.getExchangeRate())
            .setScale(2, java.math.RoundingMode.HALF_UP));
    BigDecimal remainingPayment = fullPrice.subtract(reservation.getDepositAmount());

    // 2. Ha van maradék fizetés → HUF kassza növelés
    //    (lehet 0 vagy negatív ha az árfolyam csökkent — negatív esetben nincs visszafizetés,
    //     a letét változatlanul a kasszában marad)
    if (remainingPayment.compareTo(BigDecimal.ZERO) > 0) {
        addHufBalance(branchId, remainingPayment);
        log.debug("Foglaló teljesítés — maradék fizetés: {} HUF (full={}, letét={})",
            remainingPayment, fullPrice, reservation.getDepositAmount());
    }

    // 3. A valuta már le volt vonva a kasszából a createReservation()-ban → nincs teendő
    //    (reservedAmount a kasszából "foglalt" állapotban volt, most elhagyta az irodát)

    // 4. Státusz
    reservation.setStatus(ReservationStatus.FULFILLED);
    reservation.setFulfilledAt(LocalDateTime.now());
    reservation.setRefundAmount(reservation.getDepositAmount()); // letét = megtörtént fizetés

    reservation = reservationRepository.save(reservation);

    // AuditLog
    Worker worker = workerRepository.findById(workerId)
        .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található"));
    auditLogService.log(
        "RESERVATION_FULFILLED",
        "Reservation",
        reservation.getId().toString(),
        workerId.toString(),
        worker.getName(),
        branchId.toString(),
        reservation.getBranch().getName(),
        String.format("Foglaló teljesítve: %s %s @ %s, letét: %s HUF, maradék: %s HUF",
            reservation.getReservedAmount().toPlainString(),
            reservation.getCurrencyCode(),
            reservation.getExchangeRate().toPlainString(),
            reservation.getDepositAmount().toPlainString(),
            remainingPayment.toPlainString()),
        null, null
    );

    log.info("Foglaló teljesítve: id={}, {} {}, maradék fizetés: {} HUF",
        reservation.getId(), reservation.getReservedAmount(),
        reservation.getCurrencyCode(), remainingPayment);

    return reservation;
}
```

---

## Task 2: Fix getReservedStock() — currency-specific active count

- [ ] Add new query to `ReservationRepository.java`:

```java
/**
 * Aktív foglalók száma valutánként egy irodában.
 * Javítás: az eredeti countByBranchAndStatusAndCreatedAtBetween nem volt valuta-specifikus.
 */
@Query("SELECT COUNT(r) FROM Reservation r " +
       "WHERE r.branch.id = :branchId " +
       "AND r.status = 'ACTIVE' " +
       "AND r.currencyCode = :currencyCode")
long countActiveByCurrencyAndBranch(
    @Param("branchId") UUID branchId,
    @Param("currencyCode") String currencyCode);
```

- [ ] Edit `ReservationService.getReservedStock()` — replace the count call:

```java
@Transactional(readOnly = true)
public List<ReservedStockDto> getReservedStock(UUID branchId) {
    List<Object[]> rawData = reservationRepository.getReservedStockByBranch(branchId);
    List<ReservedStockDto> result = new ArrayList<>();

    for (Object[] row : rawData) {
        String code = (String) row[0];
        BigDecimal totalAmount = (BigDecimal) row[1];

        // FIX: valuta-specifikus count (nem az összes aktív foglaló)
        long count = reservationRepository.countActiveByCurrencyAndBranch(branchId, code);

        result.add(ReservedStockDto.builder()
            .currencyCode(code)
            .reservedAmount(totalAmount)
            .activeCount(count)
            .build());
    }

    return result;
}
```

---

## Task 3: Idempotency in autoExpireReservations()

- [ ] Edit `ReservationService.autoExpireReservations()` — add idempotency guard inside the loop:

```java
public int autoExpireReservations() {
    List<Reservation> candidates = reservationRepository.findByStatusAndExpiresAtBefore(
        ReservationStatus.ACTIVE, LocalDateTime.now());

    int count = 0;
    for (Reservation reservation : candidates) {
        try {
            // IDEMPOTENCY: Friss lock és státusz ellenőrzés — concurrent feldolgozás elleni védelem
            Reservation locked = reservationRepository.findByIdForUpdate(reservation.getId())
                .orElse(null);
            if (locked == null) {
                log.debug("Foglaló auto-expiry: nem található (már törölve?): id={}",
                    reservation.getId());
                continue;
            }
            // Ha közben már lezárult (másik thread által) → skip
            if (!ReservationStatus.ACTIVE.equals(locked.getStatus())) {
                log.debug("Foglaló auto-expiry: státusz már nem ACTIVE: id={}, status={}",
                    locked.getId(), locked.getStatus());
                continue;
            }
            // Double-check: most is lejárt-e?
            if (!locked.getExpiresAt().isBefore(LocalDateTime.now())) {
                log.debug("Foglaló auto-expiry: még nem járt le: id={}, lejárat={}",
                    locked.getId(), locked.getExpiresAt());
                continue;
            }

            locked.setStatus(ReservationStatus.EXPIRED);
            locked.setCancelledAt(LocalDateTime.now());
            locked.setRefundAmount(BigDecimal.ZERO);
            locked.setCancellationReason("Automatikus lejárat — határidő letelt");

            // Valuta visszavezetés
            restoreCurrencyStock(locked);

            reservationRepository.save(locked);

            auditLogService.log(
                "RESERVATION_AUTO_EXPIRED",
                "Reservation",
                locked.getId().toString(),
                "SYSTEM",
                "Automatikus lejárat",
                locked.getBranch().getId().toString(),
                locked.getBranch().getName(),
                String.format("Foglaló automatikusan lejárt: %s %s, letét: %s HUF → kezelési költség",
                    locked.getReservedAmount().toPlainString(),
                    locked.getCurrencyCode(),
                    locked.getDepositAmount().toPlainString()),
                null, null
            );

            log.info("Foglaló automatikusan lejárt: id={}, {} {}",
                locked.getId(), locked.getReservedAmount(), locked.getCurrencyCode());
            count++;
        } catch (Exception e) {
            log.error("Hiba a foglaló auto-expiry során: id={}, hiba: {}",
                reservation.getId(), e.getMessage(), e);
        }
    }

    if (count > 0) {
        log.info("Összesen {} foglaló automatikusan lejárt", count);
    }
    return count;
}
```

---

## Task 4: Pre-expiry warning @Scheduled notification

### 4a: Check/create Notification entity

- [ ] Check if `Notification` entity exists: `backend/src/main/java/hu/puzzleir/valuta/entity/Notification.java`
  - If it exists: use it
  - If it does NOT exist: create it (see below)

```java
// Create only if missing:
package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "notification", indexes = {
    @Index(name = "idx_notification_branch", columnList = "branch_id"),
    @Index(name = "idx_notification_read", columnList = "is_read"),
    @Index(name = "idx_notification_type", columnList = "notification_type")
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "branch_id")
    private UUID branchId;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @Column(name = "notification_type", nullable = false, length = 50)
    private String notificationType;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String message;

    /** Hivatkozott entitás típusa (pl. "Reservation") */
    @Column(name = "entity_type", length = 50)
    private String entityType;

    /** Hivatkozott entitás azonosítója */
    @Column(name = "entity_id", length = 100)
    private String entityId;

    @Column(name = "is_read")
    @Builder.Default
    private Boolean isRead = false;

    @Column(name = "read_at")
    private LocalDateTime readAt;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
```

If creating: also add Flyway migration V92:
```sql
-- V92: Notification table (if not exists from other migrations)
CREATE TABLE IF NOT EXISTS notification (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id         UUID,
    company_id        UUID NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    message           TEXT NOT NULL,
    entity_type       VARCHAR(50),
    entity_id         VARCHAR(100),
    is_read           BOOLEAN NOT NULL DEFAULT FALSE,
    read_at           TIMESTAMP,
    created_at        TIMESTAMP NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_notification_branch ON notification(branch_id);
CREATE INDEX IF NOT EXISTS idx_notification_read   ON notification(is_read) WHERE is_read = FALSE;
CREATE INDEX IF NOT EXISTS idx_notification_type   ON notification(notification_type);
```

### 4b: NotificationRepository

- [ ] Create (if not existing): `backend/src/main/java/hu/puzzleir/valuta/repository/NotificationRepository.java`

```java
package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, UUID> {

    List<Notification> findByBranchIdAndIsReadFalseOrderByCreatedAtDesc(UUID branchId);

    @Query("SELECT COUNT(n) FROM Notification n WHERE n.branchId = :branchId AND n.isRead = false")
    long countUnreadByBranch(@Param("branchId") UUID branchId);

    /** Ellenőrzés: van-e már ilyen típusú értesítés az entitáshoz (idempotency) */
    boolean existsByEntityTypeAndEntityIdAndNotificationType(
        String entityType, String entityId, String notificationType);
}
```

### 4c: Pre-expiry @Scheduled in ReservationService

- [ ] Edit `ReservationService.java` — add:
  - Import `org.springframework.scheduling.annotation.Scheduled`
  - Inject `NotificationRepository notificationRepository`

```java
/**
 * Foglaló lejárat előtti figyelmeztetés (1 nappal előre).
 *
 * Minden 30 percben fut. Azokat a foglalókat keresi, amelyek 24 óra múlva lejárnak,
 * és értesítést küld a pénztárosnak, hogy proaktívan vegye fel a kapcsolatot az ügyféllel.
 *
 * Idempotens: csak egyszer hoz létre értesítést foglalónként.
 */
@Scheduled(fixedDelay = 30 * 60 * 1000)  // 30 percenként
@org.springframework.transaction.annotation.Transactional
public void sendPreExpiryWarnings() {
    LocalDateTime now = LocalDateTime.now();
    LocalDateTime warningFrom = now;
    LocalDateTime warningTo = now.plusHours(24);

    // Foglalók amelyek 0-24 óra múlva járnak le és még ACTIVE
    List<Reservation> expiringSoon = reservationRepository
        .findActiveExpiringBetween(warningFrom, warningTo);

    int notified = 0;
    for (Reservation reservation : expiringSoon) {
        String entityId = reservation.getId().toString();
        // Idempotency: ne küldjünk ismételt értesítést ugyanahhoz a foglalóhoz
        boolean alreadyNotified = notificationRepository
            .existsByEntityTypeAndEntityIdAndNotificationType(
                "Reservation", entityId, "RESERVATION_EXPIRY_WARNING");
        if (alreadyNotified) continue;

        String customerName = reservation.getCustomer() != null
            ? reservation.getCustomer().getName() : "ismeretlen ügyfél";

        Notification notification = Notification.builder()
            .branchId(reservation.getBranch().getId())
            .companyId(reservation.getCompany().getId())
            .notificationType("RESERVATION_EXPIRY_WARNING")
            .message(String.format(
                "Foglaló hamarosan lejár! Ügyfél: %s, valuta: %s %s, lejárat: %s",
                customerName,
                reservation.getReservedAmount().toPlainString(),
                reservation.getCurrencyCode(),
                reservation.getExpiresAt().toString()))
            .entityType("Reservation")
            .entityId(entityId)
            .isRead(false)
            .build();

        notificationRepository.save(notification);
        notified++;

        log.info("Foglaló lejárat figyelmeztetés elküldve: id={}, ügyfél={}, lejárat={}",
            reservation.getId(), customerName, reservation.getExpiresAt());
    }

    if (notified > 0) {
        log.info("Összesen {} foglaló lejárat figyelmeztetés létrehozva", notified);
    }
}
```

### 4d: Add findActiveExpiringBetween query to ReservationRepository

- [ ] Edit `ReservationRepository.java`:

```java
/**
 * Hamarosan lejáró aktív foglalók.
 * Pre-expiry értesítéshez: azok, amelyek az adott időablakon belül járnak le.
 */
@Query("SELECT r FROM Reservation r " +
       "WHERE r.status = 'ACTIVE' " +
       "AND r.expiresAt BETWEEN :from AND :to " +
       "ORDER BY r.expiresAt ASC")
List<Reservation> findActiveExpiringBetween(
    @Param("from") LocalDateTime from,
    @Param("to") LocalDateTime to);
```

### 4e: Enable scheduling

- [ ] Check if `@EnableScheduling` is already present on the Spring Boot main class or a config class.
  - Main class: `backend/src/main/java/hu/puzzleir/valuta/ValutaApplication.java`
  - If missing, add `@EnableScheduling` to the main class or a dedicated `SchedulingConfig.java`.

---

## TDD Steps

### Test file location
`backend/src/test/java/hu/puzzleir/valuta/service/ReservationServiceTest.java`

### Test cases

- [ ] **T1: fulfillReservation — remaining payment added to HUF** — when exchangeRate=400, reservedAmount=100 EUR, depositAmount=36000 HUF → `addHufBalance` called with 4000 HUF (400×100−36000)
- [ ] **T2: fulfillReservation — no HUF call when deposit covers full price** — when deposit = fullPrice → `addHufBalance` NOT called
- [ ] **T3: fulfillReservation — status becomes FULFILLED** — reservation.getStatus() == FULFILLED
- [ ] **T4: getReservedStock — count is currency-specific** — EUR count uses `countActiveByCurrencyAndBranch(branchId, "EUR")`, not the old universal count
- [ ] **T5: autoExpireReservations — idempotency** — if first iteration sets EXPIRED, second concurrent call skips the already-expired reservation (mock `findByIdForUpdate` to return EXPIRED on 2nd call)
- [ ] **T6: autoExpireReservations — returns correct count** — processes 3 reservations → returns 3
- [ ] **T7: sendPreExpiryWarnings — creates notification** — when expiring reservation found and no existing notification → `notificationRepository.save` called
- [ ] **T8: sendPreExpiryWarnings — idempotent** — when `existsByEntityTypeAndEntityIdAndNotificationType` returns true → no save called
- [ ] **T9: sendPreExpiryWarnings — only active expiring soon** — non-active and not-yet-expiring reservations not included

```java
@Test
void fulfillReservation_addsRemainingPayment() {
    UUID branchId = UUID.randomUUID();
    // 100 EUR @ 400 HUF, deposit = 36000 HUF → maradék = 4000 HUF
    Reservation reservation = buildActiveReservation(
        branchId, "EUR", new BigDecimal("100"), new BigDecimal("400"), new BigDecimal("36000"));

    when(reservationRepository.findByIdForUpdate(1L)).thenReturn(Optional.of(reservation));
    when(workerRepository.findById(any())).thenReturn(Optional.of(new Worker()));
    mockHufBalance(branchId);

    service.fulfillReservation(1L);

    // Ellenőrzés: HUF kassza növelés a maradék fizetéssel
    ArgumentCaptor<BigDecimal> captor = ArgumentCaptor.forClass(BigDecimal.class);
    verify(cashBalanceRepository, times(1)).save(argThat(cb ->
        cb.getCurrentBalance().compareTo(INITIAL_HUF.add(new BigDecimal("4000"))) == 0));
}
```

---

## Test commands

```bash
cd backend
./mvnw test -Dtest=ReservationServiceTest -q
```

Full suite:
```bash
./mvnw test -q
```

---

## Commit message

```
fix(reservation): fulfillReservation HUF adjustment, stock count bug, idempotent expiry, pre-expiry notification

- fulfillReservation(): adds remaining payment (reservedAmount×rate − deposit) to HUF balance
- getReservedStock(): count is now currency-specific via countActiveByCurrencyAndBranch()
- autoExpireReservations(): idempotency via findByIdForUpdate + status re-check
- sendPreExpiryWarnings(): @Scheduled 30min, creates Notification 1 day before expiry, idempotent
- ReservationRepository: findActiveExpiringBetween() + countActiveByCurrencyAndBranch()
- Notification entity + repository (if not already existing)
- V92 migration: notification table (conditional)

Fixes: missing HUF handout on fulfill, wrong activeCount per currency, concurrent expiry race,
       no proactive warning for expiring reservations
```
