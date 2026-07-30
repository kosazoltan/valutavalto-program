package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CircularRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.repository.ShipmentHandlingFeeRepository;
import hu.puzzleir.valuta.repository.TransactionBeneficialOwnerRepository;
import hu.puzzleir.valuta.repository.TransactionLineRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.beans.factory.ObjectProvider;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FK-071 HIGH-D (Codex security review) — bizonylat-lekérdezés fiók-szintű RBAC-szűkítése.
 *
 * <p>A GET /transactions/receipt/{receiptNumber} mögötti
 * {@link TransactionService#findByReceiptNumber(String)} korábban kizárólag companyId
 * szerint szűrt — egy pénztáros bizonylatszám-tippeléssel ugyanazon cég MÁS fiókjának
 * tranzakcióját is megnézhette. Elvárt viselkedés:</p>
 * <ul>
 *   <li>pénztáros (nem supervisor+): csak a saját fiókja bizonylata található meg,
 *       más fiók bizonylata 404 (létezés-maszkolás, a Transfer territory-scope és a
 *       cross-tenant F9 konvencióval azonosan);</li>
 *   <li>supervisor+ (SUPERVISOR/MANAGER/ADMIN): a cégszintű lekérdezés változatlan.</li>
 * </ul>
 */
@ExtendWith(MockitoExtension.class)
class TransactionServiceReceiptScopeFk071Test {

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID OWN_BRANCH_ID = UUID.randomUUID();
    private static final String RECEIPT = "V035000042";

    @InjectMocks private TransactionService transactionService;

    @Mock private TransactionRepository transactionRepository;
    @Mock private TransactionLineRepository transactionLineRepository;
    @Mock private TransactionBeneficialOwnerRepository transactionBeneficialOwnerRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private ExchangeRateRepository exchangeRateRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private CompanyRepository companyRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private DailySessionService dailySessionService;
    @Mock private ExchangeRateService exchangeRateService;
    @Mock private ReceiptSequenceService receiptSequenceService;
    @Mock private HandlingFeeCalculator handlingFeeCalculator;
    @Mock private HandlingFeeOverrideService handlingFeeOverrideService;
    @Mock private AmlService amlService;
    @Mock private AmlApprovalService amlApprovalService;
    @Mock private PosTerminalService posTerminalService;
    @Mock private ObjectProvider<CameraTransactionLinker> cameraTransactionLinkerProvider;
    @Mock private TransactionCalculationService calculationService;
    @Mock private TransactionReversalService reversalService;
    @Mock private TransactionConversionService conversionService;
    @Mock private TransactionMultiLineService multiLineService;
    @Mock private PmtComplianceValidator pmtComplianceValidator;
    @Mock private LicenseService licenseService;
    @Mock private SystemParameterService systemParameterService;
    @Mock private WacService wacService;
    @Mock private CircularRepository circularRepository;
    @Mock private TransactionValidationService transactionValidationService;
    @Mock private VaultStockFlowService vaultStockFlowService;
    @Mock private ValueBandService valueBandService;
    @Mock private ShipmentHandlingFeeRepository shipmentHandlingFeeRepository;

    private MockedStatic<SecurityUtils> mockCashierSecurity() {
        MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class);
        security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
        security.when(SecurityUtils::isSupervisorOrAbove).thenReturn(false);
        security.when(SecurityUtils::getCurrentBranchId).thenReturn(OWN_BRANCH_ID);
        return security;
    }

    private MockedStatic<SecurityUtils> mockSupervisorSecurity() {
        MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class);
        security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
        security.when(SecurityUtils::isSupervisorOrAbove).thenReturn(true);
        return security;
    }

    @Test
    @DisplayName("Pénztáros: a saját fiók bizonylata a fiók-szűkített lekérdezéssel látható")
    void cashier_ownBranchReceipt_visibleViaBranchScopedQuery() {
        Transaction tx = new Transaction();
        when(transactionRepository.findByReceiptNumberAndCompanyIdAndBranchId(
                RECEIPT, COMPANY_ID, OWN_BRANCH_ID)).thenReturn(Optional.of(tx));

        try (MockedStatic<SecurityUtils> security = mockCashierSecurity()) {
            assertThat(transactionService.findByReceiptNumber(RECEIPT)).isSameAs(tx);
        }

        verify(transactionRepository)
                .findByReceiptNumberAndCompanyIdAndBranchId(RECEIPT, COMPANY_ID, OWN_BRANCH_ID);
        // A cégszintű (tág) lekérdezés pénztárosnál egyáltalán nem futhat le.
        verify(transactionRepository, never())
                .findByReceiptNumberAndCompanyId(anyString(), any(UUID.class));
    }

    @Test
    @DisplayName("Pénztáros: más fiók bizonylata (azonos cég) → 404, létezés-maszkolással")
    void cashier_otherBranchReceipt_sameCompany_notFound() {
        // A fiók-szűkített lekérdezés más fiók bizonylatára üres találatot ad —
        // a repository-szintű scope-olás garantálja, hogy a sor elő sem kerül.
        when(transactionRepository.findByReceiptNumberAndCompanyIdAndBranchId(
                RECEIPT, COMPANY_ID, OWN_BRANCH_ID)).thenReturn(Optional.empty());

        try (MockedStatic<SecurityUtils> security = mockCashierSecurity()) {
            assertThatThrownBy(() -> transactionService.findByReceiptNumber(RECEIPT))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessage("Bizonylat nem található: " + RECEIPT);
        }

        verify(transactionRepository, never())
                .findByReceiptNumberAndCompanyId(anyString(), any(UUID.class));
    }

    @Test
    @DisplayName("Supervisor+: a cégszintű lekérdezés változatlanul működik")
    void supervisor_companyWideLookup_unchanged() {
        Transaction tx = new Transaction();
        when(transactionRepository.findByReceiptNumberAndCompanyId(RECEIPT, COMPANY_ID))
                .thenReturn(Optional.of(tx));

        try (MockedStatic<SecurityUtils> security = mockSupervisorSecurity()) {
            assertThat(transactionService.findByReceiptNumber(RECEIPT)).isSameAs(tx);
        }

        verify(transactionRepository).findByReceiptNumberAndCompanyId(RECEIPT, COMPANY_ID);
        verify(transactionRepository, never())
                .findByReceiptNumberAndCompanyIdAndBranchId(anyString(), any(UUID.class), any(UUID.class));
    }
}
