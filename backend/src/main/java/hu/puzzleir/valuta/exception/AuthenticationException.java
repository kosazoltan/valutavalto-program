package hu.puzzleir.valuta.exception;

/**
 * Kivétel helytelen bejelentkezési adatokhoz (401 Unauthorized).
 */
public class AuthenticationException extends RuntimeException {
    public AuthenticationException(String message) {
        super(message);
    }
}
