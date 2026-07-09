package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.BusinessException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import java.io.StringReader;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;

@Component
@Slf4j
public class MnbRateQueryClient {

    private static final String MNB_URL = "https://www.mnb.hu/arfolyamok.asmx/GetCurrentExchangeRates";

    private final RestTemplate restTemplate;

    public MnbRateQueryClient(@Value("${mnb-settlement.query.timeout-ms:5000}") int timeoutMs) {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(timeoutMs);
        factory.setReadTimeout(timeoutMs);
        this.restTemplate = new RestTemplate(factory);
    }

    /** KIZÁRÓLAG olvas: HTTP GET + XML parse. Adatbázist NEM érint. */
    public Map<String, BigDecimal> fetchCurrentRates() {
        try {
            ResponseEntity<String> response = restTemplate.getForEntity(MNB_URL, String.class);
            if (response.getBody() == null || response.getBody().isBlank()) {
                throw new BusinessException("MNB válasz üres", "MNB_EMPTY_RESPONSE");
            }
            return parseMnbXml(response.getBody());
        } catch (BusinessException e) {
            throw e;
        } catch (RestClientException e) {
            throw new BusinessException("MNB lekérdezés sikertelen", "MNB_QUERY_FAILED");
        }
    }

    Map<String, BigDecimal> parseMnbXml(String xml) {
        Map<String, BigDecimal> rates = new LinkedHashMap<>();
        try {
            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
            factory.setFeature(javax.xml.XMLConstants.FEATURE_SECURE_PROCESSING, true);
            factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
            factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
            factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
            factory.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false);
            factory.setXIncludeAware(false);
            factory.setExpandEntityReferences(false);

            DocumentBuilder builder = factory.newDocumentBuilder();
            Document doc = builder.parse(new InputSource(new StringReader(xml)));

            NodeList rateNodes = doc.getElementsByTagName("Rate");
            for (int i = 0; i < rateNodes.getLength(); i++) {
                Element rateElement = (Element) rateNodes.item(i);
                String currencyCode = normalizeCode(rateElement.getAttribute("curr"));
                String rateValueText = rateElement.getTextContent() != null
                        ? rateElement.getTextContent().trim()
                        : "";
                if (currencyCode.isEmpty() || rateValueText.isEmpty()) {
                    continue;
                }

                int unit = parseUnit(rateElement.getAttribute("unit"), currencyCode);
                String normalizedRate = rateValueText.replace(",", ".");
                try {
                    BigDecimal rateValue = new BigDecimal(normalizedRate);
                    if (unit > 1) {
                        rateValue = rateValue.divide(BigDecimal.valueOf(unit), 4, RoundingMode.HALF_UP);
                    } else {
                        rateValue = rateValue.setScale(4, RoundingMode.HALF_UP);
                    }
                    rates.put(currencyCode, rateValue);
                    log.debug("MNB árfolyam preview: {} = {} HUF (unit: {})", currencyCode, rateValue, unit);
                } catch (NumberFormatException e) {
                    log.warn("Érvénytelen MNB árfolyam érték: {} a {} valutához", rateValueText, currencyCode);
                }
            }
            return rates;
        } catch (Exception e) {
            throw new BusinessException("MNB XML feldolgozás sikertelen", "MNB_XML_PARSE_FAILED");
        }
    }

    private int parseUnit(String unitText, String currencyCode) {
        if (unitText == null || unitText.isBlank()) {
            return 1;
        }
        try {
            int unit = Integer.parseInt(unitText.trim());
            if (unit > 0) {
                return unit;
            }
        } catch (NumberFormatException e) {
            // fall through to the warning below
        }
        log.warn("Érvénytelen MNB unit érték: {} a {} valutához", unitText, currencyCode);
        return 1;
    }

    private String normalizeCode(String code) {
        return code == null ? "" : code.trim().toUpperCase(Locale.ROOT);
    }
}
