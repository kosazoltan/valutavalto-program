package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.rate.ParsedCurrencyRate;
import hu.puzzleir.valuta.dto.rate.ParsedRateFile;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

/**
 * Legacy GETARF árfolyamfájl parser.
 *
 * A régi Delphi rendszer FTP-n keresztül töltött le árfolyamfájlt,
 * amelyben valutánként 9 különböző árfolyam-típus szerepelt.
 *
 * Fájlformátum (szöveges, pontosvesszővel elválasztott):
 * {@code CURRENCY_CODE;RATE1;RATE2;...;RATE9}
 *
 * Az árfolyamok egész számok, 100-zal szorozva (pl. 39850 = 398.50 HUF).
 * Kivétel: JPY árfolyamok 1000-rel vannak szorozva (mert az árfolyam egységára
 * 100 JPY-ra vonatkozik).
 *
 * Támogatott valuták (27 db):
 * EUR, USD, GBP, CHF, CZK, PLN, HRK, RON, RSD, BGN, TRY, RUB, UAH,
 * JPY, CAD, AUD, DKK, SEK, NOK, CNY, ILS, AED, THB, KRW, ZAR, NZD, HKD
 */
@Service
@Slf4j
public class RateFileParserService {

    /** A fájlban várt oszlopok száma: 1 (valutakód) + 9 (árfolyamok) = 10 */
    private static final int EXPECTED_COLUMN_COUNT = 10;

    /** Mezőelválasztó karakter */
    private static final String DELIMITER = ";";

    /** Az árfolyam szorzó alapértéke (legtöbb valutánál 100) */
    private static final BigDecimal STANDARD_DIVISOR = new BigDecimal("100");

    /** JPY árfolyam szorzó (1000, mert 100 JPY egységre vonatkozik) */
    private static final BigDecimal JPY_DIVISOR = new BigDecimal("1000");

    /** JPY valutakód */
    private static final String JPY_CODE = "JPY";

    /** Támogatott valuták halmaza */
    private static final Set<String> SUPPORTED_CURRENCIES = Set.of(
            "EUR", "USD", "GBP", "CHF", "CZK", "PLN", "HRK", "RON", "RSD", "BGN",
            "TRY", "RUB", "UAH", "JPY", "CAD", "AUD", "DKK", "SEK", "NOK", "CNY",
            "ILS", "AED", "THB", "KRW", "ZAR", "NZD", "HKD"
    );

    /**
     * Bináris tartalom feldolgozása (UTF-8 kódolás feltételezésével).
     *
     * @param content a fájl tartalma byte tömbként
     * @return feldolgozott árfolyamfájl
     */
    public ParsedRateFile parseRateFile(byte[] content) {
        if (content == null || content.length == 0) {
            log.warn("Üres árfolyamfájl érkezett");
            return ParsedRateFile.builder()
                    .rates(new ArrayList<>())
                    .parsedAt(LocalDateTime.now())
                    .parsedLineCount(0)
                    .skippedLineCount(0)
                    .build();
        }
        String text = new String(content, StandardCharsets.UTF_8);
        return parseRateFileFromString(text);
    }

    /**
     * Szöveges tartalom feldolgozása.
     *
     * Hibás sorokat kihagyja (logol), nem dob kivételt miattuk.
     *
     * @param content a fájl tartalma szövegként
     * @return feldolgozott árfolyamfájl
     */
    public ParsedRateFile parseRateFileFromString(String content) {
        if (content == null || content.isBlank()) {
            log.warn("Üres árfolyamfájl tartalom");
            return ParsedRateFile.builder()
                    .rates(new ArrayList<>())
                    .parsedAt(LocalDateTime.now())
                    .parsedLineCount(0)
                    .skippedLineCount(0)
                    .build();
        }

        List<ParsedCurrencyRate> rates = new ArrayList<>();
        int skippedCount = 0;

        String[] lines = content.split("\\r?\\n");
        for (int i = 0; i < lines.length; i++) {
            String line = lines[i].trim();
            if (line.isEmpty()) {
                continue; // üres sorokat egyszerűen kihagyjuk, nem számoljuk hibásnak
            }

            try {
                ParsedCurrencyRate rate = parseLine(line, i + 1);
                if (rate != null) {
                    rates.add(rate);
                } else {
                    skippedCount++;
                }
            } catch (Exception e) {
                log.warn("Hibás sor a(z) {} sorban: '{}' — {}", i + 1, line, e.getMessage());
                skippedCount++;
            }
        }

        log.info("Árfolyamfájl feldolgozva: {} valuta sikeresen, {} sor kihagyva",
                rates.size(), skippedCount);

        return ParsedRateFile.builder()
                .rates(rates)
                .parsedAt(LocalDateTime.now())
                .parsedLineCount(rates.size())
                .skippedLineCount(skippedCount)
                .build();
    }

    /**
     * Egy sor feldolgozása.
     *
     * @param line      a sor tartalma
     * @param lineNumber sorszám (logoláshoz)
     * @return feldolgozott valutaárfolyam, vagy null ha a sor kihagyandó
     */
    private ParsedCurrencyRate parseLine(String line, int lineNumber) {
        String[] parts = line.split(DELIMITER, -1);

        if (parts.length < EXPECTED_COLUMN_COUNT) {
            log.warn("Túl kevés oszlop a(z) {} sorban: {} (elvárt: {})",
                    lineNumber, parts.length, EXPECTED_COLUMN_COUNT);
            return null;
        }

        String currencyCode = parts[0].trim().toUpperCase();

        if (!SUPPORTED_CURRENCIES.contains(currencyCode)) {
            log.warn("Ismeretlen valutakód a(z) {} sorban: '{}'", lineNumber, currencyCode);
            return null;
        }

        BigDecimal divisor = JPY_CODE.equals(currencyCode) ? JPY_DIVISOR : STANDARD_DIVISOR;

        BigDecimal[] rateValues = new BigDecimal[9];
        for (int i = 0; i < 9; i++) {
            rateValues[i] = parseRateValue(parts[i + 1].trim(), divisor);
        }

        return ParsedCurrencyRate.builder()
                .currencyCode(currencyCode)
                .buyRate(rateValues[0])
                .sellRate(rateValues[1])
                .mnbRate(rateValues[2])
                .discountBuy(rateValues[3])
                .discountSell(rateValues[4])
                .f1Buy(rateValues[5])
                .f1Sell(rateValues[6])
                .chiefTreasurerBuy(rateValues[7])
                .chiefTreasurerSell(rateValues[8])
                .build();
    }

    /**
     * Egész szám formátumú árfolyam átváltása BigDecimal-re.
     *
     * A fájlban az érték 100-zal (JPY: 1000-rel) szorozva van tárolva.
     * Pl. 39850 → 398.50 HUF (EUR esetén)
     *     2860 → 2.860 HUF (JPY esetén, 100 JPY-ra)
     *
     * Ha az érték 0, BigDecimal.ZERO-t ad vissza.
     *
     * @param rawValue az egész szám szövegként
     * @param divisor  a szorzó (100 vagy 1000)
     * @return a tényleges árfolyam érték
     */
    private BigDecimal parseRateValue(String rawValue, BigDecimal divisor) {
        if (rawValue.isEmpty() || "0".equals(rawValue)) {
            return BigDecimal.ZERO;
        }
        BigDecimal intValue = new BigDecimal(rawValue);
        return intValue.divide(divisor, 4, RoundingMode.HALF_UP);
    }
}
