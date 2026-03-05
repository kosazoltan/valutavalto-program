package hu.puzzleir.valuta.dto.circular;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CircularDto {
    private Long id;
    private String title;
    private String content;
    private Long createdById;
    private String createdByName;
    private Boolean urgent;
    private Boolean acknowledged;
    private String acknowledgedAt;
    private String createdAt;
}
