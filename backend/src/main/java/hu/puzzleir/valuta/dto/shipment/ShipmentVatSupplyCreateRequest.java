package hu.puzzleir.valuta.dto.shipment;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/**
 * FKH-040: ÁFA-célú HUF-ellátmány átadás-átvétel rögzítése (AS prefix).
 * Nincs díjszámítás — a rögzített HUF-összeg maga a tétel.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ShipmentVatSupplyCreateRequest {

    @NotNull(message = "Az átadó megadása kötelező")
    private UUID fromBranchId;

    @NotNull(message = "Az átvevő megadása kötelező")
    private UUID toBranchId;

    @NotNull(message = "Az ÁFA-ellátmány összege kötelező")
    @DecimalMin(value = "1", message = "Az ÁFA-ellátmány összege pozitív kell legyen")
    private BigDecimal hufAmount;

    private LocalDate deliveryDate;

    @Size(max = 2000)
    private String notes;

    @NotBlank(message = "A szállító neve kötelező")
    @Size(max = 128)
    private String carrierName;

    @NotBlank(message = "A plombaszám kötelező")
    @Size(max = 64)
    @Pattern(
            regexp = "^[A-Za-z0-9\\-/]+$",
            message = "A plombaszám csak betűt, számot, kötőjelet és perjelet tartalmazhat")
    private String sealNumber;
}
