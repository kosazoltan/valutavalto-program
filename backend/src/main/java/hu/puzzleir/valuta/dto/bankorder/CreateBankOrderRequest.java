package hu.puzzleir.valuta.dto.bankorder;

import hu.puzzleir.valuta.entity.BankOrder;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.UUID;

@Getter
@Setter
public class CreateBankOrderRequest {

    @NotNull(message = "branchId kötelező")
    private UUID branchId;

    @NotNull(message = "currencyId kötelező")
    private Long currencyId;

    @NotNull(message = "amount kötelező")
    @DecimalMin(value = "0.01", message = "amount > 0")
    private BigDecimal amount;

    private BankOrder.Urgency urgency;

    private String notes;
}
