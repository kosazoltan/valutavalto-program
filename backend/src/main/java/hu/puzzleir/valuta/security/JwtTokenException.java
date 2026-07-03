package hu.puzzleir.valuta.security;

/** JWT parse/validálási hiba — a jjwt-kivételek lib-független utódja (#386). */
public class JwtTokenException extends RuntimeException {
    public JwtTokenException(String message, Throwable cause) {
        super(message, cause);
    }

    public JwtTokenException(String message) {
        super(message);
    }
}
