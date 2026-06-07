package hu.puzzleir.valuta.dto.transfer;

import com.fasterxml.jackson.annotation.JsonInclude;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.*;

import java.math.BigDecimal;

/**
 * Értéktári átadás-átvétel bizonylat egy címletezési sora (darab × névleges érték).
 * Opcionális; ha legalább egy sor van, az összegük a service-ben validáltan egyezik az átadás összegével.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class TransferDenominationDto {

    @NotNull(message = "A címlet darabszáma kötelező")
    @Positive(message = "A címlet darabszáma pozitív kell legyen")
    private Integer quantity;

    @NotNull(message = "A címlet névleges értéke kötelező")
    @Positive(message = "A címlet névleges értéke pozitív kell legyen")
    private BigDecimal faceValue;

    /** Válasz-oldali mezők (a create-nél a service tölti; a kérésben opcionális). */
    private String currencyCode;
    private BigDecimal lineTotal;
}
