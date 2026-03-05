package hu.puzzleir.valuta.dto.led;

import jakarta.validation.constraints.NotBlank;
import lombok.*;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class UpdateScrollingTextDto {
    @NotBlank
    private String text;
}
