package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.CurrencyAuditLog;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CurrencyAuditLogRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;

import java.lang.reflect.Field;
import java.time.LocalDateTime;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

/**
 * AdminCurrencyService teszt — V238 currency admin + a 2026-05-21 POST 500 regresszió-guard.
 */
@ExtendWith(MockitoExtension.class)
class AdminCurrencyServiceTest {

    @Mock
    private CurrencyRepository currencyRepository;
    @Mock
    private CurrencyAuditLogRepository auditRepository;
    @Spy
    private ObjectMapper objectMapper = new ObjectMapper();
    @InjectMocks
    private AdminCurrencyService service;

    @Test
    @DisplayName("createCurrency: új valuta perzisztálva + audit-bejegyzés CREATE")
    void createCurrency_persistsAndWritesAudit() {
        when(currencyRepository.findByCode("AED")).thenReturn(Optional.empty());
        when(currencyRepository.save(any(Currency.class))).thenAnswer(inv -> {
            Currency c = inv.getArgument(0);
            c.setId(42L);
            return c;
        });

        Currency saved = service.createCurrency("aed", "Arab Emirátusi dirham", null, 2, 99);

        assertThat(saved.getCode()).isEqualTo("AED");
        assertThat(saved.getActive()).isTrue();
        ArgumentCaptor<CurrencyAuditLog> auditCaptor = ArgumentCaptor.forClass(CurrencyAuditLog.class);
        org.mockito.Mockito.verify(auditRepository).save(auditCaptor.capture());
        assertThat(auditCaptor.getValue().getAction()).isEqualTo("CREATE");
        assertThat(auditCaptor.getValue().getCurrencyCode()).isEqualTo("AED");
    }

    @Test
    @DisplayName("createCurrency: létező kód → ValidationException (NEM duplikálható)")
    void createCurrency_duplicate_throws() {
        when(currencyRepository.findByCode("AED")).thenReturn(Optional.of(Currency.builder().code("AED").build()));
        assertThatThrownBy(() -> service.createCurrency("AED", "x", null, 2, 99))
                .isInstanceOf(ValidationException.class);
    }

    @Test
    @DisplayName("setActive: állapotváltás + audit DEACTIVATE")
    void setActive_togglesAndWritesAudit() {
        Currency c = Currency.builder().id(7L).code("DKK").name("Dán Korona").active(true).build();
        when(currencyRepository.findById(7L)).thenReturn(Optional.of(c));
        when(currencyRepository.save(any(Currency.class))).thenAnswer(inv -> inv.getArgument(0));

        Currency result = service.setActive(7L, false, "teszt deaktiválás");

        assertThat(result.getActive()).isFalse();
        ArgumentCaptor<CurrencyAuditLog> auditCaptor = ArgumentCaptor.forClass(CurrencyAuditLog.class);
        org.mockito.Mockito.verify(auditRepository).save(auditCaptor.capture());
        assertThat(auditCaptor.getValue().getAction()).isEqualTo("DEACTIVATE");
    }

    @Test
    @DisplayName("setActive: ismeretlen id → ResourceNotFoundException")
    void setActive_notFound_throws() {
        when(currencyRepository.findById(999L)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.setActive(999L, false, null))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    /**
     * REGRESSZIÓ-GUARD (2026-05-21 POST /currencies 500): a createdAt mező típusa
     * LocalDateTime kell legyen (NEM OffsetDateTime). A @EnableJpaAuditing default
     * DateTimeProvider-e LocalDateTime-ot ad; OffsetDateTime mezővel az audit save
     * "Cannot convert LocalDateTime to OffsetDateTime"-mal dobott, ami rollback-only-ra
     * állította a @Transactional-t → a currency-művelet 500-azott.
     */
    @Test
    @DisplayName("REGRESSZIÓ: CurrencyAuditLog.createdAt típusa LocalDateTime (timestamp-konvenció)")
    void currencyAuditLogCreatedAt_isLocalDateTime() throws NoSuchFieldException {
        Field createdAt = CurrencyAuditLog.class.getDeclaredField("createdAt");
        assertThat(createdAt.getType())
                .as("CurrencyAuditLog.createdAt-nak LocalDateTime-nak kell lennie (timestamptz/OffsetDateTime tiltott — 500-bug)")
                .isEqualTo(LocalDateTime.class);
    }
}
