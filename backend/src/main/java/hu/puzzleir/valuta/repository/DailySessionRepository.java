package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DailySession;
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

/**
 * DailySession repository.
 */
@Repository
public interface DailySessionRepository extends JpaRepository<DailySession, Long> {

    /**
     * Napi session keresése fiók és dátum alapján (JOIN FETCH a lazy proxy hiba elkerüléséhez)
     */
    @Query("SELECT ds FROM DailySession ds " +
           "JOIN FETCH ds.branch " +
           "JOIN FETCH ds.company " +
           "LEFT JOIN FETCH ds.openedByWorker " +
           "LEFT JOIN FETCH ds.closedByWorker " +
           "WHERE ds.company.id = :companyId " +
           "AND ds.branch.id = :branchId AND ds.sessionDate = :sessionDate")
    Optional<DailySession> findByBranchIdAndSessionDate(
            @Param("companyId") UUID companyId,
            @Param("branchId") UUID branchId,
            @Param("sessionDate") LocalDate sessionDate);

    /**
     * Napi session keresése fiók és dátum alapján PESSIMISTIC_WRITE lockkal (race condition védelem).
     *
     * Codex P1 (2026-05-31, #944 review): a napi sztornó-plafon (max 3/nap) ellenőrzése a
     * {@code reversalCount} mezőt olvassa, a növelés viszont a tranzakció VÉGÉN történik
     * ({@code updateSessionStats} → {@code addTransaction}). Két párhuzamos, supervisor-jóváhagyott
     * sztornó KÜLÖNBÖZŐ eredeti tranzakcióra ugyanazt a count értéket olvashatja, mindkettő átmegy a
     * plafon-ellenőrzésen → a nap a hirdetett max-3 fölé kerülhet. A {@code findByIdForUpdate} csak az
     * EREDETI tranzakció sorát lockolja, a napi számlálót NEM.
     *
     * Ez a query a daily_session SORÁT lockolja (SELECT ... FOR UPDATE) a plafon-ellenőrzés ELŐTT, így
     * a párhuzamos sztornó a lock mögött sorba áll: a count olvasása+növelése ugyanabban a
     * write-tranzakcióban szerializálódik. JOIN FETCH NÉLKÜL (vö. {@code CashBalanceRepository
     * .findByBranchIdAndCurrencyIdAndCompanyIdForUpdate}) — a FOR UPDATE PostgreSQL-en nem alkalmazható outer join
     * nullable oldalára; a hívó csak a {@code reversalCount} primitív mezőt olvassa (nincs lazy access).
     */
    // TENANT-NOTE: a lock-query is companyId-szűrt; a hívó JWT-ből adja a branchId-t és companyId-t.
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT ds FROM DailySession ds " +
           "WHERE ds.branch.id = :branchId " +
           "AND ds.sessionDate = :sessionDate " +
           "AND ds.company.id = :companyId")
    Optional<DailySession> findByBranchIdAndSessionDateAndCompanyIdForUpdate(
            @Param("branchId") UUID branchId,
            @Param("sessionDate") LocalDate sessionDate,
            @Param("companyId") UUID companyId);

    /**
     * Napi session részletekkel (lazy proxy hiba elkerüléséhez DTO map előtt).
     */
    @Query("SELECT ds FROM DailySession ds " +
           "LEFT JOIN FETCH ds.branch " +
           "LEFT JOIN FETCH ds.openedByWorker " +
           "LEFT JOIN FETCH ds.closedByWorker " +
           "WHERE ds.company.id = :companyId " +
           "AND ds.branch.id = :branchId AND ds.sessionDate = :sessionDate")
    Optional<DailySession> findByBranchIdAndSessionDateWithDetails(
            @Param("companyId") UUID companyId,
            @Param("branchId") UUID branchId,
            @Param("sessionDate") LocalDate sessionDate);

    /**
     * Aktuális nyitott session egy fiókhoz (JOIN FETCH)
     */
    @Query("SELECT ds FROM DailySession ds " +
           "JOIN FETCH ds.branch " +
           "JOIN FETCH ds.company " +
           "LEFT JOIN FETCH ds.openedByWorker " +
           "LEFT JOIN FETCH ds.closedByWorker " +
           "WHERE ds.company.id = :companyId " +
           "AND ds.branch.id = :branchId " +
           "AND ds.status = 'OPEN' " +
           "ORDER BY ds.sessionDate DESC")
    List<DailySession> findOpenSessionsByBranch(@Param("companyId") UUID companyId,
                                                @Param("branchId") UUID branchId);

    /**
     * Utolsó session egy fiókhoz (JOIN FETCH)
     */
    @Query("SELECT ds FROM DailySession ds " +
           "JOIN FETCH ds.branch " +
           "JOIN FETCH ds.company " +
           "LEFT JOIN FETCH ds.openedByWorker " +
           "LEFT JOIN FETCH ds.closedByWorker " +
           "WHERE ds.company.id = :companyId " +
           "AND ds.branch.id = :branchId " +
           "ORDER BY ds.sessionDate DESC")
    List<DailySession> findLatestByBranch(@Param("companyId") UUID companyId,
                                          @Param("branchId") UUID branchId);

    /**
     * Sessions időszakra (JOIN FETCH a lazy proxy hiba elkerüléséhez)
     */
    @Query("SELECT ds FROM DailySession ds " +
           "JOIN FETCH ds.branch " +
           "JOIN FETCH ds.company " +
           "LEFT JOIN FETCH ds.openedByWorker " +
           "LEFT JOIN FETCH ds.closedByWorker " +
           "WHERE ds.company.id = :companyId " +
           "AND ds.sessionDate BETWEEN :startDate AND :endDate " +
           "ORDER BY ds.sessionDate DESC")
    List<DailySession> findByDateRange(
        @Param("companyId") UUID companyId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    /**
     * FK-038 (2026-06-21): session-történet az ÉRTÉKTÁR (is_vault=TRUE) branch-ek KIZÁRÁSÁVAL —
     * a {@link #findByDateRange} defenzív, PÉNZTÁR-only párja a Dashboard „Zárási állapot (ma)"
     * widget A-forrásához (getSessionHistory). Értéktár nem nyit pénztári napi munkamenetet
     * (DailySessionService.openDay / SessionOpenService.openSession gate); ez a read-oldali
     * védelem a (legacy) esetlegesen már létező vault-session sorok kiszűrésére is — így egy
     * értéktár SOHA nem jelenik meg a pénztári zárás-állapot csempén. A predikátum a
     * {@link hu.puzzleir.valuta.repository.BranchRepository#findRateCreationAssignableCashierBranches(UUID)}
     * (FK02-C) is_vault=false szűrőjét tükrözi.
     */
    @Query("SELECT ds FROM DailySession ds " +
           "JOIN FETCH ds.branch " +
           "JOIN FETCH ds.company " +
           "LEFT JOIN FETCH ds.openedByWorker " +
           "LEFT JOIN FETCH ds.closedByWorker " +
           "LEFT JOIN ds.branch.branchType bt " +
           "WHERE ds.company.id = :companyId " +
           "AND ds.sessionDate BETWEEN :startDate AND :endDate " +
           "AND (ds.branch.isVault IS NULL OR ds.branch.isVault = false) " +
           "AND (bt IS NULL OR bt.code <> 'VAULT_COUNTERPARTY') " +
           "ORDER BY ds.sessionDate DESC")
    List<DailySession> findByDateRangeExcludingVault(
        @Param("companyId") UUID companyId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    /**
     * Nyitott sessionök a céghez (JOIN FETCH)
     */
    @Query("SELECT ds FROM DailySession ds " +
           "JOIN FETCH ds.branch " +
           "JOIN FETCH ds.company " +
           "LEFT JOIN FETCH ds.openedByWorker " +
           "LEFT JOIN FETCH ds.closedByWorker " +
           "WHERE ds.company.id = :companyId " +
           "AND ds.status = 'OPEN'")
    List<DailySession> findOpenSessionsByCompany(@Param("companyId") UUID companyId);

    /**
     * Branch sessionök dátumtartományban (JOIN FETCH).
     */
    @Query("SELECT ds FROM DailySession ds " +
           "JOIN FETCH ds.branch " +
           "JOIN FETCH ds.company " +
           "LEFT JOIN FETCH ds.openedByWorker " +
           "LEFT JOIN FETCH ds.closedByWorker " +
           "WHERE ds.company.id = :companyId " +
           "AND ds.branch.id = :branchId " +
           "AND ds.sessionDate BETWEEN :startDate AND :endDate " +
           "ORDER BY ds.sessionDate ASC")
    List<DailySession> findByBranchAndDateRange(
        @Param("companyId") UUID companyId,
        @Param("branchId") UUID branchId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    /**
     * Nyitott sessionök száma egy branch dátumtartományán belül.
     * Havi zárás előtt 0-nak kell lennie!
     */
    @Query("SELECT COUNT(ds) FROM DailySession ds " +
           "WHERE ds.company.id = :companyId " +
           "AND ds.branch.id = :branchId " +
           "AND ds.sessionDate BETWEEN :startDate AND :endDate " +
           "AND ds.status = 'OPEN'")
    long countOpenSessionsInRange(
        @Param("companyId") UUID companyId,
        @Param("branchId") UUID branchId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    /**
     * Van-e MAI nyitott session (dátumszűrős, JOIN FETCH)
     */
    @Query("SELECT ds FROM DailySession ds " +
           "JOIN FETCH ds.branch " +
           "JOIN FETCH ds.company " +
           "LEFT JOIN FETCH ds.openedByWorker " +
           "LEFT JOIN FETCH ds.closedByWorker " +
           "WHERE ds.company.id = :companyId " +
           "AND ds.branch.id = :branchId " +
           "AND ds.sessionDate = :sessionDate " +
           "AND ds.status = 'OPEN'")
    Optional<DailySession> findOpenSessionByBranchAndDate(
            @Param("companyId") UUID companyId,
            @Param("branchId") UUID branchId,
            @Param("sessionDate") LocalDate sessionDate);

    /**
     * Van-e nyitott session (MAI napra)
     */
    default boolean hasOpenSession(UUID companyId, UUID branchId) {
        return findOpenSessionByBranchAndDate(companyId, branchId, LocalDate.now()).isPresent();
    }

    /**
     * FKH-050 (FR-1): the caller's OPEN past-day sessions for one branch, oldest first.
     * Company-scoped (invariant #1) — {@code sessionDate < today} excludes today;
     * {@code status <> CLOSED} matches the ticket wording (PENDING_CLOSE is never
     * written — verified in the plan's context).
     */
    @Query("SELECT ds FROM DailySession ds " +
           "WHERE ds.company.id = :companyId " +
           "AND ds.branch.id = :branchId " +
           "AND ds.sessionDate < :today " +
           "AND ds.status <> hu.puzzleir.valuta.entity.DailySessionStatus.CLOSED " +
           "ORDER BY ds.sessionDate ASC")
    List<DailySession> findOpenPastSessionsByBranch(
            @Param("companyId") UUID companyId,
            @Param("branchId") UUID branchId,
            @Param("today") LocalDate today);

    /**
     * FKH-051 (plan D3): "false-closed" past-day fingerprint — the destructive
     * day-open auto-close wrote CLOSED with {@code closedByWorker IS NULL} and no
     * retroactive stamp. Company-scoped (invariant #1), oldest first (matches
     * {@code findOpenPastSessionsByBranch}). The boxed {@code isRetroactiveClosing}
     * needs the explicit {@code IS NULL OR = FALSE} arm.
     */
    @Query("SELECT ds FROM DailySession ds " +
           "WHERE ds.company.id = :companyId " +
           "AND ds.branch.id = :branchId " +
           "AND ds.sessionDate < :today " +
           "AND ds.status = hu.puzzleir.valuta.entity.DailySessionStatus.CLOSED " +
           "AND ds.closedByWorker IS NULL " +
           "AND (ds.isRetroactiveClosing IS NULL OR ds.isRetroactiveClosing = FALSE) " +
           "ORDER BY ds.sessionDate ASC")
    List<DailySession> findFalseClosedPastSessionsByBranch(
            @Param("companyId") UUID companyId,
            @Param("branchId") UUID branchId,
            @Param("today") LocalDate today);

    /**
     * Utolsó session lekérése
     */
    default Optional<DailySession> findLatest(UUID companyId, UUID branchId) {
        List<DailySession> sessions = findLatestByBranch(companyId, branchId);
        return sessions.isEmpty() ? Optional.empty() : Optional.of(sessions.get(0));
    }
}
