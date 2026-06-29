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
import java.time.LocalDateTime;
import java.util.*;

import static org.assertj.core.api.Assertions.assertThat;
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
    private CashBalanceRepository cashBalanceRepository;
    @Mock
    private CurrencyStockRepository currencyStockRepository;
    @Mock
    private ExchangeRateRepository exchangeRateRepository;
    @Mock
    private WuBalanceRepository wuBalanceRepository;
    @Mock
    private ReservationRepository reservationRepository;
    @Mock
    private TransactionRepository transactionRepository;
    @Mock
    private TransactionLineRepository transactionLineRepository;
    @Mock
    private CompanyRepository companyRepository;
    @Mock
    private CurrencyRepository currencyRepository;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID FOREIGN_COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_1_ID = UUID.randomUUID();
    private static final UUID BRANCH_2_ID = UUID.randomUUID();
    private static final UUID FOREIGN_BRANCH_ID = UUID.randomUUID();

    private Map<String, BigDecimal> midRates;

    @BeforeEach
    void setUp() {
        WorkerAuthenticationDetails details = new WorkerAuthenticationDetails(
                1L, COMPANY_ID, BRANCH_1_ID, "ADMIN");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("admin", "password", "ROLE_ADMIN");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);

        midRates = new HashMap<>();

        when(transactionRepository.sumDailySingleLineTurnoverByCurrency(any(), any(), any(), anyString()))
                .thenReturn(BigDecimal.ZERO);
        when(transactionRepository.sumDailySingleLineTurnoverHufByCurrency(any(), any(), any(), anyString()))
                .thenReturn(BigDecimal.ZERO);
        when(transactionLineRepository.sumDailyLineTurnoverByCurrency(any(), any(), any(), anyString()))
                .thenReturn(BigDecimal.ZERO);
        when(transactionLineRepository.sumDailyLineTurnoverHufByCurrency(any(), any(), any(), anyString()))
                .thenReturn(BigDecimal.ZERO);
        when(reservationRepository.getReservedStockByBranch(any())).thenReturn(List.of());
        when(wuBalanceRepository.findByBranchIdsAndCompanyId(anyList(), any())).thenReturn(List.of());
        when(cashBalanceRepository.findByCompanyId(any())).thenReturn(List.of());
        when(exchangeRateRepository.findLatestMidRateByCurrencyCode(any(), anyString()))
                .thenAnswer(invocation -> Optional.ofNullable(midRates.get(invocation.getArgument(1, String.class))));

        Company mockCompany = createCompany(COMPANY_ID, "TEST", "Test Company");
        when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(mockCompany));
        when(currencyRepository.findAllActiveOrdered()).thenReturn(List.of(
                Currency.builder().code("HUF").name("Magyar forint").displayOrder(0).active(true).build(),
                Currency.builder().code("AUD").name("Ausztrál dollár").displayOrder(1).active(true).build(),
                Currency.builder().code("EUR").name("Euró").displayOrder(8).active(true).build(),
                Currency.builder().code("USD").name("Amerikai dollár").displayOrder(21).active(true).build()
        ));
    }

    private Company createCompany(UUID id, String code, String name) {
        return Company.builder().id(id).code(code).name(name).build();
    }

    private Branch createBranch(UUID id, String code, String name, String regionCode) {
        Company company = createCompany(COMPANY_ID, "TEST", "Test Company");
        return Branch.builder()
                .id(id)
                .code(code)
                .name(name)
                .regionCode(regionCode)
                .region(StockSnapshotService.REGION_NAMES.get(regionCode))
                .company(company)
                .isActive(true)
                .build();
    }

    private CashBalance createCashBalance(Branch branch, String currencyCode, String amount) {
        return createCashBalance(branch, currencyCode, amount, LocalDateTime.now());
    }

    private CashBalance createCashBalance(Branch branch, String currencyCode, String amount, LocalDateTime updatedAt) {
        return CashBalance.builder()
                .branch(branch)
                .company(branch.getCompany())
                .currency(Currency.builder().code(currencyCode).build())
                .currentBalance(new BigDecimal(amount))
                .updatedAt(updatedAt)
                .build();
    }

    private void setCompanyBalances(CashBalance... balances) {
        when(cashBalanceRepository.findByCompanyId(COMPANY_ID)).thenReturn(Arrays.asList(balances));
    }

    private void setMidRate(String currencyCode, String rate) {
        midRates.put(currencyCode, new BigDecimal(rate));
    }

    private CurrencyStockDetailDto findCurrency(List<CurrencyStockDetailDto> currencies, String code) {
        return currencies.stream()
                .filter(currency -> code.equals(currency.getCurrencyCode()))
                .findFirst()
                .orElseThrow();
    }

    @Test
    @DisplayName("FK-006: snapshot valutalistája = aktív törzs (HUF végén) + nem-nulla leftover inaktívak")
    void getFullSnapshot_currencyCodes_activeOrderedPlusLeftoverInactive() {
        Branch branch = createBranch(BRANCH_1_ID, "B01", "Iroda 1", "10");
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID)).thenReturn(List.of(branch));
        setCompanyBalances(
                createCashBalance(branch, "DKK", "250"),
                createCashBalance(branch, "EUR", "100")
        );

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        List<String> companyCodes = result.getCompanyTotals().getCurrencies().stream()
                .map(CurrencyStockDetailDto::getCurrencyCode)
                .toList();
        assertThat(companyCodes).containsExactly("AUD", "EUR", "USD", "DKK", "HUF");

        BranchSnapshotDto branchDto = result.getRegions().get(0).getBranches().get(0);
        List<String> branchCodes = branchDto.getCurrencies().stream()
                .map(CurrencyStockDetailDto::getCurrencyCode)
                .toList();
        assertThat(branchCodes).containsExactly("AUD", "EUR", "USD", "DKK", "HUF");
    }

    @Test
    @DisplayName("FK-006: cash_balance-ból érkező inaktív valuta konzisztensen bekerül branch/region/company DTO-ba")
    void getFullSnapshot_cashBalanceInactiveCurrency_isIncludedAcrossDtos() {
        Branch branch = createBranch(BRANCH_1_ID, "B01", "Iroda 1", "10");
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID)).thenReturn(List.of(branch));
        setMidRate("NOK", "35");
        setCompanyBalances(createCashBalance(branch, "NOK", "75"));

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        List<String> companyCodes = result.getCompanyTotals().getCurrencies().stream()
                .map(CurrencyStockDetailDto::getCurrencyCode)
                .toList();
        assertThat(companyCodes).containsExactly("AUD", "EUR", "USD", "NOK", "HUF");

        BranchSnapshotDto branchDto = result.getRegions().get(0).getBranches().get(0);
        assertThat(branchDto.getCurrencies()).hasSameSizeAs(result.getCompanyTotals().getCurrencies());
        assertThat(result.getRegions().get(0).getTotals().getCurrencies())
                .hasSameSizeAs(result.getCompanyTotals().getCurrencies());

        CurrencyStockDetailDto nokTotal = findCurrency(result.getCompanyTotals().getCurrencies(), "NOK");
        assertThat(nokTotal.getStock()).isEqualTo(75);
        assertThat(nokTotal.getStockHuf()).isEqualTo(2625);
    }

    @Test
    @DisplayName("FK-006 P1: ha a HUF nincs az aktív törzsben, akkor is MINDIG az utolsó sorba kerül")
    void getFullSnapshot_hufForcedLast_evenIfNotActive() {
        when(currencyRepository.findAllActiveOrdered()).thenReturn(List.of(
                Currency.builder().code("EUR").name("Euró").displayOrder(8).active(true).build(),
                Currency.builder().code("USD").name("Amerikai dollár").displayOrder(21).active(true).build()
        ));
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID)).thenReturn(List.of());

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        List<String> codes = result.getCompanyTotals().getCurrencies().stream()
                .map(CurrencyStockDetailDto::getCurrencyCode)
                .toList();
        assertThat(codes).containsExactly("EUR", "USD", "HUF");
    }

    @Test
    @DisplayName("FK-006: az inaktív, NULLA-készletű valuta NEM jelenik meg a snapshotban")
    void getFullSnapshot_inactiveZeroStock_isExcluded() {
        Branch branch = createBranch(BRANCH_1_ID, "B01", "Iroda 1", "10");
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID)).thenReturn(List.of(branch));
        setCompanyBalances(createCashBalance(branch, "DKK", "0"));

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        List<String> codes = result.getCompanyTotals().getCurrencies().stream()
                .map(CurrencyStockDetailDto::getCurrencyCode)
                .toList();
        assertThat(codes).containsExactly("AUD", "EUR", "USD", "HUF");
        assertThat(codes).doesNotContain("DKK");
    }

    @Test
    @DisplayName("snapshot_returns_cash_balance_not_currency_stock")
    void snapshot_returns_cash_balance_not_currency_stock() {
        Branch branch = createBranch(BRANCH_1_ID, "B01", "Iroda 1", "10");
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID)).thenReturn(List.of(branch));
        setMidRate("EUR", "395.50");
        setCompanyBalances(createCashBalance(branch, "EUR", "500"));

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        assertThat(result.getRegions()).hasSize(1);
        CurrencyStockDetailDto eurDetail = findCurrency(result.getRegions().get(0).getBranches().get(0).getCurrencies(), "EUR");
        assertThat(eurDetail.getStock()).isEqualTo(500);
        assertThat(eurDetail.getStockHuf()).isEqualTo(197750);
        verifyNoInteractions(currencyStockRepository);
    }

    @Test
    @DisplayName("snapshot_missing_rate_returns_zero_huf_no_exception")
    void snapshot_missing_rate_returns_zero_huf_no_exception() {
        Branch branch = createBranch(BRANCH_1_ID, "B01", "Iroda 1", "10");
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID)).thenReturn(List.of(branch));
        setCompanyBalances(createCashBalance(branch, "EUR", "500"));

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        CurrencyStockDetailDto eurDetail = findCurrency(result.getRegions().get(0).getBranches().get(0).getCurrencies(), "EUR");
        assertThat(eurDetail.getStock()).isEqualTo(500);
        assertThat(eurDetail.getStockHuf()).isZero();
    }

    @Test
    @DisplayName("snapshot_huf_only_one_to_one_no_rate_lookup")
    void snapshot_huf_only_one_to_one_no_rate_lookup() {
        Branch branch = createBranch(BRANCH_1_ID, "B01", "Iroda 1", "10");
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID)).thenReturn(List.of(branch));
        setCompanyBalances(createCashBalance(branch, "HUF", "1376165"));

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        List<CurrencyStockDetailDto> currencies = result.getRegions().get(0).getBranches().get(0).getCurrencies();
        assertThat(findCurrency(currencies, "AUD").getStock()).isZero();
        assertThat(findCurrency(currencies, "AUD").getStockHuf()).isZero();
        assertThat(findCurrency(currencies, "EUR").getStock()).isZero();
        assertThat(findCurrency(currencies, "EUR").getStockHuf()).isZero();
        assertThat(findCurrency(currencies, "USD").getStock()).isZero();
        assertThat(findCurrency(currencies, "USD").getStockHuf()).isZero();

        CurrencyStockDetailDto hufDetail = findCurrency(currencies, "HUF");
        assertThat(hufDetail.getStock()).isEqualTo(1_376_165);
        assertThat(hufDetail.getStockHuf()).isEqualTo(1_376_165);

        verify(exchangeRateRepository, never()).findLatestMidRateByCurrencyCode(any(), eq("HUF"));
    }

    @Test
    @DisplayName("snapshot_vault_branch_returns_cash_balance")
    void snapshot_vault_branch_returns_cash_balance() {
        Company company = createCompany(COMPANY_ID, "TEST", "Test Company");
        Branch vault = Branch.builder()
                .id(BRANCH_1_ID)
                .code("BR020")
                .name("Szeged Értéktár")
                .regionCode("20")
                .region("SZEGED")
                .company(company)
                .isVault(true)
                .isActive(true)
                .build();
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID)).thenReturn(List.of(vault));
        setMidRate("USD", "370");
        setCompanyBalances(createCashBalance(vault, "USD", "1000"));

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        assertThat(result.getRegions()).hasSize(1);
        BranchSnapshotDto branchDto = result.getRegions().get(0).getBranches().get(0);
        assertThat(branchDto.getBranchName()).isEqualTo("Szeged Értéktár");
        CurrencyStockDetailDto usdDetail = findCurrency(branchDto.getCurrencies(), "USD");
        assertThat(usdDetail.getStock()).isEqualTo(1000);
        assertThat(usdDetail.getStockHuf()).isEqualTo(370000);
    }

    @Test
    @DisplayName("snapshot_vault_and_cashier_same_region_both_visible")
    void snapshot_vault_and_cashier_same_region_both_visible() {
        Company company = createCompany(COMPANY_ID, "TEST", "Test Company");
        Branch vault = Branch.builder()
                .id(BRANCH_1_ID)
                .code("BR020")
                .name("Szeged Értéktár")
                .regionCode("20")
                .region("SZEGED")
                .company(company)
                .isVault(true)
                .isActive(true)
                .build();
        Branch cashier = Branch.builder()
                .id(BRANCH_2_ID)
                .code("BR021")
                .name("Szeged Belváros")
                .regionCode("20")
                .region("SZEGED")
                .company(company)
                .isVault(false)
                .isActive(true)
                .build();
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID))
                .thenReturn(List.of(cashier, vault));
        setMidRate("USD", "370");
        setCompanyBalances(
                createCashBalance(vault, "USD", "1000"),
                createCashBalance(cashier, "USD", "500")
        );

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        RegionSnapshotDto szeged = result.getRegions().stream()
                .filter(region -> "20".equals(region.getRegionCode()))
                .findFirst()
                .orElseThrow();
        assertThat(szeged.getBranches()).hasSize(2);
        BranchSnapshotDto vaultDto = szeged.getBranches().stream()
                .filter(branch -> "Szeged Értéktár".equals(branch.getBranchName()))
                .findFirst()
                .orElseThrow();
        BranchSnapshotDto cashierDto = szeged.getBranches().stream()
                .filter(branch -> "Szeged Belváros".equals(branch.getBranchName()))
                .findFirst()
                .orElseThrow();
        assertThat(findCurrency(vaultDto.getCurrencies(), "USD").getStock()).isEqualTo(1000);
        assertThat(findCurrency(cashierDto.getCurrencies(), "USD").getStock()).isEqualTo(500);
    }

    @Test
    @DisplayName("Audit P3 (2026-05-31): stockHuf HALF_UP + 5 Ft kerekítés, NEM longValue() csonkolás")
    void getFullSnapshot_stockHuf_roundsToFive_notTruncated() {
        Branch branch = createBranch(BRANCH_1_ID, "B01", "Iroda 1", "10");
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID)).thenReturn(List.of(branch));
        setMidRate("EUR", "398.534");
        setCompanyBalances(createCashBalance(branch, "EUR", "100"));

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        CurrencyStockDetailDto eur = findCurrency(result.getRegions().get(0).getBranches().get(0).getCurrencies(), "EUR");
        assertThat(eur.getStockHuf()).as("5 Ft-ra kerekített, nem csonkolt").isEqualTo(39855L);
    }

    @Test
    @DisplayName("getFullSnapshot - 2 branch ugyanabban a körzettben - régió összesítés helyes")
    void getFullSnapshot_multipleBranchesInSameRegion_aggregatesTotals() {
        Branch branch1 = createBranch(BRANCH_1_ID, "B01", "Iroda 1", "10");
        Branch branch2 = createBranch(BRANCH_2_ID, "B02", "Iroda 2", "10");
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID)).thenReturn(List.of(branch1, branch2));
        setMidRate("EUR", "395");
        setCompanyBalances(
                createCashBalance(branch1, "EUR", "300"),
                createCashBalance(branch2, "EUR", "200")
        );

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        RegionSnapshotDto region = result.getRegions().get(0);
        assertThat(region.getBranches()).hasSize(2);
        CurrencyStockDetailDto eurTotal = findCurrency(region.getTotals().getCurrencies(), "EUR");
        assertThat(eurTotal.getStock()).isEqualTo(500);
        assertThat(eurTotal.getStockHuf()).isEqualTo(197500);
    }

    @Test
    @DisplayName("company_total_includes_all_branches")
    void company_total_includes_all_branches() {
        Company company = createCompany(COMPANY_ID, "TEST", "Test Company");
        Branch cashier = Branch.builder()
                .id(BRANCH_1_ID)
                .code("B01")
                .name("Iroda 1")
                .regionCode("10")
                .region("SZEKSZARD")
                .company(company)
                .isActive(true)
                .isVault(false)
                .build();
        Branch vault = Branch.builder()
                .id(BRANCH_2_ID)
                .code("B02")
                .name("Iroda 2")
                .regionCode("20")
                .region("SZEGED")
                .company(company)
                .isActive(true)
                .isVault(true)
                .build();
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID)).thenReturn(List.of(cashier, vault));
        setMidRate("USD", "365");
        setCompanyBalances(
                createCashBalance(cashier, "USD", "1000"),
                createCashBalance(vault, "USD", "500")
        );

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        CurrencyStockDetailDto usdCompanyTotal = findCurrency(result.getCompanyTotals().getCurrencies(), "USD");
        assertThat(usdCompanyTotal.getStock()).isEqualTo(1500);
        assertThat(usdCompanyTotal.getStockHuf()).isEqualTo(547500);
    }

    @Test
    @DisplayName("FK-019: regionCode=NULL pénztár a region (text) alapján a területi fülre kerül, az értéktár UTÁN")
    void getFullSnapshot_penztarWithNullRegionCode_groupedByRegionText_vaultFirst() {
        Company company = createCompany(COMPANY_ID, "TEST", "Test Company");
        Branch vault = Branch.builder().id(BRANCH_1_ID).code("BR020").name("Szeged Értéktár")
                .regionCode("20").region("SZEGED").isVault(true).company(company).isActive(true).build();
        Branch penztar = Branch.builder().id(BRANCH_2_ID).code("BR040").name("Szeged Móra")
                .regionCode(null).region("SZEGED").isVault(false).company(company).isActive(true).build();
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID))
                .thenReturn(List.of(penztar, vault));

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        RegionSnapshotDto szeged = result.getRegions().stream()
                .filter(region -> "SZEGED".equals(region.getRegionName()))
                .findFirst()
                .orElseThrow();
        assertThat(szeged.getBranches()).hasSize(2);
        assertThat(szeged.getBranches().get(0).getBranchName()).isEqualTo("Szeged Értéktár");
        assertThat(szeged.getBranches().get(1).getBranchName()).isEqualTo("Szeged Móra");
    }

    @Test
    @DisplayName("FK-019: besorolatlan iroda (region=NULL, regionCode=NULL) nem jelenik meg területi fülön")
    void getFullSnapshot_unassignedBranch_notInAnyRegionTab() {
        Company company = createCompany(COMPANY_ID, "TEST", "Test Company");
        Branch assigned = Branch.builder().id(BRANCH_1_ID).code("BR020").name("Szeged Értéktár")
                .regionCode("20").region("SZEGED").isVault(true).company(company).isActive(true).build();
        Branch unassigned = Branch.builder().id(BRANCH_2_ID).code("BR999").name("Besorolatlan iroda")
                .regionCode(null).region(null).isVault(false).company(company).isActive(true).build();
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID))
                .thenReturn(List.of(assigned, unassigned));

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        boolean unassignedInAnyTab = result.getRegions().stream()
                .flatMap(region -> region.getBranches().stream())
                .anyMatch(branch -> "Besorolatlan iroda".equals(branch.getBranchName()));
        assertThat(unassignedInAnyTab).isFalse();
        assertThat(result.getRegions()).anyMatch(region -> "SZEGED".equals(region.getRegionName()));
    }

    @Test
    @DisplayName("getFullSnapshot - WU egyenleg megjelenik")
    void getFullSnapshot_withWuBalance_includesWuData() {
        Branch branch = createBranch(BRANCH_1_ID, "B01", "Iroda 1", "10");
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID)).thenReturn(List.of(branch));

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
        assertThat(result.getCompanyTotals().getWuBalance().getWuUsd()).isEqualTo(2500);
        assertThat(result.getCompanyTotals().getWuBalance().getWuHuf()).isEqualTo(150000);
    }

    @Test
    @DisplayName("getFullSnapshot - foglalasok megjelennek")
    void getFullSnapshot_withReservations_includesReservationData() {
        Branch branch = createBranch(BRANCH_1_ID, "B01", "Iroda 1", "10");
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID)).thenReturn(List.of(branch));
        when(reservationRepository.getReservedStockByBranch(BRANCH_1_ID)).thenReturn(List.of(
                new Object[]{"EUR", new BigDecimal("100")},
                new Object[]{"USD", new BigDecimal("250")}
        ));

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        BranchSnapshotDto branchDto = result.getRegions().get(0).getBranches().get(0);
        assertThat(branchDto.getReservations()).hasSize(2);
        assertThat(branchDto.getReservations()).extracting(ReservationSummaryDto::getCurrencyCode)
                .containsExactly("EUR", "USD");
        assertThat(result.getCompanyTotals().getReservations()).hasSize(2);
    }

    @Test
    @DisplayName("snapshot_empty_returns_zeros")
    void snapshot_empty_returns_zeros() {
        Branch branch = createBranch(BRANCH_1_ID, "B01", "Iroda 1", "10");
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID)).thenReturn(List.of(branch));

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        BranchSnapshotDto branchDto = result.getRegions().get(0).getBranches().get(0);
        assertThat(branchDto.getCurrencies()).allSatisfy(currency -> {
            assertThat(currency.getStock()).isZero();
            assertThat(currency.getStockHuf()).isZero();
        });
        assertThat(result.getCompanyTotals().getCurrencies()).allSatisfy(currency -> {
            assertThat(currency.getStock()).isZero();
            assertThat(currency.getStockHuf()).isZero();
        });
    }

    @Test
    @DisplayName("getFullSnapshot - ures branch lista - ures, de valid DTO")
    void getFullSnapshot_emptyBranches_returnsEmptySnapshot() {
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID)).thenReturn(List.of());

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        assertThat(result.getCompanyId()).isEqualTo(COMPANY_ID);
        assertThat(result.getRegions()).isEmpty();
        assertThat(result.getCompanyTotals().getCurrencies())
                .extracting(CurrencyStockDetailDto::getCurrencyCode)
                .containsExactly("AUD", "EUR", "USD", "HUF");
        assertThat(result.getCompanyTotals().getReservations()).isEmpty();
    }

    @Test
    @DisplayName("snapshot_cross_tenant_returns_no_foreign_data")
    void snapshot_cross_tenant_returns_no_foreign_data() {
        Branch localBranch = createBranch(BRANCH_1_ID, "B01", "Iroda 1", "10");
        Company foreignCompany = createCompany(FOREIGN_COMPANY_ID, "FOREIGN", "Foreign Company");
        Branch foreignBranch = Branch.builder()
                .id(FOREIGN_BRANCH_ID)
                .code("F01")
                .name("Foreign Branch")
                .regionCode("20")
                .region("SZEGED")
                .company(foreignCompany)
                .isActive(true)
                .isVault(false)
                .build();
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID)).thenReturn(List.of(localBranch));
        setMidRate("EUR", "400");
        setMidRate("USD", "370");
        when(cashBalanceRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of(
                createCashBalance(localBranch, "EUR", "100"),
                createCashBalance(foreignBranch, "USD", "999")
        ));

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        List<String> visibleBranchNames = result.getRegions().stream()
                .flatMap(region -> region.getBranches().stream())
                .map(BranchSnapshotDto::getBranchName)
                .toList();
        assertThat(visibleBranchNames).doesNotContain("Foreign Branch");
        CurrencyStockDetailDto eurTotal = findCurrency(result.getCompanyTotals().getCurrencies(), "EUR");
        CurrencyStockDetailDto usdTotal = findCurrency(result.getCompanyTotals().getCurrencies(), "USD");
        assertThat(eurTotal.getStock()).isEqualTo(100);
        assertThat(usdTotal.getStock()).isZero();
        verify(cashBalanceRepository).findByCompanyId(COMPANY_ID);
    }

    @Test
    @DisplayName("FK-005 regresszió - nem-ures, keszlettel rendelkezo branch-halmaz -> NEM ures snapshot, HUF-osszeg > 0")
    void getFullSnapshot_nonEmptyBranchesWithStock_doesNotReturnEmpty() {
        Branch branch1 = createBranch(BRANCH_1_ID, "B01", "Iroda 1", "10");
        Branch branch2 = createBranch(BRANCH_2_ID, "B02", "Iroda 2", "20");
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID)).thenReturn(List.of(branch1, branch2));
        setMidRate("EUR", "400");
        setCompanyBalances(
                createCashBalance(branch1, "HUF", "1000000"),
                createCashBalance(branch2, "EUR", "500")
        );

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        assertThat(result.getRegions()).isNotEmpty();
        int totalBranches = result.getRegions().stream().mapToInt(region -> region.getBranches().size()).sum();
        assertThat(totalBranches).isEqualTo(2);
        long companyHuf = result.getCompanyTotals().getCurrencies().stream()
                .mapToLong(CurrencyStockDetailDto::getStockHuf)
                .sum();
        assertThat(companyHuf).isGreaterThan(0L);
    }

    @Test
    @DisplayName("getFullSnapshot - ismeretlen region-code-u branch IS szerepel a companyTotals fallback-ben")
    void getFullSnapshot_branchWithUnknownRegion_includedInCompanyTotalsFallback() {
        Branch branch = createBranch(BRANCH_1_ID, "B01", "Iroda-UNKNOWN", "UNKNOWN_REGION_99");
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID)).thenReturn(List.of(branch));
        setMidRate("USD", "370");
        setCompanyBalances(createCashBalance(branch, "USD", "5000"));

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        assertThat(result.getRegions()).isEmpty();
        CurrencyStockDetailDto usdTotal = findCurrency(result.getCompanyTotals().getCurrencies(), "USD");
        assertThat(usdTotal.getStock()).isEqualTo(5000);
        assertThat(usdTotal.getStockHuf()).isEqualTo(1_850_000);
    }

    @Test
    @DisplayName("FK-003/004: NAPI FORGALOM Ft-oszlopok a hufAmount-ból (NEM fixen 0)")
    void getFullSnapshot_dailyTurnoverHuf_populatedFromHufAmount() {
        Branch branch = createBranch(BRANCH_1_ID, "B01", "Iroda 1", "10");
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID)).thenReturn(List.of(branch));
        when(transactionRepository.sumDailySingleLineTurnoverHufByCurrency(any(), any(), any(), eq("EUR")))
                .thenReturn(new BigDecimal("80000"));

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        CurrencyStockDetailDto eur = findCurrency(result.getRegions().get(0).getBranches().get(0).getCurrencies(), "EUR");
        assertThat(eur.getDailyBuyHuf()).isEqualTo(80000);
        assertThat(eur.getDailySellHuf()).isEqualTo(80000);
    }

    @Test
    @DisplayName("Codex #903: multi-line bizonylat — a forgalom valutánként helyes (single-line + line összeg)")
    void getFullSnapshot_dailyTurnover_multiLineSummedPerCurrency() {
        Branch branch = createBranch(BRANCH_1_ID, "B01", "Iroda 1", "10");
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID)).thenReturn(List.of(branch));
        when(transactionRepository.sumDailySingleLineTurnoverHufByCurrency(any(), any(), eq(TransactionType.BUY), eq("EUR")))
                .thenReturn(new BigDecimal("50000"));
        when(transactionLineRepository.sumDailyLineTurnoverHufByCurrency(any(), any(), eq(TransactionType.BUY), eq("USD")))
                .thenReturn(new BigDecimal("30000"));

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        List<CurrencyStockDetailDto> currencies = result.getRegions().get(0).getBranches().get(0).getCurrencies();
        CurrencyStockDetailDto eur = findCurrency(currencies, "EUR");
        CurrencyStockDetailDto usd = findCurrency(currencies, "USD");
        assertThat(eur.getDailyBuyHuf()).isEqualTo(50000);
        assertThat(usd.getDailyBuyHuf()).isEqualTo(30000);
    }
}
