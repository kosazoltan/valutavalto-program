package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.handlingfee.HandlingFeeDecadeReportDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.DecadeReport.DecadeReportStatus;
import hu.puzzleir.valuta.entity.HandlingFeeDecadeReport;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.PaymentMethod;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.HandlingFeeDecadeReportRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
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
import java.time.YearMonth;
import java.util.List;
import java.util.UUID;

/**
 * Kezelési díj dekád összesítő szolgáltatás.
 *
 * Legacy: KEZDEKAD.DLL — Unit2.pas
 * - NAPIKEZELESIDIJ tábla: nyitó egyenleg (ZARO mező)
 * - KEZD* havi táblák: kezelési díj rekordok tranzakciónként
 * - KEZDIJSORSZAM: EV, HONAP, DEKAD, UTOLSOSORSZAM (sorszámozás)
 * - DekadSzamitas: SUM(KEZELESIDIJ) WHERE STORNO=1 AND (TIPUS='V' OR TIPUS='E')
 * - Bankkártyás elkülönítés: FIZETOESZKOZ=2
 * - PRINTCONTROL: KEZDIJPRINT flag
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class HandlingFeeDecadeService {

    private final HandlingFeeDecadeReportRepository reportRepository;
    private final TransactionRepository transactionRepository;
    private final BranchRepository branchRepository;

    /**
     * Kezelési díj dekád összesítő generálása.
     *
     * Legacy logika (DekadSzamitas):
     * 1. Nyitó egyenleg = előző dekád záró (NAPIKEZELESIDIJ.ZARO)
     * 2. Vétel díjak összesítése (TIPUS='V', nem sztornó)
     * 3. Eladás díjak összesítése (TIPUS='E', nem sztornó)
     * 4. Bankkártyás/készpénzes szétválasztás (FIZETOESZKOZ)
     * 5. Záró = nyitó + összDíj
     * 6. Sorszámozás (KEZDIJSORSZAM)
     */
    @Transactional
    public HandlingFeeDecadeReportDto generateReport(UUID branchId, int year, int decade) {
        if (decade < 1 || decade > 36) {
            throw new ValidationException("Érvénytelen dekád: " + decade + " (1-36 között kell legyen)");
        }

        // IDOR védelem
        Branch branch = branchRepository.findById(branchId)
            .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));
        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        if (!branch.getCompany().getId().equals(currentCompanyId)) {
            throw new ValidationException("Nincs jogosultság más cég irodájának kezelési díj jelentéséhez!");
        }

        // Időszak kiszámítása
        LocalDate[] period = calculateDecadePeriod(year, decade);
        LocalDate periodStart = period[0];
        LocalDate periodEnd = period[1];

        // Meglévő ellenőrzés
        HandlingFeeDecadeReport existing = reportRepository
            .findByBranchIdAndYearAndDecade(branchId, year, decade)
            .orElse(null);

        if (existing != null && existing.getStatus() == DecadeReportStatus.CLOSED) {
            throw new ValidationException("Ez a kezelési díj dekádjelentés már le van zárva.");
        }

        // Tranzakciók lekérdezése a dekád időszakára — csak aktív (nem sztornózott)
        List<Transaction> transactions = transactionRepository
            .findActiveByBranchAndDateRange(branchId, periodStart, periodEnd);

        // === LEGACY: DekadSzamitas — díjak összesítése ===
        BigDecimal totalBuyFee = BigDecimal.ZERO;
        BigDecimal totalSellFee = BigDecimal.ZERO;
        BigDecimal totalCardFee = BigDecimal.ZERO;
        BigDecimal totalCashFee = BigDecimal.ZERO;
        int buyCount = 0;
        int sellCount = 0;
        Integer firstSeq = null;
        Integer lastSeq = null;

        for (Transaction tx : transactions) {
            BigDecimal fee = tx.getHandlingFee();
            if (fee == null || fee.compareTo(BigDecimal.ZERO) == 0) {
                continue;
            }

            // Sorszám tracking (bizonylat szám numerikus része)
            Integer seqNum = extractSequenceNumber(tx.getReceiptNumber());
            if (seqNum != null) {
                if (firstSeq == null || seqNum < firstSeq) firstSeq = seqNum;
                if (lastSeq == null || seqNum > lastSeq) lastSeq = seqNum;
            }

            // Típus szerinti összesítés (Legacy: TIPUS='V' vagy TIPUS='E')
            if (tx.getTransactionType().isBuyType()) {
                totalBuyFee = totalBuyFee.add(fee);
                buyCount++;
            } else if (tx.getTransactionType().isSellType()) {
                totalSellFee = totalSellFee.add(fee);
                sellCount++;
            }

            // Bankkártyás/készpénzes szétválasztás (Legacy: FIZETOESZKOZ=2)
            if (tx.getPaymentMethod() == PaymentMethod.CARD) {
                totalCardFee = totalCardFee.add(fee);
            } else {
                totalCashFee = totalCashFee.add(fee);
            }
        }

        BigDecimal totalFee = totalBuyFee.add(totalSellFee);

        // Nyitó egyenleg: előző dekád záró (Legacy: NAPIKEZELESIDIJ.ZARO)
        BigDecimal openingBalance = reportRepository
            .findPreviousClosingBalance(branchId, year, decade)
            .orElse(BigDecimal.ZERO);

        // Záró egyenleg = nyitó + összes díj
        BigDecimal closingBalance = openingBalance.add(totalFee);

        // Report mentés
        HandlingFeeDecadeReport report;
        if (existing != null) {
            report = existing;
        } else {
            report = HandlingFeeDecadeReport.builder()
                .branch(branch)
                .year(year)
                .decade(decade)
                .periodStart(periodStart)
                .periodEnd(periodEnd)
                .build();
        }

        report.setOpeningBalance(openingBalance);
        report.setTotalBuyFee(totalBuyFee);
        report.setTotalSellFee(totalSellFee);
        report.setTotalCardFee(totalCardFee);
        report.setTotalCashFee(totalCashFee);
        report.setClosingBalance(closingBalance);
        report.setFirstSequenceNumber(firstSeq);
        report.setLastSequenceNumber(lastSeq);
        report.setBuyCount(buyCount);
        report.setSellCount(sellCount);
        report.setTotalCount(buyCount + sellCount);
        report.setStatus(DecadeReportStatus.DRAFT);

        report = reportRepository.save(report);

        log.info("Kezelési díj dekád összesítő: branch={}, year={}, decade={}, " +
                 "nyitó={}, vétel={}, eladás={}, kártyás={}, készpénzes={}, záró={}",
            branchId, year, decade, openingBalance, totalBuyFee, totalSellFee,
            totalCardFee, totalCashFee, closingBalance);

        return toDto(report);
    }

    /**
     * Kezelési díj dekád lezárása.
     * Legacy: PRINTCONTROL.KEZDIJPRINT = TRUE
     */
    @Transactional
    public HandlingFeeDecadeReportDto closeReport(UUID reportId) {
        HandlingFeeDecadeReport report = reportRepository.findById(reportId)
            .orElseThrow(() -> new ResourceNotFoundException("Kezelési díj dekádjelentés nem található: " + reportId));

        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        if (!report.getBranch().getCompany().getId().equals(currentCompanyId)) {
            throw new ValidationException("Nincs jogosultság más cég kezelési díj dekádjelentésének lezárásához!");
        }

        if (report.getStatus() == DecadeReportStatus.CLOSED) {
            throw new ValidationException("Ez a kezelési díj dekádjelentés már le van zárva.");
        }

        report.setStatus(DecadeReportStatus.CLOSED);
        report.setClosedAt(LocalDateTime.now());
        report.setPrinted(true);
        report = reportRepository.save(report);

        log.info("Kezelési díj dekádjelentés lezárva: id={}", reportId);
        return toDto(report);
    }

    /**
     * Kezelési díj dekád jelentések lekérdezése.
     */
    @Transactional(readOnly = true)
    public Page<HandlingFeeDecadeReportDto> getReports(UUID branchId, int year, int page, int size) {
        return reportRepository
            .findByBranchIdAndYear(branchId, year, PageRequest.of(page, size, Sort.by("decade")))
            .map(this::toDto);
    }

    // ============ HELPER ============

    /**
     * Dekád időszak kiszámítása.
     */
    private LocalDate[] calculateDecadePeriod(int year, int decade) {
        int month = ((decade - 1) / 3) + 1;
        int decadeInMonth = ((decade - 1) % 3) + 1;

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

    /**
     * Bizonylat szám numerikus részének kinyerése.
     * Pl. "V00042" → 42, "E-260315-0007" → 7
     */
    private Integer extractSequenceNumber(String receiptNumber) {
        if (receiptNumber == null) return null;
        try {
            // Utolsó numerikus blokk kinyerése
            String digits = receiptNumber.replaceAll(".*[^0-9]", "");
            if (digits.isEmpty()) return null;
            return Integer.parseInt(digits);
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private HandlingFeeDecadeReportDto toDto(HandlingFeeDecadeReport entity) {
        return HandlingFeeDecadeReportDto.builder()
            .id(entity.getId())
            .branchId(entity.getBranch().getId())
            .year(entity.getYear())
            .decade(entity.getDecade())
            .periodStart(entity.getPeriodStart())
            .periodEnd(entity.getPeriodEnd())
            .openingBalance(entity.getOpeningBalance())
            .totalBuyFee(entity.getTotalBuyFee())
            .totalSellFee(entity.getTotalSellFee())
            .totalCardFee(entity.getTotalCardFee())
            .totalCashFee(entity.getTotalCashFee())
            .closingBalance(entity.getClosingBalance())
            .firstSequenceNumber(entity.getFirstSequenceNumber())
            .lastSequenceNumber(entity.getLastSequenceNumber())
            .buyCount(entity.getBuyCount())
            .sellCount(entity.getSellCount())
            .totalCount(entity.getTotalCount())
            .status(entity.getStatus().name())
            .printed(entity.getPrinted())
            .closedAt(entity.getClosedAt())
            .build();
    }
}
