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
import java.util.List;

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

    private static final List<String> SANCTION_URLS = List.of(
            "https://scsanctions.un.org/resources/xml/en/consolidated.xml",
            "https://webgate.ec.europa.eu/fsd/fsf/public/files/xmlFullSanctionsList_1_1/content"
    );

    private static final Duration TIMEOUT = Duration.ofSeconds(60);

    private final SanctionScreeningService sanctionService;
    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(TIMEOUT)
            .build();

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

        int totalImported = 0;
        for (String url : SANCTION_URLS) {
            totalImported += fetchAndImport(url);
        }

        if (totalImported > 0) {
            log.info("Szankcios lista frissites kesz: osszesen {} bejegyzes importalva", totalImported);
        } else {
            log.warn("Szankcios lista frissites: egyetlen forrasbol sem sikerult importalni!");
        }
    }

    private int fetchAndImport(String url) {
        String source = url.contains("un.org") ? "ENSZ" : "EU";
        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .timeout(TIMEOUT)
                    .GET()
                    .build();

            HttpResponse<InputStream> response = httpClient.send(request,
                    HttpResponse.BodyHandlers.ofInputStream());

            if (response.statusCode() == 200) {
                try (InputStream body = response.body()) {
                    int count = "EU".equals(source)
                            ? sanctionService.importEuSanctionList(body)
                            : sanctionService.importSanctionList(body);
                    log.info("{} szankcios lista: {} bejegyzes importalva", source, count);
                    return count;
                }
            } else {
                log.error("{} szankcios lista letoltes hiba: HTTP {}", source, response.statusCode());
            }
        } catch (Exception e) {
            log.error("{} szankcios lista frissites hiba: {}", source, e.getMessage(), e);
        }
        return 0;
    }
}
