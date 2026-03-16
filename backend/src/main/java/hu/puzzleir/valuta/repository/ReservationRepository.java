package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Reservation;
import hu.puzzleir.valuta.entity.ReservationStatus;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Reservation repository.
 *
 * Legacy mapping: FOGLALOKESZLET tábla lekérdezések
 */
@Repository
public interface ReservationRepository extends JpaRepository<Reservation, Long> {

    /**
     * Foglaló lekérdezése PESSIMISTIC_WRITE lockkal (race condition védelem).
     * CRITICAL FIX: Párhuzamos teljesítés/stornó megakadályozása.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT r FROM Reservation r WHERE r.id = :id")
    Optional<Reservation> findByIdForUpdate(@Param("id") Long id);

    /**
     * Ügyfél foglalói adott státusszal
     */
    List<Reservation> findByCustomerIdAndStatus(Long customerId, ReservationStatus status);

    /**
     * Iroda foglalói adott státusszal
     */
    List<Reservation> findByBranchIdAndStatus(UUID branchId, ReservationStatus status);

    /**
     * Lejárt, de nem lezárt foglalók (ACTIVE státusz, de expiresAt < now)
     */
    List<Reservation> findByStatusAndExpiresAtBefore(ReservationStatus status, LocalDateTime dateTime);

    /**
     * Foglalók száma egy irodában adott időszakban és státusszal
     */
    @Query("SELECT COUNT(r) FROM Reservation r " +
           "WHERE r.branch.id = :branchId " +
           "AND r.status = :status " +
           "AND r.createdAt BETWEEN :from AND :to")
    long countByBranchAndStatusAndCreatedAtBetween(
            @Param("branchId") UUID branchId,
            @Param("status") ReservationStatus status,
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to);

    /**
     * Foglalt készlet valutanemenként (FOGLALOKESZLET megfelelője).
     * Csak ACTIVE foglalókat összesít.
     */
    @Query("SELECT r.currencyCode, COALESCE(SUM(r.reservedAmount), 0) " +
           "FROM Reservation r " +
           "WHERE r.branch.id = :branchId " +
           "AND r.status = 'ACTIVE' " +
           "GROUP BY r.currencyCode")
    List<Object[]> getReservedStockByBranch(@Param("branchId") UUID branchId);

    /**
     * Aktív foglalók egy irodához (rendezve lejárati idő szerint)
     */
    @Query("SELECT r FROM Reservation r " +
           "WHERE r.branch.id = :branchId " +
           "AND r.status = 'ACTIVE' " +
           "ORDER BY r.expiresAt ASC")
    List<Reservation> findActiveByBranch(@Param("branchId") UUID branchId);

    /**
     * Ügyfél összes aktív foglalója egy cégben
     */
    @Query("SELECT r FROM Reservation r " +
           "WHERE r.customer.id = :customerId " +
           "AND r.company.id = :companyId " +
           "AND r.status = 'ACTIVE' " +
           "ORDER BY r.expiresAt ASC")
    List<Reservation> findActiveByCustomerAndCompany(
            @Param("customerId") Long customerId,
            @Param("companyId") UUID companyId);

    /**
     * Aktív foglalók száma egy irodában, valutanemre szűrve (Bug #2 fix).
     * getReservedStock() currency-specifikus count-hoz.
     */
    @Query("SELECT COUNT(r) FROM Reservation r " +
           "WHERE r.branch.id = :branchId " +
           "AND r.status = 'ACTIVE' " +
           "AND r.currencyCode = :currencyCode")
    long countActiveByCurrencyAndBranch(
            @Param("branchId") UUID branchId,
            @Param("currencyCode") String currencyCode);

    /**
     * Aktív foglalók amelyek egy időablakban járnak le (pre-expiry warning-hoz).
     */
    @Query("SELECT r FROM Reservation r " +
           "WHERE r.status = 'ACTIVE' " +
           "AND r.expiresAt >= :from " +
           "AND r.expiresAt < :to " +
           "ORDER BY r.expiresAt ASC")
    List<Reservation> findActiveExpiringBetween(
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to);

    /**
     * Adott iroda adott napon létrehozott aktív foglalói (esti záráshoz).
     * Csak az adott napon keletkezett ACTIVE foglalókat adja vissza.
     */
    @Query("SELECT r FROM Reservation r " +
           "WHERE r.branch.id = :branchId " +
           "AND r.status = 'ACTIVE' " +
           "AND r.createdAt >= :dayStart " +
           "AND r.createdAt < :dayEnd " +
           "ORDER BY r.expiresAt ASC")
    List<Reservation> findActiveByBranchAndDate(
            @Param("branchId") UUID branchId,
            @Param("dayStart") java.time.LocalDateTime dayStart,
            @Param("dayEnd") java.time.LocalDateTime dayEnd);
}
