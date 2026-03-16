package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.dto.mnb.MnbSubmissionResult;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.MnbReportRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.*;
import java.util.stream.Collectors;

/**
 * MNB adatszolgáltatás szolgáltatás.
 *
 * JOGSZABÁLYI KÖTELEZETTSÉG: A pénzváltóknak kötelező napi/heti/havi
 * MNB riportot küldeni a forgalomról a Magyar Nemzeti Bank felé.
 *
 * Legacy: MNB gyűjtő DLL (mnbgyujto/unit2.pas)
 */
@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class MnbReportService {

    static final int MAX_RETRY_COUNT = 3;

    private final MnbReportRepository mnbReportRepository;
    private final TransactionRepository transactionRepository;
    private final BranchRepository branchRepository;
    private final OwnCompanyService ownCompanyService;
    private final MnbApiClient mnbApiClient;

    /**
     * Napi MNB riport generálása egy irodához.
     *
     * Összegyűjti az adott nap összes tranzakcióját (BUY + SELL),
     * valutánként összesít, majd MNB-kompatibilis XML-t generál.
     */
    public MnbReport generateDailyReport(UUID branchId, LocalDate date) {
        log.info("MNB napi riport generálás: branchId={}, date={}", branchId, date);

        Branch branch = branchRepository.findById(branchId)
            .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));

        // Ellenőrzés: létezik-e már az adott napra riport
        Optional<MnbReport> existing = mnbReportRepository
            .findByReportTypeAndReportDateAndBranchId(MnbReportType.DAILY, date, branchId);
        if (existing.isPresent()) {
            throw new ValidationException("Már létezik MNB napi riport erre a dátumra: " + date);
        }

        // Tranzakciók lekérése az adott napra
        List<Transaction> transactions = transactionRepository.findActiveByBranchAndDate(branchId, date);

        // Riport létrehozása
        MnbReport report = MnbReport.builder()
            .reportType(MnbReportType.DAILY)
            .reportDate(date)
            .branch(branch)
            .status(MnbReportStatus.DRAFT)
            .build();

        // Valutánkénti összesítés
        Map<String, CurrencyAggregation> aggregations = aggregateTransactions(transactions);

        BigDecimal totalBuyHuf = BigDecimal.ZERO;
        BigDecimal totalSellHuf = BigDecimal.ZERO;
        int totalTxCount = 0;

        for (Map.Entry<String, CurrencyAggregation> entry : aggregations.entrySet()) {
            CurrencyAggregation agg = entry.getValue();

            MnbReportLine line = MnbReportLine.builder()
                .currencyCode(entry.getKey())
                .buyAmount(agg.buyAmount)
                .sellAmount(agg.sellAmount)
                .buyRate(agg.getBuyCount() > 0
                    ? agg.buyRateSum.divide(BigDecimal.valueOf(agg.getBuyCount()), 4, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO)
                .sellRate(agg.getSellCount() > 0
                    ? agg.sellRateSum.divide(BigDecimal.valueOf(agg.getSellCount()), 4, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO)
                .transactionCount(agg.totalCount)
                .build();

            report.addLine(line);

            totalBuyHuf = totalBuyHuf.add(agg.buyHufTotal);
            totalSellHuf = totalSellHuf.add(agg.sellHufTotal);
            totalTxCount += agg.totalCount;
        }

        report.setTotalBuyHuf(totalBuyHuf);
        report.setTotalSellHuf(totalSellHuf);
        report.setTotalTransactions(totalTxCount);

        // XML generálása
        String xml = generateMnbXml(report, branch);
        report.setXmlContent(xml);

        MnbReport saved = mnbReportRepository.save(report);

        log.info("MNB napi riport létrehozva: id={}, tranzakciók={}, buyHuf={}, sellHuf={}",
            saved.getId(), totalTxCount, totalBuyHuf, totalSellHuf);

        return saved;
    }

    /**
     * Havi MNB riport generálása.
     */
    public MnbReport generateMonthlyReport(UUID branchId, YearMonth month) {
        log.info("MNB havi riport generálás: branchId={}, month={}", branchId, month);

        Branch branch = branchRepository.findById(branchId)
            .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));

        LocalDate monthStart = month.atDay(1);
        LocalDate monthEnd = month.atEndOfMonth();

        // Ellenőrzés: létezik-e már
        Optional<MnbReport> existing = mnbReportRepository
            .findByReportTypeAndReportDateAndBranchId(MnbReportType.MONTHLY, monthEnd, branchId);
        if (existing.isPresent()) {
            throw new ValidationException("Már létezik MNB havi riport erre a hónapra: " + month);
        }

        // Havi tranzakciók lekérése
        List<Transaction> transactions = transactionRepository
            .findByBranchAndMonth(branchId, monthStart, monthEnd);

        // Riport létrehozása
        MnbReport report = MnbReport.builder()
            .reportType(MnbReportType.MONTHLY)
            .reportDate(monthEnd)
            .branch(branch)
            .status(MnbReportStatus.DRAFT)
            .build();

        // Valutánkénti összesítés
        Map<String, CurrencyAggregation> aggregations = aggregateTransactions(transactions);

        BigDecimal totalBuyHuf = BigDecimal.ZERO;
        BigDecimal totalSellHuf = BigDecimal.ZERO;
        int totalTxCount = 0;

        for (Map.Entry<String, CurrencyAggregation> entry : aggregations.entrySet()) {
            CurrencyAggregation agg = entry.getValue();

            MnbReportLine line = MnbReportLine.builder()
                .currencyCode(entry.getKey())
                .buyAmount(agg.buyAmount)
                .sellAmount(agg.sellAmount)
                .buyRate(agg.getBuyCount() > 0
                    ? agg.buyRateSum.divide(BigDecimal.valueOf(agg.getBuyCount()), 4, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO)
                .sellRate(agg.getSellCount() > 0
                    ? agg.sellRateSum.divide(BigDecimal.valueOf(agg.getSellCount()), 4, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO)
                .transactionCount(agg.totalCount)
                .build();

            report.addLine(line);

            totalBuyHuf = totalBuyHuf.add(agg.buyHufTotal);
            totalSellHuf = totalSellHuf.add(agg.sellHufTotal);
            totalTxCount += agg.totalCount;
        }

        report.setTotalBuyHuf(totalBuyHuf);
        report.setTotalSellHuf(totalSellHuf);
        report.setTotalTransactions(totalTxCount);

        // XML generálás
        String xml = generateMnbXml(report, branch);
        report.setXmlContent(xml);

        MnbReport saved = mnbReportRepository.save(report);

        log.info("MNB havi riport létrehozva: id={}, tranzakciók={}", saved.getId(), totalTxCount);

        return saved;
    }

    /**
     * Riport beküldése az MNB-nek.
     *
     * Státuszfolyamat: DRAFT → SUBMITTED → ACKNOWLEDGED (siker) | REJECTED (hiba)
     */
    public MnbSubmissionResult submitReport(UUID reportId) {
        MnbReport report = mnbReportRepository.findById(reportId)
            .orElseThrow(() -> new ResourceNotFoundException("MNB riport nem található: " + reportId));

        if (report.getStatus() != MnbReportStatus.DRAFT) {
            throw new ValidationException("Csak DRAFT státuszú riport küldhető be! Jelenlegi: " + report.getStatus());
        }

        log.info("MNB riport beküldés: reportId={}, type={}", reportId, report.getReportType());

        // Átmenet SUBMITTED-re
        report.setStatus(MnbReportStatus.SUBMITTED);
        report.setSubmittedAt(LocalDateTime.now());
        mnbReportRepository.save(report);

        // Valós HTTP beküldés
        MnbSubmissionResult result = mnbApiClient.submitXml(
            report.getXmlContent(), report.getReportType().name());

        if (result.isSuccess()) {
            report.setStatus(MnbReportStatus.ACKNOWLEDGED);
            report.setAcknowledgedAt(LocalDateTime.now());
            report.setMnbReferenceNumber(result.getReferenceNumber());
            report.setSubmissionError(null);
            log.info("MNB riport beküldés sikeres: reportId={}, ref={}", reportId, result.getReferenceNumber());
        } else {
            report.setStatus(MnbReportStatus.REJECTED);
            report.setRejectedAt(LocalDateTime.now());
            report.setSubmissionError(result.getErrorMessage());
            report.setRejectionReasonDetail(result.getErrorMessage());
            log.warn("MNB riport beküldés sikertelen: reportId={}, hiba={}", reportId, result.getErrorMessage());
        }

        mnbReportRepository.save(report);
        return result;
    }

    /**
     * Sikertelen riport újraküldése (max {@value MAX_RETRY_COUNT} kísérlet).
     *
     * Csak REJECTED státuszú riport kísérelhető újra.
     * Exponenciális várakozás validáció: minden kísérlet között legalább
     * 2^(retryCount-1) perc kell (1 / 2 / 4 perc).
     */
    public MnbSubmissionResult retrySubmission(UUID reportId) {
        MnbReport report = mnbReportRepository.findById(reportId)
            .orElseThrow(() -> new ResourceNotFoundException("MNB riport nem található: " + reportId));

        if (report.getStatus() != MnbReportStatus.REJECTED) {
            throw new ValidationException("Csak REJECTED státuszú riport küldhető újra! Jelenlegi: " + report.getStatus());
        }

        int currentRetry = report.getRetryCount() == null ? 0 : report.getRetryCount();
        if (currentRetry >= MAX_RETRY_COUNT) {
            throw new ValidationException(
                "Maximális újraküldési kísérletek száma elérve (" + MAX_RETRY_COUNT + "): reportId=" + reportId);
        }

        // Exponenciális várakozás validáció
        if (report.getLastRetryAt() != null) {
            long requiredMinutes = (long) Math.pow(2, currentRetry - 1);
            LocalDateTime earliest = report.getLastRetryAt().plusMinutes(requiredMinutes);
            if (LocalDateTime.now().isBefore(earliest)) {
                throw new ValidationException(
                    "Korai újraküldési kísérlet! Legkorábban: " + earliest + " (exponenciális backoff)");
            }
        }

        log.info("MNB riport újraküldés: reportId={}, kísérlet={}/{}", reportId, currentRetry + 1, MAX_RETRY_COUNT);

        report.setRetryCount(currentRetry + 1);
        report.setLastRetryAt(LocalDateTime.now());
        report.setStatus(MnbReportStatus.SUBMITTED);
        mnbReportRepository.save(report);

        MnbSubmissionResult result = mnbApiClient.submitXml(
            report.getXmlContent(), report.getReportType().name());

        if (result.isSuccess()) {
            report.setStatus(MnbReportStatus.ACKNOWLEDGED);
            report.setAcknowledgedAt(LocalDateTime.now());
            report.setMnbReferenceNumber(result.getReferenceNumber());
            report.setSubmissionError(null);
            log.info("MNB újraküldés sikeres: reportId={}, ref={}", reportId, result.getReferenceNumber());
        } else {
            report.setStatus(MnbReportStatus.REJECTED);
            report.setRejectedAt(LocalDateTime.now());
            report.setSubmissionError(result.getErrorMessage());
            report.setRejectionReasonDetail(result.getErrorMessage());
            log.warn("MNB újraküldés sikertelen: reportId={}, hiba={}", reportId, result.getErrorMessage());
        }

        mnbReportRepository.save(report);
        return result;
    }

    /**
     * Heti MNB riport generálása (ISO hét: hétfő–vasárnap).
     *
     * @param branchId  iroda azonosítója
     * @param weekStart hét első napja (hétfő)
     */
    public MnbReport generateWeeklyReport(UUID branchId, LocalDate weekStart) {
        // Normalizálás: ha nem hétfő, kerekítjük a hét elejére
        LocalDate monday = weekStart.with(DayOfWeek.MONDAY);
        LocalDate sunday = monday.plusDays(6);

        log.info("MNB heti riport generálás: branchId={}, hét={} – {}", branchId, monday, sunday);

        Branch branch = branchRepository.findById(branchId)
            .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));

        // Ellenőrzés: létezik-e már erre a hétre riport
        Optional<MnbReport> existing = mnbReportRepository
            .findByReportTypeAndReportDateAndBranchId(MnbReportType.WEEKLY, sunday, branchId);
        if (existing.isPresent()) {
            throw new ValidationException("Már létezik MNB heti riport erre a hétre: " + monday + " – " + sunday);
        }

        List<Transaction> transactions = transactionRepository
            .findActiveByBranchAndDateRange(branchId, monday, sunday);

        MnbReport report = MnbReport.builder()
            .reportType(MnbReportType.WEEKLY)
            .reportDate(sunday)
            .branch(branch)
            .status(MnbReportStatus.DRAFT)
            .build();

        Map<String, CurrencyAggregation> aggregations = aggregateTransactions(transactions);

        BigDecimal totalBuyHuf = BigDecimal.ZERO;
        BigDecimal totalSellHuf = BigDecimal.ZERO;
        int totalTxCount = 0;

        for (Map.Entry<String, CurrencyAggregation> entry : aggregations.entrySet()) {
            CurrencyAggregation agg = entry.getValue();

            MnbReportLine line = MnbReportLine.builder()
                .currencyCode(entry.getKey())
                .buyAmount(agg.buyAmount)
                .sellAmount(agg.sellAmount)
                .buyRate(agg.getBuyCount() > 0
                    ? agg.buyRateSum.divide(BigDecimal.valueOf(agg.getBuyCount()), 4, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO)
                .sellRate(agg.getSellCount() > 0
                    ? agg.sellRateSum.divide(BigDecimal.valueOf(agg.getSellCount()), 4, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO)
                .transactionCount(agg.totalCount)
                .build();

            report.addLine(line);

            totalBuyHuf = totalBuyHuf.add(agg.buyHufTotal);
            totalSellHuf = totalSellHuf.add(agg.sellHufTotal);
            totalTxCount += agg.totalCount;
        }

        report.setTotalBuyHuf(totalBuyHuf);
        report.setTotalSellHuf(totalSellHuf);
        report.setTotalTransactions(totalTxCount);

        String xml = generateMnbXml(report, branch);
        report.setXmlContent(xml);

        MnbReport saved = mnbReportRepository.save(report);

        log.info("MNB heti riport létrehozva: id={}, hét={}-{}, tranzakciók={}",
            saved.getId(), monday, sunday, totalTxCount);

        return saved;
    }

    /**
     * Riport státusz lekérdezése.
     */
    @Transactional(readOnly = true)
    public MnbReport getReportStatus(UUID reportId) {
        return mnbReportRepository.findById(reportId)
            .orElseThrow(() -> new ResourceNotFoundException("MNB riport nem található: " + reportId));
    }

    /**
     * Riportok listázása szűréssel.
     */
    @Transactional(readOnly = true)
    public Page<MnbReport> listReports(UUID branchId, MnbReportType reportType,
                                        MnbReportStatus status, LocalDate dateFrom,
                                        LocalDate dateTo, Pageable pageable) {
        return mnbReportRepository.findWithFilters(branchId, reportType, status, dateFrom, dateTo, pageable);
    }

    // ============ BELSŐ HELPER METÓDUSOK ============

    /**
     * Tranzakciók valutánkénti aggregálása.
     */
    private Map<String, CurrencyAggregation> aggregateTransactions(List<Transaction> transactions) {
        Map<String, CurrencyAggregation> result = new TreeMap<>();

        for (Transaction tx : transactions) {
            if (tx.getCurrency() == null) continue;

            String currCode = tx.getCurrency().getCode();
            if ("HUF".equals(currCode)) continue; // HUF nem releváns az MNB riportban

            CurrencyAggregation agg = result.computeIfAbsent(currCode, k -> new CurrencyAggregation());

            if (tx.getTransactionType().isBuyType()) {
                agg.buyAmount = agg.buyAmount.add(tx.getCurrencyAmount());
                agg.buyHufTotal = agg.buyHufTotal.add(tx.getHufAmount());
                agg.buyRateSum = agg.buyRateSum.add(tx.getExchangeRate());
                agg.buyCount++;
            } else if (tx.getTransactionType().isSellType()) {
                agg.sellAmount = agg.sellAmount.add(tx.getCurrencyAmount());
                agg.sellHufTotal = agg.sellHufTotal.add(tx.getHufAmount());
                agg.sellRateSum = agg.sellRateSum.add(tx.getExchangeRate());
                agg.sellCount++;
            }

            agg.totalCount++;
        }

        return result;
    }

    /**
     * MNB XSD-kompatibilis XML generálása.
     *
     * Namespace: http://www.mnb.hu/penzvaltok/2010
     * Magyar elemnevek: Jelentes, Devizanem, Vetel, Eladas, Osszeg, Arfolyam
     *
     * Legacy: MNB gyűjtő DLL XML formátum (mnbgyujto/unit2.pas) alapján.
     */
    private String generateMnbXml(MnbReport report, Branch branch) {
        String taxId = "00000000-0-00";
        try {
            List<OwnCompany> companies = ownCompanyService.listActive();
            if (!companies.isEmpty()) {
                taxId = companies.get(0).getTaxNumber() != null
                    ? companies.get(0).getTaxNumber() : taxId;
            }
        } catch (Exception e) {
            log.warn("Saját cég adószám nem elérhető: {}", e.getMessage());
        }

        StringBuilder xml = new StringBuilder();
        xml.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
        xml.append("<Jelentes xmlns=\"http://www.mnb.hu/penzvaltok/2010\"");
        xml.append(" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">\n");

        // Fejléc
        xml.append("  <Fejlec>\n");
        xml.append("    <RiportTipus>").append(report.getReportType().name()).append("</RiportTipus>\n");
        xml.append("    <RiportDatum>").append(report.getReportDate()).append("</RiportDatum>\n");
        xml.append("    <AdoSzam>").append(escapeXml(taxId)).append("</AdoSzam>\n");
        xml.append("    <IrodaKod>").append(escapeXml(branch.getCode())).append("</IrodaKod>\n");
        xml.append("  </Fejlec>\n");

        // Forgalom — valutánként
        xml.append("  <Forgalom>\n");
        for (MnbReportLine line : report.getLines()) {
            xml.append("    <Devizanem kod=\"").append(escapeXml(line.getCurrencyCode())).append("\">\n");
            xml.append("      <Vetel>\n");
            xml.append("        <Osszeg>").append(line.getBuyAmount().setScale(2, RoundingMode.HALF_UP)).append("</Osszeg>\n");
            xml.append("        <Arfolyam>").append(line.getBuyRate().setScale(4, RoundingMode.HALF_UP)).append("</Arfolyam>\n");
            xml.append("      </Vetel>\n");
            xml.append("      <Eladas>\n");
            xml.append("        <Osszeg>").append(line.getSellAmount().setScale(2, RoundingMode.HALF_UP)).append("</Osszeg>\n");
            xml.append("        <Arfolyam>").append(line.getSellRate().setScale(4, RoundingMode.HALF_UP)).append("</Arfolyam>\n");
            xml.append("      </Eladas>\n");
            xml.append("      <TranzakcioSzam>").append(line.getTransactionCount()).append("</TranzakcioSzam>\n");
            xml.append("    </Devizanem>\n");
        }
        xml.append("  </Forgalom>\n");

        // Összesítő
        xml.append("  <Osszesito>\n");
        xml.append("    <OsszesBvetelHuf>").append(report.getTotalBuyHuf().setScale(0, RoundingMode.HALF_UP)).append("</OsszesBvetelHuf>\n");
        xml.append("    <OsszesBEladasHuf>").append(report.getTotalSellHuf().setScale(0, RoundingMode.HALF_UP)).append("</OsszesBEladasHuf>\n");
        xml.append("    <OsszesTranzakcio>").append(report.getTotalTransactions()).append("</OsszesTranzakcio>\n");
        xml.append("  </Osszesito>\n");

        xml.append("</Jelentes>");

        return xml.toString();
    }

    /**
     * XML speciális karakterek escapelése.
     */
    private String escapeXml(String value) {
        if (value == null) return "";
        return value
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replace("'", "&apos;");
    }

    // ============ BATCH 7A: COMPANY SZINTŰ RIPORTOK ============

    /**
     * Napi MNB riport generálás company szinten (nem branch szinten).
     */
    @Transactional(readOnly = true)
    public hu.puzzleir.valuta.dto.mnb.MnbDailyReportDto generateDailyMnbReport(LocalDate date) {
        UUID companyId = hu.puzzleir.valuta.security.SecurityUtils.getCurrentCompanyId();
        List<Transaction> transactions = transactionRepository.findActiveByCompanyAndDate(companyId, date);

        Map<String, CurrencyAggregation> aggregations = aggregateTransactions(transactions);

        BigDecimal totalBuyHuf = BigDecimal.ZERO;
        BigDecimal totalSellHuf = BigDecimal.ZERO;
        int totalTxCount = 0;

        List<hu.puzzleir.valuta.dto.mnb.MnbCurrencyLineDto> lines = new ArrayList<>();
        for (Map.Entry<String, CurrencyAggregation> entry : aggregations.entrySet()) {
            CurrencyAggregation agg = entry.getValue();
            lines.add(hu.puzzleir.valuta.dto.mnb.MnbCurrencyLineDto.builder()
                .currencyCode(entry.getKey())
                .buyAmount(agg.buyAmount)
                .sellAmount(agg.sellAmount)
                .buyHuf(agg.buyHufTotal)
                .sellHuf(agg.sellHufTotal)
                .avgBuyRate(agg.getBuyCount() > 0
                    ? agg.buyRateSum.divide(BigDecimal.valueOf(agg.getBuyCount()), 4, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO)
                .avgSellRate(agg.getSellCount() > 0
                    ? agg.sellRateSum.divide(BigDecimal.valueOf(agg.getSellCount()), 4, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO)
                .transactionCount(agg.totalCount)
                .build());

            totalBuyHuf = totalBuyHuf.add(agg.buyHufTotal);
            totalSellHuf = totalSellHuf.add(agg.sellHufTotal);
            totalTxCount += agg.totalCount;
        }

        return hu.puzzleir.valuta.dto.mnb.MnbDailyReportDto.builder()
            .date(date)
            .totalBuyHuf(totalBuyHuf)
            .totalSellHuf(totalSellHuf)
            .totalTransactions(totalTxCount)
            .currencyLines(lines)
            .build();
    }

    /**
     * Havi MNB riport generálás company szinten.
     */
    @Transactional(readOnly = true)
    public hu.puzzleir.valuta.dto.mnb.MnbMonthlyReportDto generateMonthlyMnbReport(YearMonth month) {
        UUID companyId = hu.puzzleir.valuta.security.SecurityUtils.getCurrentCompanyId();
        LocalDate monthStart = month.atDay(1);
        LocalDate monthEnd = month.atEndOfMonth();

        List<Transaction> transactions = transactionRepository.findActiveByCompanyAndMonth(
            companyId, monthStart, monthEnd);

        Map<String, CurrencyAggregation> aggregations = aggregateTransactions(transactions);

        BigDecimal totalBuyHuf = BigDecimal.ZERO;
        BigDecimal totalSellHuf = BigDecimal.ZERO;
        int totalTxCount = 0;

        List<hu.puzzleir.valuta.dto.mnb.MnbCurrencyLineDto> lines = new ArrayList<>();
        for (Map.Entry<String, CurrencyAggregation> entry : aggregations.entrySet()) {
            CurrencyAggregation agg = entry.getValue();
            lines.add(hu.puzzleir.valuta.dto.mnb.MnbCurrencyLineDto.builder()
                .currencyCode(entry.getKey())
                .buyAmount(agg.buyAmount)
                .sellAmount(agg.sellAmount)
                .buyHuf(agg.buyHufTotal)
                .sellHuf(agg.sellHufTotal)
                .avgBuyRate(agg.getBuyCount() > 0
                    ? agg.buyRateSum.divide(BigDecimal.valueOf(agg.getBuyCount()), 4, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO)
                .avgSellRate(agg.getSellCount() > 0
                    ? agg.sellRateSum.divide(BigDecimal.valueOf(agg.getSellCount()), 4, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO)
                .transactionCount(agg.totalCount)
                .build());

            totalBuyHuf = totalBuyHuf.add(agg.buyHufTotal);
            totalSellHuf = totalSellHuf.add(agg.sellHufTotal);
            totalTxCount += agg.totalCount;
        }

        // Munkanapok becslése (hétköznapok)
        int workingDays = 0;
        LocalDate d = monthStart;
        while (!d.isAfter(monthEnd)) {
            if (d.getDayOfWeek().getValue() <= 5) workingDays++;
            d = d.plusDays(1);
        }

        return hu.puzzleir.valuta.dto.mnb.MnbMonthlyReportDto.builder()
            .month(month.toString())
            .totalBuyHuf(totalBuyHuf)
            .totalSellHuf(totalSellHuf)
            .totalTransactions(totalTxCount)
            .workingDays(workingDays)
            .currencyLines(lines)
            .build();
    }

    /**
     * MNB XML export company szinten.
     */
    @Transactional(readOnly = true)
    public String exportMnbXml(LocalDate date) {
        hu.puzzleir.valuta.dto.mnb.MnbDailyReportDto report = generateDailyMnbReport(date);

        String taxId = "00000000-0-00";
        try {
            List<OwnCompany> companies = ownCompanyService.listActive();
            if (!companies.isEmpty() && companies.get(0).getTaxNumber() != null) {
                taxId = companies.get(0).getTaxNumber();
            }
        } catch (Exception e) {
            log.warn("Saját cég adószám nem elérhető: {}", e.getMessage());
        }

        StringBuilder xml = new StringBuilder();
        xml.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
        xml.append("<Jelentes xmlns=\"http://www.mnb.hu/penzvaltok/2010\"");
        xml.append(" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">\n");
        xml.append("  <Fejlec>\n");
        xml.append("    <RiportTipus>DAILY</RiportTipus>\n");
        xml.append("    <RiportDatum>").append(date).append("</RiportDatum>\n");
        xml.append("    <AdoSzam>").append(escapeXml(taxId)).append("</AdoSzam>\n");
        xml.append("  </Fejlec>\n");
        xml.append("  <Forgalom>\n");

        for (hu.puzzleir.valuta.dto.mnb.MnbCurrencyLineDto line : report.getCurrencyLines()) {
            xml.append("    <Devizanem kod=\"").append(escapeXml(line.getCurrencyCode())).append("\">\n");
            xml.append("      <Vetel>\n");
            xml.append("        <Osszeg>").append(line.getBuyAmount().setScale(2, RoundingMode.HALF_UP)).append("</Osszeg>\n");
            xml.append("        <HufOsszeg>").append(line.getBuyHuf().setScale(0, RoundingMode.HALF_UP)).append("</HufOsszeg>\n");
            xml.append("        <Arfolyam>").append(line.getAvgBuyRate().setScale(4, RoundingMode.HALF_UP)).append("</Arfolyam>\n");
            xml.append("      </Vetel>\n");
            xml.append("      <Eladas>\n");
            xml.append("        <Osszeg>").append(line.getSellAmount().setScale(2, RoundingMode.HALF_UP)).append("</Osszeg>\n");
            xml.append("        <HufOsszeg>").append(line.getSellHuf().setScale(0, RoundingMode.HALF_UP)).append("</HufOsszeg>\n");
            xml.append("        <Arfolyam>").append(line.getAvgSellRate().setScale(4, RoundingMode.HALF_UP)).append("</Arfolyam>\n");
            xml.append("      </Eladas>\n");
            xml.append("      <TranzakcioSzam>").append(line.getTransactionCount()).append("</TranzakcioSzam>\n");
            xml.append("    </Devizanem>\n");
        }

        xml.append("  </Forgalom>\n");
        xml.append("  <Osszesito>\n");
        xml.append("    <OsszesBvetelHuf>").append(report.getTotalBuyHuf().setScale(0, RoundingMode.HALF_UP)).append("</OsszesBvetelHuf>\n");
        xml.append("    <OsszesBEladasHuf>").append(report.getTotalSellHuf().setScale(0, RoundingMode.HALF_UP)).append("</OsszesBEladasHuf>\n");
        xml.append("    <OsszesTranzakcio>").append(report.getTotalTransactions()).append("</OsszesTranzakcio>\n");
        xml.append("  </Osszesito>\n");
        xml.append("</Jelentes>");

        return xml.toString();
    }

    /**
     * MNB adat validáció.
     */
    @Transactional(readOnly = true)
    public List<String> validateMnbData(LocalDate date) {
        List<String> errors = new ArrayList<>();

        hu.puzzleir.valuta.dto.mnb.MnbDailyReportDto report = generateDailyMnbReport(date);

        if (report.getTotalTransactions() == 0) {
            errors.add("Nincs tranzakció az adott napon: " + date);
        }

        for (hu.puzzleir.valuta.dto.mnb.MnbCurrencyLineDto line : report.getCurrencyLines()) {
            if (line.getAvgBuyRate().compareTo(BigDecimal.ZERO) <= 0 && line.getBuyAmount().compareTo(BigDecimal.ZERO) > 0) {
                errors.add(line.getCurrencyCode() + ": Vételi árfolyam 0 vagy negatív!");
            }
            if (line.getAvgSellRate().compareTo(BigDecimal.ZERO) <= 0 && line.getSellAmount().compareTo(BigDecimal.ZERO) > 0) {
                errors.add(line.getCurrencyCode() + ": Eladási árfolyam 0 vagy negatív!");
            }
            if (line.getAvgBuyRate().compareTo(BigDecimal.ZERO) > 0 && line.getAvgSellRate().compareTo(BigDecimal.ZERO) > 0) {
                if (line.getAvgBuyRate().compareTo(line.getAvgSellRate()) >= 0) {
                    errors.add(line.getCurrencyCode() + ": Vételi árfolyam >= eladási árfolyam (spread negatív!)");
                }
            }
        }

        // Adószám ellenőrzés
        try {
            List<OwnCompany> companies = ownCompanyService.listActive();
            if (companies.isEmpty()) {
                errors.add("Nincs aktív cég regisztrálva!");
            } else if (companies.get(0).getTaxNumber() == null || companies.get(0).getTaxNumber().isBlank()) {
                errors.add("Cég adószáma hiányzik!");
            }
        } catch (Exception e) {
            errors.add("Cég adatok nem elérhetők: " + e.getMessage());
        }

        return errors;
    }

    // ============ BELSŐ SEGÉDOSZTÁLYOK ============

    /**
     * Valutánkénti aggregáció segédosztály.
     */
    private static class CurrencyAggregation {
        BigDecimal buyAmount = BigDecimal.ZERO;
        BigDecimal sellAmount = BigDecimal.ZERO;
        BigDecimal buyHufTotal = BigDecimal.ZERO;
        BigDecimal sellHufTotal = BigDecimal.ZERO;
        BigDecimal buyRateSum = BigDecimal.ZERO;
        BigDecimal sellRateSum = BigDecimal.ZERO;
        int buyCount = 0;
        int sellCount = 0;
        int totalCount = 0;

        int getBuyCount() { return buyCount; }
        int getSellCount() { return sellCount; }
    }
}
