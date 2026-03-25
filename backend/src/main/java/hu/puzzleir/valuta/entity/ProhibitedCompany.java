package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "prohibited_company")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ProhibitedCompany {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "company_id")
    private UUID companyId;

    @Column(name = "company_name", nullable = false, length = 300)
    private String companyName;

    @Column(name = "tax_number", length = 50)
    private String taxNumber;

    @Column(name = "registration_number", length = 50)
    private String registrationNumber;

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
