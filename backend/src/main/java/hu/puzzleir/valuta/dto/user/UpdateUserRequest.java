package hu.puzzleir.valuta.dto.user;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class UpdateUserRequest {

    @Email(message = "Érvénytelen email cím")
    @Size(max = 100, message = "Az email maximum 100 karakter lehet")
    private String email;

    @Size(max = 100, message = "A név maximum 100 karakter lehet")
    private String fullName;

    /** WorkerRole enum name: CASHIER, SUPERVISOR, MANAGER, ADMIN */
    private String roleId;

    /** Branch UUID */
    private String branchId;

    private Boolean active;
}
