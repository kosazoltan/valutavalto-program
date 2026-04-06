package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.AuditLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface AuditLogRepository extends JpaRepository<AuditLog, UUID> {

    @Query(value = "SELECT * FROM audit_log a WHERE " +
           "a.company_id = :companyId AND " +
           "(CAST(:from AS timestamp) IS NULL OR a.created_at >= :from) AND " +
           "(CAST(:to AS timestamp) IS NULL OR a.created_at <= :to) " +
           "ORDER BY a.created_at DESC",
           countQuery = "SELECT COUNT(*) FROM audit_log a WHERE " +
           "a.company_id = :companyId AND " +
           "(CAST(:from AS timestamp) IS NULL OR a.created_at >= :from) AND " +
           "(CAST(:to AS timestamp) IS NULL OR a.created_at <= :to)",
           nativeQuery = true)
    Page<AuditLog> findByDateRange(
            @Param("companyId") UUID companyId,
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to,
            Pageable pageable);

    @Query(value = "SELECT * FROM audit_log a WHERE " +
           "a.company_id = :companyId AND " +
           "(CAST(:from AS timestamp) IS NULL OR a.created_at >= :from) AND " +
           "(CAST(:to AS timestamp) IS NULL OR a.created_at <= :to) " +
           "ORDER BY a.created_at DESC",
           nativeQuery = true)
    List<AuditLog> findAllByDateRange(
            @Param("companyId") UUID companyId,
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to);

    List<AuditLog> findByCompanyIdAndEntityIdOrderByCreatedAtDesc(UUID companyId, String entityId);

    List<AuditLog> findByCompanyIdAndEntityTypeAndEntityIdOrderByCreatedAtDesc(UUID companyId, String entityType, String entityId);

    @Query(value = "SELECT * FROM audit_log a WHERE a.company_id = :companyId " +
           "AND a.user_id = :userId " +
           "AND (CAST(:from AS timestamp) IS NULL OR a.created_at >= :from) " +
           "AND (CAST(:to AS timestamp) IS NULL OR a.created_at <= :to) " +
           "ORDER BY a.created_at DESC",
           countQuery = "SELECT COUNT(*) FROM audit_log a WHERE a.company_id = :companyId " +
           "AND a.user_id = :userId " +
           "AND (CAST(:from AS timestamp) IS NULL OR a.created_at >= :from) " +
           "AND (CAST(:to AS timestamp) IS NULL OR a.created_at <= :to)",
           nativeQuery = true)
    Page<AuditLog> findByWorker(
            @Param("companyId") UUID companyId,
            @Param("userId") String userId,
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to,
            Pageable pageable);

    @Query(value = "SELECT * FROM audit_log a WHERE a.company_id = :companyId " +
           "AND a.branch_id = :branchId " +
           "AND (CAST(:from AS timestamp) IS NULL OR a.created_at >= :from) " +
           "AND (CAST(:to AS timestamp) IS NULL OR a.created_at <= :to) " +
           "ORDER BY a.created_at DESC",
           countQuery = "SELECT COUNT(*) FROM audit_log a WHERE a.company_id = :companyId " +
           "AND a.branch_id = :branchId " +
           "AND (CAST(:from AS timestamp) IS NULL OR a.created_at >= :from) " +
           "AND (CAST(:to AS timestamp) IS NULL OR a.created_at <= :to)",
           nativeQuery = true)
    Page<AuditLog> findByBranch(
            @Param("companyId") UUID companyId,
            @Param("branchId") String branchId,
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to,
            Pageable pageable);

    @Query(value = "SELECT * FROM audit_log a WHERE a.company_id = :companyId " +
           "AND a.action = :action " +
           "AND (CAST(:from AS timestamp) IS NULL OR a.created_at >= :from) " +
           "AND (CAST(:to AS timestamp) IS NULL OR a.created_at <= :to) " +
           "ORDER BY a.created_at DESC",
           countQuery = "SELECT COUNT(*) FROM audit_log a WHERE a.company_id = :companyId " +
           "AND a.action = :action " +
           "AND (CAST(:from AS timestamp) IS NULL OR a.created_at >= :from) " +
           "AND (CAST(:to AS timestamp) IS NULL OR a.created_at <= :to)",
           nativeQuery = true)
    Page<AuditLog> findByAction(
            @Param("companyId") UUID companyId,
            @Param("action") String action,
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to,
            Pageable pageable);

    /**
     * Összetett keresés — szűrés minden mező kombinációjára.
     * CAST(:x AS timestamp/text) a PostgreSQL nullable paraméter típus-felismerés fix-éhez.
     */
    @Query(value = "SELECT a.* FROM audit_log a WHERE " +
           "a.company_id = :companyId AND " +
           "(CAST(:dateFrom AS timestamp) IS NULL OR a.created_at >= :dateFrom) AND " +
           "(CAST(:dateTo AS timestamp) IS NULL OR a.created_at <= :dateTo) AND " +
           "(CAST(:workerId AS text) IS NULL OR a.user_id = :workerId) AND " +
           "(CAST(:entityType AS text) IS NULL OR a.entity_type = :entityType) AND " +
           "(CAST(:action AS text) IS NULL OR a.action = :action) AND " +
           "(CAST(:keyword AS text) IS NULL OR LOWER(a.changes) LIKE LOWER(CONCAT('%', CAST(:keyword AS text), '%')) " +
           " OR CAST(:keyword AS text) IS NULL OR LOWER(a.reason) LIKE LOWER(CONCAT('%', CAST(:keyword AS text), '%')) " +
           " OR CAST(:keyword AS text) IS NULL OR LOWER(a.user_name) LIKE LOWER(CONCAT('%', CAST(:keyword AS text), '%'))) " +
           "ORDER BY a.created_at DESC",
           countQuery = "SELECT COUNT(*) FROM audit_log a WHERE " +
           "a.company_id = :companyId AND " +
           "(CAST(:dateFrom AS timestamp) IS NULL OR a.created_at >= :dateFrom) AND " +
           "(CAST(:dateTo AS timestamp) IS NULL OR a.created_at <= :dateTo) AND " +
           "(CAST(:workerId AS text) IS NULL OR a.user_id = :workerId) AND " +
           "(CAST(:entityType AS text) IS NULL OR a.entity_type = :entityType) AND " +
           "(CAST(:action AS text) IS NULL OR a.action = :action) AND " +
           "(CAST(:keyword AS text) IS NULL OR LOWER(a.changes) LIKE LOWER(CONCAT('%', CAST(:keyword AS text), '%')) " +
           " OR CAST(:keyword AS text) IS NULL OR LOWER(a.reason) LIKE LOWER(CONCAT('%', CAST(:keyword AS text), '%')) " +
           " OR CAST(:keyword AS text) IS NULL OR LOWER(a.user_name) LIKE LOWER(CONCAT('%', CAST(:keyword AS text), '%')))",
           nativeQuery = true)
    Page<AuditLog> searchAuditLog(
            @Param("companyId") UUID companyId,
            @Param("dateFrom") LocalDateTime dateFrom,
            @Param("dateTo") LocalDateTime dateTo,
            @Param("workerId") String workerId,
            @Param("entityType") String entityType,
            @Param("action") String action,
            @Param("keyword") String keyword,
            Pageable pageable);

    boolean existsByActionAndEntityId(String action, String entityId);

    boolean existsByCompanyIdAndActionAndEntityId(UUID companyId, String action, String entityId);

    /**
     * Utolso bejegyzes hash-enek lekerdezese a hash-lanchoz (H11 tamper-evidence).
     * Pessimistic lock: megakadalyozza a parhuzamos olvasast (race condition vedelem).
     */
    @Query(value = "SELECT a.entry_hash FROM audit_log a WHERE a.entry_hash IS NOT NULL ORDER BY a.created_at DESC LIMIT 1 FOR UPDATE", nativeQuery = true)
    Optional<String> findLastEntryHashForUpdate();
}
