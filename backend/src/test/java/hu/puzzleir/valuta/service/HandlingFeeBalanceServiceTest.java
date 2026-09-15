package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.HandlingFeeBalance;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.HandlingFeeBalanceRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class HandlingFeeBalanceServiceTest {

    private static final UUID COMPANY_A = UUID.fromString("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa");
    private static final UUID COMPANY_B = UUID.fromString("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb");
    private static final UUID BRANCH = UUID.fromString("11111111-1111-1111-1111-111111111111");

    @Mock
    private HandlingFeeBalanceRepository repository;

    @InjectMocks
    private HandlingFeeBalanceService service;

    private HandlingFeeBalance stubLocked(UUID companyId, BigDecimal balance) {
        HandlingFeeBalance row = HandlingFeeBalance.builder()
                .id(UUID.randomUUID())
                .companyId(companyId)
                .branchId(BRANCH)
                .currentBalance(balance)
                .version(0L)
                .build();
        when(repository.findByBranchIdAndCompanyIdForUpdate(BRANCH, companyId))
                .thenReturn(Optional.of(row));
        return row;
    }

    @Test
    @DisplayName("FKH-071 FR-1: BUY/SELL fee increases the rolled balance")
    void increaseAddsRoundedFee() {
        HandlingFeeBalance row = stubLocked(COMPANY_A, BigDecimal.ZERO);
        service.increase(BRANCH, COMPANY_A, new BigDecimal("290"));
        assertThat(row.getCurrentBalance()).isEqualByComparingTo("290");
        verify(repository).insertIfAbsent(COMPANY_A, BRANCH);
        verify(repository).findByBranchIdAndCompanyIdForUpdate(BRANCH, COMPANY_A);
    }

    @Test
    @DisplayName("FKH-071 FR-3: two days accumulate (290 + 150 = 440), no daily reset")
    void twoIncreasesAccumulate() {
        HandlingFeeBalance row = stubLocked(COMPANY_A, BigDecimal.ZERO);
        service.increase(BRANCH, COMPANY_A, new BigDecimal("290"));
        service.increase(BRANCH, COMPANY_A, new BigDecimal("150"));
        assertThat(row.getCurrentBalance()).isEqualByComparingTo("440");
    }

    @Test
    @DisplayName("FKH-071 FR-4: KK create decreases immediately")
    void decreaseSubtracts() {
        HandlingFeeBalance row = stubLocked(COMPANY_A, new BigDecimal("440"));
        service.decrease(BRANCH, COMPANY_A, new BigDecimal("440"));
        assertThat(row.getCurrentBalance()).isEqualByComparingTo("0");
    }

    @Test
    @DisplayName("FKH-071 FR-5: KK cancel restores the decrease")
    void cancelRestoreIsIncrease() {
        HandlingFeeBalance row = stubLocked(COMPANY_A, BigDecimal.ZERO);
        service.increase(BRANCH, COMPANY_A, new BigDecimal("440"));
        assertThat(row.getCurrentBalance()).isEqualByComparingTo("440");
    }

    @Test
    @DisplayName("FKH-071 FR-6: storno decrease reverses a prior fee increase")
    void stornoDecrease() {
        HandlingFeeBalance row = stubLocked(COMPANY_A, new BigDecimal("290"));
        service.decrease(BRANCH, COMPANY_A, new BigDecimal("290"));
        assertThat(row.getCurrentBalance()).isEqualByComparingTo("0");
    }

    @Test
    @DisplayName("FKH-071 FR-7: decrease that would go negative is rejected, balance unchanged")
    void decreaseRejectsNegative() {
        HandlingFeeBalance row = stubLocked(COMPANY_A, new BigDecimal("100"));
        assertThatThrownBy(() -> service.decrease(BRANCH, COMPANY_A, new BigDecimal("150")))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("VV-VALID-009");
        assertThat(row.getCurrentBalance()).isEqualByComparingTo("100");
    }

    @Test
    @DisplayName("FKH-071 NFR-3: mutations are company-scoped")
    void increaseUsesCallerCompanyId() {
        stubLocked(COMPANY_A, BigDecimal.ZERO);
        service.increase(BRANCH, COMPANY_A, new BigDecimal("290"));
        verify(repository).findByBranchIdAndCompanyIdForUpdate(eq(BRANCH), eq(COMPANY_A));
        verify(repository, never()).findByBranchIdAndCompanyIdForUpdate(eq(BRANCH), eq(COMPANY_B));
    }

    @Test
    @DisplayName("FKH-071 NFR-1: increase is rounded to 5 HUF (297 -> 295)")
    void increaseRoundsToFive() {
        HandlingFeeBalance row = stubLocked(COMPANY_A, BigDecimal.ZERO);
        service.increase(BRANCH, COMPANY_A, new BigDecimal("297"));
        assertThat(row.getCurrentBalance()).isEqualByComparingTo("295");
    }

    @Test
    @DisplayName("FKH-071 FR-2: write path takes the pessimistic row lock")
    void increaseUsesPessimisticLock() {
        stubLocked(COMPANY_A, BigDecimal.ZERO);
        service.increase(BRANCH, COMPANY_A, new BigDecimal("100"));
        verify(repository).findByBranchIdAndCompanyIdForUpdate(BRANCH, COMPANY_A);
    }
}
