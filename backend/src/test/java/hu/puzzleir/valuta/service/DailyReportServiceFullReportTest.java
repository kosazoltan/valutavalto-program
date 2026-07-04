package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.report.DailyReportFullDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class DailyReportServiceFullReportTest {

    @Mock private ReportService reportService;
    @Mock private DailyReportRepository dailyReportRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private DailyBalanceRepository dailyBalanceRepository;
    @Mock private TransactionRepository transactionRepository;
    @Mock private DenominationBalanceRepository denominationBalanceRepository;
    @Mock private DailySubledgerSnapshotRepository subledgerSnapshotRepository;
    @Mock private ExchangeRateRepository exchangeRateRepository;
    @Mock private CurrencyRepository currencyRepository;

    @InjectMocks
    private DailyReportService service;

    private static final UUID BRANCH_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID COMPANY_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");
    private static final LocalDate DATE = LocalDate.of(2026, 4, 4);
    private Branch branch;

    @BeforeEach
    void setUp() {
        Company company = new Company();
        company.setId(COMPANY_ID);
        branch = new Branch();
        branch.setId(BRANCH_ID);
        branch.setCode("101");
        branch.setName("Test Iroda");
        branch.setCompany(company);
    }

    @Test
    @DisplayName("B1 fix: currencyName kitöltve a Currency entitásból")
    void currencyName_filled() {
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));

        Currency eur = new Currency();
        eur.setCode("EUR");
        eur.setName("Euró");
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of(eur));

        DailyBalance eurBal = new DailyBalance();
        eurBal.setCurrencyCode("EUR");
        eurBal.setClosingBalance(new BigDecimal("500"));
        eurBal.setPurchases(new BigDecimal("100"));
        eurBal.setSales(new BigDecimal("50"));
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(org.mockito.ArgumentMatchers.eq(COMPANY_ID), org.mockito.ArgumentMatchers.eq(BRANCH_ID), org.mockito.ArgumentMatchers.eq(DATE))).thenReturn(List.of(eurBal));
        when(exchangeRateRepository.findActiveByDateAndBranch(any(), eq(DATE), eq(BRANCH_ID))).thenReturn(List.of());
        when(transactionRepository.findFinanciallyEffectiveByBranchAndDate(BRANCH_ID, DATE)).thenReturn(List.of());
        when(denominationBalanceRepository.findByBranchIdAndDate(BRANCH_ID, DATE)).thenReturn(List.of());
        stubSubledger();

        DailyReportFullDto result = service.generateFullReport(BRANCH_ID, DATE);

        assertThat(result.getCurrencyLines()).hasSize(1);
        assertThat(result.getCurrencyLines().get(0).getCurrencyName()).isEqualTo("Euró");
    }

    @Test
    @DisplayName("B3 fix: buyHuf/sellHuf HUF ekvivalens számítva (amount * rate)")
    void buyHuf_sellHuf_calculated() {
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));

        Currency eur = new Currency();
        eur.setCode("EUR");
        eur.setName("Euró");
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of(eur));

        DailyBalance eurBal = new DailyBalance();
        eurBal.setCurrencyCode("EUR");
        eurBal.setClosingBalance(new BigDecimal("500"));
        eurBal.setPurchases(new BigDecimal("100"));
        eurBal.setSales(new BigDecimal("50"));
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(org.mockito.ArgumentMatchers.eq(COMPANY_ID), org.mockito.ArgumentMatchers.eq(BRANCH_ID), org.mockito.ArgumentMatchers.eq(DATE))).thenReturn(List.of(eurBal));

        ExchangeRate er = new ExchangeRate();
        er.setCurrency(eur);
        er.setBaseBuyRate(new BigDecimal("395.50"));
        er.setBaseSellRate(new BigDecimal("401.20"));
        when(exchangeRateRepository.findActiveByDateAndBranch(any(), eq(DATE), eq(BRANCH_ID))).thenReturn(List.of(er));
        when(transactionRepository.findFinanciallyEffectiveByBranchAndDate(BRANCH_ID, DATE)).thenReturn(List.of());
        when(denominationBalanceRepository.findByBranchIdAndDate(BRANCH_ID, DATE)).thenReturn(List.of());
        stubSubledger();

        DailyReportFullDto result = service.generateFullReport(BRANCH_ID, DATE);

        DailyReportFullDto.CurrencyLineDto line = result.getCurrencyLines().get(0);
        // 100 * 395.50 = 39550.00
        assertThat(line.getBuyHuf()).isEqualByComparingTo("39550.00");
        // 50 * 401.20 = 20060.00
        assertThat(line.getSellHuf()).isEqualByComparingTo("20060.00");
    }

    @Test
    @DisplayName("B2+B4 fix: findByBranchIdAndDate használata (nem findByCashDeskId)")
    void denomination_uses_branchIdAndDate() {
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of());
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(org.mockito.ArgumentMatchers.eq(COMPANY_ID), org.mockito.ArgumentMatchers.eq(BRANCH_ID), org.mockito.ArgumentMatchers.eq(DATE))).thenReturn(List.of());
        when(exchangeRateRepository.findActiveByDateAndBranch(any(), eq(DATE), eq(BRANCH_ID))).thenReturn(List.of());
        when(transactionRepository.findFinanciallyEffectiveByBranchAndDate(BRANCH_ID, DATE)).thenReturn(List.of());

        // Denomination setup
        Currency huf = new Currency();
        huf.setCode("HUF");
        huf.setName("Magyar forint");
        Denomination d20k = new Denomination();
        d20k.setCurrency(huf);
        d20k.setFaceValue(new BigDecimal("20000"));
        d20k.setDenominationType(DenominationType.BANKNOTE);

        DenominationBalance db = new DenominationBalance();
        db.setDenomination(d20k);
        db.setDenominationCategory(DenominationCategory.EVENING);
        db.setQuantity(5);
        db.setTotalValue(new BigDecimal("100000"));

        when(denominationBalanceRepository.findByBranchIdAndDate(BRANCH_ID, DATE)).thenReturn(List.of(db));
        stubSubledger();

        DailyReportFullDto result = service.generateFullReport(BRANCH_ID, DATE);

        // Verify: findByBranchIdAndDate hívás, NEM findByCashDeskId
        verify(denominationBalanceRepository).findByBranchIdAndDate(BRANCH_ID, DATE);
        verify(denominationBalanceRepository, never()).findByCashDeskId(any());

        assertThat(result.getHufDenominations()).hasSize(1);
        assertThat(result.getHufDenominations().get(0).getQuantity()).isEqualTo(5);
        assertThat(result.getDenominatedTotalHuf()).isEqualByComparingTo("100000");
    }

    @Test
    @DisplayName("DE/DU forgalom: tranzakciók idő alapján bontva")
    void deDu_turnover_split() {
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of());
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(org.mockito.ArgumentMatchers.eq(COMPANY_ID), org.mockito.ArgumentMatchers.eq(BRANCH_ID), org.mockito.ArgumentMatchers.eq(DATE))).thenReturn(List.of());
        when(exchangeRateRepository.findActiveByDateAndBranch(any(), eq(DATE), eq(BRANCH_ID))).thenReturn(List.of());
        when(denominationBalanceRepository.findByBranchIdAndDate(BRANCH_ID, DATE)).thenReturn(List.of());
        stubSubledger();

        Transaction morningBuyTx = createTransaction(TransactionType.BUY, new BigDecimal("50000"), LocalTime.of(9, 30));
        Transaction afternoonSellTx = createTransaction(TransactionType.SELL, new BigDecimal("30000"), LocalTime.of(14, 15));
        Transaction reversalTx = createTransaction(TransactionType.REVERSAL, new BigDecimal("10000"), LocalTime.of(16, 0));

        when(transactionRepository.findFinanciallyEffectiveByBranchAndDate(BRANCH_ID, DATE))
                .thenReturn(List.of(morningBuyTx, afternoonSellTx, reversalTx));

        DailyReportFullDto result = service.generateFullReport(BRANCH_ID, DATE);

        assertThat(result.getMorningBuyHuf()).isEqualByComparingTo("50000");
        assertThat(result.getAfternoonSellHuf()).isEqualByComparingTo("30000");
        assertThat(result.getBuyCount()).isEqualTo(1);
        assertThat(result.getSellCount()).isEqualTo(1);
        assertThat(result.getReversalCount()).isEqualTo(1);
        assertThat(result.getTransactionCount()).isEqualTo(3);
    }

    @Test
    @DisplayName("WU/ÁFA/E-kereskedelem a DailySubledgerSnapshot-ból")
    void wuAfa_ecommerce_from_snapshot() {
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of());
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(org.mockito.ArgumentMatchers.eq(COMPANY_ID), org.mockito.ArgumentMatchers.eq(BRANCH_ID), org.mockito.ArgumentMatchers.eq(DATE))).thenReturn(List.of());
        when(exchangeRateRepository.findActiveByDateAndBranch(any(), eq(DATE), eq(BRANCH_ID))).thenReturn(List.of());
        when(transactionRepository.findFinanciallyEffectiveByBranchAndDate(BRANCH_ID, DATE)).thenReturn(List.of());
        when(denominationBalanceRepository.findByBranchIdAndDate(BRANCH_ID, DATE)).thenReturn(List.of());

        DailySubledgerSnapshot wuUsdSnap = new DailySubledgerSnapshot();
        wuUsdSnap.setClosingBalance(new BigDecimal("1250.00"));
        DailySubledgerSnapshot wuHufSnap = new DailySubledgerSnapshot();
        wuHufSnap.setClosingBalance(new BigDecimal("500000"));
        DailySubledgerSnapshot vatSnap = new DailySubledgerSnapshot();
        vatSnap.setClosingBalance(new BigDecimal("35000"));
        DailySubledgerSnapshot ecomSnap = new DailySubledgerSnapshot();
        ecomSnap.setClosingBalance(new BigDecimal("125000"));
        DailySubledgerSnapshot handlingFeeSnap = new DailySubledgerSnapshot();
        handlingFeeSnap.setOpeningBalance(new BigDecimal("12000"));
        handlingFeeSnap.setIncome(new BigDecimal("8500"));
        handlingFeeSnap.setExpense(new BigDecimal("3000"));

        when(subledgerSnapshotRepository.findByBranchIdAndSnapshotDateAndSubledgerTypeAndCurrencyCode(
                BRANCH_ID, DATE, "WU_USD", "USD")).thenReturn(Optional.of(wuUsdSnap));
        when(subledgerSnapshotRepository.findByBranchIdAndSnapshotDateAndSubledgerTypeAndCurrencyCode(
                BRANCH_ID, DATE, "WU_HUF", "HUF")).thenReturn(Optional.of(wuHufSnap));
        when(subledgerSnapshotRepository.findByBranchIdAndSnapshotDateAndSubledgerTypeAndCurrencyCode(
                BRANCH_ID, DATE, "WU_VAT", "HUF")).thenReturn(Optional.of(vatSnap));
        when(subledgerSnapshotRepository.findByBranchIdAndSnapshotDateAndSubledgerTypeAndCurrencyCode(
                BRANCH_ID, DATE, "ECOMMERCE", "HUF")).thenReturn(Optional.of(ecomSnap));
        when(subledgerSnapshotRepository.findByBranchIdAndSnapshotDateAndSubledgerTypeAndCurrencyCode(
                BRANCH_ID, DATE, "HANDLING_FEE", "HUF")).thenReturn(Optional.of(handlingFeeSnap));

        DailyReportFullDto result = service.generateFullReport(BRANCH_ID, DATE);

        assertThat(result.getWuUsdBalance()).isEqualByComparingTo("1250.00");
        assertThat(result.getWuHufBalance()).isEqualByComparingTo("500000");
        assertThat(result.getAfaBalance()).isEqualByComparingTo("35000");
        assertThat(result.getEcommerceBalanceHuf()).isEqualByComparingTo("125000");
        assertThat(result.getHandlingFeeOpening()).isEqualByComparingTo("12000");
        assertThat(result.getHandlingFeeIncome()).isEqualByComparingTo("8500");
        assertThat(result.getHandlingFeeExpense()).isEqualByComparingTo("3000");
    }

    @Test
    @DisplayName("Pénztáros nevek DE/DU műszakból")
    void cashier_names() {
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of());
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(org.mockito.ArgumentMatchers.eq(COMPANY_ID), org.mockito.ArgumentMatchers.eq(BRANCH_ID), org.mockito.ArgumentMatchers.eq(DATE))).thenReturn(List.of());
        when(exchangeRateRepository.findActiveByDateAndBranch(any(), eq(DATE), eq(BRANCH_ID))).thenReturn(List.of());
        when(denominationBalanceRepository.findByBranchIdAndDate(BRANCH_ID, DATE)).thenReturn(List.of());
        stubSubledger();

        Worker morningWorker = new Worker();
        morningWorker.setName("Kovács Anna");
        Transaction morningTx = createTransaction(TransactionType.BUY, new BigDecimal("10000"), LocalTime.of(9, 0));
        morningTx.setWorker(morningWorker);

        Worker afternoonWorker = new Worker();
        afternoonWorker.setName("Nagy Béla");
        Transaction afternoonTx = createTransaction(TransactionType.SELL, new BigDecimal("20000"), LocalTime.of(14, 0));
        afternoonTx.setWorker(afternoonWorker);

        when(transactionRepository.findFinanciallyEffectiveByBranchAndDate(BRANCH_ID, DATE))
                .thenReturn(List.of(morningTx, afternoonTx));

        DailyReportFullDto result = service.generateFullReport(BRANCH_ID, DATE);

        assertThat(result.getMorningCashierName()).isEqualTo("Kovács Anna");
        assertThat(result.getAfternoonCashierName()).isEqualTo("Nagy Béla");
    }

    @Test
    @DisplayName("Nem létező branch ResourceNotFoundException")
    void branchNotFound() {
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.generateFullReport(BRANCH_ID, DATE))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    @DisplayName("Kedvezmények: egyedi árfolyam != bázis árfolyam")
    void discountLines_collected() {
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));

        Currency eur = new Currency();
        eur.setCode("EUR");
        eur.setName("Euró");
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of(eur));
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(org.mockito.ArgumentMatchers.eq(COMPANY_ID), org.mockito.ArgumentMatchers.eq(BRANCH_ID), org.mockito.ArgumentMatchers.eq(DATE))).thenReturn(List.of());

        ExchangeRate er = new ExchangeRate();
        er.setCurrency(eur);
        er.setBaseBuyRate(new BigDecimal("395.50"));
        er.setBaseSellRate(new BigDecimal("401.20"));
        when(exchangeRateRepository.findActiveByDateAndBranch(any(), eq(DATE), eq(BRANCH_ID))).thenReturn(List.of(er));
        when(denominationBalanceRepository.findByBranchIdAndDate(BRANCH_ID, DATE)).thenReturn(List.of());
        stubSubledger();

        // Kedvezményes tranzakció: más árfolyam mint a bázis
        Transaction discountTx = createTransaction(TransactionType.BUY, new BigDecimal("50000"), LocalTime.of(10, 0));
        discountTx.setCurrency(eur);
        discountTx.setCurrencyAmount(new BigDecimal("200"));
        discountTx.setExchangeRate(new BigDecimal("396.00")); // != 395.50
        discountTx.setReceiptNumber("B-2026-001");

        when(transactionRepository.findFinanciallyEffectiveByBranchAndDate(BRANCH_ID, DATE)).thenReturn(List.of(discountTx));

        DailyReportFullDto result = service.generateFullReport(BRANCH_ID, DATE);

        assertThat(result.getDiscountLines()).hasSize(1);
        assertThat(result.getDiscountLines().get(0).getCurrencyCode()).isEqualTo("EUR");
        assertThat(result.getDiscountLines().get(0).getDiscountRate()).isEqualByComparingTo("396.00");
    }

    @Test
    @DisplayName("closingBalanceForeign HUF-ekvivalensben (midRate-tel)")
    void closingForeignHuf_equivalent() {
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));

        Currency eur = new Currency();
        eur.setCode("EUR");
        eur.setName("Euró");
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of(eur));

        DailyBalance eurBal = new DailyBalance();
        eurBal.setCurrencyCode("EUR");
        eurBal.setClosingBalance(new BigDecimal("1000"));
        eurBal.setPurchases(BigDecimal.ZERO);
        eurBal.setSales(BigDecimal.ZERO);
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(org.mockito.ArgumentMatchers.eq(COMPANY_ID), org.mockito.ArgumentMatchers.eq(BRANCH_ID), org.mockito.ArgumentMatchers.eq(DATE))).thenReturn(List.of(eurBal));

        ExchangeRate er = new ExchangeRate();
        er.setCurrency(eur);
        er.setBaseBuyRate(new BigDecimal("394.00"));
        er.setBaseSellRate(new BigDecimal("402.00"));
        when(exchangeRateRepository.findActiveByDateAndBranch(any(), eq(DATE), eq(BRANCH_ID))).thenReturn(List.of(er));
        when(transactionRepository.findFinanciallyEffectiveByBranchAndDate(BRANCH_ID, DATE)).thenReturn(List.of());
        when(denominationBalanceRepository.findByBranchIdAndDate(BRANCH_ID, DATE)).thenReturn(List.of());
        stubSubledger();

        DailyReportFullDto result = service.generateFullReport(BRANCH_ID, DATE);

        // midRate = (394 + 402) / 2 = 398.00; closingForeign = 1000 * 398 = 398000
        assertThat(result.getClosingBalanceForeign()).isEqualByComparingTo("398000.00");
    }

    // ============ HELPERS ============

    private Transaction createTransaction(TransactionType type, BigDecimal hufAmount, LocalTime time) {
        Transaction tx = new Transaction();
        tx.setTransactionType(type);
        tx.setHufAmount(hufAmount);
        tx.setTransactionTime(time);
        tx.setHandlingFee(BigDecimal.ZERO);
        return tx;
    }

    private void stubSubledger() {
        when(subledgerSnapshotRepository.findByBranchIdAndSnapshotDateAndSubledgerTypeAndCurrencyCode(
                any(), any(), any(), any())).thenReturn(Optional.empty());
    }
}
