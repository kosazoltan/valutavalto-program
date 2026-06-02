package hu.puzzleir.valuta.dto.auth;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * FK-ÉRTÉKTÁR (V285, 2026-06-02): a kétlépcsős értéktári belépés 2. fázisának request DTO-ja.
 *
 * <p>A kliens újraküldi a Google ID tokent (a 1. fázisból még birtokolja) — ez igazolja az
 * intézményi értéktár-fiók identitását. Plusz a kiválasztott személyes worker id-je és annak
 * SAJÁT jelszava. A backend a Google tokent újra-verifikálja, az intézményi branch alá tartozó
 * workereket ellenőrzi, és csak a helyes jelszó után ad végleges JWT-t a személyes workerrel.</p>
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class VaultWorkerSelectRequestDto {

    /** A Google ID token (1. fázisból) — az intézményi értéktár-fiók igazolása. */
    @NotBlank
    private String idToken;

    /** A kiválasztott személyes worker azonosítója. */
    @NotNull
    private Long workerId;

    /** A személyes worker saját jelszava. */
    @NotBlank
    private String password;

    @Size(max = 32, message = "Az appMode max 32 karakter lehet")
    private String appMode;
}
