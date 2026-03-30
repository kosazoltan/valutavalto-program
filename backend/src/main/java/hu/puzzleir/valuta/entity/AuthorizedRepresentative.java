package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Meghatalmazott képviselő entity.
 * Ügyfél nevében eljáró személy nyilvántartása.
 * Spec: authorized_representative (v2.0 — 08_meghatalmazott_kezeles.md)
 */
@Entity
@Table(name = "authorized_representative", indexes = {
    @Index(name = "idx_auth_rep_customer", columnList = "customer_id"),
    @Index(name = "idx_auth_rep_document", columnList = "representative_document_number")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuthorizedRepresentative {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "company_id")
    private UUID companyId;

    @Column(name = "customer_id", nullable = false)
    private Long customerId;

    // --- Személyes adatok ---

    @Column(name = "first_name", length = 100)
    private String firstName;

    @Column(name = "last_name", length = 100)
    private String lastName;

    /** Teljes név (kompatibilitás: régi representative_name) */
    @Column(name = "representative_name", nullable = false, length = 200)
    private String representativeName;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    @Column(name = "birth_place", length = 200)
    private String birthPlace;

    @Column(name = "nationality_did", length = 50)
    private String nationalityDid;

    @Column(name = "address", length = 500)
    private String address;

    @Column(name = "phone", length = 50)
    private String phone;

    @Column(name = "email", length = 200)
    private String email;

    // --- Okmány adatok ---

    @Column(name = "document_type_did", length = 50)
    private String documentTypeDid;

    /** Okmányszám (kompatibilitás: régi representative_document_number) */
    @Column(name = "representative_document_number", nullable = false, length = 50)
    private String representativeDocumentNumber;

    @Column(name = "representative_document_type", nullable = false, length = 50)
    private String representativeDocumentType;

    @Column(name = "document_valid_from")
    private LocalDate documentValidFrom;

    @Column(name = "document_valid_to")
    private LocalDate documentValidTo;

    // --- Meghatalmazás típus/kapcsolat ---

    /** Spec: REPRESENTATIVE_TYPE szótár (PERMANENT, TEMPORARY, LEGAL_GUARDIAN, POWER_OF_ATTORNEY, COMPANY_DELEGATE) */
    @Column(name = "representative_type_did", length = 50)
    private String representativeTypeDid;

    /** Spec: RELATIONSHIP_TYPE szótár (FAMILY, COLLEAGUE, FRIEND, PROFESSIONAL, BUSINESS, OTHER) */
    @Column(name = "relationship_did", length = 50)
    private String relationshipDid;

    // --- Érvényesség ---

    @Column(name = "authorization_start", nullable = false)
    private LocalDate authorizationStart;

    @Column(name = "authorization_end")
    private LocalDate authorizationEnd;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // --- Computed helper ---

    /** Teljes név: firstName + lastName, fallback representativeName */
    public String getFullName() {
        if (firstName != null && lastName != null) {
            return lastName + " " + firstName;
        }
        return representativeName;
    }
}
