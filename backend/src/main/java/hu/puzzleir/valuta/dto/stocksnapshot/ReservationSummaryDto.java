package hu.puzzleir.valuta.dto.stocksnapshot;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ReservationSummaryDto {
    private String currencyCode;
    private long totalAmount;
}
