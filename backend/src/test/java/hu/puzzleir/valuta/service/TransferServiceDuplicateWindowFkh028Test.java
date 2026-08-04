package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.transfer.CreateTransferDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ConflictException;
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
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

/**
 * FKH-028 Fázis 2: rövid távú (3 mp-es) duplikátum-védelmi ablak a Transfer create-en.
 * Ugyanattól a felhasználótól azonos cél/valuta/összeg/irány/típus paraméterekkel az
 * ablakon belül érkező második beküldés ConflictException — a frontend gomb-letiltás
 * (Fázis 1) backend-oldali hálója direkt/megismételt API-hívások ellen.
 *
 * (A RED-bizonyítékot az eldobható TransferServiceDuplicateWindowFkh028RedProbeTest adta
 * — a 9d8a5884 commitban; a mai kódon mindkét azonos create sikeres volt.)
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class TransferServiceDuplicateWindowFkh028Test {

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
    private TransferService service;

    private final UUID fromId = UUID.randomUUID();
    private final UUID toId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);

        // FKH-028 5. kör: a dedup-viselkedést a VALÓDI TransferCreateDedupGuard adja,
        // állapottartó fake IdempotencyRecordRepository-val (DB helyett memóriában) —
        // így a viselkedés-assertek (duplikátum-elutasítás, kulcs-felszabadulás)
        // változatlanul érvényesek az architektúra-csere után is.
        java.util.concurrent.ConcurrentHashMap<String, hu.puzzleir.valuta.entity.IdempotencyRecord> dedupStore =
                new java.util.concurrent.ConcurrentHashMap<>();
        hu.puzzleir.valuta.repository.IdempotencyRecordRepository fakeDedupRepo =
                org.mockito.Mockito.mock(hu.puzzleir.valuta.repository.IdempotencyRecordRepository.class);
        org.mockito.Mockito.lenient()
                .when(fakeDedupRepo.findByCompanyIdAndEndpointAndIdempotencyKey(any(), any(), any()))
                .thenAnswer(inv -> java.util.Optional.ofNullable(dedupStore.get(inv.getArgument(2, String.class))));
        org.mockito.Mockito.lenient()
                .when(fakeDedupRepo.save(any(hu.puzzleir.valuta.entity.IdempotencyRecord.class)))
                .thenAnswer(inv -> {
                    hu.puzzleir.valuta.entity.IdempotencyRecord rec = inv.getArgument(0);
                    dedupStore.put(rec.getIdempotencyKey(), rec);
                    return rec;
                });
        TransferCreateDedupGuard realGuard = new TransferCreateDedupGuard(fakeDedupRepo);
        service = new TransferService(transferRepository, branchRepository, currencyRepository,
                workerRepository, cashBalanceRepository, transactionRepository,
                receiptSequenceService, transferSerialSequenceService, hufDaybookSequenceService,
                auditLogService, vaultStockFlowService, accessScopeService, realGuard);
        Company company = Company.builder().id(UUID.randomUUID()).build();
        Branch fromBranch = Branch.builder().id(fromId).code("BR076").company(company).build();
        Branch toBranch = Branch.builder().id(toId).code("BR001").company(company).build();
        Worker worker = Worker.builder().id(1L).branch(fromBranch).build();
        Currency eur = Currency.builder().id(4L).code("EUR").name("Euró").build();

        when(workerRepository.findById(1L)).thenReturn(Optional.of(worker));
        when(branchRepository.findById(toId)).thenReturn(Optional.of(toBranch));
        when(branchRepository.existsByIdAndCompanyId(eq(toId), any())).thenReturn(true);
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(eur));
        when(transferSerialSequenceService.next(any(), eq("AT"))).thenReturn(1L, 2L, 3L);
        when(transferRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(receiptSequenceService.generateReceiptNumber(any(), any())).thenReturn("R-001");
        when(transactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(
                        eq(fromId), anyLong(), eq(company.getId())))
                .thenAnswer(inv -> Optional.of(
                        CashBalance.builder().currentBalance(new BigDecimal("100000")).build()));
    }

    private CreateTransferDto dto(String amount) {
        CreateTransferDto dto = new CreateTransferDto();
        dto.setToBranchId(toId.toString());
        dto.setCurrencyId(4L);
        dto.setAmount(new BigDecimal(amount));
        dto.setTransferType("CURRENCY");
        dto.setDirection("F");
        return dto;
    }

    @Test
    @DisplayName("FKH-028: két azonos create() az ablakon belül → a második ConflictException")
    void secondIdenticalCreateWithinWindow_rejected() {
        service.create(dto("1000"), 1L);

        assertThatThrownBy(() -> service.create(dto("1000"), 1L))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("duplikált");
    }

    @Test
    @DisplayName("FKH-028: eltérő összegű második create az ablakon belül → átmegy (nem duplikátum)")
    void differentAmountWithinWindow_accepted() {
        service.create(dto("1000"), 1L);

        assertThatCode(() -> service.create(dto("2000"), 1L)).doesNotThrowAnyException();
    }

    @Test
    @DisplayName("FKH-028/5.kör HIGH-2: a 3 mp-nél LASSABB, még folyamatban lévő create alatt az azonos retry ELUTASÍTVA (nem idő-, hanem állapot-alapú védelem)")
    void slowInFlightCreate_retryStillRejected() throws Exception {
        // Az első create a transferRepository.save-nél mesterségesen beragad (latch),
        // a második azonos kérés 3 mp-nél KÉSŐBB érkezik — az időablak-alapú védelem
        // itt átengedné (a kulcs kiöregedett), az állapot-alapú (PROCESSING) nem.
        java.util.concurrent.CountDownLatch saveEntered = new java.util.concurrent.CountDownLatch(1);
        java.util.concurrent.CountDownLatch releaseSave = new java.util.concurrent.CountDownLatch(1);
        java.util.concurrent.atomic.AtomicBoolean firstSave = new java.util.concurrent.atomic.AtomicBoolean(true);
        when(transferRepository.save(any())).thenAnswer(inv -> {
            if (firstSave.getAndSet(false)) {
                saveEntered.countDown();
                releaseSave.await(20, java.util.concurrent.TimeUnit.SECONDS);
            }
            return inv.getArgument(0);
        });

        java.util.concurrent.ExecutorService executor = java.util.concurrent.Executors.newSingleThreadExecutor();
        try {
            java.util.concurrent.Future<?> first = executor.submit(() -> service.create(dto("1000"), 1L));
            org.assertj.core.api.Assertions.assertThat(
                            saveEntered.await(10, java.util.concurrent.TimeUnit.SECONDS))
                    .as("Az első create-nek el kell érnie a save-et")
                    .isTrue();

            // 3 mp-nél hosszabb feldolgozás szimulálása: a retry az ablakon TÚL érkezik.
            Thread.sleep(3200);

            assertThatThrownBy(() -> service.create(dto("1000"), 1L))
                    .as("A még folyamatban lévő azonos create alatt a retry nem mehet át")
                    .isInstanceOf(ConflictException.class);

            releaseSave.countDown();
            first.get(20, java.util.concurrent.TimeUnit.SECONDS);
        } finally {
            releaseSave.countDown();
            executor.shutdownNow();
        }
    }

    @Test
    @DisplayName("FKH-028/5.kör MEDIUM: a metódustörzs UTÁNI (commit-)bukás is felszabadítja a kulcsot — a következő legitim kérés nem kap hamis konfliktust")
    void commitFailureAfterBody_releasesKey_nextRequestNotBlocked() {
        org.springframework.transaction.support.TransactionSynchronizationManager.initSynchronization();
        try {
            service.create(dto("1000"), 1L);

            // A tranzakció a metódustörzs UTÁN bukik el (commit/flush-hiba szimuláció):
            // a regisztrált szinkronizációk rollback-státusszal záródnak.
            for (org.springframework.transaction.support.TransactionSynchronization sync :
                    java.util.List.copyOf(
                            org.springframework.transaction.support.TransactionSynchronizationManager
                                    .getSynchronizations())) {
                sync.afterCompletion(
                        org.springframework.transaction.support.TransactionSynchronization.STATUS_ROLLED_BACK);
            }
        } finally {
            org.springframework.transaction.support.TransactionSynchronizationManager.clearSynchronization();
        }

        // A bukott (rollbackelt) kísérlet után az AZONNALI, azonos paraméterű legitim
        // újraküldés nem kaphat hamis konfliktust.
        assertThatCode(() -> service.create(dto("1000"), 1L))
                .as("A commit-bukás után a kulcs felszabadul, a retry átmegy")
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("FKH-028/V370-guard: a V370-korrekcióval jelölt átadólapra a storno() 409-cel elutasítva")
    void v370MarkedTransfer_stornoRejected() {
        Company company = Company.builder().id(UUID.randomUUID()).build();
        Branch fromBranch = Branch.builder().id(fromId).code("BR035").company(company).build();
        Branch toBranch = Branch.builder().id(toId).code("BR020").company(company).build();
        Currency usd = Currency.builder().id(11L).code("USD").name("USA dollar").build();
        hu.puzzleir.valuta.entity.Transfer marked = hu.puzzleir.valuta.entity.Transfer.builder()
                .id(9L)
                .transferNumber("AT-000010")
                .companyId(company.getId())
                .fromBranch(fromBranch)
                .toBranch(toBranch)
                .currency(usd)
                .amount(new BigDecimal("1000"))
                .isCancelled(false)
                .notes("[FKH-028 V370] duplikalt tetel — az egyenleg-korrekcio a V370 migracioban rendezve; app-szintu sztorno TILOS ra.")
                .build();
        when(transferRepository.findByIdForUpdate(9L)).thenReturn(Optional.of(marked));

        try (org.mockito.MockedStatic<hu.puzzleir.valuta.security.SecurityUtils> secUtils =
                     org.mockito.Mockito.mockStatic(hu.puzzleir.valuta.security.SecurityUtils.class)) {
            secUtils.when(hu.puzzleir.valuta.security.SecurityUtils::getCurrentCompanyId)
                    .thenReturn(company.getId());

            assertThatThrownBy(() -> service.storno(9L, "duplikatum rendezes"))
                    .isInstanceOf(ConflictException.class)
                    .hasMessageContaining("V370");
        }
    }

    @Test
    @DisplayName("FKH-028: ha az első create validációs hibával bukik, az azonnali retry NEM duplikátum")
    void failedCreateReleasesGuard_retryNotBlocked() {
        // 1 000 000 > 100 000 készlet → a kimenő (F) könyvelés ValidationException-nel bukik.
        assertThatThrownBy(() -> service.create(dto("1000000"), 1L))
                .isInstanceOf(ValidationException.class);

        // A retry ugyanazzal a paraméterrel: ugyanaz a készlet-hiba kell legyen, NEM Conflict —
        // vagyis a bukott kísérlet kulcsa felszabadult.
        assertThatThrownBy(() -> service.create(dto("1000000"), 1L))
                .isInstanceOf(ValidationException.class)
                .isNotInstanceOf(ConflictException.class);
    }
}
