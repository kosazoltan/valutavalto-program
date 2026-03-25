package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.dto.dashboard.DashboardSummaryDto;
import hu.puzzleir.valuta.entity.Notification;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.repository.NotificationRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Dashboard service — admin összesítő.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class DashboardService {

    private static final int TOP_CUSTOMERS_LIMIT = 10;

    private final TransactionRepository transactionRepository;
    private final BranchRepository branchRepository;
    private final NotificationRepository notificationRepository;

    public DashboardSummaryDto getSummary(UUID branchId) {
        UUID effectiveBranch = branchId != null ? branchId : SecurityUtils.getCurrentBranchId();

        // Mai tranzakciók
        List<Transaction> todayTx = transactionRepository.findActiveByBranchAndDate(effectiveBranch, LocalDate.now());

        // Mai forgalom
        BigDecimal todayVolume = todayTx.stream()
                .map(t -> t.getHufAmount() != null ? t.getHufAmount() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Aktív irodák száma
        List<Branch> activeBranches = branchRepository.findByIsActiveTrue();
        int activeBranchCount = activeBranches.size();

        // Nyitott tranzakciók (mai)
        int openTx = todayTx.size();

        // Riasztások (olvasatlan értesítések)
        String userId = String.valueOf(SecurityUtils.getCurrentWorkerId());
        int alertCount = notificationRepository.findByUserIdAndIsReadFalseOrderByCreatedAtDesc(userId).size();

        // Valutánkénti forgalom
        Map<String, BigDecimal> currencyVolumes = todayTx.stream()
                .filter(t -> t.getCurrency() != null)
                .collect(Collectors.groupingBy(
                        t -> t.getCurrency().getCode(),
                        Collectors.mapping(
                                t -> t.getHufAmount() != null ? t.getHufAmount() : BigDecimal.ZERO,
                                Collectors.reducing(BigDecimal.ZERO, BigDecimal::add)
                        )
                ));

        // Utolsó 10 tranzakció
        List<DashboardSummaryDto.RecentTransactionDto> recent = todayTx.stream()
                .sorted(Comparator.comparing(Transaction::getCreatedAt, Comparator.nullsLast(Comparator.reverseOrder())))
                .limit(TOP_CUSTOMERS_LIMIT)
                .map(t -> DashboardSummaryDto.RecentTransactionDto.builder()
                        .id(t.getId())
                        .receiptNumber(t.getReceiptNumber())
                        .type(t.getTransactionType() != null ? t.getTransactionType().name() : "")
                        .currencyCode(t.getCurrency() != null ? t.getCurrency().getCode() : "")
                        .amount(t.getCurrencyAmount())
                        .hufAmount(t.getHufAmount())
                        .cashierName(t.getWorker() != null ? t.getWorker().getName() : "")
                        .createdAt(t.getCreatedAt() != null ? t.getCreatedAt().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME) : "")
                        .build())
                .collect(Collectors.toList());

        // Branch sync status (simplified)
        List<DashboardSummaryDto.BranchSyncStatusDto> branchStatuses = activeBranches.stream()
                .limit(20)
                .map(b -> DashboardSummaryDto.BranchSyncStatusDto.builder()
                        .branchCode(b.getCode())
                        .branchName(b.getName())
                        .lastSyncAt("")
                        .status("OK")
                        .build())
                .collect(Collectors.toList());

        return DashboardSummaryDto.builder()
                .todayVolume(todayVolume)
                .activeBranches(activeBranchCount)
                .openTransactions(openTx)
                .alertCount(alertCount)
                .currencyVolumes(currencyVolumes)
                .recentTransactions(recent)
                .branchSyncStatuses(branchStatuses)
                .build();
    }
}
