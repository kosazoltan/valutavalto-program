package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.AuditLog;
import hu.puzzleir.valuta.repository.AuditLogRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith({MockitoExtension.class, OutputCaptureExtension.class})
class AuditLogServiceTest {

    private static final String WARN_PREFIX = "AuditLogService companyId feloldás sikertelen";

    @Mock
    private AuditLogRepository auditLogRepository;

    private AuditLogService service;

    @BeforeEach
    void setUp() {
        when(auditLogRepository.findLastEntryHashForUpdate()).thenReturn(Optional.empty());
        service = new AuditLogService(auditLogRepository);
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void log_withoutAuthContextKeepsNullCompanyIdAndDoesNotWarn(CapturedOutput output) {
        service.log("ACTION", "message", "entity-1");

        AuditLog saved = savedAuditLog();
        assertNull(saved.getCompanyId());
        assertFalse(output.toString().contains(WARN_PREFIX));
    }

    @Test
    void log_unexpectedSecurityFailureWarnsButKeepsSchedulerCompatibleNullCompanyId(CapturedOutput output) {
        Authentication auth = mock(Authentication.class);
        when(auth.getDetails()).thenThrow(new IllegalStateException("broken details"));
        SecurityContextHolder.getContext().setAuthentication(auth);

        service.log("ACTION", "message", "entity-1");

        AuditLog saved = savedAuditLog();
        assertNull(saved.getCompanyId());
        String logs = output.toString();
        assertTrue(logs.contains(WARN_PREFIX));
        assertTrue(logs.contains("IllegalStateException"));
        assertTrue(logs.contains("broken details"));
    }

    private AuditLog savedAuditLog() {
        ArgumentCaptor<AuditLog> captor = ArgumentCaptor.forClass(AuditLog.class);
        verify(auditLogRepository).save(captor.capture());
        return captor.getValue();
    }
}
