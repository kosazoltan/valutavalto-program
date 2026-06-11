package hu.puzzleir.valuta.service;

/**
 * CSV segédmetódusok — NFR-03 (b9-munkavallalo export).
 *
 * <p>CSV-injection elleni védelem: ha egy cella =, +, -, @ karakterrel kezdődik,
 * elé aposztróf kerül (OWASP CSV Injection Prevention).</p>
 */
public final class CsvUtils {

    private CsvUtils() {}

    /**
     * Egy CSV-cellát biztonságossá tesz injection ellen.
     *
     * @param value a cella értéke (null esetén üres string)
     * @return a biztonságos cella-tartalom
     */
    public static String escapeCsvCell(String value) {
        if (value == null || value.isEmpty()) {
            return "";
        }
        char first = value.charAt(0);
        if (first == '=' || first == '+' || first == '-' || first == '@') {
            return "'" + value;
        }
        return value;
    }
}
