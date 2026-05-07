package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.entity.Transfer;
import hu.puzzleir.valuta.entity.Transfer.TransferStatus;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

/**
 * NAV/MNB riport generátor.
 *
 * Valutánkénti forgalom, pénztáros teljesítmény, átadás-átvétel
 */
@Component
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class NbReportGenerator {

    private final TransactionRepository transactionRepository;
    private final CurrencyRepository currencyRepository;
    private final WorkerRepository workerRepository;
    private final TransferRepository transferRepository;

    /**
     * Penztaros teljesitmeny riport
     */
    public ReportService.WorkerPerformanceReport generateWorkerPerformanceReport(Long workerId, LocalDate startDate, LocalDate endDate) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        Worker worker = workerRepository.findByIdAndCompanyId(workerId, companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található"));

        List<Transaction> transactions = transactionRepository
                .findByCompanyIdAndWorkerIdAndTransactionDateBetween(companyId, workerId, startDate, endDate);

        List<Transaction> activeTradeTransactions = transactions.stream()
                .filter(t -> t.isActive()
                        && (t.getTransactionType() == TransactionType.BUY
                        || t.getTransactionType() == TransactionType.SELL))
                .toList();

        int buyCount = (int) activeTradeTransactions.stream()
                .filter(t -> t.getTransactionType() == TransactionType.BUY)
                .count();

        int sellCount = (int) activeTradeTransactions.stream()
                .filter(t -> t.getTransactionType() == TransactionType.SELL)
                .count();

        BigDecimal totalBuy = activeTradeTransactions.stream()
                .filter(t -> t.getTransactionType() == TransactionType.BUY)
                .map(Transaction::getHufAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalSell = activeTradeTransactions.stream()
                .filter(t -> t.getTransactionType() == TransactionType.SELL)
                .map(Transaction::getHufAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        long reversals = transactions.stream()
                .filter(t -> t.getTransactionType() == TransactionType.REVERSAL)
                .count();

        BigDecimal totalHandlingFees = activeTradeTransactions.stream()
                .map(Transaction::getHandlingFee)
                .filter(Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalTurnover = totalBuy.add(totalSell);
        int turnoverTransactionCount = buyCount + sellCount;
        BigDecimal averageTransactionValue = turnoverTransactionCount == 0 ? BigDecimal.ZERO :
                totalTurnover.divide(BigDecimal.valueOf(turnoverTransactionCount), 0, RoundingMode.HALF_UP);
        long dayCount = Math.max(1, ChronoUnit.DAYS.between(startDate, endDate) + 1);
        BigDecimal averageDailyTransactions = BigDecimal.valueOf(turnoverTransactionCount)
                .divide(BigDecimal.valueOf(dayCount), 2, RoundingMode.HALF_UP);
        List<ReportService.CurrencyTurnover> currencyTurnovers =
                ReportService.calculateCurrencyTurnovers(activeTradeTransactions).values().stream()
                        .sorted(Comparator.comparing(ReportService.CurrencyTurnover::getCurrencyCode,
                                Comparator.nullsLast(String::compareTo)))
                        .toList();

        return ReportService.WorkerPerformanceReport.builder()
                .workerId(workerId)
                .workerCode(worker.getCode())
                .workerName(worker.getName())
                .startDate(startDate)
                .endDate(endDate)
                .generatedAt(LocalDateTime.now())
                .totalTransactions(turnoverTransactionCount)
                .buyTransactions(buyCount)
                .sellTransactions(sellCount)
                .reversalCount((int) reversals)
                .totalTransactionCount(turnoverTransactionCount)
                .totalBuyCount(buyCount)
                .totalSellCount(sellCount)
                .totalBuyHuf(totalBuy)
                .totalSellHuf(totalSell)
                .totalTurnoverHuf(totalTurnover)
                .totalHandlingFees(totalHandlingFees)
                .averageTransactionValue(averageTransactionValue)
                .averageDailyTransactions(averageDailyTransactions)
                .currencyTurnovers(currencyTurnovers)
                .build();
    }

    /**
     * Valutankenti forgalmi kimutatas
     */
    public ReportService.CurrencyReport generateCurrencyReport(Long currencyId, LocalDate startDate, LocalDate endDate) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        Currency currency = currencyRepository.findById(currencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található"));

        List<Transaction> buyTransactions = transactionRepository.findByTypeAndDateRange(
                companyId, TransactionType.BUY, startDate, endDate).stream()
                .filter(t -> t.getCurrency().getId().equals(currencyId))
                .collect(Collectors.toList());

        List<Transaction> sellTransactions = transactionRepository.findByTypeAndDateRange(
                companyId, TransactionType.SELL, startDate, endDate).stream()
                .filter(t -> t.getCurrency().getId().equals(currencyId))
                .collect(Collectors.toList());

        BigDecimal totalBoughtAmount = buyTransactions.stream()
                .filter(Transaction::isActive)
                .map(Transaction::getCurrencyAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalSoldAmount = sellTransactions.stream()
                .filter(Transaction::isActive)
                .map(Transaction::getCurrencyAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalBoughtHuf = buyTransactions.stream()
                .filter(Transaction::isActive)
                .map(Transaction::getHufAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalSoldHuf = sellTransactions.stream()
                .filter(Transaction::isActive)
                .map(Transaction::getHufAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal avgBuyRate = totalBoughtAmount.compareTo(BigDecimal.ZERO) > 0
                ? totalBoughtHuf.divide(totalBoughtAmount, 4, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        BigDecimal avgSellRate = totalSoldAmount.compareTo(BigDecimal.ZERO) > 0
                ? totalSoldHuf.divide(totalSoldAmount, 4, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        return ReportService.CurrencyReport.builder()
                .currencyId(currencyId)
                .currencyCode(currency.getCode())
                .currencyName(currency.getName())
                .startDate(startDate)
                .endDate(endDate)
                .generatedAt(LocalDateTime.now())
                .buyTransactionCount(buyTransactions.size())
                .sellTransactionCount(sellTransactions.size())
                .totalBoughtAmount(totalBoughtAmount)
                .totalSoldAmount(totalSoldAmount)
                .netAmount(totalBoughtAmount.subtract(totalSoldAmount))
                .totalBoughtHuf(totalBoughtHuf)
                .totalSoldHuf(totalSoldHuf)
                .netHuf(totalSoldHuf.subtract(totalBoughtHuf))
                .averageBuyRate(avgBuyRate)
                .averageSellRate(avgSellRate)
                .spread(avgSellRate.subtract(avgBuyRate))
                .build();
    }

    /**
     * Atadas-atvetel osszesito riport
     */
    public ReportService.TransferReport generateTransferReport(LocalDate startDate, LocalDate endDate) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();

        List<Transfer> outgoing = transferRepository.findByFromBranchIdOrderByCreatedAtDesc(branchId)
                .stream()
                .filter(t -> !t.getTransferDate().isBefore(startDate) && !t.getTransferDate().isAfter(endDate))
                .collect(Collectors.toList());

        List<Transfer> incoming = transferRepository.findByToBranchIdOrderByCreatedAtDesc(branchId)
                .stream()
                .filter(t -> !t.getTransferDate().isBefore(startDate) && !t.getTransferDate().isAfter(endDate))
                .collect(Collectors.toList());

        BigDecimal totalOutgoingHuf = outgoing.stream()
                .filter(t -> t.getStatus() != TransferStatus.CANCELLED)
                .map(t -> t.getHufValue() != null ? t.getHufValue() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        int outgoingCompleted = (int) outgoing.stream().filter(t -> t.getStatus() == TransferStatus.COMPLETED).count();
        int outgoingPending = (int) outgoing.stream().filter(t -> t.getStatus() == TransferStatus.PENDING).count();

        BigDecimal totalIncomingHuf = incoming.stream()
                .filter(t -> t.getStatus() == TransferStatus.COMPLETED)
                .map(t -> t.getHufValue() != null ? t.getHufValue() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        int incomingCompleted = (int) incoming.stream().filter(t -> t.getStatus() == TransferStatus.COMPLETED).count();
        int incomingPending = (int) incoming.stream().filter(t -> t.getStatus() == TransferStatus.PENDING).count();

        BigDecimal totalDifference = incoming.stream()
                .filter(t -> t.getStatus() == TransferStatus.COMPLETED && t.getDifference() != null)
                .map(Transfer::getDifference)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        List<ReportService.TransferSummaryItem> outgoingItems = outgoing.stream()
                .map(t -> ReportService.TransferSummaryItem.builder()
                        .transferNumber(t.getTransferNumber())
                        .date(t.getTransferDate())
                        .targetBranchName(t.getToBranch().getName())
                        .currencyCode(t.getCurrency().getCode())
                        .amount(t.getAmount())
                        .hufValue(t.getHufValue())
                        .status(t.getStatus().name())
                        .build())
                .collect(Collectors.toList());

        List<ReportService.TransferSummaryItem> incomingItems = incoming.stream()
                .map(t -> ReportService.TransferSummaryItem.builder()
                        .transferNumber(t.getTransferNumber())
                        .date(t.getTransferDate())
                        .targetBranchName(t.getFromBranch().getName())
                        .currencyCode(t.getCurrency().getCode())
                        .amount(t.getReceivedAmount() != null ? t.getReceivedAmount() : t.getAmount())
                        .hufValue(t.getHufValue())
                        .status(t.getStatus().name())
                        .difference(t.getDifference())
                        .build())
                .collect(Collectors.toList());

        return ReportService.TransferReport.builder()
                .startDate(startDate)
                .endDate(endDate)
                .generatedAt(LocalDateTime.now())
                .outgoingCount(outgoing.size())
                .outgoingCompleted(outgoingCompleted)
                .outgoingPending(outgoingPending)
                .totalOutgoingHuf(totalOutgoingHuf)
                .incomingCount(incoming.size())
                .incomingCompleted(incomingCompleted)
                .incomingPending(incomingPending)
                .totalIncomingHuf(totalIncomingHuf)
                .netTransferHuf(totalIncomingHuf.subtract(totalOutgoingHuf))
                .totalDifference(totalDifference)
                .outgoingItems(outgoingItems)
                .incomingItems(incomingItems)
                .build();
    }
}
