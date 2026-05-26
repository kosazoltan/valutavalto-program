package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.diagnostics.ErrorCodeCatalogDto;
import hu.puzzleir.valuta.logging.VVLogger;
import jakarta.annotation.PostConstruct;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;
import org.yaml.snakeyaml.LoaderOptions;
import org.yaml.snakeyaml.Yaml;
import org.yaml.snakeyaml.constructor.SafeConstructor;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;

/**
 * EBC Valutavalto - AI-olvashato hibakod-katalogus szolgaltatas.
 *
 * <p>Forras: vault/feedback/valutavalto-belso-log-audit-modul-tervezet-2026-05-18.md (4.5)
 *
 * <p>A {@code packages/shared-logging/error-codes.yaml}-bol toltodott
 * (pom.xml `<resource>` definicio masolja a classpath-ra), cache-elve es
 * a {@code GET /api/v1/diagnostics/error-codes} endpoint-on ki van szolgalva.
 *
 * <p>Az adminokat / hibajavito AI-t segiti azonositani egy adott hibakod
 * jelenteseit + javitasi receptjet.
 */
@Service
public class ErrorCodeCatalogService {

    private static final VVLogger LOG = VVLogger.of(ErrorCodeCatalogService.class);
    private static final String YAML_PATH = "error-codes.yaml";

    private volatile ErrorCodeCatalogDto cachedCatalog;

    @PostConstruct
    public void loadCatalog() {
        try (InputStream in = new ClassPathResource(YAML_PATH).getInputStream()) {
            // Semgrep use-snakeyaml-constructor hardening: SafeConstructor → nincs tetszőleges
            // típus-példányosítás (deserialization-attack védelem), bár a YAML csomagolt resource.
            Yaml yaml = new Yaml(new SafeConstructor(new LoaderOptions()));
            Map<String, Object> root = yaml.load(in);
            if (root == null) {
                LOG.warn("diagnostics.error_codes.load_failed", "VV-TECH-001", Map.of(
                        "path", YAML_PATH, "reason", "empty"));
                this.cachedCatalog = empty();
                return;
            }
            String version = String.valueOf(root.getOrDefault("version", "1"));
            @SuppressWarnings("unchecked")
            Map<String, Map<String, Object>> codesMap =
                    (Map<String, Map<String, Object>>) root.getOrDefault("codes", Collections.emptyMap());

            List<ErrorCodeCatalogDto.ErrorCodeEntry> codes = new ArrayList<>(codesMap.size());
            codesMap.forEach((code, entry) -> codes.add(new ErrorCodeCatalogDto.ErrorCodeEntry(
                    code,
                    str(entry.get("name")),
                    str(entry.get("category")),
                    str(entry.get("level")),
                    str(entry.get("user_impact")),
                    str(entry.get("ai_fix_hint"))
            )));
            this.cachedCatalog = new ErrorCodeCatalogDto(version, codes.size(), codes);

            LOG.info("diagnostics.error_codes.loaded", Map.of(
                    "total_codes", codes.size(), "version", version));
        } catch (Exception e) {
            LOG.error("VV-TECH-001", "diagnostics.error_codes.load_failed", e, Map.of(
                    "path", YAML_PATH));
            this.cachedCatalog = empty();
        }
    }

    public ErrorCodeCatalogDto getCatalog() {
        if (cachedCatalog == null) loadCatalog();
        return cachedCatalog;
    }

    private static String str(Object o) { return o == null ? null : String.valueOf(o); }

    private static ErrorCodeCatalogDto empty() {
        return new ErrorCodeCatalogDto("0", 0, Collections.emptyList());
    }
}
