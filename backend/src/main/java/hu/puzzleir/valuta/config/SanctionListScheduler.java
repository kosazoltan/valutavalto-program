package hu.puzzleir.valuta.config;

import hu.puzzleir.valuta.service.SanctionScreeningService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.io.InputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.time.LocalDate;

/**
 * Szankcios lista automatikus frissitese — naponta 6:00-kor.
 *
 * H7 gap fix: manualis batch helyett automatikus scheduler + timestamp tracking.
 *
 * Forrasok:
 * - ENSZ Consolidated List: https://scsanctions.un.org/resources/xml/en/consolidated.xml
 * - EU Financial Sanctions: https://webgate.ec.europa.eu/fsd/fsf/public/files/xmlFullSanctionsList_1_1/content
 *
 * Pmt. 27.§ (1): A szolgaltato koteles a szankcios listak naprakesz nyilvantartasat biztositani.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class SanctionListScheduler {

    private static final String UN_SANCTIONS_URL =
            "https://scsanctions.un.org/resources/xml/en/consolidated.xml";

    private static final Duration TIMEOUT = Duration.ofSeconds(60);

    private final SanctionScreeningService sanctionService;

    /**
     * Naponta 6:00-kor (munkaid elott) automatikus szankcios lista frissites.
     */
    @Scheduled(cron = "0 0 6 * * *", zone = "Europe/Budapest")
    public void refreshSanctionList() {
        log.info("Szankcios lista automatikus frissites inditasa...");

        LocalDate lastUpdate = sanctionService.getLastUpdateDate();
        if (lastUpdate != null && lastUpdate.equals(LocalDate.now())) {
            log.info("Szankcios lista mar frissitve ma ({}). Kihagyas.", lastUpdate);
            return;
        }

        try {
            HttpClient client = HttpClient.newBuilder()
                    .connectTimeout(TIMEOUT)
                    .build();

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(UN_SANCTIONS_URL))
                    .timeout(TIMEOUT)
                    .GET()
                    .build();

            HttpResponse<InputStream> response = client.send(request,
                    HttpResponse.BodyHandlers.ofInputStream());

            if (response.statusCode() == 200) {
                try (InputStream body = response.body()) {
                    int count = sanctionService.importSanctionList(body);
                    log.info("Szankcios lista frissitve: {} bejegyzes importalva. Datum: {}", count, LocalDate.now());
                }
            } else {
                log.error("Szankcios lista letoltes hiba: HTTP {}", response.statusCode());
            }
        } catch (Exception e) {
            log.error("Szankcios lista frissites hiba: {}", e.getMessage(), e);
        }
    }
}
