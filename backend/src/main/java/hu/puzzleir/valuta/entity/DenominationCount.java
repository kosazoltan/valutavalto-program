package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Címlet számlálás rekord — napi zárás / nyitás során rögzített címletkészlet.
 *
 * Legacy: CIMLETSZAM tábla — a pénztáros megszámolja a kasszában lévő
 * bankjegyeket/érméket típusonként, és rögzíti a darabszámot.
 */
@Entity
@Table(name = "denomination_count", indexes = {
    @Index(name = "idx_denom_count_session", columnList = "session_id"),
    @Index(name = "idx_denom_count_branch", columnList = "branch_id")
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class DenominationCount {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "session_id", nullable = false)
    private UUID sessionId;

    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Column(name = "face_value", nullable = false, precision = 15, scale = 2)
    private BigDecimal faceValue;

    @Column(nullable = false)
    @Builder.Default
    private Integer quantity = 0;

    /**
     * Típus: OPENING (nyitáskor), CLOSING (záráskor), RECOUNT (újraszámlálás)
     */
    @Column(name = "count_type", nullable = false, length = 20)
    @Builder.Default
    private String countType = "CLOSING";

    @Column(name = "worker_id")
    private Long workerId;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
