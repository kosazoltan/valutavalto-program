package hu.puzzleir.valuta.dto.stocksnapshot;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class WuBalanceDetailDto {
    private long wuUsd;
    private long wuHuf;
    private long vat;
    private long handlingFee;
    private long eCommerce;
}
