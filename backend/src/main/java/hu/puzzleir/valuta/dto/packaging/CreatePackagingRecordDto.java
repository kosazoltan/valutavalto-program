package hu.puzzleir.valuta.dto.packaging;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.UUID;

@Data @NoArgsConstructor @AllArgsConstructor
public class CreatePackagingRecordDto {

    @NotNull
    private UUID branchId;

    @NotBlank
    private String currencyCode;

    @NotNull
    private LocalDate packagingDate;

    @NotNull
    @Positive
    private Integer bundleCount;

    @NotNull
    @Positive
    private Integer denomination;

    @Positive
    private Integer bundleSize;

    private String notes;
}
