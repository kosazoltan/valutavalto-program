package hu.puzzleir.valuta.service.led;

/**
 * LED kijelző driver típusok — a 17 legacy variáns.
 *
 * Minden típusnak saját RS-232/USB/LAN protokollja van.
 * Az Electron kliens oldalon a megfelelő driver-t kell betölteni.
 */
public enum LedDriverType {

    // --- Soros port (RS-232) ---
    METRO_S1("Metro/Signtec single-line", "RS232", 9600),
    METRO_S2("Metro/Signtec dual-line", "RS232", 9600),
    TRUELIGHT("TrueLight LED panel", "RS232", 9600),
    TOPICA("Topica LED", "RS232", 4800),
    SIGNTEC("Signtec advanced", "RS232", 9600),
    LEDMAN("Ledman LED", "RS232", 9600),
    DELTA("Delta LED panel", "RS232", 9600),
    GENERIC_SERIAL("Általános soros port", "RS232", 9600),

    // --- Hálózat (LAN) ---
    NOVASTAR("Novastar sender", "LAN", 5200),
    LINSN("Linsn sender", "LAN", 5200),
    COLORLIGHT("Colorlight sender", "LAN", 5200),
    HUIDU("Huidu controller", "LAN", 10000),
    KYSTAR("Kystar sender", "LAN", 5200),
    MAGNIMAGE("Magnimage processor", "LAN", 5200),
    DBSTAR("DBStar sender", "LAN", 5200),
    XIXUN("Xixun controller", "LAN", 10000),
    ONBON("Onbon BX controller", "LAN", 10000),

    // --- Virtuális (szoftver) ---
    VIRTUAL("Virtuális kijelző (teszt)", "VIRTUAL", 0),
    WEB_DISPLAY("Web alapú kijelző", "HTTP", 8080);

    private final String description;
    private final String connectionType;
    private final int defaultPort;

    LedDriverType(String description, String connectionType, int defaultPort) {
        this.description = description;
        this.connectionType = connectionType;
        this.defaultPort = defaultPort;
    }

    public String getDescription() { return description; }
    public String getConnectionType() { return connectionType; }
    public int getDefaultPort() { return defaultPort; }
}
