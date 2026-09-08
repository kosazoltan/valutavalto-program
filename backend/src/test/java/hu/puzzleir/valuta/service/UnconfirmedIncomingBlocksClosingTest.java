package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.ClosingWizard;
import hu.puzzleir.valuta.entity.DailySession;
import hu.puzzleir.valuta.entity.DailySessionStatus;
import hu.puzzleir.valuta.entity.DenominationCategory;
import hu.puzzleir.valuta.entity.WizardStatus;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.ClosingWizardRepository;
import hu.puzzleir.valuta.repository.DailySessionRepository;
import hu.puzzleir.valuta.repository.DenominationBalanceRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class UnconfirmedIncomingBlocksClosingTest {

    static final UUID BRANCH_ID = UUID.randomUUID();
    static final UUID COMPANY_ID = UUID.randomUUID();
    static final UUID WIZARD_ID = UUID.randomUUID();
    static final Long WORKER_ID = 7L;
    static final LocalDate DAY = LocalDate.of(2026, 9, 1);

    static void auth() {
        UsernamePasswordAuthenticationToken token =
                new UsernamePasswordAuthenticationToken("CASHIER1", null, List.of());
        token.setDetails(new WorkerAuthenticationDetails(WORKER_ID, COMPANY_ID, BRANCH_ID, "CASHIER"));
        SecurityContextHolder.getContext().setAuthentication(token);
    }

    @Nested
    class WizardEntry {

        @Mock private UnconfirmedIncomingClosingGate unconfirmedIncomingClosingGate;
        @Mock private ClosingWizardRepository closingWizardRepository;
        @Mock private WorkerRepository workerRepository;
        @Mock private BranchRepository branchRepository;
        @Mock private DailyClosingService dailyClosingService;
        @InjectMocks private ClosingWizardService closingWizardService;

        @BeforeEach
        void setUp() {
            auth();
        }

        @AfterEach
        void clear() {
            SecurityContextHolder.clearContext();
        }

        @Test
        @DisplayName("ensureClosingCanBeSent on non-vault: gate throw blocks")
        void ensureClosingCanBeSent_nonVault_blocked() {
            Branch cashier = Branch.builder().id(BRANCH_ID).isVault(false).build();
            when(branchRepository.findByIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(Optional.of(cashier));
            doThrow(new ValidationException("boom"))
                    .when(unconfirmedIncomingClosingGate).ensureNoUnconfirmedIncoming(BRANCH_ID, DAY);

            try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
                su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_ID);
                su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
                su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
                assertThatThrownBy(() -> closingWizardService.ensureClosingCanBeSent(BRANCH_ID, DAY))
                        .isInstanceOf(ValidationException.class)
                        .hasMessageContaining("boom");
            }
            verify(unconfirmedIncomingClosingGate).ensureNoUnconfirmedIncoming(BRANCH_ID, DAY);
            verify(dailyClosingService, never()).startDailyClosing(any());
        }

        @Test
        @DisplayName("ensureClosingCanBeSent on non-vault: gate ok")
        void ensureClosingCanBeSent_nonVault_happy() {
            Branch cashier = Branch.builder().id(BRANCH_ID).isVault(false).build();
            when(branchRepository.findByIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(Optional.of(cashier));

            try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
                su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_ID);
                su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
                su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
                assertThatCode(() -> closingWizardService.ensureClosingCanBeSent(BRANCH_ID, DAY))
                        .doesNotThrowAnyException();
            }
            verify(unconfirmedIncomingClosingGate).ensureNoUnconfirmedIncoming(BRANCH_ID, DAY);
        }

        @Test
        @DisplayName("finalizeClosing: gate throw → startDailyClosing never called")
        void finalizeClosing_blocked() {
            Branch cashier = Branch.builder().id(BRANCH_ID).isVault(false).build();
            ClosingWizard wizard = ClosingWizard.builder()
                    .id(WIZARD_ID)
                    .branch(cashier)
                    .closingDate(DAY)
                    .wizardStatus(WizardStatus.IN_PROGRESS)
                    .steps(List.of())
                    .build();
            when(closingWizardRepository.findByIdWithSteps(WIZARD_ID)).thenReturn(Optional.of(wizard));
            when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(Worker.builder().id(WORKER_ID).build()));
            doThrow(new ValidationException("boom"))
                    .when(unconfirmedIncomingClosingGate).ensureNoUnconfirmedIncoming(BRANCH_ID, DAY);

            try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
                su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_ID);
                su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
                su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
                assertThatThrownBy(() -> closingWizardService.finalizeClosing(WIZARD_ID, WORKER_ID))
                        .isInstanceOf(ValidationException.class)
                        .hasMessageContaining("boom");
            }
            verify(unconfirmedIncomingClosingGate).ensureNoUnconfirmedIncoming(BRANCH_ID, DAY);
            verify(dailyClosingService, never()).startDailyClosing(any());
        }
    }

    @Nested
    class DailyEntry {

        @Mock private UnconfirmedIncomingClosingGate unconfirmedIncomingClosingGate;
        @Mock private DailySessionService dailySessionService;
        @Mock private ClosingWizardRepository closingWizardRepository;
        @InjectMocks private DailyClosingService dailyClosingUnderTest;

        @BeforeEach
        void setUp() {
            auth();
        }

        @AfterEach
        void clear() {
            SecurityContextHolder.clearContext();
        }

        @Test
        @DisplayName("startDailyClosing: gate throw after hasOpenSession → wizard not saved")
        void startDailyClosing_blocked() {
            when(dailySessionService.hasOpenSession()).thenReturn(true);
            doThrow(new ValidationException("boom"))
                    .when(unconfirmedIncomingClosingGate).ensureNoUnconfirmedIncoming(BRANCH_ID, DAY);

            try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
                su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
                su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
                su.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
                assertThatThrownBy(() -> dailyClosingUnderTest.startDailyClosing(DAY))
                        .isInstanceOf(ValidationException.class)
                        .hasMessageContaining("boom");
            }
            verify(unconfirmedIncomingClosingGate).ensureNoUnconfirmedIncoming(BRANCH_ID, DAY);
            verify(closingWizardRepository, never()).save(any());
        }
    }

    @Nested
    class RetroactiveEntry {

        @Mock private UnconfirmedIncomingClosingGate unconfirmedIncomingClosingGate;
        @Mock private DailySessionRepository dailySessionRepository;
        @Mock private DenominationBalanceRepository denominationBalanceRepository;
        @Mock private AccessScopeService accessScopeService;
        @Mock private ClosingToleranceService closingToleranceService;
        @Mock private DailyBalanceService dailyBalanceService;
        @Mock private EveningClosingService eveningClosingService;
        @Mock private ClosingControlService closingControlService;
        @InjectMocks private RetroactiveClosingService retroactiveClosingService;

        @BeforeEach
        void setUp() {
            auth();
        }

        @AfterEach
        void clear() {
            SecurityContextHolder.clearContext();
        }

        @Test
        @DisplayName("closeRetroactively: gate throw → prepareDailyPackage never called")
        void closeRetroactively_blocked() {
            DailySession session = DailySession.builder()
                    .id(1L)
                    .sessionDate(DAY)
                    .status(DailySessionStatus.OPEN)
                    .build();
            when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);
            when(dailySessionRepository.findOpenPastSessionsByBranch(COMPANY_ID, BRANCH_ID, LocalDate.now()))
                    .thenReturn(List.of(session));
            when(dailySessionRepository.findByBranchIdAndSessionDateAndCompanyIdForUpdate(BRANCH_ID, DAY, COMPANY_ID))
                    .thenReturn(Optional.of(session));
            when(denominationBalanceRepository.existsByBranchIdAndDateAndCategory(
                    BRANCH_ID, DAY, DenominationCategory.EVENING)).thenReturn(true);
            doThrow(new ValidationException("boom"))
                    .when(unconfirmedIncomingClosingGate).ensureNoUnconfirmedIncoming(BRANCH_ID, DAY);

            try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
                su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
                su.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
                su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
                assertThatThrownBy(() -> retroactiveClosingService.closeRetroactively(BRANCH_ID, DAY))
                        .isInstanceOf(ValidationException.class);
            }
            verify(eveningClosingService, never()).prepareDailyPackage(any(UUID.class), any());
            verify(eveningClosingService, never()).sendToHeadquarters(any());
        }
    }
}
