package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.central.TransferReconciliationResultDto;
import hu.puzzleir.valuta.dto.central.TransferReconciliationRowDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Transfer;
import hu.puzzleir.valuta.entity.TransferLine;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.TransferRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

/**
 * FK-003 egyeztetési modul UNIT tesztjei (Mockito).
 */
@ExtendWith(MockitoExtension.class)
class TransferReconciliationServiceTest {

    @Mock private TransferRepository transferRepository;
    @Mock private NotificationService notificationService;
    @InjectMocks private TransferReconciliationService service;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID VAULT_BRANCH_ID = UUID.randomUUID();
    private static final LocalDate D = LocalDate.of(2026, 5, 22);

    private static Currency currency(String code) {
        Currency c = new Currency();
        c.setCode(code);
        return c;
    }

    private static Branch branch(UUID id, String code, boolean isVault) {
        return Branch.builder().id(id).code(code).name(code + " név").isVault(isVault).build();
    }

    private static Transfer.TransferBuilder baseTransfer(String number, Transfer.TransferStatus status) {
        return Transfer.builder()
                .id(1L)
                .transferNumber(number)
                .fromBranch(branch(UUID.randomUUID(), "BR009", false))
                .toBranch(branch(VAULT_BRANCH_ID, "BR020", true))
                .currency(currency("EUR"))
                .transferDate(D)
                .status(status);
    }

    @Test
    @DisplayName("EGYEZIK — fogadott == küldött, fogadó megerősítette (COMPLETED), nincs értesítés")
    void testMatch() {
        Transfer t = baseTransfer("AT0001", Transfer.TransferStatus.COMPLETED)
                .amount(new BigDecimal("5000"))
                .receivedAmount(new BigDecimal("5000.0000"))
                .build();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(transferRepository.findForReconciliation(COMPANY_ID, D, D)).thenReturn(List.of(t));

            TransferReconciliationResultDto result = service.reconcile(D, D);

            assertThat(result.getTotalRows()).isEqualTo(1);
            assertThat(result.getMatchedRows()).isEqualTo(1);
            assertThat(result.getDiscrepancyRows()).isZero();
            assertThat(result.getRows().get(0).getStatus()).isEqualTo(TransferReconciliationService.STATUS_MATCH);
            verifyNoInteractions(notificationService);
        }
    }

    @Test
    @DisplayName("ELTÉRÉS — eltérő összeg (COMPLETED, received != sent) → értéktár értesítve")
    void testAmountMismatch() {
        Transfer t = baseTransfer("AT0002", Transfer.TransferStatus.COMPLETED)
                .amount(new BigDecimal("5000"))
                .receivedAmount(new BigDecimal("4900"))
                .build();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(transferRepository.findForReconciliation(COMPANY_ID, D, D)).thenReturn(List.of(t));
            when(notificationService.notifyBranchOnce(eq(VAULT_BRANCH_ID), any(), any(), any(), any(), eq("AT0002"), any()))
                    .thenReturn(true);

            TransferReconciliationResultDto result = service.reconcile(D, D);

            assertThat(result.getDiscrepancyRows()).isEqualTo(1);
            assertThat(result.getMatchedRows()).isZero();
            assertThat(result.getNotifiedBranches()).isEqualTo(1);
            TransferReconciliationRowDto row = result.getRows().get(0);
            assertThat(row.getStatus()).isEqualTo(TransferReconciliationService.STATUS_MISMATCH);
            assertThat(row.getDiscrepancyNote()).contains("Eltérő összeg");
            // az értéktár (toBranch.isVault=true) kapja az értesítést, idempotens kulcs = transferNumber
            verify(notificationService).notifyBranchOnce(eq(VAULT_BRANCH_ID), any(), any(), any(),
                    eq("TransferReconciliation"), eq("AT0002"), eq("TRANSFER_DISCREPANCY"));
        }
    }

    @Test
    @DisplayName("ELTÉRÉS — a fogadó még nem erősítette meg (PENDING) → 'Hiányzó bejegyzés a fogadó oldalon'")
    void testMissingReceiver() {
        Transfer t = baseTransfer("AT0003", Transfer.TransferStatus.PENDING)
                .amount(new BigDecimal("3000"))
                .receivedAmount(null)
                .build();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(transferRepository.findForReconciliation(COMPANY_ID, D, D)).thenReturn(List.of(t));
            when(notificationService.notifyBranchOnce(any(), any(), any(), any(), any(), any(), any()))
                    .thenReturn(true);

            TransferReconciliationResultDto result = service.reconcile(D, D);

            assertThat(result.getDiscrepancyRows()).isEqualTo(1);
            assertThat(result.getRows().get(0).getStatus()).isEqualTo(TransferReconciliationService.STATUS_MISMATCH);
            assertThat(result.getRows().get(0).getDiscrepancyNote()).contains("Hiányzó bejegyzés");
        }
    }

    @Test
    @DisplayName("Több-valutás átadólap — soronkénti egyeztetés (egy egyezik, egy eltér), 1 értesítés")
    void testMultiCurrencyLines() {
        Transfer t = baseTransfer("AT0004", Transfer.TransferStatus.RECEIVED).build();
        TransferLine ok = TransferLine.builder().currency(currency("USD"))
                .amount(new BigDecimal("1000")).receivedAmount(new BigDecimal("1000")).build();
        TransferLine bad = TransferLine.builder().currency(currency("GBP"))
                .amount(new BigDecimal("2000")).receivedAmount(new BigDecimal("1950")).build();
        t.setLines(List.of(ok, bad));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(transferRepository.findForReconciliation(COMPANY_ID, D, D)).thenReturn(List.of(t));
            when(notificationService.notifyBranchOnce(any(), any(), any(), any(), any(), any(), any()))
                    .thenReturn(true);

            TransferReconciliationResultDto result = service.reconcile(D, D);

            assertThat(result.getTotalRows()).isEqualTo(2);
            assertThat(result.getMatchedRows()).isEqualTo(1);
            assertThat(result.getDiscrepancyRows()).isEqualTo(1);
            assertThat(result.getNotifiedBranches()).isEqualTo(1);
            verify(notificationService, times(1)).notifyBranchOnce(any(), any(), any(), any(), any(), any(), any());
        }
    }

    @Test
    @DisplayName("Validáció — hiányzó dátum / fordított intervallum → ValidationException")
    void testValidation() {
        assertThatThrownBy(() -> service.reconcile(null, D)).isInstanceOf(ValidationException.class);
        assertThatThrownBy(() -> service.reconcile(D, D.minusDays(1))).isInstanceOf(ValidationException.class);
        verifyNoInteractions(transferRepository);
    }
}
