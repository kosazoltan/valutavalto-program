package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.stocksnapshot.BranchSnapshotDto;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * StockSnapshotService.latestLastUpdated pure-helper teszt — körzet lastSyncedAt
 * = a branch-ek lastUpdated maximuma (VV-ELVI frissesség-jelzés).
 */
class StockSnapshotServiceLastSyncedTest {

    private static BranchSnapshotDto branchWith(LocalDateTime lastUpdated) {
        return BranchSnapshotDto.builder().lastUpdated(lastUpdated).build();
    }

    @Test
    @DisplayName("Több branch közül a legkésőbbi lastUpdated-et adja vissza")
    void returnsMax() {
        LocalDateTime t1 = LocalDateTime.of(2026, 5, 20, 8, 0);
        LocalDateTime t2 = LocalDateTime.of(2026, 5, 20, 14, 30);
        LocalDateTime t3 = LocalDateTime.of(2026, 5, 19, 23, 59);

        LocalDateTime result = StockSnapshotService.latestLastUpdated(
                List.of(branchWith(t1), branchWith(t2), branchWith(t3)));

        assertThat(result).isEqualTo(t2);
    }

    @Test
    @DisplayName("A null lastUpdated értékeket figyelmen kívül hagyja")
    void ignoresNulls() {
        LocalDateTime t = LocalDateTime.of(2026, 5, 20, 9, 15);

        LocalDateTime result = StockSnapshotService.latestLastUpdated(
                Arrays.asList(branchWith(null), branchWith(t), branchWith(null)));

        assertThat(result).isEqualTo(t);
    }

    @Test
    @DisplayName("Üres lista / csupa-null / null lista → null (még sosem szinkronizált)")
    void emptyOrAllNull() {
        assertThat(StockSnapshotService.latestLastUpdated(List.of())).isNull();
        assertThat(StockSnapshotService.latestLastUpdated(
                Arrays.asList(branchWith(null), branchWith(null)))).isNull();
        assertThat(StockSnapshotService.latestLastUpdated(null)).isNull();
    }
}
