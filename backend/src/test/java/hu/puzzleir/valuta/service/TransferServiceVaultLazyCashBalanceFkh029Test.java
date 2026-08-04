package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.transfer.CreateTransferDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.IdempotencyRecordRepository;
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
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicBoolean;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FKH-029 FR-2: vault-branch (is_vault=TRUE) hiányzó {@code cash_balance} sorának
 * lazy get-or-create-je a kassza-mozgás útvonalán.
 *
 * <p><b>Miért:</b> az FKH-028 V369 csak a BR020-at pótolta; az élő audit (2026-08-04)
 * szerint 7 további aktív Értéktárnak 0 {@code cash_balance} sora van, és a BR075-nek
 * 10 PENDING átadása áll 2026-05-26 óta, mert a jóváhagyás
 * {@code increaseCashBalance} → {@code orElseThrow("Kassza egyenleg nem található")}-ba fut.
 * A V371 migráció pótol, de a defense-in-depth réteg (újonnan aktivált valuta, új Értéktár)
 * ezt a runtime-ágat is igényli.</p>
 *
 * <p><b>Fail-closed megőrzése:</b> a lazy create KIZÁRÓLAG {@code is_vault=TRUE} branchre
 * szól — nem-vault branchen a hiányzó sor továbbra is {@link ValidationException}, mert ott
 * a hiányzó kassza valódi adathiba (FKH-029 terv, TBD-4 döntés).</p>
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class TransferServiceVaultLazyCashBalanceFkh029Test {

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

    /** A KÜLDŐ fiók: nem-vault pénztár, bőséges egyenleggel (a create decrease-ágához). */
    private final UUID senderId = UUID.randomUUID();
    /** A FOGADÓ fiók: aktív Értéktár (is_vault=TRUE) — ennek NINCS cash_balance sora. */
    private final UUID vaultId = UUID.randomUUID();
    /** Kontroll: nem-vault fogadó, szintén cash_balance nélkül → fail-closed marad. */
    private final UUID plainId = UUID.randomUUID();

    private final UUID companyId = UUID.randomUUID();
    private Company company;
    private Branch vaultBranch;
    private Branch plainBranch;
    private Currency eur;

    @BeforeEach
    void setUp() {
        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);

        ConcurrentHashMap<String, hu.puzzleir.valuta.entity.IdempotencyRecord> dedupStore =
                new ConcurrentHashMap<>();
        IdempotencyRecordRepository fakeDedupRepo = org.mockito.Mockito.mock(IdempotencyRecordRepository.class);
        lenient().when(fakeDedupRepo.findByCompanyIdAndEndpointAndIdempotencyKey(any(), any(), any()))
                .thenAnswer(inv -> Optional.ofNullable(dedupStore.get(inv.getArgument(2, String.class))));
        lenient().when(fakeDedupRepo.findByCompanyIdAndEndpointAndIdempotencyKeyForUpdate(any(), any(), any()))
                .thenAnswer(inv -> Optional.ofNullable(dedupStore.get(inv.getArgument(2, String.class))));
        lenient().when(fakeDedupRepo.save(any(hu.puzzleir.valuta.entity.IdempotencyRecord.class)))
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

        company = Company.builder().id(companyId).build();
        Branch senderBranch = Branch.builder().id(senderId).code("BR076").company(company)
                .isVault(false).build();
        // BR075 Békéscsaba Értéktár mintázata: aktív, is_vault=TRUE, van vault_territory_id-ja.
        vaultBranch = Branch.builder().id(vaultId).code("BR075").company(company)
                .isVault(true).vaultTerritoryId(2).isActive(true).build();
        plainBranch = Branch.builder().id(plainId).code("BR999").company(company)
                .isVault(false).isActive(true).build();
        Worker worker = Worker.builder().id(1L).branch(senderBranch).build();
        eur = Currency.builder().id(4L).code("EUR").name("Euró").build();

        when(workerRepository.findById(1L)).thenReturn(Optional.of(worker));
        when(branchRepository.findById(vaultId)).thenReturn(Optional.of(vaultBranch));
        when(branchRepository.findById(plainId)).thenReturn(Optional.of(plainBranch));
        when(branchRepository.existsByIdAndCompanyId(any(), any())).thenReturn(true);
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(eur));
        when(transferSerialSequenceService.next(any(), any())).thenReturn(1L, 2L, 3L, 4L);
        when(transferRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(receiptSequenceService.generateReceiptNumber(any(), any())).thenReturn("R-001");
        when(transactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        // A küldő fióknak VAN kasszája, bőséges egyenleggel.
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(
                eq(senderId), anyLong(), eq(companyId)))
                .thenAnswer(inv -> Optional.of(CashBalance.builder()
                        .branch(Branch.builder().id(senderId).code("BR076").isVault(false).build())
                        .currency(eur)
                        .currentBalance(new BigDecimal("100000"))
                        .build()));
    }

    /**
     * UF irány: a create egy lépésben csökkenti a küldő és NÖVELI a fogadó kasszáját
     * ({@code TransferService:884-885}) — ez a BR075-öt blokkoló útvonal.
     */
    private CreateTransferDto ufDto(UUID toBranchId, String amount) {
        CreateTransferDto dto = new CreateTransferDto();
        dto.setToBranchId(toBranchId.toString());
        dto.setCurrencyId(4L);
        dto.setAmount(new BigDecimal(amount));
        dto.setTransferType("CURRENCY");
        dto.setDirection("UF");
        return dto;
    }

    @Test
    @DisplayName("FR-2: vault fogadó hiányzó cash_balance sora lazy létrejön (insertIfAbsent), a könyvelés lefut — nincs ValidationException")
    void vaultBranchMissingCashBalance_lazyCreatedAndBooked() {
        AtomicBoolean vaultRowExists = new AtomicBoolean(false);
        // A vault fiók sora ELŐSZÖR nincs; az insertIfAbsent után a lockolt újraolvasás megtalálja.
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(
                eq(vaultId), anyLong(), eq(companyId)))
                .thenAnswer(inv -> vaultRowExists.get()
                        ? Optional.of(CashBalance.builder()
                                .branch(vaultBranch)
                                .currency(eur)
                                .currentBalance(BigDecimal.ZERO)
                                .openingBalance(BigDecimal.ZERO)
                                .build())
                        : Optional.empty());
        when(cashBalanceRepository.insertIfAbsent(eq(companyId), eq(vaultId), anyLong()))
                .thenAnswer(inv -> {
                    vaultRowExists.set(true);
                    return 1;
                });

        assertThatCode(() -> service.create(ufDto(vaultId, "1000"), 1L))
                .as("A vault fogadó hiányzó kassza-sora nem blokkolhatja az átadást (BR075 hibaosztály)")
                .doesNotThrowAnyException();

        verify(cashBalanceRepository, times(1)).insertIfAbsent(eq(companyId), eq(vaultId), anyLong());
    }

    @Test
    @DisplayName("FR-2 fail-closed: NEM-vault fogadó hiányzó cash_balance sora továbbra is ValidationException — insertIfAbsent NEM hívódik")
    void nonVaultBranchMissingCashBalance_stillFailsClosed() {
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(
                eq(plainId), anyLong(), eq(companyId)))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.create(ufDto(plainId, "1000"), 1L))
                .as("Nem-vault branchen a hiányzó kassza valódi adathiba — a fail-closed viselkedés VÁLTOZATLAN")
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Kassza egyenleg nem található");

        verify(cashBalanceRepository, never()).insertIfAbsent(any(), eq(plainId), anyLong());
    }

    @Test
    @DisplayName("FR-2: a frissen létrehozott 0-s vault soron a csökkentés a negatív-kassza védelembe fut (a lazy create NEM ad fedezetet)")
    void freshZeroVaultRow_decreaseStillBlockedByNegativeGuard() {
        // FF irány: a create MINDKÉT oldalt csökkenti (TransferService:900-901) — a vault
        // oldal frissen létrehozott 0-s sora nem fedezhet 1000 EUR-t.
        AtomicBoolean vaultRowExists = new AtomicBoolean(false);
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(
                eq(vaultId), anyLong(), eq(companyId)))
                .thenAnswer(inv -> vaultRowExists.get()
                        ? Optional.of(CashBalance.builder()
                                .branch(vaultBranch)
                                .currency(eur)
                                .currentBalance(BigDecimal.ZERO)
                                .openingBalance(BigDecimal.ZERO)
                                .build())
                        : Optional.empty());
        when(cashBalanceRepository.insertIfAbsent(eq(companyId), eq(vaultId), anyLong()))
                .thenAnswer(inv -> {
                    vaultRowExists.set(true);
                    return 1;
                });

        CreateTransferDto ff = ufDto(vaultId, "1000");
        ff.setDirection("FF");

        assertThatThrownBy(() -> service.create(ff, 1L))
                .as("A 0-ról induló sor nem ad fedezetet — a negatív-kassza védelem érvényben marad")
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("nem elegendő");
    }
}
