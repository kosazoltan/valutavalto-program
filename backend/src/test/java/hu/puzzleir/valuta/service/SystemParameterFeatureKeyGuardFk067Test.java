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
 * FK-067 HIGH#1-fix (Codex review): a GLOBÁLIS (company_id IS NULL) FEATURE_* sorok
 * pénzügyi kontroll-lépéseket kapcsolnak (pl. FEATURE_HANDLING_FEE_DENOMINATION a
 * záráskori kezelésidíj-ellenőrzést), ezért a CLOSING_TOLERANCE_* kulcsokkal KÖZÖS
 * "védett pénzügyi kontroll-kulcs" guard alá tartoznak
 * ({@code assertGlobalFinancialControlKeyWriteAllowed} — egyetlen implementáció, nem
 * párhuzamos másolat): globális írás csak ADMIN-nak, a céges override
 * ({@code upsertCompanyValue}, illetve céges sor id-alapú módosítása) MANAGER-nek
 * továbbra is engedélyezett. A CLOSING_TOLERANCE_* ágat a
 * {@link SystemParameterGlobalToleranceGuardFk066Test} fedi változatlanul.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class SystemParameterFeatureKeyGuardFk067Test {

    @Mock private SystemParameterRepository repo;
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

    private SystemParameter featureRow(UUID companyId) {
        return SystemParameter.builder()
                .parameterKey("FEATURE_HANDLING_FEE_DENOMINATION")
                .parameterValue("true")
                .parameterType("BOOLEAN")
                .category("CLOSING")
                .companyId(companyId)
                .isActive(true)
                .build();
    }

    @Test
    @DisplayName("FK-067 HIGH#1: MANAGER nem írhatja a GLOBÁLIS FEATURE_HANDLING_FEE_DENOMINATION sort (update) → AccessDenied")
    void managerCannotUpdateGlobalFeatureFlag() {
        authenticateAs("MANAGER");
        when(repo.findVisibleById(ROW_ID, COMPANY_ID)).thenReturn(Optional.of(featureRow(null)));

        assertThatThrownBy(() -> service.update(ROW_ID, "false", null))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessageContaining("FEATURE_HANDLING_FEE_DENOMINATION")
                .hasMessageContaining("ADMIN");
        verify(repo, never()).save(any());
    }

    @Test
    @DisplayName("FK-067 HIGH#1: MANAGER a globális FEATURE_* kulcson upsert/create/toggleActive/delete útvonalon sem mehet át")
    void managerBlockedOnAllGenericGlobalWritePaths() {
        authenticateAs("MANAGER");
        when(repo.findVisibleById(ROW_ID, COMPANY_ID)).thenReturn(Optional.of(featureRow(null)));

        assertThatThrownBy(() -> service.upsert("FEATURE_HANDLING_FEE_DENOMINATION", "true", "CLOSING", null))
                .isInstanceOf(AccessDeniedException.class);
        assertThatThrownBy(() -> service.create("FEATURE_WESTERN_UNION", "true", "BOOLEAN", "CLOSING", null))
                .isInstanceOf(AccessDeniedException.class);
        assertThatThrownBy(() -> service.toggleActive(ROW_ID))
                .isInstanceOf(AccessDeniedException.class);
        assertThatThrownBy(() -> service.delete(ROW_ID))
                .isInstanceOf(AccessDeniedException.class);
        verify(repo, never()).save(any());
        verify(repo, never()).delete(any());
    }

    @Test
    @DisplayName("FK-067 HIGH#1: MANAGER saját céges FEATURE-override-ot írhat (upsertCompanyValue) → engedélyezett")
    void managerCanUpsertOwnCompanyFeatureOverride() {
        authenticateAs("MANAGER");
        when(repo.findByParameterKeyAndCompanyId("FEATURE_HANDLING_FEE_DENOMINATION", COMPANY_ID))
                .thenReturn(Optional.empty());
        when(repo.save(any(SystemParameter.class))).thenAnswer(inv -> inv.getArgument(0));

        SystemParameter saved = service.upsertCompanyValue(
                "FEATURE_HANDLING_FEE_DENOMINATION", COMPANY_ID, "true", "CLOSING", "céges override");

        assertThat(saved.getParameterValue()).isEqualTo("true");
        assertThat(saved.getCompanyId()).isEqualTo(COMPANY_ID);
        verify(repo).save(any(SystemParameter.class));
    }

    @Test
    @DisplayName("FK-067 HIGH#1: MANAGER a SAJÁT CÉGES FEATURE-sort id-alapú update-tel is módosíthatja")
    void managerCanUpdateOwnCompanyFeatureRow() {
        authenticateAs("MANAGER");
        when(repo.findVisibleById(ROW_ID, COMPANY_ID)).thenReturn(Optional.of(featureRow(COMPANY_ID)));
        when(repo.save(any(SystemParameter.class))).thenAnswer(inv -> inv.getArgument(0));

        assertThat(service.update(ROW_ID, "false", null).getParameterValue()).isEqualTo("false");
        verify(repo).save(any(SystemParameter.class));
    }

    @Test
    @DisplayName("FK-067 HIGH#1: ADMIN a globális FEATURE-sort módosíthatja")
    void adminCanUpdateGlobalFeatureFlag() {
        authenticateAs("ADMIN");
        when(repo.findVisibleById(ROW_ID, COMPANY_ID)).thenReturn(Optional.of(featureRow(null)));
        when(repo.save(any(SystemParameter.class))).thenAnswer(inv -> inv.getArgument(0));

        assertThat(service.update(ROW_ID, "false", null).getParameterValue()).isEqualTo("false");
        verify(repo).save(any(SystemParameter.class));
    }
}
