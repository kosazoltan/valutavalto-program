package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.config.IntegrationTransportProperties;
import hu.puzzleir.valuta.dto.darius.DariusDailyReportDto;
import hu.puzzleir.valuta.dto.darius.DariusMonthlyDto;
import hu.puzzleir.valuta.dto.darius.DariusReportLineDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.nio.file.Paths;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Darius/Raiffeisen napi jelentés szolgáltatás.
 *
 * Fő funkciók:
 * 1. Napi jelentés generálása (tranzakciós adatok összesítése)
 * 2. Jóváhagyás (főértéktáros 4-eyes)
 * 3. Beküldés (DariusAdapter-en keresztül)
 * 4. Retry kezelés (FAILED → újraküldés)
 * 5. Havi összesítő
 * 6. Hiányzó napok detektálása
 *
 * Legacy: Darius.fdb adatforrás — az új rendszerben PostgreSQL + REST API.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DariusReportService {

    private final DariusDailyReportRepository reportRepository;
    private final DariusReportLineRepository lineRepository;
    private final TransactionRepository transactionRepository;
    private final BranchRepository branchRepository;
    private final AuditLogService auditLogService;
    private final IntegrationTransportProperties integrationTransportProperties;
    private final FileTransportService fileTransportService;

    // === 1. GENERÁLÁS ===

    /**
     * Napi jelentés generálása: összesíti az adott nap COMPLETED tranzakcióit
     * valutánként és irodánként.
     *
     * Ha már létezik DRAFT/GENERATED jelentés az adott napra, felülírja.
     * Ha SUBMITTED/ACKNOWLEDGED, ValidationException-t dob.
     */
    @Transactional(rollbackFor = Exception.class)
    public DariusDailyReportDto generateDailyReport(LocalDate date) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        log.info("Darius napi jelentés generálása: companyId={}, date={}", companyId, date);

        // Ellenőrzés: már beküldött jelentés nem írható felül
        Optional<DariusDailyReport> existing = reportRepository.findByCompanyIdAndReportDate(companyId, date);
        if (existing.isPresent()) {
            DariusReportStatus existingStatus = existing.get().getStatus();
            if (existingStatus == DariusReportStatus.SUBMITTED || existingStatus == DariusReportStatus.ACKNOWLEDGED) {
                throw new ValidationException(
                    String.format("A %s napi Darius jelentés már beküldve (%s), nem módosítható!", date, existingStatus));
            }
            // DRAFT/GENERATED/FAILED: felülírjuk
            lineRepository.deleteByCompanyIdAndReportId(companyId, existing.get().getId());
        }

        // Report entity
        DariusDailyReport report = existing.orElseGet(() -> DariusDailyReport.builder()
            .companyId(companyId)
            .reportDate(date)
            .build());

        // Irodák lekérése
        List<Branch> branches = branchRepository.findByCompanyIdAndIsActiveTrue(companyId);

        // Összesítés irodánként és valutánként
        List<DariusReportLine> lines = new ArrayList<>();
        BigDecimal totalBuyHuf = BigDecimal.ZERO;
        BigDecimal totalSellHuf = BigDecimal.ZERO;
        BigDecimal totalFeeHuf = BigDecimal.ZERO;
        int totalTxCount = 0;

        for (Branch branch : branches) {
            List<Object[]> branchSummary = transactionRepository
                .groupByCurrencyAndTypeForBranch(branch.getId(), date, date);

            for (Object[] row : branchSummary) {
                // row: [currencyCode, transactionType, SUM(currencyAmount), SUM(hufAmount), SUM(handlingFee), COUNT]
                String currencyCode = (String) row[0];
                String txType = (String) row[1];
                BigDecimal currencyAmount = row[2] != null ? (BigDecimal) row[2] : BigDecimal.ZERO;
                BigDecimal hufAmount = row[3] != null ? (BigDecimal) row[3] : BigDecimal.ZERO;
                BigDecimal fee = row[4] != null ? (BigDecimal) row[4] : BigDecimal.ZERO;
                long count = row[5] != null ? ((Number) row[5]).longValue() : 0;

                // Keressük/készítünk sort ehhez a branch+currency kombóhoz
                DariusReportLine line = findOrCreateLine(lines, report, branch, currencyCode);

                if ("BUY".equals(txType)) {
                    line.setBuyCount((line.getBuyCount() != null ? line.getBuyCount() : 0) + (int) count);
                    line.setBuyCurrencyAmount(line.getBuyCurrencyAmount().add(currencyAmount));
                    line.setBuyHufAmount(line.getBuyHufAmount().add(hufAmount));
                    totalBuyHuf = totalBuyHuf.add(hufAmount);
                } else if ("SELL".equals(txType)) {
                    line.setSellCount((line.getSellCount() != null ? line.getSellCount() : 0) + (int) count);
                    line.setSellCurrencyAmount(line.getSellCurrencyAmount().add(currencyAmount));
                    line.setSellHufAmount(line.getSellHufAmount().add(hufAmount));
                    totalSellHuf = totalSellHuf.add(hufAmount);
                }

                line.setHandlingFeeHuf(line.getHandlingFeeHuf().add(fee));
                totalFeeHuf = totalFeeHuf.add(fee);
                totalTxCount += (int) count;
            }
        }

        // Átlagárfolyamok számítása soronként
        for (DariusReportLine line : lines) {
            if (line.getBuyCurrencyAmount() != null && line.getBuyCurrencyAmount().compareTo(BigDecimal.ZERO) > 0) {
                line.setAvgBuyRate(line.getBuyHufAmount().divide(line.getBuyCurrencyAmount(), 4, RoundingMode.HALF_UP));
            }
            if (line.getSellCurrencyAmount() != null && line.getSellCurrencyAmount().compareTo(BigDecimal.ZERO) > 0) {
                line.setAvgSellRate(line.getSellHufAmount().divide(line.getSellCurrencyAmount(), 4, RoundingMode.HALF_UP));
            }
        }

        // Report fejléc
        report.setStatus(DariusReportStatus.GENERATED);
        report.setTotalBuyHuf(totalBuyHuf);
        report.setTotalSellHuf(totalSellHuf);
        report.setTotalHandlingFeeHuf(totalFeeHuf);
        report.setTransactionCount(totalTxCount);
        report.setBranchCount(branches.size());

        // Payload generálás (JSON)
        String payload = buildJsonPayload(report, lines);
        report.setPayload(payload);
        report.setPayloadFormat("JSON");
        report.setPayloadHash(sha256(payload));

        // Mentés
        DariusDailyReport saved = reportRepository.save(report);
        for (DariusReportLine line : lines) {
            line.setReport(saved);
        }
        lineRepository.saveAll(lines);

        auditLogService.log(
            "DARIUS_REPORT_GENERATED",
            String.format("Darius napi jelentés generálva: %s, %d tranzakció, %d iroda",
                date, totalTxCount, branches.size()),
            companyId.toString()
        );

        log.info("Darius napi jelentés kész: date={}, tx={}, branches={}, buyHuf={}, sellHuf={}",
            date, totalTxCount, branches.size(), totalBuyHuf, totalSellHuf);

        return toDto(saved, lines);
    }

    // === 2. JÓVÁHAGYÁS ===

    /**
     * Főértéktáros jóváhagyás (4-eyes).
     * Csak GENERATED státuszú jelentés hagyható jóvá.
     */
    @Transactional(rollbackFor = Exception.class)
    public DariusDailyReportDto approveReport(UUID reportId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        DariusDailyReport report = findReport(reportId, companyId);

        if (report.getStatus() != DariusReportStatus.GENERATED) {
            throw new ValidationException(
                String.format("Jóváhagyás csak GENERATED státuszú jelentésre lehetséges (jelenlegi: %s)", report.getStatus()));
        }

        report.setApprovedBy(SecurityUtils.getCurrentWorkerCode());
        report.setApprovedAt(LocalDateTime.now());
        reportRepository.save(report);

        auditLogService.log(
            "DARIUS_REPORT_APPROVED",
            String.format("Darius napi jelentés jóváhagyva: %s", report.getReportDate()),
            report.getCompanyId().toString()
        );

        log.info("Darius jelentés jóváhagyva: id={}, date={}, approvedBy={}",
            reportId, report.getReportDate(), report.getApprovedBy());

        return toDto(report);
    }

    // === 3. BEKÜLDÉS ===

    /**
     * Jelentés beküldése a Darius rendszerbe.
     * Csak GENERATED + jóváhagyott jelentés küldhető be.
     *
     * A tényleges transport a DariusAdapter-en keresztül történik,
     * amit az implementáló fél a bank specifikáció alapján készít el.
     * Ez a service az állapotgépet és az audit trail-t kezeli.
     */
    @Transactional(rollbackFor = Exception.class)
    public DariusDailyReportDto submitReport(UUID reportId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        DariusDailyReport report = findReport(reportId, companyId);

        if (report.getStatus() != DariusReportStatus.GENERATED &&
            report.getStatus() != DariusReportStatus.FAILED) {
            throw new ValidationException(
                String.format("Beküldés csak GENERATED vagy FAILED státuszú jelentésre lehetséges (jelenlegi: %s)",
                    report.getStatus()));
        }

        if (report.getApprovedBy() == null) {
            throw new ValidationException("A jelentést először jóvá kell hagyni (4-eyes)!");
        }

        // Managed outbox transport (repo-n belül teljesíthető scope)
        try {
            String reference = submitToDarius(report);
            report.setStatus(DariusReportStatus.SUBMITTED);
            report.setSubmittedAt(LocalDateTime.now());
            report.setSubmittedBy(SecurityUtils.getCurrentWorkerCode());
            report.setAckReference(reference);
            report.setErrorMessage(null);

            auditLogService.log(
                "DARIUS_REPORT_SUBMITTED",
                String.format("Darius napi jelentés beküldve: %s, ref: %s", report.getReportDate(), reference),
                report.getCompanyId().toString()
            );

            log.info("Darius jelentés beküldve: id={}, date={}, ref={}", reportId, report.getReportDate(), reference);

        } catch (Exception e) {
            report.setStatus(DariusReportStatus.FAILED);
            report.setErrorMessage(e.getMessage());
            report.setRetryCount(report.getRetryCount() + 1);
            report.setNextRetryAt(LocalDateTime.now().plusMinutes(
                (long) Math.pow(2, report.getRetryCount()) * 5)); // exponential backoff: 5, 10, 20, 40 min

            auditLogService.log(
                "DARIUS_REPORT_FAILED",
                String.format("Darius napi jelentés beküldés sikertelen: %s — %s (retry: %d/%d)",
                    report.getReportDate(), e.getMessage(), report.getRetryCount(), report.getMaxRetries()),
                report.getCompanyId().toString()
            );

            log.error("Darius jelentés beküldés hiba: id={}, date={}, error={}, retry={}/{}",
                reportId, report.getReportDate(), e.getMessage(), report.getRetryCount(), report.getMaxRetries());
        }

        reportRepository.save(report);
        return toDto(report);
    }

    /**
     * Darius transport: payload outbox artifact létrehozása auditálható referenciával.
     */
    private String submitToDarius(DariusDailyReport report) throws Exception {
        String reference = "DARIUS-" + report.getReportDate() + "-" + UUID.randomUUID().toString().substring(0, 8);
        String safeOutboxDir = fileTransportService.sanitizePathSegment(
                integrationTransportProperties.getDarius().getOutboxDir(), "darius.outboxDir");
        String safeCompanyId = fileTransportService.sanitizePathSegment(report.getCompanyId().toString(), "companyId");

        Map<String, Object> envelope = new LinkedHashMap<>();
        envelope.put("reference", reference);
        envelope.put("companyId", report.getCompanyId());
        envelope.put("reportDate", report.getReportDate());
        envelope.put("payloadFormat", report.getPayloadFormat());
        envelope.put("payloadHash", report.getPayloadHash());
        envelope.put("payloadSizeBytes", report.getPayload() != null ? report.getPayload().getBytes(StandardCharsets.UTF_8).length : 0);
        envelope.put("payload", report.getPayload());
        envelope.put("transportMode", "managed-outbox");
        envelope.put("submittedAt", LocalDateTime.now().toString());

        var artifact = fileTransportService.writeJson(
                Paths.get(safeOutboxDir, safeCompanyId).toString(),
                "daily_report_" + report.getReportDate(),
                envelope);

        log.info("Darius outbox artifact elkészült: ref={}, file={}", reference, artifact);
        return reference;
    }

    // === 4. RETRY ===

    /**
     * A bejelentkezett cég FAILED státuszú, retry limiten belüli jelentéseit küldi újra.
     * Jelenleg autentikált controller-endpoint hívja. Scheduler esetén cégenkénti
     * iteráció és explicit company-scope szükséges.
     */
    @Transactional(rollbackFor = Exception.class)
    public List<DariusDailyReportDto> retryFailedReports() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<DariusDailyReport> retryable = reportRepository.findRetryable(companyId, LocalDateTime.now());

        if (retryable.isEmpty()) {
            return Collections.emptyList();
        }

        log.info("Darius retry: {} jelentés újraküldése", retryable.size());

        return retryable.stream()
            .map(report -> submitReport(report.getId()))
            .collect(Collectors.toList());
    }

    // === 5. ACKNOWLEDGMENT ===

    /**
     * Bank visszaigazolás rögzítése (webhook vagy polling alapú).
     */
    @Transactional(rollbackFor = Exception.class)
    public DariusDailyReportDto acknowledgeReport(UUID reportId, String ackReference) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        DariusDailyReport report = findReport(reportId, companyId);

        if (report.getStatus() != DariusReportStatus.SUBMITTED) {
            throw new ValidationException("Acknowledgment csak SUBMITTED státuszú jelentésre lehetséges!");
        }

        report.setStatus(DariusReportStatus.ACKNOWLEDGED);
        report.setAckReference(ackReference);
        report.setAckAt(LocalDateTime.now());
        reportRepository.save(report);

        auditLogService.log(
            "DARIUS_REPORT_ACKNOWLEDGED",
            String.format("Darius napi jelentés visszaigazolva: %s, ref: %s", report.getReportDate(), ackReference),
            report.getCompanyId().toString()
        );

        log.info("Darius jelentés visszaigazolva: id={}, date={}, ackRef={}", reportId, report.getReportDate(), ackReference);

        return toDto(report);
    }

    // === 6. LEKÉRDEZÉSEK ===

    @Transactional(readOnly = true)
    public DariusDailyReportDto getReport(UUID reportId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        DariusDailyReport report = findReport(reportId, companyId);
        List<DariusReportLine> lines =
            lineRepository.findByCompanyIdAndReportIdOrderByCurrencyCodeAsc(companyId, reportId);
        return toDto(report, lines);
    }

    @Transactional(readOnly = true)
    public DariusDailyReportDto getReportByDate(LocalDate date) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        DariusDailyReport report = reportRepository.findByCompanyIdAndReportDate(companyId, date)
            .orElseThrow(() -> new ResourceNotFoundException("Nincs Darius jelentés erre a napra: " + date));
        List<DariusReportLine> lines =
            lineRepository.findByCompanyIdAndReportIdOrderByCurrencyCodeAsc(companyId, report.getId());
        return toDto(report, lines);
    }

    @Transactional(readOnly = true)
    public List<DariusDailyReportDto> getReportsByDateRange(LocalDate startDate, LocalDate endDate) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return reportRepository.findByCompanyIdAndReportDateBetweenOrderByReportDateDesc(companyId, startDate, endDate)
            .stream()
            .map(this::toDto)
            .collect(Collectors.toList());
    }

    // === 7. HAVI ÖSSZESÍTŐ ===

    @Transactional(readOnly = true)
    public DariusMonthlyDto getMonthlyReport(int year, int month) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        YearMonth ym = YearMonth.of(year, month);
        LocalDate start = ym.atDay(1);
        LocalDate end = ym.atEndOfMonth();

        List<DariusDailyReport> reports = reportRepository
            .findByCompanyIdAndReportDateBetweenOrderByReportDateDesc(companyId, start, end);

        BigDecimal totalBuy = BigDecimal.ZERO;
        BigDecimal totalSell = BigDecimal.ZERO;
        BigDecimal totalFee = BigDecimal.ZERO;
        int totalTx = 0;
        int ackCount = 0;
        int failedCount = 0;
        int pendingCount = 0;

        for (DariusDailyReport r : reports) {
            if (r.getTotalBuyHuf() != null) totalBuy = totalBuy.add(r.getTotalBuyHuf());
            if (r.getTotalSellHuf() != null) totalSell = totalSell.add(r.getTotalSellHuf());
            if (r.getTotalHandlingFeeHuf() != null) totalFee = totalFee.add(r.getTotalHandlingFeeHuf());
            if (r.getTransactionCount() != null) totalTx += r.getTransactionCount();

            switch (r.getStatus()) {
                case ACKNOWLEDGED -> ackCount++;
                case FAILED -> failedCount++;
                default -> pendingCount++;
            }
        }

        return DariusMonthlyDto.builder()
            .year(year)
            .month(month)
            .totalReports(reports.size())
            .acknowledgedCount(ackCount)
            .failedCount(failedCount)
            .pendingCount(pendingCount)
            .totalBuyHuf(totalBuy)
            .totalSellHuf(totalSell)
            .totalHandlingFeeHuf(totalFee)
            .totalTransactionCount(totalTx)
            .dailyReports(reports.stream().map(this::toDto).collect(Collectors.toList()))
            .build();
    }

    // === 8. HIÁNYZÓ NAPOK ===

    @Transactional(readOnly = true)
    public List<LocalDate> findMissingDates(LocalDate startDate, LocalDate endDate) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Set<LocalDate> existingDates = new HashSet<>(
            reportRepository.findExistingDates(companyId, startDate, endDate));

        List<LocalDate> missing = new ArrayList<>();
        for (LocalDate d = startDate; !d.isAfter(endDate); d = d.plusDays(1)) {
            // Hétvégét kihagyjuk (szombat=6, vasárnap=7)
            if (d.getDayOfWeek().getValue() <= 5 && !existingDates.contains(d)) {
                missing.add(d);
            }
        }
        return missing;
    }

    // === HELPERS ===

    private DariusDailyReport findReport(UUID reportId, UUID companyId) {
        return reportRepository.findByIdAndCompanyId(reportId, companyId)
            .orElseThrow(() -> new ResourceNotFoundException("Darius jelentés nem található: " + reportId));
    }

    private DariusReportLine findOrCreateLine(List<DariusReportLine> lines, DariusDailyReport report,
                                                Branch branch, String currencyCode) {
        return lines.stream()
            .filter(l -> l.getBranchId().equals(branch.getId()) && l.getCurrencyCode().equals(currencyCode))
            .findFirst()
            .orElseGet(() -> {
                DariusReportLine newLine = DariusReportLine.builder()
                    .companyId(report.getCompanyId())
                    .report(report)
                    .branchId(branch.getId())
                    .branchCode(branch.getCode())
                    .currencyCode(currencyCode)
                    .build();
                lines.add(newLine);
                return newLine;
            });
    }

    private String buildJsonPayload(DariusDailyReport report, List<DariusReportLine> lines) {
        // Egyszerű JSON payload — éles rendszerben Jackson ObjectMapper-rel
        StringBuilder sb = new StringBuilder();
        sb.append("{");
        sb.append("\"reportDate\":\"").append(report.getReportDate()).append("\",");
        sb.append("\"companyId\":\"").append(report.getCompanyId()).append("\",");
        sb.append("\"totalBuyHuf\":").append(report.getTotalBuyHuf()).append(",");
        sb.append("\"totalSellHuf\":").append(report.getTotalSellHuf()).append(",");
        sb.append("\"totalHandlingFeeHuf\":").append(report.getTotalHandlingFeeHuf()).append(",");
        sb.append("\"transactionCount\":").append(report.getTransactionCount()).append(",");
        sb.append("\"branchCount\":").append(report.getBranchCount()).append(",");
        sb.append("\"lines\":[");

        for (int i = 0; i < lines.size(); i++) {
            DariusReportLine line = lines.get(i);
            if (i > 0) sb.append(",");
            sb.append("{");
            sb.append("\"branchCode\":\"").append(line.getBranchCode()).append("\",");
            sb.append("\"currencyCode\":\"").append(line.getCurrencyCode()).append("\",");
            sb.append("\"buyCount\":").append(line.getBuyCount()).append(",");
            sb.append("\"buyCurrencyAmount\":").append(line.getBuyCurrencyAmount()).append(",");
            sb.append("\"buyHufAmount\":").append(line.getBuyHufAmount()).append(",");
            sb.append("\"sellCount\":").append(line.getSellCount()).append(",");
            sb.append("\"sellCurrencyAmount\":").append(line.getSellCurrencyAmount()).append(",");
            sb.append("\"sellHufAmount\":").append(line.getSellHufAmount()).append(",");
            sb.append("\"handlingFeeHuf\":").append(line.getHandlingFeeHuf());
            sb.append("}");
        }

        sb.append("]}");
        return sb.toString();
    }

    private String sha256(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(input.getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder();
            for (byte b : hash) {
                hex.append(String.format("%02x", b));
            }
            return hex.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 nem elérhető", e);
        }
    }

    // === MAPPING ===

    private DariusDailyReportDto toDto(DariusDailyReport entity) {
        return toDto(entity, null);
    }

    private DariusDailyReportDto toDto(DariusDailyReport entity, List<DariusReportLine> lines) {
        DariusDailyReportDto dto = DariusDailyReportDto.builder()
            .id(entity.getId())
            .companyId(entity.getCompanyId())
            .reportDate(entity.getReportDate())
            .status(entity.getStatus().name())
            .totalBuyHuf(entity.getTotalBuyHuf())
            .totalSellHuf(entity.getTotalSellHuf())
            .transactionCount(entity.getTransactionCount())
            .totalHandlingFeeHuf(entity.getTotalHandlingFeeHuf())
            .branchCount(entity.getBranchCount())
            .payloadFormat(entity.getPayloadFormat())
            .payloadHash(entity.getPayloadHash())
            .submittedAt(entity.getSubmittedAt())
            .submittedBy(entity.getSubmittedBy())
            .ackReference(entity.getAckReference())
            .ackAt(entity.getAckAt())
            .errorMessage(entity.getErrorMessage())
            .retryCount(entity.getRetryCount())
            .maxRetries(entity.getMaxRetries())
            .nextRetryAt(entity.getNextRetryAt())
            .approvedBy(entity.getApprovedBy())
            .approvedAt(entity.getApprovedAt())
            .createdAt(entity.getCreatedAt())
            .updatedAt(entity.getUpdatedAt())
            .notes(entity.getNotes())
            .build();

        if (lines != null) {
            dto.setLines(lines.stream().map(this::toLineDto).collect(Collectors.toList()));
        }
        return dto;
    }

    private DariusReportLineDto toLineDto(DariusReportLine line) {
        return DariusReportLineDto.builder()
            .id(line.getId())
            .branchId(line.getBranchId())
            .branchCode(line.getBranchCode())
            .currencyCode(line.getCurrencyCode())
            .buyCount(line.getBuyCount())
            .buyCurrencyAmount(line.getBuyCurrencyAmount())
            .buyHufAmount(line.getBuyHufAmount())
            .sellCount(line.getSellCount())
            .sellCurrencyAmount(line.getSellCurrencyAmount())
            .sellHufAmount(line.getSellHufAmount())
            .avgBuyRate(line.getAvgBuyRate())
            .avgSellRate(line.getAvgSellRate())
            .handlingFeeHuf(line.getHandlingFeeHuf())
            .build();
    }
}
