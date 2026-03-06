package hu.puzzleir.valuta.service.led;

import lombok.extern.slf4j.Slf4j;

import java.util.List;

/**
 * Általános soros port LED driver — referencia implementáció.
 *
 * Legacy: METRO.DLL Unit2.pas — az alap kommunikációs protokoll.
 * A legtöbb LED kijelző hasonló ASCII protokollt használ:
 * - STX (0x02) + parancs + adat + ETX (0x03) + checksum
 *
 * Ez a driver a soros port kommunikációt az Electron kliens
 * oldalra delegálja IPC-n keresztül. A backend csak az adatot
 * formázza és a konfigurációt kezeli.
 *
 * Éles implementáció:
 * 1. Electron IPC → serialport npm modul → COM port
 * 2. Backend → WebSocket → Electron → serialport
 */
@Slf4j
public class GenericSerialLedDriver implements LedDriverProtocol {

    private boolean connected = false;
    private String connectionString;
    private static final char STX = 0x02;
    private static final char ETX = 0x03;

    @Override
    public boolean connect(String connectionString) {
        this.connectionString = connectionString;
        // TODO: Electron IPC bridge-en keresztül soros port megnyitás
        log.info("LED driver csatlakozás: {} (SIMULATED)", connectionString);
        this.connected = true;
        return true;
    }

    @Override
    public void disconnect() {
        log.info("LED driver lecsatlakozás: {}", connectionString);
        this.connected = false;
    }

    @Override
    public boolean isConnected() {
        return connected;
    }

    @Override
    public boolean updateRateBoard(List<RateBoardLine> lines) {
        if (!connected) {
            log.warn("LED driver nincs csatlakoztatva!");
            return false;
        }

        StringBuilder payload = new StringBuilder();
        for (RateBoardLine line : lines) {
            // Formátum: "EUR  386.50  389.00\n"
            payload.append(String.format("%-5s %8s %8s\n",
                    line.currencyCode(),
                    line.buyRate().toPlainString(),
                    line.sellRate().toPlainString()));
        }

        String frame = buildFrame("R", payload.toString());
        log.debug("LED rate board frissítés: {} sor, frame: {} byte",
                lines.size(), frame.length());

        // TODO: Electron IPC-n küldeni
        return true;
    }

    @Override
    public boolean sendScrollingText(String text, int speed) {
        if (!connected) return false;

        String frame = buildFrame("S", String.format("%d|%s", speed, text));
        log.debug("LED scrolling text: speed={}, text={}, frame={} byte",
                speed, text.length() > 30 ? text.substring(0, 30) + "..." : text, frame.length());

        // TODO: Electron IPC-n küldeni
        return true;
    }

    @Override
    public boolean clearDisplay() {
        if (!connected) return false;
        log.debug("LED display törölve");
        return true;
    }

    @Override
    public boolean setBrightness(int brightness) {
        if (!connected) return false;
        int clamped = Math.max(0, Math.min(100, brightness));
        String frame = buildFrame("B", String.valueOf(clamped));
        log.debug("LED fényerő: {}%", clamped);
        return true;
    }

    @Override
    public LedDriverType getDriverType() {
        return LedDriverType.GENERIC_SERIAL;
    }

    // === PRIVÁT ===

    /**
     * RS-232 frame összeállítása.
     * Formátum: STX + parancs(1) + adat + ETX + checksum(2)
     */
    private String buildFrame(String command, String data) {
        String body = command + data;
        int checksum = 0;
        for (char c : body.toCharArray()) {
            checksum ^= c;
        }
        return STX + body + ETX + String.format("%02X", checksum & 0xFF);
    }
}
