package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.transfer.ReceiveTransferDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Transfer;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.TransferRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TransferReceiveAuditTest {

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID TO_BRANCH_ID = UUID.randomUUID();

    @Mock private TransferRepository transferRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private TransactionRepository transactionRepository;
    @Mock private ReceiptSequenceService receiptSequenceService;
    @Mock private TransferSerialSequenceService transferSerialSequenceService;
    @Mock private HufDaybookSequenceService hufDaybookSequenceService;
    @Mock private AuditLogService auditLogService;
    @Mock private VaultStockFlowService vaultStockFlowService;
    @Mock private AccessScopeService accessScopeService;
    // FKH-028 5. kor: uj konstruktor-fuggoseg — mechanikus fixture-bovites (no-op mock),
    // a HufDaybookSequenceService-precedens szerint; assert nem valtozott.
    @Mock private TransferCreateDedupGuard createDedupGuard;

    @InjectMocks private TransferService service;

    @BeforeEach
    void setUpAccessScope() {
        // Mockito collection defaults are empty rather than null; preserve the legacy central-role fixture.
        lenient().when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);
    }

    @Test
    void receive_withCarrierName_auditContainsWorkerAndCarrier() {
        String message = receiveAndCaptureAuditMessage("Réti Pál (G4S)");

        assertThat(message)
                .contains("Átadás fogadva: AT-000042")
                .contains("igazoló dolgozó: Kiss Éva (W007)")
                .contains("szállító (Réti Pál (G4S)) megbízásából");
    }

    @Test
    void receive_withControlCharactersInCarrierName_sanitizesAuditMessage() {
        String carrierName = "Réti\rPál\nG4S\tX" + (char) 0 + "Y" + (char) 0x7F + "Z";

        String message = receiveAndCaptureAuditMessage(carrierName);

        assertThat(message)
                .contains("igazoló dolgozó: Kiss Éva (W007)")
                .contains("szállító (Réti_Pál_G4S_X_Y_Z) megbízásából")
                .doesNotContainPattern("[\\x00-\\x1F\\x7F]");
    }

    @Test
    void receive_withoutCarrierName_auditContainsWorkerNoCarrierClause() {
        String message = receiveAndCaptureAuditMessage(null);

        assertThat(message)
                .contains("igazoló dolgozó: Kiss Éva (W007)")
                .doesNotContain("megbízásából")
                .doesNotContain("null");
    }

    @Test
    void receive_blankCarrierName_treatedAsAbsent() {
        String message = receiveAndCaptureAuditMessage("  ");

        assertThat(message)
                .contains("igazoló dolgozó: Kiss Éva (W007)")
                .doesNotContain("megbízásából")
                .doesNotContain("null");
    }

    private String receiveAndCaptureAuditMessage(String carrierName) {
        Transfer transfer = transfer(carrierName);
        Worker toWorker = Worker.builder()
                .id(7L)
                .code("W007")
                .name("Kiss Éva")
                .branch(null)
                .build();
        when(transferRepository.findById(1L)).thenReturn(Optional.of(transfer));
        when(workerRepository.findByIdAndCompanyId(7L, COMPANY_ID)).thenReturn(Optional.of(toWorker));
        when(transferRepository.save(any(Transfer.class))).thenAnswer(invocation -> invocation.getArgument(0));

        ReceiveTransferDto dto = ReceiveTransferDto.builder()
                .receivedAmount(new BigDecimal("100000"))
                .build();

        try (MockedStatic<SecurityUtils> security = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(null);
            service.receive(1L, dto, 7L);
        }

        ArgumentCaptor<String> messageCaptor = ArgumentCaptor.forClass(String.class);
        verify(auditLogService).log(eq("TRANSFER_RECEIVED"), messageCaptor.capture(), eq(1L));
        return messageCaptor.getValue();
    }

    private Transfer transfer(String carrierName) {
        Company company = Company.builder().id(COMPANY_ID).build();
        Branch fromBranch = Branch.builder()
                .id(UUID.randomUUID())
                .company(company)
                .code("BR001")
                .name("Forrás")
                .build();
        Branch toBranch = Branch.builder()
                .id(TO_BRANCH_ID)
                .company(company)
                .code("BR002")
                .name("Cél")
                .build();
        Currency huf = Currency.builder().id(1L).code("HUF").name("Forint").build();
        Worker fromWorker = Worker.builder().id(1L).code("W001").name("Feladó").build();
        return Transfer.builder()
                .id(1L)
                .transferNumber("AT-000042")
                .companyId(COMPANY_ID)
                .status(Transfer.TransferStatus.PENDING)
                .direction(Transfer.TransferDirection.UF)
                .fromBranch(fromBranch)
                .toBranch(toBranch)
                .fromWorker(fromWorker)
                .currency(huf)
                .transferType(Transfer.TransferType.CURRENCY)
                .transferDate(LocalDate.of(2026, 7, 17))
                .transferTime(LocalTime.NOON)
                .amount(new BigDecimal("100000"))
                .carrierName(carrierName)
                .build();
    }
}
