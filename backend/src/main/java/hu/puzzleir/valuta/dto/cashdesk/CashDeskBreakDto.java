package hu.puzzleir.valuta.dto.cashdesk;

import lombok.*;

import java.time.LocalDateTime;

/**
 * Pénztár szünet DTO.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CashDeskBreakDto {

    private String id;
    private String cashDeskId;
    private String cashDeskName;
    private LocalDateTime breakStart;
    private LocalDateTime breakEnd;
    private String breakType;
    private String reason;
    private Boolean isActive;
}
