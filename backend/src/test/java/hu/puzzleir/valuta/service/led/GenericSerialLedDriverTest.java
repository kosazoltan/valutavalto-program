package hu.puzzleir.valuta.service.led;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class GenericSerialLedDriverTest {

    @Test
    @DisplayName("alapértelmezetten valódi transport nélkül nem jelent sikeres LED kapcsolatot")
    void defaultDriverFailsClosedWithoutTransport() {
        GenericSerialLedDriver driver = new GenericSerialLedDriver();

        assertThat(driver.connect("COM3:9600")).isFalse();
        assertThat(driver.isConnected()).isFalse();
        assertThat(driver.updateRateBoard(sampleLines())).isFalse();
        assertThat(driver.sendScrollingText("Teszt", 5)).isFalse();
        assertThat(driver.clearDisplay()).isFalse();
        assertThat(driver.setBrightness(80)).isFalse();
    }

    @Test
    @DisplayName("szimulált LED siker csak explicit kapcsolóval engedélyezett")
    void simulatedDriverCanReturnSuccessWhenExplicitlyEnabled() {
        GenericSerialLedDriver driver = new GenericSerialLedDriver(true);

        assertThat(driver.connect("COM3:9600")).isTrue();
        assertThat(driver.isConnected()).isTrue();
        assertThat(driver.updateRateBoard(sampleLines())).isTrue();
        assertThat(driver.sendScrollingText("Teszt", 5)).isTrue();
        assertThat(driver.clearDisplay()).isTrue();
        assertThat(driver.setBrightness(80)).isTrue();
    }

    private List<LedDriverProtocol.RateBoardLine> sampleLines() {
        return List.of(new LedDriverProtocol.RateBoardLine(
                "EUR",
                "Euro",
                new BigDecimal("390.00"),
                new BigDecimal("392.00"),
                1));
    }
}
