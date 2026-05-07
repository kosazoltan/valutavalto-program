package hu.puzzleir.valuta.dto.user;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class CreateUserRequest {

    @NotBlank(message = "A felhasználónév megadása kötelező")
    @Size(min = 2, max = 10, message = "A felhasználónév 2-10 karakter között legyen")
    private String username;

    @NotBlank(message = "A teljes név megadása kötelező")
    @Size(max = 100, message = "A név maximum 100 karakter lehet")
    private String fullName;

    @Email(message = "Érvénytelen email cím")
    @Size(max = 100, message = "Az email maximum 100 karakter lehet")
    private String email;

    @NotBlank(message = "A jelszó megadása kötelező")
    @Size(min = 8, max = 128, message = "A jelszó 8-128 karakter között legyen")
    private String password;

    /** WorkerRole enum name: CASHIER, SUPERVISOR, MANAGER, ADMIN */
    private String roleId;

    /** Branch UUID */
    private String branchId;
}
