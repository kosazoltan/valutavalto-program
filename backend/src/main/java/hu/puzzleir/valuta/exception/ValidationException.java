package hu.puzzleir.valuta.exception;

public class ValidationException extends RuntimeException {
    public ValidationException(String message) {
        super(message);
    }

    /**
     * FKH-061: cause-preserving constructor. The hard day-closing steps (daily balance
     * calculation, SZAMZAR/TH adjustment) wrap a technical failure into a step-named
     * ValidationException; without a cause the stack trace and suppressed exceptions would be
     * lost, which makes post-mortem diagnosis harder. GlobalExceptionHandler still returns
     * getMessage() as HTTP 400, so client behaviour is unchanged.
     */
    public ValidationException(String message, Throwable cause) {
        super(message, cause);
    }
}
