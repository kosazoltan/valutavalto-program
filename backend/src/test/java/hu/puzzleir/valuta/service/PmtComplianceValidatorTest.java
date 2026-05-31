package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ValidationException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

/**
 * {@link PmtComplianceValidator} egysegtesztek (F-002 + Codex P1, 2026-05-29).
 *
 * <p>A Copilot review kerese: a strict-default flip legyen lefedve NEM-null
 * SystemParameterService-szel — hianyzo paramnal STRICT (dob), explicit 'false'-nal WARN-only.</p>
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("PmtComplianceValidator — Pmt. 300k+ strict enforcement (F-002)")
class PmtComplianceValidatorTest {

    @Mock private SystemParameterService systemParameterService;

    private static final BigDecimal HUF_400K = BigDecimal.valueOf(400_000);

    private PmtComplianceValidator validator() {
        return new PmtComplianceValidator(systemParameterService);
    }

    @Test
    @DisplayName("Hianyzo PMT_STRICT_ENFORCEMENT param → DEFAULT 'true' → 300k+ PEP-minoseg hianynal DOB")
    void missingParamDefaultsToStrict_pepKindMissing() {
        // A param hianyzik → getValue a default 2. argot ('true') adja vissza.
        when(systemParameterService.getValue(eq("PMT_STRICT_ENFORCEMENT"), eq("true"))).thenReturn("true");

        assertThatThrownBy(() -> validator().validate(
                HUF_400K, Boolean.TRUE, null /*pepKind hianyzik*/, Boolean.TRUE,
                null, null, null, null, null, null, "BUY"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("PEP");
    }

    @Test
    @DisplayName("Hianyzo param → strict → onOwnBehalf=false + hianyzo actor-mezok → DOB")
    void missingParamDefaultsToStrict_actorMissing() {
        when(systemParameterService.getValue(eq("PMT_STRICT_ENFORCEMENT"), eq("true"))).thenReturn("true");

        assertThatThrownBy(() -> validator().validate(
                HUF_400K, Boolean.FALSE, null, Boolean.FALSE /*kepviselt fel*/,
                null, null, null, null, null, null, "SELL"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("actor");
    }

    @Test
    @DisplayName("Explicit PMT_STRICT_ENFORCEMENT=false → WARN-only (NEM dob) a hianyos adatra")
    void explicitFalseStaysWarnOnly() {
        when(systemParameterService.getValue(eq("PMT_STRICT_ENFORCEMENT"), eq("true"))).thenReturn("false");

        assertThatCode(() -> validator().validate(
                HUF_400K, Boolean.TRUE, null, Boolean.FALSE,
                null, null, null, null, null, null, "BUY"))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("300k alatt → semmi ellenorzes (nem dob, parametert sem olvas)")
    void belowThresholdSkips() {
        lenient().when(systemParameterService.getValue(eq("PMT_STRICT_ENFORCEMENT"), eq("true"))).thenReturn("true");

        assertThatCode(() -> validator().validate(
                BigDecimal.valueOf(100_000), Boolean.TRUE, null, Boolean.FALSE,
                null, null, null, null, null, null, "BUY"))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("Strict + teljes adat (PEP-minoseg + actor mezok kitoltve) → NEM dob")
    void strictWithCompleteDataPasses() {
        when(systemParameterService.getValue(eq("PMT_STRICT_ENFORCEMENT"), eq("true"))).thenReturn("true");

        assertThatCode(() -> validator().validate(
                HUF_400K, Boolean.TRUE, "hazai PEP", Boolean.FALSE,
                "Kovacs Bela", "Budapest", "1980-01-01", "Nagy Anna", "AB123456", "Budapest, Fo u. 1.", "BUY"))
                .doesNotThrowAnyException();
    }
}
