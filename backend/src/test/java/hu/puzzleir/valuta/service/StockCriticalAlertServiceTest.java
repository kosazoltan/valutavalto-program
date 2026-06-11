package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class StockCriticalAlertServiceTest {

    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private NotificationService notificationService;
    @Mock private AuditLogService auditLogService;

    @InjectMocks
    private StockCriticalAlertService service;

    private static final LocalDate TARGET_DATE = LocalDate.of(2026, 6, 11);

    @Test
    @DisplayName("Küszöb alatti egyenlegnél a company supervisorok URGENT értesítést kapnak + audit log készül")
    void alertsSupervisorsWhenBalanceBelowThreshold() {
        Company company = company("EBC");
        Branch branch = branch(company, "BR105");
        CashBalance critical = balance(company, branch, "EUR", "500.00", "2000.00");
        Worker supervisor = worker(company, 10L, WorkerRole.SUPERVISOR);
        Worker manager = worker(company, 11L, WorkerRole.MANAGER);

        when(cashBalanceRepository.findAllLowBalances()).thenReturn(List.of(critical));
        when(auditLogService.existsByActionAndReferenceForCompany(
                StockCriticalAlertService.AUDIT_ACTION,
                company.getId() + ":" + TARGET_DATE,
                company.getId())).thenReturn(false);
        when(workerRepository.findSupervisorsAndAbove(company.getId()))
                .thenReturn(List.of(supervisor, manager));

        StockCriticalAlertService.StockCriticalAlertResult result = service.checkDate(TARGET_DATE);

        assertThat(result.criticalBalances()).isEqualTo(1);
        assertThat(result.companiesAlerted()).isEqualTo(1);
        assertThat(result.notificationsSent()).isEqualTo(2);
        assertThat(result.skippedAlreadyAudited()).isZero();
        verify(notificationService).sendToWorker(
                eq(10L), anyString(),
                contains("BR105 EUR"),
                eq(StockCriticalAlertService.NOTIFICATION_TYPE));
        verify(notificationService).sendToWorker(
                eq(11L), anyString(), anyString(),
                eq(StockCriticalAlertService.NOTIFICATION_TYPE));
        verify(auditLogService).logForCompany(
                eq(StockCriticalAlertService.AUDIT_ACTION),
                any(String.class),
                eq(company.getId() + ":" + TARGET_DATE),
                eq(company.getId()));
    }

    @Test
    @DisplayName("Aznap már auditált cégnek nem megy ismételt alert (idempotencia)")
    void skipsCompanyAlreadyAuditedToday() {
        Company company = company("EBC");
        CashBalance critical = balance(company, branch(company, "BR105"), "USD", "0.00", "1000.00");

        when(cashBalanceRepository.findAllLowBalances()).thenReturn(List.of(critical));
        when(auditLogService.existsByActionAndReferenceForCompany(
                StockCriticalAlertService.AUDIT_ACTION,
                company.getId() + ":" + TARGET_DATE,
                company.getId())).thenReturn(true);

        StockCriticalAlertService.StockCriticalAlertResult result = service.checkDate(TARGET_DATE);

        assertThat(result.criticalBalances()).isEqualTo(1);
        assertThat(result.companiesAlerted()).isZero();
        assertThat(result.notificationsSent()).isZero();
        assertThat(result.skippedAlreadyAudited()).isEqualTo(1);
        verify(notificationService, never()).sendToWorker(anyLong(), anyString(), anyString(), anyString());
    }

    @Test
    @DisplayName("Nincs küszöb alatti egyenleg — nincs értesítés, nincs audit")
    void noAlertWhenNoCriticalBalances() {
        when(cashBalanceRepository.findAllLowBalances()).thenReturn(List.of());

        StockCriticalAlertService.StockCriticalAlertResult result = service.checkDate(TARGET_DATE);

        assertThat(result.criticalBalances()).isZero();
        assertThat(result.companiesAlerted()).isZero();
        assertThat(result.notificationsSent()).isZero();
        verify(notificationService, never()).sendToWorker(anyLong(), anyString(), anyString(), anyString());
        verify(auditLogService, never()).logForCompany(anyString(), anyString(), anyString(), any(UUID.class));
    }

    @Test
    @DisplayName("Multi-tenant: cégenként külön alert, csak a saját supervisoroknak")
    void alertsAreIsolatedPerCompany() {
        Company companyA = company("EBC");
        Company companyB = company("BEST");
        CashBalance criticalA = balance(companyA, branch(companyA, "A01"), "EUR", "100.00", "500.00");
        CashBalance criticalB = balance(companyB, branch(companyB, "B01"), "CHF", "50.00", "300.00");
        Worker supervisorA = worker(companyA, 20L, WorkerRole.SUPERVISOR);
        Worker supervisorB = worker(companyB, 30L, WorkerRole.ADMIN);

        when(cashBalanceRepository.findAllLowBalances()).thenReturn(List.of(criticalA, criticalB));
        when(auditLogService.existsByActionAndReferenceForCompany(anyString(), anyString(), any(UUID.class)))
                .thenReturn(false);
        when(workerRepository.findSupervisorsAndAbove(companyA.getId())).thenReturn(List.of(supervisorA));
        when(workerRepository.findSupervisorsAndAbove(companyB.getId())).thenReturn(List.of(supervisorB));

        StockCriticalAlertService.StockCriticalAlertResult result = service.checkDate(TARGET_DATE);

        assertThat(result.criticalBalances()).isEqualTo(2);
        assertThat(result.companiesAlerted()).isEqualTo(2);
        assertThat(result.notificationsSent()).isEqualTo(2);
        // A cég supervisora csak a SAJÁT cég irodáját látja az üzenetben
        verify(notificationService).sendToWorker(
                eq(20L), anyString(), contains("A01 EUR"), anyString());
        verify(notificationService).sendToWorker(
                eq(30L), anyString(), contains("B01 CHF"), anyString());
    }

    @Test
    @DisplayName("Null targetDate — IllegalArgumentException")
    void rejectsNullTargetDate() {
        assertThatThrownBy(() -> service.checkDate(null))
                .isInstanceOf(IllegalArgumentException.class);
    }

    // ============ HELPERS ============

    private Company company(String code) {
        return Company.builder()
                .id(UUID.randomUUID())
                .code(code)
                .name(code + " Zrt.")
                .build();
    }

    private Branch branch(Company company, String code) {
        return Branch.builder()
                .id(UUID.randomUUID())
                .company(company)
                .code(code)
                .name("Teszt iroda " + code)
                .isActive(true)
                .build();
    }

    private Worker worker(Company company, Long id, WorkerRole role) {
        return Worker.builder()
                .id(id)
                .company(company)
                .code("W" + id)
                .name("Vezető " + id)
                .role(role)
                .active(true)
                .build();
    }

    private CashBalance balance(Company company, Branch branch, String currencyCode,
                                String current, String min) {
        return CashBalance.builder()
                .id((long) (Math.abs(currencyCode.hashCode()) % 1000 + 1))
                .company(company)
                .branch(branch)
                .currency(Currency.builder().id((long) currencyCode.hashCode()).code(currencyCode).build())
                .currentBalance(new BigDecimal(current))
                .minBalance(new BigDecimal(min))
                .build();
    }
}
