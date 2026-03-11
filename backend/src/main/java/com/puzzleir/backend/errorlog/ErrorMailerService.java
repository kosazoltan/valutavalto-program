package com.puzzleir.backend.errorlog;

import jakarta.mail.internet.MimeMessage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.HexFormat;
import java.util.Optional;
import java.util.UUID;
import java.util.regex.Pattern;

@Service
@Slf4j
public class ErrorMailerService {

    private static final String APP_NAME = "Valutaváltó ERP";
    private static final String REPO_PATH = "D:\\repo\\valutavalto-program";
    private static final String FORBIDDEN_REPO = "D:\\repo\\Bookkeeper (TILOS!)";
    private static final String SENDER = "noraautomatizalas@gmail.com";
    private static final String RECIPIENT = "noraautomatizalas@gmail.com";

    private static final Pattern LINE_NUM = Pattern.compile("(:\\d+)");
    private static final Pattern HEX_ADDR = Pattern.compile("[0-9a-f]{6,}");

    @Value("${errorlog.hmac.secret:errorlog-hmac-s3cr3t-valutavalto-2026-kz}")
    private String hmacSecret;

    private final ErrorLogRepository errorLogRepo;
    private final JavaMailSender mailSender;

    public ErrorMailerService(ErrorLogRepository errorLogRepo, JavaMailSender mailSender) {
        this.errorLogRepo = errorLogRepo;
        this.mailSender = mailSender;
    }

    // ── Fingerprint ──────────────────────────────────────────────────────────

    private String normalize(String stack) {
        if (stack == null) return "";
        String s = LINE_NUM.matcher(stack).replaceAll(":N");
        s = HEX_ADDR.matcher(s).replaceAll("HASH");
        return s;
    }

    private String fingerprint(String errorType, String stack) {
        try {
            String raw = (errorType == null ? "unknown" : errorType) + ":" + normalize(stack);
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(raw.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash).substring(0, 32);
        } catch (Exception e) {
            return UUID.randomUUID().toString().replace("-", "").substring(0, 32);
        }
    }

    // ── Severity ─────────────────────────────────────────────────────────────

    private String determineSeverity(ErrorReportRequest req) {
        if (req.getSeverity() != null && !req.getSeverity().isBlank()) {
            return req.getSeverity().toUpperCase();
        }
        String et = req.getErrorType() == null ? "" : req.getErrorType().toLowerCase();
        if (et.contains("fatal") || et.contains("crash")) return "FATAL";
        if (et.contains("warn")) return "WARN";
        return "ERROR";
    }

    // ── Sanitize ─────────────────────────────────────────────────────────────

    private String sanitizeForEmail(String input, int maxLen) {
        if (input == null) return "";
        String s = input
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replaceAll("[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]", "");
        return s.length() > maxLen ? s.substring(0, maxLen) + "…" : s;
    }

    // ── HMAC ─────────────────────────────────────────────────────────────────

    private String signEmailPayload(String fp, String timestamp) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(hmacSecret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            byte[] raw = mac.doFinal((fp + ":" + timestamp).getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(raw);
        } catch (Exception e) {
            return "hmac-error";
        }
    }

    // ── Main entry ───────────────────────────────────────────────────────────

    public void sendErrorReport(ErrorReportRequest req) {
        String fp = fingerprint(req.getErrorType(), req.getStack());
        String severity = determineSeverity(req);
        String now = Instant.now().toString();

        Optional<ErrorLog> existing = errorLogRepo.findByFingerprint(fp);
        ErrorLog entry;

        if (existing.isPresent()) {
            entry = existing.get();
            entry.setOccurrenceCount(entry.getOccurrenceCount() + 1);
            entry.setLastSeenAt(Instant.now());
            entry.setSeverity(severity);
        } else {
            entry = ErrorLog.builder()
                .id(UUID.randomUUID().toString())
                .fingerprint(fp)
                .errorType(req.getErrorType() != null ? req.getErrorType() : "unknown")
                .severity(severity)
                .message(req.getMessage() != null ? req.getMessage() : "")
                .stack(req.getStack())
                .commitSha(req.getCommitSha())
                .appName(APP_NAME)
                .repoPath(REPO_PATH)
                .environment("production")
                .url(req.getUrl())
                .requestId(req.getRequestId())
                .requestMethod(req.getRequestMethod())
                .requestBody(req.getRequestBody())
                .userId(req.getUserId())
                .userEmail(req.getUserEmail())
                .browser(req.getBrowser())
                .occurrenceCount(1)
                .firstSeenAt(Instant.now())
                .lastSeenAt(Instant.now())
                .emailSent(false)
                .resolved(false)
                .createdAt(Instant.now())
                .build();
        }

        // Email cooldown: 5 perc
        boolean shouldEmail = true;
        if (entry.isEmailSent() && entry.getEmailSentAt() != null) {
            long diffSec = Instant.now().getEpochSecond() - entry.getEmailSentAt().getEpochSecond();
            if (diffSec < 300) {
                shouldEmail = false;
            }
        }

        errorLogRepo.save(entry);

        if (shouldEmail) {
            try {
                String hmac = signEmailPayload(fp, now);
                String html = buildEmailHtml(req, fp, severity, now, hmac);
                MimeMessage msg = mailSender.createMimeMessage();
                MimeMessageHelper helper = new MimeMessageHelper(msg, false, "UTF-8");
                helper.setFrom(SENDER);
                helper.setTo(RECIPIENT);
                helper.setSubject("[" + severity + "] " + APP_NAME + " hiba: " +
                    sanitizeForEmail(req.getErrorType(), 40));
                helper.setText(html, true);
                mailSender.send(msg);

                entry.setEmailSent(true);
                entry.setEmailSentAt(Instant.now());
                errorLogRepo.save(entry);
            } catch (Exception e) {
                log.warn("Failed to send error email for fingerprint {}: {}", fp, e.getMessage());
            }
        }
    }

    private String buildEmailHtml(ErrorReportRequest req, String fp, String severity, String timestamp, String hmac) {
        return "<!DOCTYPE html><html><body style='font-family:monospace;'>" +
            "<!-- HMAC:" + hmac + " -->" +
            "<!-- FINGERPRINT:" + fp + " -->" +
            "<h2 style='color:#c00;'>[" + sanitizeForEmail(severity, 10) + "] " + APP_NAME + " Error</h2>" +
            "<table border='1' cellpadding='6' style='border-collapse:collapse;'>" +
            row("App", APP_NAME) +
            row("Repo", REPO_PATH) +
            row("Type", sanitizeForEmail(req.getErrorType(), 100)) +
            row("Message", sanitizeForEmail(req.getMessage(), 500)) +
            row("URL", sanitizeForEmail(req.getUrl(), 300)) +
            row("Method", sanitizeForEmail(req.getRequestMethod(), 10)) +
            row("Request-ID", sanitizeForEmail(req.getRequestId(), 100)) +
            row("User", sanitizeForEmail(req.getUserEmail(), 200)) +
            row("Browser", sanitizeForEmail(req.getBrowser(), 200)) +
            row("Commit", sanitizeForEmail(req.getCommitSha(), 40)) +
            row("Timestamp", sanitizeForEmail(timestamp, 50)) +
            row("Fingerprint", fp) +
            "</table>" +
            "<h3>Stack Trace</h3><pre style='background:#f5f5f5;padding:12px;'>" +
            sanitizeForEmail(req.getStack(), 3000) +
            "</pre>" +
            "<p style='color:#999;font-size:11px;'>FORBIDDEN_REPO=" + FORBIDDEN_REPO + " (TILOS!)</p>" +
            "</body></html>";
    }

    private String row(String key, String val) {
        return "<tr><td><b>" + key + "</b></td><td>" + (val == null ? "" : val) + "</td></tr>";
    }
}
