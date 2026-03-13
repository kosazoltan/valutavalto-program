package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Foglaló (Reservation) entity.
 *
 * Legacy mapping: FOGLALO.DLL — FoglaloBevetelezes / VisszaFizetoProcedura / FoglaloKivezetes
 * - Ügyfél letétbe helyez HUF-ot, lefoglal egy adott valutát adott árfolyamon
 * - Határidő lejártakor: teljesítés, ügyfél stornó, vagy EBC stornó
 * - FOGLALOKESZLET tábla megfelelője: valutanemenként elkülönített készlet
 */
@Entity
@Table(name = "reservation", indexes = {
    @Index(name = "idx_reservation_customer", columnList = "customer_id"),
    @Index(name = "idx_reservation_branch", columnList = "branch_id"),
    @Index(name = "idx_reservation_status", columnList = "status"),
    @Index(name = "idx_reservation_expires", columnList = "expires_at"),
    @Index(name = "idx_reservation_company", columnList = "company_id"),
    @Index(name = "idx_reservation_receipt", columnList = "receipt_number")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Reservation {

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
     * Ügyfél
     * Legacy: UGYFELSZAM, UGYFELNEV
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_id", nullable = false)
    private Customer customer;

    /**
     * Iroda/fiók
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    /**
     * Pénztáros aki létrehozta
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "worker_id", nullable = false)
    private Worker worker;

    /**
     * Lefoglalt valuta kódja (ISO 4217: EUR, USD, GBP, stb.)
     * Legacy: VALUTANEM
     */
    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    /**
     * Lefoglalt valuta mennyiség
     * Legacy: foglalt összeg
     */
    @Column(name = "reserved_amount", nullable = false, precision = 15, scale = 2)
    private BigDecimal reservedAmount;

    /**
     * Lefoglalás pillanatában érvényes árfolyam
     * Legacy: ARFOLYAM
     */
    @Column(name = "exchange_rate", nullable = false, precision = 12, scale = 4)
    private BigDecimal exchangeRate;

    /**
     * HUF letét összeg (= reservedAmount × exchangeRate, 5-re kerekítve)
     * Legacy: foglaló Ft összeg
     */
    @Column(name = "deposit_amount", nullable = false, precision = 15, scale = 2)
    private BigDecimal depositAmount;

    /**
     * Foglaló státusza
     * Legacy: _visszatipus (1=FULFILLED, 2=CANCELLED_BY_CUSTOMER, 3=CANCELLED_BY_COMPANY)
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    @Builder.Default
    private ReservationStatus status = ReservationStatus.ACTIVE;

    /**
     * Lejárati idő
     * Legacy: határidő kezelés
     */
    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    /**
     * Létrehozás időpontja
     */
    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    /**
     * Teljesítés időpontja
     */
    @Column(name = "fulfilled_at")
    private LocalDateTime fulfilledAt;

    /**
     * Stornózás időpontja
     */
    @Column(name = "cancelled_at")
    private LocalDateTime cancelledAt;

    /**
     * Bevételi bizonylat szám
     * Legacy: BebizIro — sorszám léptetés
     */
    @Column(name = "receipt_number", length = 50)
    private String receiptNumber;

    /**
     * Kiadási/stornó bizonylat szám
     * Legacy: KiBizIro — kifizetési bizonylat
     */
    @Column(name = "cancellation_receipt_number", length = 50)
    private String cancellationReceiptNumber;

    /**
     * Stornó oka (kötelező EBC stornónál)
     */
    @Column(name = "cancellation_reason", length = 500)
    private String cancellationReason;

    /**
     * Supervisor jóváhagyás (idő előtti kifizetéshez kötelező)
     * Legacy: supervisor jelszó ellenőrzés
     */
    @Column(name = "supervisor_approval")
    @Builder.Default
    private Boolean supervisorApproval = false;

    /**
     * Supervisor worker ID aki jóváhagyta
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "supervisor_worker_id")
    private Worker supervisorWorker;

    /**
     * Visszafizetett összeg
     * - FULFILLED (_visszatipus=1): deposit (normál teljesítés — ügyfél a valutát kapja, a letét beszámít)
     * - CANCELLED_BY_CUSTOMER (_visszatipus=2): 0 (ügyfél hibája, letét nem jár vissza)
     * - CANCELLED_BY_COMPANY (_visszatipus=3): 2 × deposit (EBC hibája, dupla visszafizetés)
     */
    @Column(name = "refund_amount", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal refundAmount = BigDecimal.ZERO;

    /**
     * Megjegyzés
     */
    @Column(length = 1000)
    private String notes;

    // ============ HELPER METHODS ============

    /**
     * Foglaló aktív-e?
     */
    public boolean isActive() {
        return ReservationStatus.ACTIVE.equals(status);
    }

    /**
     * Foglaló lejárt-e?
     */
    public boolean isExpired() {
        return ReservationStatus.ACTIVE.equals(status) && LocalDateTime.now().isAfter(expiresAt);
    }

    /**
     * Teljesíthető-e (aktív és nem lejárt)?
     */
    public boolean isFulfillable() {
        return ReservationStatus.ACTIVE.equals(status);
    }
}
