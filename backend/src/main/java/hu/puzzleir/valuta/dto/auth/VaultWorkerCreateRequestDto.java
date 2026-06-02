package hu.puzzleir.valuta.dto.auth;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * FK-ÉRTÉKTÁR (V285, 2026-06-02): új értéktári (személyes) dolgozó felvételének request DTO-ja.
 *
 * <p>Szándékosan MINIMÁLIS: NINCS companyId / branchId / role mező — azokat a backend a
 * SecurityContextből (a bejelentkezett értéktáros company + branch) határozza meg, hogy a kliens
 * ne tudjon tetszőleges céget/irodát/szerepkört választani (audit P1).</p>
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class VaultWorkerCreateRequestDto {

    @NotBlank(message = "A név megadása kötelező")
    @Size(max = 100, message = "A név legfeljebb 100 karakter lehet")
    private String name;

    @NotBlank(message = "A jelszó megadása kötelező")
    @Size(min = 6, max = 100, message = "A jelszó legalább 6 karakter legyen")
    private String password;

    @NotBlank(message = "A jelszó megerősítése kötelező")
    private String passwordConfirm;
}
