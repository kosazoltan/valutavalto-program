package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import jakarta.persistence.Version;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import hu.puzzleir.valuta.entity.Branch;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.UUID;

@Entity
@Table(name = "transfer")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Transfer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // A sorszám-egyediség CÉGSZINTŰ (V299: uq_transfer_company_number (company_id, transfer_number)),
    // NEM globális — a per-tenant AT/AV/FF/UF-NNNNNN sorszám miatt két cég azonos sorszámot kaphat.
    @Column(name = "transfer_number", nullable = false, length = 30)
    private String transferNumber;

    /** A bizonylat cége (multi-tenant + cégszintű sorszám-egyediség). A create a from_branch cégéből tölti. */
    @Column(name = "company_id")
    private UUID companyId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "from_branch_id", nullable = false)
    private Branch fromBranch;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "to_branch_id", nullable = false)
    private Branch toBranch;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "from_worker_id", nullable = false)
    private Worker fromWorker;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "to_worker_id")
    private Worker toWorker;

    @Enumerated(EnumType.STRING)
    @Column(name = "transfer_type", nullable = false, length = 20)
    private TransferType transferType;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private TransferStatus status;

    @Column(name = "transfer_date", nullable = false)
    private LocalDate transferDate;

    @Column(name = "transfer_time", nullable = false)
    private LocalTime transferTime;

    @Column(name = "received_date")
    private LocalDate receivedDate;

    @Column(name = "received_time")
    private LocalTime receivedTime;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "currency_id", nullable = false)
    private Currency currency;

    @Column(nullable = false, precision = 18, scale = 4)
    private BigDecimal amount;

    @Column(name = "huf_value", precision = 18, scale = 2)
    private BigDecimal hufValue;

    /**
     * Több-valutás átadólap sorai (#6). ÜRES a hagyományos egy-valutás átadásnál
     * (akkor a fenti currency+amount a forrás). Ha van sor, a header currency/amount
     * az ELSŐ sort tükrözi, a cash-balance pedig soronként könyvel.
     */
    @OneToMany(mappedBy = "transfer", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @Builder.Default
    private java.util.List<TransferLine> lines = new java.util.ArrayList<>();

    @Column(name = "received_amount", precision = 18, scale = 4)
    private BigDecimal receivedAmount;

    @Column(name = "difference", precision = 18, scale = 4)
    private BigDecimal difference;

    @Enumerated(EnumType.STRING)
    @Column(name = "direction", length = 2)
    @Builder.Default
    private TransferDirection direction = TransferDirection.UF;

    @Column(columnDefinition = "TEXT")
    private String notes;

    // FR/NFR-1,2 (V283): szerződés-igazítás 128/64-re (a DTO @Size-zal egyezően). Nullable marad:
    // a régi rekordok null-ok lehetnek, az új-rekord-kötelezőséget a CreateTransferDto @NotBlank védi.
    @Column(name = "carrier_name", length = 128)
    private String carrierName;

    @Column(name = "seal_number", length = 64)
    private String sealNumber;

    // Értéktári átadás-átvétel sztornó (V299): az eredeti rekord megmarad, csak megjelölődik.
    // A sztornó bizonylat sorszáma a service-ben képződik (<eredeti>-SZ), nem külön rekord.
    @Column(name = "is_cancelled", nullable = false)
    @Builder.Default
    private Boolean isCancelled = false;

    @Column(name = "cancelled_at")
    private LocalDateTime cancelledAt;

    @Column(name = "cancellation_reason", length = 500)
    private String cancellationReason;

    /** A sztornózó dolgozó id-ja (worker.id). */
    @Column(name = "cancelled_by")
    private Long cancelledBy;

    /** Opcionális címletezés (darab × névleges érték) — üres, ha nem adtak meg. */
    @OneToMany(mappedBy = "transfer", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @Builder.Default
    private java.util.List<TransferDenomination> denominations = new java.util.ArrayList<>();

    @Column(name = "handover_printed")
    @Builder.Default
    private Boolean handoverPrinted = false;

    @Column(name = "receipt_printed")
    @Builder.Default
    private Boolean receiptPrinted = false;

    @Version
    private Long version;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    /**
     * Kötés-típus. A négy technikai gyűjtő-kód (ERB/FRB/TRB/PRB) a legacy
     * rögzítő-bizonylat (RB) gyűjtőit képezi le (b5-penztar-mozgasok.md:51-72,
     * c4 P3#5 gap, üzleti döntés 2026-06-11):
     *   ERB = FIXING VALUTA MOZGÁS RB (csak deviza),
     *   FRB = FORINT MOZGÁS RB (csak HUF),
     *   TRB = EGYEDI KÖTÉS RB (csak deviza),
     *   PRB = POS ÁTVÉTEL BANKTÓL (csak HUF, csak átvétel irány).
     * A bizonylat-sorszám prefix (AT/AV/FF/UF) valuta+irány alapú, típus-független.
     *
     * FIGYELEM — két külön "kezelési díj" mechanizmus él (2026-07-15 audit):
     * a {@code HANDLING_FEE} ITT a legacy /transfers kézi pénzmozgás-bizonylat típusa
     * (HUF-only, UI-ról választható — transferRules.ts). A jóváhagyás-életciklusos KK
     * kezelési-díj a KÜLÖN Shipment-modulon fut (ShipmentHandlingFeeService, "KK" prefix,
     * shipment_handling_fee tábla) — oda ÚJ funkciót NE Transfer-alapon implementálj.
     * Az érték @Enumerated(STRING)-ként DB-perzisztált, eltávolítása adatvesztő — TILOS.
     */
    public enum TransferType {
        CURRENCY, CASH, HANDLING_FEE, VAULT_DEPOSIT, VAULT_WITHDRAW, CORRECTION, OTHER,
        ERB, FRB, TRB, PRB
    }

    public enum TransferStatus {
        PENDING, IN_TRANSIT, RECEIVED, COMPLETED, REJECTED, CANCELLED
    }

    /**
     * Átadás iránya (legacy Delphi kompatibilis).
     *
     * F  = Feladó (Sender only): TRANSFER_OUT tx a küldő fióknál
     * U  = Vevő (Receiver only): TRANSFER_IN tx a fogadó fióknál
     * UF = Teljes körforgás: mindkét oldal tranzakciója egyszerre (küldő + fogadó)
     * FF = Dupla feladó (korrekció): két TRANSFER_OUT tx (adminisztratív javítás)
     */
    public enum TransferDirection {
        F,   // Feladó — csak kimenő tranzakció
        U,   // Vevő — csak bejövő tranzakció
        UF,  // Mindkét irány egyszerre
        FF   // Korrekció — két kimenő
    }
}
