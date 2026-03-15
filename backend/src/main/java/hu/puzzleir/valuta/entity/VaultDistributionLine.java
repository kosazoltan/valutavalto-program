package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;

@Entity
@Table(name = "vault_distribution_line")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class VaultDistributionLine {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "distribution_id", nullable = false)
    private VaultDistribution distribution;

    @Column(name = "target_branch_code", nullable = false, length = 10)
    private String targetBranchCode;

    @Column(name = "target_branch_name", length = 100)
    private String targetBranchName;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal amount;
}
