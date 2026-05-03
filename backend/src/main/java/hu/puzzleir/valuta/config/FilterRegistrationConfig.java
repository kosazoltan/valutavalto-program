package hu.puzzleir.valuta.config;

import hu.puzzleir.valuta.security.IdempotencyFilter;
import hu.puzzleir.valuta.security.JwtAuthenticationFilter;
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
 */
@Configuration
public class FilterRegistrationConfig {

    @Bean
    public FilterRegistrationBean<JwtAuthenticationFilter> jwtFilterRegistration(
            JwtAuthenticationFilter filter) {
        FilterRegistrationBean<JwtAuthenticationFilter> registration = new FilterRegistrationBean<>(filter);
        registration.setEnabled(false);
        return registration;
    }

    @Bean
    public FilterRegistrationBean<IdempotencyFilter> idempotencyFilterRegistration(
            IdempotencyFilter filter) {
        FilterRegistrationBean<IdempotencyFilter> registration = new FilterRegistrationBean<>(filter);
        registration.setEnabled(false);
        return registration;
    }

    @Bean
    public FilterRegistrationBean<ProductionCorsFilter> productionCorsFilterRegistration(
            ProductionCorsFilter filter) {
        FilterRegistrationBean<ProductionCorsFilter> registration = new FilterRegistrationBean<>(filter);
        registration.setEnabled(false);
        return registration;
    }
}
