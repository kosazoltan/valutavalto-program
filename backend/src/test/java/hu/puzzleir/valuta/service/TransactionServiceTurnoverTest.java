package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.TransactionType;
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

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TransactionServiceTurnoverTest {

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final LocalDate REPORT_DATE = LocalDate.of(2026, 7, 14);

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

    @Test
    @DisplayName("FR-6: a napi kezelési díj a tranzakciós és Shipment-esemény összege")
    void getDailyTurnoverForDate_addsTransactionAndShipmentFees() {
        stubTurnoverSources(REPORT_DATE, new BigDecimal("1500"), new BigDecimal("625"));

        try (MockedStatic<SecurityUtils> security = mockSecurity()) {
            TransactionService.DailyTurnoverSummary result =
                    transactionService.getDailyTurnoverForDate(REPORT_DATE);

            assertThat(result.getTotalHandlingFees()).isEqualByComparingTo("2125");
            verify(shipmentHandlingFeeRepository)
                    .sumDailyReceivedFees(eq(COMPANY_ID), eq(BRANCH_ID), eq(REPORT_DATE));
        }
    }

    @Test
    @DisplayName("FR-6: mindkét null díjforrás nulla összegű KPI-t ad")
    void getDailyTurnoverForDate_treatsBothNullFeeSourcesAsZero() {
        stubTurnoverSources(REPORT_DATE, null, null);

        try (MockedStatic<SecurityUtils> security = mockSecurity()) {
            TransactionService.DailyTurnoverSummary result =
                    transactionService.getDailyTurnoverForDate(REPORT_DATE);

            assertThat(result.getTotalHandlingFees()).isEqualByComparingTo(BigDecimal.ZERO);
        }
    }

    @Test
    @DisplayName("FR-6: null tranzakciós díjnál a Shipment díj marad meg")
    void getDailyTurnoverForDate_treatsNullTransactionFeeAsZero() {
        stubTurnoverSources(REPORT_DATE, null, new BigDecimal("625"));

        try (MockedStatic<SecurityUtils> security = mockSecurity()) {
            TransactionService.DailyTurnoverSummary result =
                    transactionService.getDailyTurnoverForDate(REPORT_DATE);

            assertThat(result.getTotalHandlingFees()).isEqualByComparingTo("625");
        }
    }

    @Test
    @DisplayName("FR-6: null Shipment díjnál a tranzakciós díj marad meg")
    void getDailyTurnoverForDate_treatsNullShipmentFeeAsZero() {
        stubTurnoverSources(REPORT_DATE, new BigDecimal("1500"), null);

        try (MockedStatic<SecurityUtils> security = mockSecurity()) {
            TransactionService.DailyTurnoverSummary result =
                    transactionService.getDailyTurnoverForDate(REPORT_DATE);

            assertThat(result.getTotalHandlingFees()).isEqualByComparingTo("1500");
        }
    }

    @Test
    @DisplayName("FR-6: a mai turnover publikus belépő is hozzáadja a Shipment díjat")
    void getDailyTurnover_addsShipmentFeesForToday() {
        LocalDate today = LocalDate.now();
        stubTurnoverSources(today, new BigDecimal("100"), new BigDecimal("25"));

        try (MockedStatic<SecurityUtils> security = mockSecurity()) {
            TransactionService.DailyTurnoverSummary result = transactionService.getDailyTurnover();

            assertThat(result.getTotalHandlingFees()).isEqualByComparingTo("125");
            verify(shipmentHandlingFeeRepository)
                    .sumDailyReceivedFees(eq(COMPANY_ID), eq(BRANCH_ID), eq(today));
        }
    }

    private void stubTurnoverSources(
            LocalDate date,
            BigDecimal transactionFees,
            BigDecimal shipmentFees) {
        when(transactionRepository.sumDailyTurnover(COMPANY_ID, BRANCH_ID, date, TransactionType.BUY))
                .thenReturn(BigDecimal.ZERO);
        when(transactionRepository.sumDailyTurnover(COMPANY_ID, BRANCH_ID, date, TransactionType.SELL))
                .thenReturn(BigDecimal.ZERO);
        when(transactionRepository.sumDailyHandlingFees(BRANCH_ID, date)).thenReturn(transactionFees);
        when(shipmentHandlingFeeRepository.sumDailyReceivedFees(COMPANY_ID, BRANCH_ID, date))
                .thenReturn(shipmentFees);
    }

    private static MockedStatic<SecurityUtils> mockSecurity() {
        MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class);
        security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
        security.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
        return security;
    }
}
