package hu.puzzleir.valuta.dto.user;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class UpdateMyPasswordRequest {

    @NotBlank(message = "A régi jelszó megadása kötelező")
    private String oldPassword;

    @NotBlank(message = "Az új jelszó megadása kötelező")
    @Size(min = 8, max = 128, message = "A jelszó 8-128 karakter között legyen")
    private String newPassword;
}
