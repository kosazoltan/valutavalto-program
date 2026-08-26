package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.TransactionService.ConversionRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TransactionConversionServiceTest {

    @Mock private TransactionRepository transactionRepository;
    @Mock private CompanyRepository companyRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private ExchangeRateService exchangeRateService;
    @Mock private ReceiptSequenceService receiptSequenceService;
    @Mock private HandlingFeeCalculator handlingFeeCalculator;
    @Mock private DailySessionService dailySessionService;
    @Mock private TransactionOperationHelper helper;
    @Mock private PmtComplianceValidator pmtComplianceValidator;

    @InjectMocks
    private TransactionConversionService conversionService;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final Long WORKER_ID = 1L;
    private static final Long EUR_ID = 10L;
    private static final Long USD_ID = 11L;

    @BeforeEach
    void setUp() {
        lenient().when(helper.resolveCurrencyId(eq(EUR_ID), any())).thenReturn(EUR_ID);
        lenient().when(helper.resolveCurrencyId(eq(USD_ID), any())).thenReturn(USD_ID);
        // CB-018 parity: AML result must propagate to Transaction.amlSuspicious / amlAnnualLimitReached
        lenient().when(helper.performAmlCheck(any(), any(), any(), any(), any(), any(), any(), any()))
                .thenReturn(AmlService.AmlBasicCheckResult.builder()
                        .approved(true)
                        .suspiciousFlag(false)
                        .annualLimitReached(false)
                        .build());
    }

    @Test
    @DisplayName("executeConversion - same currency throws")
    void sameCurrency_throws() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);

            lenient().when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(mock(Company.class)));
            lenient().when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(mock(Branch.class)));
            lenient().when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(mock(Worker.class)));

            Currency eur = mock(Currency.class);
            lenient().when(eur.getCode()).thenReturn("EUR");
            lenient().when(currencyRepository.findById(EUR_ID)).thenReturn(Optional.of(eur));

            ConversionRequest req = new ConversionRequest();
            req.setFromCurrencyId(EUR_ID);
            req.setToCurrencyId(EUR_ID);
            req.setFromAmount(new BigDecimal("100"));

            assertThatThrownBy(() -> conversionService.executeConversion(req))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("Azonos");
        }
    }

    @Test
    @DisplayName("executeConversion - HUF as source throws")
    void hufSource_throws() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);

            lenient().when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(mock(Company.class)));
            lenient().when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(mock(Branch.class)));
            lenient().when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(mock(Worker.class)));

            Long hufId = 1L;
            lenient().when(helper.resolveCurrencyId(eq(hufId), any())).thenReturn(hufId);

            Currency huf = mock(Currency.class);
            lenient().when(huf.getCode()).thenReturn("HUF");
            Currency eur = mock(Currency.class);
            lenient().when(eur.getCode()).thenReturn("EUR");
            lenient().when(currencyRepository.findById(hufId)).thenReturn(Optional.of(huf));
            lenient().when(currencyRepository.findById(EUR_ID)).thenReturn(Optional.of(eur));

            ConversionRequest req = new ConversionRequest();
            req.setFromCurrencyId(hufId);
            req.setToCurrencyId(EUR_ID);
            req.setFromAmount(new BigDecimal("100"));

            assertThatThrownBy(() -> conversionService.executeConversion(req))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("HUF");
        }
    }

    @Test
    @DisplayName("executeConversion - successful conversion saves 3 transactions")
    void successfulConversion_saves3Transactions() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);

            Company company = mock(Company.class);
            Branch branch = mock(Branch.class);
            Worker worker = mock(Worker.class);
            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
            when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));

            Currency eur = mock(Currency.class);
            when(eur.getCode()).thenReturn("EUR");
            when(eur.getId()).thenReturn(EUR_ID);
            Currency usd = mock(Currency.class);
            when(usd.getCode()).thenReturn("USD");
            when(usd.getId()).thenReturn(USD_ID);
            when(currencyRepository.findById(EUR_ID)).thenReturn(Optional.of(eur));
            when(currencyRepository.findById(USD_ID)).thenReturn(Optional.of(usd));

            ExchangeRate eurRate = mock(ExchangeRate.class);
            when(eurRate.getBaseBuyRate()).thenReturn(new BigDecimal("390.50"));
            ExchangeRate usdRate = mock(ExchangeRate.class);
            when(usdRate.getBaseSellRate()).thenReturn(new BigDecimal("360.20"));
            when(exchangeRateService.getCurrentRate(EUR_ID)).thenReturn(eurRate);
            when(exchangeRateService.getCurrentRate(USD_ID)).thenReturn(usdRate);

            when(receiptSequenceService.generateReceiptNumber(eq(BRANCH_ID), any()))
                    .thenReturn("R001", "R002", "R003");
            when(handlingFeeCalculator.calculate(any(), any(), any(), any())).thenReturn(BigDecimal.ZERO);

            // Save returns the transaction passed to it
            when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> inv.getArgument(0));

            ConversionRequest req = new ConversionRequest();
            req.setFromCurrencyId(EUR_ID);
            req.setToCurrencyId(USD_ID);
            req.setFromAmount(new BigDecimal("100"));

            Transaction result = conversionService.executeConversion(req);
            assertThat(result).isNotNull();

            // 3 transactions saved: main conversion + buy sub + sell sub
            verify(transactionRepository, times(3)).save(any(Transaction.class));
            // Stock validation called for target currency
            verify(helper).validateCurrencyStock(eq(BRANCH_ID), eq(USD_ID), any());
            // Cash balance updated for both currencies
            verify(helper).updateCashBalance(eq(BRANCH_ID), eq(EUR_ID), any(), eq(true));
            verify(helper).updateCashBalance(eq(BRANCH_ID), eq(USD_ID), any(), eq(false));
        }
    }

    @Test
    @DisplayName("CB-018 parity - AML suspicious/annualLimitReached flags persisted on CONVERSION transaction")
    void executeConversion_propagatesAmlFlagsToTransactionEntity() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);

            Company company = mock(Company.class);
            Branch branch = mock(Branch.class);
            Worker worker = mock(Worker.class);
            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
            when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));

            Currency eur = mock(Currency.class);
            when(eur.getCode()).thenReturn("EUR");
            when(eur.getId()).thenReturn(EUR_ID);
            Currency usd = mock(Currency.class);
            when(usd.getCode()).thenReturn("USD");
            when(usd.getId()).thenReturn(USD_ID);
            when(currencyRepository.findById(EUR_ID)).thenReturn(Optional.of(eur));
            when(currencyRepository.findById(USD_ID)).thenReturn(Optional.of(usd));

            ExchangeRate eurRate = mock(ExchangeRate.class);
            when(eurRate.getBaseBuyRate()).thenReturn(new BigDecimal("390.50"));
            ExchangeRate usdRate = mock(ExchangeRate.class);
            when(usdRate.getBaseSellRate()).thenReturn(new BigDecimal("360.20"));
            when(exchangeRateService.getCurrentRate(EUR_ID)).thenReturn(eurRate);
            when(exchangeRateService.getCurrentRate(USD_ID)).thenReturn(usdRate);

            when(receiptSequenceService.generateReceiptNumber(eq(BRANCH_ID), any()))
                    .thenReturn("R201", "R202", "R203");
            when(handlingFeeCalculator.calculate(any(), any(), any(), any())).thenReturn(BigDecimal.ZERO);
            when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> inv.getArgument(0));

            // Override AML mock to simulate BIGCTRL-flagged suspicious + annual-limit scenario
            when(helper.performAmlCheck(any(), any(), any(), any(), any(), any(), any(), any()))
                    .thenReturn(AmlService.AmlBasicCheckResult.builder()
                            .approved(true)
                            .suspiciousFlag(true)
                            .annualLimitReached(true)
                            .build());

            ConversionRequest req = new ConversionRequest();
            req.setFromCurrencyId(EUR_ID);
            req.setToCurrencyId(USD_ID);
            req.setFromAmount(new BigDecimal("100"));
            req.setCustomerId("C-777");
            req.setCustomerName("Gyanus Ugyfel");
            req.setCustomerDocumentNumber("ID-777");
            req.setSourceOfFunds("munkaber");
            req.setCustomerIsPep(Boolean.TRUE);

            Transaction result = conversionService.executeConversion(req);
            assertThat(result).isNotNull();
            assertThat(result.getTransactionType()).isEqualTo(TransactionType.CONVERSION);
            assertThat(result.getAmlSuspicious()).as("CB-018 parity: suspiciousFlag").isTrue();
            assertThat(result.getAmlAnnualLimitReached()).as("CB-018 parity: annualLimitReached").isTrue();
            assertThat(result.getSourceOfFunds()).as("CB-004 parity: sourceOfFunds").isEqualTo("munkaber");
            assertThat(result.getCustomerIsPep()).as("CB-004 parity: customerIsPep").isTrue();
            assertThat(result.getCustomerDocumentNumber()).isEqualTo("ID-777");
        }
    }

    @Test
    @DisplayName("executeConversion - AML a vétel+eladás tényleges legek összegét kapja (Codex P1 #858) + cél valuta")
    void executeConversion_passesDoubledRoundedHufAndTargetCurrencyToAml() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);

            Company company = mock(Company.class);
            Branch branch = mock(Branch.class);
            Worker worker = mock(Worker.class);
            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
            when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));

            Currency eur = mock(Currency.class);
            when(eur.getCode()).thenReturn("EUR");
            when(eur.getId()).thenReturn(EUR_ID);
            Currency usd = mock(Currency.class);
            when(usd.getCode()).thenReturn("USD");
            when(usd.getId()).thenReturn(USD_ID);
            when(currencyRepository.findById(EUR_ID)).thenReturn(Optional.of(eur));
            when(currencyRepository.findById(USD_ID)).thenReturn(Optional.of(usd));

            ExchangeRate eurRate = mock(ExchangeRate.class);
            when(eurRate.getBaseBuyRate()).thenReturn(new BigDecimal("390.52"));
            ExchangeRate usdRate = mock(ExchangeRate.class);
            when(usdRate.getBaseSellRate()).thenReturn(new BigDecimal("360.20"));
            when(exchangeRateService.getCurrentRate(EUR_ID)).thenReturn(eurRate);
            when(exchangeRateService.getCurrentRate(USD_ID)).thenReturn(usdRate);

            when(receiptSequenceService.generateReceiptNumber(eq(BRANCH_ID), any()))
                    .thenReturn("R101", "R102", "R103");
            when(handlingFeeCalculator.calculate(any(), any(), any(), any())).thenReturn(BigDecimal.ZERO);
            when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> inv.getArgument(0));

            ConversionRequest req = new ConversionRequest();
            req.setFromCurrencyId(EUR_ID);
            req.setToCurrencyId(USD_ID);
            req.setFromAmount(new BigDecimal("100"));
            req.setCustomerId("FOREIGN-1");
            req.setCustomerName("Foreign Customer");
            req.setCustomerDocumentNumber("DOC-1");

            conversionService.executeConversion(req);

            // AML-alap = BUY(39050) + SELL usedHuf(39049) = 78099 (NEM 2×39050=78100),
            // mert a teljes-fedezetű default cél (108.41 USD) usedHuf-ja 39049.
            verify(helper).performAmlCheck(
                    eq(new BigDecimal("78099")),
                    eq("FOREIGN-1"),
                    eq("Foreign Customer"),
                    eq("DOC-1"),
                    eq("USD"),
                    any(),
                    any(),
                    any());
        }
    }

    @Test
    @DisplayName("HIBA 2026-05-26 (#4/#5) — lefele modositott cel-osszeg -> visszajaro HUF + HUF kassza + foreignStatus")
    void executeConversion_reducedTargetReturnsHuf() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);

            Company company = mock(Company.class);
            Branch branch = mock(Branch.class);
            Worker worker = mock(Worker.class);
            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
            when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));

            Currency eur = mock(Currency.class);
            when(eur.getCode()).thenReturn("EUR");
            when(eur.getId()).thenReturn(EUR_ID);
            Currency usd = mock(Currency.class);
            when(usd.getCode()).thenReturn("USD");
            when(usd.getId()).thenReturn(USD_ID);
            when(currencyRepository.findById(EUR_ID)).thenReturn(Optional.of(eur));
            when(currencyRepository.findById(USD_ID)).thenReturn(Optional.of(usd));

            ExchangeRate eurRate = mock(ExchangeRate.class);
            when(eurRate.getBaseBuyRate()).thenReturn(new BigDecimal("390.50"));
            ExchangeRate usdRate = mock(ExchangeRate.class);
            when(usdRate.getBaseSellRate()).thenReturn(new BigDecimal("360.20"));
            when(exchangeRateService.getCurrentRate(EUR_ID)).thenReturn(eurRate);
            when(exchangeRateService.getCurrentRate(USD_ID)).thenReturn(usdRate);

            when(receiptSequenceService.generateReceiptNumber(eq(BRANCH_ID), any()))
                    .thenReturn("R401", "R402", "R403");
            when(handlingFeeCalculator.calculate(any(), any(), any(), any())).thenReturn(BigDecimal.ZERO);
            when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> inv.getArgument(0));
            when(helper.getHufCurrencyId()).thenReturn(1L);

            // huf = 100 * 390.50 = 39050 (5 Ft kerekitve marad 39050)
            // a penztaros 100 USD-re csokkenti a celt (max ~108.41 USD lenne)
            ConversionRequest req = new ConversionRequest();
            req.setFromCurrencyId(EUR_ID);
            req.setToCurrencyId(USD_ID);
            req.setFromAmount(new BigDecimal("100"));
            req.setToAmount(new BigDecimal("100"));
            req.setForeignStatus("DOMESTIC");

            Transaction result = conversionService.executeConversion(req);

            // usedHuf = round(100 * 360.20) = 36020; visszajaro = roundToFive(39050-36020) = 3030
            assertThat(result.getReturnedHuf()).isEqualByComparingTo("3030");
            assertThat(result.getForeignStatus()).isEqualTo(ForeignStatus.DOMESTIC);

            // HUF keszlet-ellenorzes + HUF kassza-csokkenes a visszajarora
            verify(helper).validateCurrencyStock(eq(BRANCH_ID), eq(1L), eq(new BigDecimal("3030")));
            verify(helper).updateCashBalance(eq(BRANCH_ID), eq(1L), eq(new BigDecimal("-3030")), eq(false));
            // a cel valuta a csokkentett 100 USD
            verify(helper).updateCashBalance(eq(BRANCH_ID), eq(USD_ID), eq(new BigDecimal("-100.00")), eq(false));
        }
    }

    @Test
    @DisplayName("HIBA 2026-05-26 (#5) — a maximumnal nagyobb cel-osszeg a felso hatarra vagodik (forras valtozatlan)")
    void executeConversion_targetAboveMaxIsClamped() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);

            Company company = mock(Company.class);
            Branch branch = mock(Branch.class);
            Worker worker = mock(Worker.class);
            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
            when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));

            Currency eur = mock(Currency.class);
            when(eur.getCode()).thenReturn("EUR");
            when(eur.getId()).thenReturn(EUR_ID);
            Currency usd = mock(Currency.class);
            when(usd.getCode()).thenReturn("USD");
            when(usd.getId()).thenReturn(USD_ID);
            when(currencyRepository.findById(EUR_ID)).thenReturn(Optional.of(eur));
            when(currencyRepository.findById(USD_ID)).thenReturn(Optional.of(usd));

            ExchangeRate eurRate = mock(ExchangeRate.class);
            when(eurRate.getBaseBuyRate()).thenReturn(new BigDecimal("390.50"));
            ExchangeRate usdRate = mock(ExchangeRate.class);
            when(usdRate.getBaseSellRate()).thenReturn(new BigDecimal("360.20"));
            when(exchangeRateService.getCurrentRate(EUR_ID)).thenReturn(eurRate);
            when(exchangeRateService.getCurrentRate(USD_ID)).thenReturn(usdRate);

            when(receiptSequenceService.generateReceiptNumber(eq(BRANCH_ID), any()))
                    .thenReturn("R501", "R502", "R503");
            when(handlingFeeCalculator.calculate(any(), any(), any(), any())).thenReturn(BigDecimal.ZERO);
            when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> inv.getArgument(0));

            ConversionRequest req = new ConversionRequest();
            req.setFromCurrencyId(EUR_ID);
            req.setToCurrencyId(USD_ID);
            req.setFromAmount(new BigDecimal("100"));
            // irrealisan magas cel -> a forras-fedezet maximumara (108.41 USD) vagodik
            req.setToAmount(new BigDecimal("999"));

            Transaction result = conversionService.executeConversion(req);

            org.mockito.ArgumentCaptor<Transaction> captor =
                    org.mockito.ArgumentCaptor.forClass(Transaction.class);
            verify(transactionRepository, times(3)).save(captor.capture());
            Transaction convSell = captor.getAllValues().stream()
                    .filter(t -> t.getTransactionType() == TransactionType.SELL)
                    .findFirst().orElseThrow();
            // max = floor(39050 / 360.20, 2) = 108.41 USD
            assertThat(convSell.getCurrencyAmount()).isEqualByComparingTo("108.41");
            // visszajaro a flooring-maradek (kicsi), nem negativ
            assertThat(result.getReturnedHuf()).isGreaterThanOrEqualTo(BigDecimal.ZERO);
        }
    }

    @Test
    @DisplayName("Audit P0.8 — parent CONVERSION financial_effective=false, child sorok=true, kozos conversion_group_id")
    void executeConversion_setsFinancialEffectiveAndConversionGroupId() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);

            Company company = mock(Company.class);
            Branch branch = mock(Branch.class);
            Worker worker = mock(Worker.class);
            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
            when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));

            Currency eur = mock(Currency.class);
            when(eur.getCode()).thenReturn("EUR");
            when(eur.getId()).thenReturn(EUR_ID);
            Currency usd = mock(Currency.class);
            when(usd.getCode()).thenReturn("USD");
            when(usd.getId()).thenReturn(USD_ID);
            when(currencyRepository.findById(EUR_ID)).thenReturn(Optional.of(eur));
            when(currencyRepository.findById(USD_ID)).thenReturn(Optional.of(usd));

            ExchangeRate eurRate = mock(ExchangeRate.class);
            when(eurRate.getBaseBuyRate()).thenReturn(new BigDecimal("390.50"));
            ExchangeRate usdRate = mock(ExchangeRate.class);
            when(usdRate.getBaseSellRate()).thenReturn(new BigDecimal("360.20"));
            when(exchangeRateService.getCurrentRate(EUR_ID)).thenReturn(eurRate);
            when(exchangeRateService.getCurrentRate(USD_ID)).thenReturn(usdRate);

            when(receiptSequenceService.generateReceiptNumber(eq(BRANCH_ID), any()))
                    .thenReturn("R301", "R302", "R303");
            when(handlingFeeCalculator.calculate(any(), any(), any(), any())).thenReturn(BigDecimal.ZERO);
            when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> inv.getArgument(0));

            ConversionRequest req = new ConversionRequest();
            req.setFromCurrencyId(EUR_ID);
            req.setToCurrencyId(USD_ID);
            req.setFromAmount(new BigDecimal("100"));

            conversionService.executeConversion(req);

            org.mockito.ArgumentCaptor<Transaction> captor =
                    org.mockito.ArgumentCaptor.forClass(Transaction.class);
            verify(transactionRepository, times(3)).save(captor.capture());
            java.util.List<Transaction> saved = captor.getAllValues();

            // Kotelesseg: parent CONVERSION + convBuy + convSell — mindharman ugyanazon
            // conversion_group_id-vel.
            //
            // Copilot PR #362 follow-up: a `groupId`-t a tenyleges parent CONVERSION-bol vesszuk
            // (NEM `saved.get(0)` order-fuggo), igy a teszt kovetkezetes refaktor utan is.
            UUID groupId = saved.stream()
                    .filter(t -> t.getTransactionType() == TransactionType.CONVERSION)
                    .findFirst()
                    .orElseThrow(() -> new AssertionError("parent CONVERSION sor hianyzik a save-ek kozul"))
                    .getConversionGroupId();
            assertThat(groupId).as("parent CONVERSION conversion_group_id NEM null").isNotNull();
            assertThat(saved).allSatisfy(tx ->
                    assertThat(tx.getConversionGroupId())
                        .as("mind a 3 sor azonos conversion_group_id-vel")
                        .isEqualTo(groupId));

            // Parent CONVERSION sora financial_effective = false (NEM duplikalja a child sorokat
            // a sum riportokban).
            Transaction parentConversion = saved.stream()
                    .filter(t -> t.getTransactionType() == TransactionType.CONVERSION)
                    .findFirst().orElseThrow();
            assertThat(parentConversion.isFinancialEffective())
                    .as("parent CONVERSION sora financial_effective=false")
                    .isFalse();

            // Child convBuy + convSell financial_effective = true.
            Transaction convBuy = saved.stream()
                    .filter(t -> t.getTransactionType() == TransactionType.BUY)
                    .findFirst().orElseThrow();
            Transaction convSell = saved.stream()
                    .filter(t -> t.getTransactionType() == TransactionType.SELL)
                    .findFirst().orElseThrow();
            assertThat(convBuy.isFinancialEffective())
                    .as("child convBuy financial_effective=true (default)").isTrue();
            assertThat(convSell.isFinancialEffective())
                    .as("child convSell financial_effective=true (default)").isTrue();
        }
    }
}
