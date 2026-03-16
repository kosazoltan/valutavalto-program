package hu.puzzleir.valuta.service.led;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.*;

/**
 * LedSerialPortDriver egységtesztek.
 *
 * Megjegyzés: nem létező COM portokra a send() false-t ad vissza
 * (nem kivételt), így CI környezetben is biztonságosan futnak.
 */
class LedSerialPortDriverTest {

    private LedSerialPortDriver driver;

    @BeforeEach
    void setUp() {
        driver = new LedSerialPortDriver();
    }

    @Test
    @DisplayName("1. Nem létező portra küldés false-t ad vissza")
    void sendToNonexistentPortReturnsFalse() {
        byte[] data = new byte[]{21, 18, 5, (byte) 254};
        boolean result = driver.send("COM99", data);
        assertThat(result).isFalse();
    }

    @Test
    @DisplayName("2. listAvailablePorts nem null tömböt ad vissza")
    void listPortsReturnsNonNullArray() {
        String[] ports = driver.listAvailablePorts();
        assertThat(ports).isNotNull();
        // CI-n üres is lehet, de nem null
    }

    @Test
    @DisplayName("3. null adat IllegalArgumentException-t dob")
    void nullDataThrowsIllegalArgumentException() {
        assertThatThrownBy(() -> driver.send("COM1", null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("null");
    }

    @Test
    @DisplayName("4. Üres adat IllegalArgumentException-t dob")
    void emptyDataThrowsIllegalArgumentException() {
        assertThatThrownBy(() -> driver.send("COM1", new byte[0]))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("üres");
    }
}
