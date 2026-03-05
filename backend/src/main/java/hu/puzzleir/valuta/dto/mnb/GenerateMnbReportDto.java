package hu.puzzleir.valuta.dto.mnb;

import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.time.LocalDate;
import java.util.UUID;

/**
 * MNB riport generálás kérés DTO.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GenerateMnbReportDto {

    @NotNull(message = "Iroda ID kötelező")
    private UUID branchId;

    @NotNull(message = "Dátum kötelező")
    private LocalDate date;

    /**
     * Riport típus — ha nem adott, DAILY az alapértelmezett
     */
    private String reportType;
}
