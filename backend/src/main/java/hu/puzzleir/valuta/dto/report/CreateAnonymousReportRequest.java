package hu.puzzleir.valuta.dto.report;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateAnonymousReportRequest {

    @NotBlank
    @Size(max = 50)
    private String reportType;

    @NotBlank
    @Size(max = 200)
    private String subject;

    private String description;
}
