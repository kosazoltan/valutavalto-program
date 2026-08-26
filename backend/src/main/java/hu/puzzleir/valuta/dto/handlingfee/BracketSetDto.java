package hu.puzzleir.valuta.dto.handlingfee;

import lombok.*;

import java.util.List;

/**
 * FK-096: közös sáv-készlet — LIVE + DRAFT lista egy válaszban.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BracketSetDto {
    private List<HandlingFeeBracketDto> live;
    private List<HandlingFeeBracketDto> draft;
}
