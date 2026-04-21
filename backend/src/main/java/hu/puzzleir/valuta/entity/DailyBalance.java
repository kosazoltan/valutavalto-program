package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.entity.Company;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Napi készlet / forgalom entity.
 * 
 * A Delphi napi záráskor számolta a készletmozgást:
 * nyitó + vétel + átvétel - eladás - átadás = záró
 * 
 * Ez a számviteli lánc alapja.
 * 
 * Legacy: napi forgalom számítás a NAPZAR.DLL-ben
 */
@Entity
@Table(name = "daily_balance", 
    indexes = {
        @Index(name = "idx_daily_balance_branch_date", columnList = "branch_id,balance_date"),
        @Index(name = "idx_daily_balance_date", columnList = "balance_date"),
        @Index(name = "idx_daily_balance_currency", columnList = "currency_code"),
        @Index(name = "idx_daily_balance_company", columnList = "company_id,balance_date")
    },
    uniqueConstraints = {
        @UniqueConstraint(name = "uq_daily_balance_branch_date_currency", 
            columnNames = {"branch_id", "balance_date", "currency_code", "company_id"})
    }
)
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DailyBalance {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @jakarta.persistence.Version
    @Column(name = "version", nullable = false)
    private Long version = 0L;

    /**
     * Iroda ID
     */
    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    /**
     * Mérleg dátuma
     */
    @Column(name = "balance_date", nullable = false)
    private LocalDate balanceDate;

    /**
     * Valuta kód
     */
    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    /**
     * Nyitó készlet (előző nap záró)
     */
    @Column(name = "opening_balance", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal openingBalance = BigDecimal.ZERO;

    /**
     * Vásárlás (beérkezett valuta)
     */
    @Column(name = "purchases", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal purchases = BigDecimal.ZERO;

    /**
     * Átvétel más irodától
     */
    @Column(name = "transfers_in", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal transfersIn = BigDecimal.ZERO;

    /**
     * Eladás (kiadott valuta)
     */
    @Column(name = "sales", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal sales = BigDecimal.ZERO;

    /**
     * Átadás más irodába
     */
    @Column(name = "transfers_out", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal transfersOut = BigDecimal.ZERO;

    /**
     * Záró készlet (számított: nyitó + vétel + átvétel - eladás - átadás)
     */
    @Column(name = "closing_balance", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal closingBalance = BigDecimal.ZERO;

    /**
     * Tényleges leltári készlet (ha van leltár)
     */
    @Column(name = "actual_stock", precision = 18, scale = 2)
    private BigDecimal actualStock;

    /**
     * Eltérés (záró - tényleges)
     */
    @Column(name = "difference", precision = 18, scale = 2)
    private BigDecimal difference;

    /**
     * Létrehozás időpontja
     */
    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    /**
     * Ki zárta le
     */
    @Column(name = "closed_by", length = 100)
    private String closedBy;

    /**
     * MULTI-TENANT: Cég kapcsolat
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;

    /**
     * Lezárva?
     */
    @Column(name = "is_closed")
    @Builder.Default
    private Boolean isClosed = false;

    /**
     * Lezárás időpontja
     */
    @Column(name = "closed_at")
    private LocalDateTime closedAt;

    /**
     * Megjegyzés eltérés esetén
     */
    @Column(name = "difference_note", columnDefinition = "TEXT")
    private String differenceNote;

    // --- S1-01: MNB gyűjtő készlet/mozgás mezők (Delphi legacy) ---

    /** Banki átvétel — Delphi: BANKIATVETEL */
    @Column(name = "bank_in", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal bankIn = BigDecimal.ZERO;

    /** Banki átadás — Delphi: BANKIATADAS */
    @Column(name = "bank_out", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal bankOut = BigDecimal.ZERO;

    /** Készlettöbblet — Delphi: TOBBLET */
    @Column(name = "surplus", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal surplus = BigDecimal.ZERO;

    /** Készlethiány — Delphi: HIANY */
    @Column(name = "shortage", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal shortage = BigDecimal.ZERO;

    /** Visszavétel bejövő — Delphi: VISSZAPLUSZ */
    @Column(name = "returns_in", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal returnsIn = BigDecimal.ZERO;

    /** Visszavétel kimenő — Delphi: VISSZAMINUSZ */
    @Column(name = "returns_out", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal returnsOut = BigDecimal.ZERO;

    /** Bankkártyás forgalom HUF — Delphi: BANKKARTYA */
    @Column(name = "card_payment", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal cardPayment = BigDecimal.ZERO;

    /** Számított záró (MNB validáció) */
    @Column(name = "calculated_closing", precision = 18, scale = 2)
    private BigDecimal calculatedClosing;

    /** Validáció eredménye: OK vagy ? */
    @Column(name = "validation_status", length = 5)
    private String validationStatus;

    /**
     * Záró készlet számítása (alapképlet: nyitó + bevétel - kiadás)
     */
    public void calculateClosingBalance() {
        this.closingBalance = openingBalance
            .add(purchases)
            .add(transfersIn)
            .subtract(sales)
            .subtract(transfersOut);
    }

    /**
     * MNB validáció: számított záró a teljes mozgásokkal.
     * Delphi AdatKiertekeles logika:
     *   bevétel = nyitó + vétel + többlet + pénztárból + bankból + visszaPlusz
     *   kiadás  = eladás + hiány + pénztárba + bankba + visszaMínusz
     *   számítottZáró = bevétel - kiadás
     */
    public void calculateMnbValidation() {
        BigDecimal income = openingBalance
            .add(purchases)
            .add(surplus)
            .add(transfersIn)
            .add(bankIn)
            .add(returnsIn);
        BigDecimal expense = sales
            .add(shortage)
            .add(transfersOut)
            .add(bankOut)
            .add(returnsOut);
        this.calculatedClosing = income.subtract(expense);
        BigDecimal diff = closingBalance.subtract(calculatedClosing).abs();
        this.validationStatus = diff.compareTo(BigDecimal.ZERO) == 0 ? "OK" : "?";
    }

    /**
     * Eltérés számítása
     */
    public void calculateDifference() {
        if (actualStock != null) {
            this.difference = closingBalance.subtract(actualStock);
        }
    }

    /**
     * Automatikus kalkuláció mentés előtt
     */
    @PrePersist
    @PreUpdate
    public void onSave() {
        calculateClosingBalance();
        if (actualStock != null) {
            calculateDifference();
        }
    }
}
