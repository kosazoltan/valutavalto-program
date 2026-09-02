package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.entity.DenominationBalance;
import hu.puzzleir.valuta.entity.DenominationCategory;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.ClosingWizardRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.repository.DailySessionRepository;
import hu.puzzleir.valuta.repository.DenominationAllowedRepository;
import hu.puzzleir.valuta.repository.DenominationBalanceRepository;
import hu.puzzleir.valuta.repository.DenominationRepository;
import hu.puzzleir.valuta.repository.ShipmentHandlingFeeRepository;
import hu.puzzleir.valuta.repository.ShipmentRequestRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.VatSupplyStockRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import tools.jackson.databind.ObjectMapper;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.atMost;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.verifyNoMoreInteractions;

/**
 * FKH-044: Napzaras step 2 must see the LATEST submitted denomination payload, not the
 * union of today's earlier EVENING rows. After upserting the payload, every same-desk
 * EVENING row with submissionDate = businessDate whose denomination is absent from the
 * payload must be zeroed (quantity=0, totalValue=0) in the same transaction, with one
 * audit_log KAT=TX entry when something was zeroed.
 *
 * <p>Mock style mirrors {@code ClosingWizardZeroFaceValueAutoCreateFk072Test} (no Docker).
 * RED on base for T1, T2, T7, T8 (no snapshot-replace yet); T3-T6, T9 green everywhere.
 */
@ExtendWith(MockitoExtension.class)
class ClosingWizardEveningSnapshotFkh044Test {

    @Mock private ClosingWizardRepository closingWizardRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private DailySessionRepository dailySessionRepository;
    @Mock private TransactionRepository transactionRepository;
    @Mock private DailyClosingService dailyClosingService;
    @Mock private ObjectMapper objectMapper;
    @Mock private DenominationRepository denominationRepository;
    @Mock private DenominationBalanceRepository denominationBalanceRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private CurrencyStockRepository currencyStockRepository;
    @Mock private SystemParameterService systemParameterService;
    @Mock private ClosingToleranceService closingToleranceService;
    @Mock private AuditLogService auditLogService;
    @Mock private DenominationAllowedRepository denominationAllowedRepository;
    @Mock private ShipmentRequestRepository shipmentRequestRepository;
    @Mock private ShipmentHandlingFeeRepository shipmentHandlingFeeRepository;
    @Mock private VatSupplyStockRepository vatSupplyStockRepository;
    @InjectMocks private ClosingWizardService service;

    private final UUID branchId = UUID.randomUUID();
    private final LocalDate businessDate = LocalDate.of(2026, 9, 2);

    private Currency eur;
    private Currency huf;
    private Currency usd;
    private Denomination eur50;
    private Denomination eur100;
    private Denomination huf500;
    private Denomination usd20;

    @BeforeEach
    void setUp() {
        eur = Currency.builder().id(1L).code("EUR").name("Euro").build();
        huf = Currency.builder().id(2L).code("HUF").name("Forint").build();
        usd = Currency.builder().id(3L).code("USD").name("US Dollar").build();
        eur50 = Denomination.builder().id(101L).currency(eur).faceValue(BigDecimal.valueOf(50)).build();
        eur100 = Denomination.builder().id(102L).currency(eur).faceValue(BigDecimal.valueOf(100)).build();
        huf500 = Denomination.builder().id(103L).currency(huf).faceValue(BigDecimal.valueOf(500)).build();
        usd20 = Denomination.builder().id(104L).currency(usd).faceValue(BigDecimal.valueOf(20)).build();

        // Lenient defaults: on the RED base several of these paths never run, and strict
        // stubbing would flag them. Specific per-test stubs override where needed.
        lenient().when(currencyRepository.findByCode("EUR")).thenReturn(Optional.of(eur));
        lenient().when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(huf));
        lenient().when(currencyRepository.findByCode("USD")).thenReturn(Optional.of(usd));
        // All denominations already exist in master data -> no auto-create path runs.
        lenient().when(denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(branchId, 1L, BigDecimal.valueOf(50)))
                .thenReturn(Optional.of(eur50));
        lenient().when(denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(branchId, 1L, BigDecimal.valueOf(100)))
                .thenReturn(Optional.of(eur100));
        lenient().when(denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(branchId, 2L, BigDecimal.valueOf(500)))
                .thenReturn(Optional.of(huf500));
        lenient().when(denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(branchId, 3L, BigDecimal.valueOf(20)))
                .thenReturn(Optional.of(usd20));
        // Default: no existing EVENING balance row for the upsert lookup -> INSERT path.
        lenient().when(denominationBalanceRepository.findByCashDeskIdAndDenominationIdAndCategory(any(), any(), any()))
                .thenReturn(Optional.empty());
        lenient().when(denominationBalanceRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        // Default: the snapshot finder sees no rows for (branchId, businessDate, EVENING).
        lenient().when(denominationBalanceRepository.findAllByBranchIdAndDateAndCategoryIncludingZero(any(), any(), any()))
                .thenReturn(List.of());
    }

    private DenominationBalance eveningRow(Denomination denomination, int quantity) {
        return DenominationBalance.builder()
                .cashDeskId(branchId)
                .denomination(denomination)
                .quantity(quantity)
                .totalValue(denomination.getFaceValue().multiply(BigDecimal.valueOf(quantity)))
                .denominationCategory(DenominationCategory.EVENING)
                .submissionDate(businessDate)
                .build();
    }

    private List<DenominationBalance> capturedSaves() {
        ArgumentCaptor<DenominationBalance> captor = ArgumentCaptor.forClass(DenominationBalance.class);
        verify(denominationBalanceRepository, atLeastOnce()).save(captor.capture());
        return captor.getAllValues();
    }

    /**
     * When the snapshot finder runs (WU3+), it must be scoped to the exact business date
     * and the EVENING category. On the RED base the finder is never called, so the
     * assertions are vacuous there — the unconditional safety guarantees live in the
     * individual tests (no foreign row is ever saved).
     */
    private void verifyFinderScopedIfCalled() {
        ArgumentCaptor<LocalDate> dateCaptor = ArgumentCaptor.forClass(LocalDate.class);
        ArgumentCaptor<DenominationCategory> categoryCaptor =
                ArgumentCaptor.forClass(DenominationCategory.class);
        verify(denominationBalanceRepository, atMost(1))
                .findAllByBranchIdAndDateAndCategoryIncludingZero(
                        eq(branchId), dateCaptor.capture(), categoryCaptor.capture());
        assertThat(dateCaptor.getAllValues()).allMatch(d -> businessDate.equals(d));
        assertThat(categoryCaptor.getAllValues())
                .allMatch(c -> c == DenominationCategory.EVENING);
    }

    @Test
    @DisplayName("T1: leftover EUR 50 (qty 10) is zeroed when the payload only contains EUR 100")
    void t1_omittedLeftoverRowIsZeroed() {
        DenominationBalance eur50Row = eveningRow(eur50, 10);
        lenient().when(denominationBalanceRepository
                        .findAllByBranchIdAndDateAndCategoryIncludingZero(branchId, businessDate,
                                DenominationCategory.EVENING))
                .thenReturn(List.of(eur50Row));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            service.countDenominations(branchId, businessDate, Map.of("EUR", Map.of(100, 5)));
        }

        List<DenominationBalance> saved = capturedSaves();
        // The omitted EUR 50 row must be persisted zeroed (NOT deleted — the V378
        // unique-key row must survive so the next upsert finds it).
        assertThat(saved).anySatisfy(b -> {
            assertThat(b.getDenomination().getId()).isEqualTo(101L);
            assertThat(b.getQuantity()).isZero();
            assertThat(b.getTotalValue()).isEqualByComparingTo(BigDecimal.ZERO);
        });
        // The submitted EUR 100 row: qty 5 / total 500.
        assertThat(saved).anySatisfy(b -> {
            assertThat(b.getDenomination().getId()).isEqualTo(102L);
            assertThat(b.getQuantity()).isEqualTo(5);
            assertThat(b.getTotalValue()).isEqualByComparingTo(BigDecimal.valueOf(500));
        });
        // Sum of saved EVENING totalValue for EUR = 500 (the leftover contributes 0).
        BigDecimal eurSum = saved.stream()
                .filter(b -> "EUR".equals(b.getDenomination().getCurrency().getCode()))
                .map(DenominationBalance::getTotalValue)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        assertThat(eurSum).isEqualByComparingTo(BigDecimal.valueOf(500));
    }

    @Test
    @DisplayName("T2: exactly one KAT=TX audit entry listing the zeroed EUR 50 row")
    @SuppressWarnings("unchecked")
    void t2_auditEntryForZeroedRows() {
        DenominationBalance eur50Row = eveningRow(eur50, 10);
        lenient().when(denominationBalanceRepository
                        .findAllByBranchIdAndDateAndCategoryIncludingZero(branchId, businessDate,
                                DenominationCategory.EVENING))
                .thenReturn(List.of(eur50Row));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            service.countDenominations(branchId, businessDate, Map.of("EUR", Map.of(100, 5)));
        }

        verify(auditLogService, times(1)).log(
                eq("CLOSING_DENOMINATION_SNAPSHOT_ZEROED"),
                eq("DenominationBalance"),
                eq(branchId.toString()),
                any(), any(),
                eq(branchId.toString()),
                any(), any(), any(), any());
        verifyNoMoreInteractions(auditLogService);

        // The mocked ObjectMapper returns null from writeValueAsString, so assert the
        // captured changes Map argument, not the JSON string.
        ArgumentCaptor<Object> changesCaptor = ArgumentCaptor.forClass(Object.class);
        verify(objectMapper).writeValueAsString(changesCaptor.capture());
        Map<String, Object> changes = (Map<String, Object>) changesCaptor.getValue();
        assertThat(changes.get("KAT")).isEqualTo("TX");
        assertThat(changes.get("business_date")).isEqualTo(businessDate.toString());
        assertThat(changes.get("branch_id")).isEqualTo(branchId.toString());
        List<Map<String, Object>> zeroed = (List<Map<String, Object>>) changes.get("zeroed");
        assertThat(zeroed).hasSize(1);
        assertThat(zeroed.get(0).get("currency_code")).isEqualTo("EUR");
        assertThat(new BigDecimal(String.valueOf(zeroed.get(0).get("face_value"))))
                .isEqualByComparingTo(BigDecimal.valueOf(50));
        assertThat(zeroed.get(0).get("previous_quantity")).isEqualTo(10);
        assertThat(new BigDecimal(String.valueOf(zeroed.get(0).get("previous_total_value"))))
                .isEqualByComparingTo(BigDecimal.valueOf(500));
    }

    @Test
    @DisplayName("T3: category isolation — HANDLING_FEE rows are never touched")
    void t3_handlingFeeRowUntouched() {
        DenominationBalance eveningEur50Row = eveningRow(eur50, 10);
        DenominationBalance handlingFeeRow = DenominationBalance.builder()
                .cashDeskId(branchId)
                .denomination(eur50)
                .quantity(7)
                .totalValue(BigDecimal.valueOf(350))
                .denominationCategory(DenominationCategory.HANDLING_FEE)
                .submissionDate(businessDate)
                .build();
        // The real query filters by category: the EVENING-scoped finder never returns
        // the HANDLING_FEE row even though it shares (cashDeskId, date, denomination).
        lenient().when(denominationBalanceRepository
                        .findAllByBranchIdAndDateAndCategoryIncludingZero(branchId, businessDate,
                                DenominationCategory.EVENING))
                .thenReturn(List.of(eveningEur50Row));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            service.countDenominations(branchId, businessDate, Map.of("EUR", Map.of(100, 5)));
        }

        verifyFinderScopedIfCalled();
        List<DenominationBalance> saved = capturedSaves();
        assertThat(saved).doesNotContain(handlingFeeRow);
        assertThat(saved).noneSatisfy(
                b -> assertThat(b.getDenominationCategory())
                        .isEqualTo(DenominationCategory.HANDLING_FEE));
    }

    @Test
    @DisplayName("T4: yesterday's row is out of scope — finder scoped to businessDate exactly")
    void t4_yesterdayRowNeverTouched() {
        DenominationBalance usd20Row = DenominationBalance.builder()
                .cashDeskId(branchId)
                .denomination(usd20)
                .quantity(3)
                .totalValue(BigDecimal.valueOf(60))
                .denominationCategory(DenominationCategory.EVENING)
                .submissionDate(businessDate.minusDays(1))
                .build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            service.countDenominations(branchId, businessDate, Map.of("EUR", Map.of(50, 1)));
        }

        verifyFinderScopedIfCalled();
        List<DenominationBalance> saved = capturedSaves();
        assertThat(saved).doesNotContain(usd20Row);
    }

    @Test
    @DisplayName("T5: no leftover rows — only the payload upserts, no zeroing, no audit")
    void t5_cleanSlateNoZeroing() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            service.countDenominations(branchId, businessDate, Map.of("EUR", Map.of(50, 2, 100, 3)));
        }

        List<DenominationBalance> saved = capturedSaves();
        assertThat(saved).hasSize(2);
        assertThat(saved).anySatisfy(b -> {
            assertThat(b.getDenomination().getId()).isEqualTo(101L);
            assertThat(b.getQuantity()).isEqualTo(2);
            assertThat(b.getTotalValue()).isEqualByComparingTo(BigDecimal.valueOf(100));
        });
        assertThat(saved).anySatisfy(b -> {
            assertThat(b.getDenomination().getId()).isEqualTo(102L);
            assertThat(b.getQuantity()).isEqualTo(3);
            assertThat(b.getTotalValue()).isEqualByComparingTo(BigDecimal.valueOf(300));
        });
        BigDecimal eurSum = saved.stream()
                .filter(b -> "EUR".equals(b.getDenomination().getCurrency().getCode()))
                .map(DenominationBalance::getTotalValue)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        assertThat(eurSum).isEqualByComparingTo(BigDecimal.valueOf(400));
        verifyNoInteractions(auditLogService);
    }

    @Test
    @DisplayName("T6: resubmit after cancel — the still-submitted EUR 50 row is upserted, not zeroed")
    void t6_resubmittedDenominationNotZeroed() {
        DenominationBalance eur50Row = eveningRow(eur50, 10);
        lenient().when(denominationBalanceRepository
                        .findByCashDeskIdAndDenominationIdAndCategory(branchId, 101L,
                                DenominationCategory.EVENING))
                .thenReturn(Optional.of(eur50Row));
        lenient().when(denominationBalanceRepository
                        .findAllByBranchIdAndDateAndCategoryIncludingZero(branchId, businessDate,
                                DenominationCategory.EVENING))
                .thenReturn(List.of(eur50Row));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            service.countDenominations(branchId, businessDate, Map.of("EUR", Map.of(50, 1)));
        }

        // Upserted in place to qty 1 / total 50.
        assertThat(eur50Row.getQuantity()).isEqualTo(1);
        assertThat(eur50Row.getTotalValue()).isEqualByComparingTo(BigDecimal.valueOf(50));
        // Only the upsert save — no zeroing save for the submitted row.
        verify(denominationBalanceRepository, times(1)).save(any(DenominationBalance.class));
        verifyNoInteractions(auditLogService);
    }

    @Test
    @DisplayName("T7: leftover HUF 500 (qty 4) is zeroed when only EUR is submitted")
    void t7_otherCurrencyLeftoverZeroed() {
        DenominationBalance huf500Row = eveningRow(huf500, 4);
        lenient().when(denominationBalanceRepository
                        .findAllByBranchIdAndDateAndCategoryIncludingZero(branchId, businessDate,
                                DenominationCategory.EVENING))
                .thenReturn(List.of(huf500Row));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            service.countDenominations(branchId, businessDate, Map.of("EUR", Map.of(50, 1)));
        }

        List<DenominationBalance> saved = capturedSaves();
        assertThat(saved).anySatisfy(b -> {
            assertThat(b.getDenomination().getId()).isEqualTo(103L);
            assertThat(b.getQuantity()).isZero();
            assertThat(b.getTotalValue()).isEqualByComparingTo(BigDecimal.ZERO);
        });
        assertThat(saved).anySatisfy(b -> {
            assertThat(b.getDenomination().getId()).isEqualTo(101L);
            assertThat(b.getQuantity()).isEqualTo(1);
        });
    }

    @Test
    @DisplayName("T8: sequential submits — the second payload wins, the first is zeroed")
    void t8_lastPayloadWins() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            service.countDenominations(branchId, businessDate, Map.of("EUR", Map.of(100, 5)));

            ArgumentCaptor<DenominationBalance> captor = ArgumentCaptor.forClass(DenominationBalance.class);
            verify(denominationBalanceRepository, times(1)).save(captor.capture());
            DenominationBalance eur100Row = captor.getAllValues().stream()
                    .filter(b -> b.getDenomination().getId().equals(102L))
                    .findFirst()
                    .orElseThrow();
            assertThat(eur100Row.getQuantity()).isEqualTo(5);

            // The second submit sees the row written by the first one.
            lenient().when(denominationBalanceRepository
                            .findAllByBranchIdAndDateAndCategoryIncludingZero(branchId, businessDate,
                                    DenominationCategory.EVENING))
                    .thenReturn(List.of(eur100Row));

            service.countDenominations(branchId, businessDate, Map.of("EUR", Map.of(50, 1)));

            // Last payload wins: EUR 100 zeroed, EUR 50 = 1 / 50.
            assertThat(eur100Row.getQuantity()).isZero();
            assertThat(eur100Row.getTotalValue()).isEqualByComparingTo(BigDecimal.ZERO);
            ArgumentCaptor<DenominationBalance> secondCaptor = ArgumentCaptor.forClass(DenominationBalance.class);
            verify(denominationBalanceRepository, times(2)).save(secondCaptor.capture());
            assertThat(secondCaptor.getAllValues()).anySatisfy(b -> {
                assertThat(b.getDenomination().getId()).isEqualTo(101L);
                assertThat(b.getQuantity()).isEqualTo(1);
                assertThat(b.getTotalValue()).isEqualByComparingTo(BigDecimal.valueOf(50));
            });
        }
    }

    @Test
    @DisplayName("T9: empty payload is a no-op — no finder call, no save, no audit")
    void t9_emptyPayloadNoOp() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            service.countDenominations(branchId, businessDate,
                    Collections.<String, Map<Integer, Integer>>emptyMap());
        }

        verify(denominationBalanceRepository, never())
                .findAllByBranchIdAndDateAndCategoryIncludingZero(any(), any(), any());
        verify(denominationBalanceRepository, never()).save(any(DenominationBalance.class));
        verifyNoInteractions(auditLogService);
    }
}
