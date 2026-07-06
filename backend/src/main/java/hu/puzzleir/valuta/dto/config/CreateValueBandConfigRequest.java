package hu.puzzleir.valuta.dto.config;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateValueBandConfigRequest {

    @NotNull
    private BigDecimal simplifiedIdentificationLimitHuf;

    @NotNull
    private BigDecimal identificationLimitHuf;

    @NotNull
    private BigDecimal incomeProofLimitHuf;

    @NotNull
    private Integer rollingWindowDays;

    @NotNull
    private LocalDate effectiveFrom;
}
