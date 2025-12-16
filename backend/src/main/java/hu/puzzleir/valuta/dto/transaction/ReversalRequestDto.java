package hu.puzzleir.valuta.dto.transaction;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Sztornó request DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReversalRequestDto {

    @NotNull(message = "Eredeti tranzakció azonosító kötelező")
    private Long originalTransactionId;

    @NotBlank(message = "Sztornó indok kötelező")
    private String reason;

    // Supervisor által jóváhagyott (napi 3+ sztornó esetén)
    private String approvedBy;
}
