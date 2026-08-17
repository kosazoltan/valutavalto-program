package hu.puzzleir.valuta.dto.eveningclosing;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * FKH-036 FR-1: elkészített csomag nézet — KIZÁRÓLAG kimeno (FF) shipment-tételek
 * (terv 9. döntés: az UF sor bejovo szallitmany, nem "keszitett csomag").
 */
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class PackageView {
    /** ShipmentRequest.requestNumber. */
    private String packageId;
    /** A tétel valutájának kódja (Currency.code). */
    private String currency;
    /** ShipmentRequestItem.requestedAmount. */
    private BigDecimal amount;
    /** Plombaszám — lehet null. */
    private String sealNumber;
    /** Cél-iroda neve (Branch.name a toBranchId-n). */
    private String destination;
}
