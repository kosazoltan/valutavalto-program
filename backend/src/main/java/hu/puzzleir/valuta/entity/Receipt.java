package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "receipt")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Receipt {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "company_id")
    private UUID companyId;

    @Column(name = "receipt_number", nullable = false, unique = true, length = 50)
    private String receiptNumber;

    @Column(name = "transaction_id")
    private UUID transactionId;

    @Column(name = "receipt_type", nullable = false, length = 50)
    private String receiptType;

    @Column(name = "issue_date", nullable = false)
    private LocalDate issueDate;

    @Column(columnDefinition = "TEXT")
    private String content;

    @Column(name = "nav_receipt_number", length = 100)
    private String navReceiptNumber;

    @Column(name = "is_printed", nullable = false)
    @Builder.Default
    private Boolean isPrinted = false;

    @Column(name = "printed_at")
    private LocalDateTime printedAt;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // === EXCMD b5b (FR-BSZUR-02 "csak ügyfeles" + FR-BSZUR-05 10M Ft AML-jelölő) ===
    // A bizonylat-böngésző szűrője ügyfél-jelenlét és HUF-küszöb alapján szűr/jelöl.
    // Ezek NEM a receipt táblában tárolódnak, hanem a kapcsolt Transaction-ből jönnek
    // (read-through view layer, ld. ReceiptService). @Transient → JPA nem perzisztálja,
    // de a Jackson SERIALIZÁLJA, így megjelennek a GET /api/v1/receipts JSON-ban.
    @Transient
    private String customerName;

    @Transient
    private BigDecimal hufAmount;

    // === EXCMD b5b FR-BSZUR-03 (természetes személy ügyfél-adatlap szűrőmezők) ===
    // Szintén a kapcsolt Transaction-snapshotból (read-through), @Transient → Jackson serializálja.
    // A bizonylat-böngésző ezekre LIKE-szűrhet. (LEÁNYKORI NEVE nincs a tx-snapshotban → defer.)
    @Transient
    private String customerMotherName;

    @Transient
    private String customerBirthPlace;

    @Transient
    private LocalDate customerBirthDate;

    @Transient
    private String customerNationality;

    @Transient
    private String customerAddress;

    @Transient
    private String customerDocumentType;

    @Transient
    private String customerDocumentNumber;

    // === EXCMD b5b FR-BSZUR-04 (jogi személy / képviselő) ===
    // A tx-snapshot customerActorName mezője: a más nevében eljáró személy (meghatalmazott /
    // jogi személy képviselője). "Jogi személy neve" → customerName, "Telephely címe" →
    // customerAddress (a snapshot a szerződő fél adatait hordozza, jogi személynél is).
    // "Képviselő beosztása" SEHOL nincs az adatmodellben (Transaction + Customer ellenőrizve) → defer.
    @Transient
    private String customerActorName;

    // === EXCMD b5b FR-BSZUR-05 (ENGEDÉLYEZŐ neve + beosztása) — V312 ===
    // A kapcsolt Transaction.approvalSessionId-n át a transaction_aml_approval rekordból
    // töltődik (read-through, ld. ReceiptService.enrichApprovers). Csak megjelenítés.
    // A session-kulcs maga NEM kerül a JSON-ba (belső kapcsoló-adat).
    @Transient
    @com.fasterxml.jackson.annotation.JsonIgnore
    private String approvalSessionId;

    @Transient
    private String approvedByName;

    @Transient
    private String approvedByRole;
}
