package hu.puzzleir.valuta.service;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;

class DeferredIndependentAuditTest {

    @AfterEach
    void clearTransactionSynchronization() {
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.clearSynchronization();
        }
    }

    @Test
    void activeTransactionDefersAuditUntilRollbackCompletion() {
        AtomicInteger executions = new AtomicInteger();
        TransactionSynchronizationManager.initSynchronization();

        DeferredIndependentAudit.run(executions::incrementAndGet, "rollback audit");

        assertThat(executions).hasValue(0);
        assertThat(TransactionSynchronizationManager.getSynchronizations()).singleElement();

        TransactionSynchronizationManager.getSynchronizations().getFirst()
                .afterCompletion(TransactionSynchronization.STATUS_ROLLED_BACK);

        assertThat(executions).hasValue(1);
    }

    @Test
    void activeTransactionAlsoRunsAuditAfterCommitCompletion() {
        AtomicInteger executions = new AtomicInteger();
        TransactionSynchronizationManager.initSynchronization();

        DeferredIndependentAudit.run(executions::incrementAndGet, "commit audit");
        TransactionSynchronizationManager.getSynchronizations().getFirst()
                .afterCompletion(TransactionSynchronization.STATUS_COMMITTED);

        assertThat(executions).hasValue(1);
    }

    @Test
    void noTransactionSynchronizationRunsAuditImmediately() {
        AtomicInteger executions = new AtomicInteger();

        DeferredIndependentAudit.run(executions::incrementAndGet, "immediate audit");

        assertThat(executions).hasValue(1);
    }

    @Test
    void auditFailureNeverPropagates() {
        assertThatCode(() -> DeferredIndependentAudit.run(
                () -> {
                    throw new IllegalStateException("audit unavailable");
                },
                "failing immediate audit"))
                .doesNotThrowAnyException();

        TransactionSynchronizationManager.initSynchronization();
        DeferredIndependentAudit.run(
                () -> {
                    throw new IllegalStateException("audit unavailable after completion");
                },
                "failing deferred audit");

        assertThatCode(() -> TransactionSynchronizationManager.getSynchronizations().getFirst()
                .afterCompletion(TransactionSynchronization.STATUS_UNKNOWN))
                .doesNotThrowAnyException();
    }
}
