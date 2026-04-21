package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Banki tranzakció — valuta vétel/eladás bankkal.
 * Legacy MATPTAR megfelelő.
 * BUY = bankból vesz valutát (értéktár készlet nő),
 * SELL = banknak ad el valutát (értéktár készlet csökken, HUF nő).
 */
@Entity
@Table(name = "vault_bank_transaction")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class VaultBankTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "vault_territory_id")
    private VaultTerritory vaultTerritory;

    /**
     * BUY = bankból valutát vásárolunk,
     * SELL = banknak valutát eladunk
     */
    @Column(name = "transaction_type", nullable = false, length = 10)
    private String transactionType;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal amount;

    @Column(name = "exchange_rate", nullable = false, precision = 12, scale = 4)
    private BigDecimal exchangeRate;

    @Column(name = "huf_amount", nullable = false, precision = 18, scale = 2)
    private BigDecimal hufAmount;

    @Column(name = "bank_name", length = 100)
    private String bankName;

    @Column(name = "bank_reference", length = 100)
    private String bankReference;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private VaultOperationStatus status;

    @Column(length = 500)
    private String note;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(name = "created_by")
    private Long createdBy;

    @Column(name = "approved_by")
    private Long approvedBy;

    // Workflow: deviza oldali megerositese (a bankunktol megerkezett a deviza)
    @Column(name = "received_at")
    private LocalDateTime receivedAt;

    @Column(name = "received_by")
    private Long receivedBy;

    // Workflow: HUF oldali megerositese (atutaltuk a banknak a HUF-ot)
    @Column(name = "paid_at")
    private LocalDateTime paidAt;

    @Column(name = "paid_by")
    private Long paidBy;
}
