package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.databind.ObjectMapper;
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
    @InjectMocks private ClosingWizardService service;

    private static final UUID BRANCH_ID = UUID.randomUUID();

    @Test
    @DisplayName("startWizard — mar van aktiv varazslo → hiba")
    void testStartWizard_alreadyActive() {
        Branch branch = Branch.builder().id(BRANCH_ID).build();
        Worker worker = Worker.builder().id(1L).build();
        ClosingWizard existing = ClosingWizard.builder().id(UUID.randomUUID()).build();

        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(workerRepository.findById(1L)).thenReturn(Optional.of(worker));
        when(closingWizardRepository.findByBranchIdAndStatus(eq(BRANCH_ID), any()))
                .thenReturn(List.of(existing));

        assertThatThrownBy(() -> service.startWizard(BRANCH_ID, null, "DAILY", 1L))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("aktív");
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
}
