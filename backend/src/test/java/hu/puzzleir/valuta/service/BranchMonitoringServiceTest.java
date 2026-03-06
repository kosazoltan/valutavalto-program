package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.monitoring.BranchStatusResponse;
import hu.puzzleir.valuta.entity.BranchStatus;
import hu.puzzleir.valuta.repository.BranchStatusRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * BranchMonitoringService UNIT tesztek — Mockito.
 */
@ExtendWith(MockitoExtension.class)
class BranchMonitoringServiceTest {

    @InjectMocks
    private BranchMonitoringService service;

    @Mock
    private BranchStatusRepository branchStatusRepository;

    private static final UUID BRANCH_ID = UUID.randomUUID();

    private BranchStatus createBranchStatus(UUID branchId, boolean online, LocalDateTime lastHb) {
        return BranchStatus.builder()
                .id(UUID.randomUUID())
                .branchId(branchId)
                .lastHeartbeat(lastHb)
                .isOnline(online)
                .dailyTransactionCount(10)
                .dailyVolumeHuf(new BigDecimal("500000"))
                .openAlerts(0)
                .build();
    }

    @Test
    @DisplayName("updateHeartbeat → lastHeartbeat updated, isOnline = true")
    void testUpdateHeartbeat() {
        BranchStatus existing = createBranchStatus(BRANCH_ID, false, LocalDateTime.now().minusHours(1));
        when(branchStatusRepository.findByBranchId(BRANCH_ID)).thenReturn(Optional.of(existing));
        when(branchStatusRepository.save(any(BranchStatus.class))).thenAnswer(inv -> inv.getArgument(0));

        service.updateHeartbeat(BRANCH_ID);

        ArgumentCaptor<BranchStatus> captor = ArgumentCaptor.forClass(BranchStatus.class);
        verify(branchStatusRepository).save(captor.capture());

        BranchStatus saved = captor.getValue();
        assertThat(saved.getIsOnline()).isTrue();
        assertThat(saved.getLastHeartbeat()).isAfterOrEqualTo(LocalDateTime.now().minusSeconds(5));
    }

    @Test
    @DisplayName("getOnlineBranches → returns online branches")
    void testGetOnlineBranches() {
        UUID branch1 = UUID.randomUUID();
        UUID branch2 = UUID.randomUUID();

        BranchStatus s1 = createBranchStatus(branch1, true, LocalDateTime.now());
        BranchStatus s2 = createBranchStatus(branch2, true, LocalDateTime.now());

        when(branchStatusRepository.findByIsOnlineTrue()).thenReturn(List.of(s1, s2));

        List<BranchStatusResponse> result = service.getOnlineBranches();

        assertThat(result).hasSize(2);
        assertThat(result).allMatch(r -> r.getIsOnline());
    }

    @Test
    @DisplayName("getOfflineBranches → returns branches past threshold")
    void testGetOfflineBranches_threshold() {
        UUID offlineBranch = UUID.randomUUID();
        BranchStatus offline = createBranchStatus(offlineBranch, true, LocalDateTime.now().minusMinutes(30));

        when(branchStatusRepository.findOfflineBranches(any(LocalDateTime.class)))
                .thenReturn(List.of(offline));

        List<BranchStatusResponse> result = service.getOfflineBranches(15);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getBranchId()).isEqualTo(offlineBranch);
        verify(branchStatusRepository).findOfflineBranches(any(LocalDateTime.class));
    }

    @Test
    @DisplayName("updateHeartbeat → new branch creates BranchStatus")
    void testUpdateHeartbeat_newBranch() {
        UUID newBranch = UUID.randomUUID();
        when(branchStatusRepository.findByBranchId(newBranch)).thenReturn(Optional.empty());
        when(branchStatusRepository.save(any(BranchStatus.class))).thenAnswer(inv -> {
            BranchStatus bs = inv.getArgument(0);
            if (bs.getId() == null) bs.setId(UUID.randomUUID());
            return bs;
        });

        service.updateHeartbeat(newBranch);

        ArgumentCaptor<BranchStatus> captor = ArgumentCaptor.forClass(BranchStatus.class);
        verify(branchStatusRepository).save(captor.capture());
        BranchStatus saved = captor.getValue();
        assertThat(saved.getBranchId()).isEqualTo(newBranch);
        assertThat(saved.getIsOnline()).isTrue();
    }
}
