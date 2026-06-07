package hu.puzzleir.valuta.dto.transfer;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import lombok.*;
import java.math.BigDecimal;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CreateTransferDto {
    @NotNull private String toBranchId;
    @NotNull private Long currencyId;
    @NotNull @Positive private BigDecimal amount;
    private BigDecimal hufValue;
    @NotNull private String transferType;
    /**
     * Több-valutás átadólap sorai (#6). Ha kitöltött (≥1 sor), az átadás multi-line:
     * a fenti currencyId/amount az ELSŐ sort tükrözi, a cash-balance soronként könyvel.
     * Üres/null esetén a hagyományos egy-valutás viselkedés.
     */
    @Valid
    private List<TransferLineDto> lines;
    /** Átadás iránya: F, U, UF, FF (default: UF) */
    @Pattern(regexp = "^(F|U|UF|FF)$", message = "Az irány csak F, U, UF vagy FF lehet!")
    private String direction;
    private String notes;

    /**
     * Opcionális címletezés (darab × névleges érték). Ha legalább egy sor van, az összegük
     * a service-ben validáltan egyezik az átadás összegével (FR-20b). Üres/null → nincs címletezés.
     */
    @Valid
    private List<TransferDenominationDto> denominations;

    /**
     * FR-1/FR-3 (átadás-átvétel): a fizikai szállítást végző személy/cég neve — KÖTELEZŐ minden
     * transfer-létrehozásnál (handover ÉS treasury-mozgás). Ékezet megengedett (magyar nevek), ezért
     * nincs ASCII-pattern, csak hossz-korlát.
     */
    @NotBlank(message = "A szállító neve kötelező")
    @Size(max = 128, message = "A szállító neve legfeljebb 128 karakter lehet")
    private String carrierName;

    /**
     * FR-2/FR-3 (átadás-átvétel): a szállítmány lezárásának egyedi plombaszáma — KÖTELEZŐ.
     * Csak alfanumerikus + kötőjel + perjel (NFR-2), max 64 karakter.
     */
    @NotBlank(message = "A plombaszám kötelező")
    @Size(max = 64, message = "A plombaszám legfeljebb 64 karakter lehet")
    @Pattern(regexp = "^[A-Za-z0-9\\-/]+$", message = "A plombaszám csak betűt, számot, kötőjelet és perjelet tartalmazhat")
    private String sealNumber;
}
