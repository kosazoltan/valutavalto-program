package hu.puzzleir.valuta.dto.circular;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CircularReplyDto {
    private Long id;
    private Long circularId;
    private Long workerId;
    /** A válaszoló neve (Worker.name) — center-oldali listához; null ha a worker törölve. */
    private String workerName;
    private String branchId;
    private String replyText;
    private String createdAt;
}
