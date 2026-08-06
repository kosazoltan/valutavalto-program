package hu.puzzleir.valuta.service;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

/**
 * FK-073 FR-4 — a {@link ClosingTolerance#blocks(BigDecimal)} viselkedése 0-küszöbnél,
 * nem-nulla küszöb regressziója, valamint az {@code is_active = FALSE} fallback-ág
 * dokumentált igazolása.
 *
 * <p>Szerződés (FK-073 §10 TBD-3, FELTERKEPEZES_150 A2 megerősítve):
 * <ul>
 *   <li>EXPLICIT 0-küszöbnél ({@code |diff| >= 0}) bármilyen, akár legkisebb nem-nulla
 *       eltérés (pl. 0.01) BLOKKOL — a nulla eltérés viszont SOHA nem blokkol
 *       (explicit védelem a {@code blocks()}-ban).</li>
 *   <li>Nem-nulla küszöbnél a korábbi szemantika változatlan (explicit {@code >=},
 *       fallback {@code >}) — regresszió-védelem.</li>
 *   <li>Ha egy tolerancia-sor {@code is_active = FALSE}, a
 *       {@code SystemParameterService.findEffective()} nem tekinti effektív találatnak
 *       (4a0e39d0), ezért a {@link ClosingToleranceService} a kód-fallbackre esik:
 *       HUF→1, nem-HUF→0, {@code explicit=false} ({@code >} operátor). Ez a jelenlegi,
 *       ELFOGADOTT fallback-viselkedés — a teszt dokumentálja/igazolja, NEM módosítja
 *       (a tartós admin-oldali védelem nem e kérés hatóköre, FK-073 §10 TBD-6).</li>
 * </ul>
 */
@ExtendWith(MockitoExtension.class)
class ClosingToleranceZeroThresholdFk073Test {

    // =====================================================================
    // (a) 0-küszöb határeset — explicit sor (FR-3 végállapot)
    // =====================================================================

    @Nested
    @DisplayName("FR-4 (a): explicit 0-küszöb — bármilyen nem-nulla eltérés blokkol, a nulla soha")
    class ZeroThresholdBoundary {

        private final ClosingTolerance zero = ClosingTolerance.explicitOf(BigDecimal.ZERO);

        @Test
        @DisplayName("0-küszöb: a legkisebb nem-nulla eltérés (0.01 / -0.01) IS blokkol")
        void zeroThreshold_blocksAnyNonZeroDifference() {
            assertThat(zero.blocks(new BigDecimal("0.01"))).isTrue();
            assertThat(zero.blocks(new BigDecimal("-0.01"))).isTrue();
            assertThat(zero.blocks(new BigDecimal("0.001"))).isTrue();
            assertThat(zero.blocks(BigDecimal.ONE)).isTrue();
            assertThat(zero.blocks(new BigDecimal("-10"))).isTrue();
        }

        @Test
        @DisplayName("0-küszöb: nulla (vagy null) eltérés SOHA nem blokkol")
        void zeroThreshold_zeroDifferenceNeverBlocks() {
            assertThat(zero.blocks(BigDecimal.ZERO)).isFalse();
            assertThat(zero.blocks(new BigDecimal("0.00"))).isFalse();
            assertThat(zero.blocks(new BigDecimal("-0.000"))).isFalse();
            assertThat(zero.blocks(null)).isFalse();
        }

        @Test
        @DisplayName("FR-3 bekötés: explicit '0' paraméter-sor → explicitOf(0), ugyanazokkal a blokkolási szabályokkal")
        void explicitZeroRowFromParameter_parsesToExplicitZero() {
            // A V373 utáni végállapotot szimulálja: findEffective aktív '0' sort ad vissza.
            ClosingTolerance parsed = ClosingTolerance.explicitOf(new BigDecimal("0"));
            assertThat(parsed.explicit()).isTrue();
            assertThat(parsed.value()).isEqualByComparingTo(BigDecimal.ZERO);
            assertThat(parsed.blocks(new BigDecimal("0.01"))).isTrue();
            assertThat(parsed.blocks(BigDecimal.ZERO)).isFalse();
        }
    }

    // =====================================================================
    // (b) Regresszió: nem-nulla küszöb továbbra is a korábbi szemantikát hozza
    // =====================================================================

    @Nested
    @DisplayName("FR-4 (b): nem-nulla küszöb regresszió — explicit >= és fallback > változatlan")
    class NonZeroThresholdRegression {

        @Test
        @DisplayName("explicit 5: |diff|=4 átmegy, |diff|=5 (pontos egyezés) blokkol, előjeles abszolút érték")
        void explicitNonZeroThreshold_unchangedSemantics() {
            ClosingTolerance explicitFive = ClosingTolerance.explicitOf(new BigDecimal("5"));
            assertThat(explicitFive.blocks(new BigDecimal("4"))).isFalse();
            assertThat(explicitFive.blocks(new BigDecimal("-4"))).isFalse();
            assertThat(explicitFive.blocks(new BigDecimal("5"))).isTrue();
            assertThat(explicitFive.blocks(new BigDecimal("-5"))).isTrue();
            assertThat(explicitFive.blocks(new BigDecimal("6"))).isTrue();
            assertThat(explicitFive.blocks(BigDecimal.ZERO)).isFalse();
        }

        @Test
        @DisplayName("fallback 1 (HUF kód-default): |diff|=1 átmegy (>), |diff|=2 blokkol")
        void fallbackNonZeroThreshold_unchangedSemantics() {
            ClosingTolerance fallbackOne = ClosingTolerance.fallbackOf(BigDecimal.ONE);
            assertThat(fallbackOne.blocks(BigDecimal.ONE)).isFalse();
            assertThat(fallbackOne.blocks(new BigDecimal("-1"))).isFalse();
            assertThat(fallbackOne.blocks(new BigDecimal("1.01"))).isTrue();
            assertThat(fallbackOne.blocks(new BigDecimal("2"))).isTrue();
            assertThat(fallbackOne.blocks(BigDecimal.ZERO)).isFalse();
        }

        @Test
        @DisplayName("fallback 0 (nem-HUF kód-default): bármilyen nem-nulla eltérés blokkol (mai viselkedés)")
        void fallbackZeroThreshold_unchangedSemantics() {
            ClosingTolerance fallbackZero = ClosingTolerance.fallbackOf(BigDecimal.ZERO);
            assertThat(fallbackZero.blocks(new BigDecimal("0.01"))).isTrue();
            assertThat(fallbackZero.blocks(BigDecimal.ZERO)).isFalse();
        }
    }

    // =====================================================================
    // (d) is_active = FALSE fallback-ág — jelenlegi elfogadott viselkedés
    //     dokumentálása (NEM módosítása)
    // =====================================================================

    @Nested
    @DisplayName("FR-4 (d): inaktivált tolerancia-sor → findEffective üres → kód-fallback (HUF→1 '>', nem-HUF→0 '>')")
    class InactiveRowFallbackDocumentation {

        @Mock
        private SystemParameterService systemParameterService;

        @InjectMocks
        private ClosingToleranceService closingToleranceService;

        /**
         * Az inaktivált sor szimulációja: a SystemParameterService.findEffective()
         * (4a0e39d0 óta is_active-szűrés) egy is_active=FALSE sort nem ad vissza —
         * a hívó oldaláról ez Optional.empty()-ként jelenik meg.
         */
        @Test
        @DisplayName("HUF inaktivált sor → fallback HUF→1, '>' operátor (1 nem blokkol, 1.01 igen)")
        void inactiveHufRow_fallsBackToCodeDefaultOne() {
            when(systemParameterService.findEffectiveValue("CLOSING_TOLERANCE_HUF"))
                    .thenReturn(Optional.empty());

            ClosingTolerance huf = closingToleranceService.getToleranceFor("HUF");

            assertThat(huf.explicit())
                    .as("inaktivált sor nem effektív találat → fallback ág")
                    .isFalse();
            assertThat(huf.value())
                    .as("HUF kód-fallback: 1 Ft kerekítési tolerancia")
                    .isEqualByComparingTo(BigDecimal.ONE);
            // Fallback '>' operátor: a küszöbérték maga MÉG nem blokkol.
            assertThat(huf.blocks(BigDecimal.ONE)).isFalse();
            assertThat(huf.blocks(new BigDecimal("-1"))).isFalse();
            assertThat(huf.blocks(new BigDecimal("1.01"))).isTrue();
            assertThat(huf.blocks(BigDecimal.ZERO)).isFalse();
        }

        @Test
        @DisplayName("Nem-HUF (EUR) inaktivált sor → fallback 0, '>' operátor (bármilyen nem-nulla blokkol)")
        void inactiveNonHufRow_fallsBackToCodeDefaultZero() {
            when(systemParameterService.findEffectiveValue("CLOSING_TOLERANCE_EUR"))
                    .thenReturn(Optional.empty());

            ClosingTolerance eur = closingToleranceService.getToleranceFor("EUR");

            assertThat(eur.explicit()).isFalse();
            assertThat(eur.value())
                    .as("nem-HUF kód-fallback: 0, darabra pontos")
                    .isEqualByComparingTo(BigDecimal.ZERO);
            assertThat(eur.blocks(new BigDecimal("0.01"))).isTrue();
            assertThat(eur.blocks(BigDecimal.ZERO)).isFalse();
        }

        @Test
        @DisplayName("FR-3 végállapot: AKTÍV '0' sor → explicit 0 (findEffective visszaadja, blocks: nem-nulla blokkol)")
        void activeZeroRow_isEffectiveAndExplicit() {
            when(systemParameterService.findEffectiveValue("CLOSING_TOLERANCE_HUF"))
                    .thenReturn(Optional.of("0"));

            ClosingTolerance huf = closingToleranceService.getToleranceFor("HUF");

            assertThat(huf.explicit())
                    .as("aktív explicit sor jelenléte → explicit ág (>= operátor)")
                    .isTrue();
            assertThat(huf.value()).isEqualByComparingTo(BigDecimal.ZERO);
            assertThat(huf.blocks(new BigDecimal("0.01"))).isTrue();
            assertThat(huf.blocks(BigDecimal.ZERO)).isFalse();
        }
    }
}
