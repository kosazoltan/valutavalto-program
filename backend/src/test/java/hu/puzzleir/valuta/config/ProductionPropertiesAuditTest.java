package hu.puzzleir.valuta.config;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.InputStream;
import java.util.Properties;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Audit P0.2 (2026-05-03) regressziovedelem.
 *
 * <p>A `application-production.properties`-ben kotelezo a
 * `server.forward-headers-strategy=framework` beallitas, hogy a Spring
 * `ForwardedHeaderFilter` aktivaljon. Enelkul a reverse-proxy (Caddy) mogul
 * jovo HTTPS request-eket a Tomcat HTTP-kent latja, es a
 * `request.isSecure()` `false`-t ad vissza, igy a `ResponseCookie.secure(...)`
 * a refresh token cookie-t `Secure` flag NELKUL allitja be productionben.
 */
class ProductionPropertiesAuditTest {

    @Test
    @DisplayName("server.forward-headers-strategy=framework production-ben")
    void forwardHeadersStrategyIsFrameworkInProduction() throws Exception {
        Properties props = loadProductionProperties();
        assertThat(props.getProperty("server.forward-headers-strategy"))
            .as("server.forward-headers-strategy production-ben kotelezoen 'framework' "
                + "(audit P0.2 #2026-05-03)")
            .isEqualTo("framework");
    }

    private Properties loadProductionProperties() throws Exception {
        Properties props = new Properties();
        try (InputStream is = getClass()
                .getResourceAsStream("/application-production.properties")) {
            assertThat(is)
                .as("application-production.properties nem talalhato a classpathon")
                .isNotNull();
            props.load(is);
        }
        return props;
    }
}
