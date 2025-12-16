package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.WorkerSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * WorkerSession repository - belépési történet tracking.
 */
@Repository
public interface WorkerSessionRepository extends JpaRepository<WorkerSession, Long> {

    /**
     * Aktív session egy workerhez (logoutAt = null)
     */
    Optional<WorkerSession> findByWorkerIdAndLogoutAtIsNull(Long workerId);

    /**
     * Összes session egy workerhez
     */
    List<WorkerSession> findByWorkerIdOrderByLoginAtDesc(Long workerId);

    /**
     * Sessions egy időszakban (company-nál)
     */
    @Query("SELECT ws FROM WorkerSession ws WHERE ws.company.id = :companyId AND ws.loginAt BETWEEN :startDate AND :endDate")
    List<WorkerSession> findSessionsByDateRange(
        @Param("companyId") UUID companyId,
        @Param("startDate") LocalDateTime startDate,
        @Param("endDate") LocalDateTime endDate
    );

    /**
     * Aktív sessionök száma company-ban
     */
    @Query("SELECT COUNT(ws) FROM WorkerSession ws WHERE ws.company.id = :companyId AND ws.logoutAt IS NULL")
    long countActiveSessions(@Param("companyId") UUID companyId);

    /**
     * Session token alapján
     */
    Optional<WorkerSession> findByTokenId(String tokenId);
}
