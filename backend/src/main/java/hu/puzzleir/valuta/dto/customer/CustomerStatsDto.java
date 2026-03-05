package hu.puzzleir.valuta.dto.customer;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Ügyfél statisztika DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerStatsDto {
    private Long customerId;
    private String customerName;
    private int totalTransactions;
    private BigDecimal totalVolumeHuf;
    private BigDecimal averageAmount;
    private LocalDate firstVisit;
    private LocalDate lastVisit;
    private String preferredCurrency;
}
