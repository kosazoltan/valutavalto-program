package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.entity.ExchangeRateSource;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.repository.ExchangeRateSourceRepository;
import hu.puzzleir.valuta.repository.SystemParameterRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;

import java.io.StringReader;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.*;

/**
 * Árfolyam polling szolgáltatás — MNB és ECB árfolyamok automatikus letöltése.
 *
 * Legacy: IRQ timer-rel (perces polling) töltötte le az MNB árfolyamokat FTP-n.
 * Új rendszer: Spring @Scheduled cron alapú HTTP polling.
 *
 * Ütemezés:
 *   - Munkanapokon 8:30 és 14:00 (MNB ~11:00-kor publikál)
 *   - Manuális trigger is lehetséges a controller-en keresztül
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ExchangeRatePollingService {

    // MNB SOAP web service URL
    private static final String MNB_URL = "https://www.mnb.hu/arfolyamok.asmx/GetCurrentExchangeRates";

    // ECB napi árfolyam XML
    private static final String ECB_URL = "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml";

    /**
     * A 27 támogatott valutanem kódja (HUF nem kell — az alap).
     */
    private static final Set<String> SUPPORTED_CURRENCIES = Set.of(
        "AUD", "BAM", "BGN", "BRL", "CAD", "CHF", "CNY", "CZK", "DKK", "EUR",
        "GBP", "HRK", "ILS", "JPY", "MXN", "NOK", "NZD", "PLN", "RON", "RSD",
        "RUB", "SEK", "THB", "TRY", "UAH", "USD"
    );

    private final ExchangeRateRepository exchangeRateRepository;
    private final CurrencyRepository currencyRepository;
    private final ExchangeRateSourceRepository exchangeRateSourceRepository;
    private final SystemParameterRepository systemParameterRepository;

    /**
     * A polling eredmény állapota — in-memory cache az utolsó futásról.
     */
    private volatile LocalDateTime lastPollTime;
    private volatile boolean lastPollSuccess;
    private volatile String lastPollError;
    private volatile int lastPollUpdatedCount;

    // ============ ÜTEMEZETT POLLING ============

    /**
     * Automatikus árfolyam frissítés — minden munkanapon 8:30-kor és 14:00-kor.
     * Az MNB ~11:00 körül publikálja a napi árfolyamot, így:
     *   - 8:30: korai próba (ha van előző napi esti publikáció)
     *   - 14:00: fő lekérdezés (biztosan frissül)
     */
    @Scheduled(cron = "0 30 8 * * MON-FRI")
    @Scheduled(cron = "0 0 14 * * MON-FRI")
    public void pollMnbRates() {
        log.info("MNB árfolyam polling indítása (ütemezett)...");
        executeMnbPoll();
    }

    /**
     * Manuális árfolyam frissítés trigger.
     */
    public void triggerManualPoll() {
        log.info("MNB árfolyam polling indítása (manuális trigger)...");
        executeMnbPoll();
    }

    /**
     * Az utolsó polling állapota.
     */
    public Map<String, Object> getPollingStatus() {
        Map<String, Object> status = new LinkedHashMap<>();
        status.put("lastPollTime", lastPollTime);
        status.put("lastPollSuccess", lastPollSuccess);
        status.put("lastPollError", lastPollError);
        status.put("lastPollUpdatedCount", lastPollUpdatedCount);
        return status;
    }

    // ============ MNB POLLING LOGIKA ============

    /**
     * MNB polling végrehajtása — HTTP GET + XML parse + DB update.
     * Hiba esetén NEM dob exception-t, graceful handling.
     */
    private void executeMnbPoll() {
        LocalDateTime startTime = LocalDateTime.now();
        try {
            // 1. HTTP GET az MNB-ről
            RestTemplate restTemplate = new RestTemplate();
            ResponseEntity<String> response = restTemplate.getForEntity(MNB_URL, String.class);

            if (response.getBody() == null || response.getBody().isBlank()) {
                handlePollError("MNB válasz üres", startTime);
                return;
            }

            log.info("MNB válasz megérkezett, XML feldolgozás...");

            // 2. XML parse
            Map<String, MnbRate> parsedRates = parseMnbXml(response.getBody());

            if (parsedRates.isEmpty()) {
                handlePollError("MNB XML-ből nem sikerült árfolyamot kinyerni", startTime);
                return;
            }

            log.info("MNB XML feldolgozva: {} árfolyam", parsedRates.size());

            // 3. DB update
            int updatedCount = updateOfficialRates(parsedRates);

            // 4. Sikeres polling rögzítése
            lastPollTime = startTime;
            lastPollSuccess = true;
            lastPollError = null;
            lastPollUpdatedCount = updatedCount;

            updateSourceStatus("MNB", true, null);

            log.info("MNB árfolyam polling sikeres: {} valuta frissítve, időpont: {}", updatedCount, startTime);

        } catch (Exception e) {
            handlePollError("MNB polling hiba: " + e.getMessage(), startTime);
        }
    }

    /**
     * MNB XML válasz parse-olása.
     *
     * Az MNB válasz formátuma:
     * <pre>
     * &lt;MNBCurrentExchangeRates&gt;
     *   &lt;Day date="2026-03-05"&gt;
     *     &lt;Rate curr="EUR" unit="1"&gt;406.50&lt;/Rate&gt;
     *     &lt;Rate curr="JPY" unit="100"&gt;250.30&lt;/Rate&gt;
     *     ...
     *   &lt;/Day&gt;
     * &lt;/MNBCurrentExchangeRates&gt;
     * </pre>
     *
     * A unit attribútum fontos: pl. JPY unit="100" → az árfolyam 100 JPY-ra vonatkozik,
     * tehát 1 JPY = rate / 100.
     */
    private Map<String, MnbRate> parseMnbXml(String xml) {
        Map<String, MnbRate> rates = new LinkedHashMap<>();
        try {
            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
            // XXE védelem
            factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
            factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
            factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);

            DocumentBuilder builder = factory.newDocumentBuilder();
            Document doc = builder.parse(new InputSource(new StringReader(xml)));

            NodeList rateNodes = doc.getElementsByTagName("Rate");
            for (int i = 0; i < rateNodes.getLength(); i++) {
                Element rateElement = (Element) rateNodes.item(i);
                String currencyCode = rateElement.getAttribute("curr");
                String unitStr = rateElement.getAttribute("unit");
                String rateValueStr = rateElement.getTextContent().trim();

                if (currencyCode.isEmpty() || rateValueStr.isEmpty()) {
                    continue;
                }

                // Unit kezelés — pl. JPY unit="100"
                int unit = 1;
                if (unitStr != null && !unitStr.isEmpty()) {
                    try {
                        unit = Integer.parseInt(unitStr);
                    } catch (NumberFormatException e) {
                        log.warn("Érvénytelen unit érték: {} a {} valutához", unitStr, currencyCode);
                    }
                }

                // A magyar XML vesszőt használhat tizedes elválasztóként
                rateValueStr = rateValueStr.replace(",", ".");

                try {
                    BigDecimal rateValue = new BigDecimal(rateValueStr);
                    // Normalizálás 1 egységre
                    if (unit > 1) {
                        rateValue = rateValue.divide(BigDecimal.valueOf(unit), 4, RoundingMode.HALF_UP);
                    }

                    if (SUPPORTED_CURRENCIES.contains(currencyCode)) {
                        rates.put(currencyCode, new MnbRate(currencyCode, rateValue, unit));
                        log.debug("MNB árfolyam: {} = {} HUF (unit: {})", currencyCode, rateValue, unit);
                    }
                } catch (NumberFormatException e) {
                    log.warn("Érvénytelen árfolyam érték: {} a {} valutához", rateValueStr, currencyCode);
                }
            }
        } catch (Exception e) {
            log.error("MNB XML parse hiba: {}", e.getMessage(), e);
        }
        return rates;
    }

    /**
     * Hivatalos árfolyamok frissítése az adatbázisban.
     * A mai napra aktív ExchangeRate rekordokat keresi és frissíti az officialRate-et.
     */
    @Transactional
    public int updateOfficialRates(Map<String, MnbRate> mnbRates) {
        int updatedCount = 0;
        LocalDate today = LocalDate.now();

        for (Map.Entry<String, MnbRate> entry : mnbRates.entrySet()) {
            String currencyCode = entry.getKey();
            BigDecimal officialRate = entry.getValue().rate();

            try {
                Optional<Currency> currencyOpt = currencyRepository.findByCode(currencyCode);
                if (currencyOpt.isEmpty()) {
                    log.debug("Valuta nem található a rendszerben: {}", currencyCode);
                    continue;
                }

                Currency currency = currencyOpt.get();

                // Frissítsük az összes aktív, mai dátumú árfolyamot ehhez a valutához
                List<ExchangeRate> activeRates = exchangeRateRepository.findAll().stream()
                    .filter(er -> er.getCurrency().getId().equals(currency.getId())
                        && er.getActive()
                        && er.getValidDate().equals(today))
                    .toList();

                if (activeRates.isEmpty()) {
                    log.debug("Nincs aktív mai árfolyam a(z) {} valutához — kihagyva", currencyCode);
                    continue;
                }

                for (ExchangeRate rate : activeRates) {
                    rate.setOfficialRate(officialRate);
                    exchangeRateRepository.save(rate);
                }
                updatedCount++;
                log.debug("Hivatalos árfolyam frissítve: {} = {} HUF", currencyCode, officialRate);

            } catch (Exception e) {
                log.error("Hiba a(z) {} árfolyam frissítésénél: {}", currencyCode, e.getMessage());
            }
        }

        return updatedCount;
    }

    // ============ ECB ÁRFOLYAMOK ============

    /**
     * ECB árfolyam lekérdezés (backup/összehasonlítás).
     * URL: https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml
     *
     * Az ECB EUR-bázisú árfolyamokat ad: 1 EUR = X foreign currency.
     * HUF-ra átszámítás: HUF/X = HUF/EUR / (X/EUR)
     *
     * @return Map currency kód → HUF-ban kifejezett árfolyam
     */
    public Map<String, BigDecimal> fetchEcbRates() {
        Map<String, BigDecimal> result = new LinkedHashMap<>();

        try {
            RestTemplate restTemplate = new RestTemplate();
            ResponseEntity<String> response = restTemplate.getForEntity(ECB_URL, String.class);

            if (response.getBody() == null || response.getBody().isBlank()) {
                log.error("ECB válasz üres");
                return result;
            }

            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
            factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
            factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
            factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
            factory.setNamespaceAware(true);

            DocumentBuilder builder = factory.newDocumentBuilder();
            Document doc = builder.parse(new InputSource(new StringReader(response.getBody())));

            // ECB formátum: <Cube currency="USD" rate="1.0850"/>
            // Először keressük meg a HUF/EUR rátát
            BigDecimal hufPerEur = null;
            Map<String, BigDecimal> ecbEurRates = new LinkedHashMap<>();

            NodeList cubeNodes = doc.getElementsByTagName("Cube");
            for (int i = 0; i < cubeNodes.getLength(); i++) {
                Element cube = (Element) cubeNodes.item(i);
                String currency = cube.getAttribute("currency");
                String rateStr = cube.getAttribute("rate");
                if (currency.isEmpty() || rateStr.isEmpty()) continue;

                BigDecimal rate = new BigDecimal(rateStr);
                ecbEurRates.put(currency, rate);

                if ("HUF".equals(currency)) {
                    hufPerEur = rate;
                }
            }

            if (hufPerEur == null) {
                log.warn("ECB: HUF árfolyam nem található, konverzió nem lehetséges");
                return result;
            }

            // HUF-ba átszámítás: HUF/X = HUF/EUR / (X/EUR)
            // EUR speciális: 1 EUR = hufPerEur HUF
            result.put("EUR", hufPerEur.setScale(4, RoundingMode.HALF_UP));

            for (Map.Entry<String, BigDecimal> entry : ecbEurRates.entrySet()) {
                String code = entry.getKey();
                if ("HUF".equals(code)) continue;

                BigDecimal xPerEur = entry.getValue();
                // HUF / X = (HUF / EUR) / (X / EUR)
                BigDecimal hufPerX = hufPerEur.divide(xPerEur, 4, RoundingMode.HALF_UP);

                if (SUPPORTED_CURRENCIES.contains(code)) {
                    result.put(code, hufPerX);
                }
            }

            log.info("ECB árfolyamok lekérdezve: {} valuta", result.size());

            updateSourceStatus("ECB", true, null);

        } catch (Exception e) {
            log.error("ECB árfolyam lekérdezés hiba: {}", e.getMessage(), e);
            updateSourceStatus("ECB", false, e.getMessage());
        }

        return result;
    }

    // ============ MARGIN SZÁMÍTÁS ============

    /**
     * Árfolyam margin számítás — a bázis (MNB/ECB) árfolyamból buy/sell rate-et képez.
     *
     * Legacy logika: buyRate = officialRate - spread, sellRate = officialRate + spread
     * A spread a SystemParameter táblából jön: "RATE_SPREAD_{currencyCode}"
     *
     * @param currencyId A valuta ID-ja
     * @param spread     A spread értéke (HUF-ban)
     */
    @Transactional
    public void applyMargins(Long currencyId, BigDecimal spread) {
        Currency currency = currencyRepository.findById(currencyId)
            .orElseThrow(() -> {
                log.error("Valuta nem található: {}", currencyId);
                return new IllegalArgumentException("Valuta nem található: " + currencyId);
            });

        LocalDate today = LocalDate.now();

        List<ExchangeRate> activeRates = exchangeRateRepository.findAll().stream()
            .filter(er -> er.getCurrency().getId().equals(currencyId)
                && er.getActive()
                && er.getValidDate().equals(today))
            .toList();

        if (activeRates.isEmpty()) {
            log.warn("Nincs aktív mai árfolyam a(z) {} ({}) valutához — margin nem alkalmazható",
                currency.getCode(), currencyId);
            return;
        }

        for (ExchangeRate rate : activeRates) {
            BigDecimal officialRate = rate.getOfficialRate();
            if (officialRate == null) {
                log.warn("Nincs hivatalos árfolyam a(z) {} valutához — margin kihagyva", currency.getCode());
                continue;
            }

            BigDecimal newBuyRate = officialRate.subtract(spread);
            BigDecimal newSellRate = officialRate.add(spread);

            rate.setBaseBuyRate(newBuyRate);
            rate.setBaseSellRate(newSellRate);
            exchangeRateRepository.save(rate);

            log.info("Margin alkalmazva {} valutához: official={}, spread={}, buy={}, sell={}",
                currency.getCode(), officialRate, spread, newBuyRate, newSellRate);
        }
    }

    // ============ NAPI SNAPSHOT ============

    /**
     * Napi árfolyam snapshot — napzárásnál hívjuk, elmenti az aznapi végleges árfolyamokat.
     * Egy audit jellegű rögzítés: az aktív árfolyamok "zamorzódnak".
     *
     * @param branchId Fiók azonosító
     * @param date     A nap dátuma
     */
    @Transactional
    public void snapshotDailyRates(UUID branchId, LocalDate date) {
        log.info("Napi árfolyam snapshot indítása: fiók={}, dátum={}", branchId, date);

        List<ExchangeRate> activeRates = exchangeRateRepository.findAll().stream()
            .filter(er -> er.getActive() && er.getValidDate().equals(date))
            .filter(er -> er.getBranch() == null
                || (er.getBranch() != null && er.getBranch().getId().equals(branchId)))
            .toList();

        if (activeRates.isEmpty()) {
            log.warn("Nincs aktív árfolyam snapshot-hoz: fiók={}, dátum={}", branchId, date);
            return;
        }

        // Snapshot: a meglévő aktív árfolyamokat inaktiváljuk — "befagyasztjuk" a napot
        for (ExchangeRate rate : activeRates) {
            rate.setActive(false);
            exchangeRateRepository.save(rate);
        }

        log.info("Napi árfolyam snapshot kész: {} árfolyam befagyasztva, fiók={}, dátum={}",
            activeRates.size(), branchId, date);
    }

    // ============ SEGÉD METÓDUSOK ============

    /**
     * Hiba kezelés polling közben — log + source status update.
     */
    private void handlePollError(String errorMessage, LocalDateTime startTime) {
        log.error("MNB polling hiba: {}", errorMessage);
        lastPollTime = startTime;
        lastPollSuccess = false;
        lastPollError = errorMessage;
        lastPollUpdatedCount = 0;
        updateSourceStatus("MNB", false, errorMessage);
    }

    /**
     * ExchangeRateSource állapot frissítése.
     */
    private void updateSourceStatus(String sourceName, boolean success, String error) {
        try {
            Optional<ExchangeRateSource> sourceOpt = exchangeRateSourceRepository.findBySourceName(sourceName);
            if (sourceOpt.isPresent()) {
                ExchangeRateSource source = sourceOpt.get();
                if (success) {
                    source.setLastSuccessAt(LocalDateTime.now());
                    source.setSuccessCount(source.getSuccessCount() + 1);
                    source.setLastError(null);
                    source.setLastErrorAt(null);
                } else {
                    source.setLastErrorAt(LocalDateTime.now());
                    source.setLastError(error);
                    source.setErrorCount(source.getErrorCount() + 1);
                }
                exchangeRateSourceRepository.save(source);
            } else {
                log.debug("ExchangeRateSource '{}' nem létezik az adatbázisban, állapot nem frissíthető", sourceName);
            }
        } catch (Exception e) {
            log.warn("ExchangeRateSource '{}' frissítés sikertelen: {}", sourceName, e.getMessage());
        }
    }

    /**
     * MNB árfolyam belső DTO.
     */
    private record MnbRate(String currencyCode, BigDecimal rate, int unit) {}
}
