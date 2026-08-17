package hu.puzzleir.valuta.dto.closingwizard;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ClosingWizardStatusDto {
    private String branchId;
    private String closingDate;
    private boolean vaultContext;
    private boolean denominationRecorded;
    private boolean exactMatch;
    private String message;
    private List<Map<String, Object>> differences;

    /**
     * FK-065 FR-2 (egyhívásos FR-3 szerződés): a napra vonatkozó beragadt/aktív wizard
     * jelzése a kliensnek — a frontend ebből dönt, külön get() hívás nélkül.
     * Kitöltés: mai IN_PROGRESS sor id-ja + "IN_PROGRESS"; különben mai EXPIRED sor
     * id-ja + "EXPIRED"; különben mindkettő null.
     */
    private String activeWizardId;
    private String activeWizardStatus;

    /**
     * FKH-036 FR-5: vault-kontextusban a BLOKKOLÓ (kötelező) valutakódok — HUF mindig,
     * plusz az aznapi FF/UF shipment-mozgás valutái. Pénztári ágon {@code null}.
     */
    private List<String> requiredCurrencies;
    /** FKH-036 FR-6: vault-kontextusban true, ha aznap volt KK kezelési díj mozgás. */
    private boolean handlingFeeRequired;
}
