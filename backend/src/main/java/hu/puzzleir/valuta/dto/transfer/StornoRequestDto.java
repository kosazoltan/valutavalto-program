package hu.puzzleir.valuta.dto.transfer;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.*;

/**
 * Átadás-átvétel bizonylat sztornózásának kérése — kötelező indoklással (FR-12, NFR-3).
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StornoRequestDto {

    @NotBlank(message = "A sztornó indoklása kötelező")
    @Size(max = 500, message = "A sztornó indoklása legfeljebb 500 karakter lehet")
    private String reason;
}
