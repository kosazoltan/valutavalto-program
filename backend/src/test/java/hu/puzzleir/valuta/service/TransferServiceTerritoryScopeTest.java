package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.transfer.TransferDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Transfer;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.TransferRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TransferServiceTerritoryScopeTest {

    private static final UUID COMPANY = UUID.randomUUID();
    private static final UUID OWN_VAULT = UUID.randomUUID();
    private static final UUID OWN_P2 = UUID.randomUUID();
    private static final UUID FOREIGN_B1 = UUID.randomUUID();
    private static final UUID FOREIGN_B2 = UUID.randomUUID();

    private final Set<UUID> scope = Set.of(OWN_VAULT, OWN_P2);

    @Mock private TransferRepository transferRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private TransactionRepository transactionRepository;
    @Mock private ReceiptSequenceService receiptSequenceService;
    @Mock private TransferSerialSequenceService transferSerialSequenceService;
    @Mock private HufDaybookSequenceService hufDaybookSequenceService;
    @Mock private AuditLogService auditLogService;
    @Mock private VaultStockFlowService vaultStockFlowService;
    @Mock private AccessScopeService accessScopeService;
    // FKH-028 5. kor: uj konstruktor-fuggoseg — mechanikus fixture-bovites (no-op mock),
    // a HufDaybookSequenceService-precedens szerint; assert nem valtozott.
    @Mock private TransferCreateDedupGuard createDedupGuard;

    @InjectMocks private TransferService service;

    @Test
    void getById_foreignRegionTransfer_throws404() {
        Transfer transfer = transfer(FOREIGN_B1, FOREIGN_B2);
        when(transferRepository.findById(1L)).thenReturn(Optional.of(transfer));
        stubScopedUser();

        try (MockedStatic<SecurityUtils> security = security(COMPANY, null)) {
            assertThatThrownBy(() -> service.getById(1L))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessage("Átadás nem található: 1");
        }
    }

    @Test
    void getById_fromInScope_visible() {
        Transfer transfer = transfer(OWN_P2, FOREIGN_B1);
        when(transferRepository.findById(1L)).thenReturn(Optional.of(transfer));
        stubScopedUser();

        try (MockedStatic<SecurityUtils> security = security(COMPANY, null)) {
            assertThat(service.getById(1L).getId()).isEqualTo(1L);
        }
    }

    @Test
    void getById_toInScope_visible() {
        Transfer transfer = transfer(FOREIGN_B1, OWN_P2);
        when(transferRepository.findById(1L)).thenReturn(Optional.of(transfer));
        stubScopedUser();

        try (MockedStatic<SecurityUtils> security = security(COMPANY, null)) {
            assertThat(service.getById(1L).getId()).isEqualTo(1L);
        }
    }

    @Test
    void getById_nullScope_centralRoleSeesAll() {
        Transfer transfer = transfer(FOREIGN_B1, FOREIGN_B2);
        when(transferRepository.findById(1L)).thenReturn(Optional.of(transfer));
        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);

        try (MockedStatic<SecurityUtils> security = security(COMPANY, null)) {
            assertThat(service.getById(1L).getId()).isEqualTo(1L);
        }
    }

    @Test
    void getByTransferNumber_foreignRegion_throws404() {
        Transfer transfer = transfer(FOREIGN_B1, FOREIGN_B2);
        when(transferRepository.findByTransferNumber("AT-000042")).thenReturn(Optional.of(transfer));
        stubScopedUser();

        try (MockedStatic<SecurityUtils> security = security(COMPANY, null)) {
            assertThatThrownBy(() -> service.getByTransferNumber("AT-000042"))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessage("Átadás nem található: AT-000042");
        }
    }

    @Test
    void getStornoPreview_foreignRegion_throws404() {
        Transfer transfer = transfer(FOREIGN_B1, FOREIGN_B2);
        when(transferRepository.findById(1L)).thenReturn(Optional.of(transfer));
        stubScopedUser();

        try (MockedStatic<SecurityUtils> security = security(COMPANY, null)) {
            assertThatThrownBy(() -> service.getStornoPreview(1L))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessage("Átadás nem található: 1");
        }
    }

    @Test
    void search_scopedUser_usesScopedQuery() {
        Pageable pageable = PageRequest.of(0, 20);
        LocalDate startDate = LocalDate.of(2026, 7, 1);
        LocalDate endDate = LocalDate.of(2026, 7, 17);
        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(scope);
        when(transferRepository.searchWithinBranches(
                COMPANY, scope, OWN_P2, startDate, endDate,
                Transfer.TransferStatus.PENDING, Transfer.TransferType.CURRENCY, pageable))
                .thenReturn(Page.empty(pageable));

        try (MockedStatic<SecurityUtils> security = security(COMPANY, null)) {
            assertThat(service.search(OWN_P2, startDate, endDate,
                    Transfer.TransferStatus.PENDING, Transfer.TransferType.CURRENCY, pageable)).isEmpty();
        }

        verify(transferRepository).searchWithinBranches(
                COMPANY, scope, OWN_P2, startDate, endDate,
                Transfer.TransferStatus.PENDING, Transfer.TransferType.CURRENCY, pageable);
        verify(transferRepository, never()).search(any(), any(), any(), any(), any(), any(), any());
    }

    @Test
    void search_emptyScope_failClosedEmptyPage_repoNotCalled() {
        Pageable pageable = PageRequest.of(0, 20);
        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(Set.of());

        try (MockedStatic<SecurityUtils> security = security(COMPANY, null)) {
            Page<TransferDto> result = service.search(null, null, null, null, null, pageable);
            assertThat(result.getContent()).isEmpty();
            assertThat(result.getTotalElements()).isZero();
        }

        verify(transferRepository, never()).searchWithinBranches(any(), any(), any(), any(), any(), any(), any(), any());
        verify(transferRepository, never()).search(any(), any(), any(), any(), any(), any(), any());
    }

    @Test
    void search_nullScope_legacyQueryUnchanged() {
        Pageable pageable = PageRequest.of(0, 20);
        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);
        when(transferRepository.search(COMPANY, null, null, null, null, null, pageable))
                .thenReturn(new PageImpl<>(List.of(), pageable, 0));

        try (MockedStatic<SecurityUtils> security = security(COMPANY, null)) {
            assertThat(service.search(null, null, null, null, null, pageable)).isEmpty();
        }

        verify(transferRepository).search(COMPANY, null, null, null, null, null, pageable);
        verify(transferRepository, never()).searchWithinBranches(any(), any(), any(), any(), any(), any(), any(), any());
    }

    @Test
    void getPending_usesOwnBranchQuery() {
        when(transferRepository.findPendingForBranch(
                COMPANY, OWN_VAULT, Transfer.TransferStatus.PENDING)).thenReturn(List.of());

        try (MockedStatic<SecurityUtils> security = security(COMPANY, OWN_VAULT)) {
            assertThat(service.getPending()).isEmpty();
        }

        verify(transferRepository).findPendingForBranch(
                COMPANY, OWN_VAULT, Transfer.TransferStatus.PENDING);
    }

    private void stubScopedUser() {
        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(scope);
        when(accessScopeService.isBranchVisible(any(), anyString()))
                .thenAnswer(invocation -> {
                    Set<UUID> candidateScope = invocation.getArgument(0);
                    String id = invocation.getArgument(1);
                    return candidateScope == null || (id != null && candidateScope.contains(UUID.fromString(id)));
                });
    }

    private Transfer transfer(UUID fromBranchId, UUID toBranchId) {
        Company company = Company.builder().id(COMPANY).build();
        Branch fromBranch = Branch.builder()
                .id(fromBranchId).code("BR001").name("Forrás").company(company).build();
        Branch toBranch = Branch.builder()
                .id(toBranchId).code("BR002").name("Cél").company(company).build();
        Currency currency = Currency.builder().id(1L).code("HUF").name("Forint").build();
        Worker fromWorker = Worker.builder().id(1L).code("W001").name("Teszt Dolgozó").build();
        return Transfer.builder()
                .id(1L)
                .transferNumber("AT-000042")
                .companyId(COMPANY)
                .fromBranch(fromBranch)
                .toBranch(toBranch)
                .fromWorker(fromWorker)
                .transferType(Transfer.TransferType.CURRENCY)
                .status(Transfer.TransferStatus.PENDING)
                .transferDate(LocalDate.of(2026, 7, 17))
                .transferTime(LocalTime.NOON)
                .currency(currency)
                .amount(new BigDecimal("100000"))
                .direction(Transfer.TransferDirection.F)
                .isCancelled(false)
                .build();
    }

    private MockedStatic<SecurityUtils> security(UUID companyId, UUID branchId) {
        MockedStatic<SecurityUtils> security = org.mockito.Mockito.mockStatic(SecurityUtils.class);
        security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
        security.when(SecurityUtils::getCurrentBranchId).thenReturn(branchId);
        security.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(null);
        return security;
    }
}
