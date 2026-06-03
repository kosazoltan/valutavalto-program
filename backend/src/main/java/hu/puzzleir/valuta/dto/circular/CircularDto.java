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
    /** A4 (b9-korlevelek FR-02): kötelező nyugtázás — true esetén blokkolja a tranzakciót, amíg nincs nyugtázva. */
    private Boolean requiresAcknowledgment;
    private Boolean acknowledged;
    private String acknowledgedAt;
    private String createdAt;
    // Típus rendszer
    private String circularType;
    private String circularTypeDescription;
    private String target;
    private String priority;
    private String registrationNumber;
    private String attachmentFilename;
    private String validFrom;
    private String validTo;
    // V88: Legacy paritás
    private String category;
    private Boolean archived;
    private Integer archiveYear;
    private Long attachmentSize;
    private Long acknowledgmentCount;
}
