package hu.puzzleir.valuta.service;

import tools.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.repository.DenominationAllowedRepository;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ClosingWizardServiceTest {

    @Mock private ClosingWizardRepository closingWizardRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private DailySessionRepository dailySessionRepository;
    @Mock private TransactionRepository transactionRepository;
    @Mock private DailyClosingService dailyClosingService;
    @Mock private ObjectMapper objectMapper;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private CurrencyStockRepository currencyStockRepository;
    @Mock private DenominationAllowedRepository denominationAllowedRepository;
    // FKH-036 WU-5: az új konstruktor-függőségek mockjai (pitfall 1).
    @Mock private ShipmentRequestRepository shipmentRequestRepository;
    @Mock private ShipmentHandlingFeeRepository shipmentHandlingFeeRepository;
    @InjectMocks private ClosingWizardService service;

    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final UUID COMPANY_ID = UUID.randomUUID();

    /**
     * A SecurityContext megörökölhető a surefire-fork korábbi tesztjeitől
     * (CI-ben más a tesztsorrend, mint lokálisan). Beragadt Authentication
     * esetén a service company-szkópolt repository-hívásra vált, amit ez a
     * teszt nem stubbol → ResourceNotFound / UnnecessaryStubbing. Ezért
     * minden teszt előtt és után takarítunk.
     */
    @org.junit.jupiter.api.BeforeEach
    @org.junit.jupiter.api.AfterEach
    void clearSecurityContext() {
        org.springframework.security.core.context.SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("startWizard — mar van aktiv varazslo → hiba")
    void testStartWizard_alreadyActive() {
        Branch branch = Branch.builder().id(BRANCH_ID).build();
        Worker worker = Worker.builder().id(1L).build();
        ClosingWizard existing = ClosingWizard.builder().id(UUID.randomUUID()).build();

        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(workerRepository.findById(1L)).thenReturn(Optional.of(worker));
        when(closingWizardRepository.findByBranchIdAndStatusAndClosingDate(
                        eq(BRANCH_ID), eq(WizardStatus.IN_PROGRESS), eq(LocalDate.now())))
                .thenReturn(List.of(existing));

        assertThatThrownBy(() -> service.startWizard(BRANCH_ID, null, "DAILY", 1L))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("aktív");
    }

    @Test
    @DisplayName("startWizard — korábbi napi aktív varázsló nem blokkol")
    void startWizard_priorDayInProgressDoesNotBlock() {
        Branch branch = Branch.builder().id(BRANCH_ID).build();
        Worker worker = Worker.builder().id(1L).build();
        ClosingWizard staleWizard = ClosingWizard.builder()
                .id(UUID.randomUUID())
                .closingDate(LocalDate.now().minusDays(1))
                .wizardStatus(WizardStatus.IN_PROGRESS)
                .build();

        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(workerRepository.findById(1L)).thenReturn(Optional.of(worker));
        when(closingWizardRepository.findByBranchIdAndStatus(eq(BRANCH_ID), any()))
                .thenReturn(List.of(staleWizard));
        when(closingWizardRepository.findByBranchIdAndStatusAndClosingDate(
                        eq(BRANCH_ID), eq(WizardStatus.IN_PROGRESS), eq(LocalDate.now())))
                .thenReturn(List.of());
        when(closingWizardRepository.save(any())).thenAnswer(invocation -> {
            ClosingWizard saved = invocation.getArgument(0);
            saved.setId(UUID.randomUUID());
            return saved;
        });

        assertThat(service.startWizard(BRANCH_ID, null, "DAILY", 1L)).isNotNull();
    }

    @Test
    @DisplayName("startWizard — mai aktív varázsló blokkol")
    void startWizard_sameDayInProgressBlocks() {
        Branch branch = Branch.builder().id(BRANCH_ID).build();
        Worker worker = Worker.builder().id(1L).build();
        ClosingWizard activeToday = ClosingWizard.builder()
                .id(UUID.randomUUID())
                .closingDate(LocalDate.now())
                .wizardStatus(WizardStatus.IN_PROGRESS)
                .build();

        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(workerRepository.findById(1L)).thenReturn(Optional.of(worker));
        when(closingWizardRepository.findByBranchIdAndStatusAndClosingDate(
                        eq(BRANCH_ID), eq(WizardStatus.IN_PROGRESS), eq(LocalDate.now())))
                .thenReturn(List.of(activeToday));

        assertThatThrownBy(() -> service.startWizard(BRANCH_ID, null, "DAILY", 1L))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("aktív");
    }

    @Test
    @DisplayName("startWizard — bejelentkezett kontextusban branch és worker company-scope-pal töltődik")
    void startWizard_authenticatedScopesBranchAndWorkerByCompany() {
        Branch branch = Branch.builder().id(BRANCH_ID).build();
        Worker worker = Worker.builder().id(1L).build();
        ClosingWizard existing = ClosingWizard.builder().id(UUID.randomUUID()).build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_ID);
            when(branchRepository.findByIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(Optional.of(branch));
            when(workerRepository.findByIdAndCompanyId(1L, COMPANY_ID)).thenReturn(Optional.of(worker));
            when(closingWizardRepository.findByBranchIdAndStatusAndClosingDate(
                            eq(BRANCH_ID), eq(WizardStatus.IN_PROGRESS), eq(LocalDate.now())))
                    .thenReturn(List.of(existing));

            assertThatThrownBy(() -> service.startWizard(BRANCH_ID, null, "DAILY", 1L))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("aktív");

            verify(branchRepository).findByIdAndCompanyId(BRANCH_ID, COMPANY_ID);
            verify(workerRepository).findByIdAndCompanyId(1L, COMPANY_ID);
            verify(branchRepository, never()).findById(BRANCH_ID);
            verify(workerRepository, never()).findById(1L);
        }
    }

    @Test
    @DisplayName("startWizard — nem letezo iroda → hiba")
    void testStartWizard_branchNotFound() {
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.startWizard(BRANCH_ID, null, "DAILY", 1L))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    @DisplayName("getWizard — nem letezo → hiba")
    void testGetWizard_notFound() {
        UUID wizardId = UUID.randomUUID();
        when(closingWizardRepository.findByIdWithSteps(wizardId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.getWizard(wizardId))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    @DisplayName("getWizard — IDOR vedelem, mas iroda varaszloja")
    void testGetWizard_idorProtection() {
        UUID wizardId = UUID.randomUUID();
        UUID otherBranch = UUID.randomUUID();
        Branch branch = Branch.builder().id(otherBranch).build();
        ClosingWizard wizard = ClosingWizard.builder()
                .id(wizardId)
                .branch(branch)
                .build();

        when(closingWizardRepository.findByIdWithSteps(wizardId)).thenReturn(Optional.of(wizard));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);

            assertThatThrownBy(() -> service.getWizard(wizardId))
                    .isInstanceOf(ValidationException.class);
        }
    }

    // ============ FK-063 FR-1: getCurrenciesWithBalance ============

    @Test
    @DisplayName("FK-063 FR-1: nem-nulla készletű pénznemek + HUF mindig benne (cég-szűrt)")
    void getCurrenciesWithBalance_returnsStockCurrenciesPlusHuf() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(cashBalanceRepository.findCurrencyCodesWithNonZeroBalance(BRANCH_ID, COMPANY_ID))
                    .thenReturn(List.of("EUR", "USD"));

            List<String> result = service.getCurrenciesWithBalance(BRANCH_ID);

            assertThat(result).containsExactly("HUF", "EUR", "USD");
            verify(cashBalanceRepository).findCurrencyCodesWithNonZeroBalance(BRANCH_ID, COMPANY_ID);
        }
    }

    @Test
    @DisplayName("FK-063 FR-1: HUF nem duplikálódik, ha már készleten van")
    void getCurrenciesWithBalance_noHufDuplicate() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(cashBalanceRepository.findCurrencyCodesWithNonZeroBalance(BRANCH_ID, COMPANY_ID))
                    .thenReturn(List.of("HUF", "EUR"));

            assertThat(service.getCurrenciesWithBalance(BRANCH_ID)).containsExactly("HUF", "EUR");
        }
    }

    @Test
    @DisplayName("FK-063 FR-1 cross-tenant: idegen cég branch-e üres készletet ad → csak HUF")
    void getCurrenciesWithBalance_crossTenant_failClosed() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            // A cég-szűrt query idegen branchId-re üres listát ad (fail-closed)
            when(cashBalanceRepository.findCurrencyCodesWithNonZeroBalance(any(), eq(COMPANY_ID)))
                    .thenReturn(List.of());

            assertThat(service.getCurrenciesWithBalance(UUID.randomUUID())).containsExactly("HUF");
        }
    }

    @Test
    @DisplayName("FKH-029 kieg.: getCurrenciesWithBalance vault branch-re a currency_stock nem-nulla valutáit adja + HUF elöl")
    void getCurrenciesWithBalance_vaultBranch_readsCurrencyStock() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            Branch vault = Branch.builder().id(BRANCH_ID).isVault(true).vaultTerritoryId(12).build();
            when(branchRepository.findByIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(Optional.of(vault));
            when(currencyRepository.findAllActiveOrdered()).thenReturn(List.of(
                    Currency.builder().code("EUR").build(),
                    Currency.builder().code("USD").build()));
            // V371 után a vault cash_balance sorai 0-k — a nonZero cash_balance-szűrő vaultra üres
            // lenne. A valós készlet a currency_stock VAULT sorokban van; a territory-szűrés a
            // dedikált repo-query dolga (Sourcery-kör), a pontos argumentumot verify garantálja.
            when(currencyStockRepository.findByCompanyIdAndEntityTypeAndEntityId(COMPANY_ID, "VAULT", "12"))
                    .thenReturn(List.of(
                            vaultStockRow("12", "EUR", "1000"),
                            vaultStockRow("12", "USD", "0"))); // nulla készlet → nem kerül be

            assertThat(service.getCurrenciesWithBalance(BRANCH_ID)).containsExactly("HUF", "EUR");
            verify(currencyStockRepository).findByCompanyIdAndEntityTypeAndEntityId(COMPANY_ID, "VAULT", "12");
            verify(cashBalanceRepository, never()).findCurrencyCodesWithNonZeroBalance(any(), any());
        }
    }

    @Test
    @DisplayName("FKH-029 kieg.: vault branch vault_territory_id nélkül csak HUF-ot ad (fail-closed)")
    void getCurrenciesWithBalance_vaultBranchWithoutTerritory_hufOnly() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            Branch vault = Branch.builder().id(BRANCH_ID).isVault(true).vaultTerritoryId(null).build();
            when(branchRepository.findByIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(Optional.of(vault));

            assertThat(service.getCurrenciesWithBalance(BRANCH_ID)).containsExactly("HUF");
        }
    }

    private CurrencyStock vaultStockRow(String territoryEntityId, String currencyCode, String quantity) {
        return CurrencyStock.builder()
                .entityType("VAULT")
                .entityId(territoryEntityId)
                .currencyCode(currencyCode)
                .quantity(new java.math.BigDecimal(quantity))
                .build();
    }
}
