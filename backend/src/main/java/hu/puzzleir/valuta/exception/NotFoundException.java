package hu.puzzleir.valuta.exception;

/**
 * General 404 custom exception.
 * Backward-compatible alias to existing ResourceNotFoundException.
 */
public class NotFoundException extends ResourceNotFoundException {
    public NotFoundException(String message) {
        super(message);
    }
}
