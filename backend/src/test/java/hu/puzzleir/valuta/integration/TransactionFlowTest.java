package hu.puzzleir.valuta.integration;

import hu.puzzleir.valuta.dto.license.LicenseStatusResponse;
import hu.puzzleir.valuta.service.LicenseService;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.DailySessionService;
import hu.puzzleir.valuta.service.ExchangeRateService;
import hu.puzzleir.valuta.service.TransactionService;
import hu.puzzleir.valuta.service.ReceiptSequenceService;
import hu.puzzleir.valuta.service.HandlingFeeCalculator;
import hu.puzzleir.valuta.service.AmlService;
import hu.puzzleir.valuta.service.PosTerminalService;
import hu.puzzleir.valuta.service.StornoService;
import hu.puzzleir.valuta.dto.storno.StornoRequestDto;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.lang.reflect.Field;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * TransactionFlow integr__ci__s tesztek -  __zleti flow-k Mockito-val.
 *
 * Sell flow: session open -> sell -> receipt -> close
 * Buy flow: customer create -> buy -> AML check -> receipt
 * Storno flow: sell -> storno -> inventory restored
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class TransactionFlowTest {

    @InjectMocks
    private TransactionService transactionService;

    @Mock private hu.puzzleir.valuta.service.TransactionValidationService transactionValidationService;
    @Mock private hu.puzzleir.valuta.service.PmtComplianceValidator pmtComplianceValidator;
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
    @Mock private hu.puzzleir.valuta.service.HandlingFeeOverrideService handlingFeeOverrideService;
    @Mock private AmlService amlService;
    @Mock private PosTerminalService posTerminalService;
    @Mock private hu.puzzleir.valuta.service.TransactionCalculationService calculationService;
    @Mock private hu.puzzleir.valuta.service.TransactionReversalService reversalService;
    @Mock private hu.puzzleir.valuta.service.TransactionConversionService conversionService;
    @Mock private hu.puzzleir.valuta.service.TransactionMultiLineService multiLineService;
    @Mock private LicenseService licenseService;
    @Mock private hu.puzzleir.valuta.service.WacService wacService;
    @Mock private hu.puzzleir.valuta.service.VaultStockFlowService vaultStockFlowService;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final Long WORKER_ID = 1L;
    private static final Long EUR_ID = 10L;
    private static final Long HUF_ID = 1L;

    private Company company;
    private Branch branch;
    private Worker worker;
    private Currency eurCurrency;
    private Currency hufCurrency;
    private ExchangeRate eurRate;
    private CashBalance eurBalance;
    private CashBalance hufBalance;

    @BeforeEach
    void setUp() throws Exception {
        // Set the cachedHufCurrencyId via reflection (normally set by @PostConstruct)
        org.mockito.Mockito.lenient().when(licenseService.validateLicense()).thenReturn(hu.puzzleir.valuta.dto.license.LicenseStatusResponse.builder().status("VALID").build());
        Field hufIdField = TransactionService.class.getDeclaredField("cachedHufCurrencyId");
        hufIdField.setAccessible(true);
        hufIdField.set(transactionService, HUF_ID);

        company = new Company();
        company.setId(COMPANY_ID);
        company.setName("Test Ceg");

        branch = new Branch();
        branch.setId(BRANCH_ID);
        branch.setCode("B01");
        branch.setName("Teszt Iroda");

        worker = new Worker();
        worker.setId(WORKER_ID);
        worker.setName("Teszt P__nzt__ros");

        eurCurrency = new Currency();
        eurCurrency.setId(EUR_ID);
        eurCurrency.setCode("EUR");
        eurCurrency.setName("Eur__");

        hufCurrency = new Currency();
        hufCurrency.setId(HUF_ID);
        hufCurrency.setCode("HUF");
        hufCurrency.setName("Forint");

        when(currencyRepository.findById(HUF_ID)).thenReturn(Optional.of(hufCurrency));
        when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(hufCurrency));

        eurRate = new ExchangeRate();
        eurRate.setId(1L);
        eurRate.setCurrency(eurCurrency);
        eurRate.setBaseBuyRate(new BigDecimal("390.00"));
        eurRate.setBaseSellRate(new BigDecimal("400.00"));

        eurBalance = new CashBalance();
        eurBalance.setId(1L);
        eurBalance.setCurrency(eurCurrency);
        eurBalance.setCurrentBalance(new BigDecimal("50000"));
        eurBalance.setOpeningBalance(new BigDecimal("50000"));

        hufBalance = new CashBalance();
        hufBalance.setId(2L);
        hufBalance.setCurrentBalance(new BigDecimal("10000000"));
        hufBalance.setOpeningBalance(new BigDecimal("10000000"));

        // Default mock: CalculationService
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
        // validateDiscount: by default no-op (Mockito void methods do nothing)
        // For excessive discount, we override in the specific test

        // Default mock: HandlingFeeCalculator returns 0 (no fee)
        when(handlingFeeCalculator.calculate(any(), any(), any(), any()))
            .thenReturn(java.math.BigDecimal.ZERO);
        // FK-KEZDÍJ (2026-06-02): override pass-through (NONE) — a base díjat adja vissza.
        when(handlingFeeOverrideService.resolveOverride(any(), any(), any(), any(), any(), any()))
            .thenAnswer(inv -> inv.getArgument(0));
        when(handlingFeeCalculator.calculateBuyGross(any(), any()))
            .thenAnswer(inv -> {
                java.math.BigDecimal net = inv.getArgument(0);
                java.math.BigDecimal fee = inv.getArgument(1);
                return net != null && fee != null ? net.subtract(fee) : net;
            });
        when(handlingFeeCalculator.calculateSellGross(any(), any()))
            .thenAnswer(inv -> {
                java.math.BigDecimal net = inv.getArgument(0);
                java.math.BigDecimal fee = inv.getArgument(1);
                return net != null && fee != null ? net.add(fee) : net;
            });
                AmlService.AmlBasicCheckResult amlOk = AmlService.AmlBasicCheckResult.builder()
                                .approved(true)
                                .requiresApproval(false)
                                .requiresDetailedId(false)
                                .build();
                when(amlService.checkTransaction(any(), any(), any(), any(), any(), any())).thenReturn(amlOk);
        // Default mock: ReceiptSequenceService
        when(receiptSequenceService.generateReceiptNumber(any(), any()))
            .thenReturn("TEST-001");
        when(receiptSequenceService.generateReversalReceiptNumber(any(), any()))
            .thenReturn("STORNO-001");
    }

    // ===== SELL FLOW =====

    @Nested
    @DisplayName("Sell Flow - session open, sell, receipt, close")
    class SellFlowTests {

        @Test
        @DisplayName("testSellFlow_fullCycle - sell full cycle")
        void testSellFlow_fullCycle() {
            try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
                secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
                secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
                secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
                secUtils.when(SecurityUtils::isSupervisorOrAbove).thenReturn(false);

                // Open session
                when(dailySessionService.hasOpenSession()).thenReturn(true);

                // Entit__sok
                when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
                when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
                when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
                when(currencyRepository.findById(EUR_ID)).thenReturn(Optional.of(eurCurrency));

                // Rate
                when(exchangeRateService.getCurrentRate(EUR_ID)).thenReturn(eurRate);

                // K__szlet ellen_'rz__s -  EUR __s HUF k__l__n (read + pessimistic lock)
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, EUR_ID, COMPANY_ID))
                        .thenReturn(Optional.of(eurBalance));
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(BRANCH_ID, EUR_ID, COMPANY_ID))
                        .thenReturn(Optional.of(eurBalance));
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, HUF_ID, COMPANY_ID))
                        .thenReturn(Optional.of(hufBalance));
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(BRANCH_ID, EUR_ID, COMPANY_ID))
                        .thenReturn(Optional.of(eurBalance));
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(BRANCH_ID, HUF_ID, COMPANY_ID))
                        .thenReturn(Optional.of(hufBalance));

                // Receipt number
                when(transactionRepository.findMaxReceiptNumber(eq(BRANCH_ID), any(LocalDate.class), anyString()))
                        .thenReturn(Optional.empty());

                // Save
                when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> {
                    Transaction t = inv.getArgument(0);
                    t.setId(1L);
                    return t;
                });

                // Execute sell
                TransactionService.SellRequest request = TransactionService.SellRequest.builder()
                        .currencyId(EUR_ID)
                        .currencyAmount(new BigDecimal("100"))
                        .customerName("Teszt __gyf__l")
                        .customerDocumentNumber("123456AA")
                        .build();

                Transaction result = transactionService.executeSell(request);

                assertThat(result).isNotNull();
                assertThat(result.getTransactionType()).isEqualTo(TransactionType.SELL);
                assertThat(result.getStatus()).isEqualTo(TransactionStatus.COMPLETED);
                assertThat(result.getCurrency().getCode()).isEqualTo("EUR");
                assertThat(result.getCurrencyAmount()).isEqualByComparingTo(new BigDecimal("100"));

                // Bizonylat sz__m gener__lva
                assertThat(result.getReceiptNumber()).isEqualTo("TEST-001");

                verify(transactionRepository).save(any(Transaction.class));
                verify(dailySessionService).updateSessionStats(eq(TransactionType.SELL), any(), any());
            }
        }

        @Test
        @DisplayName("testSellFlow_noSession -  nincs nyitott munkamenet")
        void testSellFlow_noSession() {
            try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
                secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
                secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
                secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);

                when(dailySessionService.hasOpenSession()).thenReturn(false);

                TransactionService.SellRequest request = TransactionService.SellRequest.builder()
                        .currencyId(EUR_ID)
                        .currencyAmount(new BigDecimal("100"))
                        .build();

                assertThatThrownBy(() -> transactionService.executeSell(request))
                        .isInstanceOf(ValidationException.class)
                        .hasMessageContaining("munkamenet");
            }
        }

        @Test
        @DisplayName("testSellFlow_insufficientStock - insufficient stock")
        void testSellFlow_insufficientStock() {
            try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
                secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
                secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
                secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
                secUtils.when(SecurityUtils::isSupervisorOrAbove).thenReturn(false);

                when(dailySessionService.hasOpenSession()).thenReturn(true);
                when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
                when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
                when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
                when(currencyRepository.findById(EUR_ID)).thenReturn(Optional.of(eurCurrency));
                when(exchangeRateService.getCurrentRate(EUR_ID)).thenReturn(eurRate);

                // __res k__szlet
                CashBalance emptyBalance = new CashBalance();
                emptyBalance.setCurrentBalance(new BigDecimal("10"));
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, EUR_ID, COMPANY_ID))
                        .thenReturn(Optional.of(emptyBalance));
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(BRANCH_ID, EUR_ID, COMPANY_ID))
                        .thenReturn(Optional.of(emptyBalance));

                TransactionService.SellRequest request = TransactionService.SellRequest.builder()
                        .currencyId(EUR_ID)
                        .currencyAmount(new BigDecimal("10000"))
                        .build();

                assertThatThrownBy(() -> transactionService.executeSell(request))
                        .isInstanceOf(ValidationException.class)
                        .hasMessageContaining("valuta");
            }
        }
    }

    // ===== BUY FLOW =====

    @Nested
    @DisplayName("Buy Flow -  customer -> buy -> AML check -> receipt")
    class BuyFlowTests {

        @Test
        @DisplayName("testBuyFlow_withCustomer - buy with customer")
        void testBuyFlow_withCustomer() {
            try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
                secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
                secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
                secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
                secUtils.when(SecurityUtils::isSupervisorOrAbove).thenReturn(false);

                when(dailySessionService.hasOpenSession()).thenReturn(true);
                when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
                when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
                when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
                when(currencyRepository.findById(EUR_ID)).thenReturn(Optional.of(eurCurrency));
                when(exchangeRateService.getCurrentRate(EUR_ID)).thenReturn(eurRate);
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, EUR_ID, COMPANY_ID))
                        .thenReturn(Optional.of(eurBalance));
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(BRANCH_ID, EUR_ID, COMPANY_ID))
                        .thenReturn(Optional.of(eurBalance));
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, HUF_ID, COMPANY_ID))
                        .thenReturn(Optional.of(hufBalance));
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(BRANCH_ID, HUF_ID, COMPANY_ID))
                        .thenReturn(Optional.of(hufBalance));
                when(transactionRepository.findMaxReceiptNumber(eq(BRANCH_ID), any(), anyString()))
                        .thenReturn(Optional.empty());
                when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> {
                    Transaction t = inv.getArgument(0);
                    t.setId(2L);
                    return t;
                });

                TransactionService.BuyRequest request = TransactionService.BuyRequest.builder()
                        .currencyId(EUR_ID)
                        .currencyAmount(new BigDecimal("500"))
                        .customerId("CUST-001")
                        .customerName("Nagy B__la")
                        .customerDocumentNumber("AB123456")
                        .customerAddress("Budapest, F_' u. 1.")
                        .customerNationality("HU")
                        .build();

                Transaction result = transactionService.executeBuy(request);

                assertThat(result).isNotNull();
                assertThat(result.getTransactionType()).isEqualTo(TransactionType.BUY);
                assertThat(result.getStatus()).isEqualTo(TransactionStatus.COMPLETED);
                assertThat(result.getCustomerName()).isEqualTo("Nagy B__la");
                assertThat(result.getCustomerDocumentNumber()).isEqualTo("AB123456");
                assertThat(result.getReceiptNumber()).isEqualTo("TEST-001");

                verify(transactionRepository).save(any(Transaction.class));
                verify(dailySessionService).updateSessionStats(eq(TransactionType.BUY), any(), any());
            }
        }

        @Test
        @DisplayName("testBuyFlow_largeAmount - 300K+ Ft azonos__t__s k__telez_'")
        void testBuyFlow_largeAmount_requiresIdentification() {
            try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
                secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
                secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
                secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
                secUtils.when(SecurityUtils::isSupervisorOrAbove).thenReturn(false);

                when(dailySessionService.hasOpenSession()).thenReturn(true);
                when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
                when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
                when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
                when(currencyRepository.findById(EUR_ID)).thenReturn(Optional.of(eurCurrency));
                when(exchangeRateService.getCurrentRate(EUR_ID)).thenReturn(eurRate);

                // 1000 EUR * 390 = 390.000 Ft > 300.000 limit -> __gyf__l n__lk__l hib__t dob
                TransactionService.BuyRequest request = TransactionService.BuyRequest.builder()
                        .currencyId(EUR_ID)
                        .currencyAmount(new BigDecimal("1000"))
                        .build();

                assertThatThrownBy(() -> transactionService.executeBuy(request))
                        .isInstanceOf(ValidationException.class)
                        .hasMessageContaining("azonos");
            }
        }

        @Test
        @DisplayName("testBuyFlow_withDiscount - discounted buy")
        void testBuyFlow_withDiscount() {
            try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
                secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
                secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
                secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
                secUtils.when(SecurityUtils::isSupervisorOrAbove).thenReturn(false);

                when(dailySessionService.hasOpenSession()).thenReturn(true);
                when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
                when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
                when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
                when(currencyRepository.findById(EUR_ID)).thenReturn(Optional.of(eurCurrency));
                when(exchangeRateService.getCurrentRate(EUR_ID)).thenReturn(eurRate);
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, EUR_ID, COMPANY_ID))
                        .thenReturn(Optional.of(eurBalance));
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(BRANCH_ID, EUR_ID, COMPANY_ID))
                        .thenReturn(Optional.of(eurBalance));
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, HUF_ID, COMPANY_ID))
                        .thenReturn(Optional.of(hufBalance));
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(BRANCH_ID, HUF_ID, COMPANY_ID))
                        .thenReturn(Optional.of(hufBalance));
                when(transactionRepository.findMaxReceiptNumber(eq(BRANCH_ID), any(), anyString()))
                        .thenReturn(Optional.empty());
                when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> {
                    Transaction t = inv.getArgument(0);
                    t.setId(3L);
                    return t;
                });

                TransactionService.BuyRequest request = TransactionService.BuyRequest.builder()
                        .currencyId(EUR_ID)
                        .currencyAmount(new BigDecimal("50"))
                        .discountPercent(new BigDecimal("1.5"))
                        .build();

                Transaction result = transactionService.executeBuy(request);

                assertThat(result).isNotNull();
                assertThat(result.getDiscountPercent()).isEqualByComparingTo(new BigDecimal("1.5"));
            }
        }

        @Test
        @DisplayName("testBuyFlow_excessiveDiscount - 2%+ kedvezm__ny supervisor n__lk__l")
        void testBuyFlow_excessiveDiscount() {
            try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
                secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
                secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
                secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
                secUtils.when(SecurityUtils::isSupervisorOrAbove).thenReturn(false);

                when(dailySessionService.hasOpenSession()).thenReturn(true);
                when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
                when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
                when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
                when(currencyRepository.findById(EUR_ID)).thenReturn(Optional.of(eurCurrency));
                when(exchangeRateService.getCurrentRate(EUR_ID)).thenReturn(eurRate);

                // 2%+ kedvezmeny supervisor nelkul _ hiba
                doThrow(new ValidationException("2% feletti kedvezmenyhez supervisor jogosultsag szukseges!"))
                        .when(calculationService).validateDiscount(eq(new BigDecimal("5.0")));

                TransactionService.BuyRequest request = TransactionService.BuyRequest.builder()
                        .currencyId(EUR_ID)
                        .currencyAmount(new BigDecimal("50"))
                        .discountPercent(new BigDecimal("5.0"))
                        .build();

                assertThatThrownBy(() -> transactionService.executeBuy(request))
                        .isInstanceOf(ValidationException.class)
                        .hasMessageContaining("supervisor");
            }
        }
    }

    // ===== STORNO FLOW =====
    // Storno tesztek atkoltoztek: TransactionReversalServiceTest.java
    // (a delegate pattern miatt az @InjectMocks a ReversalService-re mutat)

    /* REMOVED - see TransactionReversalServiceTest */
    /*

        @Test
        @DisplayName("testStornoFlow - sell reversal, stock restored")
        void testStornoFlow() {
            try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
                secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
                secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
                secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
                secUtils.when(SecurityUtils::isSupervisorOrAbove).thenReturn(true);

                when(dailySessionService.hasOpenSession()).thenReturn(true);
                when(dailySessionService.getDailyReversalCount()).thenReturn(0);

                // Eredeti tranzakci__
                Transaction original = Transaction.builder()
                        .id(100L)
                        .company(company)
                        .branch(branch)
                        .worker(worker)
                        .receiptNumber("E030600001")
                        .transactionType(TransactionType.SELL)
                        .status(TransactionStatus.COMPLETED)
                        .transactionDate(LocalDate.now())
                        .transactionTime(LocalTime.now())
                        .currency(eurCurrency)
                        .currencyAmount(new BigDecimal("200"))
                        .exchangeRate(new BigDecimal("400.00"))
                        .hufAmount(new BigDecimal("80000"))
                        .handlingFee(BigDecimal.ZERO)
                        .discountPercent(BigDecimal.ZERO)
                        .discountAmount(BigDecimal.ZERO)
                        .build();

                when(transactionRepository.findById(100L)).thenReturn(Optional.of(original));
                when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
                when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
                when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
                when(transactionRepository.findMaxReceiptNumber(eq(BRANCH_ID), any(), anyString()))
                        .thenReturn(Optional.empty());
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, EUR_ID, COMPANY_ID))
                        .thenReturn(Optional.of(eurBalance));
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(BRANCH_ID, EUR_ID, COMPANY_ID))
                        .thenReturn(Optional.of(eurBalance));
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, HUF_ID, COMPANY_ID))
                        .thenReturn(Optional.of(hufBalance));
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(BRANCH_ID, HUF_ID, COMPANY_ID))
                        .thenReturn(Optional.of(hufBalance));
                when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> {
                    Transaction t = inv.getArgument(0);
                    if (t.getId() == null) t.setId(200L);
                    return t;
                });

                TransactionService.ReversalRequest reversalRequest = TransactionService.ReversalRequest.builder()
                        .originalTransactionId(100L)
                        .reason("T__ves r__gz__t__s")
                        .approvedBy("SUPERVISOR")
                        .build();

                Transaction reversal = transactionService.executeReversal(reversalRequest);

                assertThat(reversal).isNotNull();
                assertThat(reversal.getTransactionType()).isEqualTo(TransactionType.REVERSAL);
                assertThat(reversal.getStatus()).isEqualTo(TransactionStatus.COMPLETED);
                assertThat(reversal.getReceiptNumber()).startsWith("S");
                assertThat(reversal.getReversalReason()).isEqualTo("T__ves r__gz__t__s");

                // Eredeti REVERSED-re __ll__tva
                verify(transactionRepository, atLeast(2)).save(any(Transaction.class));

                // Kassza friss__t__s megt__rt__nt (elad__s sztorn__: valuta +, HUF -)
                verify(cashBalanceRepository, atLeast(2)).save(any(CashBalance.class));
                verify(dailySessionService).updateSessionStats(eq(TransactionType.REVERSAL), any(), any());
            }
        }

        @Test
        @DisplayName("testStornoFlow_alreadyReversed - m__r sztorn__zott tranzakci__")
        void testStornoFlow_alreadyReversed() {
            try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
                secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
                secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
                secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);

                when(dailySessionService.hasOpenSession()).thenReturn(true);

                Transaction reversedTx = Transaction.builder()
                        .id(100L)
                        .branch(branch)
                        .status(TransactionStatus.REVERSED)
                        .transactionType(TransactionType.SELL)
                        .transactionDate(LocalDate.now())
                        .build();

                when(transactionRepository.findById(100L)).thenReturn(Optional.of(reversedTx));

                TransactionService.ReversalRequest request = TransactionService.ReversalRequest.builder()
                        .originalTransactionId(100L)
                        .reason("Teszt")
                        .build();

                assertThatThrownBy(() -> transactionService.executeReversal(request))
                        .isInstanceOf(ValidationException.class)
                        .hasMessageContaining("sztorn");
            }
        }

        @Test
        @DisplayName("testStornoFlow_differentBranch - m__s iroda tranzakci__j__t nem lehet sztorn__zni")
        void testStornoFlow_differentBranch() {
            try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
                secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
                secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
                secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);

                when(dailySessionService.hasOpenSession()).thenReturn(true);

                Branch otherBranch = new Branch();
                otherBranch.setId(UUID.randomUUID());

                Transaction otherBranchTx = Transaction.builder()
                        .id(100L)
                        .branch(otherBranch)
                        .status(TransactionStatus.COMPLETED)
                        .transactionType(TransactionType.SELL)
                        .transactionDate(LocalDate.now())
                        .build();

                when(transactionRepository.findById(100L)).thenReturn(Optional.of(otherBranchTx));

                TransactionService.ReversalRequest request = TransactionService.ReversalRequest.builder()
                        .originalTransactionId(100L)
                        .reason("Teszt")
                        .build();

                assertThatThrownBy(() -> transactionService.executeReversal(request))
                        .isInstanceOf(ValidationException.class)
                        .hasMessageContaining("iroda");
            }
        }
    }
    */
}
