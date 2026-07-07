package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * FS-5: Okmány-képpár egy oldala (elő/hát).
 * A képbájtok (file_data) és a thumbnail (thumbnail_data) külön táblában élnek —
 * a meta-listázó query-k sosem érintik a bájtokat (PII + méret).
 */
@Entity
@Table(name = "scanned_document_image", indexes = {
    @Index(name = "idx_sdi_document", columnList = "scanned_document_id")
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ScannedDocumentImage {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "scanned_document_id", nullable = false)
    private UUID scannedDocumentId;

    @Enumerated(EnumType.STRING)
    @Column(name = "side", nullable = false, length = 10)
    private DocumentSide side;

    @Column(name = "mime_type", nullable = false, length = 100)
    private String mimeType;

    @Column(name = "file_size_bytes", nullable = false)
    private Long fileSizeBytes;

    @Lob
    @Column(name = "file_data", nullable = false)
    private byte[] fileData;

    @Lob
    @Column(name = "thumbnail_data")
    private byte[] thumbnailData;

    @Column(name = "thumbnail_mime_type", length = 100)
    private String thumbnailMimeType;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
