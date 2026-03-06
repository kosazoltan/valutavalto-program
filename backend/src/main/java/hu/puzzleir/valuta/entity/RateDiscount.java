package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "rate_discount", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"workgroup_id", "level"})
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RateDiscount {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "workgroup_id", nullable = false)
    private UUID workgroupId;

    @Column(nullable = false)
    private Integer level;

    @Column(nullable = false, length = 50)
    private String name;

    @Column(name = "buy_discount_percent", precision = 8, scale = 4)
    @Builder.Default
    private BigDecimal buyDiscountPercent = BigDecimal.ZERO;

    @Column(name = "sell_discount_percent", precision = 8, scale = 4)
    @Builder.Default
    private BigDecimal sellDiscountPercent = BigDecimal.ZERO;

    @Builder.Default
    private Boolean active = true;
}
