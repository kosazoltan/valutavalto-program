package hu.puzzleir.valuta.dto.translation;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TranslationDto {

    private Long id;
    private String languageCode;
    private String messageKey;
    private String messageValue;
    private String module;
}
