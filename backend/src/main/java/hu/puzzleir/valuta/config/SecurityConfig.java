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
                .requestMatchers("/api/v1/auth/login", "/api/v1/auth/google-login", "/api/v1/auth/refresh").permitAll()
                .requestMatchers("/api/v1/auth/bootstrap-admin", "/api/v1/auth/bootstrap-status").permitAll()
                .requestMatchers("/api/v1/public/**").permitAll()
                .requestMatchers("/api/v1/email/accounts/callback").permitAll()
                .requestMatchers("/api/v1/error-report", "/api/v1/error-log").permitAll()
                .requestMatchers("/api/v1/version").permitAll()

                // Health check — csak health és info, nem az összes actuator endpoint
                .requestMatchers("/actuator/health", "/actuator/info").permitAll()
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
    
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
