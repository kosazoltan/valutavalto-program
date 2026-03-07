package hu.puzzleir.valuta.dto.employee;

import hu.puzzleir.valuta.entity.BankAccountType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Dolgozói bankszámla DTO.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EmployeeBankAccountDto {
    private Long id;
    private BankAccountType accountType;
    private String bankCode;
    private String accountNumber;
}
