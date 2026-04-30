package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.WorkerBranchAccess;
import hu.puzzleir.valuta.entity.WorkerBranchAccess.WorkerBranchAccessId;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.WorkerBranchAccessRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * v2.4.0 (B6 audit fix) — Tests for {@link WorkerBranchAccessService}.
 *
 * Cel:
 * 1. hasAccess() boolean lookup mukodik
 * 2. hasAccess() defenzív null-handling
 * 3. requireAccess() fail-loud ha denied
 * 4. grantAccess() idempotent (NEM duplicate ha mar exists)
 * 5. grantAccess() audit-fields populálva (grantedAt, grantedByWorkerId)
 * 6. revokeAccess() fail-loud ha NEM exists
 * 7. revokeAccess() success ha exists
 * 8. listBranches() / listWorkers() forwards to repo
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("WorkerBranchAccessService — B6 multi-branch worker access")
class WorkerBranchAccessServiceTest {

    @Mock
    private WorkerBranchAccessRepository repo;

    @InjectMocks
    private WorkerBranchAccessService service;

    private static final Long WORKER_ID = 42L;
    private static final UUID BRANCH_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID OTHER_BRANCH_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");
    private static final Long ADMIN_ID = 99L;

    @Test
    @DisplayName("hasAccess() true ha rekord exists")
    void hasAccess_returnsTrueWhenAccessGranted() {
        when(repo.existsByWorkerIdAndBranchId(WORKER_ID, BRANCH_ID)).thenReturn(true);

        boolean result = service.hasAccess(WORKER_ID, BRANCH_ID);

        assertThat(result).isTrue();
    }

    @Test
    @DisplayName("hasAccess() false ha rekord NEM exists (default deny)")
    void hasAccess_returnsFalseWhenNoRecord() {
        when(repo.existsByWorkerIdAndBranchId(WORKER_ID, BRANCH_ID)).thenReturn(false);

        boolean result = service.hasAccess(WORKER_ID, BRANCH_ID);

        assertThat(result).isFalse();
    }

    @Test
    @DisplayName("hasAccess() defenzív: null-input -> false (NEM throws)")
    void hasAccess_defensiveNullInput() {
        assertThat(service.hasAccess(null, BRANCH_ID)).isFalse();
        assertThat(service.hasAccess(WORKER_ID, null)).isFalse();
        assertThat(service.hasAccess(null, null)).isFalse();
        verify(repo, never()).existsByWorkerIdAndBranchId(any(), any());
    }

    @Test
    @DisplayName("requireAccess() fail-loud ValidationException ha denied")
    void requireAccess_failsLoudWhenDenied() {
        when(repo.existsByWorkerIdAndBranchId(WORKER_ID, BRANCH_ID)).thenReturn(false);

        assertThatThrownBy(() -> service.requireAccess(WORKER_ID, BRANCH_ID))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("no access to branch");
    }

    @Test
    @DisplayName("requireAccess() success ha granted (NEM throws)")
    void requireAccess_successWhenGranted() {
        when(repo.existsByWorkerIdAndBranchId(WORKER_ID, BRANCH_ID)).thenReturn(true);

        // Should NOT throw
        service.requireAccess(WORKER_ID, BRANCH_ID);
    }

    @Test
    @DisplayName("grantAccess() create new record audit-fields-szel")
    void grantAccess_createsNewRecordWithAuditFields() {
        when(repo.findById(any(WorkerBranchAccessId.class))).thenReturn(Optional.empty());
        ArgumentCaptor<WorkerBranchAccess> captor = ArgumentCaptor.forClass(WorkerBranchAccess.class);
        when(repo.save(captor.capture())).thenAnswer(inv -> inv.getArgument(0));

        WorkerBranchAccess result = service.grantAccess(WORKER_ID, BRANCH_ID, ADMIN_ID);

        WorkerBranchAccess saved = captor.getValue();
        assertThat(saved.getWorkerId()).isEqualTo(WORKER_ID);
        assertThat(saved.getBranchId()).isEqualTo(BRANCH_ID);
        assertThat(saved.getGrantedByWorkerId()).isEqualTo(ADMIN_ID);
        assertThat(saved.getGrantedAt()).isNotNull();
    }

    @Test
    @DisplayName("grantAccess() idempotent: létező grant nem duplicate-re save")
    void grantAccess_idempotentNoDuplicate() {
        WorkerBranchAccess existing = WorkerBranchAccess.builder()
                .workerId(WORKER_ID)
                .branchId(BRANCH_ID)
                .grantedAt(LocalDateTime.now().minusDays(7))
                .grantedByWorkerId(ADMIN_ID)
                .build();
        when(repo.findById(any(WorkerBranchAccessId.class))).thenReturn(Optional.of(existing));

        WorkerBranchAccess result = service.grantAccess(WORKER_ID, BRANCH_ID, ADMIN_ID);

        assertThat(result).isSameAs(existing);
        verify(repo, never()).save(any());
    }

    @Test
    @DisplayName("grantAccess() validation: workerId/branchId required")
    void grantAccess_validatesNullInputs() {
        assertThatThrownBy(() -> service.grantAccess(null, BRANCH_ID, ADMIN_ID))
                .isInstanceOf(ValidationException.class);
        assertThatThrownBy(() -> service.grantAccess(WORKER_ID, null, ADMIN_ID))
                .isInstanceOf(ValidationException.class);
    }

    @Test
    @DisplayName("revokeAccess() fail-loud ValidationException ha NEM exists")
    void revokeAccess_failsLoudWhenNotExists() {
        when(repo.existsById(any(WorkerBranchAccessId.class))).thenReturn(false);

        assertThatThrownBy(() -> service.revokeAccess(WORKER_ID, BRANCH_ID))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("No branch access record");

        verify(repo, never()).deleteById(any());
    }

    @Test
    @DisplayName("revokeAccess() success ha exists")
    void revokeAccess_successWhenExists() {
        when(repo.existsById(any(WorkerBranchAccessId.class))).thenReturn(true);

        service.revokeAccess(WORKER_ID, BRANCH_ID);

        verify(repo, times(1)).deleteById(any(WorkerBranchAccessId.class));
    }

    @Test
    @DisplayName("listBranches() forwards to repo with worker.id ordering")
    void listBranches_forwardsToRepo() {
        WorkerBranchAccess a = WorkerBranchAccess.builder()
                .workerId(WORKER_ID).branchId(BRANCH_ID).build();
        WorkerBranchAccess b = WorkerBranchAccess.builder()
                .workerId(WORKER_ID).branchId(OTHER_BRANCH_ID).build();
        when(repo.findAllByWorkerIdOrderByGrantedAtAsc(WORKER_ID))
                .thenReturn(List.of(a, b));

        List<WorkerBranchAccess> result = service.listBranches(WORKER_ID);

        assertThat(result).hasSize(2);
        assertThat(result).extracting(WorkerBranchAccess::getBranchId)
                .containsExactly(BRANCH_ID, OTHER_BRANCH_ID);
    }

    @Test
    @DisplayName("listWorkers() forwards to repo with branch.id ordering")
    void listWorkers_forwardsToRepo() {
        WorkerBranchAccess a = WorkerBranchAccess.builder()
                .workerId(WORKER_ID).branchId(BRANCH_ID).build();
        when(repo.findAllByBranchIdOrderByGrantedAtAsc(BRANCH_ID))
                .thenReturn(List.of(a));

        List<WorkerBranchAccess> result = service.listWorkers(BRANCH_ID);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getWorkerId()).isEqualTo(WORKER_ID);
    }
}
