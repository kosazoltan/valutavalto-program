package hu.puzzleir.valuta.config;

import hu.puzzleir.valuta.security.JwtAuthenticationFilter;
import hu.puzzleir.valuta.security.IdempotencyFilter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

/**
 * Security configuration - JWT authentication + CORS.
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final IdempotencyFilter idempotencyFilter;
    private final ProductionCorsFilter productionCorsFilter;

    public SecurityConfig(JwtAuthenticationFilter jwtAuthenticationFilter,
                          IdempotencyFilter idempotencyFilter,
                          ProductionCorsFilter productionCorsFilter) {
        this.jwtAuthenticationFilter = jwtAuthenticationFilter;
        this.idempotencyFilter = idempotencyFilter;
        this.productionCorsFilter = productionCorsFilter;
    }
    
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            // CSRF kikapcsolás (stateless JWT használat miatt)
            .csrf(csrf -> csrf.disable())
            
            // Stateless session (JWT authentication)
            .sessionManagement(session -> 
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            )
            
            // Authorization rules
            .authorizeHttpRequests(auth -> auth
                // Public endpoints (login)
                .requestMatchers("/api/v1/auth/login", "/api/v1/auth/google-login", "/api/v1/auth/refresh", "/api/v1/auth/refresh-cookie").permitAll()
                .requestMatchers("/api/v1/auth/bootstrap-admin", "/api/v1/auth/bootstrap-status").permitAll()
                // v2.3.0: uj auth endpoint-ok (worker first-time setup + forgot/reset password)
                .requestMatchers("/api/v1/auth/first-time-worker-setup").permitAll()
                .requestMatchers("/api/v1/auth/forgot-password", "/api/v1/auth/reset-password").permitAll()
                .requestMatchers("/api/v1/public/**").permitAll()
                .requestMatchers("/api/v1/email/accounts/callback").permitAll()
                .requestMatchers("/api/v1/error-report", "/api/v1/error-log").permitAll()
                // v2.5.15: kliens-oldali hibajelentes (Penztar.exe -> backend), no auth
                .requestMatchers("/api/v1/diagnostics/error-report", "/api/v1/diagnostics/health").permitAll()
                .requestMatchers("/api/v1/version").permitAll()

                // Health check — csak health és info, nem az összes actuator endpoint
                .requestMatchers("/actuator/health", "/actuator/info").permitAll()
                .requestMatchers("/actuator/prometheus").permitAll()
                .requestMatchers("/actuator/**").hasRole("ADMIN")
                .requestMatchers("/api/v1/health").permitAll()
                .requestMatchers("/api/v1/health/**").authenticated()

                // Swagger / OpenAPI docs — JWT autentikáció mögött (adatszivárgás elleni védelem)
                // Production-ban a springdoc teljesen ki van kapcsolva (application-prod.properties)
                .requestMatchers("/swagger-ui/**", "/swagger-ui.html", "/api-docs/**", "/v3/api-docs/**").authenticated()

                // WebSocket endpoint
                .requestMatchers("/ws/**").authenticated()

                // Camera live stream - minden bejelentkezett user
                .requestMatchers("/api/v1/camera/stream/**").authenticated()

                // Branch endpoints - minden bejelentkezett user
                .requestMatchers("/api/v1/branches/**").authenticated()

                // Worker self-profile - minden bejelentkezett user
                .requestMatchers("/api/v1/workers/me").authenticated()
                .requestMatchers("/api/v1/workers/active").authenticated()

                // Worker management - csak SUPERVISOR és feljebb (a többi endpoint)
                .requestMatchers("/api/v1/workers/**").hasAnyRole("SUPERVISOR", "MANAGER", "ADMIN")

                // Company endpoints - csak ADMIN
                .requestMatchers("/api/v1/companies/**").hasRole("ADMIN")

                // Minden más endpoint - autentikáció szükséges
                .anyRequest().authenticated()
            )

            // Security response headers (OWASP best practices)
            .headers(headers -> headers
                .contentTypeOptions(contentType -> {})  // X-Content-Type-Options: nosniff
                .frameOptions(frame -> frame.deny())     // X-Frame-Options: DENY
                .httpStrictTransportSecurity(hsts -> hsts
                    .includeSubDomains(true)
                    .maxAgeInSeconds(31536000))           // HSTS 1 year
                .referrerPolicy(referrer -> referrer
                    .policy(org.springframework.security.web.header.writers.ReferrerPolicyHeaderWriter.ReferrerPolicy.STRICT_ORIGIN_WHEN_CROSS_ORIGIN))
                .permissionsPolicyHeader(permissions -> permissions
                    .policy("camera=(), microphone=(), geolocation=()"))
            )

            // 401 Unauthorized (nem 403) ha nincs/érvénytelen token (F-07 security fix)
            .exceptionHandling(ex -> ex
                .authenticationEntryPoint((request, response, authException) -> {
                    response.setContentType("application/json;charset=UTF-8");
                    response.setStatus(401);
                    response.getWriter().write("{\"status\":401,\"error\":\"UNAUTHORIZED\",\"message\":\"Hitelesítés szükséges\"}");
                })
            )

            .addFilterBefore(productionCorsFilter, UsernamePasswordAuthenticationFilter.class)
            
            // JWT filter hozzáadás (UsernamePasswordAuthenticationFilter előtt)
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class)

            // Idempotency header enforcement (JWT után, de UsernamePassword előtt)
            .addFilterBefore(idempotencyFilter, UsernamePasswordAuthenticationFilter.class);
        
        return http.build();
    }
    
    /**
     * BCrypt password encoder strength=12 (2026-05-06 audit fix).
     *
     * <p>A default strength=10 (Spring 6+) megfelel az iparági alapvető szintnek,
     * de pénzügyi rendszerekhez 2024+ óta strength=12 ajánlott (NIST SP 800-63B
     * + OWASP ASVS 4.0.3 §2.4.1). A 12-es strength ~4x lassabb hash-elés
     * (~200ms) csökkenti az offline brute-force támadás kockázatát.</p>
     *
     * <p>Hatás:
     * <ul>
     *   <li>Új jelszavak: strength=12-vel hashelődnek</li>
     *   <li>Régi jelszavak (strength=10): továbbra is verifikálhatók, mert a
     *       BCrypt formátum tartalmazza a strength-et</li>
     *   <li>Login lassulás: ~150ms helyett ~600ms (egyszer per session, OK)</li>
     * </ul>
     * </p>
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(12);
    }
}
