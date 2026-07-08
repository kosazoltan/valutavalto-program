package hu.puzzleir.valuta.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * FS-10 S1: pénztárban rögzített ügyfél-válasz egy compliance-kérdésre.
 * DB-FK szándékosan NINCS (V39/V77 típus-drift tanulság) — a V347 parciális
 * unique indexei + a service fail-closed guardjai védenek. A JPA @Table-ben
 * nincs uniqueConstraints: a parciális (WHERE-es) indexet a JPA nem tudja
 * kifejezni, a guard a migrációban él.
 */
@Entity
@Table(name = "customer_question_answer", indexes = {
        @Index(name = "idx_cqa_company_customer", columnList = "company_id, customer_id"),
        @Index(name = "idx_cqa_company_question", columnList = "company_id, question_id")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CustomerQuestionAnswer {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** MULTI-TENANT: cég-azonosító — MINDEN query erre szűr. */
    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    /** ComplianceQuestion.id (UUID). */
    @Column(name = "question_id", nullable = false)
    private UUID questionId;

    /** Customer.id — IDENTITY Long (Customer.java:35-37). */
    @Column(name = "customer_id", nullable = false)
    private Long customerId;

    /** Transaction.id — IDENTITY Long (Transaction.java:45-47); opcionális. */
    @Column(name = "transaction_id")
    private Long transactionId;

    /** YES_NO esetén normalizált "YES"/"NO"; FREE_TEXT esetén szabad szöveg. */
    @Column(name = "answer_text", nullable = false, columnDefinition = "TEXT")
    private String answerText;

    @Column(name = "answered_by_worker_code", length = 50)
    private String answeredByWorkerCode;

    /** A service állítja (upsert-nél is frissül) — ezért nem @CreatedDate. */
    @Column(name = "answered_at", nullable = false)
    private LocalDateTime answeredAt;
}
