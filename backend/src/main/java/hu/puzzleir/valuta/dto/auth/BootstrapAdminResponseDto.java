package hu.puzzleir.valuta.dto.auth;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * First-run setup bootstrap response.
 *
 * <p>A wizard a {@code success=true} esetén folytatja a relaunch-ot,
 * egyébként megjeleníti a {@code message}-et a felhasználónak.</p>
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BootstrapAdminResponseDto {

    /** Sikeres admin létrehozás / frissítés */
    private boolean success;

    /** Emberi üzenet a wizardnak (magyarul) */
    private String message;

    /** A létrehozott vagy frissített worker azonosítója (ha success=true) */
    private Long workerId;

    /** Cégkód visszatükrözve (audit célból) */
    private String companyCode;

    /** Worker kód visszatükrözve (audit célból) */
    private String workerCode;
}
