package hu.puzzleir.valuta.mapper;

import hu.puzzleir.valuta.dto.cashbalance.CashBalanceDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Currency;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class CashBalanceMapperTest {

    private final CashBalanceMapper mapper = new CashBalanceMapper();

    @Test
    @DisplayName("null entity → null DTO")
    void mapsNullEntity() {
        assertThat(mapper.toDto(null)).isNull();
    }

    @Test
    @DisplayName("Pénzügyi mezők + branch/currency adatok átkerülnek a DTO-ba")
    void mapsFinancialFieldsAndReferences() {
        UUID branchId = UUID.fromString("11111111-2222-3333-4444-555555555555");
        CashBalance entity = CashBalance.builder()
                .id(1L)
                .branch(Branch.builder().id(branchId).name("Szeged Tisza Sarok").build())
                .currency(Currency.builder().id(2L).code("EUR").name("Euro").symbol("€").build())
                .currentBalance(new BigDecimal("100.00"))
                .openingBalance(new BigDecimal("80.00"))
                .minBalance(new BigDecimal("50.00"))
                .maxBalance(new BigDecimal("200.00"))
                .build();

        CashBalanceDto dto = mapper.toDto(entity);

        assertThat(dto.getId()).isEqualTo(1L);
        assertThat(dto.getBranchId()).isEqualTo(branchId.toString());
        assertThat(dto.getBranchName()).isEqualTo("Szeged Tisza Sarok");
        assertThat(dto.getCurrencyId()).isEqualTo(2L);
        assertThat(dto.getCurrencyCode()).isEqualTo("EUR");
        assertThat(dto.getCurrencyName()).isEqualTo("Euro");
        assertThat(dto.getCurrencySymbol()).isEqualTo("€");
        assertThat(dto.getCurrentBalance()).isEqualByComparingTo("100.00");
        assertThat(dto.getOpeningBalance()).isEqualByComparingTo("80.00");
        assertThat(dto.getDailyChange()).isEqualByComparingTo("20.00");
        assertThat(dto.getMinBalance()).isEqualByComparingTo("50.00");
        assertThat(dto.getMaxBalance()).isEqualByComparingTo("200.00");
        assertThat(dto.isLowBalanceAlert()).isFalse();
        assertThat(dto.isHighBalanceAlert()).isFalse();
    }

    @Test
    @DisplayName("Limit-határon a low/high balance alert inkluzív")
    void mapsInclusiveLowAndHighBalanceBoundaries() {
        CashBalance entity = CashBalance.builder()
                .currentBalance(new BigDecimal("50.00"))
                .openingBalance(new BigDecimal("50.00"))
                .minBalance(new BigDecimal("50.00"))
                .maxBalance(new BigDecimal("50.00"))
                .build();

        CashBalanceDto dto = mapper.toDto(entity);

        assertThat(dto.isLowBalanceAlert()).isTrue();
        assertThat(dto.isHighBalanceAlert()).isTrue();
    }

    @Test
    @DisplayName("Hiányzó limitek + branch/currency null → NPE nélkül null referenciák és false alert")
    void mapsNullLimitsAndReferencesSafely() {
        CashBalance entity = CashBalance.builder()
                .currentBalance(new BigDecimal("100.00"))
                .openingBalance(new BigDecimal("100.00"))
                .minBalance(null)
                .maxBalance(null)
                .branch(null)
                .currency(null)
                .build();

        CashBalanceDto dto = mapper.toDto(entity);

        assertThat(dto.getBranchId()).isNull();
        assertThat(dto.getBranchName()).isNull();
        assertThat(dto.getCurrencyId()).isNull();
        assertThat(dto.getCurrencyCode()).isNull();
        assertThat(dto.getCurrencyName()).isNull();
        assertThat(dto.getCurrencySymbol()).isNull();
        assertThat(dto.isLowBalanceAlert()).isFalse();
        assertThat(dto.isHighBalanceAlert()).isFalse();
    }
}
