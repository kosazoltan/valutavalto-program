package hu.puzzleir.valuta.dto.translation;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TranslationImportRequest {

    private String languageCode;
    private Map<String, String> translations;
}
