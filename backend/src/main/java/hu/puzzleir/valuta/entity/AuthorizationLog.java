package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Meghatalmazás napló entity.
 * Képviselők által végrehajtott tranzakciók naplózása.
 */
@Entity
@Table(name = "authorization_log", indexes = {
    @Index(name = "idx_auth_log_representative", columnList = "representative_id")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuthorizationLog {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "representative_id", nullable = false)
    private UUID representativeId;

    @Column(nullable = false, length = 100)
    private String action;

    @Column(name = "transaction_id")
    private Long transactionId;

    @Column(name = "performed_at", nullable = false)
    @Builder.Default
    private LocalDateTime performedAt = LocalDateTime.now();

    @Column(name = "performed_by_worker_id", nullable = false)
    private Long performedByWorkerId;
}
