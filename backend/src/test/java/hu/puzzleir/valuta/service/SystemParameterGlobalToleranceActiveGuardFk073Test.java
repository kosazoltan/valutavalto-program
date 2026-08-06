package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.SystemParameter;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.SystemParameterRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * FK-073 TBD-6 (2026-08-06): TARTÓS admin-védelem a GLOBÁLIS (company_id IS NULL)
 * CLOSING_TOLERANCE_* sorok aktivási állapotára. A 0-tolerancia zárási kapu (V373)
 * működésének feltétele az aktív globális sor: az is_active-szűrés (4a0e39d0) miatt
 * egy inaktivált/törölt sor a ClosingToleranceService-t a kód-fallbackre ejtené
 * (HUF→1, {@code >} operátor), ami NÉMÁN kioltaná a 0-toleranciát.
 *
 * <p>A guard SZEREPTŐL FÜGGETLEN üzleti invariáns: még ADMIN elől is tiltja a globális
 * tolerancia-sor inaktiválását, törlését és eleve inaktívként történő létrehozását.
 * Az érték módosítása (küszöb-állítás) ADMIN-nak továbbra is engedélyezett; a
 * reaktiválás (inactive → active) az invariáns helyreállítása, ezért engedélyezett;
 * cég-scope-olt sorokra a guard nem vonatkozik.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class SystemParameterGlobalToleranceActiveGuardFk073Test {

    @Mock private SystemParameterRepository repo;
    @Mock private AuditLogService auditLogService;
    @org.mockito.Spy private tools.jackson.databind.ObjectMapper objectMapper =
            tools.jackson.databind.json.JsonMapper.builder().build();
    @InjectMocks private SystemParameterService service;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID ROW_ID = UUID.randomUUID();

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    private void authenticateAs(String role) {
        hu.puzzleir.valuta.security.WorkerAuthenticationDetails details =
                new hu.puzzleir.valuta.security.WorkerAuthenticationDetails(
                        1L, COMPANY_ID, UUID.randomUUID(), role);
        TestingAuthenticationToken auth =
                new TestingAuthenticationToken("test", "pass", "ROLE_" + role);
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    private SystemParameter toleranceRow(UUID companyId, Boolean isActive) {
        return SystemParameter.builder()
                .parameterKey("CLOSING_TOLERANCE_HUF")
                .parameterValue("0")
                .parameterType("NUMBER")
                .category("CLOSING")
                .companyId(companyId)
                .isActive(isActive)
                .build();
    }

    @Test
    @DisplayName("FK-073 TBD-6: ADMIN sem inaktiválhatja a GLOBÁLIS CLOSING_TOLERANCE_HUF sort → ValidationException")
    void adminCannotDeactivateGlobalClosingTolerance() {
        authenticateAs("ADMIN");
        when(repo.findVisibleById(ROW_ID, COMPANY_ID)).thenReturn(Optional.of(toleranceRow(null, true)));

        assertThatThrownBy(() -> service.toggleActive(ROW_ID))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("CLOSING_TOLERANCE_HUF")
                .hasMessageContaining("inaktiválása");
        verify(repo, never()).save(any());
    }

    @Test
    @DisplayName("FK-073 TBD-6: ADMIN sem törölheti a GLOBÁLIS tolerancia-sort → ValidationException")
    void adminCannotDeleteGlobalClosingTolerance() {
        authenticateAs("ADMIN");
        when(repo.findVisibleById(ROW_ID, COMPANY_ID)).thenReturn(Optional.of(toleranceRow(null, true)));

        assertThatThrownBy(() -> service.delete(ROW_ID))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("CLOSING_TOLERANCE_HUF")
                .hasMessageContaining("törlése");
        verify(repo, never()).delete(any());
    }

    @Test
    @DisplayName("FK-073 TBD-6: eleve INAKTÍV globális tolerancia-sor létrehozása tiltott (még ADMIN-nak is)")
    void adminCannotCreateInactiveGlobalClosingTolerance() {
        authenticateAs("ADMIN");

        assertThatThrownBy(() -> service.create(
                "CLOSING_TOLERANCE_USD", "0", "NUMBER", "CLOSING", null, Boolean.FALSE))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("inaktívként történő létrehozása");
        verify(repo, never()).save(any());
    }

    @Test
    @DisplayName("FK-073 TBD-6: NULL is_active sor AKTÍVNAK számít → a toggle (inaktiválás) rajta is tiltott")
    void nullIsActiveGlobalRowDeactivationAlsoBlocked() {
        authenticateAs("ADMIN");
        when(repo.findVisibleById(ROW_ID, COMPANY_ID)).thenReturn(Optional.of(toleranceRow(null, null)));

        assertThatThrownBy(() -> service.toggleActive(ROW_ID))
                .isInstanceOf(ValidationException.class);
        verify(repo, never()).save(any());
    }

    @Test
    @DisplayName("FK-073 TBD-6: REAKTIVÁLÁS (inaktív → aktív) engedélyezett — az invariáns helyreállítása")
    void reactivationOfGlobalClosingToleranceAllowed() {
        authenticateAs("ADMIN");
        when(repo.findVisibleById(ROW_ID, COMPANY_ID)).thenReturn(Optional.of(toleranceRow(null, false)));
        when(repo.save(any(SystemParameter.class))).thenAnswer(inv -> inv.getArgument(0));

        SystemParameter saved = service.toggleActive(ROW_ID);

        assertThat(saved.getIsActive()).isTrue();
        verify(repo).save(any(SystemParameter.class));
    }

    @Test
    @DisplayName("FK-073 TBD-6: globális tolerancia-sor ÉRTÉKÉNEK módosítása ADMIN-nak továbbra is engedélyezett")
    void adminCanStillUpdateGlobalClosingToleranceValue() {
        authenticateAs("ADMIN");
        when(repo.findVisibleById(ROW_ID, COMPANY_ID)).thenReturn(Optional.of(toleranceRow(null, true)));
        when(repo.save(any(SystemParameter.class))).thenAnswer(inv -> inv.getArgument(0));

        assertThat(service.update(ROW_ID, "5", null).getParameterValue()).isEqualTo("5");
        verify(repo).save(any(SystemParameter.class));
    }

    @Test
    @DisplayName("FK-073 TBD-6: CÉGES override-sor inaktiválása/törlése engedélyezett (nem globális invariáns)")
    void companyScopedToleranceRowCanBeDeactivatedAndDeleted() {
        authenticateAs("ADMIN");
        when(repo.findVisibleById(ROW_ID, COMPANY_ID)).thenReturn(Optional.of(toleranceRow(COMPANY_ID, true)));
        when(repo.save(any(SystemParameter.class))).thenAnswer(inv -> inv.getArgument(0));

        assertThatCode(() -> service.toggleActive(ROW_ID)).doesNotThrowAnyException();
        verify(repo).save(any(SystemParameter.class));

        SystemParameter companyRow = toleranceRow(COMPANY_ID, true);
        when(repo.findVisibleById(ROW_ID, COMPANY_ID)).thenReturn(Optional.of(companyRow));
        assertThatCode(() -> service.delete(ROW_ID)).doesNotThrowAnyException();
        verify(repo).delete(companyRow);
    }

    @Test
    @DisplayName("FK-073 TBD-6 scope-őrzés: FEATURE_* globális sor inaktiválása TOVÁBBRA is engedélyezett (a flag-kikapcsolás rendeltetés)")
    void featureKeyGlobalRowsStayDeactivatable() {
        authenticateAs("ADMIN");
        SystemParameter feature = SystemParameter.builder()
                .parameterKey("FEATURE_HANDLING_FEE_DENOMINATION")
                .parameterValue("true")
                .parameterType("BOOLEAN")
                .category("CLOSING")
                .companyId(null)
                .isActive(true)
                .build();
        when(repo.findVisibleById(ROW_ID, COMPANY_ID)).thenReturn(Optional.of(feature));
        when(repo.save(any(SystemParameter.class))).thenAnswer(inv -> inv.getArgument(0));

        assertThatCode(() -> service.toggleActive(ROW_ID)).doesNotThrowAnyException();
        verify(repo).save(any(SystemParameter.class));
    }

    @Test
    @DisplayName("FK-073 TBD-6 scope-őrzés: MANAGER globális NEM-tolerancia sorának inaktiválása továbbra is engedélyezett (a guard CSAK a CLOSING_TOLERANCE_* prefixre él)")
    void managerGlobalNonToleranceRowStaysDeactivatable() {
        authenticateAs("MANAGER");
        SystemParameter other = SystemParameter.builder()
                .parameterKey("CLOSING_DISCREPANCY_EXPLANATION_REQUIRED")
                .parameterValue("true")
                .parameterType("BOOLEAN")
                .category("CLOSING")
                .companyId(null)
                .isActive(true)
                .build();
        when(repo.findVisibleById(ROW_ID, COMPANY_ID)).thenReturn(Optional.of(other));
        when(repo.save(any(SystemParameter.class))).thenAnswer(inv -> inv.getArgument(0));

        // A TBD-6 guard CSAK a CLOSING_TOLERANCE_* prefixre vonatkozik — ez a globális sor
        // nem az FK-066 védett prefixei alá esik, és nem tolerancia-sor: a MANAGER
        // inaktiválása változatlanul átengedett (FK-066-guardtesztekkel konzisztens).
        assertThatCode(() -> service.toggleActive(ROW_ID)).doesNotThrowAnyException();
        verify(repo).save(any(SystemParameter.class));
    }
}
