package hu.puzzleir.valuta.mapper;

import hu.puzzleir.valuta.dto.reservation.ReservationDto;
import hu.puzzleir.valuta.entity.Reservation;
import org.springframework.stereotype.Component;

/**
 * Reservation entity → DTO mapper.
 */
@Component
public class ReservationMapper {

    /**
     * Reservation entity → ReservationDto
     */
    public ReservationDto toDto(Reservation r) {
        if (r == null) {
            return null;
        }

        ReservationDto.ReservationDtoBuilder builder = ReservationDto.builder()
                .id(r.getId())
                .currencyCode(r.getCurrencyCode())
                .reservedAmount(r.getReservedAmount())
                .exchangeRate(r.getExchangeRate())
                .depositAmount(r.getDepositAmount())
                .status(r.getStatus())
                .expiresAt(r.getExpiresAt())
                .createdAt(r.getCreatedAt())
                .fulfilledAt(r.getFulfilledAt())
                .cancelledAt(r.getCancelledAt())
                .receiptNumber(r.getReceiptNumber())
                .cancellationReceiptNumber(r.getCancellationReceiptNumber())
                .cancellationReason(r.getCancellationReason())
                .supervisorApproval(r.getSupervisorApproval())
                .refundAmount(r.getRefundAmount())
                .notes(r.getNotes())
                .expired(r.isExpired());

        // Ügyfél
        if (r.getCustomer() != null) {
            builder.customerId(r.getCustomer().getId());
            builder.customerName(r.getCustomer().getName());
        }

        // Branch
        if (r.getBranch() != null) {
            builder.branchId(r.getBranch().getId() != null ? r.getBranch().getId().toString() : null);
            builder.branchName(r.getBranch().getName());
        }

        // Worker
        if (r.getWorker() != null) {
            builder.workerId(r.getWorker().getId());
            builder.workerName(r.getWorker().getName());
        }

        // Supervisor
        if (r.getSupervisorWorker() != null) {
            builder.supervisorWorkerId(r.getSupervisorWorker().getId());
            builder.supervisorWorkerName(r.getSupervisorWorker().getName());
        }

        return builder.build();
    }
}
