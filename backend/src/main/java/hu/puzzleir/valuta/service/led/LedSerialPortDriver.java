package hu.puzzleir.valuta.service.led;

import com.fazecast.jSerialComm.SerialPort;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * Soros port (RS-232 / USB-serial) kommunikáció LED kijelzőkhöz.
 *
 * Beállítások: 9600 baud, 8 adatbit, 1 stopbit, nincs paritás.
 *
 * Legacy: a Delphi rendszer közvetlenül COM portot nyitott, küldött, zárt.
 * Ez az osztály ugyanezt csinálja jSerialComm könyvtárral.
 */
@Component
@Slf4j
public class LedSerialPortDriver {

    private static final int BAUD_RATE    = 9600;
    private static final int DATA_BITS    = 8;
    private static final int STOP_BITS    = SerialPort.ONE_STOP_BIT;
    private static final int PARITY       = SerialPort.NO_PARITY;
    private static final int WRITE_TIMEOUT_MS = 2000;

    /**
     * Adatok küldése a megadott soros porton.
     *
     * @param portName port neve, pl. "COM1" vagy "/dev/ttyS0"
     * @param data     küldendő bájt tömb
     * @return true ha sikeres, false ha a port nem létezik vagy írási hiba
     * @throws IllegalArgumentException ha data null vagy üres
     */
    public boolean send(String portName, byte[] data) {
        if (data == null) {
            throw new IllegalArgumentException("Az adat nem lehet null!");
        }
        if (data.length == 0) {
            throw new IllegalArgumentException("Az adat nem lehet üres!");
        }

        SerialPort port = SerialPort.getCommPort(portName);
        if (port == null) {
            log.warn("Soros port nem található: {}", portName);
            return false;
        }

        port.setBaudRate(BAUD_RATE);
        port.setNumDataBits(DATA_BITS);
        port.setNumStopBits(STOP_BITS);
        port.setParity(PARITY);
        port.setComPortTimeouts(SerialPort.TIMEOUT_WRITE_BLOCKING, 0, WRITE_TIMEOUT_MS);

        try {
            if (!port.openPort()) {
                log.warn("Soros port megnyitása sikertelen: {}", portName);
                return false;
            }
            int written = port.writeBytes(data, data.length);
            if (written < 0) {
                log.warn("Soros port írási hiba: {}, írva: {}", portName, written);
                return false;
            }
            log.debug("Soros port küldés OK: {} — {} bájt", portName, written);
            return true;
        } catch (Exception e) {
            log.error("Soros port kivétel: {} — {}", portName, e.getMessage());
            return false;
        } finally {
            if (port.isOpen()) {
                port.closePort();
            }
        }
    }

    /**
     * Elérhető soros portok lekérdezése.
     *
     * @return port nevek tömbje (pl. ["COM1", "COM3"]), soha nem null
     */
    public String[] listAvailablePorts() {
        SerialPort[] ports = SerialPort.getCommPorts();
        String[] names = new String[ports.length];
        for (int i = 0; i < ports.length; i++) {
            names[i] = ports[i].getSystemPortName();
        }
        log.debug("Elérhető soros portok: {}", (Object) names);
        return names;
    }
}
