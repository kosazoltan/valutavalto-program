package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

/**
 * Árfolyam forrás entity — MNB, ECB és egyéb árfolyam szolgáltatók nyilvántartása.
 *
 * Legacy mapping: ratectrl.dll — MNB, ECB, MANUAL árfolyam források.
 * IRQ timer-rel kezelt FTP polling helyett, @Scheduled alapú HTTP polling.
 */
@Entity
@Table(name = "exchange_rate_source")
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ExchangeRateSource {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Forrás neve (MNB, ECB, MANUAL)
     */
    @Column(name = "source_name", nullable = false, length = 50)
    private String sourceName;

    /**
     * Forrás URL (nullable — MANUAL esetén null)
     */
    @Column(name = "source_url", length = 500)
    private String sourceUrl;

    /**
     * Polling intervallum percben
     */
    @Column(name = "polling_interval_minutes")
    private Integer pollingIntervalMinutes;

    /**
     * Aktív-e a forrás
     */
    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean active = true;

    /**
     * Utolsó sikeres polling időpontja
     */
    @Column(name = "last_success_at")
    private LocalDateTime lastSuccessAt;

    /**
     * Utolsó lekérdezés időpontja (akár sikeres, akár sikertelen)
     */
    @Column(name = "last_polled_at")
    private LocalDateTime lastPolledAt;

    /**
     * Utolsó hiba időpontja
     */
    @Column(name = "last_error_at")
    private LocalDateTime lastErrorAt;

    /**
     * Utolsó hiba üzenet
     */
    @Column(name = "last_error", length = 1000)
    private String lastError;

    /**
     * Sikeres polling-ok száma (összesített)
     */
    @Column(name = "success_count")
    @Builder.Default
    private Long successCount = 0L;

    /**
     * Sikertelen polling-ok száma (összesített)
     */
    @Column(name = "error_count")
    @Builder.Default
    private Long errorCount = 0L;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
