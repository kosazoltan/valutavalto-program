package hu.puzzleir.valuta.service.led;

import hu.puzzleir.valuta.entity.LedDisplayConfig;
import hu.puzzleir.valuta.entity.LedSerialDisplayType;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Map;

/**
 * LED kijelző bájt-szintű protokoll kódoló.
 *
 * 1:1 megfeleltés a legacy Delphi kóddal (METRO.DLL, TRUELIGHT.DLL, stb.).
 *
 * Protokoll szerkezete:
 * <pre>
 *   Init:   [21, 18, 5]                          (3 bájt, mindig)
 *   Speed:  [92('\'), 70('F'), 83('S'), 48+speed] (4 bájt, opcionális)
 *   Data:   ASCII karakterek                     (változó hosszú)
 *   End:    [254] vagy [254, 255]                 (1–2 bájt)
 * </pre>
 */
@Component
@Slf4j
public class LedProtocolEncoder {

    // Protokoll konstansok (legacy Delphi értékek)
    private static final byte INIT_1 = 21;
    private static final byte INIT_2 = 18;
    private static final byte INIT_3 = 5;
    private static final byte SPEED_BACKSLASH = 92;  // '\'
    private static final byte SPEED_F = 70;           // 'F'
    private static final byte SPEED_S = 83;           // 'S'
    private static final int  SPEED_BASE = 48;        // '0'

    // -------------------------------------------------------------------
    // Publikus API
    // -------------------------------------------------------------------

    /**
     * Árfolyam csomag kódolása.
     *
     * @param config konfiguráció (COM port, valuták, separator, stb.)
     * @param rates  valutakód → [vételi árfolyam, eladási árfolyam]
     * @return kész bájt tömb a soros portra küldéshez
     */
    public byte[] encodeRates(LedDisplayConfig config, Map<String, BigDecimal[]> rates) {
        try (ByteArrayOutputStream buf = new ByteArrayOutputStream()) {
            writeInit(buf);
            if (config.isSpeedCommand()) {
                writeSpeed(buf, config.getSpeed());
            }
            writeRateData(buf, config, rates);
            writeEndMarkers(buf, config.getEndMarkerBytes());
            return buf.toByteArray();
        } catch (IOException e) {
            log.error("Árfolyam csomag kódolási hiba", e);
            return new byte[0];
        }
    }

    /**
     * Szöveges csomag kódolása.
     *
     * @param config konfiguráció
     * @param text   küldendő szöveg
     * @return kész bájt tömb
     */
    public byte[] encodeText(LedDisplayConfig config, String text) {
        try (ByteArrayOutputStream buf = new ByteArrayOutputStream()) {
            writeInit(buf);
            if (config.isSpeedCommand()) {
                writeSpeed(buf, config.getSpeed());
            }
            if (text != null) {
                buf.write(text.getBytes());
            }
            writeEndMarkers(buf, config.getEndMarkerBytes());
            return buf.toByteArray();
        } catch (IOException e) {
            log.error("Szöveges csomag kódolási hiba", e);
            return new byte[0];
        }
    }

    /**
     * Több kijelzős csomag kódolása.
     *
     * <ul>
     *   <li>DUAL_SAME: mindkét csomag azonos árfolyam tartalom</li>
     *   <li>DUAL_DIFF: első csomag árfolyam, második csomag egyéni szöveg</li>
     *   <li>Egyéb típus: egyetlen csomag tömb egy elemmel</li>
     * </ul>
     *
     * @param config konfiguráció
     * @param rates  valutakód → [vételi, eladási]
     * @return bájt tömb tömb (indexe = COM port sorszáma)
     */
    public byte[][] encodeMultiDisplay(LedDisplayConfig config, Map<String, BigDecimal[]> rates) {
        LedSerialDisplayType type = config.getSerialDisplayType();
        if (type == null) {
            type = LedSerialDisplayType.STANDARD;
        }

        return switch (type) {
            case DUAL_SAME -> {
                byte[] packet = encodeRates(config, rates);
                yield new byte[][] { packet, packet };
            }
            case DUAL_DIFF -> {
                byte[] ratesPacket = encodeRates(config, rates);
                String secondText = config.getCustomText() != null
                        ? config.getCustomText()
                        : "CHANGE - WESTERN UNION";
                byte[] textPacket = encodeText(config, secondText);
                yield new byte[][] { ratesPacket, textPacket };
            }
            default -> new byte[][] { encodeRates(config, rates) };
        };
    }

    /**
     * Árfolyam formázása 6 karakteres, jobbra igazított mezőbe.
     *
     * Példák (decimalSeparator=','):
     * <pre>
     *   405.32  → "405,32"
     *    95.20  → " 95,20"
     *     3.75  → "  3,75"
     * </pre>
     *
     * @param rate              árfolyam érték
     * @param decimalSeparator  ',' vagy '.'
     * @return pontosan 6 karakter hosszú string
     */
    public String formatRate(BigDecimal rate, char decimalSeparator) {
        if (rate == null) return "      ";

        // Pontosan 2 tizedes jegy
        String formatted = rate.setScale(2, RoundingMode.HALF_UP).toPlainString();
        // Tizedes elválasztó csere
        if (decimalSeparator != '.') {
            formatted = formatted.replace('.', decimalSeparator);
        }
        // Jobbra igazítás, 6 karakter
        return String.format("%6s", formatted);
    }

    // -------------------------------------------------------------------
    // Belső segédmetódusok
    // -------------------------------------------------------------------

    /** Init bajt sorozat: [21, 18, 5] */
    private void writeInit(ByteArrayOutputStream buf) throws IOException {
        buf.write(INIT_1);
        buf.write(INIT_2);
        buf.write(INIT_3);
    }

    /** Sebesség parancs: [92, 70, 83, 48+speed] */
    private void writeSpeed(ByteArrayOutputStream buf, int speed) throws IOException {
        buf.write(SPEED_BACKSLASH);
        buf.write(SPEED_F);
        buf.write(SPEED_S);
        buf.write(SPEED_BASE + Math.min(9, Math.max(0, speed)));
    }

    /** Árfolyam adatok kiírása: "EUR 402,50 408,00 " formátumban */
    private void writeRateData(ByteArrayOutputStream buf,
                               LedDisplayConfig config,
                               Map<String, BigDecimal[]> rates) throws IOException {
        char sep = config.getDecimalSeparator();
        for (String currency : config.getCurrencyArray()) {
            BigDecimal[] pair = rates.get(currency);
            if (pair == null || pair.length < 2) {
                log.debug("Hiányzó árfolyam: {}", currency);
                continue;
            }
            String buyStr  = formatRate(pair[0], sep);
            String sellStr = formatRate(pair[1], sep);
            // Formátum: "EUR 402,50 408,00 "  (currency + space + buy + space + sell + space)
            buf.write((currency + " " + buyStr + " " + sellStr + " ").getBytes());
        }
        if (config.isShowBankCard()) {
            buf.write("BANKKARTYA ".getBytes());
        }
    }

    /** Záró bájtok kiírása */
    private void writeEndMarkers(ByteArrayOutputStream buf, int[] markers) throws IOException {
        for (int marker : markers) {
            buf.write(marker & 0xFF);
        }
    }
}
