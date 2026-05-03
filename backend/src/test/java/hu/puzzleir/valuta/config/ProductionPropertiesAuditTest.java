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
    @DisplayName("server.forward-headers-strategy=native production-ben (Codex P1 #352 follow-up)")
    void forwardHeadersStrategyIsNativeInProduction() throws Exception {
        Properties props = loadProductionProperties();
        assertThat(props.getProperty("server.forward-headers-strategy"))
            .as("server.forward-headers-strategy production-ben 'native' (Codex P1 PR #352): "
                + "Tomcat RemoteIpValve `internalProxies` regex-szel csak loopback-bol fogad el "
                + "X-Forwarded-* header-eket, megakadalyozza a spoofingot.")
            .isEqualTo("native");
    }

    @Test
    @DisplayName("server.tomcat.remoteip.internal-proxies csak loopback CIDR-t enged")
    void internalProxiesRegexIsLoopbackOnly() throws Exception {
        Properties props = loadProductionProperties();
        String regex = props.getProperty("server.tomcat.remoteip.internal-proxies");
        assertThat(regex)
            .as("Tomcat internal-proxies kotelezoen csak 127.x.x.x + IPv6 loopback")
            .isNotNull()
            .contains("127");
        assertThat(regex)
            .as("NEM enged 0.0.0.0/0 vagy publikus CIDR-t (Codex P1 #352 spoofing-vedelem)")
            .doesNotContain("0\\.0\\.0\\.0/0");
    }

    @Test
    @DisplayName("server.tomcat.remoteip.protocol-header X-Forwarded-Proto")
    void protocolHeaderIsXForwardedProto() throws Exception {
        Properties props = loadProductionProperties();
        assertThat(props.getProperty("server.tomcat.remoteip.protocol-header"))
            .isEqualTo("X-Forwarded-Proto");
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
