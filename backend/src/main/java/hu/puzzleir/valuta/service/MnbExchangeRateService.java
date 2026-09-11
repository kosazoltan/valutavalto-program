package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.MnbExchangeRateCache;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.MnbExchangeRateCacheRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.*;
import org.xml.sax.InputSource;

import java.io.StringReader;
import java.math.BigDecimal;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

/**
 * MNB (Magyar Nemzeti Bank) hivatalos árfolyam szolgáltatás.
 *
 * SOAP/XML kliens az MNB napi középárfolyamok letöltéséhez.
 * Kizárólag a havi záráshoz szükséges — a készlet MNB árfolyamon történő
 * értékeléséhez.
 *
 * SOAP endpoint: https://www.mnb.hu/arfolyamok.asmx
 * WSDL: https://www.mnb.hu/arfolyamok.asmx?wsdl
 *
 * Elérhető műveletek:
 * - GetCurrentExchangeRates — aktuális napi árfolyamok
 * - GetExchangeRates — adott napra/intervallumra lekérdezés
 *
 * Legacy: ELSZAMOLASIARFOLYAM mező az ARFOLYAM táblában.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class MnbExchangeRateService {

    // Semgrep httpclient-http-request hardening: TLS-en kérjük az árfolyamot (MITM-védelem,
    // ráta-integritás). A HTTPS endpoint verifikálva (200 a ?wsdl-en). 2026-05-26.
    private static final String MNB_SOAP_URL = "https://www.mnb.hu/arfolyamok.asmx";
    private static final String SOAP_NAMESPACE = "http://www.mnb.hu/webservices/";

    /**
     * FKH-061 (WU-6): the settlement currency code. MNB does not quote it against itself, so it
     * must be excluded from the cache-completeness check.
     */
    private static final String SETTLEMENT_CURRENCY = "HUF";

    /**
     * FKH-061 (PR review): the cache table is shared with other rate sources — production holds
     * 698 RAIFFEISEN rows against 17 MNB rows, and the uniqueness key is
     * (currency_code, rate_date, source). Every read on the MNB path must be source-filtered,
     * otherwise a RAIFFEISEN row could make the MNB cache look complete or be returned as an MNB
     * rate, valuing decade-report stock from the wrong source.
     */
    private static final String MNB_SOURCE = "MNB";
    private static final Duration HTTP_TIMEOUT = Duration.ofSeconds(15);

    /**
     * FKH-061 (WU-6): egy adott dátumra ennyi ideig próbálkozunk újra hiányos cache esetén.
     * A dekádjelentés 7 napos walk-backje × az MNB által nem jegyzett valuták (BAM/BRL/EUA/
     * ILS/MXN/NZD/RSD/THB) különben minden lekérdezésnél SOAP-hívást indítanának — a TTL-map
     * dátumonként legfeljebb egy próbálkozásra korlátozza ezt.
     */
    private static final Duration SOAP_ATTEMPT_TTL = Duration.ofMinutes(30);
    /** A próbálkozás-map méretkorlátja; a legrégebbi bejegyzések kiesnek (size-cap eviction). */
    private static final int SOAP_ATTEMPT_MAP_CAP = 512;

    /** Dátumonkénti utolsó SOAP-próbálkozás időpontja (in-process, TTL-kezelt). */
    private final Map<LocalDate, Instant> soapAttempts = new ConcurrentHashMap<>();

    private final MnbExchangeRateCacheRepository cacheRepository;
    /** FKH-061 (WU-6): az aktív valuták listája a cache-teljesség vizsgálathoz. */
    private final CurrencyRepository currencyRepository;

    // ============ PUBLIKUS API ============

    /**
     * MNB árfolyamok lekérése adott napra.
     * Elsősorban cache-ből szolgál ki, ha nincs → MNB SOAP hívás.
     *
     * @param date a kért dátum
     * @return Map currencyCode → MnbExchangeRateCache
     */
    @Transactional(rollbackFor = Exception.class)
    public Map<String, MnbExchangeRateCache> getRatesForDate(LocalDate date) {
        // 1. Próbálunk pontos dátumra cache-ből kiszolgálni.
        // FKH-061 (WU-6): a nem üres cache még nem feltétlen TELJES — ha az aktív valuták
        // egy része hiányzik aznap (pl. csak AUD..TRY lett korábban lekérdezve, de EUR/USD/GBP
        // kellene), egyetlen korlátozott SOAP-próbálkozással kiegészítjük (TTL: dátumonként
        // legfeljebb egy letöltés), és az eredményt a cache FÖLÉ mergeljük. Sikertelen vagy
        // TTL-en belüli (elfojtott) próbálkozás esetén a cache-elt részleges map megy vissza —
        // sosem ürítjük ki.
        List<MnbExchangeRateCache> cached = cacheRepository.findByRateDateAndSource(date, MNB_SOURCE);
        if (!cached.isEmpty()) {
            Map<String, MnbExchangeRateCache> cachedMap = toMap(cached);
            if (isCacheComplete(cached)) {
                log.debug("MNB árfolyamok cache-ből: date={}, db={}", date, cached.size());
                return cachedMap;
            }
            if (shouldAttemptDownload(date)) {
                try {
                    Map<String, MnbExchangeRateCache> fetched = fetchAndCacheRates(date);
                    Map<String, MnbExchangeRateCache> merged = new LinkedHashMap<>(cachedMap);
                    merged.putAll(fetched);
                    log.info("MNB részleges cache kiegészítve: date={}, cache={}, letöltött={}, egyesített={}",
                            date, cachedMap.size(), fetched.size(), merged.size());
                    return merged;
                } catch (Exception e) {
                    log.warn("MNB SOAP hívás sikertelen részleges cache-nél (date={}): {} — cache-elt rész visszaadása",
                            date, e.getMessage());
                }
            } else {
                log.debug("MNB részleges cache (date={}) — a letöltési próbálkozás a TTL-en belül elfojtva", date);
            }
            return cachedMap;
        }

        // 2. SOAP letöltés
        // FKH-061 (PR review): the TTL bound applies to an EMPTY cache too. It previously
        // covered only partially cached dates, so a fully empty date (a weekend, or a date MNB
        // does not quote) would fire a fresh SOAP request on every call inside the decade
        // report's 7-day walk-back — exactly a breach of the one-attempt-per-date rule.
        if (shouldAttemptDownload(date)) {
            try {
                Map<String, MnbExchangeRateCache> fetched = fetchAndCacheRates(date);
                if (!fetched.isEmpty()) {
                    return fetched;
                }
            } catch (Exception e) {
                log.warn("MNB SOAP hívás sikertelen (date={}): {}", date, e.getMessage());
            }
        } else {
            log.debug("MNB üres cache (date={}) — a letöltési próbálkozás a TTL-en belül elfojtva", date);
        }

        // 3. Fallback: legutolsó elérhető cache-elt árfolyam
        // FKH-061 (PR review): source-filtered so the fallback cannot return a RAIFFEISEN rate
        // as an MNB rate (the decade report would value stock from the wrong source).
        List<MnbExchangeRateCache> fallback = cacheRepository.findLatestRatesBySource(date, MNB_SOURCE);
        if (!fallback.isEmpty()) {
            log.info("MNB fallback: a legutolsó cache-elt árfolyamok (date={}, fallbackDate={})",
                    date, fallback.get(0).getRateDate());
            return toMap(fallback);
        }

        log.warn("Nincs elérhető MNB árfolyam: date={}", date);
        return Collections.emptyMap();
    }

    /**
     * Aktuális napi MNB árfolyamok lekérése.
     */
    @Transactional(rollbackFor = Exception.class)
    public Map<String, MnbExchangeRateCache> getCurrentRates() {
        return getRatesForDate(LocalDate.now());
    }

    /**
     * Egyetlen valuta MNB árfolyamának lekérése adott napra.
     */
    @Transactional(rollbackFor = Exception.class)
    public Optional<MnbExchangeRateCache> getRateForCurrency(String currencyCode, LocalDate date) {
        Map<String, MnbExchangeRateCache> rates = getRatesForDate(date);
        return Optional.ofNullable(rates.get(currencyCode));
    }

    /**
     * FKH-063: has the MNB EVER quoted this currency (any date, {@code source='MNB'})?
     *
     * <p>Distinguishes "MNB does not quote this currency at all" (a hand-entered rate is the only
     * possible source, and legitimate) from "the MNB cache happens to be missing this rate for
     * this period" (must fail closed, because the fix is to repair the MNB import, not to
     * substitute another rate source into a statutory valuation).</p>
     *
     * <p>Deliberately NOT {@code getRatesForDate} / {@code getRateForCurrency}: those are
     * date-scoped and would answer "no" for exactly the gap case we must reject. This is one
     * indexed read against the cache table and never triggers a SOAP call.</p>
     */
    @Transactional(readOnly = true)
    public boolean isQuotedByMnb(String currencyCode) {
        if (currencyCode == null) {
            return false;
        }
        return cacheRepository.existsByCurrencyCodeAndSource(currencyCode, MNB_SOURCE);
    }

    // ============ SOAP + CACHE LOGIKA ============

    /**
     * MNB SOAP API hívás és eredmény mentése cache-be.
     * Package-private: a MnbPartialCacheFkh061Test spy-szemje (hálózati hívás nélkül).
     */
    Map<String, MnbExchangeRateCache> fetchAndCacheRates(LocalDate date) throws Exception {
        String dateStr = date.format(DateTimeFormatter.ISO_LOCAL_DATE);

        // SOAP XML request
        String soapBody = buildGetExchangeRatesSoapRequest(dateStr, dateStr);

        log.info("MNB SOAP hívás: GetExchangeRates date={}", dateStr);

        HttpClient httpClient = HttpClient.newBuilder()
                .connectTimeout(HTTP_TIMEOUT)
                .build();

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(MNB_SOAP_URL))
                .header("Content-Type", "text/xml; charset=utf-8")
                .header("SOAPAction", SOAP_NAMESPACE + "MNBArfolyamServiceSoap/GetExchangeRates")
                .timeout(HTTP_TIMEOUT)
                .POST(HttpRequest.BodyPublishers.ofString(soapBody))
                .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

        if (response.statusCode() != 200) {
            throw new BusinessException("MNB SOAP HTTP error: " + response.statusCode(), "MNB_SOAP_ERROR");
        }

        // SOAP válasz feldolgozása
        Map<String, MnbExchangeRateCache> rates = parseSoapResponse(response.body());

        // Cache-be mentés
        for (MnbExchangeRateCache rate : rates.values()) {
            // FKH-061 (PR review): source-filtered lookup. findByCurrencyCodeAndRateDate does
            // NOT filter on source even though the uniqueness key is
            // (currency_code, rate_date, source) — if a date holds both an MNB and a RAIFFEISEN
            // row for the same currency, the Optional-returning finder throws
            // IncorrectResultSizeDataAccessException, which in the caller's transaction leads to
            // the very rollback-only poisoning this PR fixes.
            cacheRepository.findByCurrencyCodeAndRateDateAndSource(
                            rate.getCurrencyCode(), rate.getRateDate(), MNB_SOURCE)
                    .ifPresentOrElse(
                            existing -> {
                                existing.setOfficialRate(rate.getOfficialRate());
                                existing.setUnit(rate.getUnit());
                                existing.setFetchedAt(LocalDateTime.now());
                                cacheRepository.save(existing);
                            },
                            () -> cacheRepository.save(rate));
        }

        log.info("MNB árfolyamok letöltve és cache-elve: date={}, valuták={}", dateStr, rates.size());
        return rates;
    }

    // ============ SOAP XML ÉPÍTÉS ============

    /**
     * GetExchangeRates SOAP request XML összeállítása.
     */
    String buildGetExchangeRatesSoapRequest(String startDate, String endDate) {
        return "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
                + "<soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\""
                + " xmlns:web=\"" + SOAP_NAMESPACE + "\">"
                + "<soap:Body>"
                + "<web:GetExchangeRates>"
                + "<web:startDate>" + startDate + "</web:startDate>"
                + "<web:endDate>" + endDate + "</web:endDate>"
                + "<web:currencyNames></web:currencyNames>"
                + "</web:GetExchangeRates>"
                + "</soap:Body>"
                + "</soap:Envelope>";
    }

    // ============ XML PARSING ============

    /**
     * SOAP válasz feldolgozása.
     *
     * Az MNB SOAP válasz struktúrája:
     * <GetExchangeRatesResponse>
     * <GetExchangeRatesResult>
     * <!-- Escaped XML string tartalmazza az árfolyamokat -->
     * <MNBExchangeRates>
     * <Day date="2026-03-10">
     * <Rate unit="1" curr="EUR">395.12</Rate>
     * <Rate unit="1" curr="USD">370.50</Rate>
     * ...
     * </Day>
     * </MNBExchangeRates>
     * </GetExchangeRatesResult>
     * </GetExchangeRatesResponse>
     */
    Map<String, MnbExchangeRateCache> parseSoapResponse(String soapXml) throws Exception {
        Map<String, MnbExchangeRateCache> result = new LinkedHashMap<>();

        DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
        factory.setNamespaceAware(true);
        // Biztonsági beállítások
        factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
        factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
        factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
        DocumentBuilder builder = factory.newDocumentBuilder();

        // SOAP envelope parsing
        Document soapDoc = builder.parse(new InputSource(new StringReader(soapXml)));

        // GetExchangeRatesResult tartalmának kinyerése
        NodeList resultNodes = soapDoc.getElementsByTagName("GetExchangeRatesResult");
        if (resultNodes.getLength() == 0) {
            log.warn("MNB SOAP válasz: nincs GetExchangeRatesResult elem");
            return result;
        }

        String innerXml = resultNodes.item(0).getTextContent();
        if (innerXml == null || innerXml.isBlank()) {
            log.warn("MNB SOAP válasz: üres GetExchangeRatesResult");
            return result;
        }

        // Belső XML parsing (MNBExchangeRates)
        Document ratesDoc = builder.parse(new InputSource(new StringReader(innerXml)));

        NodeList dayNodes = ratesDoc.getElementsByTagName("Day");
        for (int i = 0; i < dayNodes.getLength(); i++) {
            Element dayElem = (Element) dayNodes.item(i);
            String dateStr = dayElem.getAttribute("date");
            LocalDate rateDate = LocalDate.parse(dateStr);

            NodeList rateNodes = dayElem.getElementsByTagName("Rate");
            for (int j = 0; j < rateNodes.getLength(); j++) {
                Element rateElem = (Element) rateNodes.item(j);
                String currencyCode = rateElem.getAttribute("curr");
                String unitStr = rateElem.getAttribute("unit");
                String rateStr = rateElem.getTextContent().trim();

                if (currencyCode.isEmpty() || rateStr.isEmpty())
                    continue;

                try {
                    // Az MNB tizedesvesszőt használ (pl. "395,12")
                    String normalizedRate = rateStr.replace(",", ".");
                    BigDecimal officialRate = new BigDecimal(normalizedRate);
                    int unit = unitStr.isEmpty() ? 1 : Integer.parseInt(unitStr);

                    MnbExchangeRateCache cache = MnbExchangeRateCache.builder()
                            .currencyCode(currencyCode)
                            .rateDate(rateDate)
                            .officialRate(officialRate)
                            .unit(unit)
                            .fetchedAt(LocalDateTime.now())
                            .build();

                    result.put(currencyCode, cache);
                } catch (NumberFormatException e) {
                    log.warn("MNB árfolyam parsing hiba: curr={}, rate='{}' — {}", currencyCode, rateStr,
                            e.getMessage());
                }
            }
        }

        return result;
    }

    // ============ SEGÉDMETÓDUSOK ============

    /**
     * FKH-061 (WU-6): a cache-elt nap TELJES-e — minden AKTÍV valutakód szerepel-e benne.
     * Az aktív lista a rendszer kereskedhető valutáinak forrása (Currency.active); ha az
     * aktív lista üres (nincs seedelve), a cache-t teljesnek tekintjük — nincs mit pótolni,
     * és nem indítunk SOAP-hívást ismeretlen követelményhalmaz miatt.
     */
    private boolean isCacheComplete(List<MnbExchangeRateCache> cached) {
        List<Currency> activeCurrencies = currencyRepository.findByActiveTrueOrderByDisplayOrderAsc();
        if (activeCurrencies.isEmpty()) {
            return true;
        }
        Set<String> cachedCodes = new HashSet<>();
        for (MnbExchangeRateCache rate : cached) {
            cachedCodes.add(rate.getCurrencyCode());
        }
        for (Currency currency : activeCurrencies) {
            // FKH-061: HUF is the settlement currency — MNB NEVER quotes it against itself
            // (production holds 0 HUF cache rows on any date). If completeness required HUF, no
            // date could ever be COMPLETE and the TTL-bounded SOAP attempt would restart every
            // 30 minutes FOREVER for every queried date.
            if (SETTLEMENT_CURRENCY.equals(currency.getCode())) {
                continue;
            }
            if (!cachedCodes.contains(currency.getCode())) {
                return false;
            }
        }
        return true;
    }

    /**
     * FKH-061 (WU-6): dátumonként legfeljebb egy SOAP-próbálkozás a TTL-ablakban.
     * Sikeres hívásnál is rögzítjük az időpontot: a frissen letöltött nap a következő
     * lekérdezésnél már a cache-elt (teljes vagy MNB által nem jegyzett valuták miatt
     * részleges) mapet adja vissza további letöltés nélkül — így a dekádjelentés 7 napos
     * walk-backje sem kalapálhatja az MNB-t. A map mérete korlátos: cap felett a
     * legrégebbi bejegyzéseket eldobjuk.
     */
    private boolean shouldAttemptDownload(LocalDate date) {
        Instant now = Instant.now();
        Instant last = soapAttempts.get(date);
        if (last != null && Duration.between(last, now).compareTo(SOAP_ATTEMPT_TTL) < 0) {
            return false;
        }
        if (soapAttempts.size() >= SOAP_ATTEMPT_MAP_CAP) {
            soapAttempts.entrySet().removeIf(entry ->
                    Duration.between(entry.getValue(), now).compareTo(SOAP_ATTEMPT_TTL) >= 0);
            if (soapAttempts.size() >= SOAP_ATTEMPT_MAP_CAP) {
                soapAttempts.keySet().stream()
                        .min(Comparator.comparing(soapAttempts::get))
                        .ifPresent(soapAttempts::remove);
            }
        }
        soapAttempts.put(date, now);
        return true;
    }

    private Map<String, MnbExchangeRateCache> toMap(List<MnbExchangeRateCache> list) {
        Map<String, MnbExchangeRateCache> map = new LinkedHashMap<>();
        for (MnbExchangeRateCache rate : list) {
            map.put(rate.getCurrencyCode(), rate);
        }
        return map;
    }
}
