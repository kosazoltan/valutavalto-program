package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.central.CentralReceivedDataOverviewDto;
import hu.puzzleir.valuta.dto.central.CentralReceivedDataRowDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.ClosingControl;
import hu.puzzleir.valuta.entity.DailyReport;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.ClosingControlRepository;
import hu.puzzleir.valuta.repository.DailyReportRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class CentralReceivedDataService {

    private final BranchRepository branchRepository;
    private final DailyReportRepository dailyReportRepository;
    private final ClosingControlRepository closingControlRepository;

    public CentralReceivedDataOverviewDto getOverview(LocalDate date) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        LocalDate reportDate = date != null ? date : LocalDate.now();
        log.info("Central received data overview: company={}, date={}", companyId, reportDate);

        Map<UUID, DailyReport> reportsByBranch = dailyReportRepository
                .findByCompanyIdAndReportDate(companyId, reportDate)
                .stream()
                .collect(Collectors.toMap(report -> report.getBranch().getId(), report -> report, (left, right) -> left));

        Map<UUID, ClosingControl> controlsByBranch = closingControlRepository
                .findByCompanyIdAndControlDate(companyId, reportDate)
                .stream()
                .collect(Collectors.toMap(ClosingControl::getBranchId, control -> control, (left, right) -> left));

        List<CentralReceivedDataRowDto> rows = branchRepository.findByCompanyIdAndIsActiveTrue(companyId)
                .stream()
                .sorted(Comparator.comparing(Branch::getCode, Comparator.nullsLast(String::compareToIgnoreCase)))
                .map(branch -> toRow(branch, reportsByBranch.get(branch.getId()), controlsByBranch.get(branch.getId()), reportDate))
                .collect(Collectors.toList());

        return CentralReceivedDataOverviewDto.builder()
                .reportDate(reportDate)
                .totalBranches(rows.size())
                .receivedReports((int) rows.stream().filter(row -> Boolean.TRUE.equals(row.getReportReceived())).count())
                .submittedReports((int) rows.stream().filter(row -> Boolean.TRUE.equals(row.getReportSubmitted())).count())
                .missingReports((int) rows.stream().filter(row -> !Boolean.TRUE.equals(row.getReportReceived())).count())
                .warningClosings((int) rows.stream().filter(row -> "WARNING".equals(row.getClosingAlertLevel())).count())
                .criticalClosings((int) rows.stream().filter(row -> "CRITICAL".equals(row.getClosingAlertLevel())).count())
                .totalTransactions(rows.stream()
                        .map(CentralReceivedDataRowDto::getTransactionCount)
                        .map(value -> value != null ? value : 0)
                        .reduce(0, Integer::sum))
                .totalBuyHuf(sum(rows, CentralReceivedDataRowDto::getTotalBuyHuf))
                .totalSellHuf(sum(rows, CentralReceivedDataRowDto::getTotalSellHuf))
                .totalFeeHuf(sum(rows, CentralReceivedDataRowDto::getTotalFeeHuf))
                .totalProfit(sum(rows, CentralReceivedDataRowDto::getTotalProfit))
                .generatedAt(LocalDateTime.now())
                .lastSyncedAt(computeLastSyncedAt(rows))
                .rows(rows)
                .build();
    }

    /**
     * A legfrissebb átvett branch-adat időpontja: soronként submittedAt elsőbbség, fallback
     * reportCreatedAt; csak az átvett (reportReceived) sorok számítanak. null, ha egyik sem érkezett.
     */
    private LocalDateTime computeLastSyncedAt(List<CentralReceivedDataRowDto> rows) {
        return rows.stream()
                .filter(row -> Boolean.TRUE.equals(row.getReportReceived()))
                .map(row -> row.getSubmittedAt() != null ? row.getSubmittedAt() : row.getReportCreatedAt())
                .filter(java.util.Objects::nonNull)
                .max(LocalDateTime::compareTo)
                .orElse(null);
    }

    private CentralReceivedDataRowDto toRow(Branch branch, DailyReport report, ClosingControl control, LocalDate reportDate) {
        boolean reportReceived = report != null;
        boolean submitted = reportReceived && Boolean.TRUE.equals(report.getSubmitted());
        String closingAlert = resolveClosingAlert(control, reportDate);

        return CentralReceivedDataRowDto.builder()
                .branchId(branch.getId())
                .branchCode(branch.getCode())
                .branchName(branch.getName())
                .branchCity(branch.getCity())
                .reportDate(reportDate)
                .dataStatus(resolveDataStatus(reportReceived, submitted, closingAlert, reportDate))
                .dailyReportId(reportReceived ? report.getId() : null)
                .reportReceived(reportReceived)
                .reportSubmitted(submitted)
                .reportCreatedAt(reportReceived ? report.getCreatedAt() : null)
                .submittedAt(reportReceived ? report.getSubmittedAt() : null)
                .submittedByName(reportReceived && report.getSubmittedBy() != null ? report.getSubmittedBy().getName() : null)
                .transactionCount(reportReceived ? safeInt(report.getTransactionCount()) : 0)
                .totalBuyHuf(reportReceived ? safe(report.getTotalBuyHuf()) : BigDecimal.ZERO)
                .totalSellHuf(reportReceived ? safe(report.getTotalSellHuf()) : BigDecimal.ZERO)
                .totalFeeHuf(reportReceived ? safe(report.getTotalFeeHuf()) : BigDecimal.ZERO)
                .totalProfit(reportReceived ? safe(report.getTotalProfit()) : BigDecimal.ZERO)
                .dailyClosingDone(control != null && Boolean.TRUE.equals(control.getDailyClosingDone()))
                .eveningClosingDone(control != null && Boolean.TRUE.equals(control.getEveningClosingDone()))
                .navClosingDone(control != null && Boolean.TRUE.equals(control.getNavClosingDone()))
                .closingAlertLevel(closingAlert)
                .closingControlMissing(control == null)
                .notes(control != null ? control.getNotes() : null)
                .build();
    }

    private String resolveDataStatus(boolean reportReceived, boolean submitted, String closingAlert, LocalDate reportDate) {
        if ("CRITICAL".equals(closingAlert)) {
            return "CRITICAL";
        }
        if (!reportReceived && reportDate.isBefore(LocalDate.now())) {
            return "MISSING";
        }
        if (submitted) {
            return "SUBMITTED";
        }
        if (reportReceived) {
            return "RECEIVED";
        }
        return "WAITING";
    }

    private String resolveClosingAlert(ClosingControl control, LocalDate reportDate) {
        if (control != null && control.getAlertLevel() != null && !"NONE".equalsIgnoreCase(control.getAlertLevel())) {
            return control.getAlertLevel();
        }
        if (control == null) {
            return reportDate.isBefore(LocalDate.now()) ? "CRITICAL" : "WARNING";
        }
        // FK-087 FR-1 (FK-062 minta): a zárási varázsló az értéktári fiókoknál az evening/nav
        // jelzőket nem írja, ezért CSAK a napi zárás számít teljesnek — lásd
        // ClosingControlService.isRequiredClosingDone (FK-062), ami szintén dailyDone-only.
        boolean complete = Boolean.TRUE.equals(control.getDailyClosingDone());
        if (complete) {
            return "NONE";
        }
        return reportDate.isBefore(LocalDate.now()) ? "CRITICAL" : "WARNING";
    }

    private BigDecimal safe(BigDecimal value) {
        return value != null ? value : BigDecimal.ZERO;
    }

    private int safeInt(Integer value) {
        return value != null ? value : 0;
    }

    private BigDecimal sum(List<CentralReceivedDataRowDto> rows, java.util.function.Function<CentralReceivedDataRowDto, BigDecimal> getter) {
        return rows.stream()
                .map(getter)
                .map(this::safe)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }
}
