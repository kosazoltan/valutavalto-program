package hu.puzzleir.valuta.dto.cashregister;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CashRegisterCommandRequest {

    @NotNull
    private UUID branchId;

    @NotNull
    private CashRegisterCommandType commandType;

    @Valid
    private List<CashRegisterCurrencyCommandLine> currencies;
}
