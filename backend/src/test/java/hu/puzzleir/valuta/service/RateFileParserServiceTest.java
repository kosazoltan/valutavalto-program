package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.rate.ParsedCurrencyRate;
import hu.puzzleir.valuta.dto.rate.ParsedRateFile;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;

import static org.assertj.core.api.Assertions.*;

/**
 * RateFileParserService UNIT tesztek.
 *
 * A legacy GETARF fájl parser logikáját teszteli — nincs mock dependency.
 */
class RateFileParserServiceTest {

    private final RateFileParserService service = new RateFileParserService();

    @Test
    @DisplayName("Érvényes fájl feldolgozása — EUR és USD")
    void testParseValidFile() {
        // EUR: buy=39500 (395.00), sell=40100 (401.00), mnb=39800 (398.00), stb.
        // USD: buy=35000 (350.00), sell=36000 (360.00), mnb=35500 (355.00), stb.
        String content = "EUR;39500;40100;39800;39600;40000;39550;40050;39450;40150\n"
                + "USD;35000;36000;35500;35100;35900;35200;35800;35050;35950\n";

        ParsedRateFile result = service.parseRateFileFromString(content);

        assertThat(result.getRates()).hasSize(2);
        assertThat(result.getParsedLineCount()).isEqualTo(2);
        assertThat(result.getSkippedLineCount()).isEqualTo(0);
        assertThat(result.getParsedAt()).isNotNull();

        // EUR ellenorzese
        ParsedCurrencyRate eur = result.findByCurrencyCode("EUR").orElseThrow();
        assertThat(eur.getCurrencyCode()).isEqualTo("EUR");
        assertThat(eur.getBuyRate()).isEqualByComparingTo(new BigDecimal("395.00"));
        assertThat(eur.getSellRate()).isEqualByComparingTo(new BigDecimal("401.00"));
        assertThat(eur.getMnbRate()).isEqualByComparingTo(new BigDecimal("398.00"));
        assertThat(eur.getDiscountBuy()).isEqualByComparingTo(new BigDecimal("396.00"));
        assertThat(eur.getDiscountSell()).isEqualByComparingTo(new BigDecimal("400.00"));
        assertThat(eur.getF1Buy()).isEqualByComparingTo(new BigDecimal("395.50"));
        assertThat(eur.getF1Sell()).isEqualByComparingTo(new BigDecimal("400.50"));
        assertThat(eur.getChiefTreasurerBuy()).isEqualByComparingTo(new BigDecimal("394.50"));
        assertThat(eur.getChiefTreasurerSell()).isEqualByComparingTo(new BigDecimal("401.50"));

        // USD ellenorzese
        ParsedCurrencyRate usd = result.findByCurrencyCode("USD").orElseThrow();
        assertThat(usd.getBuyRate()).isEqualByComparingTo(new BigDecimal("350.00"));
        assertThat(usd.getSellRate()).isEqualByComparingTo(new BigDecimal("360.00"));
    }

    @Test
    @DisplayName("JPY speciális kezelés — osztás 1000-rel")
    void testParseJpySpecialHandling() {
        // JPY: buy=2860 → 2.8600, sell=3020 → 3.0200, stb.
        String content = "JPY;2860;3020;2940;2880;3000;2900;2980;2850;3030\n";

        ParsedRateFile result = service.parseRateFileFromString(content);

        assertThat(result.getRates()).hasSize(1);

        ParsedCurrencyRate jpy = result.findByCurrencyCode("JPY").orElseThrow();
        assertThat(jpy.getBuyRate()).isEqualByComparingTo(new BigDecimal("2.8600"));
        assertThat(jpy.getSellRate()).isEqualByComparingTo(new BigDecimal("3.0200"));
        assertThat(jpy.getMnbRate()).isEqualByComparingTo(new BigDecimal("2.9400"));
        assertThat(jpy.getDiscountBuy()).isEqualByComparingTo(new BigDecimal("2.8800"));
        assertThat(jpy.getDiscountSell()).isEqualByComparingTo(new BigDecimal("3.0000"));
        assertThat(jpy.getF1Buy()).isEqualByComparingTo(new BigDecimal("2.9000"));
        assertThat(jpy.getF1Sell()).isEqualByComparingTo(new BigDecimal("2.9800"));
        assertThat(jpy.getChiefTreasurerBuy()).isEqualByComparingTo(new BigDecimal("2.8500"));
        assertThat(jpy.getChiefTreasurerSell()).isEqualByComparingTo(new BigDecimal("3.0300"));
    }

    @Test
    @DisplayName("Hiányzó valuták — nem minden 27 valuta van a fájlban")
    void testParseWithMissingCurrencies() {
        String content = "GBP;45000;46000;45500;45100;45900;45200;45800;45050;45950\n";

        ParsedRateFile result = service.parseRateFileFromString(content);

        assertThat(result.getRates()).hasSize(1);
        assertThat(result.findByCurrencyCode("GBP")).isPresent();
        assertThat(result.findByCurrencyCode("EUR")).isEmpty();
        assertThat(result.findByCurrencyCode("USD")).isEmpty();
    }

    @Test
    @DisplayName("Hibás sorok kihagyása — túl kevés oszlop")
    void testMalformedLineSkipped_tooFewColumns() {
        String content = "EUR;39500;40100\n"  // csak 3 oszlop — hibas
                + "USD;35000;36000;35500;35100;35900;35200;35800;35050;35950\n";

        ParsedRateFile result = service.parseRateFileFromString(content);

        assertThat(result.getRates()).hasSize(1);
        assertThat(result.getSkippedLineCount()).isEqualTo(1);
        assertThat(result.findByCurrencyCode("USD")).isPresent();
        assertThat(result.findByCurrencyCode("EUR")).isEmpty();
    }

    @Test
    @DisplayName("Hibás sorok kihagyása — nem szám az árfolyam")
    void testMalformedLineSkipped_invalidNumber() {
        String content = "EUR;ABC;40100;39800;39600;40000;39550;40050;39450;40150\n"
                + "USD;35000;36000;35500;35100;35900;35200;35800;35050;35950\n";

        ParsedRateFile result = service.parseRateFileFromString(content);

        assertThat(result.getRates()).hasSize(1);
        assertThat(result.getSkippedLineCount()).isEqualTo(1);
        assertThat(result.findByCurrencyCode("USD")).isPresent();
    }

    @Test
    @DisplayName("Ismeretlen valutakód kihagyása")
    void testUnknownCurrencySkipped() {
        String content = "XYZ;39500;40100;39800;39600;40000;39550;40050;39450;40150\n"
                + "EUR;39500;40100;39800;39600;40000;39550;40050;39450;40150\n";

        ParsedRateFile result = service.parseRateFileFromString(content);

        assertThat(result.getRates()).hasSize(1);
        assertThat(result.getSkippedLineCount()).isEqualTo(1);
        assertThat(result.findByCurrencyCode("EUR")).isPresent();
    }

    @Test
    @DisplayName("Üres fájl — üres lista")
    void testParseEmptyFile() {
        ParsedRateFile result = service.parseRateFileFromString("");

        assertThat(result.getRates()).isEmpty();
        assertThat(result.getParsedLineCount()).isEqualTo(0);
        assertThat(result.getSkippedLineCount()).isEqualTo(0);
    }

    @Test
    @DisplayName("Null tartalom — üres lista")
    void testParseNullContent() {
        ParsedRateFile result = service.parseRateFileFromString(null);

        assertThat(result.getRates()).isEmpty();
        assertThat(result.getParsedLineCount()).isEqualTo(0);
    }

    @Test
    @DisplayName("Null byte tömb — üres lista")
    void testParseNullByteArray() {
        ParsedRateFile result = service.parseRateFile(null);

        assertThat(result.getRates()).isEmpty();
    }

    @Test
    @DisplayName("Üres byte tömb — üres lista")
    void testParseEmptyByteArray() {
        ParsedRateFile result = service.parseRateFile(new byte[0]);

        assertThat(result.getRates()).isEmpty();
    }

    @Test
    @DisplayName("Byte tömb feldolgozás — UTF-8 kódolás")
    void testParseByteArray() {
        String content = "EUR;39500;40100;39800;39600;40000;39550;40050;39450;40150\n";
        byte[] bytes = content.getBytes(StandardCharsets.UTF_8);

        ParsedRateFile result = service.parseRateFile(bytes);

        assertThat(result.getRates()).hasSize(1);
        assertThat(result.findByCurrencyCode("EUR")).isPresent();
    }

    @Test
    @DisplayName("Üres sorok kihagyása — nem számít hibás sornak")
    void testEmptyLinesIgnored() {
        String content = "\n\nEUR;39500;40100;39800;39600;40000;39550;40050;39450;40150\n\n\n"
                + "USD;35000;36000;35500;35100;35900;35200;35800;35050;35950\n\n";

        ParsedRateFile result = service.parseRateFileFromString(content);

        assertThat(result.getRates()).hasSize(2);
        assertThat(result.getSkippedLineCount()).isEqualTo(0);
    }

    @Test
    @DisplayName("Windows sorvég (CRLF) kezelése")
    void testWindowsLineEndings() {
        String content = "EUR;39500;40100;39800;39600;40000;39550;40050;39450;40150\r\n"
                + "USD;35000;36000;35500;35100;35900;35200;35800;35050;35950\r\n";

        ParsedRateFile result = service.parseRateFileFromString(content);

        assertThat(result.getRates()).hasSize(2);
    }

    @Test
    @DisplayName("Nulla árfolyam — BigDecimal.ZERO")
    void testZeroRateValue() {
        String content = "EUR;39500;40100;0;0;0;0;0;0;0\n";

        ParsedRateFile result = service.parseRateFileFromString(content);

        ParsedCurrencyRate eur = result.findByCurrencyCode("EUR").orElseThrow();
        assertThat(eur.getBuyRate()).isEqualByComparingTo(new BigDecimal("395.00"));
        assertThat(eur.getSellRate()).isEqualByComparingTo(new BigDecimal("401.00"));
        assertThat(eur.getMnbRate()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(eur.getDiscountBuy()).isEqualByComparingTo(BigDecimal.ZERO);
    }

    @Test
    @DisplayName("Kisbetűs valutakód — nagybetűsre konvertálva")
    void testLowercaseCurrencyCode() {
        String content = "eur;39500;40100;39800;39600;40000;39550;40050;39450;40150\n";

        ParsedRateFile result = service.parseRateFileFromString(content);

        assertThat(result.getRates()).hasSize(1);
        assertThat(result.findByCurrencyCode("EUR")).isPresent();
    }

    @Test
    @DisplayName("Mind a 27 támogatott valuta feldolgozása")
    void testAllSupportedCurrencies() {
        String[] currencies = {
                "EUR", "USD", "GBP", "CHF", "CZK", "PLN", "HRK", "RON", "RSD", "BGN",
                "TRY", "RUB", "UAH", "JPY", "CAD", "AUD", "DKK", "SEK", "NOK", "CNY",
                "ILS", "AED", "THB", "KRW", "ZAR", "NZD", "HKD"
        };

        StringBuilder sb = new StringBuilder();
        for (String code : currencies) {
            sb.append(code).append(";10000;11000;10500;10100;10900;10200;10800;10050;10950\n");
        }

        ParsedRateFile result = service.parseRateFileFromString(sb.toString());

        assertThat(result.getRates()).hasSize(27);
        assertThat(result.getSkippedLineCount()).isEqualTo(0);

        for (String code : currencies) {
            assertThat(result.findByCurrencyCode(code)).isPresent();
        }
    }

    @Test
    @DisplayName("Több oszlop mint az elvárt — extra oszlopok figyelmen kívül hagyva")
    void testExtraColumnsIgnored() {
        String content = "EUR;39500;40100;39800;39600;40000;39550;40050;39450;40150;99999;88888\n";

        ParsedRateFile result = service.parseRateFileFromString(content);

        assertThat(result.getRates()).hasSize(1);
        ParsedCurrencyRate eur = result.findByCurrencyCode("EUR").orElseThrow();
        assertThat(eur.getBuyRate()).isEqualByComparingTo(new BigDecimal("395.00"));
    }
}
