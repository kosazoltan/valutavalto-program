package hu.puzzleir.valuta.entity;

import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.entity.Company;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Napi munkamenet (nyitás/zárás) entity.
 *
 * Legacy mapping: HARDWARE tábla + NAPZAR funkció
 * - MEGNYITOTTNAP: aktuális munkanap dátuma
 * - NAPISTORNO: napi sztornók száma
 * - Napi nyitás: VTEMP inicializálás
 * - Napi zárás: cimletezés ellenőrzés, adatfeltöltés
 */
@Entity
@Table(name = "daily_session", indexes = {
    @Index(name = "idx_daily_session_date", columnList = "session_date"),
    @Index(name = "idx_daily_session_branch", columnList = "branch_id")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DailySession {

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
     * Munkamenet dátuma
     * Legacy: MEGNYITOTTNAP
     */
    @Column(name = "session_date", nullable = false)
    private LocalDate sessionDate;

    /**
     * Státusz
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private DailySessionStatus status = DailySessionStatus.OPEN;

    // ============ NYITÁS ADATOK ============

    /**
     * Nyitó pénztáros
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "opened_by_worker_id")
    private Worker openedByWorker;

    /**
     * Nyitás időpontja
     */
    @Column(name = "opened_at")
    private LocalDateTime openedAt;

    /**
     * Nyitó HUF egyenleg
     */
    @Column(name = "opening_balance_huf", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal openingBalanceHuf = BigDecimal.ZERO;

    // ============ ZÁRÁS ADATOK ============

    /**
     * Záró pénztáros
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "closed_by_worker_id")
    private Worker closedByWorker;

    /**
     * Zárás időpontja
     */
    @Column(name = "closed_at")
    private LocalDateTime closedAt;

    /**
     * Záró HUF egyenleg
     */
    @Column(name = "closing_balance_huf", precision = 15, scale = 2)
    private BigDecimal closingBalanceHuf;

    /**
     * Címletezés ellenőrizve
     * Legacy: cimletezés validálás
     */
    @Column(name = "denomination_verified")
    @Builder.Default
    private Boolean denominationVerified = false;

    // ============ NAPI STATISZTIKÁK ============

    /**
     * Napi tranzakciók száma
     */
    @Column(name = "transaction_count")
    @Builder.Default
    private Integer transactionCount = 0;

    /**
     * Napi vételi tranzakciók száma
     */
    @Column(name = "buy_count")
    @Builder.Default
    private Integer buyCount = 0;

    /**
     * Napi eladási tranzakciók száma
     */
    @Column(name = "sell_count")
    @Builder.Default
    private Integer sellCount = 0;

    /**
     * Napi sztornók száma
     * Legacy: NAPISTORNO
     */
    @Column(name = "reversal_count")
    @Builder.Default
    private Integer reversalCount = 0;

    /**
     * Napi vételi forgalom (HUF)
     */
    @Column(name = "buy_turnover_huf", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal buyTurnoverHuf = BigDecimal.ZERO;

    /**
     * Napi eladási forgalom (HUF)
     */
    @Column(name = "sell_turnover_huf", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal sellTurnoverHuf = BigDecimal.ZERO;

    /**
     * Napi kezelési díj bevétel
     */
    @Column(name = "handling_fee_total", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal handlingFeeTotal = BigDecimal.ZERO;

    // ============ EGYÉB ============

    /**
     * Megjegyzések
     */
    @Column(length = 1000)
    private String notes;

    /**
     * QR kód generálva (napi záráshoz)
     * Legacy: QRPARAMS - NUMBER=3
     */
    @Column(name = "qr_code_generated")
    @Builder.Default
    private Boolean qrCodeGenerated = false;

    /**
     * NAV feltöltve
     */
    @Column(name = "nav_uploaded")
    @Builder.Default
    private Boolean navUploaded = false;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // ============ HELPER METHODS ============

    /**
     * Session nyitva van?
     */
    public boolean isOpen() {
        return status == DailySessionStatus.OPEN;
    }

    /**
     * Session zárva van?
     */
    public boolean isClosed() {
        return status == DailySessionStatus.CLOSED;
    }

    /**
     * Napi nettó forgalom
     */
    public BigDecimal getNetTurnover() {
        return sellTurnoverHuf.subtract(buyTurnoverHuf);
    }

    /**
     * Tranzakció hozzáadása a statisztikákhoz
     */
    public void addTransaction(TransactionType type, BigDecimal hufAmount, BigDecimal handlingFee) {
        this.transactionCount++;

        if (type.isBuyType()) {
            this.buyCount++;
            this.buyTurnoverHuf = this.buyTurnoverHuf.add(hufAmount);
        } else if (type.isSellType()) {
            this.sellCount++;
            this.sellTurnoverHuf = this.sellTurnoverHuf.add(hufAmount);
        } else if (type == TransactionType.REVERSAL) {
            this.reversalCount++;
        }

        if (handlingFee != null) {
            this.handlingFeeTotal = this.handlingFeeTotal.add(handlingFee);
        }
    }
}
