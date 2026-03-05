package hu.puzzleir.valuta.dto.printtemplate;

import lombok.Data;

import java.util.Map;

@Data
public class PrintTemplatePreviewRequest {
    private Map<String, Object> data;
}
