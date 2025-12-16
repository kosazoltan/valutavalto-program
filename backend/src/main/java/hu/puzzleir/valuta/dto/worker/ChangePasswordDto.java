package hu.puzzleir.valuta.dto.worker;

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
    @Size(min = 4, message = "Új jelszó minimum 4 karakter")
    private String newPassword;
}
