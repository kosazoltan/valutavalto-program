package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.report.DailyReportDto;
import hu.puzzleir.valuta.dto.treasury.SubmissionStatusDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.DailyReport;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.DailyReportRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Napi riport specializalt szolgaltatas.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class DailyReportService {

    private final ReportService reportService;
    private final DailyReportRepository dailyReportRepository;
    private final BranchRepository branchRepository;
    private final WorkerRepository workerRepository;

    /**
     * Napi zaras riport lekerese (ReportService-bol).
     */
    public ReportService.DailyClosingReport generateDailyClosingReport(LocalDate date) {
        return reportService.generateDailyClosingReport(date);
    }

    /**
     * Napi jelentes lekerese iroda + datum alapjan.
     */
    public DailyReportDto getReport(UUID branchId, LocalDate date) {
        DailyReport report = dailyReportRepository.findByBranchIdAndReportDate(branchId, date)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Napi jelentes nem talalhato: " + branchId + " / " + date));
        return toDto(report);
    }

    /**
     * Napi jelentes generalasa (ha meg nincs, letrehozza).
     */
    @Transactional(rollbackFor = Exception.class)
    public DailyReportDto generateReport(UUID branchId, LocalDate date) {
        DailyReport existing = dailyReportRepository.findByBranchIdAndReportDate(branchId, date)
                .orElse(null);
        if (existing != null) {
            return toDto(existing);
        }

        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem talalhato: " + branchId));

        DailyReport report = DailyReport.builder()
                .branch(branch)
                .reportDate(date)
                .submitted(false)
                .build();

        DailyReport saved = dailyReportRepository.save(report);
        log.info("Napi jelentes generalva: branch={}, date={}", branchId, date);
        return toDto(saved);
    }

    /**
     * Napi jelentes bekuldese (lezarasa).
     */
    @Transactional(rollbackFor = Exception.class)
    public DailyReportDto submitReport(Long reportId, Long workerId) {
        DailyReport report = dailyReportRepository.findById(reportId)
                .orElseThrow(() -> new ResourceNotFoundException("Napi jelentes nem talalhato: " + reportId));

        if (Boolean.TRUE.equals(report.getSubmitted())) {
            throw new BusinessException("A napi jelentes mar be van kuldve", "REPORT_ALREADY_SUBMITTED");
        }

        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Dolgozo nem talalhato: " + workerId));

        report.setSubmitted(true);
        report.setSubmittedAt(LocalDateTime.now());
        report.setSubmittedBy(worker);

        DailyReport saved = dailyReportRepository.save(report);
        log.info("Napi jelentes bekuldve: reportId={}, workerId={}", reportId, workerId);
        return toDto(saved);
    }

    /**
     * Bekuldesi statusz lekerese (osszes iroda, adott datum).
     */
    public List<SubmissionStatusDto> getSubmissionStatus(LocalDate date) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<DailyReport> reports = dailyReportRepository.findByCompanyIdAndReportDate(companyId, date);

        return reports.stream()
                .map(r -> SubmissionStatusDto.builder()
                        .branchId(r.getBranch().getId().toString())
                        .branchCode(r.getBranch().getCode())
                        .branchName(r.getBranch().getName())
                        .submitted(r.getSubmitted())
                        .submittedAt(r.getSubmittedAt() != null ? r.getSubmittedAt().toString() : null)
                        .build())
                .collect(Collectors.toList());
    }

    // ============ HELPER ============

    private DailyReportDto toDto(DailyReport report) {
        return DailyReportDto.builder()
                .id(report.getId())
                .branchId(report.getBranch().getId().toString())
                .branchCode(report.getBranch().getCode())
                .branchName(report.getBranch().getName())
                .reportDate(report.getReportDate().toString())
                .submitted(report.getSubmitted())
                .submittedAt(report.getSubmittedAt() != null ? report.getSubmittedAt().toString() : null)
                .submittedById(report.getSubmittedBy() != null ? report.getSubmittedBy().getId() : null)
                .submittedByName(report.getSubmittedBy() != null ? report.getSubmittedBy().getName() : null)
                .reportData(report.getReportData())
                .totalBuyHuf(report.getTotalBuyHuf())
                .totalSellHuf(report.getTotalSellHuf())
                .totalFeeHuf(report.getTotalFeeHuf())
                .totalProfit(report.getTotalProfit())
                .transactionCount(report.getTransactionCount())
                .createdAt(report.getCreatedAt() != null ? report.getCreatedAt().toString() : null)
                .build();
    }
}
