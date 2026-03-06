package hu.puzzleir.valuta.dto.eveningclosing;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Ügyfél adatok a napi adatcsomagban.
 *
 * Legacy: természetes + jogi személy adatok (UGYFEL tábla).
 */
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class CustomerData {
    private String customerId;
    private String customerName;
    private String customerAddress;
    private String documentNumber;
    private String nationality;
    private String customerType;  // NATURAL / LEGAL
}
