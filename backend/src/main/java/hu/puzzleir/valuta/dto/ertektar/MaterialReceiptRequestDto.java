package hu.puzzleir.valuta.dto.ertektar;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Pattern;
import lombok.*;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MaterialReceiptRequestDto {

    @NotBlank(message = "Bizonylat típus kötelező (B/K)")
    @Pattern(regexp = "B|K", message = "Érvényes típus: B (bevétel) vagy K (kiadás)")
    private String receiptType;

    private Integer vaultTerritoryId;
    private String branchCode;
    private String counterpartName;
    private String note;

    @NotEmpty(message = "Legalább egy tételsor kötelező")
    @Valid
    private List<MaterialReceiptLineDto> lines;
}
