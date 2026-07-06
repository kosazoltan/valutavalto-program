package hu.puzzleir.valuta.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * FS-8: konfigurálható AML értéksávok, érvényesség-kezdettel (effective_from) verziózva.
 * Tudatosan cég-független: a Pmt. törvényi küszöbei mind a 4 cégre azonosak (lásd terv T2).
 */
@Entity
@Table(name = "value_band_config", uniqueConstraints =
        @UniqueConstraint(name = "uq_value_band_effective_from", columnNames = "effective_from"))
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ValueBandConfig {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** Egyszerűsített azonosítási küszöb (ma: 100.000 Ft, Pmt. 7.§). */
    @Column(name = "simplified_identification_limit_huf", nullable = false, precision = 18, scale = 2)
    private BigDecimal simplifiedIdentificationLimitHuf;

    /** Teljes azonosítási küszöb (ma: 300.000 Ft) — az FS-4 lejárt-okmány blokk küszöbe IS. */
    @Column(name = "identification_limit_huf", nullable = false, precision = 18, scale = 2)
    private BigDecimal identificationLimitHuf;

    /** Jövedelemforrás/fokozott figyelem küszöb (ma: 10M, BIGCTRL TranzTipus 5). */
    @Column(name = "income_proof_limit_huf", nullable = false, precision = 18, scale = 2)
    private BigDecimal incomeProofLimitHuf;

    /** Göngyölési vizsgálati ablak napokban (ma: 8 — legacy BIGCTRL _diff < 8 parity). */
    @Column(name = "rolling_window_days", nullable = false)
    private Integer rollingWindowDays;

    /** Hatályba lépés napja. A sor eddig a napig (exkluzív) szerkeszthető. */
    @Column(name = "effective_from", nullable = false)
    private LocalDate effectiveFrom;

    @Column(name = "created_by", length = 100)
    private String createdBy;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
