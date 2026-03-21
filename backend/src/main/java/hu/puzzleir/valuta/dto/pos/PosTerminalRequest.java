package hu.puzzleir.valuta.dto.pos;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record PosTerminalRequest(
        @NotBlank(message = "A terminalId kötelező")
        @Pattern(regexp = "^[A-Za-z0-9._-]{1,64}$", message = "A terminalId formátuma érvénytelen")
        String terminalId
) {
}
