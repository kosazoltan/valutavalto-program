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
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * Security configuration - JWT authentication + CORS.
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final IdempotencyFilter idempotencyFilter;

    @Value("${cors.allowed-origins:http://localhost:3000,http://localhost:3001,http://localhost:3002,http://localhost:5173,https://excvaluta.com,https://www.excvaluta.com,https://valutavalto.vercel.app,app://localhost}")
    private String corsAllowedOrigins;

    public SecurityConfig(JwtAuthenticationFilter jwtAuthenticationFilter,
                          IdempotencyFilter idempotencyFilter) {
        this.jwtAuthenticationFilter = jwtAuthenticationFilter;
        this.idempotencyFilter = idempotencyFilter;
    }
    
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            // CSRF kikapcsolás (stateless JWT használat miatt)
            .csrf(csrf -> csrf.disable())
            
            // CORS engedélyezés
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            
            // Stateless session (JWT authentication)
            .sessionManagement(session -> 
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            )
            
            // Authorization rules
            .authorizeHttpRequests(auth -> auth
                // Public endpoints (login)
                .requestMatchers("/api/v1/auth/login", "/api/v1/auth/google-login", "/api/v1/auth/refresh").permitAll()
                .requestMatchers("/api/v1/email/accounts/callback").permitAll()
                .requestMatchers("/api/v1/error-report").permitAll()
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

                // Worker management - csak SUPERVISOR és feljebb (a többi endpoint)
                .requestMatchers("/api/v1/workers/**").hasAnyRole("SUPERVISOR", "MANAGER", "ADMIN")

                // Company endpoints - csak ADMIN
                .requestMatchers("/api/v1/companies/**").hasRole("ADMIN")

                // Minden más endpoint - autentikáció szükséges
                .anyRequest().authenticated()
            )
            
            // JWT filter hozzáadás (UsernamePasswordAuthenticationFilter előtt)
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class)

            // Idempotency header enforcement (JWT után, de UsernamePassword előtt)
            .addFilterBefore(idempotencyFilter, UsernamePasswordAuthenticationFilter.class);
        
        return http.build();
    }
    
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();

        // CORS origins kornyezeti valtozobol (vesszovel elvalasztva, whitespace trim)
        // A kritikus production originok mindig engedelyezettek maradnak akkor is,
        // ha a runtime CORS_ALLOWED_ORIGINS valtozo hianyos.
        List<String> configuredOrigins = Arrays.stream(corsAllowedOrigins.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .toList();

        List<String> allowedOrigins = new ArrayList<>();
        List<String> allowedOriginPatterns = new ArrayList<>();

        for (String origin : configuredOrigins) {
            if (origin.contains("*")) {
                allowedOriginPatterns.add(origin);
            } else {
                allowedOrigins.add(origin);
            }
        }

        for (String mandatoryOrigin : List.of(
                "https://excvaluta.com",
                "https://www.excvaluta.com",
                "https://valutavalto.vercel.app"
        )) {
            if (!allowedOrigins.contains(mandatoryOrigin)) {
                allowedOrigins.add(mandatoryOrigin);
            }
        }

        configuration.setAllowedOrigins(allowedOrigins);
        configuration.setAllowedOriginPatterns(allowedOriginPatterns);
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"));
        configuration.setAllowedHeaders(Arrays.asList(
                "Authorization", "Content-Type", "X-Requested-With", "Accept", "Origin",
                "Access-Control-Request-Method", "Access-Control-Request-Headers",
                "Idempotency-Key"));
        configuration.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
    
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
