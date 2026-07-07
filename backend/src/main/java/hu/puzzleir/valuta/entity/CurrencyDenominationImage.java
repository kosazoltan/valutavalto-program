package hu.puzzleir.valuta.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Lob;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * FS-9: valuta-címletkép (bankjegy/érme elő- vagy hátlap fotó), cégenként.
 * A bájtok és a thumbnail ebben a táblában élnek; a meta-lista-query-k SOSEM
 * érintik a bájtokat (ScannedDocumentImage-precedens).
 */
@Entity
@Table(
        name = "currency_denomination_image",
        indexes = @Index(name = "idx_cdi_company_currency", columnList = "company_id, currency_id"),
        uniqueConstraints = @UniqueConstraint(
                name = "ux_cdi_company_currency_face_type_side",
                columnNames = {"company_id", "currency_id", "face_value", "denomination_type", "side"}))
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CurrencyDenominationImage {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** MULTI-TENANT: cég-azonosító — MINDEN query erre szűr. */
    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @Column(name = "currency_id", nullable = false)
    private Long currencyId;

    @Column(name = "face_value", nullable = false, precision = 15, scale = 2)
    private BigDecimal faceValue;

    @Enumerated(EnumType.STRING)
    @Column(name = "denomination_type", nullable = false, length = 20)
    private DenominationType denominationType;

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

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean active = true;

    @Column(name = "created_by_worker_code", length = 50)
    private String createdByWorkerCode;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
