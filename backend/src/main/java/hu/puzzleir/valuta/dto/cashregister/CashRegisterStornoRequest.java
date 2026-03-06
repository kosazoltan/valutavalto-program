package hu.puzzleir.valuta.dto.cashregister;

import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.util.UUID;

/**
 * Sztornó bizonylat kérés.
 */
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class CashRegisterStornoRequest {

    @NotNull
    private UUID branchId;

    @NotNull
    private UUID originalReceiptId;
}
