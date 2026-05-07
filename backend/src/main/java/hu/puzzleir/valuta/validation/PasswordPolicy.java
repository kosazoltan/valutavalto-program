package hu.puzzleir.valuta.validation;

public final class PasswordPolicy {

    public static final int MIN_LENGTH = 8;
    public static final int MAX_LENGTH = 128;
    public static final String LENGTH_MESSAGE = "A jelszó 8-128 karakter között legyen";
    public static final String MAX_LENGTH_MESSAGE = "A jelszó maximum 128 karakter lehet";

    private PasswordPolicy() {
    }
}
