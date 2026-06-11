package hu.puzzleir.valuta.dto;

import jakarta.validation.constraints.Size;

/**
 * EXCMD b6-beallitasok FR-14 — gépenként izolált konfiguráció PUT kérés DTO.
 *
 * <p>A raw {@code Map<String,Object>} helyett típusos DTO (Sourcery finding).
 * A {@code configJson} a teljes PenztarSettings JSON string-je.
 * A {@code dailyReportPassword} opcionális — null/üres esetén a meglévő jelszó-hash változatlan.</p>
 */
public record MachineConfigUpdateRequest(
        /** A teljes settings payload JSON string-ként (PenztarSettings serialized). */
        @Size(max = 32_768, message = "A config JSON mérete nem haladhatja meg a 32 KB-ot")
        String configJson,

        /**
         * Napi-jelentés jelszó plain-text-ben (opcionális).
         * Null/üres = meglévő jelszó-hash változatlan. A service BCrypt-tel hash-eli.
         * Maximális hossz: a BCrypt 72 bájtnál hosszabb inputot levág — itt 128-cal korlátozzuk.
         */
        @Size(max = 128, message = "A jelszó legfeljebb 128 karakter lehet")
        String dailyReportPassword
) {
}
