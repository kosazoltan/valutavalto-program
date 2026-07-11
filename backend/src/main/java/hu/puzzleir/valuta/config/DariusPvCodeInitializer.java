package hu.puzzleir.valuta.config;

import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class DariusPvCodeInitializer {

    private final IntegrationTransportProperties properties;

    @PostConstruct
    public void init() {
        String raw = properties.getDarius().getPvCodesEnv();
        if (raw == null || raw.isBlank()) {
            log.warn("DARIUS_PV_CODES nincs beállítva — a Raiffeisen importfájl-export fail-closed tiltva marad");
            return;
        }

        var target = properties.getDarius().getPvCodes();
        int malformedEntries = 0;
        for (String entry : raw.split(",")) {
            String trimmed = entry.trim();
            if (trimmed.isEmpty()) {
                continue;
            }
            int separator = trimmed.indexOf('=');
            if (separator <= 0 || separator == trimmed.length() - 1) {
                malformedEntries++;
                continue;
            }
            String companyCode = trimmed.substring(0, separator).trim();
            String pvCode = trimmed.substring(separator + 1).trim();
            if (companyCode.isEmpty() || pvCode.isEmpty()) {
                malformedEntries++;
                continue;
            }
            target.putIfAbsent(companyCode, pvCode);
        }

        if (malformedEntries > 0) {
            log.warn("DARIUS_PV_CODES: {} hibás bejegyzés kihagyva", malformedEntries);
        }
        log.info("Darius PV-kód mapping betöltve {} céghez", target.size());
    }
}
