package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.exception.ErrorResponse;
import hu.puzzleir.valuta.mapper.CashBalanceMapper;
import hu.puzzleir.valuta.service.AccessScopeService;
import hu.puzzleir.valuta.service.CashBalanceService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * FK-075 (2026-08-06): „Kassza / készlet" oldal redesign — backend viselkedés tesztek.
 *
 * <ul>
 *   <li>FR-1: a POST /cash-balances/adjust (kézi Bevét/Kivét) LETILTVA → 410 Gone,
 *       a service-réteg (adjustBalance) SOHA nem hívódik.</li>
 *   <li>FR-5/FR-6: az új GET /cash-balances/today-stats delegál a service-hez és
 *       200-zal adja vissza az élő, tranzakció-alapú összesítést.</li>
 * </ul>
 */
class CashBalanceControllerFk075Test {

    private final CashBalanceService cashBalanceService = mock(CashBalanceService.class);
    private final CashBalanceController controller = new CashBalanceController(
            cashBalanceService,
            new CashBalanceMapper(),
            mock(AccessScopeService.class));

    @Test
    @DisplayName("FR-1: POST /cash-balances/adjust → 410 Gone, service NEM hívódik")
    void adjustBalanceReturnsGoneAndDoesNotTouchService() {
        ResponseEntity<ErrorResponse> response = controller.adjustBalance();

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.GONE);
        ErrorResponse body = response.getBody();
        assertThat(body).isNotNull();
        assertThat(body.getStatus()).isEqualTo(HttpStatus.GONE.value());
        assertThat(body.getError()).isEqualTo("Gone");
        assertThat(body.getMessage()).contains("FK-075");
        // A kézi könyvelés service-metódusa nem hívódhat — a végpont HTTP-szinten halott.
        verify(cashBalanceService, never()).adjustBalance(org.mockito.ArgumentMatchers.any());
        verifyNoInteractions(cashBalanceService);
    }

    @Test
    @DisplayName("FR-5/FR-6: GET /cash-balances/today-stats → 200, service-delegáció")
    void getTodayStatsDelegatesToService() {
        CashBalanceService.TodayStats stats = CashBalanceService.TodayStats.builder()
                .transactions(7)
                .buyTotal(new BigDecimal("150000"))
                .sellTotal(new BigDecimal("90000"))
                .handlingFee(new BigDecimal("2500"))
                .build();
        when(cashBalanceService.getTodayStats()).thenReturn(stats);

        ResponseEntity<CashBalanceService.TodayStats> response = controller.getTodayStats();

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        CashBalanceService.TodayStats body = response.getBody();
        assertThat(body).isNotNull();
        assertThat(body.getTransactions()).isEqualTo(7);
        assertThat(body.getBuyTotal()).isEqualByComparingTo("150000");
        assertThat(body.getSellTotal()).isEqualByComparingTo("90000");
        assertThat(body.getHandlingFee()).isEqualByComparingTo("2500");
        verify(cashBalanceService).getTodayStats();
    }
}
