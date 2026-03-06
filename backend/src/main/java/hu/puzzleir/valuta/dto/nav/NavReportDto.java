package hu.puzzleir.valuta.dto.nav;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * NAV adatszolgáltatási riport DTO.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NavReportDto {
    private LocalDate date;
    private int reportableTransactionCount;
    private BigDecimal totalAmountHuf;
    private List<NavReportableTransactionDto> transactions;
}
