package hu.puzzleir.valuta.dto.email;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Email küldés DTO.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ComposeEmailDto {

    @NotBlank(message = "Címzett kötelező!")
    private String to;

    private String cc;

    private String bcc;

    @NotBlank(message = "Tárgy kötelező!")
    private String subject;

    private String body;

    private String htmlBody;
}
