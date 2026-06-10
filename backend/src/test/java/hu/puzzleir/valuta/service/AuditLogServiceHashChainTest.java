package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.AuditLog;
import hu.puzzleir.valuta.repository.AuditLogRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuditLogServiceHashChainTest {

    private static final String PREVIOUS_HASH = "a".repeat(64);

    @Mock
    private AuditLogRepository auditLogRepository;

    private AuditLogService service;

    @BeforeEach
    void setUp() {
        service = new AuditLogService(auditLogRepository);
        when(auditLogRepository.findLastEntryHashForUpdate()).thenReturn(Optional.of(PREVIOUS_HASH));
    }

    @Test
    @DisplayName("logAction: legacy helper is hash-chained before save")
    void logActionAppliesHashChain() {
        service.logAction("CUSTOMER", UUID.randomUUID(), "UPDATE", "details", 42L);

        AuditLog saved = captureSavedAuditLog();
        assertHashChain(saved);
        assertThat(saved.getEntityType()).isEqualTo("CUSTOMER");
        assertThat(saved.getAction()).isEqualTo("UPDATE");
    }

    @Test
    @DisplayName("logTransactionEvent: legacy helper is hash-chained before save")
    void logTransactionEventAppliesHashChain() {
        service.logTransactionEvent(UUID.randomUUID(), "TRANSACTION_CREATED");

        AuditLog saved = captureSavedAuditLog();
        assertHashChain(saved);
        assertThat(saved.getEntityType()).isEqualTo("TRANSACTION");
        assertThat(saved.getAction()).isEqualTo("TRANSACTION_CREATED");
    }

    @Test
    @DisplayName("logRateChange: legacy helper is hash-chained before save")
    void logRateChangeAppliesHashChain() {
        service.logRateChange("EUR", new BigDecimal("390.00"), new BigDecimal("391.00"), 42L);

        AuditLog saved = captureSavedAuditLog();
        assertHashChain(saved);
        assertThat(saved.getEntityType()).isEqualTo("EXCHANGE_RATE");
        assertThat(saved.getAction()).isEqualTo("RATE_CHANGE");
    }

    @Test
    @DisplayName("logSecurityEvent: legacy helper is hash-chained before save")
    void logSecurityEventAppliesHashChain() {
        service.logSecurityEvent("LOGIN_FAILED", "bad password", "127.0.0.1");

        AuditLog saved = captureSavedAuditLog();
        assertHashChain(saved);
        assertThat(saved.getEntityType()).isEqualTo("SECURITY");
        assertThat(saved.getAction()).isEqualTo("LOGIN_FAILED");
    }

    private AuditLog captureSavedAuditLog() {
        ArgumentCaptor<AuditLog> captor = ArgumentCaptor.forClass(AuditLog.class);
        verify(auditLogRepository).save(captor.capture());
        verify(auditLogRepository, atLeastOnce()).findLastEntryHashForUpdate();
        return captor.getValue();
    }

    private static void assertHashChain(AuditLog saved) {
        assertThat(saved.getPreviousHash()).isEqualTo(PREVIOUS_HASH);
        assertThat(saved.getEntryHash())
                .isNotBlank()
                .hasSize(64)
                .matches("[0-9a-f]{64}");
    }
}
