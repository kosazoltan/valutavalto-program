package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "system_parameter")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class SystemParameter {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "parameter_key", nullable = false, length = 100)
    private String parameterKey;

    /**
     * TD7: opcionális cég-scope. NULL = globális default (minden cég + scheduler ezt
     * kapja fallbackként). Nem FK (V39/V77 típus-drift tanulság, V347 precedens):
     * a parciális unique indexek védenek (V348).
     */
    @Column(name = "company_id")
    private UUID companyId;

    @Column(name = "parameter_value", nullable = false, columnDefinition = "TEXT")
    private String parameterValue;

    @Column(name = "parameter_type", nullable = false, length = 30)
    private String parameterType;

    @Column(nullable = false, length = 50)
    private String category;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "is_active")
    @Builder.Default
    private Boolean isActive = true;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @Column(name = "updated_by", length = 100)
    private String updatedBy;
}
