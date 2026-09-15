package hu.puzzleir.valuta.service.central;

import hu.puzzleir.valuta.dto.central.ReceivedStornoDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionLine;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.entity.Transfer;
import hu.puzzleir.valuta.entity.TransferLine;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.TransferRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.MnbExchangeRateService;
import hu.puzzleir.valuta.service.MnbSettlementRateService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ReceivedStornoServiceTest {

    private static final UUID COMPANY_ID = UUID.fromString("10000000-0000-0000-0000-000000000001");
    private static final UUID BRANCH_A = UUID.fromString("20000000-0000-0000-0000-00000000000a");
    private static final LocalDate FROM = LocalDate.of(2026, 9, 10);
    private static final LocalDate TO = LocalDate.of(2026, 9, 12);

    private final TransactionRepository transactionRepository = mock(TransactionRepository.class);
    private final TransferRepository transferRepository = mock(TransferRepository.class);
    private final BranchRepository branchRepository = mock(BranchRepository.class);
    private final WorkerRepository workerRepository = mock(WorkerRepository.class);
    private final MnbExchangeRateService mnbExchangeRateService = mock(MnbExchangeRateService.class);
    private final MnbSettlementRateService mnbSettlementRateService = mock(MnbSettlementRateService.class);
    private final ReceivedStornoService service = new ReceivedStornoService(
            transactionRepository, transferRepository, branchRepository, workerRepository,
            mnbExchangeRateService, mnbSettlementRateService);

    @Test
    @DisplayName("FR-1/FR-4: REVERSAL + cancelled Transfer merged, newest first; REJECTED excluded by query")
    void mergesAndSortsDescending() {
        Branch office = branch(BRANCH_A, "BR001");
        when(branchRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of(office));
        Worker cashier = Worker.builder().id(7L).name("Kovács Anna").build();
        Transaction original = Transaction.builder()
                .receiptNumber("V-100")
                .lines(List.of(line(currency("EUR"), new BigDecimal("100"), new BigDecimal("38000"))))
                .build();
        Transaction reversal = Transaction.builder()
                .branch(office)
                .worker(cashier)
                .transactionDate(FROM)
                .transactionTime(LocalTime.of(10, 0))
                .receiptNumber("V-100-SZ")
                .reversalReason("ügyfél kérése")
                .originalTransaction(original)
                .build();
        Transfer transfer = Transfer.builder()
                .fromBranch(office)
                .transferNumber("AT-9")
                .cancelledAt(LocalDateTime.of(TO, LocalTime.of(15, 0)))
                .cancelledBy(8L)
                .cancellationReason("hibás összeg")
                .currency(currency("HUF"))
                .amount(new BigDecimal("5000"))
                .hufValue(new BigDecimal("5000"))
                .status(Transfer.TransferStatus.CANCELLED)
                .isCancelled(true)
                .lines(List.of())
                .build();
        when(transactionRepository.findReversalsForReceivedData(
                eq(COMPANY_ID), eq(TransactionType.REVERSAL), eq(FROM), eq(TO), eq(true),
                eq(List.of(ReceivedStornoService.EMPTY_IN_SENTINEL))))
                .thenReturn(List.of(reversal));
        when(transferRepository.findCancelledForReceivedData(
                eq(COMPANY_ID), any(), any(), eq(true),
                eq(List.of(ReceivedStornoService.EMPTY_IN_SENTINEL)),
                eq(Transfer.TransferStatus.REJECTED)))
                .thenReturn(List.of(transfer));
        when(workerRepository.findAllById(any())).thenReturn(List.of(
                Worker.builder().id(8L).name("Nagy Péter").build()));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            ReceivedStornoDto dto = service.load(FROM, TO, null, null);
            assertThat(dto.getRows()).hasSize(2);
            assertThat(dto.getRows().get(0).getType()).isEqualTo(ReceivedStornoDto.TYPE_TRANSFER);
            assertThat(dto.getRows().get(0).getStornoDocumentNumber()).isEqualTo("AT-9-SZ");
            assertThat(dto.getRows().get(0).getWorkerName()).isEqualTo("Nagy Péter");
            assertThat(dto.getRows().get(1).getType()).isEqualTo(ReceivedStornoDto.TYPE_SALE_PURCHASE);
            assertThat(dto.getRows().get(1).getOriginalDocumentNumber()).isEqualTo("V-100");
            assertThat(dto.getRows().get(1).getLines()).hasSize(1);
            assertThat(dto.getRows().get(1).getLines().get(0).getAmount()).isEqualByComparingTo("100");
        }
        verify(transferRepository).findCancelledForReceivedData(
                eq(COMPANY_ID), any(), any(), eq(true), anyList(), eq(Transfer.TransferStatus.REJECTED));
    }

    @Test
    @DisplayName("FR-3: multi-currency transfer values lines with MNB rate; missing rate is nincs adat")
    void multiLineTransferUsesMnbAndFailOpen() {
        Branch office = branch(BRANCH_A, "ET1");
        office.setIsVault(true);
        when(branchRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of(office));
        when(transactionRepository.findReversalsForReceivedData(any(), any(), any(), any(), anyBoolean(), anyList()))
                .thenReturn(List.of());
        TransferLine eur = TransferLine.builder()
                .currency(currency("EUR"))
                .amount(new BigDecimal("10"))
                .lineNo(1)
                .build();
        TransferLine bam = TransferLine.builder()
                .currency(currency("BAM"))
                .amount(new BigDecimal("20"))
                .lineNo(2)
                .build();
        Transfer transfer = Transfer.builder()
                .fromBranch(office)
                .transferNumber("AT-M")
                .cancelledAt(LocalDateTime.of(FROM, LocalTime.of(9, 0)))
                .transferDate(FROM)
                .currency(currency("EUR"))
                .amount(new BigDecimal("10"))
                .hufValue(null)
                .isCancelled(true)
                .status(Transfer.TransferStatus.CANCELLED)
                .lines(List.of(eur, bam))
                .build();
        when(transferRepository.findCancelledForReceivedData(any(), any(), any(), anyBoolean(), anyList(), any()))
                .thenReturn(List.of(transfer));
        hu.puzzleir.valuta.entity.MnbExchangeRateCache eurRate =
                hu.puzzleir.valuta.entity.MnbExchangeRateCache.builder()
                        .currencyCode("EUR")
                        .officialRate(new BigDecimal("380"))
                        .unit(1)
                        .rateDate(FROM)
                        .build();
        when(mnbExchangeRateService.getRatesForDate(any())).thenReturn(Map.of());
        when(mnbExchangeRateService.getRatesForDate(FROM)).thenReturn(Map.of("EUR", eurRate));
        when(mnbSettlementRateService.findSettlementRateAsOf(COMPANY_ID, "BAM", FROM))
                .thenReturn(Optional.empty());

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            ReceivedStornoDto dto = service.load(FROM, TO, null, null);
            assertThat(dto.getRows()).hasSize(1);
            assertThat(dto.getRows().get(0).getLines()).hasSize(2);
            assertThat(dto.getRows().get(0).getLines().get(0).isRateMissing()).isFalse();
            assertThat(dto.getRows().get(0).getLines().get(0).getHufValue()).isEqualByComparingTo("3800");
            assertThat(dto.getRows().get(0).getLines().get(1).isRateMissing()).isTrue();
            assertThat(dto.getRows().get(0).getLines().get(1).getHufValue()).isNull();
        }
    }

    @Test
    @DisplayName("fromDate after toDate is rejected")
    void invertedRangeRejected() {
        assertThatThrownBy(() -> service.load(TO, FROM, null, null))
                .isInstanceOf(ValidationException.class);
    }

    private static Branch branch(UUID id, String code) {
        Branch branch = new Branch();
        branch.setId(id);
        branch.setCode(code);
        branch.setName(code);
        branch.setIsVault(false);
        return branch;
    }

    private static Currency currency(String code) {
        Currency currency = new Currency();
        currency.setCode(code);
        return currency;
    }

    private static TransactionLine line(Currency currency, BigDecimal amount, BigDecimal huf) {
        TransactionLine line = new TransactionLine();
        line.setCurrency(currency);
        line.setBanknoteCount(amount);
        line.setHufValue(huf);
        return line;
    }
}
