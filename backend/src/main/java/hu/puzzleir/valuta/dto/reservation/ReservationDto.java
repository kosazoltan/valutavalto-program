package hu.puzzleir.valuta.dto.reservation;

import hu.puzzleir.valuta.entity.ReservationStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Foglaló response DTO.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReservationDto {

    private Long id;

    /** Ügyfél */
    private Long customerId;
    private String customerName;

    /** Iroda */
    private String branchId;
    private String branchName;

    /** Pénztáros */
    private Long workerId;
    private String workerName;

    /** Valuta */
    private String currencyCode;
    private BigDecimal reservedAmount;
    private BigDecimal exchangeRate;
    private BigDecimal depositAmount;

    /** Státusz */
    private ReservationStatus status;

    /** Időpontok */
    private LocalDateTime expiresAt;
    private LocalDateTime createdAt;
    private LocalDateTime fulfilledAt;
    private LocalDateTime cancelledAt;

    /** Bizonylatok */
    private String receiptNumber;
    private String cancellationReceiptNumber;

    /** Stornó részletek */
    private String cancellationReason;
    private Boolean supervisorApproval;
    private Long supervisorWorkerId;
    private String supervisorWorkerName;

    /** Visszafizetés */
    private BigDecimal refundAmount;

    /** Megjegyzés */
    private String notes;

    /** Lejárt-e */
    private Boolean expired;
}
