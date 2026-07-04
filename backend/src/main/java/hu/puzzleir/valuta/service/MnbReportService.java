package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.DailyBalance;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.DailyBalanceRepository;
import hu.puzzleir.valuta.dto.mnb.MnbCompanyGroupReportDto;
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
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class MnbReportService {

    static final int MAX_RETRY_COUNT = 3;

    private final MnbReportRepository mnbReportRepository;
    private final TransactionRepository transactionRepository;
    private final BranchRepository branchRepository;
    private final DailyBalanceRepository dailyBalanceRepository;
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

        assertBranchOwnership(branchId);
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

        assertBranchOwnership(branchId);
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
        assertOwnReport(report, reportId);

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
        assertOwnReport(report, reportId);

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

        assertBranchOwnership(branchId);
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
        MnbReport report = mnbReportRepository.findById(reportId)
            .orElseThrow(() -> new ResourceNotFoundException("MNB riport nem található: " + reportId));
        assertOwnReport(report, reportId);
        return report;
    }

    /**
     * Multi-tenant IDOR-védelem (F-3): a riport tulajdonos cége (branch → company)
     * egyezzen a hívó cégével. Cross-tenant esetén — az oldalcsatorna elkerülésére —
     * ugyanazt a {@link ResourceNotFoundException}-t dobja, mint a nem létező riport
     * (nem szivárogtatja, hogy a reportId más cégnél létezik).
     *
     * <p>FONTOS: ez user-facing (controller) hívási útra való. A {@code @Scheduled}
     * MnbDailyReportScheduler kizárólag a {@code generateDailyReport()}-ot hívja,
     * ezt a guardot nem érinti.</p>
     */
    private void assertOwnReport(MnbReport report, UUID reportId) {
        UUID callerCompanyId = hu.puzzleir.valuta.security.SecurityUtils.getCurrentCompanyId();
        UUID reportCompanyId = report.getBranch() != null && report.getBranch().getCompany() != null
            ? report.getBranch().getCompany().getId()
            : null;
        if (reportCompanyId == null || !reportCompanyId.equals(callerCompanyId)) {
            throw new ResourceNotFoundException("MNB riport nem található: " + reportId);
        }
    }

    /**
     * Multi-tenant IDOR-védelem a branchId-paraméteres riport-generálásra
     * (generateDaily/Monthly/WeeklyReport): a user által megadott branchId a hívó
     * cégéhez tartozzon. Cross-tenant esetén — az oldalcsatorna elkerülésére —
     * ugyanaz a {@link ResourceNotFoundException}, mint a nem létező irodánál.
     *
     * <p>FONTOS: a {@code @Scheduled} {@code MnbDailyReportScheduler} auth-kontextus
     * nélkül, minden cég összes aktív irodáját iterálva hívja a
     * {@code generateDailyReport()}-ot (kötelező rendszer-batch). Ott nincs
     * bejelentkezett user, ezért {@link hu.puzzleir.valuta.security.SecurityUtils#getCurrentCompanyIdOrNull()}
     * {@code null}-t ad → a guard kihagyásra kerül, az ütemezett út NEM törik el.
     * Ha viszont van auth-kontextus (controller-út), a branch-tulajdon kötelezően ellenőrzött.</p>
     */
    private void assertBranchOwnership(UUID branchId) {
        UUID callerCompanyId = hu.puzzleir.valuta.security.SecurityUtils.getCurrentCompanyIdOrNull();
        if (callerCompanyId == null) {
            // Nincs auth-kontextus → ütemezett rendszer-batch (MnbDailyReportScheduler).
            // A scheduled cross-tenant generálás szándékos és kötelező, NEM IDOR.
            return;
        }
        if (!branchRepository.existsByIdAndCompanyId(branchId, callerCompanyId)) {
            throw new ResourceNotFoundException("Iroda nem található: " + branchId);
        }
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

    // ============ BATCH 7B: HÁROMSZINTŰ AGGREGÁCIÓ (pénztár → körzet → cég) ============

    /**
     * Haromszintu MNB osszesites: penztar -> koerzet -> ceg.
     * Legacy: Delphi ForgalomGyujtes + KorzetSumma + KftSumma + CegSumma.
     *
     * @param date riport datuma
     * @return hierarchikus riport (ceg + koerzetek + irodak)
     */
    @Transactional(readOnly = true)
    public hu.puzzleir.valuta.dto.mnb.MnbHierarchicalReportDto generateHierarchicalReport(LocalDate date) {
        UUID companyId = hu.puzzleir.valuta.security.SecurityUtils.getCurrentCompanyId();

        // 1. Osszes aktiv iroda, regionCode-dal
        List<Branch> allBranches = branchRepository.findByCompanyIdAndIsActiveTrue(companyId);

        // 2. Csoportositas korzetenként
        Map<String, List<Branch>> regionMap = allBranches.stream()
                .collect(java.util.stream.Collectors.groupingBy(
                        b -> b.getRegionCode() != null ? b.getRegionCode() : "__UNASSIGNED__"));

        // 3. Ceg szintu osszesites
        hu.puzzleir.valuta.dto.mnb.MnbDailyReportDto companyReport = generateDailyMnbReport(date);

        // 4. Koerzet szintu riportok generalasa
        List<hu.puzzleir.valuta.dto.mnb.MnbRegionReportDto> regionReports = new ArrayList<>();
        hu.puzzleir.valuta.dto.mnb.MnbRegionReportDto unassigned = null;

        for (Map.Entry<String, List<Branch>> entry : regionMap.entrySet()) {
            String regionCode = entry.getKey();
            List<Branch> regionBranches = entry.getValue();

            hu.puzzleir.valuta.dto.mnb.MnbRegionReportDto regionReport = buildRegionReport(
                    date, regionCode, regionBranches);

            if ("__UNASSIGNED__".equals(regionCode)) {
                unassigned = regionReport;
                unassigned.setRegionCode(null);
                unassigned.setRegionName("Koerzethez nem rendelt irodak");
            } else {
                regionReports.add(regionReport);
            }
        }

        // Koerzetek rendezese regionCode alapjan
        regionReports.sort(java.util.Comparator.comparing(hu.puzzleir.valuta.dto.mnb.MnbRegionReportDto::getRegionCode));

        // 5. Cegnev
        String companyName = "";
        try {
            List<OwnCompany> companies = ownCompanyService.listActive();
            if (!companies.isEmpty()) {
                companyName = companies.get(0).getName();
            }
        } catch (Exception e) {
            log.warn("Cegnev nem elerheto: {}", e.getMessage());
        }

        // 6. KFT szintű aggregáció (Delphi: KftSumma)
        // Legacy: irodaszám < 151 = "B" (Best Change), >= 151 = "Z" (Pénz-Piac)
        // Modern: Company entity alapján csoportosítjuk
        List<MnbCompanyGroupReportDto> companyGroupReports = buildCompanyGroupReports(
                date, allBranches, regionMap);

        // 7. Készlet validáció (Delphi: AdatKiertekeles)
        List<java.util.UUID> allBranchIds = allBranches.stream()
                .map(Branch::getId)
                .collect(java.util.stream.Collectors.toList());
        List<DailyBalance> allBalances = dailyBalanceRepository.findByBranchIdsAndDate(companyId, allBranchIds, date);
        List<String> validationErrors = new ArrayList<>();
        int validCount = 0;
        int invalidCount = 0;

        // Készlet adatok integrálása a cég szintű currency line-okba
        Map<String, List<DailyBalance>> balByCurrency = allBalances.stream()
                .collect(java.util.stream.Collectors.groupingBy(DailyBalance::getCurrencyCode));

        for (hu.puzzleir.valuta.dto.mnb.MnbCurrencyLineDto line : companyReport.getCurrencyLines()) {
            List<DailyBalance> currBalances = balByCurrency.getOrDefault(line.getCurrencyCode(), java.util.Collections.emptyList());
            enrichCurrencyLineWithBalance(line, currBalances);
        }

        // Per-branch validáció
        Map<java.util.UUID, List<DailyBalance>> balByBranch = allBalances.stream()
                .collect(java.util.stream.Collectors.groupingBy(DailyBalance::getBranchId));
        for (Branch branch : allBranches) {
            List<DailyBalance> branchBalances = balByBranch.getOrDefault(branch.getId(), java.util.Collections.emptyList());
            boolean branchValid = true;
            for (DailyBalance db : branchBalances) {
                db.calculateMnbValidation();
                if (!"OK".equals(db.getValidationStatus())) {
                    branchValid = false;
                    validationErrors.add(branch.getCode() + "/" + db.getCurrencyCode()
                            + ": záró=" + db.getClosingBalance()
                            + " számított=" + db.getCalculatedClosing()
                            + " diff=" + db.getClosingBalance().subtract(db.getCalculatedClosing()).abs());
                }
            }
            if (branchValid) validCount++; else invalidCount++;
        }

        return hu.puzzleir.valuta.dto.mnb.MnbHierarchicalReportDto.builder()
                .date(date)
                .companyName(companyName)
                .totalBuyHuf(companyReport.getTotalBuyHuf())
                .totalSellHuf(companyReport.getTotalSellHuf())
                .totalTransactions(companyReport.getTotalTransactions())
                .companyCurrencyLines(companyReport.getCurrencyLines())
                .companyGroupReports(companyGroupReports)
                .regionReports(regionReports)
                .unassignedBranches(unassigned)
                .validBranchCount(validCount)
                .invalidBranchCount(invalidCount)
                .validationErrors(validationErrors)
                .build();
    }

    /**
     * Koerzet szintu napi riport epitese.
     */
    private hu.puzzleir.valuta.dto.mnb.MnbRegionReportDto buildRegionReport(
            LocalDate date, String regionCode, List<Branch> branches) {

        BigDecimal totalBuyHuf = BigDecimal.ZERO;
        BigDecimal totalSellHuf = BigDecimal.ZERO;
        int totalTxCount = 0;
        Map<String, CurrencyAggregation> regionAggregations = new java.util.LinkedHashMap<>();
        List<hu.puzzleir.valuta.dto.mnb.MnbRegionReportDto.BranchSummary> branchSummaries = new ArrayList<>();

        // Batch query - N+1 kikerulese
        List<java.util.UUID> branchIds = branches.stream()
                .map(Branch::getId)
                .collect(java.util.stream.Collectors.toList());
        List<Transaction> allTransactions = transactionRepository.findActiveByBranchIdsAndDate(branchIds, date);
        Map<java.util.UUID, List<Transaction>> txByBranch = allTransactions.stream()
                .collect(java.util.stream.Collectors.groupingBy(t -> t.getBranch().getId()));

        for (Branch branch : branches) {
            List<Transaction> transactions = txByBranch.getOrDefault(branch.getId(), java.util.Collections.emptyList());
            Map<String, CurrencyAggregation> branchAgg = aggregateTransactions(transactions);

            BigDecimal branchBuyHuf = BigDecimal.ZERO;
            BigDecimal branchSellHuf = BigDecimal.ZERO;
            int branchTxCount = 0;

            for (Map.Entry<String, CurrencyAggregation> cEntry : branchAgg.entrySet()) {
                CurrencyAggregation agg = cEntry.getValue();
                branchBuyHuf = branchBuyHuf.add(agg.buyHufTotal);
                branchSellHuf = branchSellHuf.add(agg.sellHufTotal);
                branchTxCount += agg.totalCount;

                // Merge koerzeti aggregacioba
                regionAggregations.merge(cEntry.getKey(), agg, (existing, newAgg) -> {
                    existing.buyAmount = existing.buyAmount.add(newAgg.buyAmount);
                    existing.sellAmount = existing.sellAmount.add(newAgg.sellAmount);
                    existing.buyHufTotal = existing.buyHufTotal.add(newAgg.buyHufTotal);
                    existing.sellHufTotal = existing.sellHufTotal.add(newAgg.sellHufTotal);
                    existing.buyRateSum = existing.buyRateSum.add(newAgg.buyRateSum);
                    existing.sellRateSum = existing.sellRateSum.add(newAgg.sellRateSum);
                    existing.buyCount += newAgg.buyCount;
                    existing.sellCount += newAgg.sellCount;
                    existing.totalCount += newAgg.totalCount;
                    return existing;
                });
            }

            totalBuyHuf = totalBuyHuf.add(branchBuyHuf);
            totalSellHuf = totalSellHuf.add(branchSellHuf);
            totalTxCount += branchTxCount;

            branchSummaries.add(hu.puzzleir.valuta.dto.mnb.MnbRegionReportDto.BranchSummary.builder()
                    .branchCode(branch.getCode())
                    .branchName(branch.getName())
                    .buyHuf(branchBuyHuf)
                    .sellHuf(branchSellHuf)
                    .transactionCount(branchTxCount)
                    .build());
        }

        // Koerzeti currency lines
        List<hu.puzzleir.valuta.dto.mnb.MnbCurrencyLineDto> currencyLines = new ArrayList<>();
        for (Map.Entry<String, CurrencyAggregation> entry : regionAggregations.entrySet()) {
            CurrencyAggregation agg = entry.getValue();
            currencyLines.add(hu.puzzleir.valuta.dto.mnb.MnbCurrencyLineDto.builder()
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
        }

        // Koerzet nev meghataroza (region code mapping)
        String regionName = getRegionName(regionCode);

        return hu.puzzleir.valuta.dto.mnb.MnbRegionReportDto.builder()
                .date(date)
                .regionCode(regionCode)
                .regionName(regionName)
                .branchCount(branches.size())
                .totalBuyHuf(totalBuyHuf)
                .totalSellHuf(totalSellHuf)
                .totalTransactions(totalTxCount)
                .currencyLines(currencyLines)
                .branchSummaries(branchSummaries)
                .build();
    }

    // ============ S1-01: KFT AGGREGÁCIÓ + KÉSZLET VALIDÁCIÓ ============

    /**
     * KFT (jogi személy csoport) szintű aggregáció.
     *
     * Legacy: Delphi KftSumma — irodaszám < 151 = "B" (Best Change), >= 151 = "Z" (Pénz-Piac).
     * Modern: Company entity alapján csoportosítjuk, ami rugalmasabb.
     */
    private List<MnbCompanyGroupReportDto> buildCompanyGroupReports(
            LocalDate date, List<Branch> allBranches,
            Map<String, List<Branch>> regionMap) {

        // Csoportosítás Company alapján
        Map<UUID, List<Branch>> branchesByCompany = allBranches.stream()
                .filter(b -> b.getCompany() != null)
                .collect(java.util.stream.Collectors.groupingBy(b -> b.getCompany().getId()));

        List<MnbCompanyGroupReportDto> result = new ArrayList<>();

        for (Map.Entry<UUID, List<Branch>> entry : branchesByCompany.entrySet()) {
            List<Branch> companyBranches = entry.getValue();
            Company company = companyBranches.get(0).getCompany();

            // Legacy kompatibilitás: code alapján KFT betűjel
            String groupCode = company.getCode() != null ? company.getCode() : "?";

            // Tranzakciók batch lekérése
            List<UUID> branchIds = companyBranches.stream()
                    .map(Branch::getId)
                    .collect(java.util.stream.Collectors.toList());
            List<Transaction> transactions = transactionRepository.findActiveByBranchIdsAndDate(branchIds, date);
            Map<String, CurrencyAggregation> aggregations = aggregateTransactions(transactions);

            BigDecimal totalBuyHuf = BigDecimal.ZERO;
            BigDecimal totalSellHuf = BigDecimal.ZERO;
            BigDecimal totalCardPayment = BigDecimal.ZERO;
            int totalTxCount = 0;

            // Készlet lekérése
            List<DailyBalance> balances = dailyBalanceRepository.findByBranchIdsAndDate(company.getId(), branchIds, date);
            Map<String, List<DailyBalance>> balByCurrency = balances.stream()
                    .collect(java.util.stream.Collectors.groupingBy(DailyBalance::getCurrencyCode));

            List<hu.puzzleir.valuta.dto.mnb.MnbCurrencyLineDto> lines = new ArrayList<>();
            for (Map.Entry<String, CurrencyAggregation> cEntry : aggregations.entrySet()) {
                CurrencyAggregation agg = cEntry.getValue();
                hu.puzzleir.valuta.dto.mnb.MnbCurrencyLineDto line = hu.puzzleir.valuta.dto.mnb.MnbCurrencyLineDto.builder()
                        .currencyCode(cEntry.getKey())
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
                        .build();

                // Készlet integrálás
                List<DailyBalance> currBalances = balByCurrency.getOrDefault(cEntry.getKey(), java.util.Collections.emptyList());
                enrichCurrencyLineWithBalance(line, currBalances);

                lines.add(line);

                totalBuyHuf = totalBuyHuf.add(agg.buyHufTotal);
                totalSellHuf = totalSellHuf.add(agg.sellHufTotal);
                totalTxCount += agg.totalCount;
                totalCardPayment = totalCardPayment.add(line.getCardPayment());
            }

            // Körzetek a KFT-en belül
            List<hu.puzzleir.valuta.dto.mnb.MnbRegionReportDto> kftRegionReports = new ArrayList<>();
            Map<String, List<Branch>> kftRegionMap = companyBranches.stream()
                    .collect(java.util.stream.Collectors.groupingBy(
                            b -> b.getRegionCode() != null ? b.getRegionCode() : "__UNASSIGNED__"));
            for (Map.Entry<String, List<Branch>> rEntry : kftRegionMap.entrySet()) {
                if (!"__UNASSIGNED__".equals(rEntry.getKey())) {
                    kftRegionReports.add(buildRegionReport(date, rEntry.getKey(), rEntry.getValue()));
                }
            }
            kftRegionReports.sort(java.util.Comparator.comparing(hu.puzzleir.valuta.dto.mnb.MnbRegionReportDto::getRegionCode));

            result.add(MnbCompanyGroupReportDto.builder()
                    .date(date)
                    .groupCode(groupCode)
                    .groupName(company.getName() != null ? company.getName() : groupCode)
                    .totalBuyHuf(totalBuyHuf)
                    .totalSellHuf(totalSellHuf)
                    .totalTransactions(totalTxCount)
                    .totalCardPayment(totalCardPayment)
                    .currencyLines(lines)
                    .regionReports(kftRegionReports)
                    .build());
        }

        // Rendezés groupCode alapján
        result.sort(java.util.Comparator.comparing(MnbCompanyGroupReportDto::getGroupCode));
        return result;
    }

    /**
     * Valutasor készlet-adatainak kitöltése DailyBalance-okból.
     *
     * Legacy: Delphi AdatKiertekeles — nyitó/záró/mozgás összesítés és validáció.
     */
    private void enrichCurrencyLineWithBalance(
            hu.puzzleir.valuta.dto.mnb.MnbCurrencyLineDto line,
            List<DailyBalance> balances) {

        BigDecimal opening = BigDecimal.ZERO;
        BigDecimal closing = BigDecimal.ZERO;
        BigDecimal tIn = BigDecimal.ZERO;
        BigDecimal tOut = BigDecimal.ZERO;
        BigDecimal bIn = BigDecimal.ZERO;
        BigDecimal bOut = BigDecimal.ZERO;
        BigDecimal surp = BigDecimal.ZERO;
        BigDecimal short_ = BigDecimal.ZERO;
        BigDecimal retIn = BigDecimal.ZERO;
        BigDecimal retOut = BigDecimal.ZERO;
        BigDecimal card = BigDecimal.ZERO;

        for (DailyBalance db : balances) {
            opening = opening.add(db.getOpeningBalance());
            closing = closing.add(db.getClosingBalance());
            tIn = tIn.add(db.getTransfersIn());
            tOut = tOut.add(db.getTransfersOut());
            bIn = bIn.add(db.getBankIn());
            bOut = bOut.add(db.getBankOut());
            surp = surp.add(db.getSurplus());
            short_ = short_.add(db.getShortage());
            retIn = retIn.add(db.getReturnsIn());
            retOut = retOut.add(db.getReturnsOut());
            card = card.add(db.getCardPayment());
        }

        line.setOpeningBalance(opening);
        line.setClosingBalance(closing);
        line.setTransfersIn(tIn);
        line.setTransfersOut(tOut);
        line.setBankIn(bIn);
        line.setBankOut(bOut);
        line.setSurplus(surp);
        line.setShortage(short_);
        line.setReturnsIn(retIn);
        line.setReturnsOut(retOut);
        line.setCardPayment(card);

        // Validáció: bevétel - kiadás = számított záró
        BigDecimal income = opening
                .add(line.getBuyAmount())
                .add(surp)
                .add(tIn)
                .add(bIn)
                .add(retIn);
        BigDecimal expense = line.getSellAmount()
                .add(short_)
                .add(tOut)
                .add(bOut)
                .add(retOut);
        BigDecimal calcClosing = income.subtract(expense);
        line.setCalculatedClosing(calcClosing);

        BigDecimal diff = closing.subtract(calcClosing).abs();
        line.setBalanceDiff(diff);
        line.setValidationStatus(diff.compareTo(BigDecimal.ZERO) == 0 ? "OK" : "?");
    }

    /**
     * Legacy koerzet kodok nevekre forditasa.
     * Forras: Branch entity Javadoc (V60 migracio).
     */
    private String getRegionName(String regionCode) {
        if (regionCode == null) return "Ismeretlen";
        return switch (regionCode) {
            case "10" -> "Szeksz\u00e1rd";
            case "20" -> "Szeged";
            case "40" -> "Kecskem\u00e9t";
            case "50" -> "Debrecen";
            case "63" -> "Ny\u00edregyh\u00e1za";
            case "75" -> "B\u00e9k\u00e9scsaba";
            case "120" -> "P\u00e9cs";
            case "145" -> "Kaposv\u00e1r";
            default -> "K\u00f6rzet " + regionCode;
        };
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
