package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.InventoryMovement;
import hu.puzzleir.valuta.entity.MovementStatus;
import hu.puzzleir.valuta.entity.MovementType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface InventoryMovementRepository extends JpaRepository<InventoryMovement, Long> {

    Optional<InventoryMovement> findByReferenceNumber(String referenceNumber);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT im FROM InventoryMovement im WHERE im.id = :id")
    Optional<InventoryMovement> findByIdForUpdate(@Param("id") Long id);

    List<InventoryMovement> findByStatus(MovementStatus status);

    // Multi-tenant izoláció (audit 2026-05-31, P1 IDOR): a keresés KÖTELEZŐEN a hívó cégére
    // szűr (fromBranch VAGY toBranch a cégé). A bal-oldali JOIN-ok null-biztosak a
    // bank-mozgásokra is (BANK_WITHDRAW: fromBranch=null, BANK_DEPOSIT: toBranch=null),
    // így azok sem esnek ki implicit inner-join miatt.
    @Query("SELECT m FROM InventoryMovement m " +
           "LEFT JOIN m.fromBranch fb " +
           "LEFT JOIN fb.company fbc " +
           "LEFT JOIN m.toBranch tb " +
           "LEFT JOIN tb.company tbc " +
           "WHERE (fbc.id = :companyId OR tbc.id = :companyId) " +
           "AND (:branchId IS NULL OR fb.id = :branchId OR tb.id = :branchId) " +
           "AND (:startDate IS NULL OR m.movementDate >= :startDate) " +
           "AND (:endDate IS NULL OR m.movementDate <= :endDate) " +
           "AND (:status IS NULL OR m.status = :status) " +
           "AND (:type IS NULL OR m.movementType = :type) " +
           "ORDER BY m.movementDate DESC, m.movementTime DESC")
    Page<InventoryMovement> search(
            @Param("companyId") UUID companyId,
            @Param("branchId") UUID branchId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate,
            @Param("status") MovementStatus status,
            @Param("type") MovementType type,
            Pageable pageable);

    @Query("SELECT COALESCE(MAX(CAST(SUBSTRING(m.referenceNumber, " +
           "LENGTH(:prefix) + 1) AS long)), 0) " +
           "FROM InventoryMovement m WHERE m.referenceNumber LIKE CONCAT(:prefix, '%')")
    long findMaxReferenceNumber(@Param("prefix") String prefix);

    // CAST(:param AS DATE) az SQL-szabványos type-hint a PostgreSQL JDBC driver-nek
    // (ld. issue #327 + AuditLogRepository precedens). Enélkül ':param IS NULL'
    // pattern-en PSQLException: "could not determine data type of parameter".
    @Query("SELECT m FROM InventoryMovement m WHERE " +
           "m.movementType IN ('BANK_WITHDRAW', 'BANK_DEPOSIT') " +
           "AND m.status = 'RECEIVED' " +
           "AND (CAST(:startDate AS DATE) IS NULL OR m.movementDate >= :startDate) " +
           "AND (CAST(:endDate AS DATE) IS NULL OR m.movementDate <= :endDate) " +
           "ORDER BY m.movementDate DESC")
    List<InventoryMovement> findBankFlows(
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);

    @Query("SELECT m FROM InventoryMovement m WHERE " +
           "m.movementType IN ('BANK_WITHDRAW', 'BANK_DEPOSIT') " +
           "AND m.status = 'RECEIVED' " +
           "AND (m.fromBranch.company.id = :companyId OR m.toBranch.company.id = :companyId) " +
           "AND (CAST(:startDate AS DATE) IS NULL OR m.movementDate >= :startDate) " +
           "AND (CAST(:endDate AS DATE) IS NULL OR m.movementDate <= :endDate) " +
           "ORDER BY m.movementDate DESC")
    List<InventoryMovement> findBankFlowsByCompanyId(
            @Param("companyId") UUID companyId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);

    /**
     * v2.5.x P2 — Daily vault flow snapshot tamogatas.
     * Visszaadja a megadott napon RECEIVED statusszal levo osszes mozgast a celcegen
     * belul. A `getVaultStockFlow` ebbol szamol a vault branch-ekre vonatkozo received
     * + issued total-okat valutankent.
     *
     * Index hint: a `inventory_movement(movement_date)` indexet hasznalja (idx_inv_mov_date).
     */
    @Query("SELECT m FROM InventoryMovement m WHERE " +
           "(m.fromBranch.company.id = :companyId OR m.toBranch.company.id = :companyId) " +
           "AND m.status = 'RECEIVED' " +
           "AND m.movementDate = :date " +
           "ORDER BY m.movementTime")
    List<InventoryMovement> findCompletedByCompanyIdAndDate(
            @Param("companyId") UUID companyId,
            @Param("date") LocalDate date);
}
