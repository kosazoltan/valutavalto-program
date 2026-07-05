package hu.puzzleir.valuta.errorlog;

import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
@Slf4j
@RequiredArgsConstructor
public class StaticAuditService {

    private final EntityManager entityManager;
    private final ErrorMailerService errorMailerService;

    @Value("${spring.mail.password:}")
    private String mailPassword;

    public List<AuditCheck> runStaticAudit() {
        List<AuditCheck> checks = new ArrayList<>();
        boolean anyFail = false;

        // CHECK 1: DB connection
        try {
            entityManager.createNativeQuery("SELECT 1").getSingleResult();
            checks.add(AuditCheck.builder().name("DB connection").pass(true).detail("OK").build());
        } catch (Exception e) {
            checks.add(AuditCheck.builder().name("DB connection").pass(false).detail(e.getMessage()).build());
            anyFail = true;
        }

        // CHECK 2: Env vars (NEON/DATABASE fail-closed; a tobbi CSAK informacios lathatosag)
        String[] envVars = {"NEON_DATABASE_URL", "DATABASE_URL", "ERRORLOG_HMAC_SECRET", "JUNIOR_EMAIL_PASSWORD", "APP_RATE_PRINT_HMAC_SECRET"};
        // At least one DB var must be set
        boolean dbEnvOk = System.getenv("NEON_DATABASE_URL") != null || System.getenv("DATABASE_URL") != null;
        checks.add(AuditCheck.builder()
            .name("DB env var (NEON_DATABASE_URL or DATABASE_URL)")
            .pass(dbEnvOk)
            .detail(dbEnvOk ? "SET" : "MISSING")
            .build());
        if (!dbEnvOk) anyFail = true;

        for (String var : new String[]{"ERRORLOG_HMAC_SECRET", "JUNIOR_EMAIL_PASSWORD", "APP_RATE_PRINT_HMAC_SECRET"}) {
            boolean set = System.getenv(var) != null;
            checks.add(AuditCheck.builder().name(var).pass(set).detail(set ? "SET" : "using default").build());
        }

        // CHECK 3: spring.mail.password
        boolean mailOk = mailPassword != null && !mailPassword.isBlank();
        checks.add(AuditCheck.builder()
            .name("spring.mail.password")
            .pass(mailOk)
            .detail(mailOk ? "CONFIGURED" : "MISSING")
            .build());
        if (!mailOk) anyFail = true;

        if (anyFail) {
            try {
                errorMailerService.sendErrorReport(ErrorReportRequest.builder()
                    .errorType("static_audit")
                    .message("Static audit FAIL: " + checks.stream()
                        .filter(c -> !c.isPass())
                        .map(AuditCheck::getName)
                        .reduce("", (a, b) -> a.isEmpty() ? b : a + ", " + b))
                    .severity("WARN")
                    .timestamp(java.time.Instant.now().toString())
                    .build());
            } catch (Exception e) {
                log.error("Failed to send static audit error report", e);
            }
        }

        return checks;
    }
}
