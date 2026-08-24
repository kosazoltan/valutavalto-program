package hu.puzzleir.valuta.service;

import tools.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.repository.DenominationAllowedRepository;
import hu.puzzleir.valuta.dto.closingwizard.ClosingWizardDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.ClosingWizardSteps.StepDefinition;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.time.LocalDate;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

/**
 * FK-068: a napi zárás lépésszámának javítása 10-ről 9-re — RED-fázis tesztek
 * (teszt-vezérelt, a FK-065 RED-minta szerint).
 *
 * <p>SZERZŐDÉS (FK-068 FR-1/FR-2 + a Fázis 0 felderítés tényeire építve):
 * <ul>
 *   <li>A {@link ClosingWizardSteps} 16. lépésének
 *       ({@code STEP_SEND_PERIOD_REPORTS_FINALIZE}) {@code applicableDaily} jelölése
 *       {@code false}-ra vált — KIZÁRÓLAG a jelölés, a lépés-definíció megmarad
 *       (OUT: a 16. lépés törlése a definíciós listából TILOS).</li>
 *   <li>FR-1 acceptance: DAILY zárástípusra a lépés-lista létrehozásakor pontosan
 *       9 perzisztált lépés keletkezik, a 16. legacy lépés nélkül. A megmaradó
 *       legacy lépés-sorszámok: 1, 2, 3, 4, 5, 6, 13, 14, 15. Ez megegyezik a
 *       {@code DailyClosingService.executeStepCheck} 9 esetes (pozíció-alapú)
 *       ellenőrzés-láncával — a 10. pozíció ma garantáltan
 *       "Ismeretlen lepes szam" hibára fut.</li>
 *   <li>FR-2 acceptance (regressziós guard): DECADE = 12, MONTHLY = 12, POS = 6
 *       lépés — a javítás előtti értékekkel azonosan, változatlan legacy
 *       sorszám-listával. Ezek a tesztek a MOSTANI kódon is zöldek; céljuk, hogy
 *       a Fázis 1 módosítás ne érinthesse a többi zárástípust.</li>
 * </ul>
 *
 * <p>EBBEN A FÁZISBAN A DAILY-TESZTEKNEK BUKNIUK KELL (a jelenlegi kód 10 aktív
 * napi lépést ad). Tesztet a bukás elfedésére módosítani TILOS. A meglévő
 * {@code ClosingFlowTest.testClosingWizard_happyPath} 10-es assertje az FK-068
 * dokumentált spec-változás részeként a GREEN-fázisban igazítandó 9-re.
 */
@ExtendWith(MockitoExtension.class)
class ClosingWizardDailyStepCountFk068Test {

    // ============ FR-1 + FR-2: tiszta lépés-definíciós tesztek ============

    @Nested
    @DisplayName("FK-068 FR-1 — DAILY lépés-definíciók (RED: ma 10, elvárt 9)")
    class DailyStepDefinitions {

        @Test
        @DisplayName("FR-1: getStepCountForType(DAILY) pontosan 9")
        void dailyStepCount_isNine() {
            assertThat(ClosingWizardSteps.getStepCountForType("DAILY")).isEqualTo(9);
        }

        @Test
        @DisplayName("FR-1: a DAILY lépés-lista a 16. legacy lépés NÉLKÜL áll össze")
        void dailySteps_doNotContainStep16() {
            List<Integer> dailyStepNumbers = ClosingWizardSteps.getStepsForType("DAILY").stream()
                    .map(StepDefinition::stepNumber)
                    .toList();

            assertThat(dailyStepNumbers)
                    .doesNotContain(ClosingWizardSteps.STEP_SEND_PERIOD_REPORTS_FINALIZE)
                    .containsExactly(
                            ClosingWizardSteps.STEP_CLOSING_TYPE_SELECTION,        // 1
                            ClosingWizardSteps.STEP_DAILY_TRANSACTION_SUMMARY,     // 2
                            ClosingWizardSteps.STEP_CASH_BALANCE_CHECK,            // 3
                            ClosingWizardSteps.STEP_HANDLING_FEES_SUMMARY,         // 4
                            ClosingWizardSteps.STEP_INTER_BRANCH_MOVEMENTS,        // 5
                            ClosingWizardSteps.STEP_DAILY_EXCHANGE_RATE_CHECK,     // 6
                            ClosingWizardSteps.STEP_PRINT_CLOSING_RECEIPTS,        // 13
                            ClosingWizardSteps.STEP_PRINT_HUF_TRANSFER_RECEIPTS,   // 14
                            ClosingWizardSteps.STEP_SEND_DAILY_REPORTS);           // 15
        }

        @Test
        @DisplayName("FR-1: a 16. lépés definíciója DAILY-re nem alkalmazható (isApplicable=false)")
        void step16_notApplicableForDaily() {
            StepDefinition step16 = ClosingWizardSteps.ALL_STEPS.stream()
                    .filter(s -> s.stepNumber() == ClosingWizardSteps.STEP_SEND_PERIOD_REPORTS_FINALIZE)
                    .findFirst()
                    .orElseThrow();

            assertThat(step16.isApplicable("DAILY"))
                    .as("A 16. lépés (időszaki jelentések + véglegesítés) napi zárásnál nem aktív")
                    .isFalse();
        }

        @Test
        @DisplayName("OUT-guard: a 16. lépés definíciója MEGMARAD a listában (csak a jelölés vált)")
        void step16_definitionRemainsInList() {
            assertThat(ClosingWizardSteps.LEGACY_TOTAL_STEPS).isEqualTo(16);
            assertThat(ClosingWizardSteps.ALL_STEPS).hasSize(16);
            assertThat(ClosingWizardSteps.ALL_STEPS.stream()
                    .map(StepDefinition::stepNumber)
                    .toList())
                    .contains(ClosingWizardSteps.STEP_SEND_PERIOD_REPORTS_FINALIZE);
        }
    }

    @Nested
    @DisplayName("FK-068 FR-2 — DECADE/MONTHLY/POS regressziós guard (a mostani kódon is zöld)")
    class OtherClosingTypesUnchanged {

        @Test
        @DisplayName("FR-2: DECADE lépésszám és sorszám-lista változatlan (12 lépés)")
        void decadeSteps_unchanged() {
            assertThat(ClosingWizardSteps.getStepCountForType("DECADE")).isEqualTo(12);
            assertThat(ClosingWizardSteps.getStepsForType("DECADE").stream()
                    .map(StepDefinition::stepNumber)
                    .toList())
                    .containsExactly(1, 2, 3, 4, 5, 7, 8, 9, 13, 14, 15, 16);
        }

        @Test
        @DisplayName("FR-2: MONTHLY lépésszám és sorszám-lista változatlan (12 lépés)")
        void monthlySteps_unchanged() {
            assertThat(ClosingWizardSteps.getStepCountForType("MONTHLY")).isEqualTo(12);
            assertThat(ClosingWizardSteps.getStepsForType("MONTHLY").stream()
                    .map(StepDefinition::stepNumber)
                    .toList())
                    .containsExactly(1, 2, 3, 4, 5, 7, 8, 9, 13, 14, 15, 16);
        }

        @Test
        @DisplayName("FR-2: POS lépésszám és sorszám-lista változatlan (6 lépés)")
        void posSteps_unchanged() {
            assertThat(ClosingWizardSteps.getStepCountForType("POS")).isEqualTo(6);
            assertThat(ClosingWizardSteps.getStepsForType("POS").stream()
                    .map(StepDefinition::stepNumber)
                    .toList())
                    .containsExactly(1, 10, 11, 12, 13, 16);
        }

        @Test
        @DisplayName("FR-2 guard: a 16. lépés DECADE/MONTHLY/POS típusokra alkalmazható marad")
        void step16_remainsApplicableForOtherTypes() {
            StepDefinition step16 = ClosingWizardSteps.ALL_STEPS.stream()
                    .filter(s -> s.stepNumber() == ClosingWizardSteps.STEP_SEND_PERIOD_REPORTS_FINALIZE)
                    .findFirst()
                    .orElseThrow();

            assertThat(step16.isApplicable("DECADE")).isTrue();
            assertThat(step16.isApplicable("MONTHLY")).isTrue();
            assertThat(step16.isApplicable("POS")).isTrue();
        }
    }

    // ============ FR-1: perzisztált lépések a startWizard-on át ============

    @Nested
    @ExtendWith(MockitoExtension.class)
    @DisplayName("FK-068 FR-1 — startWizard(DAILY): 9 perzisztált lépés (RED: ma 10)")
    class PersistedDailySteps {

        @Mock private ClosingWizardRepository closingWizardRepository;
        @Mock private WorkerRepository workerRepository;
        @Mock private BranchRepository branchRepository;
        @Mock private CashBalanceRepository cashBalanceRepository;
        @Mock private DailySessionRepository dailySessionRepository;
        @Mock private TransactionRepository transactionRepository;
        @Mock private DailyClosingService dailyClosingService;
        @Mock private DenominationRepository denominationRepository;
        @Mock private DenominationBalanceRepository denominationBalanceRepository;
        @Mock private CurrencyRepository currencyRepository;
        @Mock private CurrencyStockRepository currencyStockRepository;
        @Mock private SystemParameterService systemParameterService;
        @Mock private ClosingToleranceService closingToleranceService;
        @Mock private AuditLogService auditLogService;
        @Spy private ObjectMapper objectMapper = new ObjectMapper();
        @Mock private DenominationAllowedRepository denominationAllowedRepository;
        // FKH-036 WU-5: az új konstruktor-függőségek mockjai (pitfall 1).
        @Mock private ShipmentRequestRepository shipmentRequestRepository;
        @Mock private ShipmentHandlingFeeRepository shipmentHandlingFeeRepository;
    @Mock private VatSupplyStockRepository vatSupplyStockRepository;
        @InjectMocks private ClosingWizardService service;

        private final UUID branchId = UUID.randomUUID();
        private final UUID companyId = UUID.randomUUID();
        private static final Long WORKER_ID = 1L;

        private Branch branch;
        private Worker worker;

        @BeforeEach
        void setUpSecurityContext() {
            branch = Branch.builder()
                    .id(branchId)
                    .code("B01")
                    .name("Teszt Iroda")
                    .company(Company.builder().id(companyId).build())
                    .build();
            worker = Worker.builder()
                    .id(WORKER_ID)
                    .name("Teszt Pénztáros")
                    .company(Company.builder().id(companyId).build())
                    .build();

            WorkerAuthenticationDetails details =
                    new WorkerAuthenticationDetails(WORKER_ID, companyId, branchId, "PENZTAROS");
            TestingAuthenticationToken auth = new TestingAuthenticationToken("t", "x", "ROLE_PENZTAROS");
            auth.setDetails(details);
            SecurityContextHolder.getContext().setAuthentication(auth);
        }

        @AfterEach
        void tearDownSecurityContext() {
            SecurityContextHolder.clearContext();
        }

        @Test
        @DisplayName("FR-1: DAILY wizard indításakor pontosan 9 lépés perzisztálódik, a 16. legacy lépés nélkül")
        void startWizard_daily_persistsExactlyNineSteps() {
            when(branchRepository.findByIdAndCompanyId(branchId, companyId)).thenReturn(Optional.of(branch));
            when(workerRepository.findByIdAndCompanyId(WORKER_ID, companyId)).thenReturn(Optional.of(worker));
            when(closingWizardRepository.findByBranchIdAndStatusAndClosingDate(
                            branchId, WizardStatus.IN_PROGRESS, LocalDate.now()))
                    .thenReturn(Collections.emptyList());
            when(closingWizardRepository.findByBranchIdAndStatus(branchId, WizardStatus.IN_PROGRESS))
                    .thenReturn(Collections.emptyList());
            when(closingWizardRepository.save(any(ClosingWizard.class))).thenAnswer(inv -> {
                ClosingWizard w = inv.getArgument(0);
                if (w.getId() == null) w.setId(UUID.randomUUID());
                return w;
            });

            ClosingWizardDto result = service.startWizard(branchId, null, "DAILY", WORKER_ID);

            // FR-1 acceptance: pontosan 9 perzisztált lépés, 1..9 pozíciókkal
            ArgumentCaptor<ClosingWizard> saved = ArgumentCaptor.forClass(ClosingWizard.class);
            org.mockito.Mockito.verify(closingWizardRepository).save(saved.capture());
            List<ClosingWizardStep> persistedSteps = saved.getValue().getSteps();

            assertThat(persistedSteps).hasSize(9);
            assertThat(persistedSteps.stream().map(ClosingWizardStep::getStepNumber).toList())
                    .containsExactly(1, 2, 3, 4, 5, 6, 7, 8, 9);
            // A 16. legacy lépés semmilyen pozícióban nem perzisztálódhat
            // (a legacy sorszám a stepData JSON-ban utazik metaadatként).
            assertThat(persistedSteps.stream().map(ClosingWizardStep::getStepData).toList())
                    .noneMatch(data -> data != null && data.contains("\"legacyStepNumber\":16"));

            assertThat(result.getTotalSteps()).isEqualTo(9);
            assertThat(result.getSteps()).hasSize(9);
        }
    }
}
