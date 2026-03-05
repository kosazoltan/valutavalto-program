package hu.puzzleir.valuta.dto.stamp;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AssignStampRequest {
    @NotBlank(message = "Matrica sorszám kötelező!")
    private String serialNumber;

    @NotNull(message = "Tranzakció ID kötelező!")
    private Long transactionId;
}
