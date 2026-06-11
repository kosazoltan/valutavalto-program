package hu.puzzleir.valuta.service;

/**
 * CSV segédmetódusok — NFR-03 (b9-munkavallalo export).
 *
 * <p>Két védelmi réteg (review: Sourcery + Codex P2 + Copilot a #1088-ban):</p>
 * <ul>
 *   <li><b>RFC 4180 idézés:</b> ha a cella elválasztót (;), idézőjelet vagy sortörést
 *       tartalmaz, idézőjelek közé kerül (a belső idézőjelek duplázva) — különben a
 *       szabad-szöveges mezők széttörnék az oszlop-szerkezetet.</li>
 *   <li><b>CSV-injection (OWASP):</b> ha a cella érdemi tartalma {@code = + - @} vagy TAB
 *       karakterrel kezdődik — a VEZETŐ whitespace átlépése UTÁN is —, aposztróf-prefix
 *       kerül elé, így a táblázatkezelő nem értelmezi képletként.</li>
 * </ul>
 */
public final class CsvUtils {

    private CsvUtils() {}

    /** Az exportokban használt cella-elválasztó. */
    public static final char SEPARATOR = ';';

    /**
     * Egy CSV-cellát biztonságossá tesz injection ellen és RFC 4180 szerint idéz.
     *
     * @param value a cella értéke (null esetén üres string)
     * @return a biztonságos, szükség esetén idézett cella-tartalom
     */
    public static String escapeCsvCell(String value) {
        if (value == null || value.isEmpty()) {
            return "";
        }

        String cell = value;

        // Injection-guard: a vezető whitespace/tab átlépése utáni első érdemi karaktert nézzük
        // (Copilot: " =SUM(...)" és "\t=SUM(...)" is képletként értelmeződhet Excelben).
        int i = 0;
        while (i < cell.length() && (cell.charAt(i) == ' ' || cell.charAt(i) == '\t')) {
            i++;
        }
        if (i < cell.length()) {
            char first = cell.charAt(i);
            if (first == '=' || first == '+' || first == '-' || first == '@') {
                cell = "'" + cell;
            }
        } else if (cell.indexOf('\t') >= 0) {
            // csak whitespace/tab tartalom — a tab önmagában is védendő
            cell = "'" + cell;
        }

        // RFC 4180: elválasztó / idézőjel / sortörés esetén idézés + belső idézőjel-duplázás
        if (cell.indexOf(SEPARATOR) >= 0 || cell.indexOf('"') >= 0
                || cell.indexOf('\n') >= 0 || cell.indexOf('\r') >= 0) {
            cell = '"' + cell.replace("\"", "\"\"") + '"';
        }
        return cell;
    }
}
