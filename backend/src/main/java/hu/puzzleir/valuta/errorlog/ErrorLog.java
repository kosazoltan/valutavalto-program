package hu.puzzleir.valuta.errorlog;

import jakarta.persistence.*;
import lombok.*;
import java.time.Instant;

@Entity
@Table(name = "error_logs", indexes = {
    @Index(name = "error_logs_fingerprint_idx", columnList = "fingerprint"),
    @Index(name = "error_logs_severity_idx", columnList = "severity"),
    @Index(name = "error_logs_resolved_idx", columnList = "resolved"),
    @Index(name = "error_logs_created_at_idx", columnList = "created_at")
})
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class ErrorLog {
    @Id
    @Column(length = 36)
    private String id;

    @Column(name = "fingerprint", length = 32, nullable = false, unique = true)
    private String fingerprint;

    @Column(name = "error_type", length = 50, nullable = false)
    private String errorType;

    @Column(name = "severity", length = 10, nullable = false)
    private String severity = "ERROR";

    @Column(name = "message", columnDefinition = "TEXT", nullable = false)
    private String message;

    @Column(name = "stack", columnDefinition = "TEXT")
    private String stack;

    @Column(name = "commit_sha", length = 40)
    private String commitSha;

    @Column(name = "app_name", length = 50, nullable = false)
    private String appName = "Valutaváltó ERP";

    @Column(name = "repo_path", length = 100, nullable = false)
    private String repoPath = "D:/repo/valutavalto-program";

    @Column(name = "environment", length = 20, nullable = false)
    private String environment = "production";

    @Column(name = "url", length = 500)
    private String url;

    @Column(name = "request_id", length = 100)
    private String requestId;

    @Column(name = "request_method", length = 10)
    private String requestMethod;

    @Column(name = "request_body", columnDefinition = "TEXT")
    private String requestBody;

    @Column(name = "user_id", length = 100)
    private String userId;

    @Column(name = "user_email", length = 200)
    private String userEmail;

    @Column(name = "browser", length = 300)
    private String browser;

    @Column(name = "occurrence_count", nullable = false)
    private int occurrenceCount = 1;

    @Column(name = "first_seen_at", nullable = false)
    private Instant firstSeenAt = Instant.now();

    @Column(name = "last_seen_at", nullable = false)
    private Instant lastSeenAt = Instant.now();

    @Column(name = "email_sent", nullable = false)
    @Builder.Default
    private boolean emailSent = false;

    @Column(name = "email_sent_at")
    private Instant emailSentAt;

    @Column(name = "resolved", nullable = false)
    @Builder.Default
    private boolean resolved = false;

    @Column(name = "resolved_at")
    private Instant resolvedAt;

    @Column(name = "resolved_commit", length = 40)
    private String resolvedCommit;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();
}
