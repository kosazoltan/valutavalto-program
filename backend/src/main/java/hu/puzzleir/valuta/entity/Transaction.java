package hu.puzzleir.valuta.entity;

import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.entity.Company;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

/**
 * Tranzakció (Bizonylat) entity.
 *
 * Legacy mapping: TRAD+MMDD táblák (pl. TRAD1214)
 * - BIZONYLATSZAM: V/E + sorozat (pl. V00001, E00002)
 * - FIZETENDO: összeg Ft-ban
 * - VALUTANEM: valuta kód
 * - ARFOLYAM: alkalmazott árfolyam
 * - TIPUS: V=vétel, E=eladás, F=fronton, stb.
 * - PENZTAROSNEV, IDO
 * - UGYFELSZAM, UGYFELNEV, UGYFELCIM
 */
@Entity
@Table(name = "transaction", indexes = {
    @Index(name = "idx_transaction_date", columnList = "transaction_date"),
    @Index(name = "idx_transaction_branch", columnList = "branch_id"),
    @Index(name = "idx_transaction_worker", columnList = "worker_id"),
    @Index(name = "idx_transaction_receipt", columnList = "receipt_number"),
    @Index(name = "idx_transaction_company", columnList = "company_id")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Transaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * MULTI-TENANT: Cég kapcsolat
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;

    /**
     * Iroda/pénztár
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    /**
     * Pénztáros
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "worker_id", nullable = false)
    private Worker worker;

    /**
     * Bizonylat szám (pl. V00001, E00002)
     * Legacy: BIZONYLATSZAM
     */
    @Column(name = "receipt_number", nullable = false, length = 20)
    private String receiptNumber;

    /**
     * Tranzakció típusa
     * Legacy: TIPUS
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "transaction_type", nullable = false, length = 30)
    private TransactionType transactionType;

    /**
     * Tranzakció státusza
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private TransactionStatus status = TransactionStatus.COMPLETED;

    /**
     * Tranzakció dátuma
     * Legacy: DATUM (a tábla nevéből)
     */
    @Column(name = "transaction_date", nullable = false)
    private LocalDate transactionDate;

    /**
     * Tranzakció időpontja
     * Legacy: IDO
     */
    @Column(name = "transaction_time", nullable = false)
    private LocalTime transactionTime;

    // ============ VALUTA ADATOK ============

    /**
     * Valutanem
     * Legacy: VALUTANEM
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "currency_id", nullable = false)
    private Currency currency;

    /**
     * Valuta összeg
     */
    @Column(name = "currency_amount", nullable = false, precision = 15, scale = 2)
    private BigDecimal currencyAmount;

    /**
     * Alkalmazott árfolyam
     * Legacy: ARFOLYAM
     */
    @Column(name = "exchange_rate", nullable = false, precision = 12, scale = 4)
    private BigDecimal exchangeRate;

    /**
     * Forint összeg (fizetendő/kapott)
     * Legacy: FIZETENDO
     */
    @Column(name = "huf_amount", nullable = false, precision = 15, scale = 2)
    private BigDecimal hufAmount;

    // ============ DÍJAK ============

    /**
     * Kezelési díj
     */
    @Column(name = "handling_fee", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal handlingFee = BigDecimal.ZERO;

    /**
     * Kedvezmény összege
     * Legacy: SORENGEDMENY
     */
    @Column(name = "discount_amount", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal discountAmount = BigDecimal.ZERO;

    /**
     * Kedvezmény százalék
     */
    @Column(name = "discount_percent", precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal discountPercent = BigDecimal.ZERO;

    // ============ ÜGYFÉL ADATOK ============

    /**
     * Ügyfél azonosító
     * Legacy: UGYFELSZAM
     */
    @Column(name = "customer_id", length = 50)
    private String customerId;

    /**
     * Ügyfél neve
     * Legacy: UGYFELNEV
     */
    @Column(name = "customer_name", length = 200)
    private String customerName;

    /**
     * Ügyfél címe
     * Legacy: UGYFELCIM
     */
    @Column(name = "customer_address", length = 500)
    private String customerAddress;

    /**
     * Személyi/útlevél szám (adóhatósági azonosításhoz)
     */
    @Column(name = "customer_document_number", length = 50)
    private String customerDocumentNumber;

    /**
     * Ügyfél nemzetisége
     */
    @Column(name = "customer_nationality", length = 3)
    private String customerNationality;

    // ============ SZTORNÓ KAPCSOLAT ============

    /**
     * Eredeti tranzakció (ha ez sztornó)
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "original_transaction_id")
    private Transaction originalTransaction;

    /**
     * Sztornó oka
     */
    @Column(name = "reversal_reason", length = 500)
    private String reversalReason;

    /**
     * Sztornót jóváhagyó supervisor
     */
    @Column(name = "approved_by", length = 100)
    private String approvedBy;

    // ============ EGYÉB ============

    /**
     * Megjegyzés
     */
    @Column(length = 1000)
    private String notes;

    /**
     * Nyomtatva lett-e
     */
    @Column(name = "printed")
    @Builder.Default
    private Boolean printed = false;

    /**
     * MTCN szám (Western Union)
     */
    @Column(name = "mtcn", length = 50)
    private String mtcn;

    /**
     * Referencia szám (külső rendszerhez)
     */
    @Column(name = "reference_number", length = 100)
    private String referenceNumber;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // ============ MULTI-LINE SUPPORT ============

    /**
     * Bizonylat tetelek (max 6 valutasor).
     * Legacy: BLOKKTETEL tabla — egy bizonylaton max 6 kulonbozo valuta.
     */
    @OneToMany(mappedBy = "transaction", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @OrderBy("lineNumber ASC")
    @Builder.Default
    private java.util.List<TransactionLine> lines = new java.util.ArrayList<>();

    /**
     * Multi-line bizonylat (tobb valutasor)?
     */
    @Column(name = "multi_line")
    @Builder.Default
    private Boolean multiLine = false;

    /**
     * Tetelsorok szama
     */
    @Column(name = "line_count")
    @Builder.Default
    private Integer lineCount = 1;

    /**
     * Kezelesi dij tipusa (NONE/PER_MILLE/BRACKET)
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "handling_fee_type", length = 20)
    private HandlingFeeType handlingFeeType;

    /**
     * Kezdojegy osszeg
     */
    @Column(name = "initial_fee", precision = 10, scale = 0)
    @Builder.Default
    private BigDecimal initialFee = BigDecimal.ZERO;

    /**
     * Kedvezmeny tipus kod (legacy: _kedvWord)
     * 0=nincs, 4=VIP, 20=F1, 32=foertektaros, 33=ertektaros, 34=jutalektmentes
     */
    @Column(name = "discount_type_code")
    @Builder.Default
    private Integer discountTypeCode = 0;

    /**
     * AML flag - gyanus tranzakcio
     */
    @Column(name = "aml_suspicious")
    @Builder.Default
    private Boolean amlSuspicious = false;

    /**
     * AML flag - eves limit elerve
     */
    @Column(name = "aml_annual_limit_reached")
    @Builder.Default
    private Boolean amlAnnualLimitReached = false;

    // ============ HELPER METHODS ============

    /**
     * Nettó összeg számítása (díjak levonása után)
     */
    public BigDecimal getNetHufAmount() {
        return hufAmount.subtract(handlingFee).add(discountAmount);
    }

    /**
     * Ez sztornó tranzakció?
     */
    public boolean isReversal() {
        return transactionType == TransactionType.REVERSAL;
    }

    /**
     * Sztornózva lett-e?
     * HIGH FIX #13: null-safe.
     */
    public boolean isReversed() {
        return TransactionStatus.REVERSED.equals(status);
    }

    /**
     * Aktív (nem sztornózott) tranzakció?
     * HIGH FIX #13: null-safe — ha status null, nem aktív.
     */
    public boolean isActive() {
        return TransactionStatus.COMPLETED.equals(status);
    }
}
