package hu.puzzleir.valuta.dto.eveningclosing;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Foglaló adatok a napi adatcsomagban.
 */
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class ReservationData {
    private Long reservationId;
    private String customerName;
    private String currencyCode;
    private BigDecimal amount;
    private BigDecimal depositAmount;
    private String status;
    private LocalDate reservationDate;
    private LocalDate expiryDate;
}
