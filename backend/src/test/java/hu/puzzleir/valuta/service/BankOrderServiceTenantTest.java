package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.bankorder.CreateBankOrderRequest;
import hu.puzzleir.valuta.entity.BankOrder;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BankOrderRepository;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Audit P0 fix (2026-05-19) cross-tenant izoláció verifikációja a BankOrderService-en.
 *
 * <p>Korábbi IDOR-finding: a {@code BankOrderService} {@code create}, {@code approve},
 * {@code execute}, {@code cancel}, {@code get}, {@code list} metódusok csak Spring Security
 * role-check-et használtak ({@code hasAnyRole('SUPERVISOR','MANAGER','ADMIN')}) — semmilyen
 * company_id szűrést. Company A SUPERVISOR ismert UUID-vel APPROVE-olhatott Company B bank
 * order-t, ill. a {@code GET /api/v1/bank-orders} listázás összes cég bank order-jeit visszaadta.</p>
 *
 * <p>Pattern: a {@code RateApprovalServiceTenantTest} mintáját követi (a RateApproval audit
 * P0.2 fix-pattern 2026-05-17 óta él).</p>
 */
@ExtendWith(MockitoExtension.class)
class BankOrderServiceTenantTest {

    private static final UUID COMPANY_A = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID COMPANY_B = UUID.fromString("22222222-2222-2222-2222-222222222222");
    private static final UUID ORDER_ID = UUID.fromString("33333333-3333-3333-3333-333333333333");
    private static final UUID BRANCH_B_ID = UUID.fromString("44444444-4444-4444-4444-444444444444");

    @Mock private BankOrderRepository bankOrderRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private NotificationService notificationService;

    @InjectMocks private BankOrderService bankOrderService;

    @Test
    @DisplayName("get — Company A user NEM lát Company B bank order-t (404)")
    void get_otherCompanyOrder_throws() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_A);

            // A tenant-safe lookup empty-t ad vissza ha az ID másik cég branch-éhez tartozik
            when(bankOrderRepository.findByIdAndBranch_Company_Id(ORDER_ID, COMPANY_A))
                    .thenReturn(Optional.empty());

            assertThatThrownBy(() -> bankOrderService.get(ORDER_ID))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("Bank order");

            // Verify hogy a leaky findById() NEM hívódott
            verify(bankOrderRepository, never()).findById(ORDER_ID);
        }
    }

    @Test
    @DisplayName("approve — Company A user NEM approve-ol Company B bank order-t")
    void approve_otherCompanyOrder_throws() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_A);

            when(bankOrderRepository.findByIdAndBranch_Company_Id(ORDER_ID, COMPANY_A))
                    .thenReturn(Optional.empty());

            assertThatThrownBy(() -> bankOrderService.approve(ORDER_ID))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("Bank order");

            verify(bankOrderRepository, never()).findById(ORDER_ID);
            verify(bankOrderRepository, never()).save(any(BankOrder.class));
        }
    }

    @Test
    @DisplayName("execute — Company A user NEM executál Company B bank order-t")
    void execute_otherCompanyOrder_throws() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_A);

            when(bankOrderRepository.findByIdAndBranch_Company_Id(ORDER_ID, COMPANY_A))
                    .thenReturn(Optional.empty());

            assertThatThrownBy(() -> bankOrderService.execute(ORDER_ID, "BANK-REF-001"))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("Bank order");

            verify(bankOrderRepository, never()).findById(ORDER_ID);
            verify(bankOrderRepository, never()).save(any(BankOrder.class));
        }
    }

    @Test
    @DisplayName("cancel — Company A user NEM cancel-el Company B bank order-t")
    void cancel_otherCompanyOrder_throws() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_A);

            when(bankOrderRepository.findByIdAndBranch_Company_Id(ORDER_ID, COMPANY_A))
                    .thenReturn(Optional.empty());

            assertThatThrownBy(() -> bankOrderService.cancel(ORDER_ID, "okok"))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("Bank order");

            verify(bankOrderRepository, never()).findById(ORDER_ID);
            verify(bankOrderRepository, never()).save(any(BankOrder.class));
        }
    }

    @Test
    @DisplayName("create — Company A user NEM hozhat létre bank order-t Company B branch-en (cross-tenant)")
    void create_otherCompanyBranch_throws() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_A);
            secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(1L);

            // Company B branch
            Company companyB = new Company();
            companyB.setId(COMPANY_B);
            Branch branchB = new Branch();
            branchB.setId(BRANCH_B_ID);
            branchB.setCode("B-OTHER");
            branchB.setCompany(companyB);

            when(workerRepository.findById(1L)).thenReturn(Optional.of(new hu.puzzleir.valuta.entity.Worker()));
            when(branchRepository.findById(BRANCH_B_ID)).thenReturn(Optional.of(branchB));

            CreateBankOrderRequest req = new CreateBankOrderRequest();
            req.setBranchId(BRANCH_B_ID);
            // currencyId típusát NEM állítjuk be — a tenant guard a Currency lookup ELŐTT
            // dob ResourceNotFoundException-t, így a Currency mock-ot nem érintjük.
            req.setAmount(new BigDecimal("1000.00"));

            assertThatThrownBy(() -> bankOrderService.create(req))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("Branch");

            // Verify hogy a save() NEM hívódott — kritikus: NEM jött létre bank order Company B-n!
            verify(bankOrderRepository, never()).save(any(BankOrder.class));
        }
    }

    @Test
    @DisplayName("list — NEM findAll() / findByStatus(), tenant-szűrt company list")
    void list_usesTenantSafeQuery_neverFindAll() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_A);

            // A tenant-safe metódus üres oldalt ad vissza
            when(bankOrderRepository.findByCompanyAndOptionalStatus(
                    eq(COMPANY_A), eq(BankOrder.Status.PENDING), any(Pageable.class)))
                    .thenReturn(Page.empty());

            bankOrderService.list(BankOrder.Status.PENDING, 0, 50);

            // KRITIKUS: a régi findAll() / findByStatus() NEM hívódott — ez volt a total data leak
            verify(bankOrderRepository, never()).findAll(any(Pageable.class));
            verify(bankOrderRepository, never()).findByStatusOrderByRequestedAtDesc(
                    any(BankOrder.Status.class), any(Pageable.class));
            // Verify hogy a tenant-safe variánst hívtuk
            verify(bankOrderRepository).findByCompanyAndOptionalStatus(
                    eq(COMPANY_A), eq(BankOrder.Status.PENDING), any(Pageable.class));
        }
    }

    @Test
    @DisplayName("list — nulla status esetén is tenant-szűrt query (NEM findAll())")
    void list_nullStatus_usesTenantSafeQuery() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_A);

            when(bankOrderRepository.findByCompanyAndOptionalStatus(
                    eq(COMPANY_A), eq(null), any(Pageable.class)))
                    .thenReturn(Page.empty());

            bankOrderService.list(null, 0, 50);

            verify(bankOrderRepository, never()).findAll(any(Pageable.class));
            verify(bankOrderRepository).findByCompanyAndOptionalStatus(
                    eq(COMPANY_A), eq(null), any(Pageable.class));
        }
    }

    @Test
    @DisplayName("list — null currentCompanyId esetén ValidationException (defenzív)")
    void list_nullCompanyId_throws() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(null);

            assertThatThrownBy(() -> bankOrderService.list(null, 0, 50))
                    .isInstanceOf(ValidationException.class);

            verify(bankOrderRepository, never()).findAll(any(Pageable.class));
            verify(bankOrderRepository, never()).findByCompanyAndOptionalStatus(
                    any(UUID.class), any(), any(Pageable.class));
        }
    }
}
