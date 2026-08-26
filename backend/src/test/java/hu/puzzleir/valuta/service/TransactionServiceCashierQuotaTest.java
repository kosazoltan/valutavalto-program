package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.*;
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
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * TransactionService — pénztárosi sáv (cashier custom rate) napi kvóta backend
 * enforce-olási UNIT tesztek.
 *
 * <p>Hatás: 2026-05-13 v2.5.49+ (Codex P1 #562). A frontend tracking-only volt, a
 * backend most {@code ValidationException}-t dob, ha a napi limit elérve és a
 * {@code cashierCustomRate} flag true egy {@code CASHIER_CUSTOM_RATE_MIN_AMOUNT}
 * feletti tranzakcióhoz.</p>
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class TransactionServiceCashierQuotaTest {
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
    @Mock private SystemParameterService systemParameterService;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final Long WORKER_ID = 1L;

    @BeforeEach
    void setUp() {
        // License valid
        when(licenseService.validateLicense()).thenReturn(
                hu.puzzleir.valuta.dto.license.LicenseStatusResponse.builder().status("VALID").build());

        // SecurityContext
        WorkerAuthenticationDetails details =
                new WorkerAuthenticationDetails(WORKER_ID, COMPANY_ID, BRANCH_ID, "CASHIER");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("test", "pass", "ROLE_CASHIER");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);

        // Napi munkamenet nyitva
        when(dailySessionService.hasOpenSession()).thenReturn(true);

        // Entitások
        when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(new Company()));
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(new Branch()));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(new Worker()));
        // PP-06: a kvóta-ellenőrzés pesszimista zárat vesz a pénztáros sorára
        org.mockito.Mockito.lenient().when(workerRepository.findByIdForUpdate(WORKER_ID)).thenReturn(Optional.of(new Worker()));

        // HUF + EUR valuta
        Currency huf = new Currency();
        huf.setId(1L);
        huf.setCode("HUF");
        when(currencyRepository.findById(1L)).thenReturn(Optional.of(huf));
        when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(huf));

        Currency eur = new Currency();
        eur.setId(2L);
        eur.setCode("EUR");
        when(currencyRepository.findById(2L)).thenReturn(Optional.of(eur));
        when(currencyRepository.findByCode("EUR")).thenReturn(Optional.of(eur));

        // EUR árfolyam (eladás 400 HUF/EUR, vétel 395)
        ExchangeRate rate = ExchangeRate.builder()
                .id(1L)
                .baseBuyRate(new BigDecimal("395.00"))
                .baseSellRate(new BigDecimal("400.00"))
                .validDate(LocalDate.now())
                .build();
        when(exchangeRateService.getCurrentRate(2L)).thenReturn(rate);

        // CalculationService minimális stubok
        when(calculationService.resolveSellRate(any(), any(), any())).thenAnswer(inv -> {
            ExchangeRate r = inv.getArgument(0);
            BigDecimal custom = inv.getArgument(2);
            return custom != null ? custom : r.getBaseSellRate();
        });
        when(calculationService.resolveBuyRate(any(), any(), any())).thenAnswer(inv -> {
            ExchangeRate r = inv.getArgument(0);
            BigDecimal custom = inv.getArgument(2);
            return custom != null ? custom : r.getBaseBuyRate();
        });
        when(calculationService.applySellDiscount(any(), any())).thenAnswer(inv -> inv.getArgument(0));
        when(calculationService.applyBuyDiscount(any(), any())).thenAnswer(inv -> inv.getArgument(0));
        when(calculationService.calculateDiscountAmount(any(), any())).thenReturn(BigDecimal.ZERO);

        // Kezelési díj: 0
        when(handlingFeeCalculator.calculate(any(), any(), any(), any())).thenReturn(BigDecimal.ZERO);
        when(handlingFeeCalculator.calculateSellGross(any(), any())).thenAnswer(inv -> inv.getArgument(0));
        when(handlingFeeCalculator.calculateBuyGross(any(), any())).thenAnswer(inv -> inv.getArgument(0));

        // Készlet elegendő — HUF kasszára is 2 millió kell mert buy esetén 500k+ kifizetés
        CashBalance cashBalance = new CashBalance();
        cashBalance.setCurrentBalance(new BigDecimal("2000000"));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(eq(BRANCH_ID), any(), any())).thenReturn(Optional.of(cashBalance));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(eq(BRANCH_ID), any(), any())).thenReturn(Optional.of(cashBalance));

        // Bizonylat szám
        when(receiptSequenceService.generateReceiptNumber(any(), any())).thenReturn("V001-00001");

        // AML PASS
        AmlService.AmlBasicCheckResult amlOk = AmlService.AmlBasicCheckResult.builder()
                .approved(true)
                .requiresApproval(false)
                .requiresDetailedId(false)
                .build();
        when(amlService.checkTransaction(any(), any(), any(), any(), any(), any())).thenReturn(amlOk);

        // Transaction save echo
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> inv.getArgument(0));

        // SystemParameter alap-stubok (min 400k, limit 5)
        when(systemParameterService.getValue("CASHIER_CUSTOM_RATE_MIN_AMOUNT", "400000")).thenReturn("400000");
        when(systemParameterService.getValue("CASHIER_CUSTOM_RATE_DAILY_LIMIT", "5")).thenReturn("5");
    }

    private TransactionService.BuyRequest buildBuy(BigDecimal currencyAmount, boolean flag, String customerName, String docNumber) {
        return TransactionService.BuyRequest.builder()
                .currencyId(2L)
                .currencyAmount(currencyAmount)
                .customerName(customerName)
                .customerDocumentNumber(docNumber)
                .cashierCustomRate(flag)
                .build();
    }

    // ==========================================================================
    // 1. flag=false → engedi (bármi összeg, bármi kvóta)
    // ==========================================================================
    @Test
    @DisplayName("flag=false → ne validálja a kvótát, engedi át")
    void cashierCustomRateFalse_doesNotValidate() {
        when(transactionRepository.countDailyCashierCustomRatesByWorker(eq(WORKER_ID), any(LocalDate.class)))
                .thenReturn(99L); // limit régen elérve, de a flag false → mindegy

        // 2000 EUR * 395 = 790k HUF → 400k felett, de flag false
        TransactionService.BuyRequest request = buildBuy(new BigDecimal("2000"), false, "Teszt Elek", "AB123456");

        assertThatCode(() -> transactionService.executeBuy(request)).doesNotThrowAnyException();
        verify(workerRepository, never()).findByIdForUpdate(any());
    }

    // ==========================================================================
    // 2. flag=true + összeg < 400k → engedi át (kicsi tranzakciónál a flag irreleváns)
    //    + NORMALIZÁLÁS: a mentett Transaction.cashierCustomRate=false legyen (Codex P1 #564)
    // ==========================================================================
    @Test
    @DisplayName("flag=true, összeg < 400k → normalizál false-ra, ne fogyasszon kvótát")
    void cashierCustomRateTrue_belowMinAmount_normalizesFalse() {
        when(transactionRepository.countDailyCashierCustomRatesByWorker(eq(WORKER_ID), any(LocalDate.class)))
                .thenReturn(99L); // limit elérve, de összeg < min

        // 100 EUR * 395 = 39.500 HUF → 400k alatt
        TransactionService.BuyRequest request = buildBuy(new BigDecimal("100"), true, null, null);

        assertThatCode(() -> transactionService.executeBuy(request)).doesNotThrowAnyException();

        // Verify: a Transaction.cashierCustomRate=false-ra normalizálódott (a flag nem került mentésre)
        org.mockito.ArgumentCaptor<Transaction> captor = org.mockito.ArgumentCaptor.forClass(Transaction.class);
        verify(transactionRepository).save(captor.capture());
        org.assertj.core.api.Assertions.assertThat(captor.getValue().getCashierCustomRate()).isFalse();
        verify(workerRepository, never()).findByIdForUpdate(any());
    }

    // ==========================================================================
    // 3. flag=true + összeg ≥ 400k + used < limit → engedi át
    // ==========================================================================
    @Test
    @DisplayName("flag=true, összeg 500k, used=3/5 → engedi át")
    void cashierCustomRateTrue_aboveMinAmount_quotaAvailable_passes() {
        when(transactionRepository.countDailyCashierCustomRatesByWorker(eq(WORKER_ID), any(LocalDate.class)))
                .thenReturn(3L); // 3/5 használva

        // 1300 EUR * 395 = 513.500 HUF → 400k felett
        TransactionService.BuyRequest request = buildBuy(new BigDecimal("1300"), true, "Nagy Béla", "CD234567");

        assertThatCode(() -> transactionService.executeBuy(request)).doesNotThrowAnyException();
        verify(workerRepository).findByIdForUpdate(WORKER_ID);
    }

    // ==========================================================================
    // 4. flag=true + összeg ≥ 400k + used ≥ limit → ValidationException
    // ==========================================================================
    @Test
    @DisplayName("flag=true, összeg 500k, used=5/5 (limit elérve) → ValidationException")
    void cashierCustomRateTrue_quotaExhausted_throws() {
        when(transactionRepository.countDailyCashierCustomRatesByWorker(eq(WORKER_ID), any(LocalDate.class)))
                .thenReturn(5L); // 5/5 elérve

        TransactionService.BuyRequest request = buildBuy(new BigDecimal("1300"), true, "Nagy Béla", "CD234567");

        assertThatThrownBy(() -> transactionService.executeBuy(request))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Pénztárosi sáv napi limit elérve")
                .hasMessageContaining("5/5");
        verify(workerRepository).findByIdForUpdate(WORKER_ID);
    }

    // ==========================================================================
    // 5. flag=true + összeg ≥ 400k + used > limit (defensive) → ValidationException
    // ==========================================================================
    @Test
    @DisplayName("flag=true, used=10/5 (limit túllépve, defensive) → ValidationException")
    void cashierCustomRateTrue_quotaOverflow_throws() {
        when(transactionRepository.countDailyCashierCustomRatesByWorker(eq(WORKER_ID), any(LocalDate.class)))
                .thenReturn(10L); // 10/5 — kétségbeesetten túl

        TransactionService.BuyRequest request = buildBuy(new BigDecimal("2000"), true, "Nagy Béla", "CD234567");

        assertThatThrownBy(() -> transactionService.executeBuy(request))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Pénztárosi sáv napi limit elérve");
        verify(workerRepository).findByIdForUpdate(WORKER_ID);
    }

    // ==========================================================================
    // 6. executeSell ágon ugyanígy működik (külön validate hívás minden tranzakció típushoz)
    // ==========================================================================
    @Test
    @DisplayName("executeSell flag=true, used=5/5 → ValidationException")
    void executeSell_cashierCustomRate_quotaExhausted_throws() {
        when(transactionRepository.countDailyCashierCustomRatesByWorker(eq(WORKER_ID), any(LocalDate.class)))
                .thenReturn(5L);

        // 1300 EUR * 400 = 520.000 HUF → 400k felett
        TransactionService.SellRequest request = TransactionService.SellRequest.builder()
                .currencyId(2L)
                .currencyAmount(new BigDecimal("1300"))
                .customerName("Nagy Béla")
                .customerDocumentNumber("CD234567")
                .cashierCustomRate(true)
                .build();

        assertThatThrownBy(() -> transactionService.executeSell(request))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Pénztárosi sáv napi limit elérve");
        verify(workerRepository).findByIdForUpdate(WORKER_ID);
    }

    // ==========================================================================
    // 7. SystemParameter limit override (pl. 10) — működik-e
    // ==========================================================================
    @Test
    @DisplayName("SystemParameter override limit=10, used=8 → engedi át")
    void customLimit_quotaAvailable_passes() {
        when(systemParameterService.getValue("CASHIER_CUSTOM_RATE_DAILY_LIMIT", "5")).thenReturn("10");
        when(transactionRepository.countDailyCashierCustomRatesByWorker(eq(WORKER_ID), any(LocalDate.class)))
                .thenReturn(8L); // 8/10

        TransactionService.BuyRequest request = buildBuy(new BigDecimal("1300"), true, "Nagy Béla", "CD234567");

        assertThatCode(() -> transactionService.executeBuy(request)).doesNotThrowAnyException();
        verify(workerRepository).findByIdForUpdate(WORKER_ID);
    }
}
