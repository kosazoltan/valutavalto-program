package hu.puzzleir.valuta.service.led;

/**
 * LED kijelző driver protokoll absztrakció.
 *
 * Legacy: METRO.DLL, TRUELIGHT.DLL, TOPICA.DLL, SIGNTEC.DLL, stb.
 * A Delphi rendszerben 17 különböző LED kijelző gyártó driver-je volt,
 * mindegyik más RS-232/USB protokollal.
 *
 * Az új rendszerben:
 * 1. Szoftver absztrakció (LedDriverProtocol interface)
 * 2. Driver implementáció gyártónként
 * 3. Electron IPC bridge → soros port kommunikáció
 * 4. Konfiguráció: system_parameter-ből melyik driver típus kell
 *
 * A 17 legacy variáns:
 * 1.  METRO-S1      — Metro/Signtec single-line (RS-232)
 * 2.  METRO-S2      — Metro/Signtec dual-line
 * 3.  TRUELIGHT     — TrueLight LED panel (RS-232 9600 baud)
 * 4.  TOPICA        — Topica LED (RS-232 4800 baud)
 * 5.  SIGNTEC       — Signtec advanced (RS-232)
 * 6.  NOVASTAR      — Novastar sender (LAN/USB)
 * 7.  LEDMAN        — Ledman LED (RS-232)
 * 8.  LINSN         — Linsn sender (LAN)
 * 9.  COLORLIGHT    — Colorlight sender (LAN)
 * 10. HUIDU         — Huidu controller (LAN/USB)
 * 11. DELTA         — Delta LED panel
 * 12. KYSTAR        — Kystar sender
 * 13. MAGNIMAGE     — Magnimage video processor
 * 14. DBSTAR        — DBStar sender
 * 15. XIXUN         — Xixun controller (WiFi/LAN)
 * 16. ONBON         — Onbon BX controller
 * 17. GENERIC_SERIAL — Általános soros port
 */
public interface LedDriverProtocol {

    /**
     * Kapcsolat felépítése.
     * @param connectionString pl. "COM3:9600" vagy "192.168.1.100:5200"
     * @return true ha sikeres
     */
    boolean connect(String connectionString);

    /**
     * Kapcsolat bontása.
     */
    void disconnect();

    /**
     * Kapcsolat állapota.
     */
    boolean isConnected();

    /**
     * Árfolyam tábla frissítése.
     * @param lines sorok (valutanem + vétel + eladás)
     * @return true ha sikeres
     */
    boolean updateRateBoard(java.util.List<RateBoardLine> lines);

    /**
     * Futó szöveg küldése.
     * @param text szöveg (max 255 karakter)
     * @param speed sebesség (1-10)
     * @return true ha sikeres
     */
    boolean sendScrollingText(String text, int speed);

    /**
     * Kijelző törlése.
     */
    boolean clearDisplay();

    /**
     * Fényerő beállítása.
     * @param brightness 0-100%
     */
    boolean setBrightness(int brightness);

    /**
     * Driver típusa.
     */
    LedDriverType getDriverType();

    /**
     * Árfolyam tábla egy sora.
     */
    record RateBoardLine(
        String currencyCode,
        String currencyName,
        java.math.BigDecimal buyRate,
        java.math.BigDecimal sellRate,
        int unit
    ) {}
}
