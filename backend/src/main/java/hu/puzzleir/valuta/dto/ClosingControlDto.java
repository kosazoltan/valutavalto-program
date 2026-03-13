package hu.puzzleir.valuta.dto;

import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ClosingControlDto {
    private UUID id;
    private UUID branchId;
    private LocalDate controlDate;
    private Boolean dailyClosingDone;
    private Boolean eveningClosingDone;
    private Boolean navClosingDone;
    private LocalDateTime lastTransactionAt;
    private String alertLevel;
    private String notes;
}
