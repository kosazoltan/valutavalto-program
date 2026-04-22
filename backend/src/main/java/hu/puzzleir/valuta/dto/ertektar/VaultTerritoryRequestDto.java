package hu.puzzleir.valuta.dto.ertektar;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.*;

import java.math.BigDecimal;

/**
 * Request DTO a vault_territory letrehozasahoz / frissitesehez.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VaultTerritoryRequestDto {

    @NotBlank(message = "A terulet neve kotelezo")
    @Size(min = 2, max = 100, message = "A terulet neve 2-100 karakter kozott kell legyen")
    private String name;

    @NotNull(message = "Az alapotoke kotelezo")
    @DecimalMin(value = "0.00", message = "Az alapotoke nem lehet negativ")
    private BigDecimal baseCapital;

    /**
     * Opcional: ha null, akkor a letrehozaskor nem johet letre tovabbi jovahagyas.
     */
    private java.time.LocalDate baseCapitalApprovedAt;
}