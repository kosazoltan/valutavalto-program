package hu.puzzleir.valuta.dto.eveningclosing;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Napi adatcsomag — esti záráskor a központnak küldött összesített adat.
 *
 * Legacy: Delphi CsomagoloGombClick → bináris PutByte/PutWord/PutInteger/PutString csomag FTP-n.
 * Modern: JSON REST API — strukturált, ember-olvasható, verzionálható.
 *
 * Tartalmazza:
 * 1. Tranzakciók (BLOKKFEJ + BLOKKTETEL ekvivalens)
 * 2. Címletezés adatok
 * 3. Napi árfolyamok
 * 4. Ügyfél adatok (természetes + jogi személy)
 * 5. Foglaló adatok
 * 6. Kezelési díj összesítő
 */
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class DailyDataPackage {
    private Long branchId;
    private LocalDate date;
    private List<TransactionSummary> transactions;
    private List<DenominationEntry> denominations;
    private List<RateSnapshot> rates;
    private List<CustomerData> customers;
    private List<ReservationData> reservations;
    private HandlingFeeSummary handlingFees;

    /** SHA-256 checksum az adatokról — integritás ellenőrzés. */
    private String checksum;

    // ============ FKH-036 FR-1: ÖSSZEFOGLALÓ MEZŐK (ADDITÍV) ============
    // A nyers aggregát-listák fent VÁLTOZATLANOK — a sendToHeadquarters és az
    // artifact JSON jelentése nem változik. Ezek a mezők a UI-előnézetet szolgálják,
    // a calculateChecksum() őket NEM hasheli (checksum-immunitás, terv pitfall 2).

    private String branchName;

    /** NOT_STARTED | PREVIEW | SENT — EveningSyncLog-ból származtatva; CONFIRMED soha. */
    private String status;

    private int transactionCount;

    private BigDecimal totalBuyHuf;

    private BigDecimal totalSellHuf;

    /** 1, ha van függőben lévő (PENDING/ARTIFACT_PENDING/FAILED) esti szinkron erre a napra. */
    private int pendingSyncs;

    /** Aznapi ACTIVE foglalók száma (dátum-szkópolt, nem teljes backlog). */
    private int openReservations;

    /** Soha nem null — üres lista, ha nincs figyelmeztetés. */
    private List<String> warnings;

    /** Soha nem null. */
    private List<BalanceView> balances;

    /** Soha nem null. */
    private List<PackageView> packages;
}
