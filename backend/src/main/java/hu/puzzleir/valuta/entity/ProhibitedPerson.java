package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "prohibited_person")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ProhibitedPerson {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "company_id")
    private UUID companyId;

    @Column(name = "full_name", nullable = false, length = 300)
    private String fullName;

    @Column(name = "document_number", length = 50)
    private String documentNumber;

    @Column(name = "identity_number", length = 50)
    private String identityNumber;

    @Column(name = "passport_number", length = 50)
    private String passportNumber;

    @Column(name = "date_of_birth")
    private LocalDate dateOfBirth;

    @Column(length = 100)
    private String nationality;

    @Column(name = "list_type", length = 50)
    private String listType;

    @Column(name = "list_source", length = 200)
    private String listSource;

    @Column(columnDefinition = "TEXT")
    private String reason;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
