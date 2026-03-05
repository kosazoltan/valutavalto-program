package hu.puzzleir.valuta.dto.rateapproval;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RejectRateChangeDto {
    private String reason;
}
