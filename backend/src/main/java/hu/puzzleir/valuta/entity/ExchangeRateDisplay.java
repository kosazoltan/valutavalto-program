package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Árfolyam kijelző konfiguráció entity.
 */
@Entity
@Table(name = "exchange_rate_display")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ExchangeRateDisplay {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "display_name", nullable = false, length = 200)
    private String displayName;

    /** Valuta ID-k JSON tömb formátumban, pl. [1,2,3] */
    @Column(name = "currency_ids", columnDefinition = "TEXT")
    private String currencyIds;

    @Column(name = "refresh_interval", nullable = false)
    @Builder.Default
    private Integer refreshInterval = 60;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
