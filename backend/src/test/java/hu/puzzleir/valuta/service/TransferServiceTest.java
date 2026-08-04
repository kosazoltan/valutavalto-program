package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.transfer.CreateTransferDto;
import hu.puzzleir.valuta.dto.transfer.TransferDto;
import hu.puzzleir.valuta.dto.transfer.TransferLineDto;
import hu.puzzleir.valuta.dto.transfer.TransferDenominationDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ConflictException;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
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
    @DisplayName("create — forras es cel iroda azonos → hiba")
    void testCreate_sameBranch_throws() {
        UUID branchId = UUID.randomUUID();
        Branch branch = Branch.builder().id(branchId).code("B1").build();
        Worker worker = Worker.builder().id(1L).branch(branch).build();

        when(workerRepository.findById(1L)).thenReturn(Optional.of(worker));
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));

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
    @DisplayName("Sorszám: deviza átadás AT-NNNNNN, HUF átadás FF-NNNNNN (cégszintű, gap-mentes)")
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
        when(branchRepository.existsByIdAndCompanyId(eq(toId), any())).thenReturn(true);
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(eur));
        when(currencyRepository.findById(6L)).thenReturn(Optional.of(huf));
        when(transferSerialSequenceService.next(any(), eq("AT"))).thenReturn(1L);
        when(transferSerialSequenceService.next(any(), eq("FF"))).thenReturn(1L);
        when(transferRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(receiptSequenceService.generateReceiptNumber(any(), any())).thenReturn("R-001");
        when(transactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(eq(fromId), anyLong(), eq(company.getId())))
                .thenAnswer(inv -> Optional.of(CashBalance.builder().currentBalance(new BigDecimal("1000000")).build()));

        // (1) valuta átadás (F, EUR) → AT-000001
        CreateTransferDto valuta = new CreateTransferDto();
        valuta.setToBranchId(toId.toString());
        valuta.setCurrencyId(4L);
        valuta.setAmount(new BigDecimal("100"));
        valuta.setTransferType("CURRENCY");
        valuta.setDirection("F");
        service.create(valuta, 1L);

        // (2) HUF átadás (F, HUF) → FF-000001
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

        org.assertj.core.api.Assertions.assertThat(numbers).containsExactly("AT-000001", "FF-000001");
    }

    @Test
    @DisplayName("cross-tenant védelem: a cégszűrt ForUpdate-lookup üres → fail-closed, nincs kassza-mentés")
    void testCreate_crossTenantBalanceUnreachable_failsClosed() {
        UUID fromId = UUID.randomUUID();
        UUID toId = UUID.randomUUID();
        Company company = Company.builder().id(UUID.randomUUID()).build();
        Branch fromBranch = Branch.builder().id(fromId).code("BR020").company(company).build();
        Branch toBranch = Branch.builder().id(toId).code("BR099").company(company).build();
        Worker worker = Worker.builder().id(1L).branch(fromBranch).build();
        Currency eur = Currency.builder().id(4L).code("EUR").name("Euró").build();

        when(workerRepository.findById(1L)).thenReturn(Optional.of(worker));
        when(branchRepository.findById(toId)).thenReturn(Optional.of(toBranch));
        when(branchRepository.existsByIdAndCompanyId(eq(toId), eq(company.getId()))).thenReturn(true);
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(eur));
        when(transferSerialSequenceService.next(any(), eq("AT"))).thenReturn(1L);
        when(transferRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        // A (branch, currency) sor MÁS cég alatt él — a tenant-szűrt lock-lookup üres.
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(
                eq(fromId), anyLong(), eq(company.getId()))).thenReturn(Optional.empty());

        CreateTransferDto dto = new CreateTransferDto();
        dto.setToBranchId(toId.toString());
        dto.setCurrencyId(4L);
        dto.setAmount(new BigDecimal("100"));
        dto.setTransferType("CURRENCY");
        dto.setDirection("F");

        assertThatThrownBy(() -> service.create(dto, 1L))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Kassza egyenleg nem található");
        verify(cashBalanceRepository, never()).save(any());
    }

    @Test
    @DisplayName("ERB/FRB/TRB/PRB invariánsok: valuta-szabály sértés → hiba, sorszám NEM fogy")
    void testCreate_technicalRbTypes_currencyInvariants() {
        UUID fromId = UUID.randomUUID();
        UUID toId = UUID.randomUUID();
        Company company = Company.builder().id(UUID.randomUUID()).build();
        Branch fromBranch = Branch.builder().id(fromId).code("BR020").company(company).isVault(true).build();
        Branch toBranch = Branch.builder().id(toId).code("ERB").company(company).build();
        Worker worker = Worker.builder().id(1L).branch(fromBranch).build();
        Currency eur = Currency.builder().id(4L).code("EUR").build();
        Currency huf = Currency.builder().id(6L).code("HUF").build();

        when(workerRepository.findById(1L)).thenReturn(Optional.of(worker));
        when(branchRepository.findById(toId)).thenReturn(Optional.of(toBranch));
        when(branchRepository.existsByIdAndCompanyId(eq(toId), any())).thenReturn(true);
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(eur));
        when(currencyRepository.findById(6L)).thenReturn(Optional.of(huf));

        // (1) FRB (forint mozgás RB) devizával → hiba
        CreateTransferDto frbEur = new CreateTransferDto();
        frbEur.setToBranchId(toId.toString());
        frbEur.setCurrencyId(4L);
        frbEur.setAmount(new BigDecimal("100"));
        frbEur.setTransferType("FRB");
        frbEur.setDirection("F");
        assertThatThrownBy(() -> service.create(frbEur, 1L))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("csak HUF");

        // (2) ERB (fixing valuta mozgás RB) HUF-fal → hiba
        CreateTransferDto erbHuf = new CreateTransferDto();
        erbHuf.setToBranchId(toId.toString());
        erbHuf.setCurrencyId(6L);
        erbHuf.setAmount(new BigDecimal("5000"));
        erbHuf.setTransferType("ERB");
        erbHuf.setDirection("F");
        assertThatThrownBy(() -> service.create(erbHuf, 1L))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("devizával");

        // (3) PRB (POS átvétel banktól) NEM-U irányban → hiba minden átadás-családú iránynál:
        // F (feladó), FF (dupla feladó) ÉS a kihagyott direction default UF-ja is.
        for (String dir : new String[]{"F", "FF", null}) {
            CreateTransferDto prbOut = new CreateTransferDto();
            prbOut.setToBranchId(toId.toString());
            prbOut.setCurrencyId(6L);
            prbOut.setAmount(new BigDecimal("5000"));
            prbOut.setTransferType("PRB");
            prbOut.setDirection(dir);
            assertThatThrownBy(() -> service.create(prbOut, 1L))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("átvétel (U) irányban");
        }

        // (4) Vault-only: NEM értéktári fiókból technikai RB-kötés → hiba (Codex/Copilot P2)
        Branch cashierBranch = Branch.builder().id(UUID.randomUUID()).code("BR105").company(company).isVault(false).build();
        Worker cashier = Worker.builder().id(2L).branch(cashierBranch).build();
        when(workerRepository.findById(2L)).thenReturn(Optional.of(cashier));
        CreateTransferDto cashierFrb = new CreateTransferDto();
        cashierFrb.setToBranchId(toId.toString());
        cashierFrb.setCurrencyId(6L);
        cashierFrb.setAmount(new BigDecimal("5000"));
        cashierFrb.setTransferType("FRB");
        cashierFrb.setDirection("F");
        assertThatThrownBy(() -> service.create(cashierFrb, 2L))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("értéktári fiókból");

        // (5) Multi-line bypass tiltva: ERB (csak deviza) fejléc-EUR mellett HUF-sor → hiba
        CreateTransferDto erbHufLine = new CreateTransferDto();
        erbHufLine.setToBranchId(toId.toString());
        erbHufLine.setCurrencyId(4L);
        erbHufLine.setAmount(new BigDecimal("100"));
        erbHufLine.setTransferType("ERB");
        erbHufLine.setDirection("F");
        TransferLineDto hufLine = new TransferLineDto();
        hufLine.setCurrencyId(6L);
        hufLine.setAmount(new BigDecimal("5000"));
        erbHufLine.setLines(List.of(hufLine));
        assertThatThrownBy(() -> service.create(erbHufLine, 1L))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("devizával");

        // A guard a sorszám-generálás ELŐTT fut → egyik elutasítás sem fogyaszt sorszámot.
        verifyNoInteractions(transferSerialSequenceService);
        verify(transferRepository, never()).save(any());
    }

    @Test
    @DisplayName("ERB deviza átadás + PRB HUF átvétel → sikeres, helyes prefix (AT/UF) és típus")
    void testCreate_technicalRbTypes_happyPath() {
        UUID fromId = UUID.randomUUID();
        UUID toId = UUID.randomUUID();
        Company company = Company.builder().id(UUID.randomUUID()).build();
        Branch fromBranch = Branch.builder().id(fromId).code("BR020").company(company).isVault(true).build();
        Branch toBranch = Branch.builder().id(toId).code("ERB").company(company).build();
        Worker worker = Worker.builder().id(1L).branch(fromBranch).build();
        Currency eur = Currency.builder().id(4L).code("EUR").name("Euró").build();
        Currency huf = Currency.builder().id(6L).code("HUF").name("Forint").build();

        when(workerRepository.findById(1L)).thenReturn(Optional.of(worker));
        when(branchRepository.findById(toId)).thenReturn(Optional.of(toBranch));
        when(branchRepository.existsByIdAndCompanyId(eq(toId), any())).thenReturn(true);
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(eur));
        when(currencyRepository.findById(6L)).thenReturn(Optional.of(huf));
        when(transferSerialSequenceService.next(any(), eq("AT"))).thenReturn(1L);
        when(transferSerialSequenceService.next(any(), eq("UF"))).thenReturn(1L);
        when(transferRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(receiptSequenceService.generateReceiptNumber(any(), any())).thenReturn("R-001");
        when(transactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        lenient().when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(any(), anyLong(), eq(company.getId())))
                .thenAnswer(inv -> Optional.of(CashBalance.builder().currentBalance(new BigDecimal("1000000")).build()));

        // (1) ERB deviza átadás (F, EUR) → AT-000001, típus=ERB
        CreateTransferDto erb = new CreateTransferDto();
        erb.setToBranchId(toId.toString());
        erb.setCurrencyId(4L);
        erb.setAmount(new BigDecimal("100"));
        erb.setTransferType("ERB");
        erb.setDirection("F");
        service.create(erb, 1L);

        // (2) PRB HUF átvétel (U, HUF) → UF-000001, típus=PRB
        CreateTransferDto prb = new CreateTransferDto();
        prb.setToBranchId(toId.toString());
        prb.setCurrencyId(6L);
        prb.setAmount(new BigDecimal("50000"));
        prb.setTransferType("PRB");
        prb.setDirection("U");
        service.create(prb, 1L);

        ArgumentCaptor<hu.puzzleir.valuta.entity.Transfer> captor =
                ArgumentCaptor.forClass(hu.puzzleir.valuta.entity.Transfer.class);
        verify(transferRepository, times(2)).save(captor.capture());
        java.util.List<hu.puzzleir.valuta.entity.Transfer> saved = captor.getAllValues();
        assertThat(saved.get(0).getTransferNumber()).isEqualTo("AT-000001");
        assertThat(saved.get(0).getTransferType()).isEqualTo(hu.puzzleir.valuta.entity.Transfer.TransferType.ERB);
        assertThat(saved.get(1).getTransferNumber()).isEqualTo("UF-000001");
        assertThat(saved.get(1).getTransferType()).isEqualTo(hu.puzzleir.valuta.entity.Transfer.TransferType.PRB);
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
        when(branchRepository.existsByIdAndCompanyId(eq(toId), any())).thenReturn(true);
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(eur));
        when(currencyRepository.findById(5L)).thenReturn(Optional.of(usd));
        when(transferSerialSequenceService.next(any(), anyString())).thenReturn(1L);
        when(transferRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(receiptSequenceService.generateReceiptNumber(any(), any())).thenReturn("R-001");
        when(transactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(eq(fromId), anyLong(), eq(company.getId())))
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
        // F mód: minden valuta-sor csökkenti a feladó kasszáját → per-currency lock-lekérés.
        // 2x: (1) cross-branch + cash-first elo-lock (CashLockOrdering, #952), (2) decreaseCashBalance
        // no-op re-lock + mutacio — ugyanaz a sor, ket SELECT ... FOR UPDATE.
        verify(cashBalanceRepository, times(2)).findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(fromId, 4L, company.getId());
        verify(cashBalanceRepository, times(2)).findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(fromId, 5L, company.getId());
        // EUR-ra NEM a fogadó (toId) kasszáját mozgatjuk create-kor F módban (single-branch → nincs elo-lock sem)
        verify(cashBalanceRepository, never()).findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(eq(toId), eq(4L), any());
    }

    @Test
    @DisplayName("create — multi-line duplikált valuta → ValidationException (korai védelem, #6)")
    void testCreate_multiLine_duplicateCurrency_throws() {
        UUID fromId = UUID.randomUUID();
        UUID toId = UUID.randomUUID();
        Company company = Company.builder().id(UUID.randomUUID()).build();
        Branch fromBranch = Branch.builder().id(fromId).code("B1").company(company).build();
        Branch toBranch = Branch.builder().id(toId).code("B2").company(company).build();
        Worker worker = Worker.builder().id(1L).branch(fromBranch).build();
        Currency eur = Currency.builder().id(4L).code("EUR").build();

        when(workerRepository.findById(1L)).thenReturn(Optional.of(worker));
        when(branchRepository.findById(toId)).thenReturn(Optional.of(toBranch));
        when(branchRepository.existsByIdAndCompanyId(eq(toId), any())).thenReturn(true);
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

    // ===================== HUF árfolyam-fallback (FR-5, FR-6) =====================

    @Test
    @DisplayName("FR-5/FR-6: HUF átadásnál az elszámoló árfolyam 1,0000 → hufValue = összeg (5 Ft-ra kerekítve), nincs árfolyam-hiba")
    void testCreate_huf_fallbackRateIsOne() {
        UUID fromId = UUID.randomUUID();
        UUID toId = UUID.randomUUID();
        Company company = Company.builder().id(UUID.randomUUID()).build();
        Branch fromBranch = Branch.builder().id(fromId).code("BR020").company(company).build();
        Branch toBranch = Branch.builder().id(toId).code("BR099").company(company).build();
        Worker worker = Worker.builder().id(1L).branch(fromBranch).build();
        Currency huf = Currency.builder().id(6L).code("HUF").name("Forint").build();

        when(workerRepository.findById(1L)).thenReturn(Optional.of(worker));
        when(branchRepository.findById(toId)).thenReturn(Optional.of(toBranch));
        when(branchRepository.existsByIdAndCompanyId(eq(toId), any())).thenReturn(true);
        when(currencyRepository.findById(6L)).thenReturn(Optional.of(huf));
        when(transferSerialSequenceService.next(any(), eq("FF"))).thenReturn(1L);
        when(transferRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(receiptSequenceService.generateReceiptNumber(any(), any())).thenReturn("R-001");
        when(transactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(eq(fromId), anyLong(), eq(company.getId())))
                .thenAnswer(inv -> Optional.of(CashBalance.builder().currentBalance(new BigDecimal("100000000")).build()));

        CreateTransferDto dto = new CreateTransferDto();
        dto.setToBranchId(toId.toString());
        dto.setCurrencyId(6L);
        dto.setAmount(new BigDecimal("1000000"));
        dto.setHufValue(null); // a kliens NEM küld árfolyamot HUF-nál
        dto.setTransferType("CASH");
        dto.setDirection("F");

        TransferDto result = service.create(dto, 1L);

        // forintosított érték = összeg (5 Ft-ra kerekítve), nincs ValidationException árfolyam hiányára
        assertThat(result.getHufValue()).isEqualByComparingTo(new BigDecimal("1000000"));
        assertThat(result.getTransferNumber()).isEqualTo("FF-000001");
    }

    // ===================== Opcionális címletezés (FR-17..20b) =====================

    @Test
    @DisplayName("FR-20b: ha a címletezés összege NEM egyezik az átadás összegével → ValidationException (VV-VALID-002)")
    void testCreate_denomination_sumMismatch_throws() {
        UUID fromId = UUID.randomUUID();
        UUID toId = UUID.randomUUID();
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

        CreateTransferDto dto = new CreateTransferDto();
        dto.setToBranchId(toId.toString());
        dto.setCurrencyId(4L);
        dto.setAmount(new BigDecimal("1000"));
        dto.setTransferType("CURRENCY");
        dto.setDirection("F");
        // 5×100 + 3×50 = 650 ≠ 1000
        dto.setDenominations(List.of(
                TransferDenominationDto.builder().quantity(5).faceValue(new BigDecimal("100")).build(),
                TransferDenominationDto.builder().quantity(3).faceValue(new BigDecimal("50")).build()));

        assertThatThrownBy(() -> service.create(dto, 1L))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("VV-VALID-002");
    }

    @Test
    @DisplayName("FR-17/FR-18: egyező összegű címletezés rögzül és visszajön a DTO-ban")
    void testCreate_denomination_success() {
        UUID fromId = UUID.randomUUID();
        UUID toId = UUID.randomUUID();
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
        when(transferRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(receiptSequenceService.generateReceiptNumber(any(), any())).thenReturn("R-001");
        when(transactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(eq(fromId), anyLong(), eq(company.getId())))
                .thenAnswer(inv -> Optional.of(CashBalance.builder().currentBalance(new BigDecimal("100000")).build()));

        CreateTransferDto dto = new CreateTransferDto();
        dto.setToBranchId(toId.toString());
        dto.setCurrencyId(4L);
        dto.setAmount(new BigDecimal("1000"));
        dto.setTransferType("CURRENCY");
        dto.setDirection("F");
        // 5×100 + 10×50 = 1000 ✓
        dto.setDenominations(List.of(
                TransferDenominationDto.builder().quantity(5).faceValue(new BigDecimal("100")).build(),
                TransferDenominationDto.builder().quantity(10).faceValue(new BigDecimal("50")).build()));

        TransferDto result = service.create(dto, 1L);

        assertThat(result.getDenominations()).hasSize(2);
        assertThat(result.getDenominations()).extracting(d -> d.getLineTotal())
                .containsExactlyInAnyOrder(new BigDecimal("500"), new BigDecimal("500"));
    }

    // ===================== Sztornózás (FR-12..16, FR-20) =====================

    private Transfer buildStornoTarget(UUID companyId) {
        return buildStornoTarget(companyId, Transfer.TransferDirection.F);
    }

    private Transfer buildStornoTarget(UUID companyId, Transfer.TransferDirection direction) {
        Company company = Company.builder().id(companyId).build();
        Branch fromBranch = Branch.builder().id(UUID.randomUUID()).code("BR020").company(company).build();
        Branch toBranch = Branch.builder().id(UUID.randomUUID()).code("BR099").company(company).build();
        return Transfer.builder().id(50L).transferNumber("AT-000023")
                .fromBranch(fromBranch).toBranch(toBranch)
                .currency(Currency.builder().id(4L).code("EUR").name("Euró").build())
                .fromWorker(Worker.builder().id(1L).name("Teszt").build())
                .transferType(Transfer.TransferType.CURRENCY)
                .direction(direction)
                .status(Transfer.TransferStatus.COMPLETED)
                .transferDate(java.time.LocalDate.now()).transferTime(java.time.LocalTime.now())
                .amount(new BigDecimal("1000")).isCancelled(false).build();
    }

    @Test
    @DisplayName("FR-12/FR-13: átadás (F) sztornó — fromBranch VISSZAKAPJA, toBranch ELVESZTI a készletet + audit")
    void testStorno_success_reversesStock_handover() {
        UUID companyId = UUID.randomUUID();
        Transfer transfer = buildStornoTarget(companyId, Transfer.TransferDirection.F);
        UUID fromId = transfer.getFromBranch().getId();
        UUID toId = transfer.getToBranch().getId();
        CashBalance fromBal = CashBalance.builder().currentBalance(new BigDecimal("5000")).build();
        CashBalance toBal = CashBalance.builder().currentBalance(new BigDecimal("5000")).build();

        when(transferRepository.findByIdForUpdate(50L)).thenReturn(Optional.of(transfer));
        when(transferRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(workerRepository.findById(1L)).thenReturn(Optional.of(Worker.builder().id(1L).name("Teszt").build()));
        when(receiptSequenceService.generateReceiptNumber(any(), any())).thenReturn("R-SZ-1");
        when(transactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(eq(fromId), anyLong(), eq(companyId))).thenReturn(Optional.of(fromBal));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(eq(toId), anyLong(), eq(companyId))).thenReturn(Optional.of(toBal));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(1L);
            sec.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(null);

            TransferDto result = service.storno(50L, "Téves rögzítés");

            assertThat(result.getIsCancelled()).isTrue();
            assertThat(result.getStornoSerialNumber()).isEqualTo("AT-000023-SZ");
            assertThat(result.getCancellationReason()).isEqualTo("Téves rögzítés");
            verify(auditLogService).log(eq("STORNO"), contains("VV-TX-002"), eq(50L));
            // F (átadás) visszafordítás: a feladó VISSZAKAPJA (5000+1000), a fogadó ELVESZTI (5000-1000).
            assertThat(fromBal.getCurrentBalance()).isEqualByComparingTo("6000");
            assertThat(toBal.getCurrentBalance()).isEqualByComparingTo("4000");
        }
    }

    @Test
    @DisplayName("Sztornó (F): a FOGADÓ kasszáját a ténylegesen FOGADOTT összeggel fordítja vissza (receivedAmount≠amount)")
    void testStorno_handover_usesReceivedAmountForToBranch() {
        UUID companyId = UUID.randomUUID();
        Transfer transfer = buildStornoTarget(companyId, Transfer.TransferDirection.F);
        transfer.setReceivedAmount(new BigDecimal("900")); // fogadáskor 900 érkezett (eredeti 1000)
        UUID fromId = transfer.getFromBranch().getId();
        UUID toId = transfer.getToBranch().getId();
        CashBalance fromBal = CashBalance.builder().currentBalance(new BigDecimal("5000")).build();
        CashBalance toBal = CashBalance.builder().currentBalance(new BigDecimal("5000")).build();

        when(transferRepository.findByIdForUpdate(50L)).thenReturn(Optional.of(transfer));
        when(transferRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(workerRepository.findById(1L)).thenReturn(Optional.of(Worker.builder().id(1L).name("Teszt").build()));
        when(receiptSequenceService.generateReceiptNumber(any(), any())).thenReturn("R-SZ-1");
        when(transactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(eq(fromId), anyLong(), eq(companyId))).thenReturn(Optional.of(fromBal));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(eq(toId), anyLong(), eq(companyId))).thenReturn(Optional.of(toBal));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(1L);
            sec.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(null);

            service.storno(50L, "Téves rögzítés");

            // Feladó VISSZAKAPJA a kiküldött 1000-et (5000+1000); a fogadó a FOGADOTT 900-at veszti (5000-900).
            assertThat(fromBal.getCurrentBalance()).isEqualByComparingTo("6000");
            assertThat(toBal.getCurrentBalance()).isEqualByComparingTo("4100");
        }
    }

    @Test
    @DisplayName("FR-12: átvétel (U) sztornó — fromBranch (fogadó) ELVESZTI a készletet (kikerül)")
    void testStorno_reversesStock_receipt() {
        UUID companyId = UUID.randomUUID();
        Transfer transfer = buildStornoTarget(companyId, Transfer.TransferDirection.U);
        UUID fromId = transfer.getFromBranch().getId();
        CashBalance fromBal = CashBalance.builder().currentBalance(new BigDecimal("5000")).build();

        when(transferRepository.findByIdForUpdate(50L)).thenReturn(Optional.of(transfer));
        when(transferRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(workerRepository.findById(1L)).thenReturn(Optional.of(Worker.builder().id(1L).name("Teszt").build()));
        when(receiptSequenceService.generateReceiptNumber(any(), any())).thenReturn("R-SZ-1");
        when(transactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(eq(fromId), anyLong(), eq(companyId))).thenReturn(Optional.of(fromBal));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(1L);
            sec.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(null);

            service.storno(50L, "Téves átvétel");

            // U (átvétel) visszafordítás: a fogadó (fromBranch) ELVESZTI (5000-1000).
            assertThat(fromBal.getCurrentBalance()).isEqualByComparingTo("4000");
        }
    }

    @Test
    @DisplayName("FR-12/NFR-3: sztornó indoklás service-szinten sem lehet üres vagy csak whitespace")
    void testStorno_blankReason_rejectedBeforeStockMutation() {
        UUID companyId = UUID.randomUUID();
        Transfer transfer = buildStornoTarget(companyId);
        when(transferRepository.findByIdForUpdate(50L)).thenReturn(Optional.of(transfer));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            assertThatThrownBy(() -> service.storno(50L, "   "))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("indoklása kötelező");

            verify(workerRepository, never()).findById(anyLong());
            verify(cashBalanceRepository, never()).findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(any(), anyLong(), any());
            verify(transferRepository, never()).save(any());
        }
    }

    @Test
    @DisplayName("FR-15: sztornó preview már a tényleges sztornó előtt visszaadja a <eredeti>-SZ sorszámot")
    void testGetStornoPreview_setsStornoSerialBeforeCancellation() {
        UUID companyId = UUID.randomUUID();
        Transfer transfer = buildStornoTarget(companyId);
        transfer.setIsCancelled(false);
        when(transferRepository.findById(50L)).thenReturn(Optional.of(transfer));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            sec.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(null);

            TransferDto preview = service.getStornoPreview(50L);

            assertThat(preview.getIsCancelled()).isFalse();
            assertThat(preview.getStornoSerialNumber()).isEqualTo("AT-000023-SZ");
        }
    }

    @Test
    @DisplayName("Fejléc-javítás FR-1/FR-2: vaultAddress 'Város, Cím, IRSZ' + vaultPhone a branch.phone-ból")
    void testToDto_vaultAddressAndPhone_fromBranchMaster() {
        UUID companyId = UUID.randomUUID();
        Transfer transfer = buildStornoTarget(companyId);
        when(transferRepository.findById(50L)).thenReturn(Optional.of(transfer));

        UUID vaultBranchId = UUID.randomUUID();
        Branch vault = Branch.builder().id(vaultBranchId).code("BR105")
                .city("Szeged").address("Hajnóczy u. 57.").zipCode("6722")
                .phone("06703800161").build();
        when(branchRepository.findById(vaultBranchId)).thenReturn(Optional.of(vault));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            sec.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(vaultBranchId);

            TransferDto dto = service.getStornoPreview(50L);

            assertThat(dto.getVaultAddress()).isEqualTo("Szeged, Hajnóczy u. 57., 6722");
            assertThat(dto.getVaultPhone()).isEqualTo("06703800161");
        }
    }

    @Test
    @DisplayName("Fejléc-javítás TBD-3: NULL/üres branch.phone → vaultPhone null (nincs telefon sor)")
    void testToDto_blankBranchPhone_vaultPhoneNull() {
        UUID companyId = UUID.randomUUID();
        Transfer transfer = buildStornoTarget(companyId);
        when(transferRepository.findById(50L)).thenReturn(Optional.of(transfer));

        UUID vaultBranchId = UUID.randomUUID();
        Branch vault = Branch.builder().id(vaultBranchId).code("BR105")
                .city("Szeged").address("Hajnóczy u. 57.").zipCode("6722")
                .phone("   ").build();
        when(branchRepository.findById(vaultBranchId)).thenReturn(Optional.of(vault));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            sec.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(vaultBranchId);

            TransferDto dto = service.getStornoPreview(50L);

            assertThat(dto.getVaultAddress()).isEqualTo("Szeged, Hajnóczy u. 57., 6722");
            assertThat(dto.getVaultPhone()).isNull();
        }
    }

    @Test
    @DisplayName("FR-20: más cég bizonylatának sztornózása → ResourceNotFoundException (404, VV-TENANT-001)")
    void testStorno_crossTenant_404() {
        UUID transferCompany = UUID.randomUUID();
        UUID otherCompany = UUID.randomUUID();
        Transfer transfer = buildStornoTarget(transferCompany);
        when(transferRepository.findByIdForUpdate(50L)).thenReturn(Optional.of(transfer));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(otherCompany);

            assertThatThrownBy(() -> service.storno(50L, "akármi"))
                    .isInstanceOf(ResourceNotFoundException.class);
            verify(transferRepository, never()).save(any());
        }
    }

    // 13.6 szerződés-változás: a PENDING bizonylat mostantól a stornoPending útvonalra kerül
    // (ld. TransferPendingStornoPostgresTest); ez a teszt az IN_TRANSIT esetre szűkült, hogy
    // továbbra is igazolja a stornoCompleted guard státusz-ellenőrzését nem-COMPLETED bizonylatokra.
    @Test
    @DisplayName("Sztornó: nem véglegesített (IN_TRANSIT) bizonylat → ValidationException")
    void testStorno_pending_rejected() {
        UUID companyId = UUID.randomUUID();
        Transfer transfer = buildStornoTarget(companyId);
        transfer.setStatus(Transfer.TransferStatus.IN_TRANSIT);
        when(transferRepository.findByIdForUpdate(50L)).thenReturn(Optional.of(transfer));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            assertThatThrownBy(() -> service.storno(50L, "indok"))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("véglegesített");
            verify(transferRepository, never()).save(any());
        }
    }

    @Test
    @DisplayName("FR: már sztornózott bizonylat újra-sztornózása → ConflictException (409, VV-TX-003)")
    void testStorno_alreadyCancelled_409() {
        UUID companyId = UUID.randomUUID();
        Transfer transfer = buildStornoTarget(companyId);
        transfer.setIsCancelled(true);
        when(transferRepository.findByIdForUpdate(50L)).thenReturn(Optional.of(transfer));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            assertThatThrownBy(() -> service.storno(50L, "ismétlés"))
                    .isInstanceOf(ConflictException.class)
                    .hasMessageContaining("VV-TX-003");
            verify(transferRepository, never()).save(any());
        }
    }

    // A reject() tenant/branch-guardot kapott (security hardening), és a guardok a
    // storno mintája szerint MEGELŐZIK az állapot-vizsgálatot. Ezért a fixture kiegészült
    // cég/fiók adatokkal és SecurityUtils-mockkal, hogy a teszt a guardokon ÁTJUTVA
    // továbbra is a státusz-guardot mérje. Az assert VÁLTOZATLAN.
    @Test
    @DisplayName("reject — mar lezart transfer nem utasithato el")
    void testReject_completed_throws() {
        UUID companyId = UUID.randomUUID();
        Transfer transfer = buildStornoTarget(companyId); // status = COMPLETED
        Worker rejecter = Worker.builder().id(7L).branch(transfer.getToBranch()).build();

        when(transferRepository.findById(50L)).thenReturn(Optional.of(transfer));
        when(workerRepository.findById(7L)).thenReturn(Optional.of(rejecter));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            assertThatThrownBy(() -> service.reject(50L, "teszt ok", 7L))
                    .isInstanceOf(ValidationException.class);
        }
    }

    @Test
    @DisplayName("SEC: idegen CÉG átadásának elutasítása → 404 (a létezés sem szivárog), mellékhatás nélkül")
    void testReject_crossTenant_notFound_noSideEffect() {
        UUID companyId = UUID.randomUUID();
        Transfer transfer = buildStornoTarget(companyId);
        transfer.setStatus(Transfer.TransferStatus.PENDING);
        Worker rejecter = Worker.builder().id(7L).branch(transfer.getToBranch()).build();

        when(transferRepository.findById(50L)).thenReturn(Optional.of(transfer));
        // lenient: a guard ELŐBB dob, mint hogy ide jutna — de a stub nélkül a teszt a
        // "Dolgozó nem található" ResourceNotFoundException-re is zöld lenne, azaz ROSSZ okból.
        // Így a kivétel egyetlen lehetséges forrása a tenant-guard.
        lenient().when(workerRepository.findById(7L)).thenReturn(Optional.of(rejecter));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            // MÁSIK cég van bejelentkezve
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(UUID.randomUUID());

            assertThatThrownBy(() -> service.reject(50L, "idegen cég", 7L))
                    .isInstanceOf(ResourceNotFoundException.class);
        }

        assertThat(transfer.getStatus())
                .as("elutasított kísérlet NEM változtathat státuszt")
                .isEqualTo(Transfer.TransferStatus.PENDING);
        verify(transferRepository, never()).save(any());
    }

    @Test
    @DisplayName("SEC: idegen FIÓK dolgozója (azonos cég) nem utasíthat el — mellékhatás nélkül")
    void testReject_foreignBranchWorker_rejected_noSideEffect() {
        UUID companyId = UUID.randomUUID();
        Transfer transfer = buildStornoTarget(companyId);
        transfer.setStatus(Transfer.TransferStatus.PENDING);
        Company company = Company.builder().id(companyId).build();
        Branch foreignBranch = Branch.builder().id(UUID.randomUUID()).code("BR777").company(company).build();
        Worker foreignWorker = Worker.builder().id(9L).branch(foreignBranch).build();

        when(transferRepository.findById(50L)).thenReturn(Optional.of(transfer));
        when(workerRepository.findById(9L)).thenReturn(Optional.of(foreignWorker));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            assertThatThrownBy(() -> service.reject(50L, "idegen fiók", 9L))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("célfiók");
        }

        assertThat(transfer.getStatus()).isEqualTo(Transfer.TransferStatus.PENDING);
        verify(transferRepository, never()).save(any());
    }

    // 13.6 fixture-bővítés: a reject() mostantól VISSZAPÓTOLJA a create-kori könyvelést, ezért a
    // fixture megkapja a cash/bizonylat stubokat (a storno-success teszt mintája szerint). A teszt
    // EREDETI CÉLJA változatlan — a célfiók dolgozója sikeresen elutasíthat —, a mellette mérhető
    // mellékhatás (kassza-visszapótlás, -SZ bizonylat, TRANSFER_REJECTED audit) bővült.
    @Test
    @DisplayName("SEC-regresszió: a CÉLFIÓK dolgozója továbbra is elutasíthat — és a kassza visszapótlódik")
    void testReject_receivingBranchWorker_succeeds() {
        UUID companyId = UUID.randomUUID();
        Transfer transfer = buildStornoTarget(companyId); // direction = F
        transfer.setStatus(Transfer.TransferStatus.PENDING);
        UUID fromId = transfer.getFromBranch().getId();
        Worker rejecter = Worker.builder().id(7L).branch(transfer.getToBranch()).build();
        CashBalance fromBal = CashBalance.builder().currentBalance(new BigDecimal("5000")).build();

        when(transferRepository.findById(50L)).thenReturn(Optional.of(transfer));
        when(workerRepository.findById(7L)).thenReturn(Optional.of(rejecter));
        when(transferRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(receiptSequenceService.generateReceiptNumber(any(), any())).thenReturn("R-ELUT-1");
        when(transactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(
                eq(fromId), anyLong(), eq(companyId))).thenReturn(Optional.of(fromBal));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            sec.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(null);

            service.reject(50L, "sérült plomba", 7L);
        }

        assertThat(transfer.getStatus()).isEqualTo(Transfer.TransferStatus.REJECTED);
        assertThat(transfer.getNotes()).contains("sérült plomba");
        verify(transferRepository).save(any(Transfer.class));

        // F irány: a create LEVONT a küldőtől, az elutasítás VISSZAADJA (5000 + 1000).
        assertThat(fromBal.getCurrentBalance()).isEqualByComparingTo("6000");
        assertThat(transfer.getIsCancelled()).isTrue();
        assertThat(transfer.getCancellationReason()).isEqualTo("sérült plomba");
        verify(auditLogService).log(eq("TRANSFER_REJECTED"), contains("VV-TX-004"), eq(50L));
    }
}
