package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.bankorder.BankOrderDto;
import hu.puzzleir.valuta.dto.bankorder.CreateBankOrderRequest;
import hu.puzzleir.valuta.entity.BankOrder;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.repository.BankOrderRepository;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.lang.reflect.Method;
import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@DisplayName("BankOrderService")
class BankOrderServiceTest {

    @Mock private BankOrderRepository bankOrderRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private NotificationService notificationService;

    @InjectMocks private BankOrderService service;

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("create: EMERGENCY ertesites hiba eseten is letrehozza a banki rendelest")
    void createEmergencyOrderNotificationFailureDoesNotAbortOrder() {
        UUID companyId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        UUID orderId = UUID.randomUUID();
        long workerId = 11L;
        long supervisorId = 22L;

        Company company = Company.builder().id(companyId).code("EXC").name("Exclusive Change").build();
        Branch branch = Branch.builder()
                .id(branchId)
                .code("BUD")
                .name("Budapest")
                .company(company)
                .build();
        Currency currency = Currency.builder().id(978L).code("EUR").name("Euro").build();
        Worker requester = Worker.builder()
                .id(workerId)
                .code("P001")
                .name("Kasszas Teszt")
                .company(company)
                .branch(branch)
                .role(WorkerRole.CASHIER)
                .active(true)
                .build();
        Worker supervisor = Worker.builder()
                .id(supervisorId)
                .code("F001")
                .name("Fonok Teszt")
                .company(company)
                .branch(branch)
                .role(WorkerRole.SUPERVISOR)
                .active(true)
                .build();

        TestingAuthenticationToken auth = new TestingAuthenticationToken("P001", "n/a");
        auth.setDetails(new WorkerAuthenticationDetails(workerId, companyId, branchId, "CASHIER"));
        SecurityContextHolder.getContext().setAuthentication(auth);

        CreateBankOrderRequest request = new CreateBankOrderRequest();
        request.setBranchId(branchId);
        request.setCurrencyId(978L);
        request.setAmount(new BigDecimal("1234.56"));
        request.setUrgency(BankOrder.Urgency.EMERGENCY);

        when(workerRepository.findById(workerId)).thenReturn(Optional.of(requester));
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(currencyRepository.findById(978L)).thenReturn(Optional.of(currency));
        when(bankOrderRepository.save(any(BankOrder.class))).thenAnswer(invocation -> {
            BankOrder order = invocation.getArgument(0);
            order.setId(orderId);
            return order;
        });
        when(workerRepository.findSupervisorsAndAbove(companyId)).thenReturn(List.of(supervisor));
        when(notificationService.sendToWorker(eq(supervisorId), anyString(), anyString(), eq("URGENT")))
                .thenThrow(new IllegalStateException("notification queue down"));

        BankOrderDto dto = service.create(request);

        assertThat(dto.getId()).isEqualTo(orderId);
        assertThat(dto.getStatus()).isEqualTo(BankOrder.Status.PENDING);
        assertThat(dto.getUrgency()).isEqualTo(BankOrder.Urgency.EMERGENCY);

        ArgumentCaptor<BankOrder> savedOrder = ArgumentCaptor.forClass(BankOrder.class);
        verify(bankOrderRepository).save(savedOrder.capture());
        assertThat(savedOrder.getValue().getRequestedBy()).isEqualTo(requester);
        verify(notificationService)
                .sendToWorker(eq(supervisorId), anyString(), anyString(), eq("URGENT"));
    }

    @Test
    @DisplayName("auditLogValue: CR/LF szures utan hosszt is limital")
    void auditLogValueSanitizesAndTruncates() throws Exception {
        Method auditLogValue = BankOrderService.class.getDeclaredMethod("auditLogValue", String.class);
        auditLogValue.setAccessible(true);

        String input = "REF\r\n" + "x".repeat(400);
        String result = (String) auditLogValue.invoke(null, input);

        assertThat(result)
                .doesNotContain("\r")
                .doesNotContain("\n")
                .hasSize(300)
                .endsWith("...");
    }
}
