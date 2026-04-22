package hu.puzzleir.valuta.config;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.File;
import java.nio.file.Path;
import java.nio.file.Paths;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Sourcery AI P3 fix: automatikus szinkron ellenorzes a ProductionUrls.java
 * konstansok es a config/production-urls.json fajl kozott.
 *
 * <p>Ha a ket forras drift-el, ez a teszt FAIL-el CI-ban -> megelozi hogy
 * kulonbozo komponensek eltero URL-eket hasznaljanak.</p>
 */
class ProductionUrlsJsonSyncTest {

    @Test
    @DisplayName("ProductionUrls.java konstansok == config/production-urls.json mezok")
    void productionUrlsJsonSync() throws Exception {
        // Root-ban keresem a JSON-t (backend/ alatt indul a test)
        Path jsonPath = Paths.get("..", "config", "production-urls.json").toAbsolutePath().normalize();
        File jsonFile = jsonPath.toFile();
        assertThat(jsonFile).exists().as("config/production-urls.json nem talalhato: " + jsonPath);

        JsonNode json = new ObjectMapper().readTree(jsonFile);

        assertThat(json.get("domain").asText())
            .as("domain sync")
            .isEqualTo(ProductionUrls.DOMAIN);
        assertThat(json.get("base_url").asText())
            .as("base_url sync")
            .isEqualTo(ProductionUrls.BASE_URL);
        assertThat(json.get("www_base_url").asText())
            .as("www_base_url sync")
            .isEqualTo(ProductionUrls.WWW_BASE_URL);
        assertThat(json.get("api_url").asText())
            .as("api_url sync")
            .isEqualTo(ProductionUrls.API_URL);
        assertThat(json.get("health_url").asText())
            .as("health_url sync")
            .isEqualTo(ProductionUrls.HEALTH_URL);
        assertThat(json.get("type_base").asText())
            .as("type_base sync")
            .isEqualTo(ProductionUrls.TYPE_BASE);
    }
}