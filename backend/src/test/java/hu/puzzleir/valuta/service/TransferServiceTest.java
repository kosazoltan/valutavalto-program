package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.transfer.CreateTransferDto;
import hu.puzzleir.valuta.dto.transfer.TransferDto;
import hu.puzzleir.valuta.dto.transfer.TransferLineDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TransferServiceTest {

    @Mock private TransferRepository transferRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private TransactionRepository transactionRepository;
    @Mock private ReceiptSequenceService receiptSequenceService;
    @Mock private AuditLogService auditLogService;
    @InjectMocks private TransferService service;

    @Test
    @DisplayName("create — forras es cel iroda azonos → hiba")
    void testCreate_sameBranch_throws() {
        UUID branchId = UUID.randomUUID();
        Branch branch = Branch.builder().id(branchId).code("B1").build();
        Worker worker = Worker.builder().id(1L).branch(branch).build();
        Currency eur = Currency.builder().id(4L).code("EUR").build();

        when(workerRepository.findById(1L)).thenReturn(Optional.of(worker));
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(eur));

        CreateTransferDto dto = new CreateTransferDto();
        dto.setToBranchId(branchId.toString());
        dto.setCurrencyId(4L);
        dto.setAmount(new BigDecimal("1000"));
        dto.setTransferType("STANDARD");

        assertThatThrownBy(() -> service.create(dto, 1L))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("azonos");
    }

    @Test
    @DisplayName("FK-005/B2+B3 — átadólap-sorszám: valuta átadás F<branch>, HUF átadás FF<branch> (gap-mentes)")
    void testCreate_slipNumberPrefix_currencyVsHuf() {
        UUID fromId = UUID.randomUUID();
        UUID toId = UUID.randomUUID();
        Company company = Company.builder().id(UUID.randomUUID()).build();
        Branch fromBranch = Branch.builder().id(fromId).code("BR020").company(company).build();
        Branch toBranch = Branch.builder().id(toId).code("BR099").company(company).build();
        Worker worker = Worker.builder().id(1L).branch(fromBranch).build();
        Currency eur = Currency.builder().id(4L).code("EUR").name("Euró").build();
        Currency huf = Currency.builder().id(6L).code("HUF").name("Forint").build();

        when(workerRepository.findById(1L)).thenReturn(Optional.of(worker));
        when(branchRepository.findById(toId)).thenReturn(Optional.of(toBranch));
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(eur));
        when(currencyRepository.findById(6L)).thenReturn(Optional.of(huf));
        when(transferRepository.findMaxSlipSequence(anyString(), anyInt())).thenReturn(0L);
        when(transferRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(receiptSequenceService.generateReceiptNumber(any(), any())).thenReturn("R-001");
        when(transactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(eq(fromId), anyLong()))
                .thenAnswer(inv -> Optional.of(CashBalance.builder().currentBalance(new BigDecimal("1000000")).build()));

        // (1) valuta átadás (F, EUR) → F020000001
        CreateTransferDto valuta = new CreateTransferDto();
        valuta.setToBranchId(toId.toString());
        valuta.setCurrencyId(4L);
        valuta.setAmount(new BigDecimal("100"));
        valuta.setTransferType("CURRENCY");
        valuta.setDirection("F");
        service.create(valuta, 1L);

        // (2) HUF átadás (F, HUF) → FF020000001
        CreateTransferDto forint = new CreateTransferDto();
        forint.setToBranchId(toId.toString());
        forint.setCurrencyId(6L);
        forint.setAmount(new BigDecimal("5000"));
        forint.setTransferType("CASH");
        forint.setDirection("F");
        service.create(forint, 1L);

        ArgumentCaptor<hu.puzzleir.valuta.entity.Transfer> captor =
                ArgumentCaptor.forClass(hu.puzzleir.valuta.entity.Transfer.class);
        verify(transferRepository, times(2)).save(captor.capture());
        java.util.List<String> numbers = captor.getAllValues().stream()
                .map(hu.puzzleir.valuta.entity.Transfer::getTransferNumber).toList();

        org.assertj.core.api.Assertions.assertThat(numbers).containsExactly("F020000001", "FF020000001");
    }

    @Test
    @DisplayName("create — több-valutás (multi-line) F átadás: minden valuta-sor csökkenti a feladó kasszáját (#6)")
    void testCreate_multiLine_decreasesCashPerLine() {
        UUID fromId = UUID.randomUUID();
        UUID toId = UUID.randomUUID();
        Company company = Company.builder().id(UUID.randomUUID()).build();
        Branch fromBranch = Branch.builder().id(fromId).code("B1").company(company).build();
        Branch toBranch = Branch.builder().id(toId).code("B2").company(company).build();
        Worker worker = Worker.builder().id(1L).branch(fromBranch).build();
        Currency eur = Currency.builder().id(4L).code("EUR").name("Euró").build();
        Currency usd = Currency.builder().id(5L).code("USD").name("Dollár").build();

        when(workerRepository.findById(1L)).thenReturn(Optional.of(worker));
        when(branchRepository.findById(toId)).thenReturn(Optional.of(toBranch));
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(eur));
        when(currencyRepository.findById(5L)).thenReturn(Optional.of(usd));
        // FK-005/B2+B3: a sorszám-generátor a findMaxSlipSequence-t hívja (gap-mentes F/U/FF/UF).
        when(transferRepository.findMaxSlipSequence(anyString(), org.mockito.ArgumentMatchers.anyInt())).thenReturn(0L);
        when(transferRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(receiptSequenceService.generateReceiptNumber(any(), any())).thenReturn("R-001");
        when(transactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(eq(fromId), anyLong()))
                .thenAnswer(inv -> Optional.of(CashBalance.builder().currentBalance(new BigDecimal("1000000")).build()));

        CreateTransferDto dto = new CreateTransferDto();
        dto.setToBranchId(toId.toString());
        dto.setCurrencyId(4L);
        dto.setAmount(new BigDecimal("100")); // header = első sor
        dto.setTransferType("CURRENCY");
        dto.setDirection("F");
        dto.setLines(List.of(
                TransferLineDto.builder().currencyId(4L).amount(new BigDecimal("100")).build(),
                TransferLineDto.builder().currencyId(5L).amount(new BigDecimal("200")).build()
        ));

        TransferDto result = service.create(dto, 1L);

        assertThat(result.getLines()).hasSize(2);
        // Per-line összegek és valuta-kódok helyesen visszaadva
        assertThat(result.getLines()).extracting(l -> l.getCurrencyCode()).containsExactlyInAnyOrder("EUR", "USD");
        assertThat(result.getLines()).extracting(l -> l.getAmount())
                .containsExactlyInAnyOrder(new BigDecimal("100"), new BigDecimal("200"));
        // F mód: minden valuta-sor csökkenti a feladó kasszáját → per-currency lock-lekérés
        verify(cashBalanceRepository).findByBranchIdAndCurrencyIdForUpdate(fromId, 4L);
        verify(cashBalanceRepository).findByBranchIdAndCurrencyIdForUpdate(fromId, 5L);
        // EUR-ra NEM a fogadó (toId) kasszáját mozgatjuk create-kor F módban
        verify(cashBalanceRepository, never()).findByBranchIdAndCurrencyIdForUpdate(toId, 4L);
    }

    @Test
    @DisplayName("create — multi-line duplikált valuta → ValidationException (korai védelem, #6)")
    void testCreate_multiLine_duplicateCurrency_throws() {
        UUID fromId = UUID.randomUUID();
        UUID toId = UUID.randomUUID();
        Branch fromBranch = Branch.builder().id(fromId).code("B1").build();
        Branch toBranch = Branch.builder().id(toId).code("B2").build();
        Worker worker = Worker.builder().id(1L).branch(fromBranch).build();
        Currency eur = Currency.builder().id(4L).code("EUR").build();

        when(workerRepository.findById(1L)).thenReturn(Optional.of(worker));
        when(branchRepository.findById(toId)).thenReturn(Optional.of(toBranch));
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(eur));

        CreateTransferDto dto = new CreateTransferDto();
        dto.setToBranchId(toId.toString());
        dto.setCurrencyId(4L);
        dto.setAmount(new BigDecimal("100"));
        dto.setTransferType("CURRENCY");
        dto.setDirection("F");
        dto.setLines(List.of(
                TransferLineDto.builder().currencyId(4L).amount(new BigDecimal("100")).build(),
                TransferLineDto.builder().currencyId(4L).amount(new BigDecimal("50")).build()
        ));

        assertThatThrownBy(() -> service.create(dto, 1L))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("egyszer");
    }

    @Test
    @DisplayName("create — nem letezo dolgozo → hiba")
    void testCreate_workerNotFound() {
        when(workerRepository.findById(999L)).thenReturn(Optional.empty());

        CreateTransferDto dto = new CreateTransferDto();

        assertThatThrownBy(() -> service.create(dto, 999L))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    @DisplayName("create — dolgozo fiok nelkul → hiba")
    void testCreate_noBranch() {
        Worker worker = Worker.builder().id(1L).branch(null).build();
        when(workerRepository.findById(1L)).thenReturn(Optional.of(worker));

        CreateTransferDto dto = new CreateTransferDto();

        assertThatThrownBy(() -> service.create(dto, 1L))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("fiók");
    }

    @Test
    @DisplayName("reject — mar lezart transfer nem utasithato el")
    void testReject_completed_throws() {
        Transfer transfer = Transfer.builder()
                .id(1L)
                .status(Transfer.TransferStatus.COMPLETED)
                .build();

        when(transferRepository.findById(1L)).thenReturn(Optional.of(transfer));

        assertThatThrownBy(() -> service.reject(1L, "teszt ok", 1L))
                .isInstanceOf(ValidationException.class);
    }
}
