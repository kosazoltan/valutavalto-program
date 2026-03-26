package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.MnbExchangeRateCache;
import hu.puzzleir.valuta.repository.MnbExchangeRateCacheRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

/**
 * Raiffeisen Bank devizaközép árfolyam szolgáltatás.
 *
 * Devizaárfolyamok scraping a Raiffeisen weboldalról.
 * A devizaközép (middle) értéket menti az mnb_exchange_rate_cache táblába
 * RAIFFEISEN forrás megjelöléssel.
 *
 * URL: https://www.raiffeisen.hu/hasznos/arfolyamok/lakossagi/devizaarfolyamok-...
 * Struktúra: valutánként buy | middle | sell
 * JPY: 100 egységre adják → DB-ben 1 egységre normalizáljuk.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class RaiffeisenRateService {

    private static final String RAIFFEISEN_URL =
            "https://www.raiffeisen.hu/hasznos/arfolyamok/lakossagi/"
            + "deviza%C3%A1rfolyamok-bej%C3%B6v%C5%91-%C3%A9s-bankon-bel%C3%BCli-"
            + "%C3%A1tutal%C3%A1si-tranzakci%C3%B3k-elsz%C3%A1mol%C3%A1s%C3%A1hoz";

    private static final String SOURCE = "RAIFFEISEN";
    private static final int TIMEOUT_MS = 15_000;

    /**
     * A támogatott valuták listája (a Raiffeisen oldalon elérhető devizák).
     * HUF-ot kiszűrjük, mert az mindig 1.00.
     */
    private static final Set<String> SUPPORTED_CURRENCIES = Set.of(
            "AUD", "CAD", "CHF", "CZK", "DKK", "EUR", "GBP",
            "JPY", "NOK", "PLN", "RON", "SEK", "TRY", "USD"
    );

    /** Sanity bounds — normalizált (unit=1) HUF árfolyam tartomány per valuta */
    private static final Map<String, BigDecimal[]> SANITY_BOUNDS = Map.ofEntries(
            Map.entry("EUR", new BigDecimal[]{new BigDecimal("300"), new BigDecimal("500")}),
            Map.entry("USD", new BigDecimal[]{new BigDecimal("250"), new BigDecimal("450")}),
            Map.entry("GBP", new BigDecimal[]{new BigDecimal("350"), new BigDecimal("600")}),
            Map.entry("CHF", new BigDecimal[]{new BigDecimal("300"), new BigDecimal("550")}),
            Map.entry("JPY", new BigDecimal[]{new BigDecimal("1"), new BigDecimal("5")}),
            Map.entry("CZK", new BigDecimal[]{new BigDecimal("10"), new BigDecimal("25")}),
            Map.entry("PLN", new BigDecimal[]{new BigDecimal("60"), new BigDecimal("130")}),
            Map.entry("RON", new BigDecimal[]{new BigDecimal("60"), new BigDecimal("110")})
    );

    private final MnbExchangeRateCacheRepository cacheRepository;

    // ============ PUBLIKUS API ============

    /**
     * Raiffeisen devizaközép árfolyamok letöltése és cache-elése.
     *
     * @return letöltött árfolyamok száma
     */
    @Transactional(rollbackFor = Exception.class)
    public int fetchAndCacheRates() {
        LocalDate today = LocalDate.now();
        log.info("Raiffeisen devizaközép árfolyamok letöltése: {}", today);

        Map<String, RaiffeisenRate> scraped;
        try {
            scraped = scrapeRates();
        } catch (Exception e) {
            log.error("Raiffeisen scraping sikertelen: {} — fallback: meglévő cache marad érintetlen", e.getMessage());
            return 0;
        }

        if (scraped.isEmpty()) {
            log.warn("Raiffeisen scraping: üres eredmény — meglévő cache marad érintetlen");
            return 0;
        }

        int saved = 0;
        for (Map.Entry<String, RaiffeisenRate> entry : scraped.entrySet()) {
            String currencyCode = entry.getKey();
            RaiffeisenRate rate = entry.getValue();

            try {
                BigDecimal middle = rate.middleRate();
                log.debug("Raiffeisen scraped: {} = {} (raw middle: {}, unit: {})",
                        currencyCode, middle, rate.rawMiddleRate(), rate.unit());

                // Sanity check
                if (!isSane(currencyCode, middle)) {
                    log.warn("Raiffeisen sanity FAIL: {} = {} — kihagyva", currencyCode, middle);
                    continue;
                }

                saveRate(currencyCode, middle, today);
                saved++;
            } catch (Exception e) {
                log.warn("Raiffeisen rate mentési hiba: {} — {}", currencyCode, e.getMessage());
            }
        }

        log.info("Raiffeisen árfolyamok cache-elve: {}/{} valuta", saved, scraped.size());
        return saved;
    }

    /**
     * Raiffeisen devizaközép árfolyamok lekérése (cache-ből).
     * Ha nincs mai adat, a legutolsót adja vissza.
     */
    @Transactional(readOnly = true)
    public Map<String, MnbExchangeRateCache> getRates(LocalDate date) {
        // Először pontos dátumra
        List<MnbExchangeRateCache> cached = cacheRepository.findByRateDateAndSource(date, SOURCE);
        if (!cached.isEmpty()) {
            return toMap(cached);
        }

        // Fallback: legutolsó elérhető
        List<MnbExchangeRateCache> fallback = cacheRepository.findLatestRatesBySource(date, SOURCE);
        if (!fallback.isEmpty()) {
            log.info("Raiffeisen fallback: legutolsó cache (date={}, fallbackDate={})",
                    date, fallback.get(0).getRateDate());
        }
        return toMap(fallback);
    }

    // ============ SCRAPING LOGIKA ============

    /**
     * Raiffeisen oldal HTML scraping.
     * A táblázatból kinyeri: valutakód, egység, buy, middle, sell értékeket.
     */
    Map<String, RaiffeisenRate> scrapeRates() throws Exception {
        Document doc = Jsoup.connect(RAIFFEISEN_URL)
                .timeout(TIMEOUT_MS)
                .userAgent("ValutavaltoERP/1.0")
                .get();

        Map<String, RaiffeisenRate> result = new LinkedHashMap<>();

        // A Raiffeisen oldal táblázatsorokat tartalmaz valutánként
        // A web_fetch alapján a struktúra: CODE, name, unit, buy, middle, sell
        // Keressük a táblázat sorait
        Elements tables = doc.select("table");
        for (Element table : tables) {
            Elements rows = table.select("tr");
            for (Element row : rows) {
                Elements cells = row.select("td");
                if (cells.size() < 4) continue;

                try {
                    parseRow(cells, result);
                } catch (Exception e) {
                    // Skip unparseable rows silently
                }
            }
        }

        // Ha nincs táblázat, próbáljunk szöveges parsing-et (fallback)
        if (result.isEmpty()) {
            log.info("Raiffeisen: táblázat nem található, szöveges parsing...");
            parseFromText(doc.text(), result);
        }

        return result;
    }

    /**
     * Táblázat sor feldolgozása.
     */
    private void parseRow(Elements cells, Map<String, RaiffeisenRate> result) {
        // Keresünk egy cellát ami 3 betűs valutakód
        for (int i = 0; i < cells.size(); i++) {
            String cellText = cells.get(i).text().trim().toUpperCase();
            if (cellText.length() == 3 && SUPPORTED_CURRENCIES.contains(cellText)) {
                String code = cellText;

                // A cellák sorrendje a kód után: (esetleg név), unit, buy, middle, sell
                // Gyűjtsük össze a számokat a sorból
                List<BigDecimal> numbers = new ArrayList<>();
                for (int j = i + 1; j < cells.size(); j++) {
                    String val = cells.get(j).text().trim().replace(",", ".").replaceAll("[^0-9.]", "");
                    if (!val.isEmpty()) {
                        try {
                            numbers.add(new BigDecimal(val));
                        } catch (NumberFormatException ignored) {
                        }
                    }
                }

                // Elvárt: unit, buy, middle, sell (4 szám) VAGY buy, middle, sell (3 szám)
                if (numbers.size() >= 4) {
                    int unit = numbers.get(0).intValue();
                    BigDecimal middle = numbers.get(2); // 3rd number = middle
                    BigDecimal normalizedMiddle = normalizeRate(code, middle, unit);
                    result.put(code, new RaiffeisenRate(code, unit, numbers.get(1), middle, numbers.get(3), normalizedMiddle));
                } else if (numbers.size() >= 3) {
                    BigDecimal middle = numbers.get(1); // 2nd number = middle
                    BigDecimal normalizedMiddle = normalizeRate(code, middle, 1);
                    result.put(code, new RaiffeisenRate(code, 1, numbers.get(0), middle, numbers.get(2), normalizedMiddle));
                }
                break; // Found currency in this row
            }
        }
    }

    /**
     * Szöveges feldolgozás fallback — ha a táblázat parsing nem sikerült.
     * A Raiffeisen oldalon a devizaadatok szövegként is olvashatók:
     * "EUR ... 1 379.18 388.90 398.62"
     */
    private void parseFromText(String fullText, Map<String, RaiffeisenRate> result) {
        // Normalizáljuk a szóközöket
        String text = fullText.replaceAll("\\s+", " ");

        for (String code : SUPPORTED_CURRENCIES) {
            int idx = text.indexOf(code);
            if (idx < 0) continue;

            // Keressünk számokat a valutakód után
            String after = text.substring(idx + code.length());
            List<BigDecimal> numbers = extractNumbers(after, 5);

            // Elvárt: unit, buy, middle, sell
            if (numbers.size() >= 4) {
                int unit = numbers.get(0).intValue();
                BigDecimal middle = numbers.get(2);
                BigDecimal normalizedMiddle = normalizeRate(code, middle, unit);
                result.put(code, new RaiffeisenRate(code, unit, numbers.get(1), middle, numbers.get(3), normalizedMiddle));
            }
        }
    }

    /**
     * Számok kinyerése szövegből (max count darab).
     */
    private List<BigDecimal> extractNumbers(String text, int maxCount) {
        List<BigDecimal> numbers = new ArrayList<>();
        // Match numbers like 379.18, 1, 100, etc.
        java.util.regex.Matcher m = java.util.regex.Pattern.compile("(\\d+\\.\\d+|\\d+)").matcher(text);
        while (m.find() && numbers.size() < maxCount) {
            try {
                numbers.add(new BigDecimal(m.group(1)));
            } catch (NumberFormatException ignored) {
            }
        }
        return numbers;
    }

    /**
     * JPY normalizálás: ha unit=100, az árfolyamot 100-zal elosztjuk,
     * mert a DB-ben unit=1 egységre vetített értékeket tárolunk.
     */
    private BigDecimal normalizeRate(String currencyCode, BigDecimal rate, int unit) {
        if (unit > 1) {
            return rate.divide(BigDecimal.valueOf(unit), 4, RoundingMode.HALF_UP);
        }
        return rate;
    }

    /**
     * Sanity check: a normalizált (unit=1) árfolyam ésszerű tartományban van-e.
     * Ha nincs a SANITY_BOUNDS-ban a valuta, csak pozitív értéket ellenőriz.
     */
    private boolean isSane(String currencyCode, BigDecimal rate) {
        if (rate == null || rate.compareTo(BigDecimal.ZERO) <= 0) return false;
        BigDecimal[] bounds = SANITY_BOUNDS.get(currencyCode);
        if (bounds == null) return true; // Nincs bound definiálva → csak pozitív elég
        return rate.compareTo(bounds[0]) >= 0 && rate.compareTo(bounds[1]) <= 0;
    }

    // ============ CACHE MENTÉS ============

    private void saveRate(String currencyCode, BigDecimal normalizedMiddleRate, LocalDate date) {
        cacheRepository.findByCurrencyCodeAndRateDateAndSource(currencyCode, date, SOURCE)
                .ifPresentOrElse(
                        existing -> {
                            existing.setOfficialRate(normalizedMiddleRate);
                            existing.setUnit(1); // Mindig 1-re normalizálva tároljuk
                            existing.setSource(SOURCE);
                            existing.setFetchedAt(LocalDateTime.now());
                            cacheRepository.save(existing);
                        },
                        () -> {
                            MnbExchangeRateCache newEntry = MnbExchangeRateCache.builder()
                                    .currencyCode(currencyCode)
                                    .rateDate(date)
                                    .officialRate(normalizedMiddleRate)
                                    .unit(1)
                                    .source(SOURCE)
                                    .fetchedAt(LocalDateTime.now())
                                    .build();
                            cacheRepository.save(newEntry);
                        }
                );
    }

    // ============ SEGÉDMETÓDUSOK ============

    private Map<String, MnbExchangeRateCache> toMap(List<MnbExchangeRateCache> list) {
        Map<String, MnbExchangeRateCache> map = new LinkedHashMap<>();
        for (MnbExchangeRateCache rate : list) {
            map.put(rate.getCurrencyCode(), rate);
        }
        return map;
    }

    /**
     * Belső DTO a scraped adatokhoz.
     */
    record RaiffeisenRate(
            String currencyCode,
            int unit,
            BigDecimal buyRate,
            BigDecimal rawMiddleRate,
            BigDecimal sellRate,
            BigDecimal middleRate // unit=1-re normalizált
    ) {}
}
