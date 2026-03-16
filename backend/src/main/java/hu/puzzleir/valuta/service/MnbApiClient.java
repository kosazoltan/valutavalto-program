package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.mnb.MnbSubmissionResult;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;

import java.nio.charset.StandardCharsets;
import java.util.UUID;

/**
 * MNB adatszolgáltatás HTTP kliens.
 *
 * Valós HTTP POST beküldés az MNB API-ra — az MNB_API_URL és MNB_API_TOKEN
 * system-paraméterekből olvasva. Ha a paraméter nem létezik, MnbSubmissionResult
 * failure-t ad vissza (nem dob kivételt), hogy a hívó kezelhesse.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class MnbApiClient {

    private static final String PARAM_MNB_API_URL   = "MNB_API_URL";
    private static final String PARAM_MNB_API_TOKEN = "MNB_API_TOKEN";

    private final RestTemplate restTemplate;
    private final SystemParameterService systemParameterService;

    /**
     * XML tartalom beküldése az MNB API-ra.
     *
     * @param xmlContent  MNB-XSD kompatibilis XML
     * @param reportType  riport típus (DAILY / WEEKLY / MONTHLY stb.)
     * @return beküldés eredménye (success + referenceNumber vagy errorMessage)
     */
    public MnbSubmissionResult submitXml(String xmlContent, String reportType) {
        String apiUrl;
        String apiToken;

        try {
            apiUrl   = systemParameterService.getValue(PARAM_MNB_API_URL);
            apiToken = systemParameterService.getValue(PARAM_MNB_API_TOKEN);
        } catch (ResourceNotFoundException e) {
            log.warn("MNB API konfiguráció hiányzik: {}", e.getMessage());
            return MnbSubmissionResult.builder()
                .success(false)
                .errorMessage("MNB API konfiguráció hiányzik: " + e.getMessage())
                .build();
        }

        if (apiUrl == null || apiUrl.isBlank()) {
            log.warn("MNB_API_URL üres");
            return MnbSubmissionResult.builder()
                .success(false)
                .errorMessage("MNB_API_URL nincs beállítva")
                .build();
        }

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(new MediaType("application", "xml", StandardCharsets.UTF_8));
            headers.set("X-Report-Type", reportType);
            if (apiToken != null && !apiToken.isBlank()) {
                headers.set("Authorization", "Bearer " + apiToken);
            }

            HttpEntity<String> request = new HttpEntity<>(xmlContent, headers);

            log.info("MNB API beküldés: url={}, reportType={}", apiUrl, reportType);
            ResponseEntity<String> response = restTemplate.exchange(
                apiUrl, HttpMethod.POST, request, String.class);

            if (response.getStatusCode().is2xxSuccessful()) {
                String referenceNumber = extractReferenceNumber(response.getBody());
                log.info("MNB API beküldés sikeres: referenceNumber={}", referenceNumber);
                return MnbSubmissionResult.builder()
                    .success(true)
                    .referenceNumber(referenceNumber)
                    .build();
            } else {
                String errorMsg = "MNB API nem 2xx státusz: " + response.getStatusCode();
                log.warn(errorMsg);
                return MnbSubmissionResult.builder()
                    .success(false)
                    .errorMessage(errorMsg)
                    .build();
            }

        } catch (HttpClientErrorException e) {
            log.warn("MNB API 4xx hiba: status={}, body={}", e.getStatusCode(), e.getResponseBodyAsString());
            return MnbSubmissionResult.builder()
                .success(false)
                .errorMessage("MNB API 4xx hiba: " + e.getStatusCode() + " — " + e.getResponseBodyAsString())
                .build();
        } catch (HttpServerErrorException e) {
            log.warn("MNB API 5xx hiba: status={}, body={}", e.getStatusCode(), e.getResponseBodyAsString());
            return MnbSubmissionResult.builder()
                .success(false)
                .errorMessage("MNB API 5xx hiba: " + e.getStatusCode() + " — " + e.getResponseBodyAsString())
                .build();
        } catch (ResourceAccessException e) {
            log.warn("MNB API hálózati hiba: {}", e.getMessage());
            return MnbSubmissionResult.builder()
                .success(false)
                .errorMessage("MNB API hálózati hiba: " + e.getMessage())
                .build();
        } catch (Exception e) {
            log.error("MNB API váratlan hiba: {}", e.getMessage(), e);
            return MnbSubmissionResult.builder()
                .success(false)
                .errorMessage("MNB API váratlan hiba: " + e.getMessage())
                .build();
        }
    }

    /**
     * Hivatkozási szám kinyerése az MNB API válaszból.
     * Az MNB XML válaszban a RefNum elem tartalmazza, vagy egyszerű szöveg.
     */
    private String extractReferenceNumber(String responseBody) {
        if (responseBody == null || responseBody.isBlank()) {
            return "MNB-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        }
        // <RefNum>MNB-20240316-001</RefNum>
        int start = responseBody.indexOf("<RefNum>");
        int end   = responseBody.indexOf("</RefNum>");
        if (start >= 0 && end > start) {
            return responseBody.substring(start + 8, end).trim();
        }
        // Ha nincs XML elemben, az egész válasz a ref szám (legfeljebb 100 karakter)
        String trimmed = responseBody.trim();
        return trimmed.length() <= 100 ? trimmed : trimmed.substring(0, 100);
    }
}
