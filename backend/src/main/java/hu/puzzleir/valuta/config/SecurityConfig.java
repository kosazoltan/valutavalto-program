package hu.puzzleir.valuta.config;

import hu.puzzleir.valuta.security.JwtAuthenticationFilter;
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

import java.util.Arrays;

/**
 * Security configuration - JWT authentication + CORS.
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {
    
    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    
    public SecurityConfig(JwtAuthenticationFilter jwtAuthenticationFilter) {
        this.jwtAuthenticationFilter = jwtAuthenticationFilter;
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
                .requestMatchers("/api/v1/auth/login", "/api/v1/auth/refresh").permitAll()
                
                // Health check
                .requestMatchers("/actuator/**").permitAll()
                
                // Branch endpoints - minden bejelentkezett user
                .requestMatchers("/api/v1/branches/**").authenticated()
                
                // Worker management - csak SUPERVISOR és feljebb
                .requestMatchers("/api/v1/workers/**").hasAnyRole("SUPERVISOR", "MANAGER", "ADMIN")
                
                // Company endpoints - csak ADMIN
                .requestMatchers("/api/v1/companies/**").hasRole("ADMIN")
                
                // Minden más endpoint - autentikáció szükséges
                .anyRequest().authenticated()
            )
            
            // JWT filter hozzáadás
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
        
        return http.build();
    }
    
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(Arrays.asList(
            "http://localhost:3000",    // React dev server
            "http://localhost:5173"     // Vite dev server
        ));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"));
        configuration.setAllowedHeaders(Arrays.asList("*"));
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
