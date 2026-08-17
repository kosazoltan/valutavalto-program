package hu.puzzleir.valuta.service;

import tools.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.repository.DenominationAllowedRepository;
import hu.puzzleir.valuta.dto.closingwizard.ClosingWizardStatusDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * FK-065: Beragadt zárási munkamenet kezelése — RED-fázis tesztek (teszt-vezérelt).
 *
 * <p>SZERZŐDÉS (a Fázis 0 felderítés tényeire építve):
 * <ul>
 *   <li>Új {@code WizardStatus.EXPIRED} enum-érték (nincs DB-migráció: STRING enum, VARCHAR(20)).</li>
 *   <li>Új service-metódus: {@code int ClosingWizardService.autoExpireStaleWizards()} —
 *       a {@code ReservationService.autoExpireReservations()} mintát követi:
 *       globális (cross-tenant) query, per-item hibaizoláció, SecurityContext-mentes.</li>
 *   <li>Új repository-query: {@code findByWizardStatusAndStartedAtBefore(WizardStatus, LocalDateTime)}
 *       (a foglaló {@code findByStatusAndExpiresAtBefore} mintája).</li>
 *   <li>Lejárati küszöb SystemParameter-ből: kulcs {@code CLOSING_WIZARD_AUTO_EXPIRE_MINUTES},
 *       default {@code "120"} (perc) — a CLOSING_DISCREPANCY_EXPLANATION_REQUIRED minta szerint.</li>
 *   <li>Audit: cégenként a wizard SAJÁT branch→company adatából,
 *       {@code AuditLogService.logForCompany("CLOSING_WIZARD_AUTO_EXPIRED", msg, wizardId, companyId)}
 *       (P29-minta; a logForCompany-ban az actor/entityType fixen "SYSTEM").
 *       A wizard-táblán NINCS új oszlop — az indító/megszakító megkülönböztetés audit_log-on történik.</li>
 *   <li>KAT/error_code: az üzenet a repo audit-JSON konvencióját követi —
 *       {@code {"KAT":"TX","error_code":"VV-BIZ-011",...}}. Precedens: a zárás-domain
 *       audit KAT=TX + VV-BIZ-* párosítást használ (DailyBalanceService TH-adjustment,
 *       DailyClosingService VV-BIZ-006/010); a reservation auto-expiry NEM ír KAT-ot
 *       (régebbi minta). A VV-BIZ-011 a repo-ban következő szabad BIZ-sorszám —
 *       PROVIZÓRIKUS, a security-standards.md §3 katalógussal (nincs a repóban)
 *       egyeztetendő; eltérés esetén itt a konstans igazítandó (spec-változás, nem
 *       bukás-elfedés).</li>
 *   <li>{@code ClosingWizardStatusDto} bővül: {@code activeWizardId} ÉS {@code activeWizardStatus}
 *       (mindkettő nullable String) — EGYHÍVÁSOS FR-3 szerződés: a frontend az EXPIRED-ágat
 *       ebből dönti el, NEM külön get(activeWizardId) hívásból. Kitöltési szabály:
 *       mai IN_PROGRESS sor → annak id-ja + "IN_PROGRESS"; különben mai EXPIRED sor →
 *       annak id-ja + "EXPIRED"; különben mindkettő null. (A fallback-sorrend a meglévő
 *       findByBranchIdAndStatusAndClosingDate query újrahasznosításával megy — nincs új
 *       repo-metódus ehhez.)</li>
 *   <li>{@code cancel()} auditál: action {@code CLOSING_WIZARD_CANCELLED}, userId = megszakító
 *       (SecurityUtils.getCurrentWorkerCode()), changes tartalmazza az indító worker azonosítóját.</li>
 * </ul>
 *
 * <p>EBBEN A FÁZISBAN MINDEN TESZTNEK BUKNIA KELL (a hivatkozott API-k még nem léteznek —
 * a fájl fordítási hibával piros). Tesztet a bukás elfedésére módosítani TILOS.
 */
@ExtendWith(MockitoExtension.class)
class ClosingWizardStaleSessionFk065Test {

    @Mock private ClosingWizardRepository closingWizardRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private DailySessionRepository dailySessionRepository;
    @Mock private TransactionRepository transactionRepository;
    @Mock private DailyClosingService dailyClosingService;
    @Mock private ObjectMapper objectMapper;
    @Mock private DenominationRepository denominationRepository;
    @Mock private DenominationBalanceRepository denominationBalanceRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private CurrencyStockRepository currencyStockRepository;
    @Mock private SystemParameterService systemParameterService;
    /** FK-065: új service-függőség — az implementációs fázis veszi fel a konstruktorba. */
    @Mock private AuditLogService auditLogService;
    @Mock private DenominationAllowedRepository denominationAllowedRepository;
    // FKH-036 WU-5: az új konstruktor-függőségek mockjai (pitfall 1).
    @Mock private ShipmentRequestRepository shipmentRequestRepository;
    @Mock private ShipmentHandlingFeeRepository shipmentHandlingFeeRepository;
    @InjectMocks private ClosingWizardService service;

    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final UUID COMPANY_ID = UUID.randomUUID();

    /** Surefire-fork örökölt SecurityContext ellen (ld. ClosingWizardServiceTest). */
    @org.junit.jupiter.api.BeforeEach
    @org.junit.jupiter.api.AfterEach
    void clearSecurityContext() {
        org.springframework.security.core.context.SecurityContextHolder.clearContext();
    }

    private static Branch branchOf(UUID branchId, UUID companyId) {
        return Branch.builder()
                .id(branchId)
                .company(Company.builder().id(companyId).build())
                .build();
    }

    private static ClosingWizard inProgressWizard(UUID id, Branch branch, LocalDateTime startedAt) {
        return ClosingWizard.builder()
                .id(id)
                .branch(branch)
                .closingDate(startedAt.toLocalDate())
                .closingType(ClosingType.DAILY)
                .wizardStatus(WizardStatus.IN_PROGRESS)
                .startedByWorker(Worker.builder().id(1L).build())
                .startedAt(startedAt)
                .build();
    }

    // =====================================================================
    // FR-1: auto-lejárat (scheduled feladat service-magja)
    // =====================================================================

    @Test
    @DisplayName("FK-065 FR-1 happy path: 130 perce IN_PROGRESS → EXPIRED; 30 perces érintetlen")
    void autoExpire_staleExpired_freshUntouched() {
        lenient().when(systemParameterService.getValue(eq("CLOSING_WIZARD_AUTO_EXPIRE_MINUTES"), anyString()))
                .thenReturn("120");

        Branch branch = branchOf(BRANCH_ID, COMPANY_ID);
        ClosingWizard stale = inProgressWizard(UUID.randomUUID(), branch,
                LocalDateTime.now().minusMinutes(130));
        ClosingWizard fresh = inProgressWizard(UUID.randomUUID(), branch,
                LocalDateTime.now().minusMinutes(30));

        // A finder a DB-oldali szűrést szimulálja: csak a cutoff előtt indult wizardokat adja
        // vissza. Így ha az implementáció rossz küszöböt számol (pl. 20 perc), a fresh is
        // bekerülne és a lenti asserttel elbukna.
        when(closingWizardRepository.findByWizardStatusAndStartedAtBefore(
                eq(WizardStatus.IN_PROGRESS), any(LocalDateTime.class)))
                .thenAnswer(inv -> {
                    LocalDateTime cutoff = inv.getArgument(1);
                    return List.of(stale, fresh).stream()
                            .filter(w -> w.getStartedAt().isBefore(cutoff))
                            .toList();
                });
        // HIGH-fix kontraktus: az írás feltételes, atomikus UPDATE (transitionIfStale),
        // nem save() — 1 érintett sor = sikeres váltás.
        when(closingWizardRepository.transitionIfStale(
                eq(stale.getId()), eq(WizardStatus.IN_PROGRESS), eq(WizardStatus.EXPIRED),
                any(LocalDateTime.class)))
                .thenReturn(1);

        int count = service.autoExpireStaleWizards();

        assertThat(count).isEqualTo(1);
        assertThat(stale.getWizardStatus()).isEqualTo(WizardStatus.EXPIRED);
        assertThat(fresh.getWizardStatus()).isEqualTo(WizardStatus.IN_PROGRESS);
        verify(closingWizardRepository).transitionIfStale(
                eq(stale.getId()), eq(WizardStatus.IN_PROGRESS), eq(WizardStatus.EXPIRED),
                any(LocalDateTime.class));
        verify(closingWizardRepository, never()).transitionIfStale(
                eq(fresh.getId()), any(), any(), any());
        verify(closingWizardRepository, never()).save(any());

        // A cutoff a 120 perces default köré essen (küszöb-szerződés).
        ArgumentCaptor<LocalDateTime> cutoffCaptor = ArgumentCaptor.forClass(LocalDateTime.class);
        verify(closingWizardRepository).findByWizardStatusAndStartedAtBefore(
                eq(WizardStatus.IN_PROGRESS), cutoffCaptor.capture());
        assertThat(cutoffCaptor.getValue())
                .isAfter(LocalDateTime.now().minusMinutes(121))
                .isBefore(LocalDateTime.now().minusMinutes(119));
    }

    @Test
    @DisplayName("FK-065 FR-1 audit: EXPIRED-váltás → CLOSING_WIZARD_AUTO_EXPIRED bejegyzés, SYSTEM aktorral")
    void autoExpire_writesAuditEntry() {
        lenient().when(systemParameterService.getValue(eq("CLOSING_WIZARD_AUTO_EXPIRE_MINUTES"), anyString()))
                .thenReturn("120");

        UUID wizardId = UUID.randomUUID();
        ClosingWizard stale = inProgressWizard(wizardId, branchOf(BRANCH_ID, COMPANY_ID),
                LocalDateTime.now().minusMinutes(200));

        when(closingWizardRepository.findByWizardStatusAndStartedAtBefore(
                eq(WizardStatus.IN_PROGRESS), any(LocalDateTime.class)))
                .thenReturn(List.of(stale));
        when(closingWizardRepository.transitionIfStale(
                eq(wizardId), eq(WizardStatus.IN_PROGRESS), eq(WizardStatus.EXPIRED),
                any(LocalDateTime.class)))
                .thenReturn(1);

        service.autoExpireStaleWizards();

        // logForCompany: entityType/actor fixen "SYSTEM" (P29 scheduler-minta) —
        // a companyId a wizard SAJÁT branch→company adatából jön, nem SecurityContextből.
        // Az üzenet a repo audit-JSON konvencióját követi: KAT + error_code explicit
        // (zárás-domain precedens: KAT=TX + VV-BIZ-* — ld. osztály-javadoc; a VV-BIZ-011
        // sorszám a §3 katalógussal egyeztetendő, provizórikus).
        ArgumentCaptor<String> auditMessage = ArgumentCaptor.forClass(String.class);
        verify(auditLogService).logForCompany(
                eq("CLOSING_WIZARD_AUTO_EXPIRED"),
                auditMessage.capture(),
                eq(wizardId.toString()),
                eq(COMPANY_ID));
        assertThat(auditMessage.getValue())
                .contains("\"KAT\":\"TX\"")
                .contains("VV-BIZ-011");
    }

    @Test
    @DisplayName("FK-065 FR-1 cross-tenant: több tenant sorai egy körben, cégenkénti audittal, SecurityContext nélkül")
    void autoExpire_crossTenant_noSecurityContext() {
        lenient().when(systemParameterService.getValue(eq("CLOSING_WIZARD_AUTO_EXPIRE_MINUTES"), anyString()))
                .thenReturn("120");

        UUID companyA = UUID.randomUUID();
        UUID companyB = UUID.randomUUID();
        UUID wizardA = UUID.randomUUID();
        UUID wizardB = UUID.randomUUID();
        ClosingWizard staleA = inProgressWizard(wizardA, branchOf(UUID.randomUUID(), companyA),
                LocalDateTime.now().minusMinutes(300));
        ClosingWizard staleB = inProgressWizard(wizardB, branchOf(UUID.randomUUID(), companyB),
                LocalDateTime.now().minusMinutes(400));

        when(closingWizardRepository.findByWizardStatusAndStartedAtBefore(
                eq(WizardStatus.IN_PROGRESS), any(LocalDateTime.class)))
                .thenReturn(List.of(staleA, staleB));
        when(closingWizardRepository.transitionIfStale(
                any(UUID.class), eq(WizardStatus.IN_PROGRESS), eq(WizardStatus.EXPIRED),
                any(LocalDateTime.class)))
                .thenReturn(1);

        // SZÁNDÉKOSAN nincs MockedStatic<SecurityUtils> és a SecurityContext üres:
        // ha az implementáció SecurityUtils.getCurrentCompanyId()-t hívna, az itt
        // ValidationException-nel elbukna (a valós getCurrentCompanyId dob üres kontextusra).
        int count = service.autoExpireStaleWizards();

        assertThat(count).isEqualTo(2);
        assertThat(staleA.getWizardStatus()).isEqualTo(WizardStatus.EXPIRED);
        assertThat(staleB.getWizardStatus()).isEqualTo(WizardStatus.EXPIRED);
        // Pontos, cégenkénti verify a konkrét várt paraméterekkel (a korábbi
        // verifyNoMoreInteractions helyett — extra, pl. kör-összegző bejegyzést
        // ez a teszt már nem tilt).
        verify(auditLogService).logForCompany(
                eq("CLOSING_WIZARD_AUTO_EXPIRED"),
                argThat(msg -> msg.contains("\"KAT\":\"TX\"") && msg.contains("VV-BIZ-011")),
                eq(wizardA.toString()),
                eq(companyA));
        verify(auditLogService).logForCompany(
                eq("CLOSING_WIZARD_AUTO_EXPIRED"),
                argThat(msg -> msg.contains("\"KAT\":\"TX\"") && msg.contains("VV-BIZ-011")),
                eq(wizardB.toString()),
                eq(companyB));
    }

    @Test
    @DisplayName("FK-065 FR-1: közben COMPLETED/CANCELLED-re váltott sor érintetlen marad (idempotens re-check)")
    void autoExpire_completedAndCancelledUntouched() {
        lenient().when(systemParameterService.getValue(eq("CLOSING_WIZARD_AUTO_EXPIRE_MINUTES"), anyString()))
                .thenReturn("120");

        Branch branch = branchOf(BRANCH_ID, COMPANY_ID);
        // Race-szimuláció: a finder-eredménybe kerülés után a sor már nem IN_PROGRESS
        // (a foglaló-minta lock+re-check ágának megfelelője).
        ClosingWizard completed = inProgressWizard(UUID.randomUUID(), branch,
                LocalDateTime.now().minusMinutes(300));
        completed.setWizardStatus(WizardStatus.COMPLETED);
        ClosingWizard cancelled = inProgressWizard(UUID.randomUUID(), branch,
                LocalDateTime.now().minusMinutes(300));
        cancelled.setWizardStatus(WizardStatus.CANCELLED);

        when(closingWizardRepository.findByWizardStatusAndStartedAtBefore(
                eq(WizardStatus.IN_PROGRESS), any(LocalDateTime.class)))
                .thenReturn(List.of(completed, cancelled));

        int count = service.autoExpireStaleWizards();

        assertThat(count).isZero();
        assertThat(completed.getWizardStatus()).isEqualTo(WizardStatus.COMPLETED);
        assertThat(cancelled.getWizardStatus()).isEqualTo(WizardStatus.CANCELLED);
        verify(closingWizardRepository, never()).transitionIfStale(any(), any(), any(), any());
        verify(closingWizardRepository, never()).save(any());
        verifyNoInteractions(auditLogService);
    }

    @Test
    @DisplayName("FK-065 HIGH-fix: konkurens cancel/finalize elnyeri a versenyt — nincs EXPIRED-felülírás, nincs audit")
    void autoExpire_concurrentUserTransitionWins_notOverwritten() {
        lenient().when(systemParameterService.getValue(eq("CLOSING_WIZARD_AUTO_EXPIRE_MINUTES"), anyString()))
                .thenReturn("120");

        Branch branch = branchOf(BRANCH_ID, COMPANY_ID);
        // Mindkét wizard IN_PROGRESS-ként kerül a finder-eredménybe (a SELECT idején még
        // azok voltak), de a feltételes UPDATE pillanatában a felhasználói tranzakció
        // (cancel → CANCELLED, finalize → COMPLETED) már elnyerte a versenyt.
        ClosingWizard cancelledMeanwhile = inProgressWizard(UUID.randomUUID(), branch,
                LocalDateTime.now().minusMinutes(300));
        ClosingWizard completedMeanwhile = inProgressWizard(UUID.randomUUID(), branch,
                LocalDateTime.now().minusMinutes(300));

        when(closingWizardRepository.findByWizardStatusAndStartedAtBefore(
                eq(WizardStatus.IN_PROGRESS), any(LocalDateTime.class)))
                .thenReturn(List.of(cancelledMeanwhile, completedMeanwhile));
        // Az atomikus UPDATE 0 sort érint — a DB-oldali WHERE (wizard_status='IN_PROGRESS')
        // védi a felhasználói állapotot; a stub a konkurens tranzakció hatását szimulálja.
        when(closingWizardRepository.transitionIfStale(
                eq(cancelledMeanwhile.getId()), eq(WizardStatus.IN_PROGRESS), eq(WizardStatus.EXPIRED),
                any(LocalDateTime.class)))
                .thenAnswer(inv -> {
                    cancelledMeanwhile.setWizardStatus(WizardStatus.CANCELLED);
                    return 0;
                });
        when(closingWizardRepository.transitionIfStale(
                eq(completedMeanwhile.getId()), eq(WizardStatus.IN_PROGRESS), eq(WizardStatus.EXPIRED),
                any(LocalDateTime.class)))
                .thenAnswer(inv -> {
                    completedMeanwhile.setWizardStatus(WizardStatus.COMPLETED);
                    return 0;
                });

        int count = service.autoExpireStaleWizards();

        // A felhasználói CANCELLED/COMPLETED állapot NEM íródik felül EXPIRED-re,
        // és 0 érintett sornál EXPIRED-audit sem készül.
        assertThat(count).isZero();
        assertThat(cancelledMeanwhile.getWizardStatus()).isEqualTo(WizardStatus.CANCELLED);
        assertThat(completedMeanwhile.getWizardStatus()).isEqualTo(WizardStatus.COMPLETED);
        verify(closingWizardRepository, never()).save(any());
        verifyNoInteractions(auditLogService);
    }

    @Test
    @DisplayName("FK-065 MEDIUM-fix: küszöb-clamp — negatív/nulla → 30 perc, túl nagy → 1440 perc")
    void autoExpire_expireMinutesClampedToRange() {
        when(systemParameterService.getValue(eq("CLOSING_WIZARD_AUTO_EXPIRE_MINUTES"), anyString()))
                .thenReturn("-5", "0", "100000");
        when(closingWizardRepository.findByWizardStatusAndStartedAtBefore(
                eq(WizardStatus.IN_PROGRESS), any(LocalDateTime.class)))
                .thenReturn(List.of());

        service.autoExpireStaleWizards();
        service.autoExpireStaleWizards();
        service.autoExpireStaleWizards();

        ArgumentCaptor<LocalDateTime> cutoffs = ArgumentCaptor.forClass(LocalDateTime.class);
        verify(closingWizardRepository, times(3)).findByWizardStatusAndStartedAtBefore(
                eq(WizardStatus.IN_PROGRESS), cutoffs.capture());
        List<LocalDateTime> captured = cutoffs.getAllValues();
        // -5 és 0 → clamp a 30 perces alsó határra
        assertThat(captured.get(0))
                .isAfter(LocalDateTime.now().minusMinutes(31))
                .isBefore(LocalDateTime.now().minusMinutes(29));
        assertThat(captured.get(1))
                .isAfter(LocalDateTime.now().minusMinutes(31))
                .isBefore(LocalDateTime.now().minusMinutes(29));
        // 100000 → clamp az 1440 perces felső határra
        assertThat(captured.get(2))
                .isAfter(LocalDateTime.now().minusMinutes(1441))
                .isBefore(LocalDateTime.now().minusMinutes(1439));
    }

    // =====================================================================
    // FR-2: getClosingStatus → activeWizardId
    // =====================================================================

    @Test
    @DisplayName("FK-065 FR-2 happy path: mai IN_PROGRESS → id+IN_PROGRESS; nincs → null; mai EXPIRED → id+EXPIRED")
    void getClosingStatus_activeWizardIdFilledOrNull() {
        LocalDate today = LocalDate.now();
        UUID activeId = UUID.randomUUID();
        Branch branch = branchOf(BRANCH_ID, COMPANY_ID);

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(branchRepository.findByIdAndCompanyId(BRANCH_ID, COMPANY_ID))
                    .thenReturn(Optional.of(branch));
            when(denominationBalanceRepository.existsByBranchIdAndDateAndCategory(
                    BRANCH_ID, today, DenominationCategory.EVENING)).thenReturn(false);
            when(denominationBalanceRepository.sumActualStockByCurrency(
                    BRANCH_ID, today, DenominationCategory.EVENING)).thenReturn(List.of());
            when(cashBalanceRepository.findByBranchIdAndCompanyId(BRANCH_ID, COMPANY_ID))
                    .thenReturn(List.of());

            // 1) Mai IN_PROGRESS sor → id + "IN_PROGRESS" (EXPIRED-fallback nem fut, ezért lenient)
            when(closingWizardRepository.findByBranchIdAndStatusAndClosingDate(
                    BRANCH_ID, WizardStatus.IN_PROGRESS, today))
                    .thenReturn(List.of(inProgressWizard(activeId, branch,
                            LocalDateTime.now().minusMinutes(10))));
            lenient().when(closingWizardRepository.findByBranchIdAndStatusAndClosingDate(
                    BRANCH_ID, WizardStatus.EXPIRED, today)).thenReturn(List.of());

            ClosingWizardStatusDto dto = service.getClosingStatus(BRANCH_ID, today);
            assertThat(dto.getActiveWizardId()).isEqualTo(activeId.toString());
            assertThat(dto.getActiveWizardStatus()).isEqualTo("IN_PROGRESS");

            // 2) Se aktív, se EXPIRED sor → mindkét mező null
            when(closingWizardRepository.findByBranchIdAndStatusAndClosingDate(
                    BRANCH_ID, WizardStatus.IN_PROGRESS, today))
                    .thenReturn(List.of());
            ClosingWizardStatusDto empty = service.getClosingStatus(BRANCH_ID, today);
            assertThat(empty.getActiveWizardId()).isNull();
            assertThat(empty.getActiveWizardStatus()).isNull();

            // 3) Nincs IN_PROGRESS, de van mai EXPIRED → id + "EXPIRED" (egyhívásos FR-3:
            // a frontend ebből dönti el az EXPIRED-ágat, nem külön get() hívásból)
            UUID expiredId = UUID.randomUUID();
            ClosingWizard expiredWizard = inProgressWizard(expiredId, branch,
                    LocalDateTime.now().minusHours(5));
            expiredWizard.setWizardStatus(WizardStatus.EXPIRED);
            when(closingWizardRepository.findByBranchIdAndStatusAndClosingDate(
                    BRANCH_ID, WizardStatus.EXPIRED, today)).thenReturn(List.of(expiredWizard));
            ClosingWizardStatusDto afterExpiry = service.getClosingStatus(BRANCH_ID, today);
            assertThat(afterExpiry.getActiveWizardId()).isEqualTo(expiredId.toString());
            assertThat(afterExpiry.getActiveWizardStatus()).isEqualTo("EXPIRED");
        }
    }

    @Test
    @DisplayName("FK-065 FR-2 cross-tenant: más cég aktív wizardja nem szivárog a válaszba")
    void getClosingStatus_crossTenant_noLeak() {
        LocalDate today = LocalDate.now();
        UUID foreignBranchId = UUID.randomUUID();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            // (a) Idegen cég branch-ére kért státusz: a company-szkópolt branch-lookup
            // üres → fail-closed ResourceNotFound, a wizard-query el sem indulhat.
            when(branchRepository.findByIdAndCompanyId(foreignBranchId, COMPANY_ID))
                    .thenReturn(Optional.empty());
            assertThatThrownBy(() -> service.getClosingStatus(foreignBranchId, today))
                    .isInstanceOf(ResourceNotFoundException.class);
            verify(closingWizardRepository, never()).findByBranchIdAndStatusAndClosingDate(
                    eq(foreignBranchId), any(), any());

            // (b) Saját branch, de a (branch-szkópolt) wizard-query üres — más cég
            // wizardja nem jelenhet meg sem activeWizardId-ként, sem statusként.
            // (any() státusz: az IN_PROGRESS és az EXPIRED-fallback query-t is lefedi.)
            Branch own = branchOf(BRANCH_ID, COMPANY_ID);
            when(branchRepository.findByIdAndCompanyId(BRANCH_ID, COMPANY_ID))
                    .thenReturn(Optional.of(own));
            when(denominationBalanceRepository.existsByBranchIdAndDateAndCategory(
                    BRANCH_ID, today, DenominationCategory.EVENING)).thenReturn(false);
            when(denominationBalanceRepository.sumActualStockByCurrency(
                    BRANCH_ID, today, DenominationCategory.EVENING)).thenReturn(List.of());
            when(cashBalanceRepository.findByBranchIdAndCompanyId(BRANCH_ID, COMPANY_ID))
                    .thenReturn(List.of());
            when(closingWizardRepository.findByBranchIdAndStatusAndClosingDate(
                    eq(BRANCH_ID), any(), eq(today))).thenReturn(List.of());

            ClosingWizardStatusDto ownDto = service.getClosingStatus(BRANCH_ID, today);
            assertThat(ownDto.getActiveWizardId()).isNull();
            assertThat(ownDto.getActiveWizardStatus()).isNull();
        }
    }

    // =====================================================================
    // Manuális megszakítás auditja
    // =====================================================================

    @Test
    @DisplayName("FK-065: cancel() auditja rögzíti az indítót ÉS a megszakítót (audit_log, nem új oszlop)")
    void cancel_auditsInitiatorAndCanceller() {
        UUID wizardId = UUID.randomUUID();
        Worker starter = Worker.builder().id(42L).build();
        ClosingWizard wizard = ClosingWizard.builder()
                .id(wizardId)
                .branch(branchOf(BRANCH_ID, COMPANY_ID))
                .closingDate(LocalDate.now())
                // Fixture-pótlás (user-jóváhagyással): kötelező NOT NULL mező, a toDto igényli.
                .closingType(ClosingType.DAILY)
                .wizardStatus(WizardStatus.IN_PROGRESS)
                .startedByWorker(starter)
                .startedAt(LocalDateTime.now().minusMinutes(15))
                .build();

        when(closingWizardRepository.findByIdWithSteps(wizardId)).thenReturn(Optional.of(wizard));
        when(closingWizardRepository.save(any(ClosingWizard.class)))
                .thenAnswer(inv -> inv.getArgument(0));
        // LOW-fix kontraktus: a changes JSON ObjectMapper-rel serializálódik (escape-elt),
        // nem kézi string-fűzéssel — a mock valós mapperre delegál.
        when(objectMapper.writeValueAsString(any()))
                .thenAnswer(inv -> new ObjectMapper().writeValueAsString((Object) inv.getArgument(0)));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W-CANCEL");

            service.cancel(wizardId);
        }

        // 10-argumentumos log: userId = megszakító (aktor), changes tartalmazza az indítót.
        ArgumentCaptor<String> changes = ArgumentCaptor.forClass(String.class);
        verify(auditLogService).log(
                eq("CLOSING_WIZARD_CANCELLED"),
                eq("ClosingWizard"),
                eq(wizardId.toString()),
                eq("W-CANCEL"),
                any(),
                any(),
                any(),
                changes.capture(),
                any(),
                any());
        assertThat(changes.getValue()).contains("42"); // az indító worker azonosítója
    }

    // =====================================================================
    // EXPIRED: nincs folytatás
    // =====================================================================

    @Test
    @DisplayName("FK-065: EXPIRED wizardon a folytatás (navigate) elutasítva — nem éleszthető újra")
    void navigate_onExpiredWizard_rejected() {
        UUID wizardId = UUID.randomUUID();
        ClosingWizard expired = ClosingWizard.builder()
                .id(wizardId)
                .branch(branchOf(BRANCH_ID, COMPANY_ID))
                .closingDate(LocalDate.now().minusDays(1))
                .wizardStatus(WizardStatus.EXPIRED)
                .totalSteps(9)
                .build();

        when(closingWizardRepository.findByIdWithSteps(wizardId)).thenReturn(Optional.of(expired));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);

            assertThatThrownBy(() -> service.navigate(wizardId, 2))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("nem aktív");
        }
        assertThat(expired.getWizardStatus()).isEqualTo(WizardStatus.EXPIRED);
        verify(closingWizardRepository, never()).save(any());
    }

    // =====================================================================
    // Codex HIGH: optimista lock (@Version) — user-facing írások vs. scheduler
    // =====================================================================

    private ClosingWizard inProgressWizardForConflict(UUID wizardId) {
        return ClosingWizard.builder()
                .id(wizardId)
                .branch(branchOf(BRANCH_ID, COMPANY_ID))
                .closingDate(LocalDate.now())
                .closingType(ClosingType.DAILY)
                .wizardStatus(WizardStatus.IN_PROGRESS)
                .startedByWorker(Worker.builder().id(1L).build())
                .startedAt(LocalDateTime.now().minusHours(3))
                .totalSteps(9)
                .build();
    }

    @Test
    @DisplayName("FK-065 Codex HIGH: finalizeClosing közben EXPIRED-re váltott sorra → kezelt konfliktus, nem COMPLETED")
    void finalizeClosing_concurrentExpiry_translatedConflict() {
        UUID wizardId = UUID.randomUUID();
        ClosingWizard wizard = inProgressWizardForConflict(wizardId);

        when(closingWizardRepository.findByIdWithSteps(wizardId)).thenReturn(Optional.of(wizard));
        when(workerRepository.findById(2L)).thenReturn(Optional.of(Worker.builder().id(2L).build()));
        when(denominationBalanceRepository.sumActualStockByCurrency(
                BRANCH_ID, LocalDate.now(), DenominationCategory.EVENING)).thenReturn(List.of());
        when(cashBalanceRepository.findByBranchIdAndCompanyId(BRANCH_ID, COMPANY_ID))
                .thenReturn(List.of());
        lenient().when(systemParameterService.getValue(eq("CLOSING_DISCREPANCY_EXPLANATION_REQUIRED"), anyString()))
                .thenReturn("false");
        when(dailyClosingService.startDailyClosing(LocalDate.now()))
                .thenReturn(DailyClosingService.ClosingWizardResult.builder()
                        .allPassed(true)
                        .steps(List.of())
                        .build());
        // A verzió-ütközést a scheduler közbeni EXPIRED-váltása okozza:
        when(closingWizardRepository.save(any(ClosingWizard.class)))
                .thenThrow(new ObjectOptimisticLockingFailureException(ClosingWizard.class, wizardId));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThatThrownBy(() -> service.finalizeClosing(wizardId, 2L))
                    .isInstanceOf(jakarta.persistence.OptimisticLockException.class)
                    .hasMessageContaining("közben megváltozott");
        }
    }

    @Test
    @DisplayName("FK-065 Codex HIGH: cancel() verzió-ütközésnél kezelt konfliktus, audit nélkül")
    void cancel_concurrentExpiry_translatedConflict() {
        UUID wizardId = UUID.randomUUID();
        ClosingWizard wizard = inProgressWizardForConflict(wizardId);

        when(closingWizardRepository.findByIdWithSteps(wizardId)).thenReturn(Optional.of(wizard));
        when(closingWizardRepository.save(any(ClosingWizard.class)))
                .thenThrow(new ObjectOptimisticLockingFailureException(ClosingWizard.class, wizardId));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);

            assertThatThrownBy(() -> service.cancel(wizardId))
                    .isInstanceOf(jakarta.persistence.OptimisticLockException.class)
                    .hasMessageContaining("közben megváltozott");
        }
        // Meghiúsult megszakításról nem készülhet CANCELLED-audit
        verifyNoInteractions(auditLogService);
    }

    @Test
    @DisplayName("FK-065 Codex HIGH: navigate() verzió-ütközésnél kezelt konfliktus")
    void navigate_concurrentExpiry_translatedConflict() {
        UUID wizardId = UUID.randomUUID();
        ClosingWizard wizard = inProgressWizardForConflict(wizardId);

        when(closingWizardRepository.findByIdWithSteps(wizardId)).thenReturn(Optional.of(wizard));
        when(closingWizardRepository.save(any(ClosingWizard.class)))
                .thenThrow(new ObjectOptimisticLockingFailureException(ClosingWizard.class, wizardId));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);

            assertThatThrownBy(() -> service.navigate(wizardId, 2))
                    .isInstanceOf(jakarta.persistence.OptimisticLockException.class)
                    .hasMessageContaining("közben megváltozott");
        }
    }

    @Test
    @DisplayName("FK-065 Codex HIGH: a transitionIfStale SET ága a version-t is emeli + az entitáson @Version van")
    void transitionIfStale_queryIncrementsVersion() throws NoSuchMethodException, NoSuchFieldException {
        // A JPQL bulk update a @Version mezőt magától NEM inkrementálja — a SET ágban
        // kötelező a version + 1, különben a user-oldali optimista lock nem látná a
        // scheduler írását. (Valós-DB integrációs teszt a repo Testcontainers-mintájával
        // CI-ben futtatható; H2-n a jsonb-s entitáskészlet nem áll fel.)
        org.springframework.data.jpa.repository.Query query = ClosingWizardRepository.class
                .getMethod("transitionIfStale",
                        UUID.class, WizardStatus.class, WizardStatus.class, LocalDateTime.class)
                .getAnnotation(org.springframework.data.jpa.repository.Query.class);
        assertThat(query).isNotNull();
        assertThat(query.value())
                .contains("cw.version = cw.version + 1")
                .contains("cw.wizardStatus = :expectedStatus")
                .contains("cw.startedAt < :startedBefore");

        assertThat(ClosingWizard.class.getDeclaredField("version")
                .getAnnotation(jakarta.persistence.Version.class))
                .as("A ClosingWizard.version mezőn @Version annotáció kötelező")
                .isNotNull();
    }
}
