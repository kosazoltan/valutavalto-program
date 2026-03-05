package hu.puzzleir.valuta.dto.police;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;
import java.time.LocalDate;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CreatePoliceRequestDto {
    @NotBlank
    private String requestNumber;

    @NotNull
    private LocalDate requestDate;

    @NotBlank
    private String requestedBy;

    private String customerName;
    private String documentNumber;
    private LocalDate dateRangeFrom;
    private LocalDate dateRangeTo;
}
