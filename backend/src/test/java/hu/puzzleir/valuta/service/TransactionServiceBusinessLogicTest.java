package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class TransactionServiceBusinessLogicTest {

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final Long WORKER_ID = 11L;
    private static final Long HUF_ID = 1L;
    private static final Long EUR_ID = 2L;
    private static final Long USD_ID = 3L;
    @Mock private TransactionValidationService transactionValidationService;
    @Mock private PmtComplianceValidator pmtComplianceValidator;
    @Mock private WacService wacService;
    @Mock private VaultStockFlowService vaultStockFlowService;

    @InjectMocks
    private TransactionService transactionService;

    @Mock private TransactionRepository transactionRepository;
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
    @Mock private TransactionReversalService reversalService;
    @Mock private TransactionConversionService conversionService;
    @Mock private TransactionMultiLineService multiLineService;

    private Currency huf;
    private Currency eur;
    private Currency usd;

    @BeforeEach
    void setUp() {
        // License valid stub
        org.mockito.Mockito.lenient().when(licenseService.validateLicense()).thenReturn(
                hu.puzzleir.valuta.dto.license.LicenseStatusResponse.builder().status("VALID").build());
        WorkerAuthenticationDetails details =
                new WorkerAuthenticationDetails(WORKER_ID, COMPANY_ID, BRANCH_ID, "CASHIER");
        TestingAuthenticationToken auth =
                new TestingAuthenticationToken("test", "pass", "ROLE_CASHIER");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);

        when(dailySessionService.hasOpenSession()).thenReturn(true);

        Company company = new Company();
        company.setId(COMPANY_ID);
        Branch branch = new Branch();
        branch.setId(BRANCH_ID);
        branch.setCompany(company);
        Worker worker = new Worker();

        when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));

        huf = currency(HUF_ID, "HUF");
        eur = currency(EUR_ID, "EUR");
        usd = currency(USD_ID, "USD");
        when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(huf));
        when(currencyRepository.findById(HUF_ID)).thenReturn(Optional.of(huf));
        when(currencyRepository.findById(EUR_ID)).thenReturn(Optional.of(eur));
        when(currencyRepository.findByCode("EUR")).thenReturn(Optional.of(eur));
        when(currencyRepository.findById(USD_ID)).thenReturn(Optional.of(usd));
        when(currencyRepository.findByCode("USD")).thenReturn(Optional.of(usd));

        when(exchangeRateService.getCurrentRate(EUR_ID)).thenReturn(rate(eur, "395.00", "400.00"));
        when(exchangeRateService.getCurrentRate(USD_ID)).thenReturn(rate(usd, "360.00", "365.00"));

        when(calculationService.resolveBuyRate(any(), any(), any()))
                .thenAnswer(inv -> {
                    ExchangeRate r = inv.getArgument(0);
                    return r.getBaseBuyRate();
                });
        when(calculationService.resolveSellRate(any(), any(), any()))
                .thenAnswer(inv -> {
                    ExchangeRate r = inv.getArgument(0);
                    return r.getBaseSellRate();
                });
        when(calculationService.applyBuyDiscount(any(), any())).thenAnswer(inv -> inv.getArgument(0));
        when(calculationService.applySellDiscount(any(), any())).thenAnswer(inv -> inv.getArgument(0));
        when(calculationService.calculateDiscountAmount(any(), any())).thenReturn(BigDecimal.ZERO);

        when(handlingFeeCalculator.calculate(any(), any(), any(), any())).thenReturn(BigDecimal.ZERO);
        when(handlingFeeCalculator.calculateSellGross(any(), any())).thenAnswer(inv -> inv.getArgument(0));
        when(handlingFeeCalculator.calculateBuyGross(any(), any())).thenAnswer(inv -> inv.getArgument(0));

        when(receiptSequenceService.generateReceiptNumber(any(), any()))
                .thenReturn("R-001", "R-002", "R-003", "R-004");
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> inv.getArgument(0));

        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(BRANCH_ID, EUR_ID, COMPANY_ID))
                .thenReturn(Optional.of(balance(branch, eur, "1000")));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(BRANCH_ID, USD_ID, COMPANY_ID))
                .thenReturn(Optional.of(balance(branch, usd, "1000")));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(BRANCH_ID, HUF_ID, COMPANY_ID))
                .thenReturn(Optional.of(balance(branch, huf, "1000000")));

        AmlService.AmlBasicCheckResult amlOk = AmlService.AmlBasicCheckResult.builder()
                .approved(true)
                .requiresApproval(false)
                .requiresDetailedId(false)
                .build();
        when(amlService.checkTransaction(any(), any(), any(), any(), any(), any())).thenReturn(amlOk);
    }

    @Test
    @DisplayName("executeSell: null AML eredmény -> fail-closed ValidationException")
    void executeSell_nullAmlResult_blocksTransaction() {
        when(amlService.checkTransaction(any(), any(), any(), any(), any(), any())).thenReturn(null);

        TransactionService.SellRequest request = TransactionService.SellRequest.builder()
                .currencyId(EUR_ID)
                .currencyAmount(new BigDecimal("100"))
                .customerId("CUST-1")
                .build();

        assertThatThrownBy(() -> transactionService.executeSell(request))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("AML ellenőrzés nem elérhető");

        verify(transactionRepository, never()).save(any(Transaction.class));
    }

    @Test
    @DisplayName("executeSell: készletellenőrzés lockolt egyenleget használ")
    void executeSell_usesLockedBalanceValidation() {
        TransactionService.SellRequest request = TransactionService.SellRequest.builder()
                .currencyId(EUR_ID)
                .currencyAmount(new BigDecimal("100"))
                .customerId("CUST-1")
                .build();

        assertThatCode(() -> transactionService.executeSell(request)).doesNotThrowAnyException();

        verify(cashBalanceRepository, never()).findByBranchIdAndCurrencyIdAndCompanyId(any(), any(), any());
        verify(cashBalanceRepository, atLeastOnce()).findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(eq(BRANCH_ID), eq(EUR_ID), eq(COMPANY_ID));
    }

    @Test
    @DisplayName("LOCK-ORDERING (cash-vs-cash deadlock): executeSell a HUF (1) sort lockolja ELOSZOR, "
            + "csak utana a deviza (EUR, 2) sort — NOVEKVO currencyId, egyezoen a BUY/sztorno aggal")
    void executeSell_locksHufBeforeForeignCurrency_deadlockPrevention() {
        TransactionService.SellRequest request = TransactionService.SellRequest.builder()
                .currencyId(EUR_ID)
                .currencyAmount(new BigDecimal("100"))
                .customerId("CUST-1")
                .build();

        transactionService.executeSell(request);

        // A determinisztikus globalis cash-lock sorrend: a legkisebb currencyId (HUF=1) ELSO lockolasa
        // megelozi a deviza (EUR=2) elso lockolasat. A cash-sor PESSIMISTIC_WRITE lockot a
        // findByBranchIdAndCurrencyIdAndCompanyIdForUpdate veszi — a hivasi sorrendet captor-ral rogzitjuk.
        ArgumentCaptor<Long> lockOrder = ArgumentCaptor.forClass(Long.class);
        verify(cashBalanceRepository, atLeastOnce())
                .findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(eq(BRANCH_ID), lockOrder.capture(), eq(COMPANY_ID));
        assertThat(lockOrder.getAllValues().indexOf(HUF_ID))
                .isLessThan(lockOrder.getAllValues().indexOf(EUR_ID));
    }

    @Test
    @DisplayName("LOCK-ORDERING (cash-vs-cash deadlock): executeBuy a HUF (1) sort lockolja ELOSZOR, "
            + "csak utana a deviza (EUR, 2) sort — NOVEKVO currencyId (regresszio-vedelem)")
    void executeBuy_locksHufBeforeForeignCurrency_deadlockPrevention() {
        TransactionService.BuyRequest request = TransactionService.BuyRequest.builder()
                .currencyId(EUR_ID)
                .currencyAmount(new BigDecimal("100"))
                .customerId("CUST-1")
                .build();

        transactionService.executeBuy(request);

        ArgumentCaptor<Long> lockOrder = ArgumentCaptor.forClass(Long.class);
        verify(cashBalanceRepository, atLeastOnce())
                .findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(eq(BRANCH_ID), lockOrder.capture(), eq(COMPANY_ID));
        assertThat(lockOrder.getAllValues().indexOf(HUF_ID))
                .isLessThan(lockOrder.getAllValues().indexOf(EUR_ID));
    }

    // executeConversion teszt - a delegate pattern miatt a conversionService mock-ot stub-oljuk
    @Test
    @DisplayName("executeConversion: delegalja a ConversionService-nek")
    void executeConversion_delegatesToConversionService() {
        TransactionService.ConversionRequest request = TransactionService.ConversionRequest.builder()
                .fromCurrencyId(EUR_ID)
                .toCurrencyId(USD_ID)
                .fromAmount(new BigDecimal("100"))
                .customerId("CUST-1")
                .build();

        Transaction mockResult = Transaction.builder()
                .transactionType(TransactionType.CONVERSION)
                .status(TransactionStatus.COMPLETED)
                .build();
        when(conversionService.executeConversion(any())).thenReturn(mockResult);

        Transaction result = transactionService.executeConversion(request);
        assertThat(result).isNotNull();
        assertThat(result.getTransactionType()).isEqualTo(TransactionType.CONVERSION);
        verify(conversionService).executeConversion(request);
    }

    private Currency currency(Long id, String code) {
        Currency currency = new Currency();
        currency.setId(id);
        currency.setCode(code);
        currency.setName(code);
        return currency;
    }

    private ExchangeRate rate(Currency currency, String buyRate, String sellRate) {
        ExchangeRate rate = new ExchangeRate();
        rate.setCurrency(currency);
        rate.setValidDate(LocalDate.now());
        rate.setValidTime(LocalTime.NOON);
        rate.setBaseBuyRate(new BigDecimal(buyRate));
        rate.setBaseSellRate(new BigDecimal(sellRate));
        return rate;
    }

    private CashBalance balance(Branch branch, Currency currency, String amount) {
        CashBalance balance = new CashBalance();
        balance.setBranch(branch);
        balance.setCompany(branch.getCompany());
        balance.setCurrency(currency);
        balance.setCurrentBalance(new BigDecimal(amount));
        return balance;
    }
}


