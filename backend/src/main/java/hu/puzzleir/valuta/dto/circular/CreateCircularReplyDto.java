package hu.puzzleir.valuta.dto.circular;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CreateCircularReplyDto {
    @NotBlank
    @Size(max = 4000)
    private String replyText;
}
