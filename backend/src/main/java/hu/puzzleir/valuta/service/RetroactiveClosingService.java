package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.ClosingMarkType;
import hu.puzzleir.valuta.dto.eveningclosing.DailyDataPackage;
import hu.puzzleir.valuta.dto.eveningclosing.DataSyncResult;
import hu.puzzleir.valuta.dto.retroactiveclosing.OpenPastDayDto;
import hu.puzzleir.valuta.dto.retroactiveclosing.RetroactiveReconciliationDto;
import hu.puzzleir.valuta.entity.DailyBalance;
import hu.puzzleir.valuta.entity.DailySession;
import hu.puzzleir.valuta.entity.DailySessionStatus;
import hu.puzzleir.valuta.entity.DenominationCategory;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.DailyBalanceRepository;
import hu.puzzleir.valuta.repository.DailySessionRepository;
import hu.puzzleir.valuta.repository.DenominationBalanceRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * FKH-050: user-initiated simplified RETROACTIVE closing of past open daily sessions.
 *
 * <p>A caller lists their own open past days (FR-1), reconciles one (FR-5: expected
 * from that day's {@code daily_balance.closing_balance}, actual from the counted
 * EVENING stock with {@code submission_date = pastDate} — never today's
 * {@code cash_balance}/{@code currency_stock}, NFR-1), then closes it: the evening
 * package of THAT date is prepared and sent, and on success the session row is
 * locked, marked CLOSED and stamped with retroactive audit fields (FR-6/FR-7).</p>
 *
 * <p>Multi-tenant invariant #1: every query is companyId-scoped; the scope guard
 * ({@link #requireRetroactiveScope}) allows the caller's own branch or branches
 * visible in their vault-region scope ({@code null} = company-wide, EMPTY = see
 * nothing — the {@code DailySessionService} session-history pattern).</p>
 *
 * <p>D3: closing is chronological, oldest first — while an older open past day
 * exists, closing a newer one is rejected (the opening-balance chain).</p>
 *
 * <p>D7: the close does NOT call {@code ClosingWizardService.ensureClosingCanBeSent}
 * (its vault arm reads CURRENT {@code currency_stock}, which cannot describe a past
 * day). It applies its own gate over the date-keyed reconciliation with the SAME
 * {@code closingToleranceService} predicate (FK-073: displayed table == enforced gate).</p>
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class RetroactiveClosingService {

    private final DailySessionRepository dailySessionRepository;
    private final DailyBalanceRepository dailyBalanceRepository;
    private final DenominationBalanceRepository denominationBalanceRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final WorkerRepository workerRepository;
    private final AccessScopeService accessScopeService;
    private final ClosingToleranceService closingToleranceService;
    private final DailyBalanceService dailyBalanceService;
    private final EveningClosingService eveningClosingService;
    private final ClosingControlService closingControlService;
    private final DailySessionService dailySessionService;
    private final AuditLogService auditLogService;

    // ---------------------------------------------------------------------
    // FR-1 — list the caller's open past days (own company + scope)
    // ---------------------------------------------------------------------

    /**
     * FR-1: the caller's OPEN past-day sessions of one branch, oldest first
     * (today excluded). Scope-guarded (D2, invariant #1).
     */
    @Transactional(readOnly = true)
    public List<OpenPastDayDto> listOpenPastDays(UUID branchId) {
        requireRetroactiveScope(branchId);
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        LocalDate today = LocalDate.now();
        return dailySessionRepository.findOpenPastSessionsByBranch(companyId, branchId, today)
                .stream()
                .map(session -> new OpenPastDayDto(session.getSessionDate()))
                .toList();
    }

    // ---------------------------------------------------------------------
    // FR-5 / D6 — reconciliation against the PAST day's book value
    // ---------------------------------------------------------------------

    /**
     * FR-5/D6: reconciliation of a past day. Expected = that day's
     * {@code daily_balance.closing_balance} (book value); actual = the counted
     * EVENING stock with {@code submission_date = date}; blocking via the SAME
     * {@link ClosingToleranceService} predicate the today-flow uses (FK-073).
     * Never touches today's {@code cash_balance}/{@code currency_stock} (NFR-1).
     */
    public RetroactiveReconciliationDto reconcile(UUID branchId, LocalDate date) {
        requireRetroactiveScope(branchId);
        requirePastDate(date);
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        // Idempotent: writes ONLY balance_date = date rows (NFR-1).
        dailyBalanceService.calculateAllCurrenciesForDay(branchId, date);

        List<RetroactiveReconciliationDto.Row> rows = new ArrayList<>();
        boolean anyBlocking = false;
        for (Object[] stockRow : denominationBalanceRepository
                .sumActualStockByCurrency(branchId, date, DenominationCategory.EVENING)) {
            if (!(stockRow[0] instanceof String currencyCode)
                    || !(stockRow[1] instanceof BigDecimal actual)) {
                continue;
            }
            actual = actual.setScale(2, RoundingMode.HALF_UP);
            BigDecimal expected = dailyBalanceRepository
                    .findByBranchIdAndBalanceDateAndCurrencyCode(companyId, branchId, date, currencyCode)
                    .map(DailyBalance::getClosingBalance)
                    .orElse(null);
            if (expected == null) {
                // D8: missing book row -> treat as zero, but log (fail-loud, not fail-silent).
                log.warn("Retroactive reconciliation: no daily_balance row for branch={}, date={}, currency={}"
                        + " -> expected falls back to 0", branchId, date, currencyCode);
                expected = BigDecimal.ZERO;
            }
            expected = expected.setScale(2, RoundingMode.HALF_UP);
            BigDecimal difference = actual.subtract(expected);
            boolean blocking = closingToleranceService.getToleranceFor(currencyCode).blocks(difference);
            anyBlocking |= blocking;
            rows.add(new RetroactiveReconciliationDto.Row(
                    currencyCode, expected, actual, difference, blocking));
        }
        return new RetroactiveReconciliationDto(date, rows, anyBlocking);
    }

    // ---------------------------------------------------------------------
    // FR-6 / FR-7 — close retroactively
    // ---------------------------------------------------------------------

    /**
     * FR-6/FR-7: closes one past day: scope guard -> oldest-first gate (D3) ->
     * row lock -> reconciliation gate (D7) -> prepare + send the evening package
     * of THAT date -> on success mark the closing control, stamp the session
     * CLOSED with retroactive audit fields and write the audit log row.
     * A send failure throws BEFORE any status write; the day stays OPEN.
     */
    public DailySession closeRetroactively(UUID branchId, LocalDate date) {
        requireRetroactiveScope(branchId);
        requirePastDate(date);
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        LocalDate today = LocalDate.now();

        // D3: chronological, oldest first — reject while an older open day exists.
        List<DailySession> openPastDays =
                dailySessionRepository.findOpenPastSessionsByBranch(companyId, branchId, today);
        LocalDate oldest = openPastDays.isEmpty() ? null : openPastDays.get(0).getSessionDate();
        if (oldest == null || !oldest.isEqual(date)) {
            throw new ValidationException(
                    "Utólagos zárás csak a legrégebbi nyitott napon indítható. Legrégebbi nyitott nap: "
                            + (oldest == null ? "nincs" : oldest) + ", kért nap: " + date);
        }

        // Lock the session row (PESSIMISTIC_WRITE, no JOIN FETCH — the FOR UPDATE
        // pattern of findByBranchIdAndSessionDateAndCompanyIdForUpdate).
        DailySession session = dailySessionRepository
                .findByBranchIdAndSessionDateAndCompanyIdForUpdate(branchId, date, companyId)
                .orElseThrow(() -> new ValidationException(
                        "Nincs napi munkamenet erre a napra: " + date));
        if (session.getStatus() == DailySessionStatus.CLOSED) {
            // Race with openDay()'s stale-day force-close: report, never 500.
            throw new ValidationException("Ez a nap már le van zárva: " + date);
        }

        // D7 gate: the SAME tolerance predicate as the displayed reconciliation.
        RetroactiveReconciliationDto reconciliation = reconcile(branchId, date);
        if (reconciliation.anyBlocking()) {
            throw new ValidationException(
                    "Az utólagos zárás eltérést talált a(z) " + date + " napon — a zárás nem indítható.");
        }

        // FR-6: prepare + send the evening package of THAT date. Failure -> throw
        // BEFORE any status write; the day stays OPEN.
        DailyDataPackage pkg = eveningClosingService.prepareDailyPackage(branchId, date);
        DataSyncResult sendResult = eveningClosingService.sendToHeadquarters(pkg);
        if (sendResult == null || !sendResult.isSuccess()) {
            throw new ValidationException(
                    "Az esti csomag küldése sikertelen a(z) " + date + " napon: "
                            + (sendResult == null ? "ismeretlen hiba" : sendResult.getMessage()));
        }

        closingControlService.markClosingDone(companyId, branchId, date, ClosingMarkType.EVENING);

        // D8: the retroactive closing balance is the past day's HUF book value.
        BigDecimal hufClosingBalance = reconciliation.rows().stream()
                .filter(row -> "HUF".equals(row.currencyCode()))
                .findFirst()
                .map(RetroactiveReconciliationDto.Row::expected)
                .orElse(null);
        if (hufClosingBalance == null) {
            log.warn("Retroactive close: no HUF daily_balance row for branch={}, date={}"
                    + " -> closing_balance_huf stays null", branchId, date);
        }

        // FR-7 audit stamp — execution time is distinct from session_date by construction.
        Long workerId = SecurityUtils.getCurrentWorkerId();
        Worker worker = workerRepository.findById(workerId).orElse(null);
        LocalDateTime now = LocalDateTime.now();
        session.setStatus(DailySessionStatus.CLOSED);
        session.setClosedAt(now);
        session.setClosedByWorker(worker);
        session.setClosingBalanceHuf(hufClosingBalance);
        session.setIsRetroactiveClosing(true);
        session.setRetroactiveClosedByWorker(worker);
        session.setRetroactiveClosedAt(now);
        dailySessionRepository.save(session);

        // NFR-3: audit trail.
        auditLogService.log("RETROACTIVE_CLOSING_EXECUTED",
                String.format("{\"branch_id\":\"%s\",\"session_date\":\"%s\",\"worker_id\":%d}",
                        branchId, date, workerId),
                branchId.toString());

        log.info("Retroactive close executed: branch={}, date={}, worker={}", branchId, date, workerId);
        return session;
    }

    // ---------------------------------------------------------------------
    // guards
    // ---------------------------------------------------------------------

    /**
     * D2 (invariant #1): the branch must be the caller's own branch (the JWT ties
     * it to their company) or visible in their vault-region scope. {@code null}
     * scope = company-wide, EMPTY scope = see nothing (DailySessionService:422 pattern).
     */
    private void requireRetroactiveScope(UUID branchId) {
        UUID currentBranchId = SecurityUtils.getCurrentBranchIdOrNull();
        if (branchId.equals(currentBranchId)) {
            return;
        }
        Set<UUID> vaultScope = accessScopeService.vaultRegionBranchScopeOrNull();
        if (vaultScope == null) {
            return; // company-wide role
        }
        if (!vaultScope.contains(branchId)) {
            throw new AccessDeniedException("Nincs hozzáférés az irodához: " + branchId);
        }
    }

    /** Server-side past-date guard (today/future rejected, not only in the UI). */
    private void requirePastDate(LocalDate date) {
        if (date == null || !date.isBefore(LocalDate.now())) {
            throw new ValidationException("Utólagos zárás csak múlt-beli napra indítható: " + date);
        }
    }
}
