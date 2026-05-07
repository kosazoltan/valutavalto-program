package hu.puzzleir.valuta.dto.worker;

import hu.puzzleir.valuta.validation.PasswordPolicy;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Jelszóváltoztatás DTO.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ChangePasswordDto {
    
    @NotBlank(message = "Régi jelszó kötelező")
    private String oldPassword;
    
    @NotBlank(message = "Új jelszó kötelező")
    @Size(min = PasswordPolicy.MIN_LENGTH, max = PasswordPolicy.MAX_LENGTH, message = PasswordPolicy.LENGTH_MESSAGE)
    private String newPassword;
}
