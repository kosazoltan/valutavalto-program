package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.CustomerScreeningLogDto;
import hu.puzzleir.valuta.dto.SuspicionReportRequest;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Customer;
import hu.puzzleir.valuta.entity.CustomerScreeningLog;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CustomerRepository;
import hu.puzzleir.valuta.repository.CustomerRestrictionRepository;
import hu.puzzleir.valuta.repository.CustomerScreeningLogRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
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

/**
 * EXCMD b9-korlevelek FR-03: pénztárosi gyanú-bejelentés (SAR) tesztek.
 */
@ExtendWith(MockitoExtension.class)
class CustomerControlSuspicionReportTest {

    @Mock private CustomerRestrictionRepository restrictionRepository;
    @Mock private CustomerScreeningLogRepository screeningLogRepository;
    @Mock private TransactionRepository transactionRepository;
    @Mock private CustomerRepository customerRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private NotificationService notificationService;
    @Mock private AuditLogService auditLogService;

    @InjectMocks
    private CustomerControlService service;

    private static final UUID COMPANY_A = UUID.randomUUID();
    private static final UUID COMPANY_B = UUID.randomUUID();

    private MockedStatic<SecurityUtils> sec;

    @BeforeEach
    void setUp() {
        sec = Mockito.mockStatic(SecurityUtils.class);
        sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_A);
        sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(77L);
    }

    @AfterEach
    void tearDown() {
        sec.close();
    }

    @Test
    @DisplayName("Törzsbeli ügyfél: screening-log SUSPICION/FLAGGED + supervisor-notify + audit")
    void reportsSuspicionForKnownCustomer() {
        Customer customer = Customer.builder().id(42L).name("Gyanús Géza")
                .company(Company.builder().id(COMPANY_A).code("EBC").build()).build();
        when(customerRepository.findById(42L)).thenReturn(Optional.of(customer));
        when(screeningLogRepository.save(any(CustomerScreeningLog.class)))
                .thenAnswer(inv -> {
                    CustomerScreeningLog l = inv.getArgument(0);
                    l.setId(UUID.randomUUID());
                    return l;
                });
        Worker supervisor = Worker.builder().id(10L).company(customer.getCompany())
                .code("S10").name("Vezető").role(WorkerRole.SUPERVISOR).active(true).build();
        when(workerRepository.findSupervisorsAndAbove(COMPANY_A)).thenReturn(List.of(supervisor));

        CustomerScreeningLogDto dto = service.reportSuspicion(SuspicionReportRequest.builder()
                .customerId(42L)
                .hufAmount(new BigDecimal("2500000"))
                .suspicionSigns("PIN-kódot papírról olvasta; harmadik kártyás váltás ma")
                .build());

        assertThat(dto.getScreeningType()).isEqualTo("SUSPICION");
        assertThat(dto.getResult()).isEqualTo("FLAGGED");
        assertThat(dto.getDetails()).contains("Gyanús Géza").contains("PIN-kódot");
        verify(notificationService).sendToWorker(eq(10L), anyString(), contains("Gyanús Géza"), eq("URGENT"));
        verify(auditLogService).log(eq("CUSTOMER_SUSPICION_REPORT"), contains("GYANÚ-BEJELENTÉS"), anyString());
    }

    @Test
    @DisplayName("Cross-tenant ügyfél: 404, semmi nem íródik")
    void rejectsCrossTenantCustomer() {
        Customer foreign = Customer.builder().id(43L).name("Másik Cégé")
                .company(Company.builder().id(COMPANY_B).code("BEST").build()).build();
        when(customerRepository.findById(43L)).thenReturn(Optional.of(foreign));

        assertThatThrownBy(() -> service.reportSuspicion(SuspicionReportRequest.builder()
                .customerId(43L).suspicionSigns("jel").build()))
                .isInstanceOf(ResourceNotFoundException.class);
        verify(screeningLogRepository, never()).save(any());
        verify(notificationService, never()).sendToWorker(anyLong(), anyString(), anyString(), anyString());
    }

    @Test
    @DisplayName("Ismeretlen ügyfél név nélkül: ValidationException")
    void requiresNameForUnknownCustomer() {
        assertThatThrownBy(() -> service.reportSuspicion(SuspicionReportRequest.builder()
                .suspicionSigns("gyanús viselkedés").build()))
                .isInstanceOf(ValidationException.class);
        verify(screeningLogRepository, never()).save(any());
    }

    @Test
    @DisplayName("Ismeretlen ügyfél névvel: rögzül, customerId=null")
    void reportsSuspicionForUnknownCustomerWithName() {
        when(screeningLogRepository.save(any(CustomerScreeningLog.class)))
                .thenAnswer(inv -> {
                    CustomerScreeningLog l = inv.getArgument(0);
                    l.setId(UUID.randomUUID());
                    return l;
                });
        when(workerRepository.findSupervisorsAndAbove(COMPANY_A)).thenReturn(List.of());

        CustomerScreeningLogDto dto = service.reportSuspicion(SuspicionReportRequest.builder()
                .customerName("Ismeretlen Imre")
                .suspicionSigns("sorozatos kis összegű váltások")
                .build());

        assertThat(dto.getCustomerId()).isNull();
        assertThat(dto.getDetails()).contains("Ismeretlen Imre");
    }
}
