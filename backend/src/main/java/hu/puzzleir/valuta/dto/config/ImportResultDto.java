package hu.puzzleir.valuta.dto.config;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

/**
 * Konfiguráció import eredmény DTO.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImportResultDto {

    private boolean success;
    private int importedSystemParams;
    private int importedRateSettings;
    private int importedRoundingRules;
    private int importedPrintTemplates;
    private boolean ledConfigImported;

    @Builder.Default
    private List<String> warnings = new ArrayList<>();

    @Builder.Default
    private List<String> errors = new ArrayList<>();
}
