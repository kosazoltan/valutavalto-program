package hu.puzzleir.valuta.integration;

import tools.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.repository.DenominationAllowedRepository;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.service.ClosingWizardService;
import hu.puzzleir.valuta.service.DailyClosingService;
import hu.puzzleir.valuta.dto.closingwizard.ClosingWizardDto;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

// Explicit import: Currency entity (nem java.util.Currency)
import hu.puzzleir.valuta.entity.Currency;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * ClosingFlow integrációs tesztek — zárási varázsló flow.
 *
 * Happy path: validate → denom → diff → report → finalize
 * With open transactions: validate returns warnings
 */
@ExtendWith(MockitoExtension.class)
class ClosingFlowTest {

    @Mock private DenominationAllowedRepository denominationAllowedRepository;
    @InjectMocks
    private ClosingWizardService closingWizardService;

    @Mock private ClosingWizardRepository closingWizardRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private DailySessionRepository dailySessionRepository;
    @Mock private DailyClosingService dailyClosingService;
    @Mock private hu.puzzleir.valuta.repository.TransactionRepository transactionRepository;
    // Issue #117: uj mockok a countDenominations perzisztalashoz
    @Mock private hu.puzzleir.valuta.repository.DenominationRepository denominationRepository;
    @Mock private hu.puzzleir.valuta.repository.DenominationBalanceRepository denominationBalanceRepository;
    @Mock private hu.puzzleir.valuta.repository.CurrencyRepository currencyRepository;
    // FK-073 (§9.3): a differenceItem-státusz a valódi ClosingTolerance.blocks()-ot hívja —
    // mock nélkül NPE lenne a testClosingWizard_calculateDifferences futásánál.
    @Mock private hu.puzzleir.valuta.service.ClosingToleranceService closingToleranceService;

    @Spy
    private ObjectMapper objectMapper = new ObjectMapper();

    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final UUID CASH_DESK_ID = UUID.randomUUID();
    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final Long WORKER_ID = 1L;

    private Branch branch;
    private Worker worker;

    @BeforeEach
    void setUp() {
        branch = new Branch();
        branch.setId(BRANCH_ID);
        branch.setCode("B01");
        branch.setName("Teszt Iroda");
        branch.setCompany(Company.builder().id(COMPANY_ID).build());

        worker = new Worker();
        worker.setId(WORKER_ID);
        worker.setName("Teszt Pénztáros");
        worker.setCompany(Company.builder().id(COMPANY_ID).build());

        // IDOR-guard (audit 2026-06-15): assertOwnWizard SecurityUtils.getCurrentBranchId()-t hív
        // (navigate/complete/cancel/getStep). A hívó branch-e == a wizard branch-e (BRANCH_ID).
        WorkerAuthenticationDetails details =
                new WorkerAuthenticationDetails(WORKER_ID, COMPANY_ID, BRANCH_ID, "PENZTAROS");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("t", "x", "ROLE_PENZTAROS");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @AfterEach
    void tearDownSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Nested
    @DisplayName("Happy Path — teljes zárási ciklus")
    class HappyPathTests {

        @Test
        @DisplayName("testClosingWizard_happyPath — varázsló indítás, lépések, befejezés")
        void testClosingWizard_happyPath() {
            when(branchRepository.findByIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(Optional.of(branch));
            when(workerRepository.findByIdAndCompanyId(WORKER_ID, COMPANY_ID)).thenReturn(Optional.of(worker));
            when(closingWizardRepository.findByBranchIdAndStatusAndClosingDate(
                            BRANCH_ID, WizardStatus.IN_PROGRESS, LocalDate.now()))
                    .thenReturn(Collections.emptyList());
            when(closingWizardRepository.findByBranchIdAndStatus(BRANCH_ID, WizardStatus.IN_PROGRESS))
                    .thenReturn(Collections.emptyList());
            when(closingWizardRepository.save(any(ClosingWizard.class))).thenAnswer(inv -> {
                ClosingWizard w = inv.getArgument(0);
                if (w.getId() == null) w.setId(UUID.randomUUID());
                return w;
            });

            ClosingWizardDto result = closingWizardService.startWizard(BRANCH_ID, CASH_DESK_ID, "DAILY", WORKER_ID);

            assertThat(result).isNotNull();
            assertThat(result.getWizardStatus()).isEqualTo("IN_PROGRESS");
            assertThat(result.getClosingType()).isEqualTo("DAILY");
            assertThat(result.getCurrentStep()).isEqualTo(1);
            // FK-068: legacy 16-lépés wizard, DAILY típusra 9 aktív (a 16. lépés
            // napi zárásnál nem alkalmazható — igazodás a 9 lépéses ellenőrzés-lánchoz)
            assertThat(result.getTotalSteps()).isEqualTo(9);
            assertThat(result.getBranchName()).isEqualTo("Teszt Iroda");
            assertThat(result.getSteps()).hasSize(9);
        }

        @Test
        @DisplayName("testClosingWizard_navigate — lépés navigáció + ellenőrzés végrehajtás")
        void testClosingWizard_navigate() {
            UUID wizardId = UUID.randomUUID();
            ClosingWizard wizard = createWizard(wizardId, 1, WizardStatus.IN_PROGRESS);

            when(closingWizardRepository.findByIdWithSteps(wizardId)).thenReturn(Optional.of(wizard));
            when(closingWizardRepository.save(any(ClosingWizard.class))).thenAnswer(inv -> inv.getArgument(0));
            // A navigate most végrehajtja az adott lépés ellenőrzését a DailyClosingService-en keresztül
            when(dailyClosingService.executeStepCheck(eq(3), any(UUID.class), any(LocalDate.class)))
                    .thenReturn(DailyClosingService.StepCheckResult.passed("Teszt rendben"));

            ClosingWizardDto dto = closingWizardService.navigate(wizardId, 3);

            assertThat(dto.getCurrentStep()).isEqualTo(3);
            verify(closingWizardRepository).save(any(ClosingWizard.class));
            verify(dailyClosingService).executeStepCheck(eq(3), any(UUID.class), any(LocalDate.class));
        }

        @Test
        @DisplayName("testClosingWizard_complete — varázsló befejezése")
        void testClosingWizard_complete() {
            UUID wizardId = UUID.randomUUID();
            ClosingWizard wizard = createWizard(wizardId, 5, WizardStatus.IN_PROGRESS);

            when(closingWizardRepository.findByIdWithSteps(wizardId)).thenReturn(Optional.of(wizard));
            when(workerRepository.findByIdAndCompanyId(WORKER_ID, COMPANY_ID)).thenReturn(Optional.of(worker));
            when(closingWizardRepository.save(any(ClosingWizard.class))).thenAnswer(inv -> inv.getArgument(0));

            ClosingWizardDto dto = closingWizardService.complete(wizardId, WORKER_ID);

            assertThat(dto.getWizardStatus()).isEqualTo("COMPLETED");
            assertThat(dto.getCompletedByWorkerName()).isEqualTo("Teszt Pénztáros");
        }

        @Test
        @DisplayName("testClosingWizard_denomCount — címletezés számítás")
        void testClosingWizard_denomCount() {
            LocalDate businessDate = LocalDate.of(2026, 7, 22);
            Map<String, Map<Integer, Integer>> denomCounts = new LinkedHashMap<>();
            denomCounts.put("HUF", Map.of(20000, 5, 10000, 3, 5000, 2));
            denomCounts.put("EUR", Map.of(100, 10, 50, 5));

            // Issue #117: uj mockok a perzisztalashoz
            hu.puzzleir.valuta.entity.Currency hufC = new hu.puzzleir.valuta.entity.Currency();
            hufC.setId(3L); hufC.setCode("HUF");
            hu.puzzleir.valuta.entity.Currency eurC = new hu.puzzleir.valuta.entity.Currency();
            eurC.setId(4L); eurC.setCode("EUR");
            when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(hufC));
            when(currencyRepository.findByCode("EUR")).thenReturn(Optional.of(eurC));

            // FK-076 (FR-3): az EUR auto-create ág a denomination_allowed ellen validál —
            // EUR 100 és EUR 50 a V376 seedben engedélyezett kombinációk.
            when(denominationAllowedRepository.existsAllowed(eq(COMPANY_ID), eq(4L), any()))
                    .thenReturn(true);

            // Denomination auto-create path: mindig ures Optional -> save-el ujat
            when(denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(eq(BRANCH_ID), any(), any()))
                    .thenReturn(Optional.empty());
            when(denominationRepository.save(any(hu.puzzleir.valuta.entity.Denomination.class)))
                    .thenAnswer(inv -> {
                        hu.puzzleir.valuta.entity.Denomination d = inv.getArgument(0);
                        if (d.getId() == null) d.setId(1L);
                        return d;
                    });

            // Branch lookup a auto-create-hez
            hu.puzzleir.valuta.entity.Company company = new hu.puzzleir.valuta.entity.Company();
            company.setId(COMPANY_ID);
            branch.setCompany(company);
            when(branchRepository.findByIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(Optional.of(branch));

            when(denominationBalanceRepository.findByCashDeskIdAndDenominationIdAndCategory(eq(BRANCH_ID), any(), any()))
                    .thenReturn(Optional.empty());
            when(denominationBalanceRepository.save(any(hu.puzzleir.valuta.entity.DenominationBalance.class)))
                    .thenAnswer(inv -> inv.getArgument(0));

            Map<String, Object> result = closingWizardService.countDenominations(
                    BRANCH_ID, businessDate, denomCounts);

            assertThat(result).containsKey("totals");
            @SuppressWarnings("unchecked")
            Map<String, BigDecimal> totals = (Map<String, BigDecimal>) result.get("totals");
            assertThat(totals.get("HUF")).isEqualByComparingTo(new BigDecimal("140000")); // 100k + 30k + 10k
            assertThat(totals.get("EUR")).isEqualByComparingTo(new BigDecimal("1250")); // 1000 + 250
            ArgumentCaptor<DenominationBalance> savedBalance = ArgumentCaptor.forClass(DenominationBalance.class);
            verify(denominationBalanceRepository, times(5)).save(savedBalance.capture());
            assertThat(savedBalance.getAllValues())
                    .allSatisfy(balance -> assertThat(balance.getSubmissionDate()).isEqualTo(businessDate));
        }

        @Test
        @DisplayName("testClosingWizard_calculateDifferences — eltérés számítás")
        void testClosingWizard_calculateDifferences() {
            hu.puzzleir.valuta.entity.Currency eur = new hu.puzzleir.valuta.entity.Currency();
            eur.setCode("EUR");
            hu.puzzleir.valuta.entity.Currency huf = new hu.puzzleir.valuta.entity.Currency();
            huf.setCode("HUF");

            CashBalance eurBal = new CashBalance();
            eurBal.setCurrency(eur);
            eurBal.setCurrentBalance(new BigDecimal("5000"));

            CashBalance hufBal = new CashBalance();
            hufBal.setCurrency(huf);
            hufBal.setCurrentBalance(new BigDecimal("2000000"));

            when(branchRepository.findByIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(Optional.of(branch));
            when(cashBalanceRepository.findByBranchIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(List.of(eurBal, hufBal));

            // FK-073 (FR-1/§9.3): a státusz-számítás a valódi ClosingTolerance.blocks()-ot
            // hívja — a 0-küszöbű végállapotot (FR-3) szimuláljuk: explicit 0-toleranciánál
            // bármilyen nem-nulla eltérés blokkol (EUR -10 → DISCREPANCY), a nulla nem (HUF 0 → OK).
            when(closingToleranceService.getToleranceFor("EUR"))
                    .thenReturn(hu.puzzleir.valuta.service.ClosingTolerance.explicitOf(BigDecimal.ZERO));
            when(closingToleranceService.getToleranceFor("HUF"))
                    .thenReturn(hu.puzzleir.valuta.service.ClosingTolerance.explicitOf(BigDecimal.ZERO));

            Map<String, BigDecimal> physicalCounts = Map.of(
                    "EUR", new BigDecimal("4990"),
                    "HUF", new BigDecimal("2000000")
            );

            List<Map<String, Object>> differences = closingWizardService.calculateDifferences(BRANCH_ID, physicalCounts);

            assertThat(differences).hasSize(2);

            Map<String, Object> eurDiff = differences.stream()
                    .filter(d -> "EUR".equals(d.get("currencyCode")))
                    .findFirst().orElseThrow();
            assertThat(eurDiff.get("status")).isEqualTo("DISCREPANCY");
            assertThat((BigDecimal) eurDiff.get("difference")).isEqualByComparingTo(new BigDecimal("-10"));

            Map<String, Object> hufDiff = differences.stream()
                    .filter(d -> "HUF".equals(d.get("currencyCode")))
                    .findFirst().orElseThrow();
            assertThat(hufDiff.get("status")).isEqualTo("OK");
        }

        @Test
        @DisplayName("testClosingWizard_cancel — varázsló megszakítása")
        void testClosingWizard_cancel() {
            UUID wizardId = UUID.randomUUID();
            ClosingWizard wizard = createWizard(wizardId, 2, WizardStatus.IN_PROGRESS);

            when(closingWizardRepository.findByIdWithSteps(wizardId)).thenReturn(Optional.of(wizard));
            when(closingWizardRepository.save(any(ClosingWizard.class))).thenAnswer(inv -> inv.getArgument(0));

            ClosingWizardDto dto = closingWizardService.cancel(wizardId);

            assertThat(dto.getWizardStatus()).isEqualTo("CANCELLED");
        }
    }

    @Nested
    @DisplayName("Edge Cases — hibakezelés")
    class EdgeCaseTests {

        @Test
        @DisplayName("testClosingWizard_withOpenTransactions — nyitott tranzakciók figyelmeztetés")
        void testClosingWizard_withOpenTransactions() {
            when(dailySessionRepository.hasOpenSession(org.mockito.ArgumentMatchers.eq(COMPANY_ID), org.mockito.ArgumentMatchers.eq(BRANCH_ID))).thenReturn(false);

            List<String> warnings = closingWizardService.validateOpenTransactions(BRANCH_ID);

            assertThat(warnings).isNotEmpty();
            assertThat(warnings.get(0)).contains("munkamenet");
        }

        @Test
        @DisplayName("testClosingWizard_duplicateActive — már van aktív varázsló")
        void testClosingWizard_duplicateActive() {
            when(branchRepository.findByIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(Optional.of(branch));
            when(workerRepository.findByIdAndCompanyId(WORKER_ID, COMPANY_ID)).thenReturn(Optional.of(worker));

            ClosingWizard existing = createWizard(UUID.randomUUID(), 1, WizardStatus.IN_PROGRESS);
            when(closingWizardRepository.findByBranchIdAndStatusAndClosingDate(
                            BRANCH_ID, WizardStatus.IN_PROGRESS, LocalDate.now()))
                    .thenReturn(List.of(existing));

            assertThatThrownBy(() -> closingWizardService.startWizard(BRANCH_ID, CASH_DESK_ID, "DAILY", WORKER_ID))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("aktív");
        }

        @Test
        @DisplayName("testClosingWizard_invalidStep — érvénytelen lépés szám")
        void testClosingWizard_invalidStep() {
            UUID wizardId = UUID.randomUUID();
            ClosingWizard wizard = createWizard(wizardId, 1, WizardStatus.IN_PROGRESS);

            when(closingWizardRepository.findByIdWithSteps(wizardId)).thenReturn(Optional.of(wizard));

            assertThatThrownBy(() -> closingWizardService.navigate(wizardId, 99))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("Érvénytelen");
        }

        @Test
        @DisplayName("testClosingWizard_completedCantNavigate — befejezett varázsló nem navigálható")
        void testClosingWizard_completedCantNavigate() {
            UUID wizardId = UUID.randomUUID();
            ClosingWizard wizard = createWizard(wizardId, 5, WizardStatus.COMPLETED);

            when(closingWizardRepository.findByIdWithSteps(wizardId)).thenReturn(Optional.of(wizard));

            assertThatThrownBy(() -> closingWizardService.navigate(wizardId, 3))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("aktív");
        }
    }

    // ===== HELPER =====

    private ClosingWizard createWizard(UUID id, int currentStep, WizardStatus status) {
        List<ClosingWizardStep> steps = new ArrayList<>();
        for (int i = 1; i <= 5; i++) {
            steps.add(ClosingWizardStep.builder()
                    .stepNumber(i)
                    .stepTitle("Lépés " + i)
                    .stepDescription("Leírás " + i)
                    .completed(i <= currentStep)
                    .canProceed(true)
                    .stepData("{}")
                    .build());
        }

        return ClosingWizard.builder()
                .id(id)
                .branch(branch)
                .cashDeskId(CASH_DESK_ID)
                .closingDate(LocalDate.now())
                .closingType(ClosingType.DAILY)
                .currentStep(currentStep)
                .totalSteps(5)
                .wizardStatus(status)
                .startedByWorker(worker)
                .startedAt(LocalDateTime.now())
                .steps(steps)
                .build();
    }
}
