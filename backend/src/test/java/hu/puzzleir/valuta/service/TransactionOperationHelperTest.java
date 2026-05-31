package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.beans.factory.ObjectProvider;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

/**
 * Audit-finding 2026-05-31 (P1): a sikeres tranzakció könyvelése után KÖTELEZŐ az ügyfél
 * highRiskFlag frissítése. Eddig az AmlService.setHighRiskFlagIfNeeded SEHOL nem hívódott
 * (halott write-oldali AML-kontroll); a flagHighRiskAfterBooking köti be a 3 könyvelő flow-ba.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class TransactionOperationHelperTest {

    @InjectMocks private TransactionOperationHelper helper;

    @Mock private DailySessionService dailySessionService;
    @Mock private AmlService amlService;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private ObjectProvider<CameraTransactionLinker> cameraTransactionLinkerProvider;

    @Test
    @DisplayName("flagHighRiskAfterBooking: a friss éves göngyölttel hívja a setHighRiskFlagIfNeeded-et")
    void flagHighRiskAfterBooking_callsSetWithAnnualTotal() {
        BigDecimal annual = new BigDecimal("4000000");
        when(amlService.getAnnualRollingTotal("CUST1")).thenReturn(annual);

        helper.flagHighRiskAfterBooking("CUST1");

        verify(amlService).getAnnualRollingTotal("CUST1");
        verify(amlService).setHighRiskFlagIfNeeded(eq("CUST1"), eq(annual));
    }

    @Test
    @DisplayName("flagHighRiskAfterBooking: null/üres customerId → nincs AML-hívás (anonim ügyfél)")
    void flagHighRiskAfterBooking_blankCustomer_noCall() {
        helper.flagHighRiskAfterBooking(null);
        helper.flagHighRiskAfterBooking("   ");

        verify(amlService, never()).getAnnualRollingTotal(any());
        verify(amlService, never()).setHighRiskFlagIfNeeded(any(), any());
    }

    @Test
    @DisplayName("Audit P2 #7: performAmlCheck NULL AML-eredménynél → ValidationException (FAIL-CLOSED; VV-AML-004 strukturált log)")
    void performAmlCheck_nullResult_throwsFailClosed() {
        when(amlService.checkTransaction(any(), any(), any(), any(), any())).thenReturn(null);

        ValidationException ex = assertThrows(ValidationException.class,
                () -> helper.performAmlCheck(new BigDecimal("100000"), "C1", "Név", "DOC", "EUR"));
        assertTrue(ex.getMessage().contains("AML"), ex.getMessage());
        // A tranzakciót a dobott kivétel blokkolja (fail-closed); a VV-AML-004 FATAL strukturáltan logolva.
        verify(amlService).checkTransaction(any(), any(), any(), any(), any());
    }
}
