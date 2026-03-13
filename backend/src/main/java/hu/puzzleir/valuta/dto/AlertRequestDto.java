package hu.puzzleir.valuta.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AlertRequestDto {

    @NotNull(message = "Iroda azonosító kötelező")
    private UUID branchId;

    @NotBlank(message = "Üzenet megadása kötelező")
    private String message;
}
