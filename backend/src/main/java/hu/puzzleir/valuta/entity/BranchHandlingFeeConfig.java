package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.exception.ValidationException;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * FK-096: iroda-szintű kezelési díj konfiguráció (DRAFT/LIVE).
 *
 * <p>Aggregate root: a konzisztencia-határ „irodánként max 1 LIVE + 1 DRAFT aktív sor"
 * (parciális egyedi indexek: {@code uk_bhfc_branch_live}, {@code uk_bhfc_branch_draft}).
 * A domain-invariánsok AZ ENTITÁSON élnek, nem service-ben.</p>
 *
 * <p>OSIV kikapcsolva: a mezők sima UUID/érték-oszlopok, nincs lazy asszociáció,
 * ami tranzakción kívülre szivároghatna.</p>
 */
@Entity
@Table(name = "branch_handling_fee_config")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class BranchHandlingFeeConfig {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** Multi-tenant izoláció: minden lekérdezés companyId-szűrt. */
    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    /** D4: a NONE is érvényes mód (örökölt cégszintű érték lehet), de az editor csak BRACKET/PER_MILLE-t kínál. */
    @Enumerated(EnumType.STRING)
    @Column(name = "fee_mode", nullable = false, length = 20)
    private HandlingFeeType feeMode;

    /** Ezrelékes mérték (‰). NUMERIC(6,3). */
    @Column(name = "per_mille_rate", precision = 6, scale = 3)
    private BigDecimal perMilleRate;

    /** Ezrelékes sapka (Ft). NULL vagy 0 = nincs sapka (HandlingFeeService:149 paritás). NUMERIC(15,2). */
    @Column(name = "per_mille_cap", precision = 15, scale = 2)
    private BigDecimal perMilleCap;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 10)
    private FeeConfigStatus status;

    /** Archiválás: a lecserélt LIVE sor is_active=false lesz (megmarad, nem törlődik). */
    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean active = true;

    @Column(name = "valid_from", nullable = false)
    @Builder.Default
    private LocalDate validFrom = LocalDate.now();

    /** D8: optimista zárás — a V383 seed version=0, az első publikálás expectedVersion=0-t küld (B2). */
    @Version
    @Column(name = "version", nullable = false)
    private Long version;

    @Column(name = "created_by", length = 100)
    private String createdBy;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "published_by", length = 100)
    private String publishedBy;

    @Column(name = "published_at")
    private LocalDateTime publishedAt;

    /**
     * Publikálhatósági invariáns — az entitáson, nem a service-ben.
     *
     * @throws ValidationException ha a konfiguráció nem publikálható
     */
    public void assertPublishable() {
        if (feeMode == HandlingFeeType.PER_MILLE) {
            if (perMilleRate == null || perMilleRate.compareTo(BigDecimal.ZERO) < 0) {
                throw new ValidationException(
                        "Ezrelékes módhoz nemnegatív mérték (per_mille_rate) kötelező.");
            }
        }
        if (perMilleCap != null && perMilleCap.compareTo(BigDecimal.ZERO) < 0) {
            throw new ValidationException("A per_mille_cap nem lehet negatív.");
        }
    }

    /**
     * A sor LIVE másolatként történő előléptetése (publish-swap). A publish atomi csere
     * (D17): a régi LIVE inaktiválódik, ez a sor lesz az új LIVE.
     *
     * @param workerCode a publikáló munkavállaló kódja (audit + published_by)
     * @return új entitás-példa LIVE státusszal
     */
    public BranchHandlingFeeConfig toLiveCopy(String workerCode) {
        LocalDateTime now = LocalDateTime.now();
        return BranchHandlingFeeConfig.builder()
                .companyId(companyId)
                .branchId(branchId)
                .feeMode(feeMode)
                .perMilleRate(perMilleRate)
                .perMilleCap(perMilleCap)
                .status(FeeConfigStatus.LIVE)
                .active(true)
                .validFrom(LocalDate.now())
                .createdBy(createdBy)
                .createdAt(createdAt != null ? createdAt : now)
                .publishedBy(workerCode)
                .publishedAt(now)
                .build();
    }
}
