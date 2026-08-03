package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.SystemParameter;
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
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * FK-066 HIGH-fix (Codex review): a GLOBÁLIS (company_id IS NULL) CLOSING_TOLERANCE_*
 * sorok írása minden cég zárási kapuját befolyásolja, ezért a generikus írási
 * útvonalakon (update/upsert/create/toggleActive/delete) kizárólag ADMIN végezheti —
 * a /api/v1/system-params MANAGER-t is engedő végpontja mögött a SERVICE-rétegben
 * érvényesül a guard. MANAGER a saját céges override-ot ({@code upsertCompanyValue},
 * illetve céges sor módosítása) továbbra is kezelheti; a nem-tolerancia globális
 * paraméterek MANAGER-viselkedése változatlan.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class SystemParameterGlobalToleranceGuardFk066Test {

    @Mock private SystemParameterRepository repo;
    /** §3 audit-bekötés (VV-VALID-201) óta a service kollaborátora — a guard-viselkedés változatlan. */
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

    private SystemParameter toleranceRow(UUID companyId) {
        return SystemParameter.builder()
                .parameterKey("CLOSING_TOLERANCE_HUF")
                .parameterValue("5")
                .parameterType("NUMBER")
                .category("CLOSING")
                .companyId(companyId)
                .isActive(true)
                .build();
    }

    @Test
    @DisplayName("FK-066 HIGH: MANAGER nem írhatja a GLOBÁLIS CLOSING_TOLERANCE_HUF sort (update) → AccessDenied (403)")
    void managerCannotUpdateGlobalClosingTolerance() {
        authenticateAs("MANAGER");
        when(repo.findVisibleById(ROW_ID, COMPANY_ID)).thenReturn(Optional.of(toleranceRow(null)));

        assertThatThrownBy(() -> service.update(ROW_ID, "100", null))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessageContaining("CLOSING_TOLERANCE_HUF")
                .hasMessageContaining("ADMIN");
        verify(repo, never()).save(any());
    }

    @Test
    @DisplayName("FK-066 HIGH: MANAGER a globális tolerancián upsert/create/toggleActive/delete útvonalon sem mehet át")
    void managerBlockedOnAllGenericGlobalWritePaths() {
        authenticateAs("MANAGER");
        when(repo.findVisibleById(ROW_ID, COMPANY_ID)).thenReturn(Optional.of(toleranceRow(null)));

        assertThatThrownBy(() -> service.upsert("CLOSING_TOLERANCE_EUR", "9", "CLOSING", null))
                .isInstanceOf(AccessDeniedException.class);
        assertThatThrownBy(() -> service.create("CLOSING_TOLERANCE_USD", "9", "NUMBER", "CLOSING", null))
                .isInstanceOf(AccessDeniedException.class);
        assertThatThrownBy(() -> service.toggleActive(ROW_ID))
                .isInstanceOf(AccessDeniedException.class);
        assertThatThrownBy(() -> service.delete(ROW_ID))
                .isInstanceOf(AccessDeniedException.class);
        verify(repo, never()).save(any());
        verify(repo, never()).delete(any());
    }

    @Test
    @DisplayName("FK-066 HIGH: MANAGER saját céges override-ot írhat (upsertCompanyValue) → engedélyezett")
    void managerCanUpsertOwnCompanyOverride() {
        authenticateAs("MANAGER");
        when(repo.findByParameterKeyAndCompanyId("CLOSING_TOLERANCE_HUF", COMPANY_ID))
                .thenReturn(Optional.empty());
        when(repo.save(any(SystemParameter.class))).thenAnswer(inv -> inv.getArgument(0));

        SystemParameter saved = service.upsertCompanyValue(
                "CLOSING_TOLERANCE_HUF", COMPANY_ID, "3", "CLOSING", "céges override");

        assertThat(saved.getParameterValue()).isEqualTo("3");
        assertThat(saved.getCompanyId()).isEqualTo(COMPANY_ID);
        verify(repo).save(any(SystemParameter.class));
    }

    @Test
    @DisplayName("FK-066 HIGH: MANAGER a SAJÁT CÉGES tolerancia-sort id-alapú update-tel is módosíthatja")
    void managerCanUpdateOwnCompanyToleranceRow() {
        authenticateAs("MANAGER");
        when(repo.findVisibleById(ROW_ID, COMPANY_ID)).thenReturn(Optional.of(toleranceRow(COMPANY_ID)));
        when(repo.save(any(SystemParameter.class))).thenAnswer(inv -> inv.getArgument(0));

        assertThat(service.update(ROW_ID, "3", null).getParameterValue()).isEqualTo("3");
        verify(repo).save(any(SystemParameter.class));
    }

    @Test
    @DisplayName("FK-066 HIGH: ADMIN a globális tolerancia-sort módosíthatja")
    void adminCanUpdateGlobalClosingTolerance() {
        authenticateAs("ADMIN");
        when(repo.findVisibleById(ROW_ID, COMPANY_ID)).thenReturn(Optional.of(toleranceRow(null)));
        when(repo.save(any(SystemParameter.class))).thenAnswer(inv -> inv.getArgument(0));

        assertThat(service.update(ROW_ID, "7", null).getParameterValue()).isEqualTo("7");
        verify(repo).save(any(SystemParameter.class));
    }

    @Test
    @DisplayName("FK-066 HIGH scope-őrzés: MANAGER a NEM-tolerancia globális paramétert továbbra is írhatja (változatlan viselkedés)")
    void managerCanStillUpdateOtherGlobalParameters() {
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

        assertThat(service.update(ROW_ID, "false", null).getParameterValue()).isEqualTo("false");
        verify(repo).save(any(SystemParameter.class));
    }
}
