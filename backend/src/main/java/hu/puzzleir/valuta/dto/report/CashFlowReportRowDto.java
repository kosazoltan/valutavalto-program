package hu.puzzleir.valuta.dto.report;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * FKH-030 FR-5: a Pénzforgalom riport egy bizonylat-sora.
 *
 * <p>Bizonylatonkénti sor (NEM napi/pénztári összesítés, FR-3): minden Transfer és
 * Shipment tétel saját sort kap.</p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CashFlowReportRowDto {

    /** A bizonylat dátuma (ISO), FR-4: több napos tartománynál soronként a saját nap. */
    private String date;

    /** Bizonylatszám (Transfer: transferNumber, Shipment: requestNumber; sztornónál -SZ). */
    private String receiptNumber;

    /**
     * FR-8: a partner azonosítója — pénztárnál a Branch.code numerikus része 3 jegyű,
     * 0-paddelt formában (BR076 → "076"), VAULT_COUNTERPARTY partnernél a betűkód
     * változatlanul (PRB, ERB, TRB, ...). A {@code HufDaybookService.partnerCode()}
     * logikájával azonos.
     */
    private String partnerCode;

    /** FR-8: "Bank" | "Terület" | "Pénztár" | "Egyéb" — a betűkód alapján képzett kategória. */
    private String partnerCategory;

    /** A tétel valutája (a Shipment-tételek több valutát is tartalmazhatnak → soronként bontva). */
    private String currency;

    /** Átvett összeg az adott valutában, vagy {@code null}, ha a sor átadás. */
    private BigDecimal receivedAmount;

    /** Átadott összeg az adott valutában, vagy {@code null}, ha a sor átvétel. */
    private BigDecimal handedOverAmount;

    /** FR-11: sztornó-sor jelölés (a Naplókönyv előjeles logikájának mintájára). */
    private boolean storno;
}
