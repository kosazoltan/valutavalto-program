package hu.puzzleir.valuta.dto.customer;

import lombok.*;

import java.math.BigDecimal;

/**
 * Ügyfél rangsor DTO (top customer)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerRankingDto {
    private Long customerId;
    private String customerName;
    private int transactionCount;
    private BigDecimal totalVolumeHuf;
    private int rank;
}
