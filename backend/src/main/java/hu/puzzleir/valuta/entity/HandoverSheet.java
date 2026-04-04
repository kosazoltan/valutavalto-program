package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Értéktári Átadólap entitás.
 *
 * Legacy: ATADOLAP DLL (64K) — _etData[] tömb (93+ mező).
 * A Delphi struktúra:
 *   [1] Értéktárszám, [2] Dátum, [3] Átadó, [4] Átvevő
 *   [5-7] Pénzkészlet egyezés/eltérés
 *   [8-16] Tartozások (max 3 tétel)
 *   [17-25] Követelések (max 3 tétel)
 *   [26-31] WU/ÁFA rendelés (max 2 tétel)
 *   [32-47] Banki beszállítás (max 4 tétel: devizanem, összeg, név, árfolyam)
 *   [48-59] Banki kiszállítás (max 4 tétel)
 *   [60-79] Pénztári rendelések (max 4 tétel)
 *   [80-91] Körlevelek (max 4 tétel)
 *   [92-93] Egyéb info (szabad szöveg)
 */
@Entity
@Table(name = "handover_sheet")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class HandoverSheet {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "company_id")
    private UUID companyId;

    @Column(name = "sheet_number", nullable = false, unique = true, length = 50)
    private String sheetNumber;

    @Column(name = "from_cash_desk_id", nullable = false)
    private UUID fromCashDeskId;

    @Column(name = "to_cash_desk_id", nullable = false)
    private UUID toCashDeskId;

    @Column(name = "transfer_date", nullable = false)
    private LocalDate transferDate;

    // --- Legacy [3-4]: Átadó/Átvevő ---
    @Column(name = "handed_over_by", length = 100)
    private String handedOverBy;

    @Column(name = "received_by", length = 100)
    private String receivedBy;

    // --- Legacy [5-7]: Pénzkészlet egyezés ---
    /** true = egyezik, false = nem egyezik, null = nem ellenőrizve */
    @Column(name = "cash_balance_matches")
    private Boolean cashBalanceMatches;

    /** Eltérés összege HUF-ban (null ha egyezik) */
    @Column(name = "cash_balance_deviation", precision = 15, scale = 0)
    private BigDecimal cashBalanceDeviation;

    // --- Legacy [8-25]: Tartozások és Követelések (JSONB) ---
    /**
     * Tartozások (max 3 tétel): [{vaultNumber, amount, currency}]
     * Legacy: _etData[8-16]
     */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "debts", columnDefinition = "jsonb")
    private List<DebtEntry> debts;

    /**
     * Követelések (max 3 tétel): [{vaultNumber, amount, currency}]
     * Legacy: _etData[17-25]
     */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "claims", columnDefinition = "jsonb")
    private List<ClaimEntry> claims;

    // --- Legacy [26-31]: WU/ÁFA rendelés ---
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "wu_vat_orders", columnDefinition = "jsonb")
    private List<WuVatOrder> wuVatOrders;

    // --- Legacy [32-47]: Banki beszállítás (max 4 tétel) ---
    /**
     * Banki beszállítás: [{currency, amount, counterparty, rate}]
     * Legacy: _etData[32-47] — 4×4 mező/tétel
     */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "bank_inbound_shipments", columnDefinition = "jsonb")
    private List<BankShipmentEntry> bankInboundShipments;

    // --- Legacy [48-59]: Banki kiszállítás (max 4 tétel) ---
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "bank_outbound_shipments", columnDefinition = "jsonb")
    private List<BankShipmentEntry> bankOutboundShipments;

    // --- Legacy [60-79]: Pénztári rendelések (max 4 tétel) ---
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "cash_desk_orders", columnDefinition = "jsonb")
    private List<CashDeskOrder> cashDeskOrders;

    // --- Legacy [80-91]: Körlevelek (max 4 tétel) ---
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "circulars", columnDefinition = "jsonb")
    private List<CircularEntry> circulars;

    // --- Legacy: devizánkénti összegek (eredeti amounts mező) ---
    @Column(columnDefinition = "TEXT")
    private String amounts;

    // --- Legacy [92-93]: Egyéb info ---
    @Column(columnDefinition = "TEXT")
    private String notes;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private HandoverSheetStatus status = HandoverSheetStatus.DRAFT;

    @Column(name = "created_by_id")
    private Long createdById;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // ============ EMBEDDED VALUE OBJECTS ============

    @Embeddable
    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class DebtEntry {
        private String vaultNumber;
        private BigDecimal amount;
        private String currency;
    }

    @Embeddable
    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class ClaimEntry {
        private String vaultNumber;
        private BigDecimal amount;
        private String currency;
    }

    @Embeddable
    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class WuVatOrder {
        private String description;
        private BigDecimal amount;
        private String currency;
    }

    @Embeddable
    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class BankShipmentEntry {
        /** Devizanem (EUR, USD, stb.) */
        private String currency;
        /** Összeg */
        private BigDecimal amount;
        /** Banki partner neve */
        private String counterparty;
        /** Alkalmazott árfolyam */
        private BigDecimal rate;
    }

    @Embeddable
    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class CashDeskOrder {
        private String currency;
        private String cashDeskName;
        private String workerName;
        private BigDecimal amount;
        private BigDecimal rate;
    }

    @Embeddable
    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class CircularEntry {
        private String subject;
        private String content;
        private String issuedBy;
    }
}
