package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

/**
 * Körlevél entity (központi utasítás a pénztáraknak).
 *
 * Legacy mapping: ERTEKTAR — korlev.dll
 * Központi utasítások küldése a pénztáraknak.
 */
@Entity
@Table(name = "circular", indexes = {
    @Index(name = "idx_circular_created_by", columnList = "created_by_id"),
    @Index(name = "idx_circular_urgent", columnList = "urgent")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Circular {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Körlevél címe
     */
    @Column(nullable = false, length = 200)
    private String title;

    /**
     * Körlevél tartalma
     */
    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;

    /**
     * Létrehozó dolgozó
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by_id", nullable = false)
    private Worker createdBy;

    /**
     * Sürgős-e
     */
    @Column(nullable = false)
    @Builder.Default
    private Boolean urgent = false;

    /**
     * Tudomásul véve-e
     */
    @Column(nullable = false)
    @Builder.Default
    private Boolean acknowledged = false;

    /**
     * Tudomásul vétel időpontja
     */
    @Column(name = "acknowledged_at")
    private LocalDateTime acknowledgedAt;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
