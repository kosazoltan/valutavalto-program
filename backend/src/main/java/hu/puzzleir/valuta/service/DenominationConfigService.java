package hu.puzzleir.valuta.service;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Címlet konfiguráció szolgáltatás.
 *
 * A legacy rendszer a {@code c:\valuta\cimlet.cfg} fájlból olvasta a címleteket.
 * Az új rendszerben in-memory konfiguráció, amit a DB-ből is lehet tölteni.
 *
 * 27 valutanem teljes bankjegy/érme címlet definíciója.
 */
@Service
@Slf4j
public class DenominationConfigService {

    /**
     * Címlet konfigurációs rekord.
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DenominationConfig {
        private String currencyCode;
        private BigDecimal faceValue;
        private String type; // "BANKNOTE" or "COIN"
        private String label; // human-readable label, e.g. "500 Ft bankjegy"
    }

    // ── Valuta → címletek leképezés ──────────────────────────────────────
    private static final Map<String, List<DenominationConfig>> DENOMINATION_MAP;

    static {
        DENOMINATION_MAP = new LinkedHashMap<>();

        // HUF — Magyar forint
        addDenominations("HUF",
                banknotes("20000", "10000", "5000", "2000", "1000", "500", "200"),
                coins("100", "50", "20", "10", "5"));

        // EUR — Euró
        addDenominations("EUR",
                banknotes("500", "200", "100", "50", "20", "10", "5"),
                coins("2", "1", "0.50", "0.20", "0.10", "0.05", "0.02", "0.01"));

        // USD — Amerikai dollár
        addDenominations("USD",
                banknotes("100", "50", "20", "10", "5", "2", "1"),
                coins("1", "0.50", "0.25", "0.10", "0.05", "0.01"));

        // GBP — Angol font
        addDenominations("GBP",
                banknotes("50", "20", "10", "5"),
                coins("2", "1", "0.50", "0.20", "0.10", "0.05", "0.02", "0.01"));

        // CHF — Svájci frank
        addDenominations("CHF",
                banknotes("1000", "200", "100", "50", "20", "10"),
                coins("5", "2", "1", "0.50", "0.20", "0.10", "0.05"));

        // CZK — Cseh korona
        addDenominations("CZK",
                banknotes("5000", "2000", "1000", "500", "200", "100"),
                coins("50", "20", "10", "5", "2", "1"));

        // PLN — Lengyel zloty
        addDenominations("PLN",
                banknotes("500", "200", "100", "50", "20", "10"),
                coins("5", "2", "1", "0.50", "0.20", "0.10", "0.05", "0.02", "0.01"));

        // RON — Román lej
        addDenominations("RON",
                banknotes("500", "200", "100", "50", "10", "5", "1"),
                coins("0.50", "0.10", "0.05", "0.01"));

        // HRK — Horvát kuna (történelmi, EUR-ra váltott, de legacy támogatás)
        addDenominations("HRK",
                banknotes("1000", "500", "200", "100", "50", "20", "10"),
                coins("5", "2", "1", "0.50", "0.20", "0.10", "0.05"));

        // RSD — Szerb dinár
        addDenominations("RSD",
                banknotes("5000", "2000", "1000", "500", "200", "100", "50", "20", "10"),
                coins("20", "10", "5", "2", "1"));

        // UAH — Ukrán hrivnya
        addDenominations("UAH",
                banknotes("1000", "500", "200", "100", "50", "20", "10"),
                coins("10", "5", "2", "1", "0.50", "0.25", "0.10"));

        // TRY — Török líra
        addDenominations("TRY",
                banknotes("200", "100", "50", "20", "10", "5"),
                coins("1", "0.50", "0.25", "0.10", "0.05"));

        // SEK — Svéd korona
        addDenominations("SEK",
                banknotes("1000", "500", "200", "100", "50", "20"),
                coins("10", "5", "2", "1"));

        // NOK — Norvég korona
        addDenominations("NOK",
                banknotes("1000", "500", "200", "100", "50"),
                coins("20", "10", "5", "1"));

        // DKK — Dán korona
        addDenominations("DKK",
                banknotes("1000", "500", "200", "100", "50"),
                coins("20", "10", "5", "2", "1", "0.50"));

        // BGN — Bolgár leva
        addDenominations("BGN",
                banknotes("100", "50", "20", "10", "5", "2"),
                coins("1", "0.50", "0.20", "0.10", "0.05", "0.02", "0.01"));

        // BAM — Bosnyák márka
        addDenominations("BAM",
                banknotes("200", "100", "50", "20", "10", "5"),
                coins("2", "1", "0.50", "0.20", "0.10", "0.05"));

        // RUB — Orosz rubel
        addDenominations("RUB",
                banknotes("5000", "2000", "1000", "500", "200", "100", "50"),
                coins("10", "5", "2", "1", "0.50", "0.10"));

        // JPY — Japán jen
        addDenominations("JPY",
                banknotes("10000", "5000", "2000", "1000"),
                coins("500", "100", "50", "10", "5", "1"));

        // CAD — Kanadai dollár
        addDenominations("CAD",
                banknotes("100", "50", "20", "10", "5"),
                coins("2", "1", "0.25", "0.10", "0.05", "0.01"));

        // AUD — Ausztrál dollár
        addDenominations("AUD",
                banknotes("100", "50", "20", "10", "5"),
                coins("2", "1", "0.50", "0.20", "0.10", "0.05"));

        // NZD — Új-zélandi dollár
        addDenominations("NZD",
                banknotes("100", "50", "20", "10", "5"),
                coins("2", "1", "0.50", "0.20", "0.10"));

        // CNY — Kínai jüan
        addDenominations("CNY",
                banknotes("100", "50", "20", "10", "5", "1"),
                coins("1", "0.50", "0.10", "0.05", "0.02", "0.01"));

        // ILS — Izraeli sékel
        addDenominations("ILS",
                banknotes("200", "100", "50", "20"),
                coins("10", "5", "2", "1", "0.50", "0.10"));

        // MXN — Mexikói peso
        addDenominations("MXN",
                banknotes("1000", "500", "200", "100", "50", "20"),
                coins("10", "5", "2", "1", "0.50", "0.20", "0.10"));

        // THB — Thai baht
        addDenominations("THB",
                banknotes("1000", "500", "100", "50", "20"),
                coins("10", "5", "2", "1", "0.50", "0.25"));

        // BRL — Brazil real
        addDenominations("BRL",
                banknotes("200", "100", "50", "20", "10", "5", "2"),
                coins("1", "0.50", "0.25", "0.10", "0.05"));
    }

    // ── Helper: címlet lista összeállítás ────────────────────────────────

    private static List<BigDecimal> banknotes(String... values) {
        return Arrays.stream(values).map(BigDecimal::new).collect(Collectors.toList());
    }

    private static List<BigDecimal> coins(String... values) {
        return Arrays.stream(values).map(BigDecimal::new).collect(Collectors.toList());
    }

    private static void addDenominations(String currencyCode,
                                          List<BigDecimal> banknoteValues,
                                          List<BigDecimal> coinValues) {
        List<DenominationConfig> configs = new ArrayList<>();

        for (BigDecimal val : banknoteValues) {
            configs.add(DenominationConfig.builder()
                    .currencyCode(currencyCode)
                    .faceValue(val)
                    .type("BANKNOTE")
                    .label(val.stripTrailingZeros().toPlainString() + " " + currencyCode + " bankjegy")
                    .build());
        }
        for (BigDecimal val : coinValues) {
            configs.add(DenominationConfig.builder()
                    .currencyCode(currencyCode)
                    .faceValue(val)
                    .type("COIN")
                    .label(val.stripTrailingZeros().toPlainString() + " " + currencyCode + " érme")
                    .build());
        }

        // Csökkenő sorrend (nagyobb címlet előre)
        configs.sort((a, b) -> b.getFaceValue().compareTo(a.getFaceValue()));

        DENOMINATION_MAP.put(currencyCode, Collections.unmodifiableList(configs));
    }

    // ── Publikus szolgáltatások ─────────────────────────────────────────

    /**
     * Lekérdezi az adott valutanem összes lehetséges címletét.
     *
     * @param currencyCode ISO 4217 valutakód (pl. "EUR", "HUF")
     * @return címlet lista csökkenő sorrendben, üres lista ha ismeretlen valuta
     */
    public List<DenominationConfig> getDenominations(String currencyCode) {
        if (currencyCode == null) {
            return Collections.emptyList();
        }
        return DENOMINATION_MAP.getOrDefault(currencyCode.toUpperCase(), Collections.emptyList());
    }

    /**
     * Ellenőrzi, hogy egy adott összeg érvényes címlet-e az adott valutához.
     *
     * @param currencyCode ISO 4217 valutakód
     * @param amount       ellenőrizendő összeg
     * @return true ha az összeg egy létező címlet
     */
    public boolean validateDenomination(String currencyCode, BigDecimal amount) {
        if (currencyCode == null || amount == null) {
            return false;
        }

        List<DenominationConfig> configs = getDenominations(currencyCode);
        return configs.stream()
                .anyMatch(c -> c.getFaceValue().compareTo(amount) == 0);
    }

    /**
     * Optimális visszajáró/címlet kiadás számítása — greedy algoritmus.
     * Legnagyobb címlettől indul lefelé, mindig a lehető legtöbbet adja.
     *
     * @param currencyCode ISO 4217 valutakód
     * @param amount       kiadandó összeg
     * @return Map: címletérték → darabszám (csökkenő sorrendben)
     * @throws IllegalArgumentException ha az összeg negatív
     */
    public Map<BigDecimal, Integer> getOptimalChange(String currencyCode, BigDecimal amount) {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("Az összeg nem lehet negatív: " + amount);
        }

        Map<BigDecimal, Integer> result = new LinkedHashMap<>();
        List<DenominationConfig> configs = getDenominations(currencyCode);

        if (configs.isEmpty() || amount.compareTo(BigDecimal.ZERO) == 0) {
            return result;
        }

        BigDecimal remaining = amount;

        for (DenominationConfig config : configs) {
            BigDecimal faceValue = config.getFaceValue();

            // HIGH FIX #1: faceValue null guard — NPE megelőzés címletezésnél
            if (faceValue != null && faceValue.compareTo(BigDecimal.ZERO) > 0 && remaining.compareTo(faceValue) >= 0) {
                int count = remaining.divideToIntegralValue(faceValue).intValue();

                if (count > 0) {
                    result.put(faceValue, count);
                    remaining = remaining.subtract(faceValue.multiply(BigDecimal.valueOf(count)));
                }
            }

            if (remaining.compareTo(BigDecimal.ZERO) == 0) {
                break;
            }
        }

        if (remaining.compareTo(BigDecimal.ZERO) > 0) {
            log.warn("Nem sikerült teljes címletezés: {} {} maradék {} {} összegből",
                    remaining, currencyCode, amount, currencyCode);
        }

        return result;
    }

    /**
     * Támogatott valuták listája (amelyekhez van címlet konfiguráció).
     *
     * @return valutakódok halmaza
     */
    public Set<String> getSupportedCurrencies() {
        return Collections.unmodifiableSet(DENOMINATION_MAP.keySet());
    }

    /**
     * Van-e címlet konfiguráció az adott valutához.
     *
     * @param currencyCode ISO 4217 valutakód
     * @return true ha van konfiguráció
     */
    public boolean isCurrencySupported(String currencyCode) {
        if (currencyCode == null) {
            return false;
        }
        return DENOMINATION_MAP.containsKey(currencyCode.toUpperCase());
    }

    /**
     * Csak bankjegy címletek lekérdezése.
     */
    public List<DenominationConfig> getBanknotes(String currencyCode) {
        return getDenominations(currencyCode).stream()
                .filter(c -> "BANKNOTE".equals(c.getType()))
                .collect(Collectors.toList());
    }

    /**
     * Csak érme címletek lekérdezése.
     */
    public List<DenominationConfig> getCoins(String currencyCode) {
        return getDenominations(currencyCode).stream()
                .filter(c -> "COIN".equals(c.getType()))
                .collect(Collectors.toList());
    }
}
