package hu.puzzleir.valuta.service;

import tools.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.CurrencyAuditLog;
import hu.puzzleir.valuta.exception.BusinessException;
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
import org.springframework.http.HttpStatus;

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
    @Mock
    private CashBalanceService cashBalanceService;
    @InjectMocks
    private AdminCurrencyService service;

    @Test
    @DisplayName("createCurrency: új valuta perzisztálva + audit-bejegyzés CREATE")
    void createCurrency_persistsAndWritesAudit() {
        when(currencyRepository.findByCode("AED")).thenReturn(Optional.empty());
        when(currencyRepository.existsByDisplayOrder(99)).thenReturn(false);
        when(currencyRepository.saveAndFlush(any(Currency.class))).thenAnswer(inv -> {
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

    /**
     * FK04 / FR-7: foglalt display_order → 409 CONFLICT + VV-VALID-003, és NEM jön létre
     * a valuta (se save, se audit). A V318 UNIQUE constraint service-szintű előszűrése.
     */
    @Test
    @DisplayName("FK04 FR-7: duplikált display_order → BusinessException 409 + VV-VALID-003, nincs mentés")
    void createCurrency_duplicateDisplayOrder_rejectedWithVvValid003() {
        when(currencyRepository.findByCode("AED")).thenReturn(Optional.empty());
        when(currencyRepository.existsByDisplayOrder(5)).thenReturn(true);

        assertThatThrownBy(() -> service.createCurrency("AED", "Arab Emirátusi dirham", null, 2, 5))
                .isInstanceOf(BusinessException.class)
                .satisfies(ex -> {
                    BusinessException be = (BusinessException) ex;
                    assertThat(be.getErrorCode()).isEqualTo("VV-VALID-003");
                    assertThat(be.getHttpStatus()).isEqualTo(HttpStatus.CONFLICT);
                });
        org.mockito.Mockito.verify(currencyRepository, org.mockito.Mockito.never()).saveAndFlush(any(Currency.class));
        org.mockito.Mockito.verify(auditRepository, org.mockito.Mockito.never()).save(any(CurrencyAuditLog.class));
    }

    /**
     * Codex PR #1096 P2: konkurens createCurrency — két tranzakció ugyanazt a display_order-t
     * számolja ki, az existsBy előszűrés mindkettőt átengedi, a V318 UNIQUE constraint a
     * saveAndFlush-nál üt. A DataIntegrityViolationException-nek is 409 + VV-VALID-003-má
     * kell fordulnia (nem 500).
     */
    @Test
    @DisplayName("FK04 konkurencia: UNIQUE constraint sérülés a flush-nál → 409 + VV-VALID-003 (nem 500)")
    void createCurrency_concurrentUniqueViolation_mapsTo409() {
        when(currencyRepository.findByCode("AED")).thenReturn(Optional.empty());
        when(currencyRepository.existsByDisplayOrder(5)).thenReturn(false);
        when(currencyRepository.saveAndFlush(any(Currency.class)))
                .thenThrow(new org.springframework.dao.DataIntegrityViolationException("uq_currency_display_order"));

        assertThatThrownBy(() -> service.createCurrency("AED", "Arab Emirátusi dirham", null, 2, 5))
                .isInstanceOf(BusinessException.class)
                .satisfies(ex -> {
                    BusinessException be = (BusinessException) ex;
                    assertThat(be.getErrorCode()).isEqualTo("VV-VALID-003");
                    assertThat(be.getHttpStatus()).isEqualTo(HttpStatus.CONFLICT);
                });
        org.mockito.Mockito.verify(auditRepository, org.mockito.Mockito.never()).save(any(CurrencyAuditLog.class));
    }

    /**
     * FK04: hiányzó display_order → max+1 (a korábbi fix 99 default a UNIQUE constraint
     * mellett a második sorrend-nélküli felvételnél ütközne).
     */
    @Test
    @DisplayName("FK04: null display_order → max(displayOrder)+1 kiosztás")
    void createCurrency_nullDisplayOrder_usesMaxPlusOne() {
        when(currencyRepository.findByCode("AED")).thenReturn(Optional.empty());
        when(currencyRepository.findMaxDisplayOrder()).thenReturn(22);
        when(currencyRepository.existsByDisplayOrder(23)).thenReturn(false);
        when(currencyRepository.saveAndFlush(any(Currency.class))).thenAnswer(inv -> inv.getArgument(0));

        Currency saved = service.createCurrency("AED", "Arab Emirátusi dirham", null, 2, null);

        assertThat(saved.getDisplayOrder()).isEqualTo(23);
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

    // =================================================================
    // FK-074 (2026-08-06): valuta-aktiválás → automatikus cash_balance
    // inicializálás wiring-tesztjei (FR-3/FR-4/FR-5 + NFR-4)
    // =================================================================

    @Test
    @DisplayName("FK-074 FR-3: inaktív→aktív váltás PONTOSAN EGYSZER inicializálja a cash_balance-okat")
    void setActive_activation_initializesCashBalancesExactlyOnce() {
        Currency c = Currency.builder().id(11L).code("USD").name("Amerikai dollár").active(false).build();
        when(currencyRepository.findById(11L)).thenReturn(Optional.of(c));
        when(currencyRepository.save(any(Currency.class))).thenAnswer(inv -> inv.getArgument(0));
        when(cashBalanceService.initializeCurrencyBalancesForActiveBranches(any(Currency.class))).thenReturn(3);

        Currency result = service.setActive(11L, true, "FK-074 aktiválás");

        assertThat(result.getActive()).isTrue();
        ArgumentCaptor<Currency> initCaptor = ArgumentCaptor.forClass(Currency.class);
        org.mockito.Mockito.verify(cashBalanceService, org.mockito.Mockito.times(1))
                .initializeCurrencyBalancesForActiveBranches(initCaptor.capture());
        assertThat(initCaptor.getValue().getId()).isEqualTo(11L);
        assertThat(initCaptor.getValue().getActive())
                .as("az inicializálás a már AKTÍVRA állított valutát kapja")
                .isTrue();
    }

    @Test
    @DisplayName("FK-074 FR-4: deaktiválás SOHA nem inicializál (meglévő sorok érintetlenek)")
    void setActive_deactivation_neverInitializes() {
        Currency c = Currency.builder().id(12L).code("DKK").name("Dán Korona").active(true).build();
        when(currencyRepository.findById(12L)).thenReturn(Optional.of(c));
        when(currencyRepository.save(any(Currency.class))).thenAnswer(inv -> inv.getArgument(0));

        Currency result = service.setActive(12L, false, "FK-074 deaktiválás");

        assertThat(result.getActive()).isFalse();
        org.mockito.Mockito.verifyNoInteractions(cashBalanceService);
    }

    @Test
    @DisplayName("FK-074 FR-5: már aktív valuta 'aktiválása' no-op — nincs inicializálás, nincs mentés")
    void setActive_alreadyActive_noOpNeverInitializes() {
        Currency c = Currency.builder().id(13L).code("EUR").name("Euró").active(true).build();
        when(currencyRepository.findById(13L)).thenReturn(Optional.of(c));

        Currency result = service.setActive(13L, true, null);

        assertThat(result.getActive()).isTrue();
        org.mockito.Mockito.verify(currencyRepository, org.mockito.Mockito.never()).save(any(Currency.class));
        org.mockito.Mockito.verifyNoInteractions(cashBalanceService);
    }

    @Test
    @DisplayName("FK-074 NFR-4: az inicializálás hibája kivételként TERJED (a @Transactional az aktiválást visszagörgeti)")
    void setActive_initializationFailure_propagates() {
        Currency c = Currency.builder().id(14L).code("GBP").name("Angol font").active(false).build();
        when(currencyRepository.findById(14L)).thenReturn(Optional.of(c));
        when(currencyRepository.save(any(Currency.class))).thenAnswer(inv -> inv.getArgument(0));
        when(cashBalanceService.initializeCurrencyBalancesForActiveBranches(any(Currency.class)))
                .thenThrow(new IllegalStateException("cash_balance insert meghiusult"));

        assertThatThrownBy(() -> service.setActive(14L, true, "FK-074 hiba-teszt"))
                .as("az inicializálás hibájának a setActive hívóhoz kell terjednie — "
                        + "a @Transactional (rollbackFor) így az egész aktiválást visszagörgeti")
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("cash_balance");
        // Az audit az írásáig eljutott (a writeAudit a hiba ELŐTT fut) — a rollback a
        // tranzakció-interceptor feladata, amit a propagált kivétel vált ki (NFR-4).
        org.mockito.Mockito.verify(auditRepository).save(any(CurrencyAuditLog.class));
        org.mockito.Mockito.verify(cashBalanceService).initializeCurrencyBalancesForActiveBranches(any(Currency.class));
    }
}
