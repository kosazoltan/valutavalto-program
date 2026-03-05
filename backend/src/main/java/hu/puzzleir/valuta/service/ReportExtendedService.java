package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Kibővített riport szolgáltatás — tranzakciós listák, díjösszesítők,
 * havi forgalmi és készlet kimutatások, AML gyanús tranzakciók.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class ReportExtendedService {

    private final TransactionRepository transactionRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final TransferRepository transferRepository;
    private final DenominationRepository denominationRepository;

    // ============ TRANSACTION LIST ============

    public Map<String, Object> getTransactionList(UUID branchId, LocalDate startDate, LocalDate endDate) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID effectiveBranch = branchId != null ? branchId : SecurityUtils.getCurrentBranchId();
        LocalDate start = startDate != null ? startDate : LocalDate.now();
        LocalDate end = endDate != null ? endDate : LocalDate.now();

        List<Transaction> transactions = new ArrayList<>();
        LocalDate current = start;
        while (!current.isAfter(end)) {
            transactions.addAll(transactionRepository.findByBranchAndDate(effectiveBranch, current));
            current = current.plusDays(1);
        }

        BigDecimal totalHuf = transactions.stream()
                .filter(Transaction::isActive)
                .map(Transaction::getHufAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalFees = transactions.stream()
                .filter(Transaction::isActive)
                .map(Transaction::getHandlingFee)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("totalTransactions", transactions.size());
        summary.put("totalHufAmount", totalHuf);
        summary.put("totalFees", totalFees);
        summary.put("startDate", start);
        summary.put("endDate", end);

        List<Map<String, Object>> txList = transactions.stream().map(t -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", t.getId());
            m.put("receiptNumber", t.getReceiptNumber());
            m.put("transactionType", t.getTransactionType().name());
            m.put("transactionDate", t.getTransactionDate());
            m.put("transactionTime", t.getTransactionTime());
            m.put("currencyCode", t.getCurrency().getCode());
            m.put("currencyAmount", t.getCurrencyAmount());
            m.put("exchangeRate", t.getExchangeRate());
            m.put("hufAmount", t.getHufAmount());
            m.put("handlingFee", t.getHandlingFee());
            m.put("status", t.getStatus().name());
            m.put("customerName", t.getCustomerName());
            return m;
        }).collect(Collectors.toList());

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("transactions", txList);
        result.put("summary", summary);
        result.put("generatedAt", LocalDateTime.now());
        return result;
    }

    // ============ RECEIPT LIST ============

    public Map<String, Object> getReceiptList(UUID branchId, LocalDate startDate, LocalDate endDate) {
        UUID effectiveBranch = branchId != null ? branchId : SecurityUtils.getCurrentBranchId();
        LocalDate start = startDate != null ? startDate : LocalDate.now();
        LocalDate end = endDate != null ? endDate : LocalDate.now();

        List<Transaction> transactions = new ArrayList<>();
        LocalDate current = start;
        while (!current.isAfter(end)) {
            transactions.addAll(transactionRepository.findActiveByBranchAndDate(effectiveBranch, current));
            current = current.plusDays(1);
        }

        List<Map<String, Object>> receipts = transactions.stream().map(t -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("receiptNumber", t.getReceiptNumber());
            m.put("transactionType", t.getTransactionType().name());
            m.put("date", t.getTransactionDate());
            m.put("time", t.getTransactionTime());
            m.put("currencyCode", t.getCurrency().getCode());
            m.put("currencyAmount", t.getCurrencyAmount());
            m.put("hufAmount", t.getHufAmount());
            m.put("handlingFee", t.getHandlingFee());
            m.put("customerName", t.getCustomerName());
            m.put("printed", t.getPrinted());
            return m;
        }).collect(Collectors.toList());

        BigDecimal totalHuf = transactions.stream()
                .map(Transaction::getHufAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("totalReceipts", receipts.size());
        summary.put("totalHufAmount", totalHuf);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("receipts", receipts);
        result.put("summary", summary);
        result.put("generatedAt", LocalDateTime.now());
        return result;
    }

    // ============ FEE SUMMARY ============

    public Map<String, Object> getFeeSummary(UUID branchId, LocalDate startDate, LocalDate endDate) {
        UUID effectiveBranch = branchId != null ? branchId : SecurityUtils.getCurrentBranchId();
        LocalDate start = startDate != null ? startDate : LocalDate.now();
        LocalDate end = endDate != null ? endDate : LocalDate.now();

        List<Transaction> transactions = new ArrayList<>();
        LocalDate current = start;
        while (!current.isAfter(end)) {
            transactions.addAll(transactionRepository.findActiveByBranchAndDate(effectiveBranch, current));
            current = current.plusDays(1);
        }

        BigDecimal totalHandlingFees = transactions.stream()
                .map(Transaction::getHandlingFee)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalInitialFees = transactions.stream()
                .map(Transaction::getInitialFee)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalDiscounts = transactions.stream()
                .map(Transaction::getDiscountAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        long feeTransactionCount = transactions.stream()
                .filter(t -> t.getHandlingFee().compareTo(BigDecimal.ZERO) > 0)
                .count();

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("totalHandlingFees", totalHandlingFees);
        result.put("totalInitialFees", totalInitialFees);
        result.put("totalDiscounts", totalDiscounts);
        result.put("netFees", totalHandlingFees.subtract(totalDiscounts));
        result.put("feeTransactionCount", feeTransactionCount);
        result.put("totalTransactionCount", transactions.size());
        result.put("startDate", start);
        result.put("endDate", end);
        result.put("generatedAt", LocalDateTime.now());
        return result;
    }

    // ============ MONTHLY INVENTORY ============

    public Map<String, Object> getMonthlyInventory(int year, int month, UUID branchId) {
        UUID effectiveBranch = branchId != null ? branchId : SecurityUtils.getCurrentBranchId();

        List<CashBalance> balances = cashBalanceRepository.findByBranchId(effectiveBranch);
        List<Denomination> denominations = denominationRepository.findByBranchId(effectiveBranch);

        List<Map<String, Object>> balanceList = balances.stream().map(cb -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("currencyCode", cb.getCurrency().getCode());
            m.put("currencyName", cb.getCurrency().getName());
            m.put("currentBalance", cb.getCurrentBalance());
            m.put("openingBalance", cb.getOpeningBalance());
            return m;
        }).collect(Collectors.toList());

        BigDecimal totalDenominationValue = denominations.stream()
                .map(Denomination::getTotalValue)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("year", year);
        result.put("month", month);
        result.put("balances", balanceList);
        result.put("totalDenominationValue", totalDenominationValue);
        result.put("denominationCount", denominations.size());
        result.put("generatedAt", LocalDateTime.now());
        return result;
    }

    // ============ MONTHLY TURNOVER ============

    public Map<String, Object> getMonthlyTurnover(int year, int month, UUID branchId) {
        UUID effectiveBranch = branchId != null ? branchId : SecurityUtils.getCurrentBranchId();
        LocalDate start = LocalDate.of(year, month, 1);
        LocalDate end = start.withDayOfMonth(start.lengthOfMonth());

        List<Transaction> transactions = new ArrayList<>();
        LocalDate current = start;
        while (!current.isAfter(end)) {
            transactions.addAll(transactionRepository.findActiveByBranchAndDate(effectiveBranch, current));
            current = current.plusDays(1);
        }

        BigDecimal totalBuy = transactions.stream()
                .filter(t -> t.getTransactionType() == TransactionType.BUY)
                .map(Transaction::getHufAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalSell = transactions.stream()
                .filter(t -> t.getTransactionType() == TransactionType.SELL)
                .map(Transaction::getHufAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalFees = transactions.stream()
                .map(Transaction::getHandlingFee)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        long buyCount = transactions.stream()
                .filter(t -> t.getTransactionType() == TransactionType.BUY)
                .count();

        long sellCount = transactions.stream()
                .filter(t -> t.getTransactionType() == TransactionType.SELL)
                .count();

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("year", year);
        result.put("month", month);
        result.put("totalBuyHuf", totalBuy);
        result.put("totalSellHuf", totalSell);
        result.put("netTurnoverHuf", totalSell.subtract(totalBuy));
        result.put("totalFees", totalFees);
        result.put("buyCount", buyCount);
        result.put("sellCount", sellCount);
        result.put("totalTransactions", transactions.size());
        result.put("generatedAt", LocalDateTime.now());
        return result;
    }

    // ============ MONTHLY TRANSFERS ============

    public Map<String, Object> getMonthlyTransfers(int year, int month, UUID branchId) {
        UUID effectiveBranch = branchId != null ? branchId : SecurityUtils.getCurrentBranchId();

        // Transfers: find outgoing and incoming
        List<Transfer> outgoing = transferRepository.findOutgoingByBranch(effectiveBranch);
        List<Transfer> incoming = transferRepository.findIncomingByBranch(effectiveBranch);

        LocalDate start = LocalDate.of(year, month, 1);
        LocalDate end = start.withDayOfMonth(start.lengthOfMonth());

        List<Transfer> monthlyOutgoing = outgoing.stream()
                .filter(t -> !t.getTransferDate().isBefore(start) && !t.getTransferDate().isAfter(end))
                .collect(Collectors.toList());

        List<Transfer> monthlyIncoming = incoming.stream()
                .filter(t -> !t.getTransferDate().isBefore(start) && !t.getTransferDate().isAfter(end))
                .collect(Collectors.toList());

        BigDecimal outgoingTotal = monthlyOutgoing.stream()
                .map(Transfer::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal incomingTotal = monthlyIncoming.stream()
                .map(Transfer::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("year", year);
        result.put("month", month);
        result.put("outgoingCount", monthlyOutgoing.size());
        result.put("incomingCount", monthlyIncoming.size());
        result.put("outgoingTotal", outgoingTotal);
        result.put("incomingTotal", incomingTotal);
        result.put("netTransfer", incomingTotal.subtract(outgoingTotal));
        result.put("generatedAt", LocalDateTime.now());
        return result;
    }

    // ============ HANDLING COST ============

    public Map<String, Object> getHandlingCost(UUID branchId, LocalDate startDate, LocalDate endDate) {
        UUID effectiveBranch = branchId != null ? branchId : SecurityUtils.getCurrentBranchId();
        LocalDate start = startDate != null ? startDate : LocalDate.now();
        LocalDate end = endDate != null ? endDate : LocalDate.now();

        List<Transaction> transactions = new ArrayList<>();
        LocalDate current = start;
        while (!current.isAfter(end)) {
            transactions.addAll(transactionRepository.findActiveByBranchAndDate(effectiveBranch, current));
            current = current.plusDays(1);
        }

        // Group by handling fee type
        Map<String, BigDecimal> feeByType = transactions.stream()
                .filter(t -> t.getHandlingFeeType() != null)
                .collect(Collectors.groupingBy(
                        t -> t.getHandlingFeeType().name(),
                        Collectors.reducing(BigDecimal.ZERO, Transaction::getHandlingFee, BigDecimal::add)));

        BigDecimal totalFees = transactions.stream()
                .map(Transaction::getHandlingFee)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("totalHandlingCost", totalFees);
        result.put("feeByType", feeByType);
        result.put("transactionCount", transactions.size());
        result.put("startDate", start);
        result.put("endDate", end);
        result.put("generatedAt", LocalDateTime.now());
        return result;
    }

    // ============ DAILY CASH DESK ============

    public Map<String, Object> getDailyCashDesk(UUID cashDeskId, LocalDate date) {
        UUID effectiveBranch = cashDeskId != null ? cashDeskId : SecurityUtils.getCurrentBranchId();
        LocalDate reportDate = date != null ? date : LocalDate.now();

        List<Transaction> transactions = transactionRepository.findActiveByBranchAndDate(effectiveBranch, reportDate);
        List<CashBalance> balances = cashBalanceRepository.findByBranchId(effectiveBranch);

        BigDecimal totalBuy = transactions.stream()
                .filter(t -> t.getTransactionType() == TransactionType.BUY)
                .map(Transaction::getHufAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalSell = transactions.stream()
                .filter(t -> t.getTransactionType() == TransactionType.SELL)
                .map(Transaction::getHufAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalFees = transactions.stream()
                .map(Transaction::getHandlingFee)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        List<Map<String, Object>> balanceList = balances.stream().map(cb -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("currencyCode", cb.getCurrency().getCode());
            m.put("currentBalance", cb.getCurrentBalance());
            m.put("openingBalance", cb.getOpeningBalance());
            m.put("dailyChange", cb.getDailyChange());
            return m;
        }).collect(Collectors.toList());

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("cashDeskId", effectiveBranch);
        result.put("date", reportDate);
        result.put("transactionCount", transactions.size());
        result.put("totalBuyHuf", totalBuy);
        result.put("totalSellHuf", totalSell);
        result.put("totalFees", totalFees);
        result.put("balances", balanceList);
        result.put("generatedAt", LocalDateTime.now());
        return result;
    }

    // ============ CURRENT CASH DESK STATUS ============

    public Map<String, Object> getCurrentCashDeskStatus(UUID cashDeskId) {
        UUID effectiveBranch = cashDeskId != null ? cashDeskId : SecurityUtils.getCurrentBranchId();

        List<CashBalance> balances = cashBalanceRepository.findByBranchId(effectiveBranch);
        List<Denomination> denominations = denominationRepository.findByBranchId(effectiveBranch);

        List<Map<String, Object>> balanceList = balances.stream().map(cb -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("currencyCode", cb.getCurrency().getCode());
            m.put("currencyName", cb.getCurrency().getName());
            m.put("currentBalance", cb.getCurrentBalance());
            m.put("openingBalance", cb.getOpeningBalance());
            m.put("minBalance", cb.getMinBalance());
            m.put("maxBalance", cb.getMaxBalance());
            m.put("isLow", cb.isLowBalance());
            m.put("isHigh", cb.isHighBalance());
            return m;
        }).collect(Collectors.toList());

        BigDecimal totalDenominationValue = denominations.stream()
                .map(Denomination::getTotalValue)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("cashDeskId", effectiveBranch);
        result.put("balances", balanceList);
        result.put("totalCurrencies", balances.size());
        result.put("denominationTotalValue", totalDenominationValue);
        result.put("generatedAt", LocalDateTime.now());
        return result;
    }

    // ============ SUSPICIOUS TRANSACTIONS ============

    public List<Map<String, Object>> getSuspiciousTransactions(UUID branchId, LocalDate startDate, LocalDate endDate) {
        UUID effectiveBranch = branchId != null ? branchId : SecurityUtils.getCurrentBranchId();
        LocalDate start = startDate != null ? startDate : LocalDate.now().minusDays(30);
        LocalDate end = endDate != null ? endDate : LocalDate.now();

        List<Transaction> transactions = new ArrayList<>();
        LocalDate current = start;
        while (!current.isAfter(end)) {
            transactions.addAll(transactionRepository.findByBranchAndDate(effectiveBranch, current));
            current = current.plusDays(1);
        }

        // Filter AML suspicious
        return transactions.stream()
                .filter(t -> Boolean.TRUE.equals(t.getAmlSuspicious()) || Boolean.TRUE.equals(t.getAmlAnnualLimitReached()))
                .map(t -> {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("id", t.getId());
                    m.put("receiptNumber", t.getReceiptNumber());
                    m.put("transactionType", t.getTransactionType().name());
                    m.put("transactionDate", t.getTransactionDate());
                    m.put("hufAmount", t.getHufAmount());
                    m.put("currencyCode", t.getCurrency().getCode());
                    m.put("currencyAmount", t.getCurrencyAmount());
                    m.put("customerName", t.getCustomerName());
                    m.put("customerId", t.getCustomerId());
                    m.put("amlSuspicious", t.getAmlSuspicious());
                    m.put("amlAnnualLimitReached", t.getAmlAnnualLimitReached());
                    return m;
                })
                .collect(Collectors.toList());
    }

    // ============ CARD TRANSACTION FEES ============

    public Map<String, Object> getCardTransactionFees(UUID branchId, LocalDate startDate, LocalDate endDate) {
        UUID effectiveBranch = branchId != null ? branchId : SecurityUtils.getCurrentBranchId();
        LocalDate start = startDate != null ? startDate : LocalDate.now();
        LocalDate end = endDate != null ? endDate : LocalDate.now();

        // Card transactions: use handling fee type or reference to identify card transactions
        List<Transaction> transactions = new ArrayList<>();
        LocalDate current = start;
        while (!current.isAfter(end)) {
            transactions.addAll(transactionRepository.findActiveByBranchAndDate(effectiveBranch, current));
            current = current.plusDays(1);
        }

        // Filter transactions that have reference numbers (card/POS transactions)
        List<Transaction> cardTransactions = transactions.stream()
                .filter(t -> t.getReferenceNumber() != null && !t.getReferenceNumber().isEmpty())
                .collect(Collectors.toList());

        BigDecimal totalCardFees = cardTransactions.stream()
                .map(Transaction::getHandlingFee)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalCardAmount = cardTransactions.stream()
                .map(Transaction::getHufAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("totalCardTransactions", cardTransactions.size());
        result.put("totalCardFees", totalCardFees);
        result.put("totalCardAmount", totalCardAmount);
        result.put("startDate", start);
        result.put("endDate", end);
        result.put("generatedAt", LocalDateTime.now());
        return result;
    }
}
