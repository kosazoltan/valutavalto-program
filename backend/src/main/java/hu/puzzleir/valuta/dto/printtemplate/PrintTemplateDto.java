package hu.puzzleir.valuta.dto.printtemplate;

import lombok.Data;

@Data
public class PrintTemplateDto {
    private String name;
    private String templateType;
    private String content;
    private Boolean isDefault;
    private Integer companyId;
}
