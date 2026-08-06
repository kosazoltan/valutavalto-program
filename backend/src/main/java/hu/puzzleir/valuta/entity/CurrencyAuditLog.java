package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * V238 (2026-05-19) — Currency modositasok immutable audit log.
 *
 * <p>Kosa Zoltan user-direktiva: az Arfolyamkeszitoben minden valuta-modositast
 * rgzítsunk, az adatbazisbol soha nem torolunk (Pmt./NAV 8-eves megorzes).</p>
 *
 * <p>A `currency_audit_log` table-en immutable trigger (UPDATE+DELETE tiltott).
 * V234 audit_log-hoz hasonlo tamper-evidence, de NEM hash-chain (nem szukseges
 * itt, mert a Currency modositasok ritkak).</p>
 */
@Entity
@Table(name = "currency_audit_log")
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CurrencyAuditLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "currency_id", nullable = false)
    private Long currencyId;

    @Column(name = "currency_code", nullable = false, length = 10)
    private String currencyCode;

    /**
     * CREATE / ACTIVATE / DEACTIVATE / UPDATE.
     */
    @Column(nullable = false, length = 20)
    private String action;

    /** Az allapot a muvelet ELOTT (JSONB), CREATE eseten NULL. */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "old_value", columnDefinition = "jsonb")
    private String oldValue;

    /** Az allapot a muvelet UTAN (JSONB). */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "new_value", columnDefinition = "jsonb", nullable = false)
    private String newValue;

    @Column(name = "worker_id")
    private Long workerId;

    @Column(name = "company_id")
    private UUID companyId;

    @Column(name = "ip_address", length = 45)
    private String ipAddress;

    @Column(name = "user_agent", length = 500)
    private String userAgent;

    @Column(columnDefinition = "TEXT")
    private String note;

    // VV-FIX (2026-05-21): OffsetDateTime -> LocalDateTime. A @EnableJpaAuditing default
    // DateTimeProvider LocalDateTime-ot ad (a kódbázis konvenció, pl. AuditLog.createdAt is
    // LocalDateTime + timestamp). Az OffsetDateTime/timestamptz kilógott → az auditing
    // LocalDateTime-ja nem volt köthető → audit save dobott → @Transactional rollback-only
    // → a createCurrency/setActive 500-azott. A V253 migráció a DB-oszlopot is timestamp-ra állítja.
    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    /**
     * {@code created_at} védőháló — az {@link AuditLog#applyCreatedAtFallback()} bevált mintája.
     * A mező {@code nullable = false}, az értéket viszont kizárólag a {@code @CreatedDate}
     * auditing tölti. Repo-szabály: a {@code TestApplication}-alapú Spring-kontextusokban az
     * {@code @EnableJpaAuditing} TILOS (suite-szintű törést okozott — a többi tesztosztály
     * kézi createdAt-seedelését írta felül, ld. EntityCreatedAtAuditingRegressionPostgresIT),
     * tehát az auditing nélküli útvonal NOT NULL-sértéssel esne el, holott az auditálandó
     * esemény hibátlan. Egy audit-bejegyzés nem veszhet el emiatt.
     *
     * <p><b>Élesben ez sosem sül el:</b> a {@code ValutaBackendApplication} hordozza az
     * {@code @EnableJpaAuditing}-et, és a JPA-spec szerint az {@code @EntityListeners}
     * callbackjei az entitás saját callbackjei ELŐTT futnak — ide érve a {@code createdAt}
     * már ki van töltve, a null-check no-op.
     *
     * <p>Kizárólag null-check + kitöltés: meglévő értéket SOHA nem ír felül.
     */
    @PrePersist
    void applyCreatedAtFallback() {
        if (this.createdAt == null) {
            this.createdAt = LocalDateTime.now();
        }
    }
}
