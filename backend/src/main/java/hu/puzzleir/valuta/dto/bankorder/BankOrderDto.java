package hu.puzzleir.valuta.dto.bankorder;

import com.fasterxml.jackson.annotation.JsonInclude;
import hu.puzzleir.valuta.entity.BankOrder;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class BankOrderDto {
    private UUID id;
    private UUID branchId;
    private String branchCode;
    private String branchName;
    private Long currencyId;
    private String currencyCode;
    private BigDecimal amount;
    private BankOrder.Status status;
    private BankOrder.Urgency urgency;
    private Long requestedByWorkerId;
    private String requestedByWorkerName;
    private LocalDateTime requestedAt;
    private Long approvedByWorkerId;
    private String approvedByWorkerName;
    private LocalDateTime approvedAt;
    private Long executedByWorkerId;
    private String executedByWorkerName;
    private LocalDateTime executedAt;
    private Long cancelledByWorkerId;
    private LocalDateTime cancelledAt;
    private String cancellationReason;
    private String bankReference;
    private String notes;

    public static BankOrderDto from(BankOrder o) {
        if (o == null) return null;
        return BankOrderDto.builder()
                .id(o.getId())
                .branchId(o.getBranch() != null ? o.getBranch().getId() : null)
                .branchCode(o.getBranch() != null ? o.getBranch().getCode() : null)
                .branchName(o.getBranch() != null ? o.getBranch().getName() : null)
                .currencyId(o.getCurrency() != null ? o.getCurrency().getId() : null)
                .currencyCode(o.getCurrency() != null ? o.getCurrency().getCode() : null)
                .amount(o.getAmount())
                .status(o.getStatus())
                .urgency(o.getUrgency())
                .requestedByWorkerId(o.getRequestedBy() != null ? o.getRequestedBy().getId() : null)
                .requestedByWorkerName(o.getRequestedBy() != null ? o.getRequestedBy().getName() : null)
                .requestedAt(o.getRequestedAt())
                .approvedByWorkerId(o.getApprovedBy() != null ? o.getApprovedBy().getId() : null)
                .approvedByWorkerName(o.getApprovedBy() != null ? o.getApprovedBy().getName() : null)
                .approvedAt(o.getApprovedAt())
                .executedByWorkerId(o.getExecutedBy() != null ? o.getExecutedBy().getId() : null)
                .executedByWorkerName(o.getExecutedBy() != null ? o.getExecutedBy().getName() : null)
                .executedAt(o.getExecutedAt())
                .cancelledByWorkerId(o.getCancelledBy() != null ? o.getCancelledBy().getId() : null)
                .cancelledAt(o.getCancelledAt())
                .cancellationReason(o.getCancellationReason())
                .bankReference(o.getBankReference())
                .notes(o.getNotes())
                .build();
    }
}
