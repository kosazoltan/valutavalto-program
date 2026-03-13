package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.dto.sync.SyncLogDto;
import hu.puzzleir.valuta.dto.sync.SyncStatusDto;
import hu.puzzleir.valuta.entity.SyncLog;
import hu.puzzleir.valuta.repository.SyncLogRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.*;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * SyncService UNIT tesztek — Mockito.
 */
@ExtendWith(MockitoExtension.class)
class SyncServiceTest {

    @InjectMocks
    private SyncService service;

    @Mock
    private SyncLogRepository syncLogRepository;

    @Mock
    private BranchRepository branchRepository;

    private static final UUID BRANCH_ID = UUID.randomUUID();

    private Branch createBranch() {
        Branch b = new Branch();
        b.setId(BRANCH_ID);
        b.setCode("B01");
        b.setName("Teszt Iroda");
        return b;
    }

    @Test
    @DisplayName("syncRatesDown → COMPLETED status")
    void testSyncRatesDown() {
        Branch branch = createBranch();
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(syncLogRepository.save(any(SyncLog.class))).thenAnswer(inv -> {
            SyncLog s = inv.getArgument(0);
            if (s.getId() == null) s.setId(UUID.randomUUID());
            return s;
        });

        SyncLogDto result = service.syncRatesDown(BRANCH_ID);

        assertThat(result).isNotNull();
        assertThat(result.getStatus()).isEqualTo("COMPLETED");
        assertThat(result.getSyncType()).isEqualTo("RATES");
        assertThat(result.getDirection()).isEqualTo("DOWN");
        assertThat(result.getRecordCount()).isEqualTo(15);
        verify(syncLogRepository, times(2)).save(any(SyncLog.class));
    }

    @Test
    @DisplayName("syncTransactionsUp → COMPLETED status")
    void testSyncTransactionsUp() {
        Branch branch = createBranch();
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(syncLogRepository.save(any(SyncLog.class))).thenAnswer(inv -> {
            SyncLog s = inv.getArgument(0);
            if (s.getId() == null) s.setId(UUID.randomUUID());
            return s;
        });

        SyncLogDto result = service.syncTransactionsUp(BRANCH_ID);

        assertThat(result).isNotNull();
        assertThat(result.getStatus()).isEqualTo("COMPLETED");
        assertThat(result.getSyncType()).isEqualTo("TRANSACTIONS");
        assertThat(result.getDirection()).isEqualTo("UP");
        assertThat(result.getRecordCount()).isEqualTo(50);
    }

    @Test
    @DisplayName("syncAll → COMPLETED status, FULL type")
    void testSyncAll() {
        Branch branch = createBranch();
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(syncLogRepository.save(any(SyncLog.class))).thenAnswer(inv -> {
            SyncLog s = inv.getArgument(0);
            if (s.getId() == null) s.setId(UUID.randomUUID());
            return s;
        });

        SyncLogDto result = service.syncAll(BRANCH_ID);

        assertThat(result).isNotNull();
        assertThat(result.getStatus()).isEqualTo("COMPLETED");
        assertThat(result.getSyncType()).isEqualTo("FULL");
        assertThat(result.getRecordCount()).isEqualTo(90);
    }

    @Test
    @DisplayName("getSyncStatus → returns lastSyncTimes map")
    void testGetSyncStatus() {
        SyncLog rateLog = SyncLog.builder()
                .id(UUID.randomUUID())
                .branch(createBranch())
                .syncType(SyncLog.SyncType.RATES)
                .direction(SyncLog.SyncDirection.DOWN)
                .status(SyncLog.SyncStatus.COMPLETED)
                .startedAt(LocalDateTime.now().minusMinutes(10))
                .completedAt(LocalDateTime.now().minusMinutes(5))
                .recordCount(15)
                .build();

        when(syncLogRepository.findLastCompletedByBranch(BRANCH_ID)).thenReturn(List.of(rateLog));

        SyncStatusDto result = service.getSyncStatus(BRANCH_ID);

        assertThat(result).isNotNull();
        assertThat(result.getBranchId()).isEqualTo(BRANCH_ID);
        assertThat(result.getLastSyncTimes()).containsKey("RATES");
    }
}
