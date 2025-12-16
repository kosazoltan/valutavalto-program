package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DailySession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * DailySession repository.
 */
@Repository
public interface DailySessionRepository extends JpaRepository<DailySession, Long> {

    /**
     * Napi session keresése fiók és dátum alapján
     */
    Optional<DailySession> findByBranchIdAndSessionDate(UUID branchId, LocalDate sessionDate);

    /**
     * Aktuális nyitott session egy fiókhoz
     */
    @Query("SELECT ds FROM DailySession ds " +
           "WHERE ds.branch.id = :branchId " +
           "AND ds.status = 'OPEN' " +
           "ORDER BY ds.sessionDate DESC")
    List<DailySession> findOpenSessionsByBranch(@Param("branchId") UUID branchId);

    /**
     * Utolsó session egy fiókhoz
     */
    @Query("SELECT ds FROM DailySession ds " +
           "WHERE ds.branch.id = :branchId " +
           "ORDER BY ds.sessionDate DESC")
    List<DailySession> findLatestByBranch(@Param("branchId") UUID branchId);

    /**
     * Sessions időszakra
     */
    @Query("SELECT ds FROM DailySession ds " +
           "WHERE ds.company.id = :companyId " +
           "AND ds.sessionDate BETWEEN :startDate AND :endDate " +
           "ORDER BY ds.sessionDate DESC")
    List<DailySession> findByDateRange(
        @Param("companyId") UUID companyId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    /**
     * Nyitott sessionök a céghez
     */
    @Query("SELECT ds FROM DailySession ds " +
           "WHERE ds.company.id = :companyId " +
           "AND ds.status = 'OPEN'")
    List<DailySession> findOpenSessionsByCompany(@Param("companyId") UUID companyId);

    /**
     * Van-e nyitott session
     */
    default boolean hasOpenSession(UUID branchId) {
        return !findOpenSessionsByBranch(branchId).isEmpty();
    }

    /**
     * Utolsó session lekérése
     */
    default Optional<DailySession> findLatest(UUID branchId) {
        List<DailySession> sessions = findLatestByBranch(branchId);
        return sessions.isEmpty() ? Optional.empty() : Optional.of(sessions.get(0));
    }
}
