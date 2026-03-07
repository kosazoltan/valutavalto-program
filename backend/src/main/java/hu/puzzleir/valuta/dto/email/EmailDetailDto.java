package hu.puzzleir.valuta.dto.email;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Email részletes nézet DTO.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EmailDetailDto {

    private String id;
    private String threadId;
    private String subject;
    private String from;
    private List<String> to;
    private List<String> cc;
    private String body;
    private String htmlBody;
    private long receivedAt;
    private List<AttachmentDto> attachments;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class AttachmentDto {
        private String attachmentId;
        private String filename;
        private String mimeType;
        private long size;
    }
}
