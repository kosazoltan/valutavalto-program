package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * FK-076: engedelyezett cimlet-katalogus (torzsadat).
 *
 * A `denomination` tabla teljes, jegybanki forrasbol (V320/V328) szarmazo
 * katalogusaval szemben ez a tabla kizarolag a ténylegesen forgalmazott
 * bankjegy/erme kombinaciokat tartalmazza. Deviza-szintu es fiok-fuggetlen
 * (nincs branch_id), cegenkent szeparalt (company_id).
 *
 * HUF szandekosan NINCS benne (Scope OUT) - a zaras-validacio HUF-ra explicit
 * ki van kapcsolva, kulonben minden HUF-zaras tevesen elutasitasra kerulne.
 *
 * Migracio: V376__denomination_allowed_catalog_and_seed.sql
 */
@Entity
@Table(name = "denomination_allowed", indexes = {
    @Index(name = "idx_denomination_allowed_company_currency", columnList = "company_id,currency_id")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DenominationAllowed {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * MULTI-TENANT: Ceg kapcsolat
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;

    /**
     * Valutanem
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "currency_id", nullable = false)
    private Currency currency;

    /**
     * Nevertek - DB CHECK szerint mindig pozitiv egesz (tort cimlet tilos).
     */
    @Column(name = "face_value", nullable = false, precision = 15, scale = 2)
    private BigDecimal faceValue;

    @Enumerated(EnumType.STRING)
    @Column(name = "denomination_type", nullable = false, length = 20)
    private DenominationType denominationType;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean active = true;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
