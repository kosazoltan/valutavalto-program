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
    @Size(min = 8, max = 128, message = "Új jelszó 8-128 karakter között legyen")
    private String newPassword;
}
