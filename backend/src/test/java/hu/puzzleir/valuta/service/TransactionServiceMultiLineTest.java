package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * TransactionMultiLineService tesztek (korabban TransactionService multi-line).
 * A delegate pattern miatt kozvetlenul a MultiLineService-t teszteljuk.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class TransactionServiceMultiLineTest {

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final Long WORKER_ID = 11L;
    private static final Long HUF_ID = 1L;
    private static final Long EUR_ID = 2L;
    private static final Long USD_ID = 3L;
    @Mock private TransactionValidationService transactionValidationService;
    @Mock private WacService wacService;

    @InjectMocks
    private TransactionMultiLineService multiLineServiceImpl;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private TransactionLineRepository transactionLineRepository;

    @Mock
    private CurrencyRepository currencyRepository;

    @Mock
    private ExchangeRateRepository exchangeRateRepository;

    @Mock
    private CashBalanceRepository cashBalanceRepository;

    @Mock
    private WorkerRepository workerRepository;

    @Mock
    private CompanyRepository companyRepository;

    @Mock
    private BranchRepository branchRepository;

    @Mock
    private DailySessionService dailySessionService;

    @Mock
    private ExchangeRateService exchangeRateService;

    @Mock
    private ReceiptSequenceService receiptSequenceService;

    @Mock
    private HandlingFeeCalculator handlingFeeCalculator;

    @Mock
    private HandlingFeeOverrideService handlingFeeOverrideService;

    @Mock
    private AmlService amlService;

    @Mock
    private PosTerminalService posTerminalService;

    @Mock
    private TransactionCalculationService calculationService;

    @Mock
    private TransactionOperationHelper helper;

    @Mock
    private LicenseService licenseService;

    private Company company;
    private Branch branch;
    private Worker worker;
    private Currency eurCurrency;
    private Currency usdCurrency;
    private Currency hufCurrency;
    private ExchangeRate eurRate;
    private ExchangeRate usdRate;

    @BeforeEach
    void setUp() {
        // License valid stub
        org.mockito.Mockito.lenient().when(licenseService.validateLicense()).thenReturn(
                hu.puzzleir.valuta.dto.license.LicenseStatusResponse.builder().status("VALID").build());
        // Security context beallitas
        var details = new WorkerAuthenticationDetails(WORKER_ID, COMPANY_ID, BRANCH_ID, "CASHIER");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("user", "pass", "ROLE_CASHIER");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);

        // Kozos entitasok
        company = new Company();
        company.setId(COMPANY_ID);

        branch = new Branch();
        branch.setId(BRANCH_ID);
        branch.setName("Test Iroda");
        branch.setCompany(company);

        worker = new Worker();
        worker.setId(WORKER_ID);
        worker.setCode("T01");
        worker.setName("Test Penztar");

        hufCurrency = new Currency();
        hufCurrency.setId(HUF_ID);
        hufCurrency.setCode("HUF");
        hufCurrency.setName("Magyar forint");

        eurCurrency = new Currency();
        eurCurrency.setId(EUR_ID);
        eurCurrency.setCode("EUR");
        eurCurrency.setName("Euro");

        usdCurrency = new Currency();
        usdCurrency.setId(USD_ID);
        usdCurrency.setCode("USD");
        usdCurrency.setName("US Dollar");

        eurRate = new ExchangeRate();
        eurRate.setCurrency(eurCurrency);
        eurRate.setBaseBuyRate(new BigDecimal("390.00"));
        eurRate.setBaseSellRate(new BigDecimal("400.00"));

        usdRate = new ExchangeRate();
        usdRate.setCurrency(usdCurrency);
        usdRate.setBaseBuyRate(new BigDecimal("350.00"));
        usdRate.setBaseSellRate(new BigDecimal("360.00"));

        // Kozos mock beallitasok
        when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
        when(currencyRepository.findById(EUR_ID)).thenReturn(Optional.of(eurCurrency));
        when(currencyRepository.findById(USD_ID)).thenReturn(Optional.of(usdCurrency));
        when(currencyRepository.findById(HUF_ID)).thenReturn(Optional.of(hufCurrency));
        when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(hufCurrency));
        when(currencyRepository.findByCode("EUR")).thenReturn(Optional.of(eurCurrency));
        when(currencyRepository.findByCode("USD")).thenReturn(Optional.of(usdCurrency));
        when(exchangeRateService.getCurrentRate(EUR_ID)).thenReturn(eurRate);
        when(exchangeRateService.getCurrentRate(USD_ID)).thenReturn(usdRate);
        when(dailySessionService.hasOpenSession()).thenReturn(true);
        when(receiptSequenceService.generateReceiptNumber(any(), any())).thenReturn("V00001");
        when(handlingFeeCalculator.calculate(any(), any(), any(), any())).thenReturn(BigDecimal.ZERO);
        when(handlingFeeCalculator.calculateBuyGross(any(), any())).thenAnswer(inv -> inv.getArgument(0));
        when(handlingFeeCalculator.calculateSellGross(any(), any())).thenAnswer(inv -> inv.getArgument(0));
        // FK-KEZDÍJ (2026-06-02): override pass-through (NONE) — a base díjat adja vissza.
        when(handlingFeeOverrideService.resolveOverride(any(), any(), any(), any(), any(), any()))
                .thenAnswer(inv -> inv.getArgument(0));

        // CalculationService mock — rate resolve + discount
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

        // AML mock — approved
        AmlService.AmlBasicCheckResult amlOk = new AmlService.AmlBasicCheckResult();
        amlOk.setApproved(true);
        when(amlService.checkTransaction(any(), any(), any(), any(), any(), any())).thenReturn(amlOk);

        // Helper mock — validateOpenSession no-op (void), resolveCurrencyId delegates, etc.
        when(helper.getHufCurrencyId()).thenReturn(HUF_ID);
        when(helper.getMaxTransactionLines()).thenReturn(6);
        when(helper.resolveCurrencyId(eq(EUR_ID), any())).thenReturn(EUR_ID);
        when(helper.resolveCurrencyId(eq(USD_ID), any())).thenReturn(USD_ID);
        when(helper.resolveCurrencyId(eq(null), eq("EUR"))).thenReturn(EUR_ID);
        when(helper.resolveCurrencyId(eq(null), eq("USD"))).thenReturn(USD_ID);

        // Kassza egyenleg mock
        CashBalance hufBalance = new CashBalance();
        hufBalance.setCurrentBalance(new BigDecimal("10000000"));
        hufBalance.setBranch(branch);
        hufBalance.setCompany(company);
        hufBalance.setCurrency(hufCurrency);

        CashBalance eurBalance = new CashBalance();
        eurBalance.setCurrentBalance(new BigDecimal("50000"));
        eurBalance.setBranch(branch);
        eurBalance.setCompany(company);
        eurBalance.setCurrency(eurCurrency);

        CashBalance usdBalance = new CashBalance();
        usdBalance.setCurrentBalance(new BigDecimal("50000"));
        usdBalance.setBranch(branch);
        usdBalance.setCompany(company);
        usdBalance.setCurrency(usdCurrency);

        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(BRANCH_ID, HUF_ID, COMPANY_ID))
                .thenReturn(Optional.of(hufBalance));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(BRANCH_ID, EUR_ID, COMPANY_ID))
                .thenReturn(Optional.of(eurBalance));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(BRANCH_ID, USD_ID, COMPANY_ID))
                .thenReturn(Optional.of(usdBalance));

        // Transaction save mock — id-t allitunk
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> {
            Transaction t = inv.getArgument(0);
            if (t.getId() == null) {
                t.setId(100L);
            }
            return t;
        });
    }

    // Single-line backward compatibility tesztek eltavolitva:
    // A single-line logika a TransactionService.executeBuy()-ban marad,
    // nem a MultiLineService feladata.

    // ============ MULTI-LINE BUY ============

    @Test
    @DisplayName("Multi-line vetel 2 valutaval")
    void multiLineBuyWithTwoCurrencies() {
        TransactionService.LineRequest eurLine = TransactionService.LineRequest.builder()
                .currencyId(EUR_ID)
                .banknoteCount(new BigDecimal("100"))
                .build();
        TransactionService.LineRequest usdLine = TransactionService.LineRequest.builder()
                .currencyId(USD_ID)
                .banknoteCount(new BigDecimal("200"))
                .build();

        TransactionService.BuyRequest request = TransactionService.BuyRequest.builder()
                .lines(Arrays.asList(eurLine, usdLine))
                .build();

        Transaction result = multiLineServiceImpl.executeMultiLineBuy(request);

        assertThat(result).isNotNull();
        assertThat(result.getMultiLine()).isTrue();
        assertThat(result.getLineCount()).isEqualTo(2);
        assertThat(result.getLines()).hasSize(2);

        // Elso sor EUR
        TransactionLine line1 = result.getLines().get(0);
        assertThat(line1.getLineNumber()).isEqualTo(1);
        assertThat(line1.getCurrency().getCode()).isEqualTo("EUR");
        assertThat(line1.getBanknoteCount()).isEqualByComparingTo("100");

        // Masodik sor USD
        TransactionLine line2 = result.getLines().get(1);
        assertThat(line2.getLineNumber()).isEqualTo(2);
        assertThat(line2.getCurrency().getCode()).isEqualTo("USD");
        assertThat(line2.getBanknoteCount()).isEqualByComparingTo("200");

        // Aggregalt currencyAmount = 100 + 200 = 300
        assertThat(result.getCurrencyAmount()).isEqualByComparingTo("300");

        // A fejlec valutaja az elso sor valutaja (EUR)
        assertThat(result.getCurrency().getCode()).isEqualTo("EUR");
    }

    @Test
    @DisplayName("Multi-line vetel HUF osszeg aggregalt a sorokbol")
    void multiLineBuyHufAggregated() {
        // EUR 100 @ 390 = 39000 HUF, USD 200 @ 350 = 70000 HUF
        // Osszesen: 109000 HUF -> 5 Ft kerekites
        TransactionService.LineRequest eurLine = TransactionService.LineRequest.builder()
                .currencyId(EUR_ID)
                .banknoteCount(new BigDecimal("100"))
                .build();
        TransactionService.LineRequest usdLine = TransactionService.LineRequest.builder()
                .currencyId(USD_ID)
                .banknoteCount(new BigDecimal("200"))
                .build();

        TransactionService.BuyRequest request = TransactionService.BuyRequest.builder()
                .lines(Arrays.asList(eurLine, usdLine))
                .build();

        Transaction result = multiLineServiceImpl.executeMultiLineBuy(request);

        // hufAmount tartalmazza az osszes sor HUF erteket kerekitve
        assertThat(result.getHufAmount()).isNotNull();
        assertThat(result.getHufAmount().compareTo(BigDecimal.ZERO)).isGreaterThan(0);

        // Codex P1 (2026-06-04): minden sor HUF-erteke = alkalmazott arfolyam × bankjegy-mennyiseg, EGESZ
        // forintra kerekitve — OSZTO NELKUL (a korabbi /100 legacy-osztot tavolitottuk el). EXACT assert
        // (nem csak > 0), hogy a 100×/1000× alultarifalo regresszio ne lappanghasson ujra.
        for (TransactionLine line : result.getLines()) {
            assertThat(line.getHufValue()).isNotNull();
            BigDecimal expected = line.getAppliedRate()
                    .multiply(line.getBanknoteCount())
                    .setScale(0, java.math.RoundingMode.HALF_UP);
            assertThat(line.getHufValue()).isEqualByComparingTo(expected);
            // Sanity: 100+ egysegnyi valuta ~350-400 arfolyamon tizezres nagysagrend — a /100 bug ~tizeztized
            // erteket adott volna (< 1000), ezt explicit kizarjuk.
            assertThat(line.getHufValue().compareTo(new BigDecimal("1000"))).isGreaterThan(0);
        }
    }

    // ============ MAX 6 LINES VALIDATION ============

    @Test
    @DisplayName("7 tetelsor eseten ValidationException")
    void maxSixLinesValidation() {
        List<TransactionService.LineRequest> sevenLines = new java.util.ArrayList<>();
        for (int i = 0; i < 7; i++) {
            sevenLines.add(TransactionService.LineRequest.builder()
                    .currencyId(EUR_ID)
                    .banknoteCount(new BigDecimal("100"))
                    .build());
        }

        TransactionService.BuyRequest request = TransactionService.BuyRequest.builder()
                .lines(sevenLines)
                .build();

        assertThatThrownBy(() -> multiLineServiceImpl.executeMultiLineBuy(request))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("maximum 6");
    }

    @Test
    @DisplayName("6 tetelsor meg engedelyezett")
    void sixLinesAllowed() {
        List<TransactionService.LineRequest> sixLines = new java.util.ArrayList<>();
        for (int i = 0; i < 6; i++) {
            sixLines.add(TransactionService.LineRequest.builder()
                    .currencyId(EUR_ID)
                    .banknoteCount(new BigDecimal("10"))
                    .build());
        }

        TransactionService.BuyRequest request = TransactionService.BuyRequest.builder()
                .lines(sixLines)
                .build();

        Transaction result = multiLineServiceImpl.executeMultiLineBuy(request);
        assertThat(result).isNotNull();
        assertThat(result.getLineCount()).isEqualTo(6);
        assertThat(result.getLines()).hasSize(6);
    }

    // ============ VALIDATION ============

    @Test
    @DisplayName("Nulla bankjegy darabszam eseten ValidationException")
    void zeroBanknoteCountValidation() {
        TransactionService.LineRequest line = TransactionService.LineRequest.builder()
                .currencyId(EUR_ID)
                .banknoteCount(BigDecimal.ZERO)
                .build();

        TransactionService.BuyRequest request = TransactionService.BuyRequest.builder()
                .lines(List.of(line))
                .build();

        assertThatThrownBy(() -> multiLineServiceImpl.executeMultiLineBuy(request))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("pozitiv");
    }

    @Test
    @DisplayName("Valuta nelkuli sor eseten ValidationException")
    void missingCurrencyValidation() {
        TransactionService.LineRequest line = TransactionService.LineRequest.builder()
                .banknoteCount(new BigDecimal("100"))
                .build();

        TransactionService.BuyRequest request = TransactionService.BuyRequest.builder()
                .lines(List.of(line))
                .build();

        assertThatThrownBy(() -> multiLineServiceImpl.executeMultiLineBuy(request))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("valuta");
    }

    // ============ MULTI-LINE SELL ============

    @Test
    @DisplayName("Multi-line eladas 2 valutaval")
    void multiLineSellWithTwoCurrencies() {
        when(receiptSequenceService.generateReceiptNumber(any(), eq(TransactionType.SELL))).thenReturn("E00001");

        TransactionService.LineRequest eurLine = TransactionService.LineRequest.builder()
                .currencyId(EUR_ID)
                .banknoteCount(new BigDecimal("50"))
                .build();
        TransactionService.LineRequest usdLine = TransactionService.LineRequest.builder()
                .currencyId(USD_ID)
                .banknoteCount(new BigDecimal("100"))
                .build();

        TransactionService.SellRequest request = TransactionService.SellRequest.builder()
                .lines(Arrays.asList(eurLine, usdLine))
                .build();

        Transaction result = multiLineServiceImpl.executeMultiLineSell(request);

        assertThat(result).isNotNull();
        assertThat(result.getMultiLine()).isTrue();
        assertThat(result.getLineCount()).isEqualTo(2);
        assertThat(result.getTransactionType()).isEqualTo(TransactionType.SELL);
        assertThat(result.getLines()).hasSize(2);
    }

    @Test
    @DisplayName("Multi-line sell kassza frissites soronkent")
    void multiLineSellUpdatesCashPerLine() {
        TransactionService.LineRequest eurLine = TransactionService.LineRequest.builder()
                .currencyId(EUR_ID)
                .banknoteCount(new BigDecimal("50"))
                .build();
        TransactionService.LineRequest usdLine = TransactionService.LineRequest.builder()
                .currencyId(USD_ID)
                .banknoteCount(new BigDecimal("100"))
                .build();

        TransactionService.SellRequest request = TransactionService.SellRequest.builder()
                .lines(Arrays.asList(eurLine, usdLine))
                .build();

        multiLineServiceImpl.executeMultiLineSell(request);

        // Kassza frissites: soronkent updateCashBalance + HUF
        verify(helper, atLeast(3)).updateCashBalance(any(), any(), any(), anyBoolean());
    }

    // ============ CURRENCY CODE RESOLUTION ============

    @Test
    @DisplayName("Multi-line sorok currencyCode-al is mukodnek")
    void multiLineBuyWithCurrencyCode() {
        TransactionService.LineRequest eurLine = TransactionService.LineRequest.builder()
                .currencyCode("EUR")
                .banknoteCount(new BigDecimal("100"))
                .build();

        TransactionService.BuyRequest request = TransactionService.BuyRequest.builder()
                .lines(List.of(eurLine))
                .build();

        Transaction result = multiLineServiceImpl.executeMultiLineBuy(request);

        assertThat(result).isNotNull();
        assertThat(result.getMultiLine()).isTrue();
        assertThat(result.getLineCount()).isEqualTo(1);
    }
}


