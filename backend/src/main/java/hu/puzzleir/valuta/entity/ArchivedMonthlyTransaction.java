package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Havi záráskor archivált tranzakció.
 *
 * Legacy: NAPZAR.DLL CopyTables() — a napi TRAD+MMDD táblák tartalmát
 * havi gyűjtő táblákba (BF2603 stb.) másolta. Modern megfelelő:
 * minden lezárt hónap tranzakciója ide kerül archiválásra.
 */
@Entity
@Table(name = "archived_monthly_transaction", indexes = {
    @Index(name = "idx_amt_closing", columnList = "monthly_closing_id"),
    @Index(name = "idx_amt_branch_ym", columnList = "branch_id,year_month")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ArchivedMonthlyTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Kapcsolódó havi zárás
     */
    @Column(name = "monthly_closing_id", nullable = false)
    private Long monthlyClosingId;

    /**
     * Iroda azonosítója
     */
    @Column(name = "branch_id", nullable = false, columnDefinition = "UUID")
    private UUID branchId;

    /**
     * Cég azonosítója (multi-tenant)
     */
    @Column(name = "company_id", nullable = false, columnDefinition = "UUID")
    private UUID companyId;

    /**
     * Eredeti tranzakció ID-ja (ha nem sztornózott)
     */
    @Column(name = "original_tx_id")
    private Long originalTxId;

    /**
     * Tranzakció dátuma
     */
    @Column(name = "transaction_date", nullable = false)
    private LocalDate transactionDate;

    /**
     * Tranzakció típusa (BUY, SELL, stb.)
     */
    @Column(name = "transaction_type", nullable = false, length = 30)
    private String transactionType;

    /**
     * Valuta kód (EUR, USD, stb.)
     */
    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    /**
     * Valuta összeg
     */
    @Column(name = "currency_amount", nullable = false, precision = 18, scale = 2)
    private BigDecimal currencyAmount;

    /**
     * HUF összeg
     */
    @Column(name = "huf_amount", nullable = false, precision = 18, scale = 2)
    private BigDecimal hufAmount;

    /**
     * Alkalmazott árfolyam
     */
    @Column(name = "exchange_rate", precision = 18, scale = 6)
    private BigDecimal exchangeRate;

    /**
     * Kezelési díj
     */
    @Column(name = "handling_fee", precision = 18, scale = 2)
    private BigDecimal handlingFee;

    /**
     * Ügyfél azonosító (AML nyilvántartáshoz)
     */
    @Column(name = "customer_id", length = 50)
    private String customerId;

    /**
     * Pénztáros azonosítója
     */
    @Column(name = "worker_id")
    private Long workerId;

    /**
     * Archiválás időpontja
     */
    @Column(name = "archived_at", nullable = false)
    @Builder.Default
    private LocalDateTime archivedAt = LocalDateTime.now();

    /**
     * Év-hónap (pl. "2026-03") — gyors kereséshez
     */
    @Column(name = "year_month", nullable = false, length = 7)
    private String yearMonth;
}
