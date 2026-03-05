package hu.puzzleir.valuta.service;

import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.entity.Company;
import com.puzzleir.backend.exception.ResourceNotFoundException;
import com.puzzleir.backend.exception.ValidationException;
import com.puzzleir.backend.repository.BranchRepository;
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

    private final MnbReportRepository mnbReportRepository;
    private final TransactionRepository transactionRepository;
    private final BranchRepository branchRepository;
    private final OwnCompanyService ownCompanyService;

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
     * Placeholder — a valós MNB API integráció későbbi fejlesztés.
     */
    public MnbSubmissionResult submitReport(UUID reportId) {
        MnbReport report = mnbReportRepository.findById(reportId)
            .orElseThrow(() -> new ResourceNotFoundException("MNB riport nem található: " + reportId));

        if (report.getStatus() != MnbReportStatus.DRAFT) {
            throw new ValidationException("Csak DRAFT státuszú riport küldhető be! Jelenlegi: " + report.getStatus());
        }

        log.info("MNB riport beküldés (placeholder): reportId={}", reportId);

        // Placeholder: szimulált sikeres beküldés
        report.setStatus(MnbReportStatus.SUBMITTED);
        report.setSubmittedAt(LocalDateTime.now());
        mnbReportRepository.save(report);

        return MnbSubmissionResult.builder()
            .success(true)
            .referenceNumber("MNB-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
            .build();
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
     * MNB-kompatibilis XML generálása.
     *
     * Legacy: MNB gyűjtő DLL XML formátum.
     */
    private String generateMnbXml(MnbReport report, Branch branch) {
        // Saját cég adatainak lekérése (adószám, stb.)
        String taxId = "00000000-0-00"; // default placeholder
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
        xml.append("<MNBReport>\n");

        // Header
        xml.append("  <Header>\n");
        xml.append("    <ReportType>").append(report.getReportType().name()).append("</ReportType>\n");
        xml.append("    <ReportDate>").append(report.getReportDate()).append("</ReportDate>\n");
        xml.append("    <CompanyTaxId>").append(escapeXml(taxId)).append("</CompanyTaxId>\n");
        xml.append("    <BranchCode>").append(escapeXml(branch.getCode())).append("</BranchCode>\n");
        xml.append("  </Header>\n");

        // Transactions
        xml.append("  <Transactions>\n");
        for (MnbReportLine line : report.getLines()) {
            xml.append("    <Currency code=\"").append(escapeXml(line.getCurrencyCode())).append("\">\n");
            xml.append("      <BuyAmount>").append(line.getBuyAmount().setScale(2, RoundingMode.HALF_UP)).append("</BuyAmount>\n");
            xml.append("      <SellAmount>").append(line.getSellAmount().setScale(2, RoundingMode.HALF_UP)).append("</SellAmount>\n");
            xml.append("      <AvgBuyRate>").append(line.getBuyRate().setScale(2, RoundingMode.HALF_UP)).append("</AvgBuyRate>\n");
            xml.append("      <AvgSellRate>").append(line.getSellRate().setScale(2, RoundingMode.HALF_UP)).append("</AvgSellRate>\n");
            xml.append("      <TransactionCount>").append(line.getTransactionCount()).append("</TransactionCount>\n");
            xml.append("    </Currency>\n");
        }
        xml.append("  </Transactions>\n");

        // Summary
        xml.append("  <Summary>\n");
        xml.append("    <TotalBuyHuf>").append(report.getTotalBuyHuf().setScale(0, RoundingMode.HALF_UP)).append("</TotalBuyHuf>\n");
        xml.append("    <TotalSellHuf>").append(report.getTotalSellHuf().setScale(0, RoundingMode.HALF_UP)).append("</TotalSellHuf>\n");
        xml.append("    <TotalTransactions>").append(report.getTotalTransactions()).append("</TotalTransactions>\n");
        xml.append("  </Summary>\n");

        xml.append("</MNBReport>");

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
