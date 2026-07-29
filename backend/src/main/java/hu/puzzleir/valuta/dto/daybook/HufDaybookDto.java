package hu.puzzleir.valuta.dto.daybook;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class HufDaybookDto {
    private String branchId;
    private String branchName;
    /** FR-K4: telephely-cím a nyomtatvány fejlécéhez — a hívó tenant saját (companyId-szűrt) Branch-éből. */
    private String branchAddress;
    private String date;
    private List<HufDaybookRowDto> rows;
    private BigDecimal totalAtadasHuf;
    private BigDecimal totalAtvetelHuf;
    /** FR-K5: Nyitó = a nap ELŐTTI össz FF/UF előjeles összege (UF+, FF−, sztornó negálva), implicit horgony. */
    private BigDecimal openingBalanceHuf;
    /** FR-K5: Záró = Nyitó + totalAtvetelHuf − totalAtadasHuf. */
    private BigDecimal closingBalanceHuf;
}
