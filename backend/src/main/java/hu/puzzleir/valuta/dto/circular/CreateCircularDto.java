package hu.puzzleir.valuta.dto.circular;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CreateCircularDto {
    @NotBlank private String title;
    @NotBlank private String content;
    private Boolean urgent;
}
