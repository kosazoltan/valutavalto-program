package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Reservation;
import hu.puzzleir.valuta.entity.ReservationStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Reservation repository.
 *
 * Legacy mapping: FOGLALOKESZLET tábla lekérdezések
 */
@Repository
public interface ReservationRepository extends JpaRepository<Reservation, Long> {

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
}
