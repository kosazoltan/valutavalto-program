package hu.puzzleir.valuta.dto.led;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class LedDisplayDto {
    private String id;
    private String branchId;
    private String displayType;
    private String content;
    private String lastUpdated;
}
