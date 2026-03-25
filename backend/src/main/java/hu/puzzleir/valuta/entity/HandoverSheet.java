package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "handover_sheet")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class HandoverSheet {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "company_id")
    private UUID companyId;

    @Column(name = "sheet_number", nullable = false, unique = true, length = 50)
    private String sheetNumber;

    @Column(name = "from_cash_desk_id", nullable = false)
    private UUID fromCashDeskId;

    @Column(name = "to_cash_desk_id", nullable = false)
    private UUID toCashDeskId;

    @Column(name = "transfer_date", nullable = false)
    private LocalDate transferDate;

    @Column(columnDefinition = "TEXT")
    private String amounts;

    @Column(columnDefinition = "TEXT")
    private String notes;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private HandoverSheetStatus status = HandoverSheetStatus.DRAFT;

    @Column(name = "created_by_id")
    private Long createdById;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
