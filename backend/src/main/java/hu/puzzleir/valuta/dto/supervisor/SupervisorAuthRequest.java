package hu.puzzleir.valuta.dto.supervisor;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SupervisorAuthRequest {
    @NotBlank(message = "Supervisor jelszó kötelező!")
    private String password;
}
