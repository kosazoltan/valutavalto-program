package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.repository.SystemParameterRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.core.env.Environment;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SupervisorHandlingFeeOverrideTest {

    private static final UUID COMPANY = UUID.fromString("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa");
    private static final UUID BRANCH = UUID.fromString("11111111-1111-1111-1111-111111111111");

    @Mock private TransactionRepository transactionRepository;
    @Mock private HandlingFeeBalanceService handlingFeeBalanceService;
    @Mock private AuditLogService auditLogService;

    @Test
    void overrideFee_increasesRolledBalanceWhenFeeRaised() {
        Transaction tx = buyTx(new BigDecimal("290"));
        when(transactionRepository.findById(7L)).thenReturn(Optional.of(tx));

        try (MockedStatic<SecurityUtils> security = supervisorSecurity()) {
            service().overrideFee(7L, new BigDecimal("400"), "desk correction");
        }

        verify(handlingFeeBalanceService).increase(BRANCH, COMPANY, new BigDecimal("110"));
        verify(transactionRepository).save(tx);
    }

    @Test
    void overrideFee_decreasesRolledBalanceWhenFeeLowered() {
        Transaction tx = buyTx(new BigDecimal("290"));
        when(transactionRepository.findById(7L)).thenReturn(Optional.of(tx));

        try (MockedStatic<SecurityUtils> security = supervisorSecurity()) {
            service().overrideFee(7L, new BigDecimal("100"), "desk correction");
        }

        // SEC-AUDIT 2026-09-16: a downward override is a CORRECTION of already-booked money,
        // so it must use the clamping settle() and not the refusable decrease() — otherwise an
        // emptied drawer makes the override throw and rolls the whole supervisor action back.
        verify(handlingFeeBalanceService).settle(BRANCH, COMPANY, new BigDecimal("190"));
        verify(handlingFeeBalanceService, never()).decrease(any(), any(), any());
    }

    @Test
    void overrideFee_skipsBalanceWhenNotBuyOrSell() {
        Transaction tx = buyTx(new BigDecimal("290"));
        tx.setTransactionType(TransactionType.TRANSFER_OUT);
        when(transactionRepository.findById(7L)).thenReturn(Optional.of(tx));

        try (MockedStatic<SecurityUtils> security = supervisorSecurity()) {
            service().overrideFee(7L, new BigDecimal("400"), "n/a");
        }

        verifyNoInteractions(handlingFeeBalanceService);
    }

    @Test
    void overrideFee_skipsBalanceWhenAlreadyReversed() {
        Transaction tx = buyTx(new BigDecimal("290"));
        tx.setStatus(TransactionStatus.REVERSED);
        when(transactionRepository.findById(7L)).thenReturn(Optional.of(tx));

        try (MockedStatic<SecurityUtils> security = supervisorSecurity()) {
            service().overrideFee(7L, new BigDecimal("400"), "n/a");
        }

        verifyNoInteractions(handlingFeeBalanceService);
    }

    @Test
    void overrideFee_rejectsWhenNotSupervisor() {
        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::isSupervisorOrAbove).thenReturn(false);
            assertThatThrownBy(() -> service().overrideFee(7L, new BigDecimal("400"), "n/a"))
                    .isInstanceOf(ValidationException.class);
        }
        verify(transactionRepository, never()).findById(7L);
        verifyNoInteractions(handlingFeeBalanceService);
    }

    private SupervisorService service() {
        return new SupervisorService(
                mock(SystemParameterRepository.class),
                transactionRepository,
                mock(ExchangeRateRepository.class),
                auditLogService,
                mock(PasswordEncoder.class),
                mock(Environment.class),
                handlingFeeBalanceService);
    }

    private static MockedStatic<SecurityUtils> supervisorSecurity() {
        MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class);
        security.when(SecurityUtils::isSupervisorOrAbove).thenReturn(true);
        security.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
        security.when(SecurityUtils::getCurrentWorkerCode).thenReturn("SUP1");
        return security;
    }

    private static Transaction buyTx(BigDecimal fee) {
        Company company = new Company();
        company.setId(COMPANY);
        Branch branch = new Branch();
        branch.setId(BRANCH);
        Transaction tx = new Transaction();
        tx.setId(7L);
        tx.setCompany(company);
        tx.setBranch(branch);
        tx.setTransactionType(TransactionType.BUY);
        tx.setStatus(TransactionStatus.COMPLETED);
        tx.setHandlingFee(fee);
        return tx;
    }
}
