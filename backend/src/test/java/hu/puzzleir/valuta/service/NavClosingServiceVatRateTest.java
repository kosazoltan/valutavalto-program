package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.NavClosingRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.service.NavClosingService.NavTaxCode;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

/**
 * {@link NavClosingService#resolveVatRate(NavTaxCode)} egységtesztek (CB-016).
 *
 * Célok:
 *   - DB override érvényesül (happy path)
 *   - Fallback a beépített táblára, ha a paraméter hiányzik
 *   - Fallback hibás formátum (pl. "nem szám") esetén
 *   - Fallback üres/whitespace érték esetén
 *   - Fallback negatív érték esetén
 *   - Minden enum kulcsra létezik default (ZERO = 0)
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("NavClosingService.resolveVatRate — tax_code alapú ÁFA lookup")
class NavClosingServiceVatRateTest {

    @InjectMocks
    private NavClosingService service;

    @Mock private NavClosingRepository navClosingRepository;
    @Mock private TransactionRepository transactionRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private NavIntegrationService navIntegrationService;
    @Mock private SystemParameterService systemParameterService;

    @Test
    @DisplayName("STANDARD kulcs DB override-ja érvényesül (0.27 -> 0.25)")
    void standardOverrideApplies() {
        when(systemParameterService.getValue("nav.vat-rate.STANDARD")).thenReturn("0.25");

        BigDecimal rate = service.resolveVatRate(NavTaxCode.STANDARD);

        assertThat(rate).isEqualByComparingTo("0.25");
    }

    @Test
    @DisplayName("Paraméter hiányzik -> fallback a beépített 0.27 STANDARD-re")
    void missingParameterFallsBackToDefault() {
        when(systemParameterService.getValue("nav.vat-rate.STANDARD"))
            .thenThrow(new ResourceNotFoundException("Paraméter nem található: nav.vat-rate.STANDARD"));

        BigDecimal rate = service.resolveVatRate(NavTaxCode.STANDARD);

        assertThat(rate).isEqualByComparingTo("0.27");
    }

    @Test
    @DisplayName("Hibás decimális formátum -> fallback default")
    void invalidDecimalFallsBack() {
        when(systemParameterService.getValue("nav.vat-rate.REDUCED_18")).thenReturn("nem-szam");

        BigDecimal rate = service.resolveVatRate(NavTaxCode.REDUCED_18);

        assertThat(rate).isEqualByComparingTo("0.18");
    }

    @Test
    @DisplayName("Üres/whitespace érték -> fallback default")
    void blankValueFallsBack() {
        when(systemParameterService.getValue("nav.vat-rate.REDUCED_5")).thenReturn("   ");

        BigDecimal rate = service.resolveVatRate(NavTaxCode.REDUCED_5);

        assertThat(rate).isEqualByComparingTo("0.05");
    }

    @Test
    @DisplayName("Negatív érték -> fallback default (nem engedjük a negatív ÁFA-t)")
    void negativeValueFallsBack() {
        when(systemParameterService.getValue("nav.vat-rate.STANDARD")).thenReturn("-0.1");

        BigDecimal rate = service.resolveVatRate(NavTaxCode.STANDARD);

        assertThat(rate).isEqualByComparingTo("0.27");
    }

    @Test
    @DisplayName("ZERO kulcs default fallback 0.00")
    void zeroDefault() {
        when(systemParameterService.getValue("nav.vat-rate.ZERO"))
            .thenThrow(new ResourceNotFoundException("Paraméter nem található: nav.vat-rate.ZERO"));

        BigDecimal rate = service.resolveVatRate(NavTaxCode.ZERO);

        assertThat(rate).isEqualByComparingTo("0.00");
    }

    @Test
    @DisplayName("Minden enum kulcsra van alapérték (nincs ZERO fallback NullPointerException)")
    void allEnumKeysHaveDefault() {
        when(systemParameterService.getValue(org.mockito.ArgumentMatchers.anyString()))
            .thenThrow(new ResourceNotFoundException("not found"));

        for (NavTaxCode code : NavTaxCode.values()) {
            BigDecimal rate = service.resolveVatRate(code);
            assertThat(rate)
                .as("Default fallback for %s must be non-null and non-negative", code)
                .isNotNull()
                .isGreaterThanOrEqualTo(BigDecimal.ZERO);
        }
    }
}
