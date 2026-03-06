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
    // Sprint 3 — típus rendszer
    private String circularType;
    private String circularTypeDescription;
    private String target;
    private String priority;
    private String registrationNumber;
    private String attachmentFilename;
    private String validFrom;
    private String validTo;
}
