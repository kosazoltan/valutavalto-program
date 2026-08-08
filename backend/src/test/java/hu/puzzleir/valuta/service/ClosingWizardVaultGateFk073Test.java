package hu.puzzleir.valuta.service;

import tools.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.repository.DenominationAllowedRepository;
import hu.puzzleir.valuta.dto.closingwizard.ClosingWizardStatusDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ValidationException;
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

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

/**
 * FK-073 FR-4 (c) + FR-1 kiegészítő acceptance — MINDKÉT vault-kapu
 * ({@code finalizeClosing():768-773} ÉS {@code ensureClosingCanBeSent():1096-1105})
 * a 0-küszöbű végállapotban (FR-3) pontosan ugyanúgy dönt, mint FR-1 előtt:
 * {@code OK} ⇔ {@code diff == 0}.
 *
 * <p>A kapuk KÓDJA nem változott (scope-OUT) — a bemenetük azonban igen: az
 * {@code exactMatch} mező a {@code differenceItem} FR-1 által átállított,
 * tolerancia-alapú státuszából számolódik ({@code getClosingStatus():1050-1051} →
 * builder {@code :1088} → mindkét kapu). Ez a teszt a közös forrást
 * ({@link ClosingToleranceService} → {@link ClosingTolerance#blocks}) explicit
 * 0-toleranciával stubbolva igazolja, hogy a végállapot viselkedés-semleges.
 *
 * <p>Scope-OUT betartva: a {@code CLOSING_DISCREPANCY_EXPLANATION_REQUIRED}
 * enforce-logika érintetlen — a véglegesítési tesztben a flag KI, hogy a vizsgálat
 * kizárólag a vault {@code isExactMatch()} kapura fókuszáljon.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class ClosingWizardVaultGateFk073Test {

    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID WIZARD_ID = UUID.randomUUID();
    private static final Long WORKER_ID = 2L;
    private static final LocalDate CLOSING_DATE = LocalDate.of(2026, 8, 5);
    private static final String VAULT_ENTITY_ID = "77";

    @Mock private DenominationAllowedRepository denominationAllowedRepository;
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

        ClosingWizard wizard = ClosingWizard.builder()
                .id(WIZARD_ID)
                .branch(vaultBranch)
                .closingDate(CLOSING_DATE)
                .closingType(ClosingType.DAILY)
                .wizardStatus(WizardStatus.IN_PROGRESS)
                .startedByWorker(Worker.builder().id(1L).build())
                .startedAt(LocalDateTime.now().minusMinutes(10))
                .build();

        when(closingWizardRepository.findByIdWithSteps(WIZARD_ID)).thenReturn(Optional.of(wizard));
        when(closingWizardRepository.save(any(ClosingWizard.class)))
                .thenAnswer(inv -> inv.getArgument(0));
        when(workerRepository.findById(WORKER_ID))
                .thenReturn(Optional.of(Worker.builder().id(WORKER_ID).build()));
        // Az enforce-logika (CLOSING_DISCREPANCY_EXPLANATION_REQUIRED) TILOS-scope: a
        // flag KI, így kizárólag a vault isExactMatch() kapu döntése vizsgálható.
        when(systemParameterService.getValue(anyString(), anyString())).thenReturn("false");
        when(dailyClosingService.startDailyClosing(CLOSING_DATE))
                .thenReturn(DailyClosingService.ClosingWizardResult.builder()
                        .allPassed(true)
                        .steps(List.of())
                        .build());
    }

    /**
     * Vault-zárás stub: egyetlen HUF pénznem, a megadott várt készlettel és
     * becímletezett (fizikai) összeggel; a tolerancia-forrás explicit 0
     * (a V373 utáni FR-3 végállapot).
     */
    private void stubVaultClosing(BigDecimal expectedStock, BigDecimal physicalCount) {
        when(branchRepository.findByIdAndCompanyId(BRANCH_ID, COMPANY_ID))
                .thenReturn(Optional.of(vaultBranch));
        when(denominationBalanceRepository.existsByBranchIdAndDateAndCategory(
                BRANCH_ID, CLOSING_DATE, DenominationCategory.EVENING)).thenReturn(true);
        when(denominationBalanceRepository.sumActualStockByCurrency(
                BRANCH_ID, CLOSING_DATE, DenominationCategory.EVENING))
                .thenReturn(List.<Object[]>of(new Object[]{"HUF", physicalCount}));

        Currency huf = new Currency();
        huf.setCode("HUF");
        when(currencyRepository.findAllActiveOrdered()).thenReturn(List.of(huf));

        CurrencyStock stock = new CurrencyStock();
        stock.setCurrencyCode("HUF");
        stock.setQuantity(expectedStock);
        when(currencyStockRepository.findByCompanyIdAndEntityTypeAndEntityIdAndCurrencyCode(
                COMPANY_ID, "VAULT", VAULT_ENTITY_ID, "HUF")).thenReturn(Optional.of(stock));

        // FR-3 végállapot: explicit 0-küszöb — a KÖZÖS forrás, amit a finalizeClosing
        // enforce-ága és az FR-1 utáni differenceItem-státusz is használ.
        when(closingToleranceService.getToleranceFor("HUF"))
                .thenReturn(ClosingTolerance.explicitOf(BigDecimal.ZERO));
    }

    private ClosingWizardStatusDto statusWithSecurity(BigDecimal expected, BigDecimal physical) {
        stubVaultClosing(expected, physical);
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            return service.getClosingStatus(BRANCH_ID, CLOSING_DATE);
        }
    }

    // =====================================================================
    // Az eltérés-táblázat státusza és az exactMatch közös forrása
    // =====================================================================

    @Test
    @DisplayName("FR-1: 0-küszöbnél diff==0 → status OK + exactMatch=true (a táblázat és a kapu egybeesik)")
    void zeroDifference_statusOk_exactMatchTrue() {
        ClosingWizardStatusDto status =
                statusWithSecurity(new BigDecimal("100"), new BigDecimal("100"));

        assertThat(status.isExactMatch()).isTrue();
        Map<String, Object> hufRow = status.getDifferences().stream()
                .filter(item -> "HUF".equals(item.get("currencyCode")))
                .findFirst().orElseThrow();
        assertThat(hufRow.get("status")).isEqualTo("OK");
        verify(closingToleranceService, atLeastOnce()).getToleranceFor("HUF");
    }

    @Test
    @DisplayName("FR-1/FR-4: 0-küszöbnél a legkisebb eltérés (0.01) is status DISCREPANCY + exactMatch=false")
    void smallestNonZeroDifference_statusDiscrepancy_exactMatchFalse() {
        ClosingWizardStatusDto status =
                statusWithSecurity(new BigDecimal("100"), new BigDecimal("100.01"));

        assertThat(status.isExactMatch()).isFalse();
        Map<String, Object> hufRow = status.getDifferences().stream()
                .filter(item -> "HUF".equals(item.get("currencyCode")))
                .findFirst().orElseThrow();
        assertThat(hufRow.get("status")).isEqualTo("DISCREPANCY");
        assertThat((BigDecimal) hufRow.get("difference"))
                .isEqualByComparingTo(new BigDecimal("0.01"));
        verify(closingToleranceService, atLeastOnce()).getToleranceFor("HUF");
    }

    // =====================================================================
    // 1. vault-kapu: ensureClosingCanBeSent
    // =====================================================================

    @Test
    @DisplayName("FR-4 (c) 1. kapu: ensureClosingCanBeSent 0-küszöbnél diff==0 esetén átenged")
    void ensureClosingCanBeSent_zeroDifference_passes() {
        stubVaultClosing(new BigDecimal("100"), new BigDecimal("100"));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);

            assertThatCode(() -> service.ensureClosingCanBeSent(BRANCH_ID, CLOSING_DATE))
                    .doesNotThrowAnyException();
        }
    }

    @Test
    @DisplayName("FR-4 (c) 1. kapu: ensureClosingCanBeSent 0-küszöbnél bármilyen nem-nulla diffnél blokkol")
    void ensureClosingCanBeSent_nonZeroDifference_blocks() {
        stubVaultClosing(new BigDecimal("100"), new BigDecimal("99.99"));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);

            assertThatThrownBy(() -> service.ensureClosingCanBeSent(BRANCH_ID, CLOSING_DATE))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("currency_stock");
        }
    }

    // =====================================================================
    // 2. vault-kapu: finalizeClosing (768-773, változatlan kód)
    // =====================================================================

    @Test
    @DisplayName("FR-4 (c) 2. kapu: finalizeClosing 0-küszöbnél diff==0 esetén véglegesít (OK ⇔ diff==0)")
    void finalizeClosing_zeroDifference_finalizes() {
        stubVaultClosing(new BigDecimal("100"), new BigDecimal("100"));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);

            assertThat(service.finalizeClosing(WIZARD_ID, WORKER_ID)).isTrue();
        }
        // A kapu nem blokkolt — a napzárás ténylegesen elindult.
        verify(dailyClosingService).startDailyClosing(CLOSING_DATE);
    }

    @Test
    @DisplayName("FR-4 (c) 2. kapu: finalizeClosing 0-küszöbnél bármilyen nem-nulla diffnél blokkol (OK ⇔ diff==0)")
    void finalizeClosing_nonZeroDifference_blocks() {
        stubVaultClosing(new BigDecimal("100"), new BigDecimal("100.01"));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);

            assertThatThrownBy(() -> service.finalizeClosing(WIZARD_ID, WORKER_ID))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("currency_stock");
        }
        // A kapu blokkolt — napzárás nem indulhatott.
        verify(dailyClosingService, never()).startDailyClosing(any());
    }
}
