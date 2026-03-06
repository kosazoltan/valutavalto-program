package hu.puzzleir.valuta.entity;

import com.puzzleir.backend.entity.Branch;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * LED kijelző konfiguráció entity.
 * A fizikai LED kijelző beállításai: csatlakozás típus, kapcsolat, megjelenített valuták.
 */
@Entity
@Table(name = "led_display_config", indexes = {
    @Index(name = "idx_led_display_config_branch", columnList = "branch_id")
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class LedDisplayConfig {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    @Enumerated(EnumType.STRING)
    @Column(name = "display_type", nullable = false, length = 30)
    @Builder.Default
    private LedDisplayConnectionType displayType = LedDisplayConnectionType.NETWORK;

    @Column(name = "connection_string", length = 255)
    private String connectionString;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "refresh_interval_seconds", nullable = false)
    @Builder.Default
    private Integer refreshIntervalSeconds = 60;

    /** Megjelenített valuták JSON array, pl. ["EUR","USD","GBP"] */
    @Column(name = "displayed_currencies", columnDefinition = "TEXT")
    private String displayedCurrencies;

    @Column(name = "last_updated_at")
    private LocalDateTime lastUpdatedAt;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
