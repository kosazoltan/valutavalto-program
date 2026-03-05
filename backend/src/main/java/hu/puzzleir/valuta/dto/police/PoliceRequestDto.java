package hu.puzzleir.valuta.dto.police;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class PoliceRequestDto {
    private String id;
    private String requestNumber;
    private String requestDate;
    private String requestedBy;
    private String customerName;
    private String documentNumber;
    private String dateRangeFrom;
    private String dateRangeTo;
    private String status;
    private String responseData;
    private String completedAt;
    private String createdAt;
    private Long createdById;
    private String createdByName;
}
