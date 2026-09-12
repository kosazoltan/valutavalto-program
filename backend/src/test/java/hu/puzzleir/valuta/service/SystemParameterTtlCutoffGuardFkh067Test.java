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

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FKH-067 review fix (Copilot P1): the GLOBAL (company_id IS NULL) TTL_NONBLOCKING_CUTOFF row
 * decides in EVERY company whether a transaction may be booked with an expired exchange rate,
 * so it belongs under the same protected financial-control guard as CLOSING_TOLERANCE_* and
 * FEATURE_* ({@code assertGlobalFinancialControlKeyWriteAllowed}): the global row is ADMIN-only,
 * while a company-scoped override stays available to MANAGER.
 *
 * Structure mirrors {@link SystemParameterFeatureKeyGuardFk067Test}.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class SystemParameterTtlCutoffGuardFkh067Test {

    @Mock private SystemParameterRepository repo;
    @Mock private AuditLogService auditLogService;
    @org.mockito.Spy private tools.jackson.databind.ObjectMapper objectMapper =
            tools.jackson.databind.json.JsonMapper.builder().build();
    @InjectMocks private SystemParameterService service;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID ROW_ID = UUID.randomUUID();

    /** Single source for the key - guards against typo drift. */
    private static final String CUTOFF_KEY = ExchangeRateService.TTL_NONBLOCKING_CUTOFF_KEY;

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

    private SystemParameter cutoffRow(UUID companyId) {
        return SystemParameter.builder()
                .parameterKey(CUTOFF_KEY)
                .parameterValue("")
                .parameterType("DATETIME")
                .category("TRANSACTION")
                .companyId(companyId)
                .isActive(true)
                .build();
    }

    @Test
    @DisplayName("FKH-067: MANAGER cannot write the GLOBAL TTL_NONBLOCKING_CUTOFF row (update) -> AccessDenied")
    void managerCannotUpdateGlobalCutoff() {
        authenticateAs("MANAGER");
        when(repo.findVisibleById(ROW_ID, COMPANY_ID)).thenReturn(Optional.of(cutoffRow(null)));

        assertThatThrownBy(() -> service.update(ROW_ID, "2026-09-12T06:00:00Z", null))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessageContaining(CUTOFF_KEY)
                .hasMessageContaining("ADMIN");
        verify(repo, never()).save(any());
    }

    @Test
    @DisplayName("FKH-067: MANAGER is blocked on every generic global write path (upsert/create/toggleActive/delete)")
    void managerBlockedOnAllGenericGlobalWritePaths() {
        authenticateAs("MANAGER");
        when(repo.findVisibleById(ROW_ID, COMPANY_ID)).thenReturn(Optional.of(cutoffRow(null)));

        assertThatThrownBy(() -> service.upsert(CUTOFF_KEY, "2026-09-12T06:00:00Z", "TRANSACTION", null))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessageContaining(CUTOFF_KEY)
                .hasMessageContaining("ADMIN");
        assertThatThrownBy(() -> service.create(CUTOFF_KEY, "2026-09-12T06:00:00Z", "DATETIME", "TRANSACTION", null))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessageContaining(CUTOFF_KEY)
                .hasMessageContaining("ADMIN");
        assertThatThrownBy(() -> service.toggleActive(ROW_ID))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessageContaining(CUTOFF_KEY)
                .hasMessageContaining("ADMIN");
        assertThatThrownBy(() -> service.delete(ROW_ID))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessageContaining(CUTOFF_KEY)
                .hasMessageContaining("ADMIN");
        verify(repo, never()).save(any());
        verify(repo, never()).delete(any());
    }

    @Test
    @DisplayName("FKH-067: ADMIN may set the global cutoff (the guard is authorization, not a ban)")
    void adminCanUpdateGlobalCutoff() {
        authenticateAs("ADMIN");
        when(repo.findVisibleById(ROW_ID, COMPANY_ID)).thenReturn(Optional.of(cutoffRow(null)));
        when(repo.save(any())).thenAnswer(inv -> inv.getArgument(0));

        assertThatCode(() -> service.update(ROW_ID, "2026-09-12T06:00:00Z", null))
                .doesNotThrowAnyException();
        verify(repo).save(any());
    }
}
