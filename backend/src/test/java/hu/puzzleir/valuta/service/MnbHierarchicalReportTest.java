package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.mnb.MnbHierarchicalReportDto;
import hu.puzzleir.valuta.dto.mnb.MnbRegionReportDto;
import hu.puzzleir.valuta.dto.mnb.MnbCurrencyLineDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.DailyBalanceRepository;
import hu.puzzleir.valuta.repository.MnbReportRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.*;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * P2 Sprint 3 — MNB háromszintű aggregáció (pénztár → körzet → cég) unit tesztek.
 *
 * Fókusz:
 *  - MnbRegionReportDto + BranchSummary builder/Lombok
 *  - MnbHierarchicalReportDto builder/Lombok
 *  - generateHierarchicalReport: cég totálok, regionReports, unassignedBranches
 *  - buildRegionReport: CurrencyAggregation merge (9 mező), BranchSummary-k
 *  - getRegionName: 8 körzet kód + default fallback + null
 *  - Edge case-ek: üres, nincs aktív iroda, minden unassigned, egyetlen branch
 */
@ExtendWith(MockitoExtension.class)
@org.mockito.junit.jupiter.MockitoSettings(strictness = org.mockito.quality.Strictness.LENIENT)
@DisplayName("P2 Sprint 3 — MNB háromszintű aggregáció tesztek")
class MnbHierarchicalReportTest {

    @InjectMocks
    private MnbReportService mnbReportService;

    @Mock
    private MnbReportRepository mnbReportRepository;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private BranchRepository branchRepository;

    @Mock
    private DailyBalanceRepository dailyBalanceRepository;

    @Mock
    private OwnCompanyService ownCompanyService;

    @Mock
    private MnbApiClient mnbApiClient;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID_1 = UUID.randomUUID();
    private static final UUID BRANCH_ID_2 = UUID.randomUUID();
    private static final UUID BRANCH_ID_3 = UUID.randomUUID();

    private static final LocalDate TEST_DATE = LocalDate.of(2026, 4, 4);

    @BeforeEach
    void setUp() {
        WorkerAuthenticationDetails details = new WorkerAuthenticationDetails(
                1L, COMPANY_ID, BRANCH_ID_1, "MANAGER");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("test", "pass", "ROLE_MANAGER");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);

        // S1-01: DailyBalanceRepository alapértelmezett mock (üres készlet)
        lenient().when(dailyBalanceRepository.findByBranchIdsAndDate(org.mockito.ArgumentMatchers.eq(COMPANY_ID), anyList(), any(LocalDate.class)))
                .thenReturn(Collections.emptyList());
    }

    // ══════════════════════════════════════════════════════════════
    //  DTO BUILDER + LOMBOK TESZTEK
    // ══════════════════════════════════════════════════════════════

    @Nested
    @DisplayName("MnbRegionReportDto builder + Lombok")
    class MnbRegionReportDtoBuilderTest {

        @Test
        @DisplayName("Minden mező kitöltve — builder teljes")
        void testBuilderAllFields() {
            LocalDate date = LocalDate.of(2026, 4, 1);
            List<MnbCurrencyLineDto> lines = List.of(
                    MnbCurrencyLineDto.builder().currencyCode("EUR").transactionCount(5).build()
            );
            List<MnbRegionReportDto.BranchSummary> summaries = List.of(
                    MnbRegionReportDto.BranchSummary.builder()
                            .branchCode("BP01")
                            .branchName("Budapest")
                            .buyHuf(new BigDecimal("100000"))
                            .sellHuf(new BigDecimal("80000"))
                            .transactionCount(3)
                            .build()
            );

            MnbRegionReportDto dto = MnbRegionReportDto.builder()
                    .date(date)
                    .regionCode("10")
                    .regionName("Szeksz\u00e1rd")
                    .branchCount(1)
                    .totalBuyHuf(new BigDecimal("100000"))
                    .totalSellHuf(new BigDecimal("80000"))
                    .totalTransactions(3)
                    .currencyLines(lines)
                    .branchSummaries(summaries)
                    .build();

            assertThat(dto.getDate()).isEqualTo(date);
            assertThat(dto.getRegionCode()).isEqualTo("10");
            assertThat(dto.getRegionName()).isEqualTo("Szeksz\u00e1rd");
            assertThat(dto.getBranchCount()).isEqualTo(1);
            assertThat(dto.getTotalBuyHuf()).isEqualByComparingTo("100000");
            assertThat(dto.getTotalSellHuf()).isEqualByComparingTo("80000");
            assertThat(dto.getTotalTransactions()).isEqualTo(3);
            assertThat(dto.getCurrencyLines()).hasSize(1);
            assertThat(dto.getBranchSummaries()).hasSize(1);
        }

        @Test
        @DisplayName("BranchSummary inner class builder minden mezővel")
        void testBranchSummaryBuilderAllFields() {
            MnbRegionReportDto.BranchSummary summary = MnbRegionReportDto.BranchSummary.builder()
                    .branchCode("SZK01")
                    .branchName("Szekszárd Főiroda")
                    .buyHuf(new BigDecimal("500000"))
                    .sellHuf(new BigDecimal("300000"))
                    .transactionCount(12)
                    .build();

            assertThat(summary.getBranchCode()).isEqualTo("SZK01");
            assertThat(summary.getBranchName()).isEqualTo("Szekszárd Főiroda");
            assertThat(summary.getBuyHuf()).isEqualByComparingTo("500000");
            assertThat(summary.getSellHuf()).isEqualByComparingTo("300000");
            assertThat(summary.getTransactionCount()).isEqualTo(12);
        }

        @Test
        @DisplayName("BranchSummary setter/getter (Lombok @Setter)")
        void testBranchSummarySetterGetter() {
            MnbRegionReportDto.BranchSummary summary = new MnbRegionReportDto.BranchSummary();
            summary.setBranchCode("TEST");
            summary.setBranchName("Teszt Iroda");
            summary.setBuyHuf(BigDecimal.TEN);
            summary.setSellHuf(BigDecimal.ONE);
            summary.setTransactionCount(7);

            assertThat(summary.getBranchCode()).isEqualTo("TEST");
            assertThat(summary.getBranchName()).isEqualTo("Teszt Iroda");
            assertThat(summary.getBuyHuf()).isEqualByComparingTo("10");
            assertThat(summary.getSellHuf()).isEqualByComparingTo("1");
            assertThat(summary.getTransactionCount()).isEqualTo(7);
        }

        @Test
        @DisplayName("MnbRegionReportDto NoArgsConstructor + setterek")
        void testNoArgsAndSetters() {
            MnbRegionReportDto dto = new MnbRegionReportDto();
            dto.setRegionCode("20");
            dto.setRegionName("Szeged");
            dto.setBranchCount(3);
            dto.setTotalTransactions(42);

            assertThat(dto.getRegionCode()).isEqualTo("20");
            assertThat(dto.getRegionName()).isEqualTo("Szeged");
            assertThat(dto.getBranchCount()).isEqualTo(3);
            assertThat(dto.getTotalTransactions()).isEqualTo(42);
        }
    }

    @Nested
    @DisplayName("MnbHierarchicalReportDto builder + Lombok")
    class MnbHierarchicalReportDtoBuilderTest {

        @Test
        @DisplayName("Hierarchikus DTO builder minden mezővel")
        void testBuilderAllFields() {
            List<MnbRegionReportDto> regions = List.of(
                    MnbRegionReportDto.builder().regionCode("10").build()
            );
            MnbRegionReportDto unassigned = MnbRegionReportDto.builder().regionCode(null).build();

            MnbHierarchicalReportDto dto = MnbHierarchicalReportDto.builder()
                    .date(TEST_DATE)
                    .companyName("Best Change Kft.")
                    .totalBuyHuf(new BigDecimal("1000000"))
                    .totalSellHuf(new BigDecimal("800000"))
                    .totalTransactions(50)
                    .companyCurrencyLines(List.of())
                    .regionReports(regions)
                    .unassignedBranches(unassigned)
                    .build();

            assertThat(dto.getDate()).isEqualTo(TEST_DATE);
            assertThat(dto.getCompanyName()).isEqualTo("Best Change Kft.");
            assertThat(dto.getTotalBuyHuf()).isEqualByComparingTo("1000000");
            assertThat(dto.getTotalSellHuf()).isEqualByComparingTo("800000");
            assertThat(dto.getTotalTransactions()).isEqualTo(50);
            assertThat(dto.getCompanyCurrencyLines()).isEmpty();
            assertThat(dto.getRegionReports()).hasSize(1);
            assertThat(dto.getUnassignedBranches()).isNotNull();
            assertThat(dto.getUnassignedBranches().getRegionCode()).isNull();
        }

        @Test
        @DisplayName("MnbHierarchicalReportDto NoArgsConstructor + setterek")
        void testNoArgsAndSetters() {
            MnbHierarchicalReportDto dto = new MnbHierarchicalReportDto();
            dto.setDate(TEST_DATE);
            dto.setCompanyName("EBC Zrt.");
            dto.setTotalTransactions(100);

            assertThat(dto.getDate()).isEqualTo(TEST_DATE);
            assertThat(dto.getCompanyName()).isEqualTo("EBC Zrt.");
            assertThat(dto.getTotalTransactions()).isEqualTo(100);
        }

        @Test
        @DisplayName("unassignedBranches null ha nincs unassigned iroda")
        void testUnassignedBranchesNullWhenNone() {
            MnbHierarchicalReportDto dto = MnbHierarchicalReportDto.builder()
                    .date(TEST_DATE)
                    .totalTransactions(0)
                    .unassignedBranches(null)
                    .build();

            assertThat(dto.getUnassignedBranches()).isNull();
        }
    }

    // ══════════════════════════════════════════════════════════════
    //  getRegionName — 8 körzet kód + default + null
    // ══════════════════════════════════════════════════════════════

    @Nested
    @DisplayName("generateHierarchicalReport → getRegionName körzet mapping")
    class GetRegionNameViaHierarchicalTest {

        /**
         * Teszti a getRegionName metódust közvetve — generateHierarchicalReport hívásán
         * keresztül ellenőrizzük, hogy a regionName helyes értéket kap.
         */
        private MnbHierarchicalReportDto buildReportWithRegionCode(String regionCode) {
            Branch branch = buildBranch(BRANCH_ID_1, "B01", "Iroda", regionCode);
            when(branchRepository.findByCompanyIdAndIsActiveTrue(COMPANY_ID))
                    .thenReturn(List.of(branch));
            when(transactionRepository.findActiveByCompanyAndDate(eq(COMPANY_ID), eq(TEST_DATE)))
                    .thenReturn(List.of());
            when(transactionRepository.findActiveByBranchIdsAndDate(anyList(), eq(TEST_DATE)))
                    .thenReturn(List.of());
            when(ownCompanyService.listActive()).thenReturn(List.of());
            return mnbReportService.generateHierarchicalReport(TEST_DATE);
        }

        @Test @DisplayName("regionCode=10 → Szekszard")
        void testRegion10() {
            assertThat(buildReportWithRegionCode("10").getRegionReports().get(0).getRegionName())
                    .isEqualTo("Szeksz\u00e1rd");
        }

        @Test @DisplayName("regionCode=20 → Szeged")
        void testRegion20() {
            assertThat(buildReportWithRegionCode("20").getRegionReports().get(0).getRegionName())
                    .isEqualTo("Szeged");
        }

        @Test @DisplayName("regionCode=40 → Kecskemet")
        void testRegion40() {
            assertThat(buildReportWithRegionCode("40").getRegionReports().get(0).getRegionName())
                    .isEqualTo("Kecskem\u00e9t");
        }

        @Test @DisplayName("regionCode=50 → Debrecen")
        void testRegion50() {
            assertThat(buildReportWithRegionCode("50").getRegionReports().get(0).getRegionName())
                    .isEqualTo("Debrecen");
        }

        @Test @DisplayName("regionCode=63 → Nyiregyhaza")
        void testRegion63() {
            assertThat(buildReportWithRegionCode("63").getRegionReports().get(0).getRegionName())
                    .isEqualTo("Ny\u00edregyh\u00e1za");
        }

        @Test @DisplayName("regionCode=75 → Bekescsaba")
        void testRegion75() {
            assertThat(buildReportWithRegionCode("75").getRegionReports().get(0).getRegionName())
                    .isEqualTo("B\u00e9k\u00e9scsaba");
        }

        @Test @DisplayName("regionCode=120 → Pecs")
        void testRegion120() {
            assertThat(buildReportWithRegionCode("120").getRegionReports().get(0).getRegionName())
                    .isEqualTo("P\u00e9cs");
        }

        @Test @DisplayName("regionCode=145 → Kaposvar")
        void testRegion145() {
            assertThat(buildReportWithRegionCode("145").getRegionReports().get(0).getRegionName())
                    .isEqualTo("Kaposv\u00e1r");
        }

        @Test @DisplayName("ismeretlen kód → 'Koerzet XYZ' default fallback")
        void testRegionUnknownDefaultFallback() {
            assertThat(buildReportWithRegionCode("999").getRegionReports().get(0).getRegionName())
                    .isEqualTo("K\u00f6rzet 999");
        }

        @Test @DisplayName("null regionCode → unassignedBranches.regionName = 'Koerzethez nem rendelt irodak'")
        void testRegionNullBecomesUnassigned() {
            Branch branch = buildBranch(BRANCH_ID_1, "B01", "Iroda", null);
            when(branchRepository.findByCompanyIdAndIsActiveTrue(COMPANY_ID))
                    .thenReturn(List.of(branch));
            when(transactionRepository.findActiveByCompanyAndDate(eq(COMPANY_ID), eq(TEST_DATE)))
                    .thenReturn(List.of());
            when(transactionRepository.findActiveByBranchIdsAndDate(anyList(), eq(TEST_DATE)))
                    .thenReturn(List.of());
            when(ownCompanyService.listActive()).thenReturn(List.of());

            MnbHierarchicalReportDto result = mnbReportService.generateHierarchicalReport(TEST_DATE);

            assertThat(result.getUnassignedBranches()).isNotNull();
            assertThat(result.getUnassignedBranches().getRegionCode()).isNull();
            assertThat(result.getUnassignedBranches().getRegionName())
                    .isEqualTo("Koerzethez nem rendelt irodak");
            assertThat(result.getRegionReports()).isEmpty();
        }
    }

    // ══════════════════════════════════════════════════════════════
    //  generateHierarchicalReport — cég szintű totálok
    // ══════════════════════════════════════════════════════════════

    @Nested
    @DisplayName("generateHierarchicalReport — cég szintű totálok")
    class GenerateHierarchicalReportCompanyTotalsTest {

        @Test
        @DisplayName("Cég szintű összegek helyesek két különböző körzet tranzakcióiból")
        void testCompanyTotalsAggregated() {
            Branch b1 = buildBranch(BRANCH_ID_1, "B01", "Iroda1", "10");
            Branch b2 = buildBranch(BRANCH_ID_2, "B02", "Iroda2", "20");

            when(branchRepository.findByCompanyIdAndIsActiveTrue(COMPANY_ID))
                    .thenReturn(List.of(b1, b2));

            var eur = buildCurrency("EUR");
            // Cég szintű tranzakciók
            Transaction companyTx1 = createTxWithBranch(TransactionType.BUY, eur,
                    new BigDecimal("1000"), new BigDecimal("395000"), new BigDecimal("395"), b1);
            Transaction companyTx2 = createTxWithBranch(TransactionType.SELL, eur,
                    new BigDecimal("500"), new BigDecimal("202500"), new BigDecimal("405"), b2);
            when(transactionRepository.findActiveByCompanyAndDate(eq(COMPANY_ID), eq(TEST_DATE)))
                    .thenReturn(List.of(companyTx1, companyTx2));

            // Branch szintű tranzakciók (nem szükséges összhang a cég totállal ebben a tesztben)
            when(transactionRepository.findActiveByBranchIdsAndDate(anyList(), eq(TEST_DATE)))
                    .thenReturn(List.of(companyTx1, companyTx2));

            when(ownCompanyService.listActive()).thenReturn(buildOwnCompanyList("Best Change Kft."));

            MnbHierarchicalReportDto result = mnbReportService.generateHierarchicalReport(TEST_DATE);

            assertThat(result).isNotNull();
            assertThat(result.getDate()).isEqualTo(TEST_DATE);
            assertThat(result.getCompanyName()).isEqualTo("Best Change Kft.");
            assertThat(result.getTotalBuyHuf()).isEqualByComparingTo("395000");
            assertThat(result.getTotalSellHuf()).isEqualByComparingTo("202500");
            assertThat(result.getTotalTransactions()).isEqualTo(2);
            assertThat(result.getCompanyCurrencyLines()).isNotEmpty();
        }

        @Test
        @DisplayName("companyCurrencyLines EUR adatai helyesek")
        void testCompanyCurrencyLineEurFields() {
            Branch b1 = buildBranch(BRANCH_ID_1, "B01", "Iroda1", "10");
            when(branchRepository.findByCompanyIdAndIsActiveTrue(COMPANY_ID))
                    .thenReturn(List.of(b1));

            var eur = buildCurrency("EUR");
            Transaction tx = createTxWithBranch(TransactionType.BUY, eur,
                    new BigDecimal("2000"), new BigDecimal("790000"), new BigDecimal("395"), b1);
            when(transactionRepository.findActiveByCompanyAndDate(eq(COMPANY_ID), eq(TEST_DATE)))
                    .thenReturn(List.of(tx));
            when(transactionRepository.findActiveByBranchIdsAndDate(anyList(), eq(TEST_DATE)))
                    .thenReturn(List.of(tx));
            when(ownCompanyService.listActive()).thenReturn(List.of());

            MnbHierarchicalReportDto result = mnbReportService.generateHierarchicalReport(TEST_DATE);

            assertThat(result.getCompanyCurrencyLines()).hasSize(1);
            MnbCurrencyLineDto line = result.getCompanyCurrencyLines().get(0);
            assertThat(line.getCurrencyCode()).isEqualTo("EUR");
            assertThat(line.getBuyAmount()).isEqualByComparingTo("2000");
            assertThat(line.getBuyHuf()).isEqualByComparingTo("790000");
            assertThat(line.getAvgBuyRate()).isEqualByComparingTo("395.0000");
        }

        @Test
        @DisplayName("regionReports lista rendezve regionCode szerint")
        void testRegionReportsSortedByRegionCode() {
            Branch b1 = buildBranch(BRANCH_ID_1, "B01", "Iroda1", "50"); // Debrecen
            Branch b2 = buildBranch(BRANCH_ID_2, "B02", "Iroda2", "10"); // Szekszard
            Branch b3 = buildBranch(BRANCH_ID_3, "B03", "Iroda3", "20"); // Szeged

            when(branchRepository.findByCompanyIdAndIsActiveTrue(COMPANY_ID))
                    .thenReturn(List.of(b1, b2, b3));
            when(transactionRepository.findActiveByCompanyAndDate(eq(COMPANY_ID), eq(TEST_DATE)))
                    .thenReturn(List.of());
            when(transactionRepository.findActiveByBranchIdsAndDate(anyList(), eq(TEST_DATE)))
                    .thenReturn(List.of());
            when(ownCompanyService.listActive()).thenReturn(List.of());

            MnbHierarchicalReportDto result = mnbReportService.generateHierarchicalReport(TEST_DATE);

            assertThat(result.getRegionReports()).hasSize(3);
            // Rendezés: "10" < "20" < "50"
            assertThat(result.getRegionReports().get(0).getRegionCode()).isEqualTo("10");
            assertThat(result.getRegionReports().get(1).getRegionCode()).isEqualTo("20");
            assertThat(result.getRegionReports().get(2).getRegionCode()).isEqualTo("50");
        }

        @Test
        @DisplayName("unassignedBranches null ha minden iroda hozzá van rendelve körzethez")
        void testNoUnassignedBranches() {
            Branch b1 = buildBranch(BRANCH_ID_1, "B01", "Iroda1", "10");
            when(branchRepository.findByCompanyIdAndIsActiveTrue(COMPANY_ID))
                    .thenReturn(List.of(b1));
            when(transactionRepository.findActiveByCompanyAndDate(eq(COMPANY_ID), eq(TEST_DATE)))
                    .thenReturn(List.of());
            when(transactionRepository.findActiveByBranchIdsAndDate(anyList(), eq(TEST_DATE)))
                    .thenReturn(List.of());
            when(ownCompanyService.listActive()).thenReturn(List.of());

            MnbHierarchicalReportDto result = mnbReportService.generateHierarchicalReport(TEST_DATE);

            assertThat(result.getUnassignedBranches()).isNull();
        }
    }

    // ══════════════════════════════════════════════════════════════
    //  buildRegionReport — CurrencyAggregation merge (9 mező)
    // ══════════════════════════════════════════════════════════════

    @Nested
    @DisplayName("buildRegionReport — CurrencyAggregation merge + BranchSummary-k")
    class BuildRegionReportTest {

        @Test
        @DisplayName("Két branch EUR tranzakciói mergelve — 9 mező helyes")
        void testCurrencyAggregationMerge9Fields() {
            Branch b1 = buildBranch(BRANCH_ID_1, "SZK01", "Szekszárd 1", "10");
            Branch b2 = buildBranch(BRANCH_ID_2, "SZK02", "Szekszárd 2", "10");

            when(branchRepository.findByCompanyIdAndIsActiveTrue(COMPANY_ID))
                    .thenReturn(List.of(b1, b2));

            var eur = buildCurrency("EUR");

            // Branch 1: 1 BUY
            Transaction b1tx = createTxWithBranch(TransactionType.BUY, eur,
                    new BigDecimal("1000"), new BigDecimal("395000"), new BigDecimal("395"), b1);
            // Branch 2: 1 BUY + 1 SELL
            Transaction b2buyTx = createTxWithBranch(TransactionType.BUY, eur,
                    new BigDecimal("500"), new BigDecimal("199000"), new BigDecimal("398"), b2);
            Transaction b2sellTx = createTxWithBranch(TransactionType.SELL, eur,
                    new BigDecimal("300"), new BigDecimal("123000"), new BigDecimal("410"), b2);

            when(transactionRepository.findActiveByCompanyAndDate(eq(COMPANY_ID), eq(TEST_DATE)))
                    .thenReturn(List.of(b1tx, b2buyTx, b2sellTx));
            when(transactionRepository.findActiveByBranchIdsAndDate(anyList(), eq(TEST_DATE)))
                    .thenReturn(List.of(b1tx, b2buyTx, b2sellTx));
            when(ownCompanyService.listActive()).thenReturn(List.of());

            MnbHierarchicalReportDto result = mnbReportService.generateHierarchicalReport(TEST_DATE);

            assertThat(result.getRegionReports()).hasSize(1);
            MnbRegionReportDto region = result.getRegionReports().get(0);
            assertThat(region.getRegionCode()).isEqualTo("10");
            assertThat(region.getRegionName()).isEqualTo("Szeksz\u00e1rd");
            assertThat(region.getBranchCount()).isEqualTo(2);

            // Összegek: b1 + b2
            assertThat(region.getTotalBuyHuf()).isEqualByComparingTo("594000"); // 395000+199000
            assertThat(region.getTotalSellHuf()).isEqualByComparingTo("123000");
            assertThat(region.getTotalTransactions()).isEqualTo(3); // 1+2

            // CurrencyLines EUR merge ellenőrzése (9 mező)
            assertThat(region.getCurrencyLines()).hasSize(1);
            MnbCurrencyLineDto eurLine = region.getCurrencyLines().get(0);
            assertThat(eurLine.getCurrencyCode()).isEqualTo("EUR");
            // buyAmount: 1000+500=1500
            assertThat(eurLine.getBuyAmount()).isEqualByComparingTo("1500");
            // sellAmount: 300
            assertThat(eurLine.getSellAmount()).isEqualByComparingTo("300");
            // buyHuf: 395000+199000=594000
            assertThat(eurLine.getBuyHuf()).isEqualByComparingTo("594000");
            // sellHuf: 123000
            assertThat(eurLine.getSellHuf()).isEqualByComparingTo("123000");
            // avgBuyRate: (395+398)/2=396.5000
            assertThat(eurLine.getAvgBuyRate()).isEqualByComparingTo("396.5000");
            // avgSellRate: 410/1=410.0000
            assertThat(eurLine.getAvgSellRate()).isEqualByComparingTo("410.0000");
            // transactionCount: 3
            assertThat(eurLine.getTransactionCount()).isEqualTo(3);
        }

        @Test
        @DisplayName("Két branch különböző valuták — EUR és USD szétválasztva a régióban")
        void testMultipleCurrenciesInRegion() {
            Branch b1 = buildBranch(BRANCH_ID_1, "SZK01", "Szekszárd 1", "10");
            Branch b2 = buildBranch(BRANCH_ID_2, "SZK02", "Szekszárd 2", "10");

            when(branchRepository.findByCompanyIdAndIsActiveTrue(COMPANY_ID))
                    .thenReturn(List.of(b1, b2));

            var eur = buildCurrency("EUR");
            var usd = buildCurrency("USD");

            Transaction eurTx = createTxWithBranch(TransactionType.BUY, eur,
                    new BigDecimal("1000"), new BigDecimal("395000"), new BigDecimal("395"), b1);
            Transaction usdTx = createTxWithBranch(TransactionType.SELL, usd,
                    new BigDecimal("500"), new BigDecimal("192000"), new BigDecimal("384"), b2);

            when(transactionRepository.findActiveByCompanyAndDate(eq(COMPANY_ID), eq(TEST_DATE)))
                    .thenReturn(List.of(eurTx, usdTx));
            when(transactionRepository.findActiveByBranchIdsAndDate(anyList(), eq(TEST_DATE)))
                    .thenReturn(List.of(eurTx, usdTx));
            when(ownCompanyService.listActive()).thenReturn(List.of());

            MnbHierarchicalReportDto result = mnbReportService.generateHierarchicalReport(TEST_DATE);

            MnbRegionReportDto region = result.getRegionReports().get(0);
            assertThat(region.getCurrencyLines()).hasSize(2);
            List<String> codes = region.getCurrencyLines().stream()
                    .map(MnbCurrencyLineDto::getCurrencyCode).toList();
            assertThat(codes).containsExactlyInAnyOrder("EUR", "USD");
        }

        @Test
        @DisplayName("BranchSummary-k branchCode, branchName, buyHuf, sellHuf, transactionCount helyesek")
        void testBranchSummariesCorrect() {
            Branch b1 = buildBranch(BRANCH_ID_1, "SZK01", "Szekszárd Főiroda", "10");
            Branch b2 = buildBranch(BRANCH_ID_2, "SZK02", "Szekszárd Fiók", "10");

            when(branchRepository.findByCompanyIdAndIsActiveTrue(COMPANY_ID))
                    .thenReturn(List.of(b1, b2));

            var eur = buildCurrency("EUR");
            Transaction b1tx = createTxWithBranch(TransactionType.BUY, eur,
                    new BigDecimal("1000"), new BigDecimal("395000"), new BigDecimal("395"), b1);
            Transaction b2tx = createTxWithBranch(TransactionType.SELL, eur,
                    new BigDecimal("200"), new BigDecimal("82000"), new BigDecimal("410"), b2);

            when(transactionRepository.findActiveByCompanyAndDate(eq(COMPANY_ID), eq(TEST_DATE)))
                    .thenReturn(List.of(b1tx, b2tx));
            when(transactionRepository.findActiveByBranchIdsAndDate(anyList(), eq(TEST_DATE)))
                    .thenReturn(List.of(b1tx, b2tx));
            when(ownCompanyService.listActive()).thenReturn(List.of());

            MnbHierarchicalReportDto result = mnbReportService.generateHierarchicalReport(TEST_DATE);
            MnbRegionReportDto region = result.getRegionReports().get(0);

            assertThat(region.getBranchSummaries()).hasSize(2);

            // Branch 1 summary
            MnbRegionReportDto.BranchSummary s1 = region.getBranchSummaries().stream()
                    .filter(s -> "SZK01".equals(s.getBranchCode())).findFirst().orElseThrow();
            assertThat(s1.getBranchName()).isEqualTo("Szekszárd Főiroda");
            assertThat(s1.getBuyHuf()).isEqualByComparingTo("395000");
            assertThat(s1.getSellHuf()).isEqualByComparingTo("0");
            assertThat(s1.getTransactionCount()).isEqualTo(1);

            // Branch 2 summary
            MnbRegionReportDto.BranchSummary s2 = region.getBranchSummaries().stream()
                    .filter(s -> "SZK02".equals(s.getBranchCode())).findFirst().orElseThrow();
            assertThat(s2.getBranchName()).isEqualTo("Szekszárd Fiók");
            assertThat(s2.getBuyHuf()).isEqualByComparingTo("0");
            assertThat(s2.getSellHuf()).isEqualByComparingTo("82000");
            assertThat(s2.getTransactionCount()).isEqualTo(1);
        }
    }

    // ══════════════════════════════════════════════════════════════
    //  EDGE CASE-EK
    // ══════════════════════════════════════════════════════════════

    @Nested
    @DisplayName("Edge case-ek")
    class EdgeCasesTest {

        @Test
        @DisplayName("Üres tranzakció lista — nullák, üres listák, 0 totalTransactions")
        void testEmptyTransactions() {
            Branch b1 = buildBranch(BRANCH_ID_1, "B01", "Iroda1", "10");
            when(branchRepository.findByCompanyIdAndIsActiveTrue(COMPANY_ID))
                    .thenReturn(List.of(b1));
            when(transactionRepository.findActiveByCompanyAndDate(eq(COMPANY_ID), eq(TEST_DATE)))
                    .thenReturn(List.of());
            when(transactionRepository.findActiveByBranchIdsAndDate(anyList(), eq(TEST_DATE)))
                    .thenReturn(List.of());
            when(ownCompanyService.listActive()).thenReturn(List.of());

            MnbHierarchicalReportDto result = mnbReportService.generateHierarchicalReport(TEST_DATE);

            assertThat(result.getTotalTransactions()).isEqualTo(0);
            assertThat(result.getTotalBuyHuf()).isEqualByComparingTo("0");
            assertThat(result.getTotalSellHuf()).isEqualByComparingTo("0");
            assertThat(result.getCompanyCurrencyLines()).isEmpty();

            MnbRegionReportDto region = result.getRegionReports().get(0);
            assertThat(region.getTotalTransactions()).isEqualTo(0);
            assertThat(region.getTotalBuyHuf()).isEqualByComparingTo("0");
            assertThat(region.getCurrencyLines()).isEmpty();
            assertThat(region.getBranchSummaries()).hasSize(1);
            assertThat(region.getBranchSummaries().get(0).getTransactionCount()).isEqualTo(0);
        }

        @Test
        @DisplayName("Nincs aktív iroda — üres regionReports, null unassigned")
        void testNoActiveBranches() {
            when(branchRepository.findByCompanyIdAndIsActiveTrue(COMPANY_ID))
                    .thenReturn(List.of());
            when(transactionRepository.findActiveByCompanyAndDate(eq(COMPANY_ID), eq(TEST_DATE)))
                    .thenReturn(List.of());
            when(ownCompanyService.listActive()).thenReturn(List.of());

            MnbHierarchicalReportDto result = mnbReportService.generateHierarchicalReport(TEST_DATE);

            assertThat(result.getRegionReports()).isEmpty();
            assertThat(result.getUnassignedBranches()).isNull();
            assertThat(result.getTotalTransactions()).isEqualTo(0);
        }

        @Test
        @DisplayName("Minden iroda unassigned (regionCode=null) — regionReports üres, unassigned tartalmaz mindent")
        void testAllBranchesUnassigned() {
            Branch b1 = buildBranch(BRANCH_ID_1, "B01", "Iroda1", null);
            Branch b2 = buildBranch(BRANCH_ID_2, "B02", "Iroda2", null);

            when(branchRepository.findByCompanyIdAndIsActiveTrue(COMPANY_ID))
                    .thenReturn(List.of(b1, b2));

            var eur = buildCurrency("EUR");
            Transaction tx = createTxWithBranch(TransactionType.BUY, eur,
                    new BigDecimal("500"), new BigDecimal("197500"), new BigDecimal("395"), b1);

            when(transactionRepository.findActiveByCompanyAndDate(eq(COMPANY_ID), eq(TEST_DATE)))
                    .thenReturn(List.of(tx));
            when(transactionRepository.findActiveByBranchIdsAndDate(anyList(), eq(TEST_DATE)))
                    .thenReturn(List.of(tx));
            when(ownCompanyService.listActive()).thenReturn(List.of());

            MnbHierarchicalReportDto result = mnbReportService.generateHierarchicalReport(TEST_DATE);

            assertThat(result.getRegionReports()).isEmpty();
            assertThat(result.getUnassignedBranches()).isNotNull();
            assertThat(result.getUnassignedBranches().getRegionCode()).isNull();
            assertThat(result.getUnassignedBranches().getRegionName())
                    .isEqualTo("Koerzethez nem rendelt irodak");
            assertThat(result.getUnassignedBranches().getBranchCount()).isEqualTo(2);
            assertThat(result.getUnassignedBranches().getBranchSummaries()).hasSize(2);
        }

        @Test
        @DisplayName("Egyetlen branch egy körzetben — branchCount=1, branchSummaries 1 elem")
        void testSingleBranchInRegion() {
            Branch b1 = buildBranch(BRANCH_ID_1, "PCS01", "Pécs Főiroda", "120");

            when(branchRepository.findByCompanyIdAndIsActiveTrue(COMPANY_ID))
                    .thenReturn(List.of(b1));

            var eur = buildCurrency("EUR");
            Transaction tx = createTxWithBranch(TransactionType.BUY, eur,
                    new BigDecimal("750"), new BigDecimal("296250"), new BigDecimal("395"), b1);

            when(transactionRepository.findActiveByCompanyAndDate(eq(COMPANY_ID), eq(TEST_DATE)))
                    .thenReturn(List.of(tx));
            when(transactionRepository.findActiveByBranchIdsAndDate(anyList(), eq(TEST_DATE)))
                    .thenReturn(List.of(tx));
            when(ownCompanyService.listActive()).thenReturn(List.of());

            MnbHierarchicalReportDto result = mnbReportService.generateHierarchicalReport(TEST_DATE);

            assertThat(result.getRegionReports()).hasSize(1);
            MnbRegionReportDto region = result.getRegionReports().get(0);
            assertThat(region.getRegionCode()).isEqualTo("120");
            assertThat(region.getRegionName()).isEqualTo("P\u00e9cs");
            assertThat(region.getBranchCount()).isEqualTo(1);
            assertThat(region.getBranchSummaries()).hasSize(1);
            assertThat(region.getBranchSummaries().get(0).getBranchCode()).isEqualTo("PCS01");
            assertThat(region.getTotalBuyHuf()).isEqualByComparingTo("296250");
            assertThat(region.getTotalTransactions()).isEqualTo(1);
        }

        @Test
        @DisplayName("HUF tranzakciók nem kerülnek az MNB riportba (szűrve)")
        void testHufTransactionsFiltered() {
            Branch b1 = buildBranch(BRANCH_ID_1, "B01", "Iroda1", "10");
            when(branchRepository.findByCompanyIdAndIsActiveTrue(COMPANY_ID))
                    .thenReturn(List.of(b1));

            var huf = buildCurrency("HUF");
            var eur = buildCurrency("EUR");
            Transaction hufTx = createTxWithBranch(TransactionType.BUY, huf,
                    new BigDecimal("10000"), new BigDecimal("10000"), new BigDecimal("1"), b1);
            Transaction eurTx = createTxWithBranch(TransactionType.BUY, eur,
                    new BigDecimal("100"), new BigDecimal("39500"), new BigDecimal("395"), b1);

            when(transactionRepository.findActiveByCompanyAndDate(eq(COMPANY_ID), eq(TEST_DATE)))
                    .thenReturn(List.of(hufTx, eurTx));
            when(transactionRepository.findActiveByBranchIdsAndDate(anyList(), eq(TEST_DATE)))
                    .thenReturn(List.of(hufTx, eurTx));
            when(ownCompanyService.listActive()).thenReturn(List.of());

            MnbHierarchicalReportDto result = mnbReportService.generateHierarchicalReport(TEST_DATE);

            // Cég szintű lines: csak EUR
            assertThat(result.getCompanyCurrencyLines()).hasSize(1);
            assertThat(result.getCompanyCurrencyLines().get(0).getCurrencyCode()).isEqualTo("EUR");

            // Régió szintű lines: csak EUR
            MnbRegionReportDto region = result.getRegionReports().get(0);
            assertThat(region.getCurrencyLines()).hasSize(1);
            assertThat(region.getCurrencyLines().get(0).getCurrencyCode()).isEqualTo("EUR");
        }

        @Test
        @DisplayName("Vegyes körzetek: van hozzárendelt és unassigned iroda is")
        void testMixedAssignedAndUnassignedBranches() {
            Branch assigned = buildBranch(BRANCH_ID_1, "A01", "Rendelt Iroda", "10");
            Branch unassigned = buildBranch(BRANCH_ID_2, "U01", "Rendel tlen Iroda", null);

            when(branchRepository.findByCompanyIdAndIsActiveTrue(COMPANY_ID))
                    .thenReturn(List.of(assigned, unassigned));
            when(transactionRepository.findActiveByCompanyAndDate(eq(COMPANY_ID), eq(TEST_DATE)))
                    .thenReturn(List.of());
            when(transactionRepository.findActiveByBranchIdsAndDate(anyList(), eq(TEST_DATE)))
                    .thenReturn(List.of());
            when(ownCompanyService.listActive()).thenReturn(List.of());

            MnbHierarchicalReportDto result = mnbReportService.generateHierarchicalReport(TEST_DATE);

            assertThat(result.getRegionReports()).hasSize(1);
            assertThat(result.getRegionReports().get(0).getRegionCode()).isEqualTo("10");
            assertThat(result.getUnassignedBranches()).isNotNull();
            assertThat(result.getUnassignedBranches().getBranchCount()).isEqualTo(1);
        }
    }

    // ══════════════════════════════════════════════════════════════
    //  HELPER METÓDUSOK
    // ══════════════════════════════════════════════════════════════

    private Branch buildBranch(UUID id, String code, String name, String regionCode) {
        Company company = Company.builder()
                .id(COMPANY_ID)
                .code("EBC")
                .name("Best Change Kft.")
                .build();
        Branch branch = Branch.builder()
                .id(id)
                .code(code)
                .name(name)
                .company(company)
                .build();
        branch.setRegionCode(regionCode);
        branch.setIsActive(true);
        return branch;
    }

    private hu.puzzleir.valuta.entity.Currency buildCurrency(String code) {
        return hu.puzzleir.valuta.entity.Currency.builder().code(code).build();
    }

    private Transaction createTxWithBranch(TransactionType type, hu.puzzleir.valuta.entity.Currency currency,
                                  BigDecimal currencyAmount, BigDecimal hufAmount, BigDecimal rate, Branch branch) {
        Transaction tx = createTx(type, currency, currencyAmount, hufAmount, rate);
        tx.setBranch(branch);
        return tx;
    }

    private Transaction createTx(TransactionType type, hu.puzzleir.valuta.entity.Currency currency,
                                  BigDecimal currencyAmount, BigDecimal hufAmount, BigDecimal rate) {
        return Transaction.builder()
                .transactionType(type)
                .currency(currency)
                .currencyAmount(currencyAmount)
                .hufAmount(hufAmount)
                .exchangeRate(rate)
                .transactionDate(TEST_DATE)
                .transactionTime(LocalTime.of(10, 0))
                .build();
    }

    private List<OwnCompany> buildOwnCompanyList(String name) {
        OwnCompany company = OwnCompany.builder()
                .name(name)
                .taxNumber("12345678-2-41")
                .build();
        return List.of(company);
    }
}
