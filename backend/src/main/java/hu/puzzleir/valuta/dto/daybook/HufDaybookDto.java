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
    private String date;
    private List<HufDaybookRowDto> rows;
    private BigDecimal totalAtadasHuf;
    private BigDecimal totalAtvetelHuf;
}
