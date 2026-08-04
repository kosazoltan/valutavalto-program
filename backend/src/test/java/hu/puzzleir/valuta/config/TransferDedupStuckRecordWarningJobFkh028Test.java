package hu.puzzleir.valuta.config;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import hu.puzzleir.valuta.entity.IdempotencyRecord;
import hu.puzzleir.valuta.repository.IdempotencyRecordRepository;
import hu.puzzleir.valuta.service.TransferCreateDedupGuard;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.slf4j.LoggerFactory;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

/**
 * FKH-028 7. kör: a beragadt-PROCESSING figyelmeztető job tesztjei — a job KIZÁRÓLAG
 * riaszt (log.warn), nem módosít; a küszöb konfigurálható (perc).
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class TransferDedupStuckRecordWarningJobFkh028Test {

    private static final long WARN_MINUTES = 15;

    @Mock private IdempotencyRecordRepository repository;

    private TransferDedupStuckRecordWarningJob job;
    private ListAppender<ILoggingEvent> logAppender;
    private Logger jobLogger;

    @BeforeEach
    void setUp() {
        job = new TransferDedupStuckRecordWarningJob(repository, WARN_MINUTES);
        jobLogger = (Logger) LoggerFactory.getLogger(TransferDedupStuckRecordWarningJob.class);
        logAppender = new ListAppender<>();
        logAppender.start();
        jobLogger.addAppender(logAppender);
    }

    @AfterEach
    void tearDown() {
        jobLogger.detachAppender(logAppender);
    }

    private IdempotencyRecord stuckRecord() {
        return IdempotencyRecord.builder()
                .id(42L)
                .companyId(UUID.randomUUID())
                .endpoint(TransferCreateDedupGuard.ENDPOINT)
                .idempotencyKey("deadbeef")
                .requestHash("deadbeef")
                .status(IdempotencyRecord.Status.PROCESSING)
                .createdAt(Instant.now().minus(25, ChronoUnit.MINUTES))
                .expiresAt(Instant.now().plus(1, ChronoUnit.HOURS))
                .build();
    }

    @Test
    @DisplayName("Pozitív: a küszöbnél régebbi PROCESSING rekordnál a job log.warn-t ír (rekord-azonosítóval és korral)")
    void stuckRecord_triggersWarn() {
        when(repository.findByEndpointAndStatusAndCreatedAtBefore(
                eq(TransferCreateDedupGuard.ENDPOINT),
                eq(IdempotencyRecord.Status.PROCESSING),
                any()))
                .thenReturn(List.of(stuckRecord()));

        job.warnStuckRecords();

        List<ILoggingEvent> warns = logAppender.list.stream()
                .filter(e -> e.getLevel() == ch.qos.logback.classic.Level.WARN)
                .toList();
        assertThat(warns)
                .as("Beragadt rekordnál kötelező a WARN")
                .hasSize(1);
        assertThat(warns.get(0).getFormattedMessage())
                .contains("42")
                .containsIgnoringCase("PROCESSING");
    }

    @Test
    @DisplayName("Negatív: ha nincs küszöbnél régebbi PROCESSING rekord, a job nem ír WARN-t")
    void noStuckRecord_noWarn() {
        when(repository.findByEndpointAndStatusAndCreatedAtBefore(any(), any(), any()))
                .thenReturn(List.of());

        job.warnStuckRecords();

        assertThat(logAppender.list.stream()
                .filter(e -> e.getLevel() == ch.qos.logback.classic.Level.WARN))
                .as("Beragadt rekord nélkül nincs WARN")
                .isEmpty();
    }

    @Test
    @DisplayName("A job csak riaszt: sem save, sem delete nem hívódik a repository-n")
    void jobIsReadOnly() {
        when(repository.findByEndpointAndStatusAndCreatedAtBefore(any(), any(), any()))
                .thenReturn(List.of(stuckRecord()));

        job.warnStuckRecords();

        org.mockito.Mockito.verify(repository, org.mockito.Mockito.never()).save(any());
        org.mockito.Mockito.verify(repository, org.mockito.Mockito.never()).delete(any());
        org.mockito.Mockito.verify(repository, org.mockito.Mockito.never()).deleteAll();
    }
}
