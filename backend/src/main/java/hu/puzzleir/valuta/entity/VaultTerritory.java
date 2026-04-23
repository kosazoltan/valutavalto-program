package hu.puzzleir.valuta.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import hu.puzzleir.valuta.entity.Company;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Értéktári terület.
 * Területi szervezés: pénztárak (branch) területi értéktárakhoz rendelése.
 */
@Entity
@Table(name = "vault_territory", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"company_id", "name"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VaultTerritory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    @JsonIgnore
    private Company company;

    /**
     * Sourcery #126 rename: getCompanyIdForJson -> getCompanyId (Java bean convention).
     * Transient JSON-convenience getter, ami csak a company ID-t olvassa ki,
     * nem a teljes Company entity-t -> elkerulli a lazy-init
     * 'Could not initialize proxy - no session' hibat.
     * A @JsonProperty("companyId") miatt a JSON kulcs valtozatlan.
     */
    @JsonProperty("companyId")
    @Transient
    public java.util.UUID getCompanyId() {
        return company != null ? company.getId() : null;
    }

    @Column(nullable = false, length = 100)
    private String name;

    /**
     * Alaptőke (Ft)
     */
    @Column(name = "base_capital", nullable = false, precision = 15, scale = 2)
    private BigDecimal baseCapital;

    @Column(name = "base_capital_approved_at")
    private LocalDate baseCapitalApprovedAt;

    @Column(name = "is_active")
    @Builder.Default
    private Boolean active = true;
}
