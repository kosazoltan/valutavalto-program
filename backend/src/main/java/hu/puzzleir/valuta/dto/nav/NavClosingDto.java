package hu.puzzleir.valuta.dto.nav;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * NAV zárás válasz DTO.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NavClosingDto {

    private UUID id;
    private LocalDate closingDate;
    private UUID branchId;
    private String closingType;
    private BigDecimal totalRevenue;
    private BigDecimal totalExpense;
    private BigDecimal handlingFeeTotal;
    private BigDecimal vatAmount;
    private String status;
    private String navReferenceNumber;
    private Long closedById;
    private LocalDateTime closedAt;
    private List<NavClosingLineDto> lines;
    private LocalDateTime createdAt;
}
