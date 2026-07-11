package hu.puzzleir.valuta.config;

import jakarta.servlet.ServletException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import java.io.IOException;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * PP-04: a CORS minta-illesztő biztonsági tesztje — a korábbi startsWith/endsWith
 * kijátszhatóságának (origin hijack) kizárása.
 */
class ProductionCorsFilterTest {

    private final ProductionCorsFilter filter =
            new ProductionCorsFilter("http://localhost:*,https://*.excvaluta.com,https://excvaluta.com");

    @Test
    @DisplayName("pontos egyezés (nincs wildcard) — csak az azonos origin")
    void testExactMatch() {
        assertThat(filter.matchesPattern("https://excvaluta.com", "https://excvaluta.com")).isTrue();
        assertThat(filter.matchesPattern("https://evil.com", "https://excvaluta.com")).isFalse();
    }

    @Test
    @DisplayName("http://localhost:* — port wildcard csak portot enged, nem domain-trükköt")
    void testLocalhostPortWildcard() {
        assertThat(filter.matchesPattern("http://localhost:3000", "http://localhost:*")).isTrue();
        assertThat(filter.matchesPattern("http://localhost:5173", "http://localhost:*")).isTrue();
        // KIJÁTSZÁSI KÍSÉRLETEK — mind tiltott:
        assertThat(filter.matchesPattern("http://localhost.evil.com", "http://localhost:*")).isFalse();
        assertThat(filter.matchesPattern("http://localhost:3000/@evil.com", "http://localhost:*")).isFalse();
        assertThat(filter.matchesPattern("http://localhost:3000.evil.com/", "http://localhost:*")).isFalse();
    }

    @Test
    @DisplayName("https://*.excvaluta.com — aldomén wildcard, de nem enged path/userinfo-injekciót")
    void testSubdomainWildcard() {
        assertThat(filter.matchesPattern("https://app.excvaluta.com", "https://*.excvaluta.com")).isTrue();
        // KIJÁTSZÁSI KÍSÉRLETEK:
        assertThat(filter.matchesPattern("https://x.excvaluta.com.evil.com", "https://*.excvaluta.com")).isFalse();
        assertThat(filter.matchesPattern("https://evil.com/x.excvaluta.com", "https://*.excvaluta.com")).isFalse();
        assertThat(filter.matchesPattern("https://evil.com#.excvaluta.com", "https://*.excvaluta.com")).isFalse();
        assertThat(filter.matchesPattern("https://evil.com@x.excvaluta.com", "https://*.excvaluta.com")).isFalse();
    }

    @Test
    @DisplayName("case-insensitive illesztés")
    void testCaseInsensitive() {
        assertThat(filter.matchesPattern("HTTPS://EXCVALUTA.COM", "https://excvaluta.com")).isTrue();
    }

    @Test
    @DisplayName("engedélyezett origin számára olvashatóvá teszi a Content-Disposition headert")
    void exposesContentDispositionForAllowedOrigin() throws ServletException, IOException {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/v1/darius/import-file");
        request.addHeader(HttpHeaders.ORIGIN, "https://excvaluta.com");
        MockHttpServletResponse response = new MockHttpServletResponse();

        filter.doFilter(request, response, new MockFilterChain());

        assertThat(response.getHeader(HttpHeaders.ACCESS_CONTROL_EXPOSE_HEADERS))
                .isEqualTo(HttpHeaders.CONTENT_DISPOSITION);
    }
}
