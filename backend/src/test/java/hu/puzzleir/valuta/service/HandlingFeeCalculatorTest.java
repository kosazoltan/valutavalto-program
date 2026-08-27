package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.HandlingFeeBracketRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * HandlingFeeCalculator UNIT tesztek — P0 Sprint 1
 *
 * Tesztelt változások:
 * 1. CONVERSION típusnál kezelési díj = 0 (GAP-P0-001)
 * 2. SHK napi limit 5 → ValidationException a 6. kísérletnél (GAP-P0-003)
 * 3. BUY/SELL típusnál kalkulált kezelési díj (regresszió)
 */
@ExtendWith(MockitoExtension.class)
class HandlingFeeCalculatorTest {

    @Mock
    private HandlingFeeService handlingFeeService;

    @Mock
    private TransactionRepository transactionRepository;

    @InjectMocks
    private HandlingFeeCalculator calculator;

    /** FK-096: a kalkulator mostantol explicit branchId-t kap (DIP) — a tesztek fix id-val hivjak. */
    private static final UUID BRANCH_ID = UUID.randomUUID();

    // =========================================================
    // TC-01: CONVERSION típusnál kezelési díj = 0
    // =========================================================

    @Nested
    @DisplayName("TC-01 — CONVERSION típusnál handlingFee = 0")
    class ConversionFeeZeroTests {

        @Test
        @DisplayName("CONVERSION: 100.000 Ft összegnél handlingFee = 0")
        void conversionFeeIsZero_normalAmount() {
            BigDecimal fee = calculator.calculate(
                    new BigDecimal("100000"),
                    TransactionType.CONVERSION,
                    null,
                    BRANCH_ID
            );
            assertThat(fee).isEqualByComparingTo(BigDecimal.ZERO);
            // CONVERSION ágban handlingFeeService.calculateHandlingFee() soha nem hívódik
            verifyNoInteractions(handlingFeeService);
        }

        @Test
        @DisplayName("CONVERSION: 1.000.000 Ft összeget is 0 díjjal kezel")
        void conversionFeeIsZero_largeAmount() {
            BigDecimal fee = calculator.calculate(
                    new BigDecimal("1000000"),
                    TransactionType.CONVERSION,
                    null,
                    BRANCH_ID
            );
            assertThat(fee).isEqualByComparingTo(BigDecimal.ZERO);
            verifyNoInteractions(handlingFeeService);
        }

        @Test
        @DisplayName("CONVERSION: kliens által küldött díj sem érvényesül")
        void conversionFeeIsZero_evenIfClientSendsNonZero() {
            BigDecimal fee = calculator.calculate(
                    new BigDecimal("500000"),
                    TransactionType.CONVERSION,
                    new BigDecimal("500"), // kliens ezt küldte, de ignorálni kell
                    BRANCH_ID
            );
            assertThat(fee)
                    .as("CONVERSION esetén a kliens díj sem érvényesülhet")
                    .isEqualByComparingTo(BigDecimal.ZERO);
            verifyNoInteractions(handlingFeeService);
        }
    }

    // =========================================================
    // TC-02: BUY/SELL típusnál kalkulált díj (regresszió)
    // =========================================================

    @Nested
    @DisplayName("TC-02 — BUY/SELL típusnál kalkulált díj (regresszió)")
    class BuySellFeeCalculatedTests {

        @BeforeEach
        void setup() {
            // Szerver oldali díjszámítás visszaad valós értéket
            when(handlingFeeService.calculateHandlingFee(any(), any()))
                    .thenReturn(new BigDecimal("500"));
        }

        @Test
        @DisplayName("BUY: 100.000 Ft összegnél kezelési díj = 500 Ft (nem 0!)")
        void buyFeeIsCalculated() {
            BigDecimal fee = calculator.calculate(
                    new BigDecimal("100000"),
                    TransactionType.BUY,
                    null,
                    BRANCH_ID
            );
            assertThat(fee)
                    .as("BUY tranzakciónál kezelési díj NEM lehet 0")
                    .isGreaterThan(BigDecimal.ZERO)
                    .isEqualByComparingTo("500");
            verify(handlingFeeService).calculateHandlingFee(new BigDecimal("100000"), BRANCH_ID);
        }

        @Test
        @DisplayName("SELL: 200.000 Ft összegnél kezelési díj = 500 Ft (nem 0!)")
        void sellFeeIsCalculated() {
            BigDecimal fee = calculator.calculate(
                    new BigDecimal("200000"),
                    TransactionType.SELL,
                    null,
                    BRANCH_ID
            );
            assertThat(fee)
                    .as("SELL tranzakciónál kezelési díj NEM lehet 0")
                    .isGreaterThan(BigDecimal.ZERO)
                    .isEqualByComparingTo("500");
            verify(handlingFeeService).calculateHandlingFee(new BigDecimal("200000"), BRANCH_ID);
        }
    }

    // =========================================================
    // TC-03: SHK napi limit = 5, 6. kísérletkor ValidationException
    // =========================================================

    @Nested
    @DisplayName("TC-03 — SHK napi limit 5 → ValidationException a 6. kísérletnél")
    class SHKLimitTests {

        @Test
        @DisplayName("SHK kvóta megvan (remaining=3): validateCustomFee nem dob kivételt")
        void customFeeAllowed_whenQuotaAvailable() {
            when(handlingFeeService.getRemainingCustomFeeQuota()).thenReturn(3);

            // Ne dobjon kivételt
            calculator.validateCustomFee(new BigDecimal("1000"));

            verify(handlingFeeService).getRemainingCustomFeeQuota();
        }

        @Test
        @DisplayName("SHK kvóta megvan (remaining=1): az utolsó engedélyezett díjnál sem dob kivételt")
        void customFeeAllowed_whenLastQuota() {
            when(handlingFeeService.getRemainingCustomFeeQuota()).thenReturn(1);

            calculator.validateCustomFee(new BigDecimal("2000"));
            // Sikeres — nincs kivétel
        }

        @Test
        @DisplayName("SHK kvóta elfogyott (remaining=0): 6. kísérletkor ValidationException")
        void customFeeDenied_whenLimitReached() {
            when(handlingFeeService.getRemainingCustomFeeQuota()).thenReturn(0);

            assertThatThrownBy(() -> calculator.validateCustomFee(new BigDecimal("3000")))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("5") // limit=5 szerepel az üzenetben
                    .hasMessageContaining("limit");
        }

        @Test
        @DisplayName("SHK limit üzenet tartalmazza a 'Napi egyedi kezelési díj limit' szöveget")
        void customFeeException_containsCorrectMessage() {
            when(handlingFeeService.getRemainingCustomFeeQuota()).thenReturn(0);

            assertThatThrownBy(() -> calculator.validateCustomFee(new BigDecimal("500")))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("Napi egyedi kezelési díj limit")
                    .hasMessageContaining("5");
        }

        @Test
        @DisplayName("NULL egyedi díj: validateCustomFee mindig átenged (nincs kvóta-használat)")
        void customFeeNull_noQuotaConsumed() {
            calculator.validateCustomFee(null);
            verifyNoInteractions(handlingFeeService);
        }

        @Test
        @DisplayName("0 egyedi díj: validateCustomFee átenged, nem számol kvótába")
        void customFeeZero_noQuotaConsumed() {
            calculator.validateCustomFee(BigDecimal.ZERO);
            verifyNoInteractions(handlingFeeService);
        }

        @Test
        @DisplayName("DAILY_CUSTOM_FEE_LIMIT konstans értéke 5 (V100 migráció után)")
        void dailyCustomFeeLimitConstantIs5() {
            // A konstans értékét a validálás hibaüzenetéből ellenőrizzük
            when(handlingFeeService.getRemainingCustomFeeQuota()).thenReturn(0);

            assertThatThrownBy(() -> calculator.validateCustomFee(new BigDecimal("100")))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("5"); // "limit (5) elérve"
        }
    }

    // =========================================================
    // TC-04: Edge case-ek (null, negatív összeg)
    // =========================================================

    @Nested
    @DisplayName("TC-04 — Edge case-ek")
    class EdgeCaseTests {

        @Test
        @DisplayName("NULL hufAmount → 0 Ft (minden típusnál)")
        void nullAmount_returnsZero() {
            BigDecimal fee = calculator.calculate(null, TransactionType.BUY, null, BRANCH_ID);
            assertThat(fee).isEqualByComparingTo(BigDecimal.ZERO);
            verifyNoInteractions(handlingFeeService);
        }

        @Test
        @DisplayName("Negatív hufAmount → 0 Ft")
        void negativeAmount_returnsZero() {
            BigDecimal fee = calculator.calculate(
                    new BigDecimal("-50000"),
                    TransactionType.SELL,
                    null,
                    BRANCH_ID
            );
            assertThat(fee).isEqualByComparingTo(BigDecimal.ZERO);
            verifyNoInteractions(handlingFeeService);
        }

        @Test
        @DisplayName("0 Ft hufAmount → 0 Ft")
        void zeroAmount_returnsZero() {
            BigDecimal fee = calculator.calculate(
                    BigDecimal.ZERO,
                    TransactionType.BUY,
                    null,
                    BRANCH_ID
            );
            assertThat(fee).isEqualByComparingTo(BigDecimal.ZERO);
            verifyNoInteractions(handlingFeeService);
        }

        @Test
        @DisplayName("calculateSellGross: nettó + díj = bruttó")
        void sellGross_isNetPlusFee() {
            BigDecimal gross = calculator.calculateSellGross(
                    new BigDecimal("100000"),
                    new BigDecimal("500")
            );
            assertThat(gross).isEqualByComparingTo("100500");
        }

        @Test
        @DisplayName("calculateBuyGross: nettó - díj = bruttó")
        void buyGross_isNetMinusFee() {
            BigDecimal gross = calculator.calculateBuyGross(
                    new BigDecimal("100000"),
                    new BigDecimal("500")
            );
            assertThat(gross).isEqualByComparingTo("99500");
        }
    }
}
