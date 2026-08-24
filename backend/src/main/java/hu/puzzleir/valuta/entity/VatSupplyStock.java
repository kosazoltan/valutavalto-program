package hu.puzzleir.valuta.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
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

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * FKH-040: folyamatosan vezetett ÁFA-célú HUF-ellátmány egyenleg értéktár-területenként.
 * Bank→Értéktár átvételkor nő, Értéktár→Pénztár átadáskor csökken.
 */
@Entity
@Table(name = "vat_supply_stock", uniqueConstraints = {
        @UniqueConstraint(name = "ux_vss_company_territory",
                columnNames = {"company_id", "vault_territory_id"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VatSupplyStock {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @Column(name = "vault_territory_id", nullable = false)
    private Integer vaultTerritoryId;

    @Column(name = "current_balance", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal currentBalance = BigDecimal.ZERO;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
