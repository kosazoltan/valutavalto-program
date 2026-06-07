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
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(eur));
        when(currencyRepository.findById(6L)).thenReturn(Optional.of(huf));
        when(transferRepository.findMaxTransferSerialForCompany(any(), anyString(), anyInt())).thenReturn(0L);
        when(transferRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(receiptSequenceService.generateReceiptNumber(any(), any())).thenReturn("R-001");
        when(transactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(eq(fromId), anyLong()))
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
        // A sorszám-generátor a cégszintű findMaxTransferSerialForCompany-t hívja (gap-mentes AT/AV/FF/UF).
        when(transferRepository.findMaxTransferSerialForCompany(any(), anyString(), org.mockito.ArgumentMatchers.anyInt())).thenReturn(0L);
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
        // F mód: minden valuta-sor csökkenti a feladó kasszáját → per-currency lock-lekérés.
        // 2x: (1) cross-branch + cash-first elo-lock (CashLockOrdering, #952), (2) decreaseCashBalance
        // no-op re-lock + mutacio — ugyanaz a sor, ket SELECT ... FOR UPDATE.
        verify(cashBalanceRepository, times(2)).findByBranchIdAndCurrencyIdForUpdate(fromId, 4L);
        verify(cashBalanceRepository, times(2)).findByBranchIdAndCurrencyIdForUpdate(fromId, 5L);
        // EUR-ra NEM a fogadó (toId) kasszáját mozgatjuk create-kor F módban (single-branch → nincs elo-lock sem)
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
        when(currencyRepository.findById(6L)).thenReturn(Optional.of(huf));
        when(transferRepository.findMaxTransferSerialForCompany(any(), anyString(), anyInt())).thenReturn(0L);
        when(transferRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(receiptSequenceService.generateReceiptNumber(any(), any())).thenReturn("R-001");
        when(transactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(eq(fromId), anyLong()))
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
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(eur));
        when(transferRepository.findMaxTransferSerialForCompany(any(), anyString(), anyInt())).thenReturn(0L);

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
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(eur));
        when(transferRepository.findMaxTransferSerialForCompany(any(), anyString(), anyInt())).thenReturn(0L);
        when(transferRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(receiptSequenceService.generateReceiptNumber(any(), any())).thenReturn("R-001");
        when(transactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(eq(fromId), anyLong()))
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
        Company company = Company.builder().id(companyId).build();
        Branch fromBranch = Branch.builder().id(UUID.randomUUID()).code("BR020").company(company).build();
        Branch toBranch = Branch.builder().id(UUID.randomUUID()).code("BR099").company(company).build();
        return Transfer.builder().id(50L).transferNumber("AT-000023")
                .fromBranch(fromBranch).toBranch(toBranch)
                .currency(Currency.builder().id(4L).code("EUR").name("Euró").build())
                .fromWorker(Worker.builder().id(1L).name("Teszt").build())
                .transferType(Transfer.TransferType.CURRENCY)
                .status(Transfer.TransferStatus.COMPLETED)
                .transferDate(java.time.LocalDate.now()).transferTime(java.time.LocalTime.now())
                .amount(new BigDecimal("1000")).isCancelled(false).build();
    }

    @Test
    @DisplayName("FR-12/FR-13: sztornó megjelöli az eredetit + audit (VV-TX-002), a sorszám <eredeti>-SZ")
    void testStorno_success() {
        UUID companyId = UUID.randomUUID();
        Transfer transfer = buildStornoTarget(companyId);
        when(transferRepository.findById(50L)).thenReturn(Optional.of(transfer));
        when(transferRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(1L);
            sec.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(null);

            TransferDto result = service.storno(50L, "Téves rögzítés");

            assertThat(result.getIsCancelled()).isTrue();
            assertThat(result.getCancellationReason()).isEqualTo("Téves rögzítés");
            assertThat(result.getStornoSerialNumber()).isEqualTo("AT-000023-SZ");
            verify(auditLogService).log(eq("STORNO"), contains("VV-TX-002"), eq(50L));
        }
    }

    @Test
    @DisplayName("FR-20: más cég bizonylatának sztornózása → ResourceNotFoundException (404, VV-TENANT-001)")
    void testStorno_crossTenant_404() {
        UUID transferCompany = UUID.randomUUID();
        UUID otherCompany = UUID.randomUUID();
        Transfer transfer = buildStornoTarget(transferCompany);
        when(transferRepository.findById(50L)).thenReturn(Optional.of(transfer));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(otherCompany);

            assertThatThrownBy(() -> service.storno(50L, "akármi"))
                    .isInstanceOf(ResourceNotFoundException.class);
            verify(transferRepository, never()).save(any());
        }
    }

    @Test
    @DisplayName("Sztornó: nem véglegesített (PENDING) bizonylat → ValidationException (a /cancel kezeli)")
    void testStorno_pending_rejected() {
        UUID companyId = UUID.randomUUID();
        Transfer transfer = buildStornoTarget(companyId);
        transfer.setStatus(Transfer.TransferStatus.PENDING);
        when(transferRepository.findById(50L)).thenReturn(Optional.of(transfer));

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
        when(transferRepository.findById(50L)).thenReturn(Optional.of(transfer));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            assertThatThrownBy(() -> service.storno(50L, "ismétlés"))
                    .isInstanceOf(ConflictException.class)
                    .hasMessageContaining("VV-TX-003");
            verify(transferRepository, never()).save(any());
        }
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
