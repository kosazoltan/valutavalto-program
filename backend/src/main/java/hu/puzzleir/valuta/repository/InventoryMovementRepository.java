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

    @Query("SELECT m FROM InventoryMovement m WHERE " +
           "(:branchId IS NULL OR m.fromBranch.id = :branchId OR m.toBranch.id = :branchId) " +
           "AND (:startDate IS NULL OR m.movementDate >= :startDate) " +
           "AND (:endDate IS NULL OR m.movementDate <= :endDate) " +
           "AND (:status IS NULL OR m.status = :status) " +
           "AND (:type IS NULL OR m.movementType = :type) " +
           "ORDER BY m.movementDate DESC, m.movementTime DESC")
    Page<InventoryMovement> search(
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

    // v2.4.1 (TRB Export production fix): PostgreSQL JDBC NEM tudja megallapitani
    // a ':param IS NULL' pattern type-jat, ezert PSQLException: "could not determine
    // data type of parameter $N". Megoldas (AuditLogRepository precedens):
    // CAST(:param AS LocalDate) IS NULL — ez explicit type-hint a JDBC driver-nek.
    // Hetzner production log: 2026-04-30 05:02:16 + 05:02:37 — ket reprodukalt hiba.
    @Query("SELECT m FROM InventoryMovement m WHERE " +
           "m.movementType IN ('BANK_WITHDRAW', 'BANK_DEPOSIT') " +
           "AND m.status = 'RECEIVED' " +
           "AND (CAST(:startDate AS LocalDate) IS NULL OR m.movementDate >= :startDate) " +
           "AND (CAST(:endDate AS LocalDate) IS NULL OR m.movementDate <= :endDate) " +
           "ORDER BY m.movementDate DESC")
    List<InventoryMovement> findBankFlows(
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);

    @Query("SELECT m FROM InventoryMovement m WHERE " +
           "m.movementType IN ('BANK_WITHDRAW', 'BANK_DEPOSIT') " +
           "AND m.status = 'RECEIVED' " +
           "AND (m.fromBranch.company.id = :companyId OR m.toBranch.company.id = :companyId) " +
           "AND (CAST(:startDate AS LocalDate) IS NULL OR m.movementDate >= :startDate) " +
           "AND (CAST(:endDate AS LocalDate) IS NULL OR m.movementDate <= :endDate) " +
           "ORDER BY m.movementDate DESC")
    List<InventoryMovement> findBankFlowsByCompanyId(
            @Param("companyId") UUID companyId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);
}
