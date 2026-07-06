package hu.puzzleir.valuta.mapper;

import hu.puzzleir.valuta.dto.denomination.DenominationDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.entity.DenominationType;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class DenominationMapperTest {

    private final DenominationMapper mapper = new DenominationMapper();

    @Test
    @DisplayName("null entity → null DTO")
    void mapsNullEntity() {
        assertThat(mapper.toDto(null)).isNull();
    }

    @Test
    @DisplayName("Címlet pénzügyi és készletmezők átkerülnek a DTO-ba")
    void mapsFinancialStockFieldsAndReferences() {
        UUID branchId = UUID.fromString("22222222-3333-4444-5555-666666666666");
        Denomination entity = Denomination.builder()
                .id(7L)
                .branch(Branch.builder().id(branchId).name("Pécs").build())
                .currency(Currency.builder().id(4L).code("HUF").name("Forint").build())
                .faceValue(new BigDecimal("10000.00"))
                .denominationType(DenominationType.BANKNOTE)
                .quantity(12)
                .minQuantity(5)
                .maxQuantity(50)
                .active(true)
                .build();

        DenominationDto dto = mapper.toDto(entity);

        assertThat(dto.getId()).isEqualTo(7L);
        assertThat(dto.getBranchId()).isEqualTo(branchId.toString());
        assertThat(dto.getBranchName()).isEqualTo("Pécs");
        assertThat(dto.getCurrencyId()).isEqualTo(4L);
        assertThat(dto.getCurrencyCode()).isEqualTo("HUF");
        assertThat(dto.getCurrencyName()).isEqualTo("Forint");
        assertThat(dto.getFaceValue()).isEqualByComparingTo("10000.00");
        assertThat(dto.getDenominationType()).isEqualTo(DenominationType.BANKNOTE);
        assertThat(dto.getQuantity()).isEqualTo(12);
        assertThat(dto.getTotalValue()).isEqualByComparingTo("120000.00");
        assertThat(dto.getMinQuantity()).isEqualTo(5);
        assertThat(dto.getMaxQuantity()).isEqualTo(50);
        assertThat(dto.isLowStock()).isFalse();
        assertThat(dto.getActive()).isTrue();
    }

    @Test
    @DisplayName("Készlet minimum-határon lowStock true")
    void mapsLowStockBoundaryFromEntityHelper() {
        Denomination entity = Denomination.builder()
                .faceValue(new BigDecimal("5000"))
                .quantity(5)
                .minQuantity(5)
                .build();

        DenominationDto dto = mapper.toDto(entity);

        assertThat(dto.isLowStock()).isTrue();
        assertThat(dto.getTotalValue()).isEqualByComparingTo("25000");
    }

    @Test
    @DisplayName("Hiányzó branch/currency → null referencia mezők NPE nélkül")
    void mapsNullReferencesSafely() {
        Denomination entity = Denomination.builder()
                .branch(null)
                .currency(null)
                .faceValue(new BigDecimal("100"))
                .quantity(2)
                .minQuantity(null)
                .build();

        DenominationDto dto = mapper.toDto(entity);

        assertThat(dto.getBranchId()).isNull();
        assertThat(dto.getBranchName()).isNull();
        assertThat(dto.getCurrencyId()).isNull();
        assertThat(dto.getCurrencyCode()).isNull();
        assertThat(dto.getCurrencyName()).isNull();
        assertThat(dto.isLowStock()).isFalse();
    }
}
