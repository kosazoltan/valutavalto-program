package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.closingwizard.ClosingWizardStatusDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import tools.jackson.databind.ObjectMapper;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

/**
 * FKH-036 FR-5/FR-6 — mozgás-alapú kötelező valuta-halmaz a vault-zárásban.
 *
 * <p>WU-0 RED: a teszt a CÉLVISELKEDÉST pineli; a {@code getRequiredCurrencies()} /
 * {@code isHandlingFeeRequired()} DTO-mezők és a service-logika nélkül a fordítása
 * elbukik — ez a várt RED állapot (a commit-üzenet rögzíti).</p>
 *
 * <p>Esetek:
 * (a) mozgás nélkül a kötelező halmaz pontosan {HUF}, handlingFeeRequired=false;
 * (b) EUR shipment-mozgás → EUR is kötelező;
 * (c) KK kezelési díj mozgás → handlingFeeRequired=true;
 * (d) CROSS-TENANT: a lekérdezés a hívó companyId-jával fut, más cég mozgása nem számít;
 * (e) nem-kötelező valuta eltérése NEM blokkol (exactMatch=true);
 * (f) kötelező valuta eltérése blokkol (exactMatch=false);
 * (g) PÉNZTÁR-ág regresszió: requiredCurrencies=null, handlingFeeRequired=false,
 *     exactMatch a cash_balance-eltérésekből számít, pontosan a régi szemantikával;
 * (h) B2 regresszió: a valuta- és a díj-mozgás lekérdezés UGYANAZT az üzleti dátumot
 *     (ShipmentRequest.requestDate) használja — nincs createdAt-időablakos díj-módszer.</p>
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class ClosingWizardMandatoryCurrenciesFkh036Test {

    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final LocalDate CLOSING_DATE = LocalDate.of(2026, 8, 17);
    private static final String VAULT_ENTITY_ID = "77";

    @InjectMocks private ClosingWizardService service;

    @Mock private ClosingWizardRepository closingWizardRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private DailySessionRepository dailySessionRepository;
    @Mock private TransactionRepository transactionRepository;
    @Mock private DailyClosingService dailyClosingService;
    @Mock private ObjectMapper objectMapper;
    @Mock private DenominationRepository denominationRepository;
    @Mock private DenominationBalanceRepository denominationBalanceRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private CurrencyStockRepository currencyStockRepository;
    @Mock private SystemParameterService systemParameterService;
    @Mock private ClosingToleranceService closingToleranceService;
    @Mock private AuditLogService auditLogService;
    @Mock private DenominationAllowedRepository denominationAllowedRepository;
    // FKH-036: az új mozgás-alapú függőségek (WU-5).
    @Mock private ShipmentRequestRepository shipmentRequestRepository;
    @Mock private ShipmentHandlingFeeRepository shipmentHandlingFeeRepository;
    @Mock private VatSupplyStockRepository vatSupplyStockRepository;

    private Branch vaultBranch;

    @BeforeEach
    void setUp() {
        vaultBranch = Branch.builder()
                .id(BRANCH_ID)
                .code("VT01")
                .isVault(true)
                .vaultTerritoryId(Integer.valueOf(VAULT_ENTITY_ID))
                .company(Company.builder().id(COMPANY_ID).build())
                .build();
    }

    /**
     * Vault-zárás stub: a megadott aktív valuták, várt currency_stock-készlettel és
     * becímletezett (fizikai) összegekkel; 0-tolerancia (FK-073 FR-3 végállapot).
     */
    private void stubVaultClosing(List<String> activeCodes,
                                  List<BigDecimal> expectedStocks,
                                  List<BigDecimal> physicalCounts) {
        when(branchRepository.findByIdAndCompanyId(BRANCH_ID, COMPANY_ID))
                .thenReturn(Optional.of(vaultBranch));
        when(denominationBalanceRepository.existsByBranchIdAndDateAndCategory(
                BRANCH_ID, CLOSING_DATE, DenominationCategory.EVENING)).thenReturn(true);

        Object[][] countRows = new Object[activeCodes.size()][];
        for (int i = 0; i < activeCodes.size(); i++) {
            countRows[i] = new Object[]{activeCodes.get(i), physicalCounts.get(i)};
        }
        when(denominationBalanceRepository.sumActualStockByCurrency(
                BRANCH_ID, CLOSING_DATE, DenominationCategory.EVENING))
                .thenReturn(java.util.Arrays.asList(countRows));

        List<Currency> currencies = activeCodes.stream().map(code -> {
            Currency c = new Currency();
            c.setCode(code);
            return c;
        }).toList();
        when(currencyRepository.findAllActiveOrdered()).thenReturn(currencies);

        for (int i = 0; i < activeCodes.size(); i++) {
            CurrencyStock stock = new CurrencyStock();
            stock.setCurrencyCode(activeCodes.get(i));
            stock.setQuantity(expectedStocks.get(i));
            when(currencyStockRepository.findByCompanyIdAndEntityTypeAndEntityIdAndCurrencyCode(
                    COMPANY_ID, "VAULT", VAULT_ENTITY_ID, activeCodes.get(i)))
                    .thenReturn(Optional.of(stock));
            when(closingToleranceService.getToleranceFor(activeCodes.get(i)))
                    .thenReturn(ClosingTolerance.explicitOf(BigDecimal.ZERO));
        }
    }

    private ClosingWizardStatusDto vaultStatus() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            return service.getClosingStatus(BRANCH_ID, CLOSING_DATE);
        }
    }

    // =====================================================================
    // (a)–(d): a kötelező halmaz összetétele
    // =====================================================================

    @Test
    @DisplayName("(a) mozgás nélkül a kötelező halmaz pontosan {HUF}, handlingFeeRequired=false")
    void noMovement_requiredIsHufOnly_noFee() {
        stubVaultClosing(List.of("HUF"), List.of(new BigDecimal("100")), List.of(new BigDecimal("100")));
        when(shipmentRequestRepository.findMovedCurrencyCodesForDate(
                eq(COMPANY_ID), eq(BRANCH_ID), eq(CLOSING_DATE), any())).thenReturn(List.of());
        when(shipmentHandlingFeeRepository.existsDailyMovementForSourceBranch(
                COMPANY_ID, BRANCH_ID, CLOSING_DATE)).thenReturn(false);

        ClosingWizardStatusDto dto = vaultStatus();

        assertThat(dto.getRequiredCurrencies()).containsExactly("HUF");
        assertThat(dto.isHandlingFeeRequired()).isFalse();
    }

    @Test
    @DisplayName("(b) EUR shipment-mozgás → EUR is kötelező (HUF + EUR)")
    void eurMovement_eurBecomesRequired() {
        stubVaultClosing(List.of("HUF", "EUR"),
                List.of(new BigDecimal("100"), new BigDecimal("50")),
                List.of(new BigDecimal("100"), new BigDecimal("50")));
        when(shipmentRequestRepository.findMovedCurrencyCodesForDate(
                eq(COMPANY_ID), eq(BRANCH_ID), eq(CLOSING_DATE), any()))
                .thenReturn(List.of("EUR"));
        when(shipmentHandlingFeeRepository.existsDailyMovementForSourceBranch(
                COMPANY_ID, BRANCH_ID, CLOSING_DATE)).thenReturn(false);

        ClosingWizardStatusDto dto = vaultStatus();

        assertThat(dto.getRequiredCurrencies()).containsExactly("HUF", "EUR");
    }

    @Test
    @DisplayName("(c) KK kezelési díj mozgás → handlingFeeRequired=true")
    void handlingFeeMovement_flagTrue() {
        stubVaultClosing(List.of("HUF"), List.of(new BigDecimal("100")), List.of(new BigDecimal("100")));
        when(shipmentRequestRepository.findMovedCurrencyCodesForDate(
                eq(COMPANY_ID), eq(BRANCH_ID), eq(CLOSING_DATE), any())).thenReturn(List.of());
        when(shipmentHandlingFeeRepository.existsDailyMovementForSourceBranch(
                COMPANY_ID, BRANCH_ID, CLOSING_DATE)).thenReturn(true);

        ClosingWizardStatusDto dto = vaultStatus();

        assertThat(dto.isHandlingFeeRequired()).isTrue();
    }

    @Test
    @DisplayName("(d) CROSS-TENANT: a mozgás-lekérdezés a hívó companyId-jával fut; üres eredménnyel {HUF} marad")
    void crossTenant_queryUsesCallerCompanyId() {
        stubVaultClosing(List.of("HUF"), List.of(new BigDecimal("100")), List.of(new BigDecimal("100")));
        when(shipmentRequestRepository.findMovedCurrencyCodesForDate(
                eq(COMPANY_ID), eq(BRANCH_ID), eq(CLOSING_DATE), any())).thenReturn(List.of());
        when(shipmentHandlingFeeRepository.existsDailyMovementForSourceBranch(
                COMPANY_ID, BRANCH_ID, CLOSING_DATE)).thenReturn(false);

        ClosingWizardStatusDto dto = vaultStatus();

        // A tenant-kulcs a hívó companyId (invariáns #1) — pontos argumentum-ellenőrzés.
        verify(shipmentRequestRepository).findMovedCurrencyCodesForDate(
                eq(COMPANY_ID), eq(BRANCH_ID), eq(CLOSING_DATE), any());
        assertThat(dto.getRequiredCurrencies()).containsExactly("HUF");
    }

    // =====================================================================
    // (e)–(f): a blokkoló exactMatch csak a kötelező halmazra szűkül
    // =====================================================================

    @Test
    @DisplayName("(e) nem-kötelező valuta eltérése NEM blokkol (exactMatch=true)")
    void nonRequiredCurrencyDifference_doesNotBlock() {
        // EUR aktív, EUR-eltérés van, de EUR NEM szerepel a mozgási halmazban.
        stubVaultClosing(List.of("HUF", "EUR"),
                List.of(new BigDecimal("100"), new BigDecimal("50")),
                List.of(new BigDecimal("100"), new BigDecimal("40")));
        when(shipmentRequestRepository.findMovedCurrencyCodesForDate(
                eq(COMPANY_ID), eq(BRANCH_ID), eq(CLOSING_DATE), any())).thenReturn(List.of());
        when(shipmentHandlingFeeRepository.existsDailyMovementForSourceBranch(
                COMPANY_ID, BRANCH_ID, CLOSING_DATE)).thenReturn(false);

        ClosingWizardStatusDto dto = vaultStatus();

        // A differences TELJES marad (FK-073 szerződés): az EUR-sor DISCREPANCY.
        assertThat(dto.getDifferences()).hasSize(2);
        assertThat(dto.getDifferences().stream()
                .filter(item -> "EUR".equals(item.get("currencyCode")))
                .findFirst().orElseThrow().get("status")).isEqualTo("DISCREPANCY");
        // De a blokkolás csak a kötelező {HUF}-ra vonatkozik → nem blokkol.
        assertThat(dto.isExactMatch()).isTrue();
    }

    @Test
    @DisplayName("(f) kötelező valuta (HUF) eltérése blokkol (exactMatch=false)")
    void requiredCurrencyDifference_blocks() {
        stubVaultClosing(List.of("HUF"), List.of(new BigDecimal("100")), List.of(new BigDecimal("90")));
        when(shipmentRequestRepository.findMovedCurrencyCodesForDate(
                eq(COMPANY_ID), eq(BRANCH_ID), eq(CLOSING_DATE), any())).thenReturn(List.of());
        when(shipmentHandlingFeeRepository.existsDailyMovementForSourceBranch(
                COMPANY_ID, BRANCH_ID, CLOSING_DATE)).thenReturn(false);

        ClosingWizardStatusDto dto = vaultStatus();

        assertThat(dto.isExactMatch()).isFalse();
    }

    // =====================================================================
    // (g): PÉNZTÁR-ág regresszió — a kötelező halmaz itt sosem töltődik
    // =====================================================================

    private void stubPenztarClosing(BigDecimal currentBalance, BigDecimal physicalCount) {
        Branch penztarBranch = Branch.builder()
                .id(BRANCH_ID)
                .code("PT01")
                .isVault(false)
                .company(Company.builder().id(COMPANY_ID).build())
                .build();
        when(branchRepository.findByIdAndCompanyId(BRANCH_ID, COMPANY_ID))
                .thenReturn(Optional.of(penztarBranch));
        when(denominationBalanceRepository.existsByBranchIdAndDateAndCategory(
                BRANCH_ID, CLOSING_DATE, DenominationCategory.EVENING)).thenReturn(true);
        when(denominationBalanceRepository.sumActualStockByCurrency(
                BRANCH_ID, CLOSING_DATE, DenominationCategory.EVENING))
                .thenReturn(List.<Object[]>of(new Object[]{"HUF", physicalCount}));

        Currency huf = new Currency();
        huf.setCode("HUF");
        CashBalance balance = CashBalance.builder()
                .currency(huf)
                .currentBalance(currentBalance)
                .build();
        when(cashBalanceRepository.findByBranchIdAndCompanyId(BRANCH_ID, COMPANY_ID))
                .thenReturn(List.of(balance));
        when(closingToleranceService.getToleranceFor("HUF"))
                .thenReturn(ClosingTolerance.explicitOf(BigDecimal.ZERO));
    }

    @Test
    @DisplayName("(g1) PÉNZTÁR-ág: requiredCurrencies=null, handlingFeeRequired=false, OK sor → exactMatch=true")
    void penztarBranch_okRow_exactMatchTrue() {
        stubPenztarClosing(new BigDecimal("100"), new BigDecimal("100"));

        ClosingWizardStatusDto dto = vaultStatus();

        assertThat(dto.isVaultContext()).isFalse();
        assertThat(dto.getRequiredCurrencies()).isNull();
        assertThat(dto.isHandlingFeeRequired()).isFalse();
        assertThat(dto.isExactMatch()).isTrue();
        // A mozgás-lekérdezések a pénztári ágon sosem futnak.
        verifyNoInteractions(shipmentRequestRepository, shipmentHandlingFeeRepository);
    }

    @Test
    @DisplayName("(g2) PÉNZTÁR-ág: DISCREPANCY sor → exactMatch=false (változatlan szemantika)")
    void penztarBranch_discrepancyRow_exactMatchFalse() {
        stubPenztarClosing(new BigDecimal("100"), new BigDecimal("90"));

        ClosingWizardStatusDto dto = vaultStatus();

        assertThat(dto.isVaultContext()).isFalse();
        assertThat(dto.getRequiredCurrencies()).isNull();
        assertThat(dto.isExactMatch()).isFalse();
    }

    // =====================================================================
    // FKH-036 kieg. #2 FR-13: a blokkoló gate-üzenetek ékezetes alakja
    // =====================================================================

    @Test
    @DisplayName("FKH-036 kieg. #2 FR-13: a blokkolo vault gate-uzenet ekezetes")
    void vaultGateMessageIsAccented() {
        // Kötelező valuta (HUF) eltérése → exactMatch=false → vault-ág gate-üzenete.
        stubVaultClosing(List.of("HUF"), List.of(new BigDecimal("100")), List.of(new BigDecimal("90")));
        when(shipmentRequestRepository.findMovedCurrencyCodesForDate(
                eq(COMPANY_ID), eq(BRANCH_ID), eq(CLOSING_DATE), any())).thenReturn(List.of());
        when(shipmentHandlingFeeRepository.existsDailyMovementForSourceBranch(
                COMPANY_ID, BRANCH_ID, CLOSING_DATE)).thenReturn(false);

        ClosingWizardStatusDto dto = vaultStatus();

        assertThat(dto.isExactMatch()).isFalse();
        assertThat(dto.getMessage()).isEqualTo(
                "Az esti zárás csak a valutánkénti címletezés és a currency_stock teljes egyezése után küldhető.");
    }

    @Test
    @DisplayName("FKH-036 kieg. #2 FR-13: a hianyzo cimletezes uzenete is ekezetes")
    void missingDenominationMessageIsAccented() {
        stubVaultClosing(List.of("HUF"), List.of(new BigDecimal("100")), List.of(new BigDecimal("100")));
        // Felülírás: nincs rögzített esti címletezés erre a napra.
        when(denominationBalanceRepository.existsByBranchIdAndDateAndCategory(
                BRANCH_ID, CLOSING_DATE, DenominationCategory.EVENING)).thenReturn(false);
        when(shipmentRequestRepository.findMovedCurrencyCodesForDate(
                eq(COMPANY_ID), eq(BRANCH_ID), eq(CLOSING_DATE), any())).thenReturn(List.of());
        when(shipmentHandlingFeeRepository.existsDailyMovementForSourceBranch(
                COMPANY_ID, BRANCH_ID, CLOSING_DATE)).thenReturn(false);

        ClosingWizardStatusDto dto = vaultStatus();

        assertThat(dto.getMessage()).isEqualTo("Nincs rögzített esti címletezés erre a napra.");
    }

    // =====================================================================
    // (h): B2 regresszió — egyetlen üzleti dátum-dimenzió (requestDate)
    // =====================================================================

    @Test
    @DisplayName("(h) B2: a valuta- és díj-mozgás lekérdezés UGYANAZT a dátumot kapja; nincs createdAt-ablakos díj-hívás")
    void bothMovementQueriesUseTheSameBusinessDate() {
        stubVaultClosing(List.of("HUF"), List.of(new BigDecimal("100")), List.of(new BigDecimal("100")));
        when(shipmentRequestRepository.findMovedCurrencyCodesForDate(
                eq(COMPANY_ID), eq(BRANCH_ID), eq(CLOSING_DATE), any())).thenReturn(List.of());
        when(shipmentHandlingFeeRepository.existsDailyMovementForSourceBranch(
                COMPANY_ID, BRANCH_ID, CLOSING_DATE)).thenReturn(false);

        vaultStatus();

        verify(shipmentRequestRepository).findMovedCurrencyCodesForDate(
                eq(COMPANY_ID), eq(BRANCH_ID), eq(CLOSING_DATE),
                eq(ShipmentHandlingFeeRepository.KPI_COUNTED_STATUSES));
        verify(shipmentHandlingFeeRepository).existsDailyMovementForSourceBranch(
                eq(COMPANY_ID), eq(BRANCH_ID), eq(CLOSING_DATE));
        // A KPI createdAt-ablakos lekérdezés sosem lehet a záró-kapu bemenete.
        verify(shipmentHandlingFeeRepository, never()).sumReceivedFeesForBranchAndPeriod(
                any(), any(), any(), any(), any());
    }
}
