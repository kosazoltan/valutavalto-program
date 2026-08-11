package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * FK-076/FK-080: engedelyezett cimlet-katalogus (torzsadat).
 *
 * A `denomination` tabla teljes, jegybanki forrasbol (V320/V328) szarmazo
 * katalogusaval szemben ez a tabla kizarolag a ténylegesen forgalmazott
 * bankjegy/erme kombinaciokat tartalmazza. Deviza-szintu es fiok-fuggetlen
 * (nincs branch_id), cegenkent szeparalt (company_id).
 *
 * FK-080 ota ez az EGYETLEN igazsagforras, es a HUF-ot IS tartalmazza (V379):
 * erme kizarolag HUF 200/100/50/20/10/5 es EUR 2/1 lehet, minden mas deviza
 * minden nevertekben BANKNOTE. A HUF 1 es 2 forint szandekosan hianyzik
 * (az MNB 2008-ban bevonta oket). A zaras-validacio HUF-ra mar NINCS
 * kikapcsolva — minden deviza ugyanazon a gaton megy at.
 *
 * Migraciok: V376__denomination_allowed_catalog_and_seed.sql (katalogus + deviza-seed),
 *            V379__fk080_denomination_allowed_huf_seed.sql (HUF-seed)
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
