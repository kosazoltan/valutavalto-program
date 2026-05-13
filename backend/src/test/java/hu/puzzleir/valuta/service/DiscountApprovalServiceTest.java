package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.ApprovalLevel;
import hu.puzzleir.valuta.exception.ValidationException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

/**
 * Sprint 4 P2-D: discount granular approval szint logika tesztek.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class DiscountApprovalServiceTest {

    @Mock private SystemParameterService systemParameterService;

    @InjectMocks
    private DiscountApprovalService service;

    @BeforeEach
    void setUp() {
        when(systemParameterService.getValue("DISCOUNT_SUPERVISOR_THRESHOLD_PCT", "2.0")).thenReturn("2.0");
        when(systemParameterService.getValue("DISCOUNT_MANAGER_THRESHOLD_PCT", "5.0")).thenReturn("5.0");
        when(systemParameterService.getValue("DISCOUNT_DIRECTOR_THRESHOLD_PCT", "10.0")).thenReturn("10.0");
        // Codex P2 #571 fix: DISCOUNT_MAX_PCT új system parameter
        when(systemParameterService.getValue("DISCOUNT_MAX_PCT", "15.0")).thenReturn("15.0");
    }

    @ParameterizedTest
    @CsvSource({
            "0.0,    CASHIER",
            "1.0,    CASHIER",
            "2.0,    CASHIER",
            "2.5,    SUPERVISOR",
            "5.0,    SUPERVISOR",
            "5.5,    MANAGER",
            "10.0,   MANAGER",
            "10.5,   DIRECTOR",
            "15.0,   DIRECTOR"
    })
    @DisplayName("getRequiredLevel — % alapján a helyes szint")
    void getRequiredLevel_correctMapping(BigDecimal pct, ApprovalLevel expected) {
        assertThat(service.getRequiredLevel(pct)).isEqualTo(expected);
    }

    @Test
    @DisplayName("getRequiredLevel — null vagy 0 → CASHIER")
    void getRequiredLevel_nullOrZero_returnsCashier() {
        assertThat(service.getRequiredLevel(null)).isEqualTo(ApprovalLevel.CASHIER);
        assertThat(service.getRequiredLevel(BigDecimal.ZERO)).isEqualTo(ApprovalLevel.CASHIER);
        assertThat(service.getRequiredLevel(new BigDecimal("-5"))).isEqualTo(ApprovalLevel.CASHIER);
    }

    @ParameterizedTest
    @CsvSource({
            "CASHIER,            CASHIER",
            "CASHIER_SUPERVISOR, SUPERVISOR",
            "SUPERVISOR,         SUPERVISOR",
            "TREASURY_MANAGER,   MANAGER",
            "REGIONAL_MANAGER,   MANAGER",
            "MANAGER,            MANAGER",
            "ADMIN,              DIRECTOR",
            "SYSTEM_ADMIN,       DIRECTOR",
            "MAIN_TREASURY,      DIRECTOR",
            "DIRECTOR,           DIRECTOR"
    })
    @DisplayName("mapRoleToLevel — role string → ApprovalLevel")
    void mapRoleToLevel_correctMapping(String role, ApprovalLevel expected) {
        assertThat(service.mapRoleToLevel(role)).isEqualTo(expected);
    }

    @Test
    @DisplayName("mapRoleToLevel — ismeretlen/null role → CASHIER")
    void mapRoleToLevel_unknownOrNull_returnsCashier() {
        assertThat(service.mapRoleToLevel(null)).isEqualTo(ApprovalLevel.CASHIER);
        assertThat(service.mapRoleToLevel("UNKNOWN")).isEqualTo(ApprovalLevel.CASHIER);
        assertThat(service.mapRoleToLevel("")).isEqualTo(ApprovalLevel.CASHIER);
    }

    @Test
    @DisplayName("validateApprovalLevel — CASHIER 1% discount → OK")
    void validateApprovalLevel_lowDiscount_ok() {
        assertThatCode(() -> service.validateApprovalLevel(new BigDecimal("1.5"), "CASHIER"))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("validateApprovalLevel — CASHIER 4% discount → ValidationException (SUPERVISOR kell)")
    void validateApprovalLevel_cashier4pct_throws() {
        assertThatThrownBy(() -> service.validateApprovalLevel(new BigDecimal("4.0"), "CASHIER"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("SUPERVISOR szintű jóváhagyást igényel");
    }

    @Test
    @DisplayName("validateApprovalLevel — MANAGER 8% discount → OK")
    void validateApprovalLevel_manager8pct_ok() {
        assertThatCode(() -> service.validateApprovalLevel(new BigDecimal("8.0"), "MANAGER"))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("validateApprovalLevel — MANAGER 12% discount → ValidationException (DIRECTOR kell)")
    void validateApprovalLevel_manager12pct_throws() {
        assertThatThrownBy(() -> service.validateApprovalLevel(new BigDecimal("12.0"), "MANAGER"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("DIRECTOR szintű jóváhagyást igényel");
    }

    @Test
    @DisplayName("validateApprovalLevel — DIRECTOR 15% → OK (max)")
    void validateApprovalLevel_director15pct_ok() {
        assertThatCode(() -> service.validateApprovalLevel(new BigDecimal("15.0"), "DIRECTOR"))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("validateApprovalLevel — DIRECTOR 16% → ValidationException (cap=15)")
    void validateApprovalLevel_director16pct_throws_atMaxCap() {
        // Codex P2 #571: 15%+ nem engedélyezett senkinek (üzleti policy max).
        assertThatThrownBy(() -> service.validateApprovalLevel(new BigDecimal("16.0"), "DIRECTOR"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("meghaladja a rendszer-szintű maximum");
    }

    @Test
    @DisplayName("mapRoleToLevel — REGIONAL_MGR (operational code) → MANAGER")
    void mapRoleToLevel_regionalMgr_isManager() {
        // Codex P2 #571: a JWT activeRole-ban REGIONAL_MGR (NEM REGIONAL_MANAGER) érkezhet.
        assertThat(service.mapRoleToLevel("REGIONAL_MGR")).isEqualTo(ApprovalLevel.MANAGER);
        assertThat(service.mapRoleToLevel("TERULETI_VEZETO")).isEqualTo(ApprovalLevel.MANAGER);
    }

    @Test
    @DisplayName("mapRoleToLevel — RAW operational codes (Copilot P2 #580)")
    void mapRoleToLevel_rawOperationalCodes() {
        // Copilot P2 #580: a WorkerAuthenticationDetails.activeRole RAW operational code-ot tárol,
        // NEM normalized canonical. Mind a 2 csatorna lefedve a switch-ben.
        assertThat(service.mapRoleToLevel("CHIEF_VAULT")).isEqualTo(ApprovalLevel.DIRECTOR);
        assertThat(service.mapRoleToLevel("OFFICE_MGR")).isEqualTo(ApprovalLevel.MANAGER);
        assertThat(service.mapRoleToLevel("AUDITOR")).isEqualTo(ApprovalLevel.SUPERVISOR);
        // Normalized canonical egyaránt működik:
        assertThat(service.mapRoleToLevel("FOERTEKTAR")).isEqualTo(ApprovalLevel.DIRECTOR);
        assertThat(service.mapRoleToLevel("IRODAVEZETO")).isEqualTo(ApprovalLevel.MANAGER);
        assertThat(service.mapRoleToLevel("BELSO_ELLENOR")).isEqualTo(ApprovalLevel.SUPERVISOR);
    }

    @Test
    @DisplayName("ApprovalLevel.satisfies — CASHIER < SUPERVISOR")
    void approvalLevel_satisfies() {
        assertThat(ApprovalLevel.CASHIER.satisfies(ApprovalLevel.SUPERVISOR)).isFalse();
        assertThat(ApprovalLevel.SUPERVISOR.satisfies(ApprovalLevel.SUPERVISOR)).isTrue();
        assertThat(ApprovalLevel.MANAGER.satisfies(ApprovalLevel.SUPERVISOR)).isTrue();
        assertThat(ApprovalLevel.DIRECTOR.satisfies(ApprovalLevel.MANAGER)).isTrue();
        assertThat(ApprovalLevel.SUPERVISOR.satisfies(ApprovalLevel.MANAGER)).isFalse();
    }
}
