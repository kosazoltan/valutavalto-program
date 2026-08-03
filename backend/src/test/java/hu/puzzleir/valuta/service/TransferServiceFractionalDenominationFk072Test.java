package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.transfer.CreateTransferDto;
import hu.puzzleir.valuta.dto.transfer.TransferDenominationDto;
import hu.puzzleir.valuta.dto.transfer.TransferDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.TransferRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

/**
 * FK-072_v2 FR-4 (backend, MUST): a Transfer-létrehozás címletezési sorában az 1 alatti
 * névérték elutasítása. A meglévő VV-VALID-002 ellenőrzés ma csak {@code > 0}-t vizsgál,
 * így a 0.5 névérték átmegy és perzisztálódik — az elvárt új viselkedés a {@code >= 1}
 * szigorítás, egyértelmű magyar hibával.
 */
@ExtendWith(MockitoExtension.class)
class TransferServiceFractionalDenominationFk072Test {

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
    @InjectMocks private TransferService service;

    private final UUID fromId = UUID.randomUUID();
    private final UUID toId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        lenient().when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);

        Company company = Company.builder().id(UUID.randomUUID()).build();
        Branch fromBranch = Branch.builder().id(fromId).code("BR020").company(company).build();
        Branch toBranch = Branch.builder().id(toId).code("BR099").company(company).build();
        Worker worker = Worker.builder().id(1L).branch(fromBranch).build();
        Currency eur = Currency.builder().id(4L).code("EUR").name("Euró").build();

        when(workerRepository.findById(1L)).thenReturn(Optional.of(worker));
        when(branchRepository.findById(toId)).thenReturn(Optional.of(toBranch));
        when(branchRepository.existsByIdAndCompanyId(eq(toId), any())).thenReturn(true);
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(eur));
        when(transferSerialSequenceService.next(any(), eq("AT"))).thenReturn(1L);

        // A sikeres mentési út stubjai LENIENT-ként: a tört-esetben a GREEN implementáció
        // már a validációnál dob, így ezek nem futnak — strict módban UnnecessaryStubbing
        // lenne (ld. memory: red-teszt-mockito-strict-stubs-csapda). A RED fázisban viszont
        // a jelenlegi kód végigmegy a teljes success-path-en, ezért kellenek.
        lenient().when(transferRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        lenient().when(receiptSequenceService.generateReceiptNumber(any(), any())).thenReturn("R-001");
        lenient().when(transactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        lenient().when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(
                        eq(fromId), anyLong(), eq(company.getId())))
                .thenAnswer(inv -> Optional.of(
                        CashBalance.builder().currentBalance(new BigDecimal("100000")).build()));
    }

    private CreateTransferDto baseDto() {
        CreateTransferDto dto = new CreateTransferDto();
        dto.setToBranchId(toId.toString());
        dto.setCurrencyId(4L);
        dto.setAmount(new BigDecimal("100"));
        dto.setTransferType("CURRENCY");
        dto.setDirection("F");
        return dto;
    }

    @Test
    @DisplayName("FR-4: 1 alatti névértékű címletsor (200 × 0.5) → ValidationException (VV-VALID-002), nem perzisztálódik")
    void fractionalFaceValue_rejected() {
        CreateTransferDto dto = baseDto();
        // 200 × 0.5 = 100 — az összeg-egyezés (FR-20b) teljesül, tehát kizárólag a
        // névérték >= 1 szabály utasíthatja el.
        dto.setDenominations(List.of(
                TransferDenominationDto.builder()
                        .quantity(200)
                        .faceValue(new BigDecimal("0.5"))
                        .build()));

        assertThatThrownBy(() -> service.create(dto, 1L))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("VV-VALID-002")
                .hasMessageContaining("névleges");
    }

    @Test
    @DisplayName("FR-4/FR-7 regresszió: egész névértékek (EUR 1 és 2 is) változatlanul átmennek")
    void wholeFaceValues_stillAccepted() {
        CreateTransferDto dto = baseDto();
        // 50×1 + 25×2 = 100 — az EUR 1-es és 2-es érme kifejezetten a spec szerint marad.
        dto.setDenominations(List.of(
                TransferDenominationDto.builder().quantity(50).faceValue(new BigDecimal("1")).build(),
                TransferDenominationDto.builder().quantity(25).faceValue(new BigDecimal("2")).build()));

        TransferDto result = service.create(dto, 1L);

        assertThat(result).isNotNull();
        assertThat(result.getTransferNumber()).isEqualTo("AT-000001");
    }
}
