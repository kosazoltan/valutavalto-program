package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * FS-C (Center FS-1): pénztárosi szabadszöveges válasz egy körlevélre.
 * Egy körlevélre worker-enként TÖBB válasz is jöhet (nincs unique constraint).
 */
@Entity
@Table(name = "circular_reply", indexes = {
    @Index(name = "idx_circ_reply_circular", columnList = "circular_id"),
    @Index(name = "idx_circ_reply_company", columnList = "company_id, circular_id")
})
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class CircularReply {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "circular_id", nullable = false)
    private Circular circular;

    @Column(name = "worker_id", nullable = false)
    private Long workerId;

    /** Multi-tenant bélyeg (invariáns #1) — mindig a beküldő worker cége. */
    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @Column(name = "branch_id")
    private UUID branchId;

    @Column(name = "reply_text", nullable = false, columnDefinition = "TEXT")
    private String replyText;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
}
