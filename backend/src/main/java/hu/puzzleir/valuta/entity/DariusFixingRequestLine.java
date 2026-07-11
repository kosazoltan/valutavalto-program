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
import lombok.Setter;

import java.math.BigDecimal;
import java.util.UUID;

/** Egy Darius fixing-igény valutánkénti részletsora. */
@Entity
@Table(name = "darius_fixing_request_line")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DariusFixingRequestLine {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @Column(name = "request_id", nullable = false)
    private UUID requestId;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Column(name = "delivered_amount", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal deliveredAmount = BigDecimal.ZERO;

    @Column(name = "collected_amount", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal collectedAmount = BigDecimal.ZERO;
}
