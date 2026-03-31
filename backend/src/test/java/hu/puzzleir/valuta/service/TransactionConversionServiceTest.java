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
            when(handlingFeeCalculator.calculate(any(), any(), any())).thenReturn(BigDecimal.ZERO);

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
}
