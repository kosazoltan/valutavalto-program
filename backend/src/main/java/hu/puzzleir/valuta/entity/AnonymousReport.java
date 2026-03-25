package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "anonymous_report")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AnonymousReport {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "report_type", nullable = false, length = 50)
    private String reportType;

    @Column(nullable = false, length = 200)
    private String subject;

    @Column(columnDefinition = "TEXT")
    private String description;

    @CreatedDate
    @Column(name = "reported_at", nullable = false, updatable = false)
    private LocalDateTime reportedAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private AnonymousReportStatus status = AnonymousReportStatus.NEW;

    @Column(name = "company_id")
    private UUID companyId;

    @Column(name = "assigned_to_id")
    private Long assignedToId;

    @Column(columnDefinition = "TEXT")
    private String resolution;
}
