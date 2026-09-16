package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.HandlingFeeBalance;
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
import static org.assertj.core.api.Assertions.assertThatCode;

/**
 * SEC-AUDIT 2026-09-16 (FKH-071 follow-up): a reversal of a fee-bearing transaction must
 * never be blocked by the rolled drawer balance.
 *
 * <p>The strict {@code decrease} exists for FR-7 (a KK shipment may not take out more than
 * the drawer holds — user-initiated, refusable). Reversal and a downward supervisor fee
 * override are CORRECTIONS of money already booked elsewhere: the transaction row, the cash
 * balance and the audit trail are written in the same transaction, so a ValidationException
 * here rolls the whole storno back and the cashier cannot reverse at all. The drawer is
 * clamped at zero instead, and the unapplied remainder is logged.</p>
 */
@ExtendWith(MockitoExtension.class)
class HandlingFeeBalanceSettleTest {

    private static final UUID COMPANY = UUID.fromString("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa");
    private static final UUID BRANCH = UUID.fromString("11111111-1111-1111-1111-111111111111");

    @Mock
    private HandlingFeeBalanceRepository repository;

    @InjectMocks
    private HandlingFeeBalanceService service;

    private HandlingFeeBalance stubLocked(BigDecimal balance) {
        HandlingFeeBalance row = HandlingFeeBalance.builder()
                .id(UUID.randomUUID())
                .companyId(COMPANY)
                .branchId(BRANCH)
                .currentBalance(balance)
                .version(0L)
                .build();
        org.mockito.Mockito.when(repository.findByBranchIdAndCompanyIdForUpdate(BRANCH, COMPANY))
                .thenReturn(Optional.of(row));
        return row;
    }

    @Test
    @DisplayName("SEC-001: storno of a fee-bearing tx is not blocked when the drawer was emptied by a KK shipment")
    void settleClampsInsteadOfThrowing() {
        HandlingFeeBalance row = stubLocked(new BigDecimal("100"));

        assertThatCode(() -> service.settle(BRANCH, COMPANY, new BigDecimal("290")))
                .doesNotThrowAnyException();

        assertThat(row.getCurrentBalance()).isEqualByComparingTo("0");
    }

    @Test
    @DisplayName("SEC-001: a settle that fits is applied in full")
    void settleAppliesFullAmountWhenCovered() {
        HandlingFeeBalance row = stubLocked(new BigDecimal("440"));

        service.settle(BRANCH, COMPANY, new BigDecimal("290"));

        assertThat(row.getCurrentBalance()).isEqualByComparingTo("150");
    }

    @Test
    @DisplayName("SEC-001: settle rounds to 5 HUF like every other drawer mutation")
    void settleRoundsToFive() {
        HandlingFeeBalance row = stubLocked(new BigDecimal("300"));

        service.settle(BRANCH, COMPANY, new BigDecimal("297"));

        assertThat(row.getCurrentBalance()).isEqualByComparingTo("5");
    }

    @Test
    @DisplayName("SEC-001: settle with a null or non-positive amount is a no-op and takes no lock")
    void settleIgnoresNonPositive() {
        service.settle(BRANCH, COMPANY, null);
        service.settle(BRANCH, COMPANY, BigDecimal.ZERO);

        org.mockito.Mockito.verify(repository, org.mockito.Mockito.never())
                .findByBranchIdAndCompanyIdForUpdate(BRANCH, COMPANY);
    }
}
