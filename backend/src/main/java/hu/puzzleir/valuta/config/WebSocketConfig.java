package hu.puzzleir.valuta.config;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * WebSocket configuration for real-time rate updates.
 * STOMP over WebSocket — pénztárak kapják az árfolyam-frissítéseket.
 */
@Configuration
@EnableWebSocketMessageBroker
@RequiredArgsConstructor
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Value("${cors.allowed-origins:http://localhost:3000,http://localhost:3001,http://localhost:3002,http://localhost:5173,https://excvaluta.com,https://www.excvaluta.com,https://excbesttest.com,https://www.excbesttest.com,https://valutavalto.vercel.app,app://localhost}")
    private String corsAllowedOrigins;

    private final WebSocketAuthInterceptor webSocketAuthInterceptor;

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic");
        config.setApplicationDestinationPrefixes("/app");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        List<String> configuredOrigins = new ArrayList<>(
                Arrays.stream(corsAllowedOrigins.split(","))
                        .map(String::trim)
                        .filter(s -> !s.isEmpty())
                        .toList()
        );

        // SSOT refaktor (2026-04-24): excvaluta.com konstansok a ProductionUrls-bol
        List<String> mandatoryOrigins = List.of(
            ProductionUrls.BASE_URL,
            ProductionUrls.WWW_BASE_URL,
            "https://valutavalto.vercel.app",
            "app://localhost"
        );
        for (String mandatoryOrigin : mandatoryOrigins) {
            if (!configuredOrigins.contains(mandatoryOrigin)) {
            configuredOrigins.add(mandatoryOrigin);
            }
        }

        List<String> originPatterns = configuredOrigins.stream()
            .filter(origin -> origin.contains("*"))
            .toList();

        registry.addEndpoint("/ws")
            .setAllowedOriginPatterns(originPatterns.toArray(new String[0]))
            .setAllowedOrigins(
                configuredOrigins.stream()
                    .filter(origin -> !origin.contains("*"))
                    .toArray(String[]::new)
            )
                .withSockJS();
    }

    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        registration.interceptors(webSocketAuthInterceptor);
    }
}
