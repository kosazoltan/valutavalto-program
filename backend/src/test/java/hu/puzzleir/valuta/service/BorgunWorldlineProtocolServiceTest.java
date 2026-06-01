package hu.puzzleir.valuta.service;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * F1 (2026-06-01): a Borgun/Worldline éles driverek VÁZ-állapotúak — minden műveletre
 * UnsupportedOperationException-t dobnak (NEM fake jóváhagyás), amíg a vendor protokoll-spec
 * meg nem érkezik. Ez a teszt rögzíti a kontraktust: a stub SOHA nem ad csendben jóváhagyást.
 */
class BorgunWorldlineProtocolServiceTest {

    private final BorgunProtocolService borgun = new BorgunProtocolService();
    private final WorldlineProtocolService worldline = new WorldlineProtocolService();

    @Test
    @DisplayName("Borgun: minden művelet UnsupportedOperationException-t dob (nincs fake approve)")
    void borgun_allOperationsThrow() {
        assertThatThrownBy(() -> borgun.executePayment(new BigDecimal("1000"), "HUF", "T1"))
                .isInstanceOf(UnsupportedOperationException.class)
                .hasMessageContaining("nincs implementálva");
        assertThatThrownBy(() -> borgun.executeReversal("REF1", "T1"))
                .isInstanceOf(UnsupportedOperationException.class);
        assertThatThrownBy(() -> borgun.executeDailyClose("T1"))
                .isInstanceOf(UnsupportedOperationException.class);
    }

    @Test
    @DisplayName("Worldline: minden művelet UnsupportedOperationException-t dob (nincs fake approve)")
    void worldline_allOperationsThrow() {
        assertThatThrownBy(() -> worldline.executePayment(new BigDecimal("1000"), "HUF", "T2"))
                .isInstanceOf(UnsupportedOperationException.class)
                .hasMessageContaining("nincs implementálva");
        assertThatThrownBy(() -> worldline.executeReversal("REF2", "T2"))
                .isInstanceOf(UnsupportedOperationException.class);
        assertThatThrownBy(() -> worldline.executeDailyClose("T2"))
                .isInstanceOf(UnsupportedOperationException.class);
    }
}
