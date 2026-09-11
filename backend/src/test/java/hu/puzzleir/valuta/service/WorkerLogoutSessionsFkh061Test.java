package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.WorkerSession;
import hu.puzzleir.valuta.repository.WorkerSessionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.when;

/**
 * FKH-061 (Defect C) — logout must close EVERY open session and stay idempotent.
 *
 * <p>Production evidence: {@code worker_session} held 1771 rows, all with {@code logout_at IS NULL}
 * (worker 3: 456, worker 4: 329, worker 1: 259, worker 2: 238). The repository finder returned
 * {@code Optional<WorkerSession>}, so {@code WorkerService.logout} threw
 * {@code IncorrectResultSizeDataAccessException} ("Query did not return a unique result: 238
 * results were returned") and the logout endpoint answered HTTP 500. The failure was
 * self-reinforcing: the session was never closed, so the next login added another orphan row.</p>
 *
 * <p>RED on BASE 1588b5b2: the finder returns {@code Optional} there, so this test does not even
 * compile against the base revision — the signature change is the fix.</p>
 *
 * <p>Note: the bulk close writes a TENANT-SCOPED audit entry
 * ({@code WORKER_SESSION_BULK_CLOSED}, {@code WorkerService.java:573-585}) via
 * {@code AuditLogService.logForCompany}, with the companyId derived from
 * {@code worker_session.company_id} rather than the SecurityContext, which is empty on the
 * blacklisted-token JWT fallback branch. {@code AuditLogService} is the 13th constructor
 * dependency, so no constructor change was needed.</p>
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class WorkerLogoutSessionsFkh061Test {

    private static final Long WORKER_ID = 42L;

    @Mock
    private WorkerSessionRepository sessionRepository;
    @Mock
    private hu.puzzleir.valuta.security.JwtTokenProvider jwtTokenProvider;
    @Mock
    private AuditLogService auditLogService;

    private WorkerService workerService;

    @BeforeEach
    void setUp() {
        // WorkerService uses Lombok @RequiredArgsConstructor over 13 final fields; only
        // sessionRepository (2nd), jwtTokenProvider (6th) and auditLogService (13th) are
        // exercised by logout(token).
        workerService = new WorkerService(
                null, sessionRepository, null, null, null, jwtTokenProvider,
                null, null, null, null, null, null, auditLogService);
    }

    private static final UUID COMPANY_ID = UUID.fromString("11111111-2222-3333-4444-555555555555");

    /**
     * FKH-061 round-3 (reviewer WARNING): the session MUST carry a company, because
     * worker_session.company_id is NOT NULL (WorkerSession.java:38 @JoinColumn(nullable=false)).
     * A company-less session would only exercise the defensive else-branch and leave the real
     * production path (tenant-scoped logForCompany) uncovered.
     */
    private static WorkerSession openSession(Long id) {
        return WorkerSession.builder()
                .id(id)
                .company(Company.builder().id(COMPANY_ID).build())
                .loginAt(LocalDateTime.now().minusHours(1))
                .logoutAt(null)
                .build();
    }

    @Test
    @DisplayName("FKH-061 A5: logout closes ALL open sessions of the worker without throwing")
    void logoutClosesEveryOpenSession() {
        when(sessionRepository.findByWorkerIdAndLogoutAtIsNull(WORKER_ID))
                .thenReturn(List.of(openSession(1L), openSession(2L), openSession(3L)));

        // SecurityUtils is consulted FIRST (WorkerService.java:545); pin it so the worker id is
        // deterministic instead of leaking from ambient test state.
        try (MockedStatic<hu.puzzleir.valuta.security.SecurityUtils> sec =
                     mockStatic(hu.puzzleir.valuta.security.SecurityUtils.class)) {
            sec.when(hu.puzzleir.valuta.security.SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
            // On BASE this path threw IncorrectResultSizeDataAccessException for >1 open row.
            assertThatCode(() -> workerService.logout("tok")).doesNotThrowAnyException();
        }

        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<WorkerSession>> captor = ArgumentCaptor.forClass(List.class);
        verify(sessionRepository).saveAll(captor.capture());

        List<WorkerSession> saved = captor.getValue();
        assertThat(saved).hasSize(3);
        assertThat(saved).allSatisfy(s -> assertThat(s.getLogoutAt()).isNotNull());

        // Pin the audit contract: the bulk close must leave a trace (reviewer NIT 1).
        // FKH-061 round-3 (reviewer WARNING): pin the TENANT-SCOPED overload. Asserting
        // logForCompany (not the 3-arg log()) is what proves multi-tenant isolation
        // (invariant #1) holds here — the 3-arg overload resolves companyId from the
        // SecurityContext, which is empty on the blacklisted-token JWT fallback branch.
        verify(auditLogService).logForCompany(
                org.mockito.ArgumentMatchers.eq("WORKER_SESSION_BULK_CLOSED"),
                org.mockito.ArgumentMatchers.anyString(),
                org.mockito.ArgumentMatchers.anyString(),
                org.mockito.ArgumentMatchers.eq(COMPANY_ID));
    }

    @Test
    @DisplayName("FKH-061 A5: logout with no open session is a no-op (idempotent on repeat)")
    void logoutWithoutOpenSessionIsNoOp() {
        when(sessionRepository.findByWorkerIdAndLogoutAtIsNull(anyLong()))
                .thenReturn(List.of());

        try (MockedStatic<hu.puzzleir.valuta.security.SecurityUtils> sec =
                     mockStatic(hu.puzzleir.valuta.security.SecurityUtils.class)) {
            sec.when(hu.puzzleir.valuta.security.SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
            assertThatCode(() -> workerService.logout("tok")).doesNotThrowAnyException();
            assertThatCode(() -> workerService.logout("tok")).doesNotThrowAnyException();
        }

        verify(sessionRepository, never()).saveAll(org.mockito.ArgumentMatchers.anyList());
    }
}
