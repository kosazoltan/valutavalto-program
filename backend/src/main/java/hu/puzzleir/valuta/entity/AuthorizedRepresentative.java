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
 */
@Entity
@Table(name = "authorized_representative", indexes = {
    @Index(name = "idx_auth_rep_customer", columnList = "customer_id")
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

    @Column(name = "customer_id", nullable = false)
    private Long customerId;

    @Column(name = "representative_name", nullable = false, length = 200)
    private String representativeName;

    @Column(name = "representative_document_number", nullable = false, length = 50)
    private String representativeDocumentNumber;

    @Column(name = "representative_document_type", nullable = false, length = 50)
    private String representativeDocumentType;

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
}
