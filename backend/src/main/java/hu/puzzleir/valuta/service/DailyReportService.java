package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.dto.report.DailyReportDto;
import hu.puzzleir.valuta.dto.treasury.SubmissionStatusDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
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
 * Napi jelentés service.
 *
 * Legacy: napijel.dll — napi forgalmi adatok összesítése és beküldése.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DailyReportService {

    private final DailyReportRepository dailyReportRepository;
    private final TransactionRepository transactionRepository;
    private final BranchRepository branchRepository;
    private final WorkerRepository workerRepository;

    /**
     * Napi riport generálás a Transaction-ökből.
     */
    @Transactional
    public DailyReportDto generateReport(UUID branchId, LocalDate date) {
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));

        // Ha már létezik, felülírjuk
        DailyReport report = dailyReportRepository.findByBranchIdAndReportDate(branchId, date)
                .orElse(DailyReport.builder()
                        .branch(branch)
                        .reportDate(date)
                        .build());

        // Tranzakciók összesítése
        List<Transaction> transactions = transactionRepository.findActiveByBranchAndDate(branchId, date);

        BigDecimal totalBuyHuf = BigDecimal.ZERO;
        BigDecimal totalSellHuf = BigDecimal.ZERO;
        BigDecimal totalFeeHuf = BigDecimal.ZERO;

        for (Transaction t : transactions) {
            if (t.getTransactionType() == null) {
                log.warn("Transaction {} típus null — kihagyva a napi riportból", t.getId());
                continue;
            }
            if (t.getTransactionType().isBuyType()) {
                totalBuyHuf = totalBuyHuf.add(
                        t.getHufAmount() != null ? t.getHufAmount() : BigDecimal.ZERO);
            } else if (t.getTransactionType().isSellType()) {
                totalSellHuf = totalSellHuf.add(
                        t.getHufAmount() != null ? t.getHufAmount() : BigDecimal.ZERO);
            }
            totalFeeHuf = totalFeeHuf.add(
                    t.getHandlingFee() != null ? t.getHandlingFee() : BigDecimal.ZERO);
        }

        BigDecimal totalProfit = totalSellHuf.subtract(totalBuyHuf).add(totalFeeHuf)
                .setScale(2, RoundingMode.HALF_UP);

        report.setTotalBuyHuf(totalBuyHuf.setScale(2, RoundingMode.HALF_UP));
        report.setTotalSellHuf(totalSellHuf.setScale(2, RoundingMode.HALF_UP));
        report.setTotalFeeHuf(totalFeeHuf.setScale(2, RoundingMode.HALF_UP));
        report.setTotalProfit(totalProfit);
        report.setTransactionCount(transactions.size());
        report.setReportData(buildReportDataJson(transactions));

        report = dailyReportRepository.save(report);
        return toDto(report);
    }

    /**
     * Jelentés beküldés (submitted=true).
     */
    @Transactional
    public DailyReportDto submitReport(Long reportId, Long workerId) {
        DailyReport report = dailyReportRepository.findById(reportId)
                .orElseThrow(() -> new ResourceNotFoundException("Jelentés nem található: " + reportId));

        if (Boolean.TRUE.equals(report.getSubmitted())) {
            throw new ValidationException("A jelentés már be lett küldve!");
        }

        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Dolgozó nem található: " + workerId));

        report.setSubmitted(true);
        report.setSubmittedAt(LocalDateTime.now());
        report.setSubmittedBy(worker);

        report = dailyReportRepository.save(report);
        return toDto(report);
    }

    /**
     * Jelentés lekérdezés.
     */
    @Transactional(readOnly = true)
    public DailyReportDto getReport(UUID branchId, LocalDate date) {
        DailyReport report = dailyReportRepository.findByBranchIdAndReportDate(branchId, date)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Jelentés nem található: branchId=" + branchId + ", date=" + date));
        return toDto(report);
    }

    /**
     * Mely irodák küldték be a napi jelentést.
     */
    @Transactional(readOnly = true)
    public List<SubmissionStatusDto> getSubmissionStatus(LocalDate date) {
        List<Branch> activeBranches = branchRepository.findByIsActiveTrue();
        List<DailyReport> reports = dailyReportRepository.findAllByReportDate(date);

        Map<String, DailyReport> reportMap = reports.stream()
                .collect(Collectors.toMap(
                        r -> r.getBranch().getId().toString(),
                        r -> r,
                        (a, b) -> a));

        return activeBranches.stream()
                .map(branch -> {
                    DailyReport report = reportMap.get(branch.getId().toString());
                    return SubmissionStatusDto.builder()
                            .branchId(branch.getId().toString())
                            .branchCode(branch.getCode())
                            .branchName(branch.getName())
                            .submitted(report != null && Boolean.TRUE.equals(report.getSubmitted()))
                            .submittedAt(report != null && report.getSubmittedAt() != null
                                    ? report.getSubmittedAt().toString() : null)
                            .build();
                })
                .collect(Collectors.toList());
    }

    // ============ HELPERS ============

    private String buildReportDataJson(List<Transaction> transactions) {
        // Egyszerű JSON összesítés valutánként
        Map<String, Map<String, BigDecimal>> byCurrency = new LinkedHashMap<>();
        for (Transaction t : transactions) {
            if (t.getTransactionType() == null) {
                log.warn("Transaction {} típus null — kihagyva a report JSON-ból", t.getId());
                continue;
            }
            String code = t.getCurrency().getCode();
            Map<String, BigDecimal> totals = byCurrency.computeIfAbsent(code,
                    k -> new LinkedHashMap<>());
            if (t.getTransactionType().isBuyType()) {
                totals.merge("buy", t.getCurrencyAmount(), BigDecimal::add);
                totals.merge("buyHuf", t.getHufAmount(), BigDecimal::add);
            } else if (t.getTransactionType().isSellType()) {
                totals.merge("sell", t.getCurrencyAmount(), BigDecimal::add);
                totals.merge("sellHuf", t.getHufAmount(), BigDecimal::add);
            }
            totals.merge("fee", t.getHandlingFee() != null ? t.getHandlingFee() : BigDecimal.ZERO,
                    BigDecimal::add);
        }

        // Egyszerű JSON string építés (nem Jackson, mert nem garantált a classpath-on)
        StringBuilder sb = new StringBuilder("{");
        boolean first = true;
        for (Map.Entry<String, Map<String, BigDecimal>> entry : byCurrency.entrySet()) {
            if (!first) sb.append(",");
            sb.append("\"").append(entry.getKey()).append("\":{");
            boolean innerFirst = true;
            for (Map.Entry<String, BigDecimal> inner : entry.getValue().entrySet()) {
                if (!innerFirst) sb.append(",");
                sb.append("\"").append(inner.getKey()).append("\":")
                        .append(inner.getValue().setScale(2, RoundingMode.HALF_UP));
                innerFirst = false;
            }
            sb.append("}");
            first = false;
        }
        sb.append("}");
        return sb.toString();
    }

    private DailyReportDto toDto(DailyReport r) {
        return DailyReportDto.builder()
                .id(r.getId())
                .branchId(r.getBranch().getId().toString())
                .branchCode(r.getBranch().getCode())
                .branchName(r.getBranch().getName())
                .reportDate(r.getReportDate().toString())
                .submitted(r.getSubmitted())
                .submittedAt(r.getSubmittedAt() != null ? r.getSubmittedAt().toString() : null)
                .submittedById(r.getSubmittedBy() != null ? r.getSubmittedBy().getId() : null)
                .submittedByName(r.getSubmittedBy() != null ? r.getSubmittedBy().getName() : null)
                .reportData(r.getReportData())
                .totalBuyHuf(r.getTotalBuyHuf())
                .totalSellHuf(r.getTotalSellHuf())
                .totalFeeHuf(r.getTotalFeeHuf())
                .totalProfit(r.getTotalProfit())
                .transactionCount(r.getTransactionCount())
                .createdAt(r.getCreatedAt() != null ? r.getCreatedAt().toString() : null)
                .build();
    }
}
