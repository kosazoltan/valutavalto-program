package hu.puzzleir.valuta.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;

import jakarta.persistence.EntityListeners;

/**
 * FK-099 — pénzügyi tranzakciós illeték ráta-history (append-only, dátumozott).
 *
 * <p>D2: az entitás insert után immutable — nincs {@code @Setter}; az aggregátum
 * invariánst (append-only, szigorúan növekvő {@code effective_from} cégenként)
 * három független hely kényszeríti: DB UNIQUE, DB immutable trigger,
 * alkalmazás-szintű monotonitás-ellenőrzés.</p>
 *
 * <p>D17: {@code conversionSingleSideFlag} primitív {@code boolean}
 * ({@code @Builder.Default true}) — a {@code Transaction.financialEffective}
 * mintája szerint, NPE-biztos és konzisztens a DB {@code BOOLEAN NOT NULL
 * DEFAULT TRUE} oszloppal.</p>
 */
@Entity
@Table(name = "transaction_levy_rate_history")
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EntityListeners(AuditingEntityListener.class)
public class TransactionLevyRateHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** MULTI-TENANT: a ráta-sor kizárólag erre a cégre érvényes. */
    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    /** Hatálybalépés dátuma; cégenként szigorúan növekvő (append-only). */
    @Column(name = "effective_from", nullable = false)
    private LocalDate effectiveFrom;

    /** Alap-illeték ráta (százalék; 0.450 = 0,45%). */
    @Column(name = "base_rate_percent", nullable = false, precision = 6, scale = 3)
    private BigDecimal baseRatePercent;

    /** Alap-illeték felső korlátja HUF-ban. */
    @Column(name = "base_rate_cap_huf", nullable = false, precision = 15, scale = 2)
    private BigDecimal baseRateCapHuf;

    /** Kiegészítő konverziós illeték ráta (százalék). */
    @Column(name = "supplement_rate_percent", nullable = false, precision = 6, scale = 3)
    private BigDecimal supplementRatePercent;

    /** Kiegészítő konverziós illeték felső korlátja HUF-ban. */
    @Column(name = "supplement_rate_cap_huf", nullable = false, precision = 15, scale = 2)
    private BigDecimal supplementRateCapHuf;

    /**
     * C2/FR-5: TRUE = konverziónként egy illeték-pár (Konverzió oszlopcsoport);
     * FALSE = dokumentált fallback (convBuy → Vétel, convSell → Eladás).
     */
    @Builder.Default
    @Column(name = "conversion_single_side_flag", nullable = false)
    private boolean conversionSingleSideFlag = true;

    /** {@code SecurityUtils.getCurrentWorkerCode()} — NINCS getCurrentUsername. */
    @Column(name = "created_by", length = 100)
    private String createdBy;

    @CreatedDate
    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt;
}
