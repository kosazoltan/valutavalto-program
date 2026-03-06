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
import java.util.UUID;

@Repository
public interface AuditLogRepository extends JpaRepository<AuditLog, UUID> {

    @Query("SELECT a FROM AuditLog a WHERE " +
           "(:from IS NULL OR a.createdAt >= :from) AND " +
           "(:to IS NULL OR a.createdAt <= :to) " +
           "ORDER BY a.createdAt DESC")
    Page<AuditLog> findByDateRange(
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to,
            Pageable pageable);

    @Query("SELECT a FROM AuditLog a WHERE " +
           "(:from IS NULL OR a.createdAt >= :from) AND " +
           "(:to IS NULL OR a.createdAt <= :to) " +
           "ORDER BY a.createdAt DESC")
    List<AuditLog> findAllByDateRange(
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to);

    List<AuditLog> findByEntityIdOrderByCreatedAtDesc(String entityId);

    List<AuditLog> findByEntityTypeAndEntityIdOrderByCreatedAtDesc(String entityType, String entityId);

    @Query("SELECT a FROM AuditLog a WHERE a.userId = :userId " +
           "AND (:from IS NULL OR a.createdAt >= :from) " +
           "AND (:to IS NULL OR a.createdAt <= :to) " +
           "ORDER BY a.createdAt DESC")
    Page<AuditLog> findByWorker(
            @Param("userId") String userId,
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to,
            Pageable pageable);

    @Query("SELECT a FROM AuditLog a WHERE a.branchId = :branchId " +
           "AND (:from IS NULL OR a.createdAt >= :from) " +
           "AND (:to IS NULL OR a.createdAt <= :to) " +
           "ORDER BY a.createdAt DESC")
    Page<AuditLog> findByBranch(
            @Param("branchId") String branchId,
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to,
            Pageable pageable);

    @Query("SELECT a FROM AuditLog a WHERE a.action = :action " +
           "AND (:from IS NULL OR a.createdAt >= :from) " +
           "AND (:to IS NULL OR a.createdAt <= :to) " +
           "ORDER BY a.createdAt DESC")
    Page<AuditLog> findByAction(
            @Param("action") String action,
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to,
            Pageable pageable);

    /**
     * Összetett keresés — szűrés minden mező kombinációjára.
     */
    @Query("SELECT a FROM AuditLog a WHERE " +
           "(:dateFrom IS NULL OR a.createdAt >= :dateFrom) AND " +
           "(:dateTo IS NULL OR a.createdAt <= :dateTo) AND " +
           "(:workerId IS NULL OR a.userId = :workerId) AND " +
           "(:entityType IS NULL OR a.entityType = :entityType) AND " +
           "(:action IS NULL OR a.action = :action) AND " +
           "(:keyword IS NULL OR LOWER(a.changes) LIKE LOWER(CONCAT('%', :keyword, '%')) " +
           " OR :keyword IS NULL OR LOWER(a.reason) LIKE LOWER(CONCAT('%', :keyword, '%')) " +
           " OR :keyword IS NULL OR LOWER(a.userName) LIKE LOWER(CONCAT('%', :keyword, '%'))) " +
           "ORDER BY a.createdAt DESC")
    Page<AuditLog> searchAuditLog(
            @Param("dateFrom") LocalDateTime dateFrom,
            @Param("dateTo") LocalDateTime dateTo,
            @Param("workerId") String workerId,
            @Param("entityType") String entityType,
            @Param("action") String action,
            @Param("keyword") String keyword,
            Pageable pageable);
}
