package hu.puzzleir.valuta.dto.eveningclosing;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

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
}
