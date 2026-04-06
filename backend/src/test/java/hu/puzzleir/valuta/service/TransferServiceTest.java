package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.transfer.CreateTransferDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
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
