package hu.puzzleir.valuta.dto.printtemplate;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
public class PrintTemplateResponse {
    private UUID id;
    private String name;
    private String templateType;
    private String content;
    private Boolean isDefault;
    private Integer companyId;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
