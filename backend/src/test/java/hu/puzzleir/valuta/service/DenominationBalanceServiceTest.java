package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.entity.DenominationBalance;
import hu.puzzleir.valuta.entity.DenominationType;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
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
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class DenominationBalanceServiceTest {

    @Mock private DenominationBalanceRepository balanceRepository;
    @Mock private DenominationRepository denominationRepository;
    @Mock private CashRegisterDeviceRepository cashRegisterDeviceRepository;
    @Mock private BranchRepository branchRepository;

    private DenominationBalanceService service() {
        return new DenominationBalanceService(
                balanceRepository, denominationRepository, cashRegisterDeviceRepository, branchRepository);
    }

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
        when(branchRepository.existsByIdAndCompanyId(cashDeskId, companyId)).thenReturn(false);
        when(cashRegisterDeviceRepository.existsByIdAndCompanyId(cashDeskId, companyId)).thenReturn(true);
        when(balanceRepository.findByCashDeskIdAndDenominationId(cashDeskId, 2L))
                .thenReturn(Optional.of(balance));
        when(balanceRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            service().updateQuantity(cashDeskId, 2L, 1);
        }

        ArgumentCaptor<DenominationBalance> captor = ArgumentCaptor.forClass(DenominationBalance.class);
        verify(balanceRepository).save(captor.capture());
        assertThat(captor.getValue().getSubmissionDate()).isEqualTo(LocalDate.now());
    }

    /**
     * FK-077 FR-2 — a guard gyokerok-javitasa. A denomination_balance.cash_desk_id
     * a gyakorlatban FIOK-UUID (a ClosingWizardService a branchId-t irja bele, es a
     * frontend is azt kuldi). A regi guard KIZAROLAG cash_register_device PK-t fogadott
     * el, ezert minden valos hivast 404-gyel utasitott el → csendes kiurules.
     */
    @Test
    void readAcceptsBranchUuidWithoutCashRegisterDeviceRow() {
        UUID companyId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        when(branchRepository.existsByIdAndCompanyId(branchId, companyId)).thenReturn(true);
        when(balanceRepository.findByCashDeskId(branchId)).thenReturn(List.of());

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            assertThat(service().getCashDeskDenominations(branchId)).isEmpty();
        }

        // A fiok-talalat utan az eszkoz-tabla mar meg sem kerdezodik (rovidzar).
        verify(cashRegisterDeviceRepository, never()).existsByIdAndCompanyId(any(), any());
    }

    /** FK-077 FR-4 regresszio: a penztargep-eszkoz-id tovabbra is ervenyes azonosito. */
    @Test
    void readStillAcceptsCashRegisterDeviceId() {
        UUID companyId = UUID.randomUUID();
        UUID deviceId = UUID.randomUUID();
        when(branchRepository.existsByIdAndCompanyId(deviceId, companyId)).thenReturn(false);
        when(cashRegisterDeviceRepository.existsByIdAndCompanyId(deviceId, companyId)).thenReturn(true);
        when(balanceRepository.findByCashDeskId(deviceId)).thenReturn(List.of());

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            assertThat(service().getCashDeskDenominations(deviceId)).isEmpty();
        }
    }

    /** FK-077: a tenant-izolacio valtozatlanul szoros — mas ceg fiokja/eszkoze 404. */
    @Test
    void crossTenantIdentifierIsStillRejected() {
        UUID companyId = UUID.randomUUID();
        UUID foreignId = UUID.randomUUID();
        when(branchRepository.existsByIdAndCompanyId(foreignId, companyId)).thenReturn(false);
        when(cashRegisterDeviceRepository.existsByIdAndCompanyId(foreignId, companyId)).thenReturn(false);

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            DenominationBalanceService svc = service();
            assertThatThrownBy(() -> svc.getCashDeskDenominations(foreignId))
                    .isInstanceOf(ResourceNotFoundException.class);
        }
        verify(balanceRepository, never()).findByCashDeskId(any());
    }

    /** FK-077: null azonosito 404, a repository-k megkerdezese nelkul. */
    @Test
    void nullIdentifierIsRejected() {
        UUID companyId = UUID.randomUUID();
        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            DenominationBalanceService svc = service();
            assertThatThrownBy(() -> svc.getCashDeskDenominations(null))
                    .isInstanceOf(ResourceNotFoundException.class);
        }
        verify(branchRepository, never()).existsByIdAndCompanyId(any(), any());
        verify(cashRegisterDeviceRepository, never()).existsByIdAndCompanyId(any(), any());
    }
}
