package hu.puzzleir.valuta.config;

import hu.puzzleir.valuta.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.stereotype.Component;

/**
 * WebSocket STOMP channel interceptor — JWT validálás CONNECT frame-eken.
 *
 * A HTTP upgrade handshake-en túl a STOMP CONNECT üzenetekben is
 * ellenőrzi a JWT tokent, megakadályozva a jogosulatlan feliratkozást.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class WebSocketAuthInterceptor implements ChannelInterceptor {

    private final JwtTokenProvider jwtTokenProvider;

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);

        if (accessor != null && StompCommand.CONNECT.equals(accessor.getCommand())) {
            String authHeader = accessor.getFirstNativeHeader("Authorization");

            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                log.warn("WebSocket CONNECT elutasítva: hiányzó Authorization header");
                throw new org.springframework.messaging.MessageDeliveryException(
                        "Hiányzó vagy érvénytelen Authorization header!");
            }

            String token = authHeader.substring(7);
            if (!jwtTokenProvider.validateToken(token)) {
                log.warn("WebSocket CONNECT elutasítva: érvénytelen JWT token");
                throw new org.springframework.messaging.MessageDeliveryException(
                        "Érvénytelen JWT token!");
            }

            log.debug("WebSocket CONNECT engedélyezve: worker={}",
                    jwtTokenProvider.getWorkerCodeFromToken(token));
        }

        return message;
    }
}
