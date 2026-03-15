package hu.puzzleir.valuta.integration;

import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.service.ClosingWizardService;
import hu.puzzleir.valuta.dto.closingwizard.ClosingWizardDto;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

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

    @InjectMocks
    private ClosingWizardService closingWizardService;

    @Mock private ClosingWizardRepository closingWizardRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private DailySessionRepository dailySessionRepository;

    @Spy
    private ObjectMapper objectMapper = new ObjectMapper();

    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final UUID CASH_DESK_ID = UUID.randomUUID();
    private static final Long WORKER_ID = 1L;

    private Branch branch;
    private Worker worker;

    @BeforeEach
    void setUp() {
        branch = new Branch();
        branch.setId(BRANCH_ID);
        branch.setCode("B01");
        branch.setName("Teszt Iroda");

        worker = new Worker();
        worker.setId(WORKER_ID);
        worker.setName("Teszt Pénztáros");
    }

    @Nested
    @DisplayName("Happy Path — teljes zárási ciklus")
    class HappyPathTests {

        @Test
        @DisplayName("testClosingWizard_happyPath — varázsló indítás, lépések, befejezés")
        void testClosingWizard_happyPath() {
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
            when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
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
            assertThat(result.getTotalSteps()).isEqualTo(10); // Legacy 16-lépés wizard, DAILY típusra 10 aktív
            assertThat(result.getBranchName()).isEqualTo("Teszt Iroda");
            assertThat(result.getSteps()).hasSize(10);
        }

        @Test
        @DisplayName("testClosingWizard_navigate — lépés navigáció")
        void testClosingWizard_navigate() {
            UUID wizardId = UUID.randomUUID();
            ClosingWizard wizard = createWizard(wizardId, 1, WizardStatus.IN_PROGRESS);

            when(closingWizardRepository.findByIdWithSteps(wizardId)).thenReturn(Optional.of(wizard));
            when(closingWizardRepository.save(any(ClosingWizard.class))).thenAnswer(inv -> inv.getArgument(0));

            ClosingWizardDto dto = closingWizardService.navigate(wizardId, 3);

            assertThat(dto.getCurrentStep()).isEqualTo(3);
            verify(closingWizardRepository).save(any(ClosingWizard.class));
        }

        @Test
        @DisplayName("testClosingWizard_complete — varázsló befejezése")
        void testClosingWizard_complete() {
            UUID wizardId = UUID.randomUUID();
            ClosingWizard wizard = createWizard(wizardId, 5, WizardStatus.IN_PROGRESS);

            when(closingWizardRepository.findByIdWithSteps(wizardId)).thenReturn(Optional.of(wizard));
            when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
            when(closingWizardRepository.save(any(ClosingWizard.class))).thenAnswer(inv -> inv.getArgument(0));

            ClosingWizardDto dto = closingWizardService.complete(wizardId, WORKER_ID);

            assertThat(dto.getWizardStatus()).isEqualTo("COMPLETED");
            assertThat(dto.getCompletedByWorkerName()).isEqualTo("Teszt Pénztáros");
        }

        @Test
        @DisplayName("testClosingWizard_denomCount — címletezés számítás")
        void testClosingWizard_denomCount() {
            Map<String, Map<Integer, Integer>> denomCounts = new LinkedHashMap<>();
            denomCounts.put("HUF", Map.of(20000, 5, 10000, 3, 5000, 2));
            denomCounts.put("EUR", Map.of(100, 10, 50, 5));

            Map<String, Object> result = closingWizardService.countDenominations(BRANCH_ID, denomCounts);

            assertThat(result).containsKey("totals");
            @SuppressWarnings("unchecked")
            Map<String, BigDecimal> totals = (Map<String, BigDecimal>) result.get("totals");
            assertThat(totals.get("HUF")).isEqualByComparingTo(new BigDecimal("140000")); // 100k + 30k + 10k
            assertThat(totals.get("EUR")).isEqualByComparingTo(new BigDecimal("1250")); // 1000 + 250
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

            when(cashBalanceRepository.findByBranchId(BRANCH_ID)).thenReturn(List.of(eurBal, hufBal));

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
            when(dailySessionRepository.hasOpenSession(BRANCH_ID)).thenReturn(false);

            List<String> warnings = closingWizardService.validateOpenTransactions(BRANCH_ID);

            assertThat(warnings).isNotEmpty();
            assertThat(warnings.get(0)).contains("munkamenet");
        }

        @Test
        @DisplayName("testClosingWizard_duplicateActive — már van aktív varázsló")
        void testClosingWizard_duplicateActive() {
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
            when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));

            ClosingWizard existing = createWizard(UUID.randomUUID(), 1, WizardStatus.IN_PROGRESS);
            when(closingWizardRepository.findByBranchIdAndStatus(BRANCH_ID, WizardStatus.IN_PROGRESS))
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
