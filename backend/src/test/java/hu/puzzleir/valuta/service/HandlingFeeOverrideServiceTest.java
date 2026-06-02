package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.ApprovalLevel;
import hu.puzzleir.valuta.entity.HandlingFeeOverrideReason;
import hu.puzzleir.valuta.entity.HandlingFeeOverrideType;
import hu.puzzleir.valuta.exception.ValidationException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

/**
 * FK-KEZDÍJ (2026-06-02): a kezelési díj override engedély-mátrix szerver-oldali validálása.
 */
class HandlingFeeOverrideServiceTest {

    private DiscountApprovalService discountApprovalService;
    private HandlingFeeOverrideService service;

    private static final BigDecimal BASE = new BigDecimal("1000");

    @BeforeEach
    void setUp() {
        discountApprovalService = Mockito.mock(DiscountApprovalService.class);
        service = new HandlingFeeOverrideService(discountApprovalService);
        when(discountApprovalService.mapRoleToLevel("penztar")).thenReturn(ApprovalLevel.CASHIER);
        when(discountApprovalService.mapRoleToLevel("ugyvezeto")).thenReturn(ApprovalLevel.DIRECTOR);
        when(discountApprovalService.mapRoleToLevel("foertektar")).thenReturn(ApprovalLevel.DIRECTOR);
    }

    @Test
    @DisplayName("NONE → az alap díj változatlanul")
    void none_returnsBase() {
        assertThat(service.resolveOverride(BASE, HandlingFeeOverrideType.NONE, null, null, null, "penztar"))
                .isEqualByComparingTo("1000");
    }

    @Test
    @DisplayName("HALF + PROMOTION (pénztáros) → a díj fele, 5 Ft-ra kerekítve")
    void half_promotion_cashier_ok() {
        assertThat(service.resolveOverride(BASE, HandlingFeeOverrideType.HALF,
                HandlingFeeOverrideReason.PROMOTION, null, null, "penztar"))
                .isEqualByComparingTo("500");
    }

    @Test
    @DisplayName("WAIVED + PROMOTION (pénztáros) → 0 Ft")
    void waived_promotion_cashier_ok() {
        assertThat(service.resolveOverride(BASE, HandlingFeeOverrideType.WAIVED,
                HandlingFeeOverrideReason.PROMOTION, null, null, "penztar"))
                .isEqualByComparingTo("0");
    }

    @Test
    @DisplayName("HALF + CUSTOMER_CARD kártyaszám NÉLKÜL → ValidationException")
    void half_customerCard_noCardNumber_throws() {
        assertThatThrownBy(() -> service.resolveOverride(BASE, HandlingFeeOverrideType.HALF,
                HandlingFeeOverrideReason.CUSTOMER_CARD, null, null, "penztar"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("kártyaszám");
    }

    @Test
    @DisplayName("HALF + CUSTOMER_CARD kártyaszámmal (pénztáros) → a díj fele")
    void half_customerCard_withCardNumber_ok() {
        assertThat(service.resolveOverride(BASE, HandlingFeeOverrideType.HALF,
                HandlingFeeOverrideReason.CUSTOMER_CARD, "1234-5678", null, "penztar"))
                .isEqualByComparingTo("500");
    }

    @Test
    @DisplayName("HALF + DIRECTOR_APPROVAL pénztárosként → ValidationException (vezetői jóváhagyás kell)")
    void half_directorApproval_cashier_throws() {
        assertThatThrownBy(() -> service.resolveOverride(BASE, HandlingFeeOverrideType.HALF,
                HandlingFeeOverrideReason.DIRECTOR_APPROVAL, null, null, "penztar"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("jóváhagyás");
    }

    @Test
    @DisplayName("SPECIAL + DIRECTOR_APPROVAL (ügyvezető) → a kért egyedi díj (5 Ft-ra kerekítve)")
    void special_director_ok() {
        assertThat(service.resolveOverride(BASE, HandlingFeeOverrideType.SPECIAL,
                HandlingFeeOverrideReason.DIRECTOR_APPROVAL, null, new BigDecimal("333"), "ugyvezeto"))
                .isEqualByComparingTo("335");
    }

    @Test
    @DisplayName("SPECIAL pénztárosként → ValidationException")
    void special_cashier_throws() {
        assertThatThrownBy(() -> service.resolveOverride(BASE, HandlingFeeOverrideType.SPECIAL,
                HandlingFeeOverrideReason.PROMOTION, null, new BigDecimal("100"), "penztar"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Speciális");
    }

    @Test
    @DisplayName("override típus megadva, de jogcím null → ValidationException")
    void type_withoutReason_throws() {
        assertThatThrownBy(() -> service.resolveOverride(BASE, HandlingFeeOverrideType.WAIVED,
                null, null, null, "penztar"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("jogcím");
    }

    @Test
    @DisplayName("WAIVED + DIRECTOR_APPROVAL (ügyvezető) → 0 Ft")
    void waived_director_ok() {
        assertThat(service.resolveOverride(BASE, HandlingFeeOverrideType.WAIVED,
                HandlingFeeOverrideReason.DIRECTOR_APPROVAL, null, null, "ugyvezeto"))
                .isEqualByComparingTo("0");
    }
}
