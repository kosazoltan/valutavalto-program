package hu.puzzleir.valuta.dto.ertektar;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import lombok.Data;
import java.util.List;

@Data
public class DistributionRequestDto {
    @NotEmpty
    @Valid
    private List<DistributionItemDto> items;
    private String note;
}
