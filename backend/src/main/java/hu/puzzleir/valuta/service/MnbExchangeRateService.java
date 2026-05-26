package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.entity.MnbExchangeRateCache;
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
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

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
    private static final Duration HTTP_TIMEOUT = Duration.ofSeconds(15);

    private final MnbExchangeRateCacheRepository cacheRepository;

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
        // 1. Próbálunk pontos dátumra cache-ből kiszolgálni
        List<MnbExchangeRateCache> cached = cacheRepository.findByRateDate(date);
        if (!cached.isEmpty()) {
            log.debug("MNB árfolyamok cache-ből: date={}, db={}", date, cached.size());
            return toMap(cached);
        }

        // 2. SOAP letöltés
        try {
            Map<String, MnbExchangeRateCache> fetched = fetchAndCacheRates(date);
            if (!fetched.isEmpty()) {
                return fetched;
            }
        } catch (Exception e) {
            log.warn("MNB SOAP hívás sikertelen (date={}): {}", date, e.getMessage());
        }

        // 3. Fallback: legutolsó elérhető cache-elt árfolyam
        List<MnbExchangeRateCache> fallback = cacheRepository.findLatestRates(date);
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

    // ============ SOAP + CACHE LOGIKA ============

    /**
     * MNB SOAP API hívás és eredmény mentése cache-be.
     */
    private Map<String, MnbExchangeRateCache> fetchAndCacheRates(LocalDate date) throws Exception {
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
            cacheRepository.findByCurrencyCodeAndRateDate(rate.getCurrencyCode(), rate.getRateDate())
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

    private Map<String, MnbExchangeRateCache> toMap(List<MnbExchangeRateCache> list) {
        Map<String, MnbExchangeRateCache> map = new LinkedHashMap<>();
        for (MnbExchangeRateCache rate : list) {
            map.put(rate.getCurrencyCode(), rate);
        }
        return map;
    }
}
