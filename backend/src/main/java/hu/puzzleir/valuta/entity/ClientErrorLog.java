package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;

/**
 * Kliens-oldali hibajelentes (Penztar.exe Electron + NSIS Installer + renderer axios).
 *
 * <p>2026-05-05 user-direktiva: a kollegak gepen tortenо hibakat AUTOMATIKUSAN
 * a backend POST /api/v1/diagnostics/error-report endpointra kuldjuk, NEM kell
 * manualis debug-utasitast adni. SSH-val SQL-lekerdezessel bármikor
 * megtekinthetо.</p>
 *
 * <p>Forrás: V182 migracio.</p>
 */
@Entity
@Table(name = "client_error_log")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ClientErrorLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    /**
     * A hiba forrása: 'electron-main' | 'electron-renderer' | 'nsis-installer' | 'axios-http'.
     */
    @Column(name = "component", nullable = false, length = 80)
    private String component;

    @Column(name = "version", length = 40)
    private String version;

    @Column(name = "os_info", length = 200)
    private String osInfo;

    @Column(name = "user_identifier", length = 150)
    private String userIdentifier;

    @Column(name = "error_message", nullable = false, length = 1000)
    private String errorMessage;

    @Column(name = "stack_trace", columnDefinition = "TEXT")
    private String stackTrace;

    /**
     * Strukturált kontextus JSON formátumban.
     * Példa: {"url": "https://...", "httpStatus": 500, "branchCode": "EBC", "installMode": "THIN"}
     */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "context", columnDefinition = "JSONB")
    private String contextJson;

    /**
     * IPv4 vagy IPv6 cím (max 45 char: IPv6 39 char + esetleg ::ffff:1.2.3.4 IPv4-mapped).
     * V183 (2026-05-05): INET → VARCHAR(45) Hibernate kompat miatt.
     */
    @Column(name = "client_ip", length = 45)
    private String clientIp;

    @Column(name = "user_agent", length = 300)
    private String userAgent;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = LocalDateTime.now();
    }
}
