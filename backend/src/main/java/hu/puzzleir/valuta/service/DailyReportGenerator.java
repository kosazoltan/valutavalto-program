package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.DailySession;
import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

/**
 * Napi riport generátor.
 *
 * Legacy: NAPZAR, PILLALL riportok
 */
@Component
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class DailyReportGenerator {

    private final TransactionRepository transactionRepository;
    private final DailySessionRepository dailySessionRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final DenominationRepository denominationRepository;
    private final CurrencyRepository currencyRepository;

    /**
     * Napi zaras riport
     *
     * Legacy: NAPZAR - osszesito riport nyomtatashoz
     */
    public ReportService.DailyClosingReport generateDailyClosingReport(LocalDate date) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();

        // Session adatok
        DailySession session = dailySessionRepository.findByBranchIdAndSessionDate(branchId, date)
                .orElse(null);

        // Napi tranzakciok
        List<Transaction> transactions = transactionRepository.findByBranchAndDate(branchId, date);

        // Valutankenti bontas
        Map<String, ReportService.CurrencyTurnover> currencyTurnovers = ReportService.calculateCurrencyTurnovers(transactions);

        // Kassza egyenlegek
        List<CashBalance> balances = cashBalanceRepository.findByBranchId(branchId);

        // Cimletezés (HUF)
        Currency huf = currencyRepository.findByCode("HUF").orElse(null);
        List<Denomination> hufDenominations = huf != null
                ? denominationRepository.findByBranchAndCurrency(branchId, huf.getId())
                : Collections.emptyList();

        BigDecimal denominatedTotal = hufDenominations.stream()
                .map(Denomination::getTotalValue)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Osszesites
        BigDecimal totalBuy = transactions.stream()
                .filter(t -> t.getTransactionType() == TransactionType.BUY && t.isActive())
                .map(Transaction::getHufAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalSell = transactions.stream()
                .filter(t -> t.getTransactionType() == TransactionType.SELL && t.isActive())
                .map(Transaction::getHufAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalFees = transactions.stream()
                .filter(Transaction::isActive)
                .map(Transaction::getHandlingFee)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        long reversalCount = transactions.stream()
                .filter(t -> t.getTransactionType() == TransactionType.REVERSAL)
                .count();

        return ReportService.DailyClosingReport.builder()
                .reportDate(date)
                .generatedAt(LocalDateTime.now())
                .sessionId(session != null ? session.getId() : null)
                .sessionStatus(session != null ? session.getStatus().name() : "NO_SESSION")
                .openingBalanceHuf(session != null ? session.getOpeningBalanceHuf() : BigDecimal.ZERO)
                .closingBalanceHuf(session != null ? session.getClosingBalanceHuf() : null)
                .transactionCount(transactions.size())
                .buyCount((int) transactions.stream().filter(t -> t.getTransactionType() == TransactionType.BUY).count())
                .sellCount((int) transactions.stream().filter(t -> t.getTransactionType() == TransactionType.SELL).count())
                .reversalCount((int) reversalCount)
                .totalBuyHuf(totalBuy)
                .totalSellHuf(totalSell)
                .netTurnoverHuf(totalSell.subtract(totalBuy))
                .totalHandlingFees(totalFees)
                .currencyTurnovers(new ArrayList<>(currencyTurnovers.values()))
                .cashBalances(balances)
                .hufDenominations(hufDenominations)
                .denominatedTotalHuf(denominatedTotal)
                .build();
    }

    /**
     * Kassza allapot riport (pillanat allas)
     *
     * Legacy: PILLALL - pillanat allapot
     */
    public ReportService.CashStatusReport generateCashStatusReport() {
        UUID branchId = SecurityUtils.getCurrentBranchId();

        List<CashBalance> balances = cashBalanceRepository.findByBranchId(branchId);
        List<Denomination> denominations = denominationRepository.findByBranchId(branchId);

        BigDecimal totalHuf = balances.stream()
                .filter(b -> "HUF".equals(b.getCurrency().getCode()))
                .map(CashBalance::getCurrentBalance)
                .findFirst()
                .orElse(BigDecimal.ZERO);

        int lowBalanceAlerts = (int) balances.stream().filter(CashBalance::isLowBalance).count();
        int highBalanceAlerts = (int) balances.stream().filter(CashBalance::isHighBalance).count();
        int lowDenominationAlerts = (int) denominations.stream().filter(Denomination::isLowStock).count();

        return ReportService.CashStatusReport.builder()
                .generatedAt(LocalDateTime.now())
                .totalCurrencies(balances.size())
                .hufBalance(totalHuf)
                .lowBalanceAlerts(lowBalanceAlerts)
                .highBalanceAlerts(highBalanceAlerts)
                .lowDenominationAlerts(lowDenominationAlerts)
                .balances(balances)
                .build();
    }
}
