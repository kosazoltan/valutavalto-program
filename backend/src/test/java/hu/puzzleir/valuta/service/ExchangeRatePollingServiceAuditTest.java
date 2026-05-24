package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.repository.ExchangeRateSourceRepository;
import hu.puzzleir.valuta.repository.SystemParameterRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * #PP-20: az automatikus hivatalos árfolyam-frissítés hash-láncolt audit naplózása.
 *
 * <p>Bizonyítja, hogy az {@code updateOfficialRates} minden sikeres frissítésnél
 * append-el egy {@code EXCHANGE_RATE_SYNC} audit eseményt, és hogy az audit hiba
 * NEM blokkolja az árfolyam-frissítést (non-blocking, külön try-catch).</p>
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class ExchangeRatePollingServiceAuditTest {

    @InjectMocks
    private ExchangeRatePollingService service;

    @Mock private ExchangeRateRepository exchangeRateRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private ExchangeRateSourceRepository exchangeRateSourceRepository;
    @Mock private SystemParameterRepository systemParameterRepository;
    @Mock private AuditEventService auditEventService;

    private Currency currency(Long id, String code) {
        return Currency.builder().id(id).code(code).build();
    }

    @Test
    @DisplayName("Sikeres frissítés → EXCHANGE_RATE_SYNC audit esemény valutánként")
    void testUpdateOfficialRates_appendsAuditEvent() {
        Currency eur = currency(1L, "EUR");
        when(currencyRepository.findByCode("EUR")).thenReturn(Optional.of(eur));
        when(exchangeRateRepository.findActiveByCurrencyAndDate(eq(1L), any(LocalDate.class)))
                .thenReturn(List.of(ExchangeRate.builder().build()));

        Map<String, ExchangeRatePollingService.MnbRate> rates = Map.of(
                "EUR", new ExchangeRatePollingService.MnbRate("EUR", new BigDecimal("412.50"), 1));

        int updated = service.updateOfficialRates(rates, "MNB");

        assertThat(updated).isEqualTo(1);

        ArgumentCaptor<AuditEventService.AuditEventRequest> captor =
                ArgumentCaptor.forClass(AuditEventService.AuditEventRequest.class);
        verify(auditEventService, times(1)).appendEvent(captor.capture());

        AuditEventService.AuditEventRequest req = captor.getValue();
        assertThat(req.eventType()).isEqualTo("EXCHANGE_RATE_SYNC");
        assertThat(req.currency()).isEqualTo("EUR");
        assertThat(req.amount()).isEqualByComparingTo(new BigDecimal("412.50"));
        assertThat(req.reason()).contains("MNB");
    }

    @Test
    @DisplayName("ECB fallback forrás az audit reason-ben (Copilot #830 P2)")
    void testUpdateOfficialRates_recordsEcbSource() {
        Currency gbp = currency(3L, "GBP");
        when(currencyRepository.findByCode("GBP")).thenReturn(Optional.of(gbp));
        when(exchangeRateRepository.findActiveByCurrencyAndDate(eq(3L), any(LocalDate.class)))
                .thenReturn(List.of(ExchangeRate.builder().build()));

        Map<String, ExchangeRatePollingService.MnbRate> rates = Map.of(
                "GBP", new ExchangeRatePollingService.MnbRate("GBP", new BigDecimal("478.00"), 1));

        service.updateOfficialRates(rates, "ECB");

        ArgumentCaptor<AuditEventService.AuditEventRequest> captor =
                ArgumentCaptor.forClass(AuditEventService.AuditEventRequest.class);
        verify(auditEventService).appendEvent(captor.capture());
        assertThat(captor.getValue().reason()).contains("ECB");
    }

    @Test
    @DisplayName("Audit hiba NEM blokkolja az árfolyam-frissítést (non-blocking)")
    void testUpdateOfficialRates_auditFailureDoesNotBlock() {
        Currency usd = currency(2L, "USD");
        when(currencyRepository.findByCode("USD")).thenReturn(Optional.of(usd));
        when(exchangeRateRepository.findActiveByCurrencyAndDate(eq(2L), any(LocalDate.class)))
                .thenReturn(List.of(ExchangeRate.builder().build()));
        when(auditEventService.appendEvent(any()))
                .thenThrow(new RuntimeException("audit DB nem elérhető"));

        Map<String, ExchangeRatePollingService.MnbRate> rates = Map.of(
                "USD", new ExchangeRatePollingService.MnbRate("USD", new BigDecimal("365.00"), 1));

        int updated = service.updateOfficialRates(rates, "MNB");

        // Az árfolyam mentése MEGTÖRTÉNT az audit-hiba ellenére
        assertThat(updated).isEqualTo(1);
        verify(exchangeRateRepository, atLeastOnce()).save(any(ExchangeRate.class));
    }

    @Test
    @DisplayName("Ismeretlen valuta → nincs frissítés és nincs audit")
    void testUpdateOfficialRates_unknownCurrency_noAudit() {
        when(currencyRepository.findByCode("XXX")).thenReturn(Optional.empty());

        Map<String, ExchangeRatePollingService.MnbRate> rates = Map.of(
                "XXX", new ExchangeRatePollingService.MnbRate("XXX", new BigDecimal("1.00"), 1));

        int updated = service.updateOfficialRates(rates, "MNB");

        assertThat(updated).isEqualTo(0);
        verify(auditEventService, never()).appendEvent(any());
    }
}
