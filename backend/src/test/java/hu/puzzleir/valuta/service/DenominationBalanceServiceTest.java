package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.entity.DenominationBalance;
import hu.puzzleir.valuta.entity.DenominationType;
import hu.puzzleir.valuta.repository.CashRegisterDeviceRepository;
import hu.puzzleir.valuta.repository.DenominationBalanceRepository;
import hu.puzzleir.valuta.repository.DenominationRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class DenominationBalanceServiceTest {

    @Mock private DenominationBalanceRepository balanceRepository;
    @Mock private DenominationRepository denominationRepository;
    @Mock private CashRegisterDeviceRepository cashRegisterDeviceRepository;

    @Test
    void updateQuantityExplicitlySetsCurrentSubmissionDate() {
        UUID companyId = UUID.randomUUID();
        UUID cashDeskId = UUID.randomUUID();
        Currency huf = Currency.builder().id(1L).code("HUF").build();
        Denomination denomination = Denomination.builder()
                .id(2L)
                .currency(huf)
                .faceValue(new BigDecimal("1000"))
                .denominationType(DenominationType.BANKNOTE)
                .build();
        DenominationBalance balance = DenominationBalance.builder()
                .id(UUID.randomUUID())
                .cashDeskId(cashDeskId)
                .denomination(denomination)
                .quantity(1)
                .totalValue(new BigDecimal("1000"))
                .submissionDate(LocalDate.now().minusDays(1))
                .build();
        when(cashRegisterDeviceRepository.existsByIdAndCompanyId(cashDeskId, companyId)).thenReturn(true);
        when(balanceRepository.findByCashDeskIdAndDenominationId(cashDeskId, 2L))
                .thenReturn(Optional.of(balance));
        when(balanceRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            DenominationBalanceService service = new DenominationBalanceService(
                    balanceRepository, denominationRepository, cashRegisterDeviceRepository);

            service.updateQuantity(cashDeskId, 2L, 1);
        }

        ArgumentCaptor<DenominationBalance> captor = ArgumentCaptor.forClass(DenominationBalance.class);
        verify(balanceRepository).save(captor.capture());
        assertThat(captor.getValue().getSubmissionDate()).isEqualTo(LocalDate.now());
    }
}