package hu.puzzleir.valuta.dto.mnbsettlement;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MnbSettlementRateUpdateRequest {

    /** Üres lista megengedett (publish módosítás nélkül — FR-10). */
    @NotNull
    @Valid
    @Builder.Default
    private List<Item> items = new ArrayList<>();

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class Item {
        @NotBlank
        @Size(min = 3, max = 3)
        private String currencyCode;

        @NotNull
        @Positive
        @Digits(integer = 11, fraction = 4)
        private BigDecimal officialRate;
    }
}
