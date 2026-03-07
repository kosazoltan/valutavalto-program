package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Email cache entitás — Gmail üzenetek helyi cache-elése.
 */
@Entity
@Table(name = "email_cache", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"email_account_id", "gmail_message_id"})
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class EmailCache {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "email_account_id", nullable = false)
    private EmailAccount emailAccount;

    @Column(name = "gmail_message_id", nullable = false, length = 100)
    private String gmailMessageId;

    @Column(name = "thread_id", length = 100)
    private String threadId;

    @Column(length = 500)
    private String subject;

    @Column(name = "sender_address", length = 255)
    private String senderAddress;

    /**
     * Címzettek JSON formátumban (pl. ["a@b.com", "c@d.com"])
     */
    @Column(columnDefinition = "TEXT")
    private String recipients;

    @Column(length = 500)
    private String snippet;

    @Column(name = "has_attachments", nullable = false)
    @Builder.Default
    private Boolean hasAttachments = false;

    @Column(name = "is_read", nullable = false)
    @Builder.Default
    private Boolean isRead = false;

    @Column(name = "is_starred", nullable = false)
    @Builder.Default
    private Boolean isStarred = false;

    /**
     * Gmail label ID-k JSON formátumban (pl. ["INBOX", "UNREAD"])
     */
    @Column(name = "label_ids", columnDefinition = "TEXT")
    private String labelIds;

    @Column(name = "received_at", nullable = false)
    @Builder.Default
    private LocalDateTime receivedAt = LocalDateTime.now();

    @Column(name = "cached_at", nullable = false)
    @Builder.Default
    private LocalDateTime cachedAt = LocalDateTime.now();
}
