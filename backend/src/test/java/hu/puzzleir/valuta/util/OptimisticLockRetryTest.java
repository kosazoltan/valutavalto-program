package hu.puzzleir.valuta.util;

import hu.puzzleir.valuta.exception.BusinessException;
import jakarta.persistence.OptimisticLockException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.orm.ObjectOptimisticLockingFailureException;

import java.util.function.Supplier;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class OptimisticLockRetryTest {

    private static final String OP = "test-op";

    @SuppressWarnings("unchecked")
    private static Supplier<String> mockSupplier() {
        return mock(Supplier.class);
    }

    @Test
    @DisplayName("(1) sikeres elso probalkozas: ertek visszajon, supplier 1x hivodik")
    void firstAttemptSuccess() {
        Supplier<String> supplier = mockSupplier();
        when(supplier.get()).thenReturn("ok");

        String result = OptimisticLockRetry.execute(supplier, OP);

        assertThat(result).isEqualTo("ok");
        verify(supplier, times(1)).get();
    }

    @Test
    @DisplayName("(2a) OOLFE az 1. hivasnal, siker a 2.-nal: eredmeny visszajon, 2 hivas")
    void retriesOnSpringLockExceptionThenSucceeds() {
        Supplier<String> supplier = mockSupplier();
        when(supplier.get())
                .thenThrow(new ObjectOptimisticLockingFailureException("CashBalance", 1L))
                .thenReturn("ok");

        assertThat(OptimisticLockRetry.execute(supplier, OP)).isEqualTo("ok");
        verify(supplier, times(2)).get();
    }

    @Test
    @DisplayName("(2b) jakarta OptimisticLockException 2x, siker a 3.-nal: 3 hivas")
    void retriesTwiceOnJakartaLockExceptionThenSucceeds() {
        Supplier<String> supplier = mockSupplier();
        when(supplier.get())
                .thenThrow(new OptimisticLockException("stale"))
                .thenThrow(new OptimisticLockException("stale"))
                .thenReturn("ok");

        assertThat(OptimisticLockRetry.execute(supplier, OP)).isEqualTo("ok");
        verify(supplier, times(3)).get();
    }

    @Test
    @DisplayName("(3a) mindig OOLFE: 3 hivas utan az EREDETI peldany propagal")
    void exhaustedRetriesRethrowOriginalSpringException() {
        Supplier<String> supplier = mockSupplier();
        ObjectOptimisticLockingFailureException original =
                new ObjectOptimisticLockingFailureException("CashBalance", 1L);
        when(supplier.get()).thenThrow(original);

        assertThatThrownBy(() -> OptimisticLockRetry.execute(supplier, OP))
                .isSameAs(original);
        verify(supplier, times(3)).get();
    }

    @Test
    @DisplayName("(3b) mindig jakarta OLE: 3 hivas utan az EREDETI peldany propagal")
    void exhaustedRetriesRethrowOriginalJakartaException() {
        Supplier<String> supplier = mockSupplier();
        OptimisticLockException original = new OptimisticLockException("stale");
        when(supplier.get()).thenThrow(original);

        assertThatThrownBy(() -> OptimisticLockRetry.execute(supplier, OP))
                .isSameAs(original);
        verify(supplier, times(3)).get();
    }

    @Test
    @DisplayName("(4) nem-lock RuntimeException: NINCS retry, 1 hivas, eredeti propagal")
    void nonLockExceptionPropagatesImmediately() {
        Supplier<String> supplier = mockSupplier();
        IllegalArgumentException original = new IllegalArgumentException("boom");
        when(supplier.get()).thenThrow(original);

        assertThatThrownBy(() -> OptimisticLockRetry.execute(supplier, OP))
                .isSameAs(original);
        verify(supplier, times(1)).get();
    }

    @Test
    @DisplayName("(5) executeVoid siker es retry: runnable hivas-szamok helyesek")
    void executeVoidSuccessAndRetriesThenSucceeds() {
        Runnable successRunnable = mock(Runnable.class);

        OptimisticLockRetry.executeVoid(successRunnable, OP);

        verify(successRunnable, times(1)).run();

        Runnable retryRunnable = mock(Runnable.class);
        doThrow(new ObjectOptimisticLockingFailureException("CashBalance", 1L))
                .doNothing()
                .when(retryRunnable).run();

        OptimisticLockRetry.executeVoid(retryRunnable, OP);

        verify(retryRunnable, times(2)).run();
    }

    @Test
    @DisplayName("(6) sleep-interrupt: BusinessException RETRY_INTERRUPTED + flag visszaall")
    void interruptDuringRetrySleepThrowsBusinessExceptionAndRestoresFlag() {
        Supplier<String> supplier = () -> {
            Thread.currentThread().interrupt();
            throw new ObjectOptimisticLockingFailureException("CashBalance", 1L);
        };

        try {
            assertThatThrownBy(() -> OptimisticLockRetry.execute(supplier, OP))
                    .isInstanceOf(BusinessException.class)
                    .hasMessage("Retry interrupted")
                    .extracting(e -> ((BusinessException) e).getErrorCode())
                    .isEqualTo("RETRY_INTERRUPTED");
            assertThat(Thread.currentThread().isInterrupted())
                    .as("a SUT-nak vissza kell allitania az interrupt-flaget")
                    .isTrue();
        } finally {
            Thread.interrupted();
        }
    }
}
