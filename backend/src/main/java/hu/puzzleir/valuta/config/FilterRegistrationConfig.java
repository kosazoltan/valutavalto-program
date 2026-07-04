package hu.puzzleir.valuta.config;

import hu.puzzleir.valuta.security.IdempotencyFilter;
import hu.puzzleir.valuta.security.JwtAuthenticationFilter;
import hu.puzzleir.valuta.security.CompanyCodeCrossCheckFilter;
import jakarta.servlet.Filter;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Audit P0.6 (2026-05-03): a `JwtAuthenticationFilter`, `IdempotencyFilter`,
 * `ProductionCorsFilter` `@Component`-ek, igy Spring Boot a Servlet container
 * filter-chain-jebe AUTOMATIKUSAN regisztralja oket. EZUTAN a `SecurityConfig`
 * `addFilterBefore(...)` hivasa a Spring Security chain-jebe is felveszi —
 * tehat ket helyen futnak, ami:
 *
 * <ol>
 *   <li>OncePerRequestFilter eseten ugyan idempotens (request-attribute flag),
 *       de ket regisztracio = ket ordering forras = CONFUSING.</li>
 *   <li>Ha a Servlet container ordering eltert a Security ordering-tol, kovetkezetes
 *       hibakat okozhat.</li>
 * </ol>
 *
 * <p>Megoldas: a Servlet container auto-regisztraciot DIS-able-eljuk, igy a
 * filterek CSAK a Security chain-en keresztul futnak (mar SecurityConfig
 * addFilterBefore-jevel definialt ordering-gel).</p>
 *
 * <p>NOTE — Sourcery PR #357 false positive: a `ProductionCorsFilter` ugyanezen
 * `hu.puzzleir.valuta.config` package-ben van, igy explicit import NEM kell
 * (a 3 unit teszt PASS-elt is). A Sourcery static analysis tevedett.</p>
 */
@Configuration
public class FilterRegistrationConfig {

    /**
     * Sourcery PR #357 follow-up: generikus helper a 3 azonos pattern (filter ->
     * disabled FilterRegistrationBean) kivaltasara, hogy a config DRY legyen.
     */
    private <T extends Filter> FilterRegistrationBean<T> disabledRegistration(T filter) {
        FilterRegistrationBean<T> registration = new FilterRegistrationBean<>(filter);
        registration.setEnabled(false);
        return registration;
    }

    @Bean
    public FilterRegistrationBean<JwtAuthenticationFilter> jwtFilterRegistration(
            JwtAuthenticationFilter filter) {
        return disabledRegistration(filter);
    }

    @Bean
    public FilterRegistrationBean<IdempotencyFilter> idempotencyFilterRegistration(
            IdempotencyFilter filter) {
        return disabledRegistration(filter);
    }

    @Bean
    public FilterRegistrationBean<CompanyCodeCrossCheckFilter> companyCodeCrossCheckFilterRegistration(
            CompanyCodeCrossCheckFilter filter) {
        return disabledRegistration(filter);
    }

    @Bean
    public FilterRegistrationBean<ProductionCorsFilter> productionCorsFilterRegistration(
            ProductionCorsFilter filter) {
        return disabledRegistration(filter);
    }
}
