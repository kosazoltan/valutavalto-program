package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/**
 * Per-worker körlevél nyugtázás.
 * Legacy: AT.xxx fájlok — minden dolgozónak külön AT rekordja volt,
 * ami tartalmazta a körlevél számát és a nyugtázás tényét.
 */
@Entity
@Table(name = "circular_acknowledgment", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"circular_id", "worker_id"})
})
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class CircularAcknowledgment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "circular_id", nullable = false)
    private Circular circular;

    @Column(name = "worker_id", nullable = false)
    private Long workerId;

    @Column(name = "acknowledged_at", nullable = false)
    private LocalDateTime acknowledgedAt;

    @Column(name = "ip_address", length = 45)
    private String ipAddress;

    /** G21: a nyugtázó szerepköre (Pénztáros / Belső ellenőr / Területi vezető stb.) a megoszlás-riporthoz. */
    @Column(name = "acknowledger_role", length = 50)
    private String acknowledgerRole;
}
