package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

/**
 * Körlevél entity (központi utasítás a pénztáraknak).
 *
 * Legacy mapping: ERTEKTAR — korlev.dll
 * Központi utasítások küldése a pénztáraknak.
 */
@Entity
@Table(name = "circular", indexes = {
    @Index(name = "idx_circular_created_by", columnList = "created_by_id"),
    @Index(name = "idx_circular_urgent", columnList = "urgent")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Circular {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Körlevél címe
     */
    @Column(nullable = false, length = 200)
    private String title;

    /**
     * Körlevél tartalma
     */
    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;

    /**
     * Létrehozó dolgozó
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by_id", nullable = false)
    private Worker createdBy;

    /**
     * Körlevél típusa
     * Legacy: FZS/BT/KI/KZ/DA/SCS/DURU prefixek
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "circular_type", nullable = false, length = 30)
    @Builder.Default
    private CircularType circularType = CircularType.GENERAL;

    /**
     * Célcsoport
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "target", nullable = false, length = 30)
    @Builder.Default
    private CircularType.CircularTarget target = CircularType.CircularTarget.ALL_BRANCHES;

    /**
     * Prioritás
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "priority", nullable = false, length = 20)
    @Builder.Default
    private CircularType.CircularPriority priority = CircularType.CircularPriority.NORMAL;

    /**
     * Cél iroda (ha target = SINGLE_BRANCH)
     */
    @Column(name = "target_branch_id")
    private java.util.UUID targetBranchId;

    /**
     * Cél cég (ha target = COMPANY_SPECIFIC)
     */
    @Column(name = "target_company_id")
    private Integer targetCompanyId;

    /**
     * Csatolmány fájlnév (ODT/DOCX/PDF)
     */
    @Column(name = "attachment_filename", length = 255)
    private String attachmentFilename;

    /**
     * Csatolmány MIME típus
     */
    @Column(name = "attachment_mime_type", length = 100)
    private String attachmentMimeType;

    /**
     * Csatolmány elérési útja (szerveren)
     */
    @Column(name = "attachment_path", length = 500)
    private String attachmentPath;

    /**
     * Érvényesség kezdete
     */
    @Column(name = "valid_from")
    private java.time.LocalDate validFrom;

    /**
     * Érvényesség vége (null = korlátlan)
     */
    @Column(name = "valid_to")
    private java.time.LocalDate validTo;

    /**
     * Iktatószám (legacy: _iktatoszam)
     */
    @Column(name = "registration_number", length = 50)
    private String registrationNumber;

    /**
     * Sürgős-e
     */
    @Column(nullable = false)
    @Builder.Default
    private Boolean urgent = false;

    /**
     * Tudomásul véve-e
     */
    @Column(nullable = false)
    @Builder.Default
    private Boolean acknowledged = false;

    /**
     * Tudomásul vétel időpontja
     */
    @Column(name = "acknowledged_at")
    private LocalDateTime acknowledgedAt;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
