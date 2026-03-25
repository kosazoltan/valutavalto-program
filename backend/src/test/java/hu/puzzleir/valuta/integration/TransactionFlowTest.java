package hu.puzzleir.valuta.integration;

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
 * TransactionFlow integrĂˇciĂłs tesztek â€” ĂĽzleti flow-k Mockito-val.
 *
 * Sell flow: session open â†’ sell â†’ receipt â†’ close
 * Buy flow: customer create â†’ buy â†’ AML check â†’ receipt
 * Storno flow: sell â†’ storno â†’ inventory restored
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class TransactionFlowTest {

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
    @Mock private hu.puzzleir.valuta.service.TransactionCalculationService calculationService;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final Long WORKER_ID = 1L;
    private static final Long EUR_ID = 10L;
    private static final Long HUF_ID = 1L;

    private Company company;
    private Branch branch;
    private Worker worker;
    private Currency eurCurrency;
    private ExchangeRate eurRate;
    private CashBalance eurBalance;
    private CashBalance hufBalance;

    @BeforeEach
    void setUp() throws Exception {
        // Set the cachedHufCurrencyId via reflection (normally set by @PostConstruct)
        Field hufIdField = TransactionService.class.getDeclaredField("cachedHufCurrencyId");
        hufIdField.setAccessible(true);
        hufIdField.set(transactionService, HUF_ID);

        company = new Company();
        company.setId(COMPANY_ID);
        company.setName("Test CĂ©g");

        branch = new Branch();
        branch.setId(BRANCH_ID);
        branch.setCode("B01");
        branch.setName("Teszt Iroda");

        worker = new Worker();
        worker.setId(WORKER_ID);
        worker.setName("Teszt PĂ©nztĂˇros");

        eurCurrency = new Currency();
        eurCurrency.setId(EUR_ID);
        eurCurrency.setCode("EUR");
        eurCurrency.setName("EurĂł");

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
        when(handlingFeeCalculator.calculate(any(), any(), any()))
            .thenReturn(java.math.BigDecimal.ZERO);
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
                when(amlService.checkTransaction(any(), any(), any(), any())).thenReturn(amlOk);
        // Default mock: ReceiptSequenceService
        when(receiptSequenceService.generateReceiptNumber(any(), any()))
            .thenReturn("TEST-001");
        when(receiptSequenceService.generateReversalReceiptNumber(any(), any()))
            .thenReturn("STORNO-001");
    }

    // ===== SELL FLOW =====

    @Nested
    @DisplayName("Sell Flow â€” session open â†’ sell â†’ receipt â†’ close")
    class SellFlowTests {

        @Test
        @DisplayName("testSellFlow_fullCycle â€” eladĂˇs teljes ciklus")
        void testSellFlow_fullCycle() {
            try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
                secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
                secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
                secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
                secUtils.when(SecurityUtils::isSupervisorOrAbove).thenReturn(false);

                // Open session
                when(dailySessionService.hasOpenSession()).thenReturn(true);

                // EntitĂˇsok
                when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
                when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
                when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
                when(currencyRepository.findById(EUR_ID)).thenReturn(Optional.of(eurCurrency));

                // Rate
                when(exchangeRateService.getCurrentRate(EUR_ID)).thenReturn(eurRate);

                // KĂ©szlet ellenĹ‘rzĂ©s â€” EUR Ă©s HUF kĂĽlĂ¶n (read + pessimistic lock)
                when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_ID, EUR_ID))
                        .thenReturn(Optional.of(eurBalance));
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(BRANCH_ID, EUR_ID))
                        .thenReturn(Optional.of(eurBalance));
                when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_ID, HUF_ID))
                        .thenReturn(Optional.of(hufBalance));
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(BRANCH_ID, EUR_ID))
                        .thenReturn(Optional.of(eurBalance));
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(BRANCH_ID, HUF_ID))
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
                        .customerName("Teszt ĂśgyfĂ©l")
                        .customerDocumentNumber("123456AA")
                        .build();

                Transaction result = transactionService.executeSell(request);

                assertThat(result).isNotNull();
                assertThat(result.getTransactionType()).isEqualTo(TransactionType.SELL);
                assertThat(result.getStatus()).isEqualTo(TransactionStatus.COMPLETED);
                assertThat(result.getCurrency().getCode()).isEqualTo("EUR");
                assertThat(result.getCurrencyAmount()).isEqualByComparingTo(new BigDecimal("100"));

                // Bizonylat szĂˇm generĂˇlva
                assertThat(result.getReceiptNumber()).isEqualTo("TEST-001");

                verify(transactionRepository).save(any(Transaction.class));
                verify(dailySessionService).updateSessionStats(eq(TransactionType.SELL), any(), any());
            }
        }

        @Test
        @DisplayName("testSellFlow_noSession â€” nincs nyitott munkamenet")
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
        @DisplayName("testSellFlow_insufficientStock â€” nincs elegendĹ‘ kĂ©szlet")
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

                // Ăśres kĂ©szlet
                CashBalance emptyBalance = new CashBalance();
                emptyBalance.setCurrentBalance(new BigDecimal("10"));
                when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_ID, EUR_ID))
                        .thenReturn(Optional.of(emptyBalance));
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(BRANCH_ID, EUR_ID))
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
    @DisplayName("Buy Flow â€” customer â†’ buy â†’ AML check â†’ receipt")
    class BuyFlowTests {

        @Test
        @DisplayName("testBuyFlow_withCustomer â€” ĂĽgyfeles vĂ©tel tranzakciĂł")
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
                when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_ID, EUR_ID))
                        .thenReturn(Optional.of(eurBalance));
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(BRANCH_ID, EUR_ID))
                        .thenReturn(Optional.of(eurBalance));
                when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_ID, HUF_ID))
                        .thenReturn(Optional.of(hufBalance));
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(BRANCH_ID, HUF_ID))
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
                        .customerName("Nagy BĂ©la")
                        .customerDocumentNumber("AB123456")
                        .customerAddress("Budapest, FĹ‘ u. 1.")
                        .customerNationality("HU")
                        .build();

                Transaction result = transactionService.executeBuy(request);

                assertThat(result).isNotNull();
                assertThat(result.getTransactionType()).isEqualTo(TransactionType.BUY);
                assertThat(result.getStatus()).isEqualTo(TransactionStatus.COMPLETED);
                assertThat(result.getCustomerName()).isEqualTo("Nagy BĂ©la");
                assertThat(result.getCustomerDocumentNumber()).isEqualTo("AB123456");
                assertThat(result.getReceiptNumber()).isEqualTo("TEST-001");

                verify(transactionRepository).save(any(Transaction.class));
                verify(dailySessionService).updateSessionStats(eq(TransactionType.BUY), any(), any());
            }
        }

        @Test
        @DisplayName("testBuyFlow_largeAmount_requiresIdentification â€” 300K+ Ft azonosĂ­tĂˇs kĂ¶telezĹ‘")
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

                // 1000 EUR * 390 = 390.000 Ft > 300.000 limit â†’ ĂĽgyfĂ©l nĂ©lkĂĽl hibĂˇt dob
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
        @DisplayName("testBuyFlow_withDiscount â€” kedvezmĂ©nyes vĂ©tel")
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
                when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_ID, EUR_ID))
                        .thenReturn(Optional.of(eurBalance));
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(BRANCH_ID, EUR_ID))
                        .thenReturn(Optional.of(eurBalance));
                when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_ID, HUF_ID))
                        .thenReturn(Optional.of(hufBalance));
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(BRANCH_ID, HUF_ID))
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
        @DisplayName("testBuyFlow_excessiveDiscount â€” 2%+ kedvezmĂ©ny supervisor nĂ©lkĂĽl")
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

                // 2%+ kedvezmény supervisor nélkül → hiba
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

    @Nested
    @DisplayName("Storno Flow â€” sell â†’ storno â†’ inventory restored")
    class StornoFlowTests {

        @Test
        @DisplayName("testStornoFlow â€” eladĂˇs sztornĂł â†’ kĂ©szlet visszaĂˇll")
        void testStornoFlow() {
            try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
                secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
                secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
                secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
                secUtils.when(SecurityUtils::isSupervisorOrAbove).thenReturn(true);

                when(dailySessionService.hasOpenSession()).thenReturn(true);
                when(dailySessionService.getDailyReversalCount()).thenReturn(0);

                // Eredeti tranzakciĂł
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
                when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_ID, EUR_ID))
                        .thenReturn(Optional.of(eurBalance));
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(BRANCH_ID, EUR_ID))
                        .thenReturn(Optional.of(eurBalance));
                when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_ID, HUF_ID))
                        .thenReturn(Optional.of(hufBalance));
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(BRANCH_ID, HUF_ID))
                        .thenReturn(Optional.of(hufBalance));
                when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> {
                    Transaction t = inv.getArgument(0);
                    if (t.getId() == null) t.setId(200L);
                    return t;
                });

                TransactionService.ReversalRequest reversalRequest = TransactionService.ReversalRequest.builder()
                        .originalTransactionId(100L)
                        .reason("TĂ©ves rĂ¶gzĂ­tĂ©s")
                        .approvedBy("SUPERVISOR")
                        .build();

                Transaction reversal = transactionService.executeReversal(reversalRequest);

                assertThat(reversal).isNotNull();
                assertThat(reversal.getTransactionType()).isEqualTo(TransactionType.REVERSAL);
                assertThat(reversal.getStatus()).isEqualTo(TransactionStatus.COMPLETED);
                assertThat(reversal.getReceiptNumber()).startsWith("S");
                assertThat(reversal.getReversalReason()).isEqualTo("TĂ©ves rĂ¶gzĂ­tĂ©s");

                // Eredeti REVERSED-re ĂˇllĂ­tva
                verify(transactionRepository, atLeast(2)).save(any(Transaction.class));

                // Kassza frissĂ­tĂ©s megtĂ¶rtĂ©nt (eladĂˇs sztornĂł: valuta +, HUF -)
                verify(cashBalanceRepository, atLeast(2)).save(any(CashBalance.class));
                verify(dailySessionService).updateSessionStats(eq(TransactionType.REVERSAL), any(), any());
            }
        }

        @Test
        @DisplayName("testStornoFlow_alreadyReversed â€” mĂˇr sztornĂłzott tranzakciĂł")
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
        @DisplayName("testStornoFlow_differentBranch â€” mĂˇs iroda tranzakciĂłjĂˇt nem lehet sztornĂłzni")
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
}