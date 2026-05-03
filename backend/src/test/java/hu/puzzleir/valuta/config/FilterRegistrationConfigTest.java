package hu.puzzleir.valuta.config;

import hu.puzzleir.valuta.security.IdempotencyFilter;
import hu.puzzleir.valuta.security.JwtAuthenticationFilter;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.boot.web.servlet.FilterRegistrationBean;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Audit P0.6 (2026-05-03) regressziovedelem.
 *
 * <p>Bizonyitja, hogy a `FilterRegistrationConfig` minden bean-je
 * `setEnabled(false)`-t ad vissza — igy a 3 filter Servlet container
 * auto-registration-ja KIvel van, es CSAK a Spring Security chain-en
 * (`SecurityConfig.addFilterBefore`) futnak.</p>
 *
 * <p>Direct unit teszt (NEM `@SpringBootTest`), hogy a teljes context-bootstrap
 * koltsegei nelkul futhasson — a fix lokalisan deklarativ, nem fugg
 * mas bean-ektol.</p>
 */
class FilterRegistrationConfigTest {

    private final FilterRegistrationConfig config = new FilterRegistrationConfig();

    @Test
    @DisplayName("jwtFilterRegistration setEnabled(false)")
    void jwtFilterServletRegistrationDisabled() {
        JwtAuthenticationFilter filter = Mockito.mock(JwtAuthenticationFilter.class);
        FilterRegistrationBean<JwtAuthenticationFilter> reg = config.jwtFilterRegistration(filter);
        assertThat(reg).as("FilterRegistrationBean letezik").isNotNull();
        assertThat(reg.isEnabled())
            .as("setEnabled(false) — csak Spring Security chain-en futhat")
            .isFalse();
        assertThat(reg.getFilter()).as("ugyanaz a filter peldany").isSameAs(filter);
    }

    @Test
    @DisplayName("idempotencyFilterRegistration setEnabled(false)")
    void idempotencyFilterServletRegistrationDisabled() {
        IdempotencyFilter filter = Mockito.mock(IdempotencyFilter.class);
        FilterRegistrationBean<IdempotencyFilter> reg = config.idempotencyFilterRegistration(filter);
        assertThat(reg).isNotNull();
        assertThat(reg.isEnabled()).isFalse();
        assertThat(reg.getFilter()).isSameAs(filter);
    }

    @Test
    @DisplayName("productionCorsFilterRegistration setEnabled(false)")
    void productionCorsFilterServletRegistrationDisabled() {
        ProductionCorsFilter filter = Mockito.mock(ProductionCorsFilter.class);
        FilterRegistrationBean<ProductionCorsFilter> reg = config.productionCorsFilterRegistration(filter);
        assertThat(reg).isNotNull();
        assertThat(reg.isEnabled()).isFalse();
        assertThat(reg.getFilter()).isSameAs(filter);
    }
}
