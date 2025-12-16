package hu.puzzleir.valuta.dto.auth;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Login request DTO.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class LoginRequestDto {
    
    @NotBlank(message = "Company kód kötelező")
    private String companyCode;
    
    @NotBlank(message = "Pénztáros kód kötelező")
    private String workerCode;
    
    @NotBlank(message = "Jelszó kötelező")
    private String password;
    
    private UUID branchId; // Opcionális - ha több iroda közül választ
}
