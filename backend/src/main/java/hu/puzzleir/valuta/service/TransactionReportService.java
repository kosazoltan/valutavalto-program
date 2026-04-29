package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Tranzakcio riport es lekerdezesi szolgaltatas.
 *
 * Napi forgalom osszesites, tranzakcio keresese, szures.
 * Kiemelve a TransactionService-bol a single-responsibility elv alapjan.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class TransactionReportService {

    private final TransactionRepository transactionRepository;

    /**
     * Tranzakcio keresese bizonylat szam alapjan.
     */
    public Transaction findByReceiptNumber(String receiptNumber) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return transactionRepository.findByReceiptNumberAndCompanyId(receiptNumber, companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Bizonylat nem talalhato: " + receiptNumber));
    }

    /**
     * Napi tranzakciok lekerese.
     */
    public List<Transaction> getDailyTransactions() {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        return transactionRepository.findByBranchAndDate(branchId, LocalDate.now());
    }

    /**
     * Tranzakciok szurese es lapozas.
     *
     * 2026-04-29 v2.3.26 (Codex P1 PR #290 follow-up):
     * branchId nullable — ha null, company-wide query (cég-szintű riport).
     * A controller `@PreAuthorize`-ja védi a company-wide hívást MANAGER+ szinten.
     */
    public Page<Transaction> searchTransactions(
            UUID branchId,
            LocalDate startDate,
            LocalDate endDate,
            TransactionType type,
            Pageable pageable) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (branchId == null) {
            return transactionRepository.findCompanyWideWithFilters(
                    companyId, startDate, endDate, type, pageable);
        }
        return transactionRepository.findWithFilters(companyId, branchId, startDate, endDate, type, pageable);
    }

    /**
     * Napi forgalom osszesites.
     */
    public TransactionService.DailyTurnoverSummary getDailyTurnover() {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        LocalDate today = LocalDate.now();

        BigDecimal buyTotal = transactionRepository.sumDailyTurnover(branchId, today, TransactionType.BUY);
        BigDecimal sellTotal = transactionRepository.sumDailyTurnover(branchId, today, TransactionType.SELL);
        long reversalCount = transactionRepository.countReversalsByBranchAndDate(branchId, today);

        long buyCount = transactionRepository.countByBranchIdAndTransactionDateAndTransactionType(branchId, today, TransactionType.BUY);
        long sellCount = transactionRepository.countByBranchIdAndTransactionDateAndTransactionType(branchId, today, TransactionType.SELL);
        BigDecimal totalHandlingFees = transactionRepository.sumDailyHandlingFees(branchId, today);

        return TransactionService.DailyTurnoverSummary.builder()
                .date(today)
                .buyTotal(buyTotal != null ? buyTotal : BigDecimal.ZERO)
                .sellTotal(sellTotal != null ? sellTotal : BigDecimal.ZERO)
                .netTotal((sellTotal != null ? sellTotal : BigDecimal.ZERO)
                        .subtract(buyTotal != null ? buyTotal : BigDecimal.ZERO))
                .reversalCount(reversalCount)
                .totalBuyCount(buyCount)
                .totalSellCount(sellCount)
                .totalBuyHuf(buyTotal != null ? buyTotal : BigDecimal.ZERO)
                .totalSellHuf(sellTotal != null ? sellTotal : BigDecimal.ZERO)
                .totalHandlingFees(totalHandlingFees != null ? totalHandlingFees : BigDecimal.ZERO)
                .totalReversalCount(reversalCount)
                .build();
    }
}
