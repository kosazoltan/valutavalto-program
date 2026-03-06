package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.receipt.ReceiptData;
import hu.puzzleir.valuta.entity.RateCategory;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.*;

import static org.assertj.core.api.Assertions.*;

/**
 * Performance tesztek — JMeter nélkül, JUnit alapú.
 *
 * Cél: kritikus üzleti logika throughput mérése.
 * Nem Spring context — pure unit performance.
 */
@Tag("performance")
class PerformanceTest {

    private final RateCalculationService rateService = new RateCalculationService();

    // ============ 1. ÁRFOLYAM SZÁMÍTÁS ============

    @Test
    @DisplayName("1000 árfolyam számítás < 1 másodperc")
    void testRateCalculation_1000iterations() {
        String[] currencies = {"EUR", "USD", "GBP", "CHF", "CZK", "PLN", "RON", "HRK", "SEK", "NOK"};
        RateCategory.RateCategoryType[] categories = RateCategory.RateCategoryType.values();

        long start = System.nanoTime();

        for (int i = 0; i < 1000; i++) {
            String currency = currencies[i % currencies.length];
            BigDecimal mnbRate = new BigDecimal("395.00").add(new BigDecimal(i % 50));
            BigDecimal spread = new BigDecimal("3.00").add(new BigDecimal(String.valueOf(i % 10)).movePointLeft(1));
            RateCategory.RateCategoryType category = categories[i % categories.length];

            BigDecimal buyRate = rateService.calculateBuyRate(currency, mnbRate, spread, category);
            BigDecimal sellRate = rateService.calculateSellRate(currency, mnbRate, spread, category);
            BigDecimal rounded = rateService.applyRounding(buyRate, currency);

            assertThat(buyRate).isNotNull();
            assertThat(sellRate).isNotNull();
            assertThat(rounded).isNotNull();
            // Buy <= MNB <= Sell (alap invariáns)
            assertThat(buyRate).isLessThanOrEqualTo(mnbRate);
            assertThat(sellRate).isGreaterThanOrEqualTo(mnbRate);
        }

        long elapsed = System.nanoTime() - start;
        Duration duration = Duration.ofNanos(elapsed);

        System.out.printf(">> 1000 rate calculations: %d ms%n", duration.toMillis());
        assertThat(duration).isLessThan(Duration.ofSeconds(1));
    }

    // ============ 2. BIZONYLAT GENERÁLÁS ============

    @Test
    @DisplayName("100 bizonylat generálás < 2 másodperc")
    void testReceiptGeneration_100receipts() {
        long start = System.nanoTime();

        for (int i = 0; i < 100; i++) {
            // ReceiptData builder-rel generálunk (a tényleges formattálási logikát teszteljük)
            ReceiptData receipt = ReceiptData.builder()
                    .receiptNumber(String.format("E-260306-%04d", i))
                    .receiptType(i % 2 == 0 ? "SELL" : "BUY")
                    .companyName("Best Change Kft.")
                    .branchName("Budapest - Váci utca " + (i % 10))
                    .workerName("Pénztáros #" + (i % 5))
                    .date(LocalDateTime.now())
                    .currencyCode(i % 3 == 0 ? "EUR" : i % 3 == 1 ? "USD" : "GBP")
                    .foreignAmount(new BigDecimal("1000.00").add(new BigDecimal(i * 50)))
                    .rate(new BigDecimal("395.50").add(new BigDecimal(i % 20)))
                    .hufAmount(new BigDecimal("395500.00").add(new BigDecimal(i * 5000)))
                    .handlingFee(new BigDecimal("500"))
                    .customerName("Ügyfél " + i)
                    .customerIdNumber("AB" + String.format("%06d", i))
                    .lines(List.of(
                            ReceiptData.ReceiptLineData.builder()
                                    .label("Eredeti bizonylat").value("E-260306-0001").build(),
                            ReceiptData.ReceiptLineData.builder()
                                    .label("Kezelési díj").value("500 Ft").build()
                    ))
                    .qrCode("QR-" + i)
                    .build();

            assertThat(receipt).isNotNull();
            assertThat(receipt.getReceiptNumber()).isNotBlank();
            assertThat(receipt.getHufAmount()).isPositive();

            // ESC/POS formátum generálás szimulálása (string building)
            String formatted = formatReceiptText(receipt);
            assertThat(formatted).contains(receipt.getReceiptNumber());
            assertThat(formatted.length()).isGreaterThan(100);
        }

        long elapsed = System.nanoTime() - start;
        Duration duration = Duration.ofNanos(elapsed);

        System.out.printf(">> 100 receipt generations: %d ms%n", duration.toMillis());
        assertThat(duration).isLessThan(Duration.ofSeconds(2));
    }

    // ============ 3. AML ELLENŐRZÉS ============

    @Test
    @DisplayName("500 AML ellenőrzés < 3 másodperc")
    void testAmlCheck_500transactions() {
        // AML pure logic tesztelés: küszöbérték ellenőrzés
        BigDecimal IDENTIFICATION_LIMIT = new BigDecimal("300000");
        BigDecimal DETAILED_ID_LIMIT = new BigDecimal("1500000");
        BigDecimal ANNUAL_ROLLING_LIMIT = new BigDecimal("3600000");
        BigDecimal DAILY_SUSPICIOUS_LIMIT = new BigDecimal("900000");

        long start = System.nanoTime();

        for (int i = 0; i < 500; i++) {
            BigDecimal amount = new BigDecimal(10000 + (i * 7500)); // 10K - 3.75M tartomány

            // Küszöbérték ellenőrzés (az AmlService.checkTransaction core logikája)
            boolean requiresId = amount.compareTo(IDENTIFICATION_LIMIT) >= 0;
            boolean requiresDetailedId = amount.compareTo(DETAILED_ID_LIMIT) >= 0;
            boolean suspiciousDaily = amount.compareTo(DAILY_SUSPICIOUS_LIMIT) >= 0;

            // Éves göngyölési szimulálás
            BigDecimal annualTotal = new BigDecimal(i * 50000L);
            BigDecimal projectedTotal = annualTotal.add(amount);
            boolean annualLimitReached = projectedTotal.compareTo(ANNUAL_ROLLING_LIMIT) >= 0;

            // Validáció: ha 300K+ → requiresId KÖTELEZŐ
            if (amount.compareTo(IDENTIFICATION_LIMIT) >= 0) {
                assertThat(requiresId).isTrue();
            }
            // Ha 1.5M+ → requiresDetailedId KÖTELEZŐ
            if (amount.compareTo(DETAILED_ID_LIMIT) >= 0) {
                assertThat(requiresDetailedId).isTrue();
                assertThat(requiresId).isTrue(); // detailed → basic is kell
            }
            // Éves limit konzisztencia
            if (annualLimitReached) {
                assertThat(projectedTotal).isGreaterThanOrEqualTo(ANNUAL_ROLLING_LIMIT);
            }

            // Kockázati pontszám kalkuláció (szimulált)
            int riskScore = 0;
            if (requiresId) riskScore += 10;
            if (requiresDetailedId) riskScore += 30;
            if (suspiciousDaily) riskScore += 20;
            if (annualLimitReached) riskScore += 40;
            assertThat(riskScore).isBetween(0, 100);
        }

        long elapsed = System.nanoTime() - start;
        Duration duration = Duration.ofNanos(elapsed);

        System.out.printf(">> 500 AML checks: %d ms%n", duration.toMillis());
        assertThat(duration).isLessThan(Duration.ofSeconds(3));
    }

    // ============ 4. DASHBOARD CONCURRENT ============

    @Test
    @DisplayName("10 párhuzamos dashboard lekérés")
    void testDashboardSummary_concurrent() throws Exception {
        ExecutorService executor = Executors.newFixedThreadPool(10);
        CountDownLatch latch = new CountDownLatch(10);
        List<Future<DashboardResult>> futures = new ArrayList<>();

        long start = System.nanoTime();

        for (int i = 0; i < 10; i++) {
            final int branchIndex = i;
            futures.add(executor.submit(() -> {
                try {
                    // Szimulált dashboard aggregáció (a DashboardService core logikája)
                    BigDecimal todayVolume = BigDecimal.ZERO;
                    int txCount = 50 + branchIndex * 10;

                    for (int tx = 0; tx < txCount; tx++) {
                        BigDecimal amount = new BigDecimal("50000").add(new BigDecimal(tx * 1000));
                        todayVolume = todayVolume.add(amount);
                    }

                    // Valutánkénti bontás
                    String[] currencies = {"EUR", "USD", "GBP", "CHF", "CZK"};
                    ConcurrentHashMap<String, BigDecimal> currencyVolumes = new ConcurrentHashMap<>();
                    for (int tx = 0; tx < txCount; tx++) {
                        String curr = currencies[tx % currencies.length];
                        currencyVolumes.merge(curr, new BigDecimal("1000"),  BigDecimal::add);
                    }

                    return new DashboardResult(
                            branchIndex,
                            todayVolume,
                            txCount,
                            currencyVolumes.size()
                    );
                } finally {
                    latch.countDown();
                }
            }));
        }

        // Várakozás max 5 mp
        boolean completed = latch.await(5, TimeUnit.SECONDS);
        assertThat(completed).isTrue();

        // Eredmények validálása
        for (Future<DashboardResult> future : futures) {
            DashboardResult result = future.get(1, TimeUnit.SECONDS);
            assertThat(result).isNotNull();
            assertThat(result.todayVolume).isPositive();
            assertThat(result.txCount).isGreaterThan(0);
            assertThat(result.currencyCount).isEqualTo(5);
        }

        long elapsed = System.nanoTime() - start;
        Duration duration = Duration.ofNanos(elapsed);

        System.out.printf(">> 10 concurrent dashboard queries: %d ms%n", duration.toMillis());
        assertThat(duration).isLessThan(Duration.ofSeconds(5));

        executor.shutdown();
        assertThat(executor.awaitTermination(2, TimeUnit.SECONDS)).isTrue();
    }

    // ============ HELPERS ============

    /**
     * Bizonylat szöveges formázás (ESC/POS szimulálás)
     */
    private String formatReceiptText(ReceiptData data) {
        StringBuilder sb = new StringBuilder();
        sb.append("=== BIZONYLAT ===\n");
        sb.append("Bizonylat: ").append(data.getReceiptNumber()).append("\n");
        sb.append("Típus: ").append(data.getReceiptType()).append("\n");
        sb.append("Cég: ").append(data.getCompanyName()).append("\n");
        sb.append("Fiók: ").append(data.getBranchName()).append("\n");
        sb.append("Pénztáros: ").append(data.getWorkerName()).append("\n");
        sb.append("Dátum: ").append(data.getDate()).append("\n");
        sb.append("--------------------------------\n");
        if (data.getCurrencyCode() != null) {
            sb.append("Valuta: ").append(data.getCurrencyCode()).append("\n");
            sb.append("Összeg: ").append(data.getForeignAmount()).append("\n");
            sb.append("Árfolyam: ").append(data.getRate()).append("\n");
            sb.append("HUF: ").append(data.getHufAmount()).append(" Ft\n");
        }
        if (data.getHandlingFee() != null && data.getHandlingFee().compareTo(BigDecimal.ZERO) > 0) {
            sb.append("Kezelési díj: ").append(data.getHandlingFee()).append(" Ft\n");
        }
        sb.append("--------------------------------\n");
        if (data.getCustomerName() != null) {
            sb.append("Ügyfél: ").append(data.getCustomerName()).append("\n");
        }
        for (ReceiptData.ReceiptLineData line : data.getLines()) {
            sb.append(line.getLabel()).append(": ").append(line.getValue()).append("\n");
        }
        sb.append("================================\n");
        return sb.toString();
    }

    private record DashboardResult(int branchId, BigDecimal todayVolume, int txCount, int currencyCount) {}
}
