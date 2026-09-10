package hu.puzzleir.valuta.exception;

public class ValidationException extends RuntimeException {
    public ValidationException(String message) {
        super(message);
    }

    /**
     * FKH-061: ok-lánc megőrző konstruktor. A napzárás kemény lépései (napi mérleg számítás,
     * SZÁMZÁR/TH igazítás) a technikai hibát lépés-nevű ValidationException-be csomagolják —
     * cause nélkül a stacktrace és az elnyomott kivételek elveszne, ami a post-mortem
     * diagnózist nehezíti (reviewer WARNING). A GlobalExceptionHandler továbbra is a
     * getMessage()-t adja vissza HTTP 400-ként, tehát a kliens-viselkedés nem változik.
     */
    public ValidationException(String message, Throwable cause) {
        super(message, cause);
    }
}
