package hu.puzzleir.valuta.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.servers.Server;
import io.swagger.v3.oas.models.tags.Tag;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.boot.info.BuildProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

/**
 * OpenAPI / Swagger UI konfiguráció.
 *
 * Tag csoportok:
 * - Pénztár: tranzakciók, eladás, vétel, stornó
 * - Admin: audit, dolgozó kezelés, rendszer paraméterek
 * - Rendszer: health, info, backup
 * - Szinkronizáció: sync, polling, data collection
 */
@Configuration
public class OpenApiConfig {

    private final ObjectProvider<BuildProperties> buildPropertiesProvider;

    public OpenApiConfig(ObjectProvider<BuildProperties> buildPropertiesProvider) {
        this.buildPropertiesProvider = buildPropertiesProvider;
    }

    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("Valutaváltó ERP API")
                        .version(resolveVersion())
                        .description("Teljes valutaváltó/pénzváltó ERP rendszer REST API. "
                                + "Tartalmazza a pénztár, admin, rendszer és szinkronizáció modulokat.")
                        .contact(new Contact()
                                .name("PuzzleIR")
                                .email("info@puzzleir.hu")))
                .servers(List.of(
                        new Server().url("http://localhost:8080").description("Helyi fejlesztés"),
                        new Server().url("https://excbesttest.com").description("Éles szerver")))
                .tags(List.of(
                        new Tag().name("Pénztár").description("Tranzakciók, eladás, vétel, stornó, zárlat"),
                        new Tag().name("Admin").description("Audit napló, dolgozó kezelés, rendszer paraméterek, licenc"),
                        new Tag().name("Rendszer").description("Health check, verzió, backup, nyomtatás"),
                        new Tag().name("Szinkronizáció").description("Sync, polling, adatgyűjtés, MNB árfolyamok")))
                .components(new Components()
                        .addSecuritySchemes("bearerAuth", new SecurityScheme()
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")
                                .description("JWT Authentication — Bearer token")))
                .addSecurityItem(new SecurityRequirement().addList("bearerAuth"));
    }

    private String resolveVersion() {
        BuildProperties buildProperties = buildPropertiesProvider.getIfAvailable();
        String version = buildProperties == null ? null : buildProperties.getVersion();
        if (version == null || version.isBlank()) {
            return "dev";
        }
        return version;
    }
}
