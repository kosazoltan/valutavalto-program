package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.dto.decade.DecadeReportDto;
import hu.puzzleir.valuta.entity.DecadeReport;
import hu.puzzleir.valuta.entity.DecadeReport.DecadeReportStatus;
import hu.puzzleir.valuta.repository.DecadeReportRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.YearMonth;
import java.util.UUID;

/**
 * Dekádjelentés szolgáltatás.
 * Dekád = 10 napos időszak: 1-10, 11-20, 21-hó vége.
 * Évenként max 36 dekád.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DecadeReportService {

    private final DecadeReportRepository decadeReportRepository;
    private final TransactionRepository transactionRepository;
    private final BranchRepository branchRepository;

    /**
     * Dekádjelentés generálása. Összesíti az adott 10 napos időszak tranzakcióit.
     */
    @Transactional
    public DecadeReportDto generateDecadeReport(UUID branchId, int year, int decade) {
        if (decade < 1 || decade > 36) {
            throw new ValidationException("Érvénytelen dekád: " + decade + " (1-36 között kell legyen)");
        }

        Branch branch = branchRepository.findById(branchId)
            .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));

        // Időszak kiszámítása a dekád számból
        LocalDate[] period = calculateDecadePeriod(year, decade);
        LocalDateTime from = period[0].atStartOfDay();
        LocalDateTime to = period[1].atTime(LocalTime.MAX);

        // Meglévő ellenőrzés
        DecadeReport existing = decadeReportRepository
            .findByBranchIdAndYearAndDecade(branchId, year, decade)
            .orElse(null);

        if (existing != null && existing.getStatus() == DecadeReportStatus.CLOSED) {
            throw new ValidationException("Ez a dekádjelentés már le van zárva.");
        }

        // Összesítés a tranzakciókból
        BigDecimal totalBuy = transactionRepository.sumHufAmountByBranchAndTypeAndPeriod(
            branchId, "BUY", from, to);
        BigDecimal totalSell = transactionRepository.sumHufAmountByBranchAndTypeAndPeriod(
            branchId, "SELL", from, to);
        BigDecimal totalFee = transactionRepository.sumFeeByBranchAndPeriod(branchId, from, to);
        long txCount = transactionRepository.countByBranchAndPeriod(branchId, from, to);

        DecadeReport report;
        if (existing != null) {
            report = existing;
        } else {
            report = DecadeReport.builder()
                .branch(branch)
                .year(year)
                .decade(decade)
                .build();
        }

        report.setTotalBuyHuf(totalBuy != null ? totalBuy : BigDecimal.ZERO);
        report.setTotalSellHuf(totalSell != null ? totalSell : BigDecimal.ZERO);
        report.setTotalHandlingFee(totalFee != null ? totalFee : BigDecimal.ZERO);
        report.setTransactionCount((int) txCount);
        report.setStatus(DecadeReportStatus.DRAFT);

        report = decadeReportRepository.save(report);
        log.info("Dekádjelentés generálva: branch={}, year={}, decade={}, txCount={}",
            branchId, year, decade, txCount);

        return toDto(report);
    }

    /**
     * Dekád véglegesítése (CLOSED státusz).
     */
    @Transactional
    public DecadeReportDto closeDecade(UUID reportId) {
        DecadeReport report = decadeReportRepository.findById(reportId)
            .orElseThrow(() -> new ResourceNotFoundException("Dekádjelentés nem található: " + reportId));

        if (report.getStatus() == DecadeReportStatus.CLOSED) {
            throw new ValidationException("Ez a dekádjelentés már le van zárva.");
        }

        report.setStatus(DecadeReportStatus.CLOSED);
        report.setClosedAt(LocalDateTime.now());
        report = decadeReportRepository.save(report);

        log.info("Dekádjelentés lezárva: id={}", reportId);
        return toDto(report);
    }

    /**
     * Dekádjelentések lekérdezése iroda és év szerint.
     */
    @Transactional(readOnly = true)
    public Page<DecadeReportDto> getDecadeReports(UUID branchId, int year, int page, int size) {
        return decadeReportRepository
            .findByBranchIdAndYear(branchId, year, PageRequest.of(page, size, Sort.by("decade")))
            .map(this::toDto);
    }

    // ============ HELPER ============

    /**
     * Dekád időszak kiszámítása.
     * Dekád 1-3: január 1-10, 11-20, 21-31
     * Dekád 4-6: február 1-10, 11-20, 21-28/29
     * stb.
     */
    private LocalDate[] calculateDecadePeriod(int year, int decade) {
        int month = ((decade - 1) / 3) + 1; // 1-12
        int decadeInMonth = ((decade - 1) % 3) + 1; // 1-3

        LocalDate start;
        LocalDate end;

        switch (decadeInMonth) {
            case 1:
                start = LocalDate.of(year, month, 1);
                end = LocalDate.of(year, month, 10);
                break;
            case 2:
                start = LocalDate.of(year, month, 11);
                end = LocalDate.of(year, month, 20);
                break;
            case 3:
                start = LocalDate.of(year, month, 21);
                end = YearMonth.of(year, month).atEndOfMonth();
                break;
            default:
                throw new ValidationException("Érvénytelen dekád: " + decade);
        }

        return new LocalDate[]{start, end};
    }

    private DecadeReportDto toDto(DecadeReport entity) {
        return DecadeReportDto.builder()
            .id(entity.getId())
            .branchId(entity.getBranch().getId())
            .year(entity.getYear())
            .decade(entity.getDecade())
            .totalBuyHuf(entity.getTotalBuyHuf())
            .totalSellHuf(entity.getTotalSellHuf())
            .totalHandlingFee(entity.getTotalHandlingFee())
            .transactionCount(entity.getTransactionCount())
            .status(entity.getStatus().name())
            .closedAt(entity.getClosedAt())
            .closedBy(entity.getClosedBy())
            .createdAt(entity.getCreatedAt())
            .build();
    }
}
