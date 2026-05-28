package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.stocksnapshot.*;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class StockSnapshotServiceTest {

    @InjectMocks
    private StockSnapshotService service;

    @Mock
    private BranchRepository branchRepository;
    @Mock
    private CurrencyStockRepository currencyStockRepository;
    @Mock
    private WuBalanceRepository wuBalanceRepository;
    @Mock
    private ReservationRepository reservationRepository;
    @Mock
    private TransactionRepository transactionRepository;
    @Mock
    private hu.puzzleir.valuta.repository.CompanyRepository companyRepository;
    @Mock
    private CurrencyRepository currencyRepository;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_1_ID = UUID.randomUUID();
    private static final UUID BRANCH_2_ID = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        WorkerAuthenticationDetails details = new WorkerAuthenticationDetails(
                1L, COMPANY_ID, BRANCH_1_ID, "ADMIN");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("admin", "password", "ROLE_ADMIN");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);

        // Default mocks for transaction queries (return zero)
        when(transactionRepository.sumDailyTurnoverByCurrency(any(), any(), any(), anyString()))
                .thenReturn(BigDecimal.ZERO);
        // Default mocks for reservations (return empty)
        when(reservationRepository.getReservedStockByBranch(any())).thenReturn(List.of());
        Company _mockCompany = Company.builder().id(COMPANY_ID).code("TEST").name("Test Company").build();
        when(companyRepository.findById(any())).thenReturn(Optional.of(_mockCompany));
        when(currencyStockRepository.sumCompanyLevelByCurrency(any())).thenReturn(List.of());

        // FK-006: a snapshot a központi valutanem-törzset olvassa. Default active set a tesztek
        // számára: HUF (bázis), AUD, EUR, USD. A lazy mockingnál a felüldefiniáló tesztek a saját
        // állapotot adják meg.
        when(currencyRepository.findAllActiveOrdered()).thenReturn(List.of(
                Currency.builder().code("HUF").name("Magyar forint").displayOrder(0).active(true).build(),
                Currency.builder().code("AUD").name("Ausztrál dollár").displayOrder(1).active(true).build(),
                Currency.builder().code("EUR").name("Euró").displayOrder(8).active(true).build(),
                Currency.builder().code("USD").name("Amerikai dollár").displayOrder(21).active(true).build()
        ));
    }

    // ===== HELPER =====

    private Branch createBranch(UUID id, String code, String name, String regionCode) {
        Company company = Company.builder().id(COMPANY_ID).code("TEST").name("Test Company").build();
        return Branch.builder()
                .id(id).code(code).name(name)
                .regionCode(regionCode)
                .company(company)
                .isActive(true)
                .build();
    }

    // ===== TESTS =====

    @Test
    @DisplayName("FK-006: snapshot valutalistája = aktív törzs (HUF végén) + nem-nulla leftover inaktívak")
    void getFullSnapshot_currencyCodes_activeOrderedPlusLeftoverInactive() {
        // Aktív törzs: HUF=0, AUD=1, EUR=8, USD=21 → várt sorrend HUF nélkül: [AUD, EUR, USD, HUF]
        // DKK INAKTÍV, mégis van készlet (leftover) → várt végső sorrend: [AUD, EUR, USD, HUF, DKK]
        Branch branch = createBranch(BRANCH_1_ID, "B01", "Iroda 1", "10");
        when(branchRepository.findActiveWithRegionByCompanyId(COMPANY_ID)).thenReturn(List.of(branch));

        CurrencyStock dkkLeftover = CurrencyStock.builder()
                .entityType("CASHIER").entityId(BRANCH_1_ID.toString())
                .currencyCode("DKK").quantity(new BigDecimal("250"))
                .weightedAvgCost(new BigDecimal("60")).lastUpdated(LocalDateTime.now()).build();
        CurrencyStock eurActive = CurrencyStock.builder()
                .entityType("CASHIER").entityId(BRANCH_1_ID.toString())
                .currencyCode("EUR").quantity(new BigDecimal("100"))
                .weightedAvgCost(new BigDecimal("400")).lastUpdated(LocalDateTime.now()).build();
        when(currencyStockRepository.findAllByBranchIds(anyList())).thenReturn(List.of(dkkLeftover, eurActive));
        when(wuBalanceRepository.findByBranchIdsAndCompanyId(anyList(), eq(COMPANY_ID))).thenReturn(List.of());

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        List<String> codes = result.getCompanyTotals().getCurrencies().stream()
                .map(CurrencyStockDetailDto::getCurrencyCode)
                .toList();
        assertThat(codes).containsExactly("AUD", "EUR", "USD", "HUF", "DKK");

        // Branch-szinten ugyanaz a sorrend (a snapshot szolgáltatás egyetlen igazságforrásból építkezik)
        BranchSnapshotDto branchDto = result.getRegions().get(0).getBranches().get(0);
        List<String> branchCodes = branchDto.getCurrencies().stream()
                .map(CurrencyStockDetailDto::getCurrencyCode).toList();
        assertThat(branchCodes).containsExactly("AUD", "EUR", "USD", "HUF", "DKK");
    }

    @Test
    @DisplayName("FK-006 P1: company-szintű leftover (orphan-zombie kód) is bekerül a snapshotba")
    void getFullSnapshot_companyLevelLeftover_isIncluded() {
        // Branch-szinten NINCS leftover, de a sumCompanyLevelByCurrency egy NOK rekordot ad
        // (pl. törölt/inaktivált branch maradéka). Ezt is meg KELL jeleníteni a riportban,
        // és a snapshot DTO array-eknek konzisztens méretben kell épülniük (P1 IOOBE-védelem).
        Branch branch = createBranch(BRANCH_1_ID, "B01", "Iroda 1", "10");
        when(branchRepository.findActiveWithRegionByCompanyId(COMPANY_ID)).thenReturn(List.of(branch));
        when(currencyStockRepository.findAllByBranchIds(anyList())).thenReturn(List.of());
        when(wuBalanceRepository.findByBranchIdsAndCompanyId(anyList(), eq(COMPANY_ID))).thenReturn(List.of());
        List<Object[]> nokRow = new ArrayList<>();
        nokRow.add(new Object[]{"NOK", new BigDecimal("75"), new BigDecimal("2625")});
        when(currencyStockRepository.sumCompanyLevelByCurrency(any())).thenReturn(nokRow);

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        List<String> companyCodes = result.getCompanyTotals().getCurrencies().stream()
                .map(CurrencyStockDetailDto::getCurrencyCode).toList();
        assertThat(companyCodes).containsExactly("AUD", "EUR", "USD", "HUF", "NOK");

        // KÖTELEZŐ konzisztencia: a per-branch és a region totals DTO array MÉRETE megegyezik
        // a company-szintű DTO méretével (különben az Excel-export IOOBE-be csordulna).
        BranchSnapshotDto branchDto = result.getRegions().get(0).getBranches().get(0);
        assertThat(branchDto.getCurrencies()).hasSameSizeAs(result.getCompanyTotals().getCurrencies());
        assertThat(result.getRegions().get(0).getTotals().getCurrencies())
                .hasSameSizeAs(result.getCompanyTotals().getCurrencies());

        CurrencyStockDetailDto nokTotal = result.getCompanyTotals().getCurrencies().stream()
                .filter(c -> "NOK".equals(c.getCurrencyCode())).findFirst().orElseThrow();
        assertThat(nokTotal.getStock()).isEqualTo(75);
        assertThat(nokTotal.getStockHuf()).isEqualTo(2625);
    }

    @Test
    @DisplayName("FK-006 P1: ha a HUF nincs az aktív törzsben, akkor is MINDIG az utolsó sorba kerül")
    void getFullSnapshot_hufForcedLast_evenIfNotActive() {
        // Aktív törzs HUF NÉLKÜL (degenerált eset)
        when(currencyRepository.findAllActiveOrdered()).thenReturn(List.of(
                Currency.builder().code("EUR").name("Euró").displayOrder(8).active(true).build(),
                Currency.builder().code("USD").name("Amerikai dollár").displayOrder(21).active(true).build()
        ));
        when(branchRepository.findActiveWithRegionByCompanyId(COMPANY_ID)).thenReturn(List.of());

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        List<String> codes = result.getCompanyTotals().getCurrencies().stream()
                .map(CurrencyStockDetailDto::getCurrencyCode).toList();
        // HUF mindenképp a végén — ne kerüljön az alfabetikus leftover-blokkba.
        assertThat(codes).containsExactly("EUR", "USD", "HUF");
    }

    @Test
    @DisplayName("FK-006: az inaktív, NULLA-készletű valuta NEM jelenik meg a snapshotban")
    void getFullSnapshot_inactiveZeroStock_isExcluded() {
        Branch branch = createBranch(BRANCH_1_ID, "B01", "Iroda 1", "10");
        when(branchRepository.findActiveWithRegionByCompanyId(COMPANY_ID)).thenReturn(List.of(branch));

        // DKK inaktív + ZERO készlet → ne legyen a listában
        CurrencyStock dkkZero = CurrencyStock.builder()
                .entityType("CASHIER").entityId(BRANCH_1_ID.toString())
                .currencyCode("DKK").quantity(BigDecimal.ZERO)
                .weightedAvgCost(new BigDecimal("60")).lastUpdated(LocalDateTime.now()).build();
        when(currencyStockRepository.findAllByBranchIds(anyList())).thenReturn(List.of(dkkZero));
        when(wuBalanceRepository.findByBranchIdsAndCompanyId(anyList(), eq(COMPANY_ID))).thenReturn(List.of());

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        List<String> codes = result.getCompanyTotals().getCurrencies().stream()
                .map(CurrencyStockDetailDto::getCurrencyCode).toList();
        assertThat(codes).containsExactly("AUD", "EUR", "USD", "HUF");
        assertThat(codes).doesNotContain("DKK");
    }

    @Test
    @DisplayName("getFullSnapshot - 1 branch EUR készlettel - stock=500, stockHuf=500*395.50=197750")
    void getFullSnapshot_singleBranch_returnsCurrencyData() {
        Branch branch = createBranch(BRANCH_1_ID, "B01", "Iroda 1", "10");
        when(branchRepository.findActiveWithRegionByCompanyId(COMPANY_ID)).thenReturn(List.of(branch));

        CurrencyStock eurStock = CurrencyStock.builder()
                .entityType("CASHIER")
                .entityId(BRANCH_1_ID.toString())
                .currencyCode("EUR")
                .quantity(new BigDecimal("500"))
                .weightedAvgCost(new BigDecimal("395.50"))
                .lastUpdated(LocalDateTime.now())
                .build();
        when(currencyStockRepository.findAllByBranchIds(anyList())).thenReturn(List.of(eurStock));
        when(wuBalanceRepository.findByBranchIdsAndCompanyId(anyList(), eq(COMPANY_ID))).thenReturn(List.of());

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        assertThat(result).isNotNull();
        assertThat(result.getCompanyId()).isEqualTo(COMPANY_ID);
        assertThat(result.getRegions()).hasSize(1);
        assertThat(result.getRegions().get(0).getRegionCode()).isEqualTo("10");

        BranchSnapshotDto branchDto = result.getRegions().get(0).getBranches().get(0);
        CurrencyStockDetailDto eurDetail = branchDto.getCurrencies().stream()
                .filter(c -> "EUR".equals(c.getCurrencyCode())).findFirst().orElseThrow();
        assertThat(eurDetail.getStock()).isEqualTo(500);
        // 500 * 395.50 = 197750
        assertThat(eurDetail.getStockHuf()).isEqualTo(197750);
    }

    @Test
    @DisplayName("getFullSnapshot - 2 branch ugyanabban a körzettben - régió összesítés helyes")
    void getFullSnapshot_multipleBranchesInSameRegion_aggregatesTotals() {
        Branch branch1 = createBranch(BRANCH_1_ID, "B01", "Iroda 1", "10");
        Branch branch2 = createBranch(BRANCH_2_ID, "B02", "Iroda 2", "10");
        when(branchRepository.findActiveWithRegionByCompanyId(COMPANY_ID)).thenReturn(List.of(branch1, branch2));

        CurrencyStock eurStock1 = CurrencyStock.builder()
                .entityType("CASHIER").entityId(BRANCH_1_ID.toString())
                .currencyCode("EUR").quantity(new BigDecimal("300"))
                .weightedAvgCost(new BigDecimal("400")).lastUpdated(LocalDateTime.now()).build();
        CurrencyStock eurStock2 = CurrencyStock.builder()
                .entityType("CASHIER").entityId(BRANCH_2_ID.toString())
                .currencyCode("EUR").quantity(new BigDecimal("200"))
                .weightedAvgCost(new BigDecimal("390")).lastUpdated(LocalDateTime.now()).build();
        when(currencyStockRepository.findAllByBranchIds(anyList())).thenReturn(List.of(eurStock1, eurStock2));
        when(wuBalanceRepository.findByBranchIdsAndCompanyId(anyList(), eq(COMPANY_ID))).thenReturn(List.of());

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        assertThat(result.getRegions()).hasSize(1);
        RegionSnapshotDto region = result.getRegions().get(0);
        assertThat(region.getBranches()).hasSize(2);

        CurrencyStockDetailDto eurTotal = region.getTotals().getCurrencies().stream()
                .filter(c -> "EUR".equals(c.getCurrencyCode())).findFirst().orElseThrow();
        // 300 + 200 = 500
        assertThat(eurTotal.getStock()).isEqualTo(500);
        // 300*400 + 200*390 = 120000 + 78000 = 198000
        assertThat(eurTotal.getStockHuf()).isEqualTo(198000);
    }

    @Test
    @DisplayName("getFullSnapshot - 2 branch eltero korzetben - cegszintu osszesites")
    void getFullSnapshot_companyTotals_sumsAcrossRegions() {
        Branch branch1 = createBranch(BRANCH_1_ID, "B01", "Iroda 1", "10");
        Branch branch2 = createBranch(BRANCH_2_ID, "B02", "Iroda 2", "20");
        when(branchRepository.findActiveWithRegionByCompanyId(COMPANY_ID)).thenReturn(List.of(branch1, branch2));

        CurrencyStock usdStock1 = CurrencyStock.builder()
                .entityType("CASHIER").entityId(BRANCH_1_ID.toString())
                .currencyCode("USD").quantity(new BigDecimal("1000"))
                .weightedAvgCost(new BigDecimal("360")).lastUpdated(LocalDateTime.now()).build();
        CurrencyStock usdStock2 = CurrencyStock.builder()
                .entityType("CASHIER").entityId(BRANCH_2_ID.toString())
                .currencyCode("USD").quantity(new BigDecimal("500"))
                .weightedAvgCost(new BigDecimal("365")).lastUpdated(LocalDateTime.now()).build();
        when(currencyStockRepository.findAllByBranchIds(anyList())).thenReturn(List.of(usdStock1, usdStock2));
        when(wuBalanceRepository.findByBranchIdsAndCompanyId(anyList(), eq(COMPANY_ID))).thenReturn(List.of());

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        assertThat(result.getRegions()).hasSize(2);

        CurrencyStockDetailDto usdCompanyTotal = result.getCompanyTotals().getCurrencies().stream()
                .filter(c -> "USD".equals(c.getCurrencyCode())).findFirst().orElseThrow();
        // 1000 + 500 = 1500
        assertThat(usdCompanyTotal.getStock()).isEqualTo(1500);
        // 1000*360 + 500*365 = 360000 + 182500 = 542500
        assertThat(usdCompanyTotal.getStockHuf()).isEqualTo(542500);
    }

    @Test
    @DisplayName("getFullSnapshot - WU egyenleg megjelenik")
    void getFullSnapshot_withWuBalance_includesWuData() {
        Branch branch = createBranch(BRANCH_1_ID, "B01", "Iroda 1", "10");
        when(branchRepository.findActiveWithRegionByCompanyId(COMPANY_ID)).thenReturn(List.of(branch));
        when(currencyStockRepository.findAllByBranchIds(anyList())).thenReturn(List.of());

        WuBalance wuBalance = WuBalance.builder()
                .branch(branch)
                .usdBalance(new BigDecimal("2500"))
                .hufBalance(new BigDecimal("150000"))
                .build();
        when(wuBalanceRepository.findByBranchIdsAndCompanyId(anyList(), eq(COMPANY_ID))).thenReturn(List.of(wuBalance));

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        BranchSnapshotDto branchDto = result.getRegions().get(0).getBranches().get(0);
        assertThat(branchDto.getWuBalance().getWuUsd()).isEqualTo(2500);
        assertThat(branchDto.getWuBalance().getWuHuf()).isEqualTo(150000);

        // Company totals too
        assertThat(result.getCompanyTotals().getWuBalance().getWuUsd()).isEqualTo(2500);
        assertThat(result.getCompanyTotals().getWuBalance().getWuHuf()).isEqualTo(150000);
    }

    @Test
    @DisplayName("getFullSnapshot - foglalasok megjelennek")
    void getFullSnapshot_withReservations_includesReservationData() {
        Branch branch = createBranch(BRANCH_1_ID, "B01", "Iroda 1", "10");
        when(branchRepository.findActiveWithRegionByCompanyId(COMPANY_ID)).thenReturn(List.of(branch));
        when(currencyStockRepository.findAllByBranchIds(anyList())).thenReturn(List.of());
        when(wuBalanceRepository.findByBranchIdsAndCompanyId(anyList(), eq(COMPANY_ID))).thenReturn(List.of());

        // Override reservation mock for this branch
        when(reservationRepository.getReservedStockByBranch(BRANCH_1_ID)).thenReturn(List.of(
                new Object[]{"EUR", new BigDecimal("100")},
                new Object[]{"USD", new BigDecimal("250")}
        ));

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        BranchSnapshotDto branchDto = result.getRegions().get(0).getBranches().get(0);
        assertThat(branchDto.getReservations()).hasSize(2);

        ReservationSummaryDto eurRes = branchDto.getReservations().stream()
                .filter(r -> "EUR".equals(r.getCurrencyCode())).findFirst().orElseThrow();
        assertThat(eurRes.getTotalAmount()).isEqualTo(100);

        ReservationSummaryDto usdRes = branchDto.getReservations().stream()
                .filter(r -> "USD".equals(r.getCurrencyCode())).findFirst().orElseThrow();
        assertThat(usdRes.getTotalAmount()).isEqualTo(250);
    }

    @Test
    @DisplayName("getFullSnapshot - ures branch lista - ures, de valid DTO")
    void getFullSnapshot_emptyBranches_returnsEmptySnapshot() {
        when(branchRepository.findActiveWithRegionByCompanyId(COMPANY_ID)).thenReturn(List.of());

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        assertThat(result).isNotNull();
        assertThat(result.getCompanyId()).isEqualTo(COMPANY_ID);
        assertThat(result.getRegions()).isEmpty();
        assertThat(result.getCompanyTotals()).isNotNull();
        // FK-006: a snapshot a központi valutanem-törzset olvassa; üres branch-listánál nincs leftover,
        // így pontosan az aktív törzs méretét kapjuk (a setUp mock 4 elemet ad: HUF, AUD, EUR, USD).
        assertThat(result.getCompanyTotals().getCurrencies()).hasSize(4);
        assertThat(result.getCompanyTotals().getCurrencies())
                .extracting(CurrencyStockDetailDto::getCurrencyCode)
                .containsExactly("AUD", "EUR", "USD", "HUF");
        assertThat(result.getCompanyTotals().getReservations()).isEmpty();
    }

    /**
     * Codex P2 PR #157 regression test:
     * Ha egy branch-nek olyan region-code-ja van ami NINCS a REGION_NAMES hardcoded map-ben,
     * a branch-e NEM vesz el a companyTotals-bol (fallback aggregation minden branch-et kell latnia).
     */
    @Test
    @DisplayName("getFullSnapshot - ismeretlen region-code-u branch IS szerepel a companyTotals fallback-ben")
    void getFullSnapshot_branchWithUnknownRegion_includedInCompanyTotalsFallback() {
        // UNKNOWN_REGION nincs a REGION_NAMES-ben ("10","20","40","50","63","75","120","145")
        Branch branch = createBranch(BRANCH_1_ID, "B01", "Iroda-UNKNOWN", "UNKNOWN_REGION_99");
        when(branchRepository.findActiveWithRegionByCompanyId(COMPANY_ID)).thenReturn(List.of(branch));

        CurrencyStock usdStock = CurrencyStock.builder()
                .entityType("CASHIER").entityId(BRANCH_1_ID.toString())
                .currencyCode("USD").quantity(new BigDecimal("5000"))
                .weightedAvgCost(new BigDecimal("370"))
                .lastUpdated(LocalDateTime.now()).build();
        when(currencyStockRepository.findAllByBranchIds(anyList())).thenReturn(List.of(usdStock));

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        // regions ures (REGION_NAMES nem tartalmazza UNKNOWN_REGION_99-et)
        assertThat(result.getRegions()).isEmpty();

        // DE a companyTotals fallback agregalja a branch stock-jat
        CurrencyStockDetailDto usdTotal = result.getCompanyTotals().getCurrencies().stream()
                .filter(c -> "USD".equals(c.getCurrencyCode())).findFirst().orElseThrow();
        // 5000 USD * 370 HUF = 1,850,000 HUF
        assertThat(usdTotal.getStock()).as("USD stock aggregalva fallback-bol").isEqualTo(5000);
        assertThat(usdTotal.getStockHuf()).as("USD stockHuf aggregalva fallback-bol").isEqualTo(1_850_000);
    }
}