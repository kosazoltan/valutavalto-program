package hu.puzzleir.valuta.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.sql.DataSource;
import java.lang.management.GarbageCollectorMXBean;
import java.lang.management.ManagementFactory;
import java.lang.management.MemoryMXBean;
import java.lang.management.ThreadMXBean;
import java.sql.Connection;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Egészségügyi és rendszer-információs végpontok.
 */
@RestController
@RequestMapping("/api/v1/health")
@RequiredArgsConstructor
@Tag(name = "Rendszer", description = "Health check és rendszer információk")
public class HealthController {

    private final DataSource dataSource;
    private static final Instant START_TIME = Instant.now();

    @Value("${spring.application.name:valuta-backend}")
    private String appName;

    /**
     * Alap health check.
     * GET /api/v1/health
     */
    @GetMapping
    @Operation(summary = "Alap health check")
    public ResponseEntity<Map<String, Object>> healthCheck() {
        Map<String, Object> health = new LinkedHashMap<>();
        health.put("status", "UP");
        health.put("timestamp", LocalDateTime.now().toString());
        health.put("uptime", formatUptime());
        health.put("version", "2.0.0");
        health.put("db", checkDatabaseConnection() ? "connected" : "disconnected");
        return ResponseEntity.ok(health);
    }

    /**
     * Részletes health check — JVM, DB, app metrikák.
     * GET /api/v1/health/detailed
     */
    @GetMapping("/detailed")
    @Operation(summary = "Részletes health check (JVM, DB, app metrikák)")
    public ResponseEntity<Map<String, Object>> detailedHealthCheck() {
        Map<String, Object> health = new LinkedHashMap<>();
        health.put("status", "UP");
        health.put("timestamp", LocalDateTime.now().toString());
        health.put("uptime", formatUptime());
        health.put("version", "2.0.0");

        // Database info
        Map<String, Object> database = new LinkedHashMap<>();
        long dbStart = System.currentTimeMillis();
        boolean dbConnected = checkDatabaseConnection();
        long dbResponseTime = System.currentTimeMillis() - dbStart;
        database.put("connected", dbConnected);
        database.put("responseTimeMs", dbResponseTime);
        database.put("activeConnections", getActiveConnections());
        health.put("database", database);

        // JVM info
        MemoryMXBean memoryBean = ManagementFactory.getMemoryMXBean();
        ThreadMXBean threadBean = ManagementFactory.getThreadMXBean();
        Map<String, Object> jvm = new LinkedHashMap<>();
        jvm.put("heapUsed", memoryBean.getHeapMemoryUsage().getUsed());
        jvm.put("heapMax", memoryBean.getHeapMemoryUsage().getMax());
        jvm.put("threads", threadBean.getThreadCount());
        long gcCount = ManagementFactory.getGarbageCollectorMXBeans().stream()
                .mapToLong(GarbageCollectorMXBean::getCollectionCount)
                .filter(c -> c >= 0)
                .sum();
        jvm.put("gcCount", gcCount);
        health.put("jvm", jvm);

        // App info
        Map<String, Object> app = new LinkedHashMap<>();
        app.put("totalTransactions", "N/A");
        app.put("activeWorkers", "N/A");
        app.put("activeBranches", "N/A");
        app.put("lastSync", "N/A");
        health.put("app", app);

        return ResponseEntity.ok(health);
    }

    /**
     * Alkalmazás információk.
     * GET /api/v1/health/info
     */
    @GetMapping("/info")
    @Operation(summary = "Alkalmazás verzió és build információk")
    public ResponseEntity<Map<String, Object>> appInfo() {
        Map<String, Object> info = new LinkedHashMap<>();
        info.put("name", appName);
        info.put("version", "2.0.0");
        info.put("buildTime", "2026-03-06T00:00:00");
        info.put("gitCommit", "N/A");
        info.put("environment", System.getenv("SPRING_PROFILES_ACTIVE") != null
                ? System.getenv("SPRING_PROFILES_ACTIVE") : "default");
        info.put("javaVersion", System.getProperty("java.version"));
        return ResponseEntity.ok(info);
    }

    // --- Helpers ---

    private boolean checkDatabaseConnection() {
        try (Connection conn = dataSource.getConnection()) {
            return conn.isValid(3);
        } catch (Exception e) {
            return false;
        }
    }

    private int getActiveConnections() {
        // HikariCP-specific; fallback -1 if not available
        try {
            var hikari = (com.zaxxer.hikari.HikariDataSource) dataSource;
            var pool = hikari.getHikariPoolMXBean();
            return pool != null ? pool.getActiveConnections() : -1;
        } catch (Exception e) {
            return -1;
        }
    }

    private String formatUptime() {
        Duration uptime = Duration.between(START_TIME, Instant.now());
        long days = uptime.toDays();
        long hours = uptime.toHoursPart();
        long minutes = uptime.toMinutesPart();
        long seconds = uptime.toSecondsPart();
        if (days > 0) {
            return String.format("%dd %dh %dm %ds", days, hours, minutes, seconds);
        }
        return String.format("%dh %dm %ds", hours, minutes, seconds);
    }
}
