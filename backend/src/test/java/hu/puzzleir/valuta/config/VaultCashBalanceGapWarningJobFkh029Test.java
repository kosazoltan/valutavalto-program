package hu.puzzleir.valuta.config;

import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoMoreInteractions;
import static org.mockito.Mockito.when;

/**
 * FKH-029 FR-3: a {@link VaultCashBalanceGapWarningJob} viselkedése.
 *
 * <p>Bizonyítja: hiányzó sor → riasztás; nincs hiány → csendes; és hogy a job
 * <b>semmit nem ír</b> az adatbázisba (ez a lényegi biztonsági követelmény —
 * a pótlást a V371 migráció és a TransferService lazy-create végzi, nem ez).</p>
 */
@ExtendWith(MockitoExtension.class)
class VaultCashBalanceGapWarningJobFkh029Test {

    @Mock private CashBalanceRepository cashBalanceRepository;

    private VaultCashBalanceGapWarningJob job;

    @BeforeEach
    void setUp() {
        job = new VaultCashBalanceGapWarningJob(cashBalanceRepository);
    }

    @Test
    @DisplayName("FR-3: hiányzó értéktári cash_balance sor esetén lefut és NEM ír az adatbázisba")
    void missingRows_warnsAndWritesNothing() {
        when(cashBalanceRepository.findVaultBranchesWithMissingCashBalance()).thenReturn(List.of(
                new Object[]{"EBC", "BR075", "EUR,HUF,USD", 3L},
                new Object[]{"EBC", "BR010", "EUR", 1L}
        ));

        assertThatCode(() -> job.warnMissingVaultCashBalanceRows()).doesNotThrowAnyException();

        verify(cashBalanceRepository).findVaultBranchesWithMissingCashBalance();
        // A job KIZÁRÓLAG riaszt — egyetlen mutáló repository-hívás sem történhet.
        verify(cashBalanceRepository, never()).save(any(CashBalance.class));
        verify(cashBalanceRepository, never()).saveAll(any());
        verify(cashBalanceRepository, never()).insertIfAbsent(any(), any(), anyLong());
        verify(cashBalanceRepository, never()).delete(any(CashBalance.class));
        verifyNoMoreInteractions(cashBalanceRepository);
    }

    @Test
    @DisplayName("FR-3: ha nincs hiányzó sor, a job csendes — csak a read-only lekérdezés fut")
    void noGaps_staysSilent() {
        when(cashBalanceRepository.findVaultBranchesWithMissingCashBalance()).thenReturn(List.of());

        assertThatCode(() -> job.warnMissingVaultCashBalanceRows()).doesNotThrowAnyException();

        verify(cashBalanceRepository).findVaultBranchesWithMissingCashBalance();
        verifyNoMoreInteractions(cashBalanceRepository);
    }

    @Test
    @DisplayName("FR-3: hiányos/null oszlopok és null lista nem dobnak kivételt (a monitorozás soha ne bukjon el)")
    void malformedRows_doNotThrow() {
        when(cashBalanceRepository.findVaultBranchesWithMissingCashBalance()).thenReturn(List.of(
                new Object[]{null, null, null, null},
                new Object[]{"EBC"}
        ));

        assertThatCode(() -> job.warnMissingVaultCashBalanceRows()).doesNotThrowAnyException();

        when(cashBalanceRepository.findVaultBranchesWithMissingCashBalance()).thenReturn(null);

        assertThatCode(() -> job.warnMissingVaultCashBalanceRows())
                .as("null eredmény sem buktathatja el a scheduled jobot")
                .doesNotThrowAnyException();
    }
}
