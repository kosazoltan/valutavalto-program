package hu.puzzleir.valuta.errorlog;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import jakarta.mail.internet.MimeMessage;
import jakarta.servlet.http.HttpServletRequest;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

@RestController
@RequestMapping("/api/v1/error-report")
@RequiredArgsConstructor
public class ErrorLogController {

    private static final String RECIPIENT = "noraautomatizalas@gmail.com";
    private static final String SUBJECT = "[VALUTAVALTO HIBA] [REPO: D:\\repo\\valutavalto-program]";
    private static final long RATE_LIMIT_WINDOW_MS = 60_000L;
    private static final int RATE_LIMIT_MAX_REQUESTS = 10;

    private final JavaMailSender mailSender;
    private final ObjectMapper objectMapper;
    private final ConcurrentHashMap<String, RateLimitEntry> rateLimits = new ConcurrentHashMap<>();

    @Value("${errorlog.hmac.secret:}")
    private String hmacSecret;

    @PostMapping
    public ResponseEntity<Map<String, Object>> reportError(
        @RequestBody String rawBody,
        @RequestHeader(value = "X-Error-Signature", required = false) String signature,
        HttpServletRequest request
    ) {
        String clientIp = resolveClientIp(request);
        if (isRateLimited(clientIp)) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS).body(Map.of("error", "Rate limit exceeded"));
        }
        if (signature == null || signature.isBlank()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Missing signature"));
        }
        if (hmacSecret == null || hmacSecret.isBlank()) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", "HMAC secret missing"));
        }

        String expected = hmacSha256(rawBody, hmacSecret);
        if (!timingSafeEquals(signature, expected)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Invalid signature"));
        }

        try {
            ErrorLogPayload payload = objectMapper.readValue(rawBody, ErrorLogPayload.class);
            String body = objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(payload);
            sendEmail(body);
            return ResponseEntity.ok(Map.of("ok", true));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("error", "Invalid payload"));
        }
    }

    private boolean isRateLimited(String clientIp) {
        long now = System.currentTimeMillis();
        RateLimitEntry entry = rateLimits.compute(clientIp, (key, existing) -> {
            if (existing == null || now - existing.windowStartMs >= RATE_LIMIT_WINDOW_MS) {
                return new RateLimitEntry(now);
            }
            return existing;
        });
        return entry.counter.incrementAndGet() > RATE_LIMIT_MAX_REQUESTS;
    }

    private String resolveClientIp(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            int commaIndex = forwarded.indexOf(',');
            return commaIndex >= 0 ? forwarded.substring(0, commaIndex).trim() : forwarded.trim();
        }
        return request.getRemoteAddr();
    }

    private void sendEmail(String body) throws Exception {
        MimeMessage message = mailSender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(message, false, "UTF-8");
        helper.setTo(RECIPIENT);
        helper.setFrom(RECIPIENT);
        helper.setSubject(SUBJECT);
        helper.setText(body, false);
        mailSender.send(message);
    }

    private String hmacSha256(String data, String secret) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            return HexFormat.of().formatHex(mac.doFinal(data.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            return "";
        }
    }

    private boolean timingSafeEquals(String a, String b) {
        return MessageDigest.isEqual(
            a.getBytes(StandardCharsets.UTF_8),
            b.getBytes(StandardCharsets.UTF_8)
        );
    }

    private static final class RateLimitEntry {
        private final long windowStartMs;
        private final AtomicInteger counter = new AtomicInteger(0);

        private RateLimitEntry(long windowStartMs) {
            this.windowStartMs = windowStartMs;
        }
    }

    public record ErrorLogPayload(
        String errorType,
        String message,
        String stack,
        String appVersion,
        String timestamp
    ) {}
}
