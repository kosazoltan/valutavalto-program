package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * AML küszöbérték entity.
 *
 * Magyar jogszabályi küszöbértékek a pénzmosás elleni szabályozáshoz.
 */
@Entity
@Table(name = "aml_threshold")
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AmlThreshold {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "threshold_type", nullable = false, unique = true, length = 30)
    private String thresholdType;

    @Column(name = "amount_huf", nullable = false, precision = 18, scale = 2)
    private BigDecimal amountHuf;

    @Column(length = 500)
    private String description;

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
