package hu.puzzleir.valuta.service.led;

import hu.puzzleir.valuta.entity.LedDisplayConfig;
import hu.puzzleir.valuta.entity.LedSerialDisplayType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.Map;

import static org.assertj.core.api.Assertions.*;

/**
 * LedProtocolEncoder egységtesztek.
 * Ellenőrzi a bájt-szintű protokoll helyes összeállítását.
 */
class LedProtocolEncoderTest {

    private LedProtocolEncoder encoder;

    @BeforeEach
    void setUp() {
        encoder = new LedProtocolEncoder();
    }

    // ---------- Init bájtok ----------

    @Test
    @DisplayName("1. Init bájtok [21, 18, 5] a csomag elején")
    void initBytesAtStart() {
        LedDisplayConfig config = buildConfig(true, 5, "254", ',', LedSerialDisplayType.STANDARD);
        Map<String, BigDecimal[]> rates = Map.of("EUR",
                new BigDecimal[]{new BigDecimal("400.00"), new BigDecimal("405.00")});

        byte[] packet = encoder.encodeRates(config, rates);

        assertThat(packet).hasSizeGreaterThanOrEqualTo(3);
        assertThat(packet[0]).isEqualTo((byte) 21);
        assertThat(packet[1]).isEqualTo((byte) 18);
        assertThat(packet[2]).isEqualTo((byte) 5);
    }

    // ---------- Speed command ----------

    @Test
    @DisplayName("2. Speed command [92, 70, 83, 53] amikor speed=5")
    void speedCommandWhenEnabled() {
        LedDisplayConfig config = buildConfig(true, 5, "254", ',', LedSerialDisplayType.STANDARD);
        Map<String, BigDecimal[]> rates = Map.of();

        byte[] packet = encoder.encodeRates(config, rates);

        // Init [21,18,5] + Speed [92,70,83,53]
        assertThat(packet).hasSizeGreaterThanOrEqualTo(7);
        assertThat(packet[3]).isEqualTo((byte) 92);
        assertThat(packet[4]).isEqualTo((byte) 70);
        assertThat(packet[5]).isEqualTo((byte) 83);
        assertThat(packet[6]).isEqualTo((byte) 53);  // 48 + 5
    }

    @Test
    @DisplayName("3. Nincs speed command amikor speedCommand=false")
    void noSpeedCommandWhenDisabled() {
        LedDisplayConfig config = buildConfig(false, 5, "254", ',', LedSerialDisplayType.STANDARD);
        Map<String, BigDecimal[]> rates = Map.of();

        byte[] packet = encoder.encodeRates(config, rates);

        // Init [21,18,5] + End [254] — 4 bájt total
        assertThat(packet).hasSize(4);
        // Nincs 92 a 4. pozícióban (az a speed command lenne)
        assertThat(packet[3]).isEqualTo((byte) 254);
    }

    // ---------- End markers ----------

    @Test
    @DisplayName("4. Egyetlen záró bájt [254]")
    void singleEndMarker() {
        LedDisplayConfig config = buildConfig(false, 5, "254", ',', LedSerialDisplayType.STANDARD);
        Map<String, BigDecimal[]> rates = Map.of();

        byte[] packet = encoder.encodeRates(config, rates);

        assertThat(packet[packet.length - 1]).isEqualTo((byte) 254);
        // Csak egy záró bájt
        if (packet.length >= 2) {
            assertThat(packet[packet.length - 2]).isNotEqualTo((byte) 255);
        }
    }

    @Test
    @DisplayName("5. Kettős záró bájt [254, 255]")
    void doubleEndMarker() {
        LedDisplayConfig config = buildConfig(false, 5, "254,255", ',', LedSerialDisplayType.STANDARD);
        Map<String, BigDecimal[]> rates = Map.of();

        byte[] packet = encoder.encodeRates(config, rates);

        assertThat(packet).hasSizeGreaterThanOrEqualTo(2);
        assertThat(packet[packet.length - 2]).isEqualTo((byte) 254);
        assertThat(packet[packet.length - 1]).isEqualTo((byte) 255);
    }

    // ---------- formatRate ----------

    @Test
    @DisplayName("6. formatRate: magyar vesszős elválasztóval: '405.32' → '405,32'")
    void formatRateHungarianComma() {
        String result = encoder.formatRate(new BigDecimal("405.32"), ',');
        assertThat(result).isEqualTo("405,32");
    }

    @Test
    @DisplayName("7. formatRate: pontos elválasztóval: '405.32' → '405.32'")
    void formatRateDot() {
        String result = encoder.formatRate(new BigDecimal("405.32"), '.');
        assertThat(result).isEqualTo("405.32");
    }

    @Test
    @DisplayName("8. formatRate: jobbra igazítás 6 karakterre: '95.20' → ' 95,20'")
    void formatRateRightAligned() {
        String result = encoder.formatRate(new BigDecimal("95.20"), ',');
        assertThat(result).isEqualTo(" 95,20");
        assertThat(result).hasSize(6);
    }

    @Test
    @DisplayName("8b. formatRate: kis érték jobbra igazítva: '3.75' → '  3,75'")
    void formatRateSmallValueRightAligned() {
        String result = encoder.formatRate(new BigDecimal("3.75"), ',');
        assertThat(result).isEqualTo("  3,75");
        assertThat(result).hasSize(6);
    }

    // ---------- encodeText ----------

    @Test
    @DisplayName("9. encodeText: érvényes csomag összeállítása")
    void encodeTextProducesValidPacket() {
        LedDisplayConfig config = buildConfig(true, 3, "254", ',', LedSerialDisplayType.TEXT_ONLY);
        config.setCustomText("HELLO");

        byte[] packet = encoder.encodeText(config, "HELLO");

        // Init [21,18,5] + Speed [92,70,83,51] + "HELLO" (5 bájt) + [254]
        assertThat(packet[0]).isEqualTo((byte) 21);
        assertThat(packet[1]).isEqualTo((byte) 18);
        assertThat(packet[2]).isEqualTo((byte) 5);
        assertThat(packet[packet.length - 1]).isEqualTo((byte) 254);
        // Ellenőrzés: 'H' 'E' 'L' 'L' 'O' bájtok megvannak
        String decoded = new String(packet, 7, 5);
        assertThat(decoded).isEqualTo("HELLO");
    }

    // ---------- encodeMultiDisplay ----------

    @Test
    @DisplayName("10. DUAL_SAME: mindkét csomag azonos")
    void dualSameBothPacketsIdentical() {
        LedDisplayConfig config = buildConfig(true, 5, "254", ',', LedSerialDisplayType.DUAL_SAME);
        Map<String, BigDecimal[]> rates = Map.of("EUR",
                new BigDecimal[]{new BigDecimal("400.00"), new BigDecimal("405.00")});

        byte[][] packets = encoder.encodeMultiDisplay(config, rates);

        assertThat(packets.length).isEqualTo(2);
        assertThat(packets[0]).isEqualTo(packets[1]);
    }

    @Test
    @DisplayName("11. DUAL_DIFF: két csomag különböző")
    void dualDiffPacketsDiffer() {
        LedDisplayConfig config = buildConfig(true, 5, "254", ',', LedSerialDisplayType.DUAL_DIFF);
        config.setCustomText("CHANGE - WESTERN UNION");
        Map<String, BigDecimal[]> rates = Map.of("EUR",
                new BigDecimal[]{new BigDecimal("400.00"), new BigDecimal("405.00")});

        byte[][] packets = encoder.encodeMultiDisplay(config, rates);

        assertThat(packets.length).isEqualTo(2);
        assertThat(packets[0]).isNotEqualTo(packets[1]);
    }

    // ---------- Helper ----------

    private LedDisplayConfig buildConfig(boolean speedCommand, int speed,
                                          String endMarkers, char decimalSeparator,
                                          LedSerialDisplayType type) {
        LedDisplayConfig config = new LedDisplayConfig();
        config.setSpeedCommand(speedCommand);
        config.setSpeed(speed);
        config.setEndMarkers(endMarkers);
        config.setDecimalSeparator(decimalSeparator);
        config.setSerialDisplayType(type);
        config.setCurrencies("EUR,USD,GBP,CHF");
        config.setComPorts("COM1");
        config.setShowBankCard(false);
        return config;
    }
}
