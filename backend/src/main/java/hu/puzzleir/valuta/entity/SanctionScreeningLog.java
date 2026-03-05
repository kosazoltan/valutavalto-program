package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Szankciós szűrés audit napló.
 *
 * Minden szűrés naplózva van — jogszabályi kötelezettség (Pmt. 2017. évi LIII. tv.)
 * Rögzíti ki, mikor, kit szűrt, és mi volt az eredmény.
 */
@Entity
@Table(name = "sanction_screening_log", indexes = {
        @Index(name = "idx_screening_log_screened_name", columnList = "screened_name"),
        @Index(name = "idx_screening_log_result", columnList = "result"),
        @Index(name = "idx_screening_log_created", columnList = "created_at"),
        @Index(name = "idx_screening_log_worker", columnList = "worker_id")
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class SanctionScreeningLog {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** Szűrt személy neve */
    @Column(name = "screened_name", nullable = false, length = 500)
    private String screenedName;

    /** Szűrt okmányszám (ha megadták) */
    @Column(name = "screened_document_number", length = 100)
    private String screenedDocumentNumber;

    /** Szűrt születési dátum (ha megadták) */
    @Column(name = "screened_date_of_birth", length = 50)
    private String screenedDateOfBirth;

    /** Szűrés eredménye: CLEAR, POSSIBLE, CONFIRMED */
    @Column(name = "result", nullable = false, length = 20)
    private String result;

    /** Találatok száma */
    @Column(name = "match_count", nullable = false)
    @Builder.Default
    private Integer matchCount = 0;

    /** Találatok részletezése (JSON) */
    @Column(name = "match_details", columnDefinition = "TEXT")
    private String matchDetails;

    /** Szűrést végző pénztáros ID */
    @Column(name = "worker_id", length = 50)
    private String workerId;

    /** Szűrést végző pénztáros neve */
    @Column(name = "worker_name", length = 200)
    private String workerName;

    /** Iroda kódja */
    @Column(name = "branch_code", length = 20)
    private String branchCode;

    /** Supervisor jóváhagyás (POSSIBLE esetén) */
    @Column(name = "supervisor_approved")
    @Builder.Default
    private Boolean supervisorApproved = false;

    /** Supervisor neve (ha jóváhagyta) */
    @Column(name = "supervisor_name", length = 200)
    private String supervisorName;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
