package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.DailyDenominationSnapshot;
import hu.puzzleir.valuta.entity.DailySubledgerSnapshot;
import hu.puzzleir.valuta.entity.DailyWuAfaTransaction;
import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.entity.DenominationBalance;
import hu.puzzleir.valuta.entity.DenominationCategory;
import hu.puzzleir.valuta.entity.DenominationType;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.repository.DailyDenominationSnapshotRepository;
import hu.puzzleir.valuta.repository.DailySubledgerSnapshotRepository;
import hu.puzzleir.valuta.repository.DailyWuAfaTransactionRepository;
import hu.puzzleir.valuta.repository.DenominationBalanceRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * S1-02 DailyClosingArchiveService unit tesztek.
 * 10 teszt eset: happy path, duplikáció-védelem, category mapping, WU matching, üres nap.
 */
@ExtendWith(MockitoExtension.class)
class DailyClosingArchiveServiceTest {

    @Mock private DailyDenominationSnapshotRepository denominationSnapshotRepo;
    @Mock private DailySubledgerSnapshotRepository subledgerSnapshotRepo;
    @Mock private DailyWuAfaTransactionRepository wuAfaTransactionRepo;
    @Mock private DenominationBalanceRepository denominationBalanceRepo;
    @Mock private TransactionRepository transactionRepository;

    @InjectMocks
    private DailyClosingArchiveService service;

    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final LocalDate DATE = LocalDate.of(2026, 4, 4);

    private Currency usdCurrency;
    private Currency hufCurrency;

    @BeforeEach
    void setUp() {
        usdCurrency = new Currency();
        usdCurrency.setCode("USD");
        hufCurrency = new Currency();
        hufCurrency.setCode("HUF");
    }

    // --- snapshotDenominations ---

    @Test
    @DisplayName("snapshotDenominations: happy path - 2 db mentés, category mapping helyes")
    void snapshotDenominations_happyPath() {
        when(denominationSnapshotRepo.existsByBranchIdAndSnapshotDate(BRANCH_ID, DATE)).thenReturn(false);

        Denomination denom1 = new Denomination();
        denom1.setCurrency(hufCurrency);
        denom1.setDenominationType(DenominationType.BANKNOTE);
        denom1.setFaceValue(BigDecimal.valueOf(10000));

        DenominationBalance bal1 = DenominationBalance.builder()
                .cashDeskId(BRANCH_ID)
                .denomination(denom1)
                .quantity(5)
                .totalValue(BigDecimal.valueOf(50000))
                .denominationCategory(DenominationCategory.EVENING)
                .build();

        Denomination denom2 = new Denomination();
        denom2.setCurrency(usdCurrency);
        denom2.setDenominationType(DenominationType.BANKNOTE);
        denom2.setFaceValue(BigDecimal.valueOf(100));

        DenominationBalance bal2 = DenominationBalance.builder()
                .cashDeskId(BRANCH_ID)
                .denomination(denom2)
                .quantity(10)
                .totalValue(BigDecimal.valueOf(1000))
                .denominationCategory(DenominationCategory.WESTERN_UNION)
                .build();

        when(denominationBalanceRepo.findByBranchIdAndDate(BRANCH_ID, DATE)).thenReturn(List.of(bal1, bal2));

        int count = service.snapshotDenominations(BRANCH_ID, DATE);

        assertThat(count).isEqualTo(2);

        ArgumentCaptor<DailyDenominationSnapshot> captor = ArgumentCaptor.forClass(DailyDenominationSnapshot.class);
        verify(denominationSnapshotRepo, times(2)).save(captor.capture());

        List<DailyDenominationSnapshot> saved = captor.getAllValues();
        // B1 fix: category mapping
        assertThat(saved.get(0).getClosingType()).isEqualTo(1); // EVENING
        assertThat(saved.get(1).getClosingType()).isEqualTo(3); // WESTERN_UNION
    }

    @Test
    @DisplayName("snapshotDenominations: duplikáció-védelem — már létező snapshot")
    void snapshotDenominations_duplicate() {
        when(denominationSnapshotRepo.existsByBranchIdAndSnapshotDate(BRANCH_ID, DATE)).thenReturn(true);

        int count = service.snapshotDenominations(BRANCH_ID, DATE);

        assertThat(count).isEqualTo(0);
        verify(denominationSnapshotRepo, never()).save(any());
    }

    @Test
    @DisplayName("snapshotDenominations: 0 quantity kihagyva")
    void snapshotDenominations_zeroQuantitySkipped() {
        when(denominationSnapshotRepo.existsByBranchIdAndSnapshotDate(BRANCH_ID, DATE)).thenReturn(false);

        Denomination denom = new Denomination();
        denom.setCurrency(hufCurrency);
        denom.setDenominationType(DenominationType.BANKNOTE);
        denom.setFaceValue(BigDecimal.valueOf(5000));

        DenominationBalance bal = DenominationBalance.builder()
                .cashDeskId(BRANCH_ID)
                .denomination(denom)
                .quantity(0)
                .totalValue(BigDecimal.ZERO)
                .denominationCategory(DenominationCategory.EVENING)
                .build();

        when(denominationBalanceRepo.findByBranchIdAndDate(BRANCH_ID, DATE)).thenReturn(List.of(bal));

        int count = service.snapshotDenominations(BRANCH_ID, DATE);

        assertThat(count).isEqualTo(0);
        verify(denominationSnapshotRepo, never()).save(any());
    }

    @Test
    @DisplayName("FKH-054: same HUF COIN 100 on another submission_date is not snapshotted")
    void snapshotDenominations_ignoresOtherSubmissionDates() {
        when(denominationSnapshotRepo.existsByBranchIdAndSnapshotDate(BRANCH_ID, DATE)).thenReturn(false);

        Denomination coin100 = new Denomination();
        coin100.setCurrency(hufCurrency);
        coin100.setDenominationType(DenominationType.COIN);
        coin100.setFaceValue(BigDecimal.valueOf(100));

        DenominationBalance today = DenominationBalance.builder()
                .cashDeskId(BRANCH_ID)
                .denomination(coin100)
                .quantity(1)
                .totalValue(BigDecimal.valueOf(100))
                .denominationCategory(DenominationCategory.EVENING)
                .submissionDate(DATE)
                .build();

        when(denominationBalanceRepo.findByBranchIdAndDate(BRANCH_ID, DATE)).thenReturn(List.of(today));

        int count = service.snapshotDenominations(BRANCH_ID, DATE);

        assertThat(count).isEqualTo(1);
        verify(denominationBalanceRepo).findByBranchIdAndDate(BRANCH_ID, DATE);
        verify(denominationBalanceRepo, never()).findByCashDeskId(any());
        ArgumentCaptor<DailyDenominationSnapshot> captor = ArgumentCaptor.forClass(DailyDenominationSnapshot.class);
        verify(denominationSnapshotRepo).save(captor.capture());
        assertThat(captor.getValue().getFaceValue()).isEqualByComparingTo("100");
        assertThat(captor.getValue().getSnapshotDate()).isEqualTo(DATE);
        assertThat(captor.getValue().getQuantity()).isEqualTo(1);
    }

    // --- snapshotSubledger ---

    @Test
    @DisplayName("snapshotSubledger HANDLING_FEE: kezelési díj income aggregálás")
    void snapshotSubledger_handlingFee() {
        when(subledgerSnapshotRepo.existsByBranchIdAndSnapshotDateAndSubledgerType(
                BRANCH_ID, DATE, "HANDLING_FEE")).thenReturn(false);
        when(subledgerSnapshotRepo.findByBranchIdAndSnapshotDateAndSubledgerTypeAndCurrencyCode(
                eq(BRANCH_ID), any(), eq("HANDLING_FEE"), eq("HUF"))).thenReturn(Optional.empty());

        Transaction tx = buildTransaction(TransactionType.BUY, hufCurrency,
                BigDecimal.valueOf(100000), BigDecimal.valueOf(500));

        when(transactionRepository.findActiveByBranchAndDate(BRANCH_ID, DATE)).thenReturn(List.of(tx));

        service.snapshotSubledger(BRANCH_ID, DATE, "HANDLING_FEE", "HUF");

        ArgumentCaptor<DailySubledgerSnapshot> captor = ArgumentCaptor.forClass(DailySubledgerSnapshot.class);
        verify(subledgerSnapshotRepo).save(captor.capture());

        DailySubledgerSnapshot snap = captor.getValue();
        assertThat(snap.getSubledgerType()).isEqualTo("HANDLING_FEE");
        assertThat(snap.getIncome()).isEqualByComparingTo("500"); // handling fee
        assertThat(snap.getExpense()).isEqualByComparingTo("0");
        assertThat(snap.getClosingBalance()).isEqualByComparingTo("500");
    }

    @Test
    @DisplayName("snapshotSubledger WU_USD: WU receive = income, send = expense")
    void snapshotSubledger_wuUsd() {
        when(subledgerSnapshotRepo.existsByBranchIdAndSnapshotDateAndSubledgerType(
                BRANCH_ID, DATE, "WU_USD")).thenReturn(false);
        when(subledgerSnapshotRepo.findByBranchIdAndSnapshotDateAndSubledgerTypeAndCurrencyCode(
                eq(BRANCH_ID), any(), eq("WU_USD"), eq("USD"))).thenReturn(Optional.empty());

        Transaction receive = buildWuTransaction(TransactionType.WESTERN_UNION_RECEIVE, usdCurrency,
                BigDecimal.valueOf(500), BigDecimal.valueOf(150000));
        Transaction send = buildWuTransaction(TransactionType.WESTERN_UNION_SEND, usdCurrency,
                BigDecimal.valueOf(200), BigDecimal.valueOf(60000));

        when(transactionRepository.findActiveByBranchAndDate(BRANCH_ID, DATE))
                .thenReturn(List.of(receive, send));

        service.snapshotSubledger(BRANCH_ID, DATE, "WU_USD", "USD");

        ArgumentCaptor<DailySubledgerSnapshot> captor = ArgumentCaptor.forClass(DailySubledgerSnapshot.class);
        verify(subledgerSnapshotRepo).save(captor.capture());

        DailySubledgerSnapshot snap = captor.getValue();
        assertThat(snap.getIncome()).isEqualByComparingTo("500");
        assertThat(snap.getExpense()).isEqualByComparingTo("200");
        assertThat(snap.getClosingBalance()).isEqualByComparingTo("300"); // 0 + 500 - 200
    }

    @Test
    @DisplayName("snapshotSubledger WU_HUF: HUF oldal WU tranzakciókból")
    void snapshotSubledger_wuHuf() {
        when(subledgerSnapshotRepo.existsByBranchIdAndSnapshotDateAndSubledgerType(
                BRANCH_ID, DATE, "WU_HUF")).thenReturn(false);
        when(subledgerSnapshotRepo.findByBranchIdAndSnapshotDateAndSubledgerTypeAndCurrencyCode(
                eq(BRANCH_ID), any(), eq("WU_HUF"), eq("HUF"))).thenReturn(Optional.empty());

        Transaction receive = buildWuTransaction(TransactionType.WESTERN_UNION_RECEIVE, usdCurrency,
                BigDecimal.valueOf(500), BigDecimal.valueOf(150000));

        when(transactionRepository.findActiveByBranchAndDate(BRANCH_ID, DATE))
                .thenReturn(List.of(receive));

        service.snapshotSubledger(BRANCH_ID, DATE, "WU_HUF", "HUF");

        ArgumentCaptor<DailySubledgerSnapshot> captor = ArgumentCaptor.forClass(DailySubledgerSnapshot.class);
        verify(subledgerSnapshotRepo).save(captor.capture());

        DailySubledgerSnapshot snap = captor.getValue();
        assertThat(snap.getIncome()).isEqualByComparingTo("150000");
        assertThat(snap.getExpense()).isEqualByComparingTo("0");
    }

    @Test
    @DisplayName("snapshotSubledger duplikáció-védelem")
    void snapshotSubledger_duplicate() {
        when(subledgerSnapshotRepo.existsByBranchIdAndSnapshotDateAndSubledgerType(
                BRANCH_ID, DATE, "ECOMMERCE")).thenReturn(true);

        service.snapshotSubledger(BRANCH_ID, DATE, "ECOMMERCE", "HUF");

        verify(subledgerSnapshotRepo, never()).save(any());
    }

    // --- snapshotWuAfaTransactions ---

    @Test
    @DisplayName("snapshotWuAfaTransactions: WU tételek archiválása")
    void snapshotWuAfaTransactions_happyPath() {
        when(wuAfaTransactionRepo.existsByBranchIdAndTransactionDate(BRANCH_ID, DATE)).thenReturn(false);

        Transaction wuSend = buildWuTransaction(TransactionType.WESTERN_UNION_SEND, usdCurrency,
                BigDecimal.valueOf(200), BigDecimal.valueOf(60000));
        wuSend.setReceiptNumber("WU-001");

        Transaction nonWu = buildTransaction(TransactionType.BUY, usdCurrency,
                BigDecimal.valueOf(100), BigDecimal.ZERO);
        nonWu.setReceiptNumber("TX-002");

        when(transactionRepository.findActiveByBranchAndDate(BRANCH_ID, DATE))
                .thenReturn(List.of(wuSend, nonWu));

        int count = service.snapshotWuAfaTransactions(BRANCH_ID, DATE);

        assertThat(count).isEqualTo(1); // only WU, not BUY

        ArgumentCaptor<DailyWuAfaTransaction> captor = ArgumentCaptor.forClass(DailyWuAfaTransaction.class);
        verify(wuAfaTransactionRepo).save(captor.capture());

        DailyWuAfaTransaction saved = captor.getValue();
        assertThat(saved.getSign()).isEqualTo("-");
        assertThat(saved.getReceiptType()).isEqualTo("WU");
    }

    @Test
    @DisplayName("snapshotWuAfaTransactions: üres nap — nincs WU tranzakció")
    void snapshotWuAfaTransactions_emptyDay() {
        when(wuAfaTransactionRepo.existsByBranchIdAndTransactionDate(BRANCH_ID, DATE)).thenReturn(false);
        when(transactionRepository.findActiveByBranchAndDate(BRANCH_ID, DATE)).thenReturn(List.of());

        int count = service.snapshotWuAfaTransactions(BRANCH_ID, DATE);

        assertThat(count).isEqualTo(0);
        verify(wuAfaTransactionRepo, never()).save(any());
    }

    // --- executeFullDailyArchive ---

    @Test
    @DisplayName("executeFullDailyArchive: orchestrál, visszaad summary-t")
    void executeFullDailyArchive_orchestrates() {
        // All duplication checks return false (first run)
        when(denominationSnapshotRepo.existsByBranchIdAndSnapshotDate(BRANCH_ID, DATE)).thenReturn(false);
        when(denominationBalanceRepo.findByBranchIdAndDate(BRANCH_ID, DATE)).thenReturn(List.of());
        when(subledgerSnapshotRepo.existsByBranchIdAndSnapshotDateAndSubledgerType(
                eq(BRANCH_ID), eq(DATE), anyString())).thenReturn(false);
        when(subledgerSnapshotRepo.findByBranchIdAndSnapshotDateAndSubledgerTypeAndCurrencyCode(
                eq(BRANCH_ID), any(), anyString(), anyString())).thenReturn(Optional.empty());
        when(transactionRepository.findActiveByBranchAndDate(BRANCH_ID, DATE)).thenReturn(List.of());
        when(wuAfaTransactionRepo.existsByBranchIdAndTransactionDate(BRANCH_ID, DATE)).thenReturn(false);

        String summary = service.executeFullDailyArchive(BRANCH_ID, DATE);

        assertThat(summary).contains("Címletezés", "E-kereskedelem", "Kezelési díj", "WU/ÁFA");
    }

    // --- Extra tesztek (Eszter kérésére) ---

    @Test
    @DisplayName("snapshotSubledger WU_VAT: WU_SEND handlingFee=1270 Ft → ÁFA = 269.76 Ft (27/127 formula)")
    void snapshotSubledger_wuVat_handlingFeeAfaFormula() {
        when(subledgerSnapshotRepo.existsByBranchIdAndSnapshotDateAndSubledgerType(
                BRANCH_ID, DATE, "WU_VAT")).thenReturn(false);
        when(subledgerSnapshotRepo.findByBranchIdAndSnapshotDateAndSubledgerTypeAndCurrencyCode(
                eq(BRANCH_ID), any(), eq("WU_VAT"), eq("HUF"))).thenReturn(Optional.empty());

        Transaction wuSend = new Transaction();
        wuSend.setTransactionType(TransactionType.WESTERN_UNION_SEND);
        wuSend.setCurrency(usdCurrency);
        wuSend.setCurrencyAmount(BigDecimal.valueOf(100));
        wuSend.setHufAmount(BigDecimal.valueOf(30000));
        wuSend.setHandlingFee(BigDecimal.valueOf(1270));
        wuSend.setReceiptNumber("WU-VAT-001");

        when(transactionRepository.findActiveByBranchAndDate(BRANCH_ID, DATE))
                .thenReturn(List.of(wuSend));

        service.snapshotSubledger(BRANCH_ID, DATE, "WU_VAT", "HUF");

        ArgumentCaptor<DailySubledgerSnapshot> captor = ArgumentCaptor.forClass(DailySubledgerSnapshot.class);
        verify(subledgerSnapshotRepo).save(captor.capture());

        DailySubledgerSnapshot snap = captor.getValue();
        assertThat(snap.getSubledgerType()).isEqualTo("WU_VAT");
        // 1270 * 27 / 127 = 34290 / 127 = 270.00 (pontosan osztható, HALF_UP, 2 tizedes)
        assertThat(snap.getIncome()).isEqualByComparingTo("270.00");
        assertThat(snap.getExpense()).isEqualByComparingTo("0");
        assertThat(snap.getClosingBalance()).isEqualByComparingTo("270.00");
    }

    @Test
    @DisplayName("snapshotSubledger ECOMMERCE: OTHER típusú tranzakció → income aggregálás, BUY kihagyva")
    void snapshotSubledger_ecommerce_happyPath() {
        when(subledgerSnapshotRepo.existsByBranchIdAndSnapshotDateAndSubledgerType(
                BRANCH_ID, DATE, "ECOMMERCE")).thenReturn(false);
        when(subledgerSnapshotRepo.findByBranchIdAndSnapshotDateAndSubledgerTypeAndCurrencyCode(
                eq(BRANCH_ID), any(), eq("ECOMMERCE"), eq("HUF"))).thenReturn(Optional.empty());

        Transaction ecomTx = new Transaction();
        ecomTx.setTransactionType(TransactionType.OTHER);
        ecomTx.setCurrency(hufCurrency);
        ecomTx.setHufAmount(BigDecimal.valueOf(45000));
        ecomTx.setHandlingFee(BigDecimal.ZERO);
        ecomTx.setReceiptNumber("EC-001");

        // BUY típus NEM kerül ECOMMERCE subledgerbe
        Transaction nonEcom = buildTransaction(TransactionType.BUY, hufCurrency,
                BigDecimal.valueOf(100000), BigDecimal.ZERO);

        when(transactionRepository.findActiveByBranchAndDate(BRANCH_ID, DATE))
                .thenReturn(List.of(ecomTx, nonEcom));

        service.snapshotSubledger(BRANCH_ID, DATE, "ECOMMERCE", "HUF");

        ArgumentCaptor<DailySubledgerSnapshot> captor = ArgumentCaptor.forClass(DailySubledgerSnapshot.class);
        verify(subledgerSnapshotRepo).save(captor.capture());

        DailySubledgerSnapshot snap = captor.getValue();
        assertThat(snap.getSubledgerType()).isEqualTo("ECOMMERCE");
        assertThat(snap.getIncome()).isEqualByComparingTo("45000");   // csak az OTHER kerül be
        assertThat(snap.getExpense()).isEqualByComparingTo("0");
        assertThat(snap.getClosingBalance()).isEqualByComparingTo("45000");
    }

    @Test
    @DisplayName("snapshotWuAfaSubledgers: orchestráció — 3x hívja snapshotSubledger (WU_USD, WU_HUF, WU_VAT)")
    void snapshotWuAfaSubledgers_callsThreeSubledgers() {
        when(subledgerSnapshotRepo.existsByBranchIdAndSnapshotDateAndSubledgerType(
                eq(BRANCH_ID), eq(DATE), anyString())).thenReturn(false);
        when(subledgerSnapshotRepo.findByBranchIdAndSnapshotDateAndSubledgerTypeAndCurrencyCode(
                eq(BRANCH_ID), any(), anyString(), anyString())).thenReturn(Optional.empty());
        when(transactionRepository.findActiveByBranchAndDate(BRANCH_ID, DATE)).thenReturn(List.of());

        service.snapshotWuAfaSubledgers(BRANCH_ID, DATE);

        // 3 al-pénztár snapshotot kell menteni: WU_USD, WU_HUF, WU_VAT
        ArgumentCaptor<DailySubledgerSnapshot> captor = ArgumentCaptor.forClass(DailySubledgerSnapshot.class);
        verify(subledgerSnapshotRepo, times(3)).save(captor.capture());

        List<DailySubledgerSnapshot> saved = captor.getAllValues();
        assertThat(saved)
                .extracting(DailySubledgerSnapshot::getSubledgerType)
                .containsExactlyInAnyOrder("WU_USD", "WU_HUF", "WU_VAT");
    }

    // --- helpers ---

    private Transaction buildTransaction(TransactionType type, Currency currency,
                                          BigDecimal hufAmount, BigDecimal handlingFee) {
        Transaction tx = new Transaction();
        tx.setTransactionType(type);
        tx.setCurrency(currency);
        tx.setHufAmount(hufAmount);
        tx.setHandlingFee(handlingFee);
        tx.setReceiptNumber("TX-" + UUID.randomUUID().toString().substring(0, 6));
        return tx;
    }

    private Transaction buildWuTransaction(TransactionType type, Currency currency,
                                            BigDecimal currencyAmount, BigDecimal hufAmount) {
        Transaction tx = new Transaction();
        tx.setTransactionType(type);
        tx.setCurrency(currency);
        tx.setCurrencyAmount(currencyAmount);
        tx.setHufAmount(hufAmount);
        tx.setHandlingFee(BigDecimal.ZERO);
        tx.setReceiptNumber("WU-" + UUID.randomUUID().toString().substring(0, 6));
        return tx;
    }
}
