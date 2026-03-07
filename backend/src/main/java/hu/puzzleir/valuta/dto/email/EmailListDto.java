package hu.puzzleir.valuta.dto.email;

import com.fasterxml.jackson.annotation.JsonProperty;
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
        /** JSON: "sender" — a frontend EmailSummary.sender-t vár */
        @JsonProperty("sender")
        private String from;
        private String snippet;
        /** JSON: "isRead" — Jackson primitív boolean "is" prefixet levágja, @JsonProperty kényszeríti */
        @JsonProperty("isRead")
        private boolean isRead;
        @JsonProperty("hasAttachments")
        private boolean hasAttachments;
        /** Epoch ms → String konverzió a frontend számára */
        private long receivedAt;
    }
}
