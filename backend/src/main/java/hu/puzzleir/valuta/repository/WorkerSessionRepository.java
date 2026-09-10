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
     * Nyitott (logoutAt = null) sessionök egy workerhez.
     *
     * FKH-061 (Defect C): korábban {@code Optional} volt, de a nyitott sorok száma workerenként
     * NEM garantáltan legfeljebb egy — élesben 1771 sor volt nyitva (egy workerhez 456 is), mert
     * minden sikertelen kilépés újabb nyitott sort hagyott hátra. Az {@code Optional} ilyenkor
     * {@code IncorrectResultSizeDataAccessException}-t dobott, amitől a kilépés HTTP 500 lett,
     * ami önerősítő hibakört alkotott (a session sosem zárult le). Listát adunk vissza, a hívó
     * pedig az ÖSSZES nyitott sort lezárja.
     *
     * Multi-tenant megjegyzés: a szűrőkulcs a {@code workerId}, ami önmagában bérlő-meghatározó
     * ({@code worker.company_id NOT NULL}, {@code unique(company_id, code)}). A kilépés üres
     * SecurityContext mellett is futhat (blacklistelt token), ezért a companyId nem mindig
     * feloldható — emiatt nem szűrünk rá külön.
     */
    List<WorkerSession> findByWorkerIdAndLogoutAtIsNull(Long workerId);

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
