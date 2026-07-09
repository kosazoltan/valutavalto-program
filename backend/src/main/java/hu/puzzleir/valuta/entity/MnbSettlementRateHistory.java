package hu.puzzleir.valuta.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "mnb_settlement_rate_history",
        indexes = @Index(name = "ix_msr_history_company_recorded", columnList = "company_id, recorded_at"))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MnbSettlementRateHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Column(name = "official_rate", nullable = false, precision = 15, scale = 4)
    private BigDecimal officialRate;

    @Column(name = "available_to_offices_at")
    private Instant availableToOfficesAt;

    @Column(name = "recorded_by", length = 50)
    private String recordedBy;

    @Column(name = "recorded_at", nullable = false)
    private Instant recordedAt;
}
