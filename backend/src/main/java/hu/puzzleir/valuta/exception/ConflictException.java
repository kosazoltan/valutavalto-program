package hu.puzzleir.valuta.exception;

/**
 * Conflict kivétel — HTTP 409 Conflict.
 * Pl. optimistic lock, duplikátum, egyidejű módosítás.
 */
public class ConflictException extends RuntimeException {
    public ConflictException(String message) {
        super(message);
    }

    public ConflictException(String message, Throwable cause) {
        super(message, cause);
    }
}
