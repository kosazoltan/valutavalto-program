package hu.puzzleir.valuta.service;

import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import hu.puzzleir.valuta.entity.AuditLog;
import hu.puzzleir.valuta.repository.AuditLogRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuditLogServiceTest {

    private static final String WARN_PREFIX = "AuditLogService companyId feloldás sikertelen";

    @Mock
    private AuditLogRepository auditLogRepository;

    private AuditLogService service;
    private Logger auditLogLogger;
    private Level previousLogLevel;
    private ListAppender<ILoggingEvent> logAppender;

    @BeforeEach
    void setUp() {
        when(auditLogRepository.findLastEntryHashForUpdate()).thenReturn(Optional.empty());
        service = new AuditLogService(auditLogRepository);
        auditLogLogger = (Logger) LoggerFactory.getLogger(AuditLogService.class);
        previousLogLevel = auditLogLogger.getLevel();
        auditLogLogger.setLevel(Level.DEBUG);
        logAppender = new ListAppender<>();
        logAppender.start();
        auditLogLogger.addAppender(logAppender);
    }

    @AfterEach
    void tearDown() {
        if (auditLogLogger != null && logAppender != null) {
            auditLogLogger.detachAppender(logAppender);
            logAppender.stop();
        }
        if (auditLogLogger != null) {
            auditLogLogger.setLevel(previousLogLevel);
        }
        SecurityContextHolder.clearContext();
    }

    @Test
    void log_withoutAuthContextKeepsNullCompanyIdAndDoesNotWarn() {
        service.log("ACTION", "message", "entity-1");

        AuditLog saved = savedAuditLog();
        assertNull(saved.getCompanyId());
        assertFalse(warnEventsWithPrefix().stream().anyMatch(event -> event.getFormattedMessage().contains(WARN_PREFIX)));
    }

    @Test
    void log_unexpectedSecurityFailureWarnsButKeepsSchedulerCompatibleNullCompanyId() {
        Authentication auth = mock(Authentication.class);
        when(auth.getDetails()).thenThrow(new IllegalStateException("broken details"));
        SecurityContextHolder.getContext().setAuthentication(auth);

        service.log("ACTION", "message", "entity-1");

        AuditLog saved = savedAuditLog();
        assertNull(saved.getCompanyId());
        List<ILoggingEvent> warnEvents = warnEventsWithPrefix();
        assertEquals(1, warnEvents.size());
        String logs = warnEvents.getFirst().getFormattedMessage();
        assertTrue(logs.contains(WARN_PREFIX));
        assertTrue(logs.contains("IllegalStateException"));
        assertTrue(logs.contains("broken details"));
    }

    private List<ILoggingEvent> warnEventsWithPrefix() {
        return logAppender.list.stream()
                .filter(event -> Level.WARN.equals(event.getLevel()))
                .filter(event -> event.getFormattedMessage().contains(WARN_PREFIX))
                .toList();
    }

    private AuditLog savedAuditLog() {
        ArgumentCaptor<AuditLog> captor = ArgumentCaptor.forClass(AuditLog.class);
        verify(auditLogRepository).save(captor.capture());
        return captor.getValue();
    }
}
