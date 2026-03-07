package hu.puzzleir.valuta.dto.email;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Email lista DTO — lapozással.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EmailListDto {

    private List<EmailSummaryDto> messages;

    private String nextPageToken;

    private int resultSizeEstimate;

    /**
     * Egyetlen email összefoglaló a lista nézethez.
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class EmailSummaryDto {
        private String id;
        private String threadId;
        private String subject;
        private String from;
        private String snippet;
        private boolean isRead;
        private boolean hasAttachments;
        private long receivedAt;
    }
}
