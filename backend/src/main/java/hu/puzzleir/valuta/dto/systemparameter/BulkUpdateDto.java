package hu.puzzleir.valuta.dto.systemparameter;

import lombok.*;

import java.util.Map;

@Data @NoArgsConstructor @AllArgsConstructor
public class BulkUpdateDto {
    private Map<String, String> parameters;
}
