package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TransactionServiceCameraLinkingTest {

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final Long WORKER_ID = 11L;
    private static final Long EUR_ID = 2L;
    private static final Long HUF_ID = 1L;
    @Mock private TransactionValidationService transactionValidationService;
    @Mock private PmtComplianceValidator pmtComplianceValidator;
    @Mock private WacService wacService;
    @Mock private VaultStockFlowService vaultStockFlowService;

    @InjectMocks
    private TransactionService transactionService;

    @Mock private TransactionRepository transactionRepository;
    @Mock private TransactionLineRepository transactionLineRepository;
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
    @Mock private AmlService amlService;
    @Mock private PosTerminalService posTerminalService;
    @Mock private LicenseService licenseService;
    @Mock private TransactionCalculationService calculationService;
    @Mock private ObjectProvider<CameraTransactionLinker> cameraTransactionLinkerProvider;
    @Mock private CameraTransactionLinker cameraTransactionLinker;

    @BeforeEach
    void setUp() {
        // License valid stub
        org.mockito.Mockito.lenient().when(licenseService.validateLicense()).thenReturn(
                hu.puzzleir.valuta.dto.license.LicenseStatusResponse.builder().status("VALID").build());
        var details = new WorkerAuthenticationDetails(WORKER_ID, COMPANY_ID, BRANCH_ID, "CASHIER");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("user", "pass", "ROLE_CASHIER");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);

        Company company = new Company();
        company.setId(COMPANY_ID);

        Branch branch = new Branch();
        branch.setId(BRANCH_ID);
        branch.setCompany(company);

        Worker worker = new Worker();
        worker.setId(WORKER_ID);

        Currency eur = new Currency();
        eur.setId(EUR_ID);
        eur.setCode("EUR");

        Currency huf = new Currency();
        huf.setId(HUF_ID);
        huf.setCode("HUF");

        ExchangeRate rate = new ExchangeRate();
        rate.setBaseBuyRate(new BigDecimal("400"));
        rate.setOfficialRate(new BigDecimal("405"));

        when(dailySessionService.hasOpenSession()).thenReturn(true);
        when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
        when(currencyRepository.findById(EUR_ID)).thenReturn(Optional.of(eur));
        when(currencyRepository.findById(HUF_ID)).thenReturn(Optional.of(huf));
        when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(huf));
        when(exchangeRateService.getCurrentRate(EUR_ID)).thenReturn(rate);
        when(receiptSequenceService.generateReceiptNumber(BRANCH_ID, TransactionType.BUY)).thenReturn("V00001");
        when(handlingFeeCalculator.calculate(any(), eq(TransactionType.BUY), any(), any())).thenReturn(BigDecimal.ZERO);
        when(handlingFeeCalculator.calculateBuyGross(any(), any())).thenAnswer(inv -> inv.getArgument(0));
        when(calculationService.resolveBuyRate(any(), any(), any()))
                .thenAnswer(inv -> {
                    ExchangeRate r = inv.getArgument(0);
                    return r.getBaseBuyRate();
                });
        when(calculationService.applyBuyDiscount(any(), any())).thenAnswer(inv -> inv.getArgument(0));
        when(calculationService.calculateDiscountAmount(any(), any())).thenReturn(BigDecimal.ZERO);
        when(cameraTransactionLinkerProvider.getIfAvailable()).thenReturn(cameraTransactionLinker);

        CashBalance eurBalance = new CashBalance();
        eurBalance.setBranch(branch);
        eurBalance.setCurrency(eur);
        eurBalance.setCurrentBalance(BigDecimal.ZERO);

        CashBalance hufBalance = new CashBalance();
        hufBalance.setBranch(branch);
        hufBalance.setCurrency(huf);
        hufBalance.setCurrentBalance(new BigDecimal("1000000"));

        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(BRANCH_ID, EUR_ID, COMPANY_ID)).thenReturn(Optional.of(eurBalance));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(BRANCH_ID, HUF_ID, COMPANY_ID)).thenReturn(Optional.of(hufBalance));
        when(cashBalanceRepository.save(any(CashBalance.class))).thenAnswer(invocation -> invocation.getArgument(0));

        AmlService.AmlBasicCheckResult amlResult = mock(AmlService.AmlBasicCheckResult.class);
        when(amlResult.isApproved()).thenReturn(true);
        when(amlResult.isRequiresApproval()).thenReturn(false);
        when(amlResult.isRequiresDetailedId()).thenReturn(false);
        when(amlService.checkTransaction(any(), any(), any(), any(), any(), any())).thenReturn(amlResult);

        when(transactionRepository.save(any(Transaction.class))).thenAnswer(invocation -> {
            Transaction tx = invocation.getArgument(0);
            if (tx.getId() == null) {
                tx.setId(123L);
            }
            if (tx.getTransactionDate() == null) {
                tx.setTransactionDate(LocalDate.of(2026, 3, 21));
            }
            if (tx.getTransactionTime() == null) {
                tx.setTransactionTime(LocalTime.of(12, 0));
            }
            return tx;
        });

        transactionService.initHufCurrencyId();
    }

    @Test
    void executeBuy_linksSavedTransactionToCameraEvidence() {
        TransactionService.BuyRequest request = TransactionService.BuyRequest.builder()
                .currencyId(EUR_ID)
                .currencyAmount(new BigDecimal("10"))
                .customerName("Teszt Elek")
                .customerDocumentNumber("AA123456")
                .build();

        Transaction saved = transactionService.executeBuy(request);

        ArgumentCaptor<LocalDateTime> timeCaptor = ArgumentCaptor.forClass(LocalDateTime.class);
        verify(cameraTransactionLinker).linkTransaction(eq(123L), eq(BRANCH_ID), timeCaptor.capture(), eq("V00001"));
        assertThat(saved.getId()).isEqualTo(123L);
        assertThat(timeCaptor.getValue().toLocalDate()).isEqualTo(saved.getTransactionDate());
        assertThat(timeCaptor.getValue().toLocalTime()).isEqualTo(saved.getTransactionTime());
    }
}


