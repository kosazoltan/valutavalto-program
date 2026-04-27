package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CircularSequence;
import hu.puzzleir.valuta.entity.ReceiptSequence;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CircularSequenceRepository;
import hu.puzzleir.valuta.repository.ReceiptSequenceRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * YearOpeningService unit tesztek.
 *
 * Lefedett területek:
 * 1. targetYear validáció (múltbeli, jövőbeli, érvényes)
 * 2. Idempotencia: duplikált futtatás IllegalStateException
 * 3. Tenant-izolálás: csak a saját company branch ID-jai kerülnek reset-re
 * 4. Happy path: 4 lépés sikeresen lefut, audit log mentve
 * 5. getLastExecution: aktuális és jövő évre is visszaad státuszt
 */
@ExtendWith(MockitoExtension.class)
class YearOpeningServiceTest {

    @Mock private CircularSequenceRepository circularSequenceRepository;
    @Mock private ReceiptSequenceRepository receiptSequenceRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private DailyClosingArchiveService dailyClosingArchiveService;
    @Mock private CircularService circularService;
    @Mock private AuditLogService auditLogService;

    @InjectMocks
    private YearOpeningService yearOpeningService;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID_1 = UUID.randomUUID();
    private static final UUID BRANCH_ID_2 = UUID.randomUUID();
    private static final String OPERATOR = "KOSA";

    private MockedStatic<SecurityUtils> securityUtilsMock;
    private int currentYear;

    @BeforeEach
    void setUp() {
        currentYear = LocalDate.now().getYear();
        securityUtilsMock = mockStatic(SecurityUtils.class);
        securityUtilsMock.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
        securityUtilsMock.when(SecurityUtils::getCurrentWorkerCode).thenReturn(OPERATOR);
    }

    @AfterEach
    void tearDown() {
        securityUtilsMock.close();
    }

    // =========================================================================
    // 1. targetYear validáció
    // =========================================================================

    @Test
    @DisplayName("targetYear validáció: 2 évvel régebbi év → IllegalArgumentException")
    void executeYearOpening_pastYear_throws() {
        int pastYear = currentYear - 2;
        assertThatThrownBy(() -> yearOpeningService.executeYearOpening(pastYear))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining(String.valueOf(pastYear));
    }

    @Test
    @DisplayName("targetYear validáció: 2 évvel jövőbeli év → IllegalArgumentException")
    void executeYearOpening_farFutureYear_throws() {
        int farFuture = currentYear + 2;
        assertThatThrownBy(() -> yearOpeningService.executeYearOpening(farFuture))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining(String.valueOf(farFuture));
    }

    @Test
    @DisplayName("targetYear validáció: aktuális év érvényes")
    void executeYearOpening_currentYear_valid() {
        setupHappyPath(currentYear);

        Map<String, Object> result = yearOpeningService.executeYearOpening(currentYear);

        assertThat(result).containsEntry("targetYear", currentYear);
        assertThat(result).containsEntry("status", "SUCCESS");
    }

    @Test
    @DisplayName("targetYear validáció: következő év érvényes")
    void executeYearOpening_nextYear_valid() {
        int nextYear = currentYear + 1;
        setupHappyPath(nextYear);

        Map<String, Object> result = yearOpeningService.executeYearOpening(nextYear);

        assertThat(result).containsEntry("targetYear", nextYear);
        assertThat(result).containsEntry("status", "SUCCESS");
    }

    // =========================================================================
    // 2. Idempotencia
    // =========================================================================

    @Test
    @DisplayName("Idempotencia: már futott az adott évre → IllegalStateException (companyId-scoped kulcs)")
    void executeYearOpening_alreadyExecuted_throws() {
        // F1 fix: az idempotency-key uj formatuma <companyId>:<year>
        when(auditLogService.existsByActionAndReference("YEAR_OPENING", COMPANY_ID + ":" + currentYear))
            .thenReturn(true);

        assertThatThrownBy(() -> yearOpeningService.executeYearOpening(currentYear))
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining(String.valueOf(currentYear));

        // Semmilyen módosítás nem történt
        verify(circularSequenceRepository, never()).findByCompanyId(any());
        verify(receiptSequenceRepository, never()).findByBranchIdIn(any());
    }

    @Test
    @DisplayName("Idempotencia: első futásnál audit log mentődik (companyId-scoped reference)")
    void executeYearOpening_firstRun_auditLogSaved() {
        setupHappyPath(currentYear);

        yearOpeningService.executeYearOpening(currentYear);

        // F1 fix: az audit log reference mezo most <companyId>:<year> formatumu
        verify(auditLogService).log(
            eq("YEAR_OPENING"),
            contains(String.valueOf(currentYear)),
            eq(COMPANY_ID + ":" + currentYear)
        );
    }

    // =========================================================================
    // 3. Tenant-izolálás
    // =========================================================================

    @Test
    @DisplayName("Tenant-izolálás: csak a céghez tartozó branch ID-k kerülnek reset-be")
    void executeYearOpening_tenantIsolation_onlyCompanyBranches() {
        // Setup 2 branch a céghez
        Branch b1 = new Branch(); b1.setId(BRANCH_ID_1);
        Branch b2 = new Branch(); b2.setId(BRANCH_ID_2);
        when(branchRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of(b1, b2));
        when(auditLogService.existsByActionAndReference(anyString(), anyString())).thenReturn(false);
        when(circularSequenceRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of());
        when(receiptSequenceRepository.findByBranchIdIn(List.of(BRANCH_ID_1, BRANCH_ID_2))).thenReturn(List.of());
        when(circularService.archiveByYear(eq(COMPANY_ID), anyInt())).thenReturn(0);
        when(dailyClosingArchiveService.archiveBeforeYear(anyList(), anyInt())).thenReturn(0);

        yearOpeningService.executeYearOpening(currentYear);

        // ReceiptSequence reset csak a céghez tartozó branch ID-kkel hívódik
        verify(receiptSequenceRepository).findByBranchIdIn(List.of(BRANCH_ID_1, BRANCH_ID_2));
        // CircularSequence reset csak a cég companyId-jával
        verify(circularSequenceRepository).findByCompanyId(COMPANY_ID);
        // CircularService archivál csak erre a companyId-ra
        verify(circularService).archiveByYear(eq(COMPANY_ID), eq(currentYear - 1));
        // DailyClosingArchive csak a céghez tartozó branch ID-kkal
        verify(dailyClosingArchiveService).archiveBeforeYear(
            eq(List.of(BRANCH_ID_1, BRANCH_ID_2)), eq(currentYear - 2));
    }

    @Test
    @DisplayName("Tenant-izolálás: üres branch lista esetén receipt és closing reset kihagyva (0 visszaadva)")
    void executeYearOpening_noBranches_receiptAndClosingSkipped() {
        when(branchRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of());
        when(auditLogService.existsByActionAndReference(anyString(), anyString())).thenReturn(false);
        when(circularSequenceRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of());
        when(circularService.archiveByYear(eq(COMPANY_ID), anyInt())).thenReturn(0);

        Map<String, Object> result = yearOpeningService.executeYearOpening(currentYear);

        assertThat(result).containsEntry("receiptSequencesReset", 0);
        assertThat(result).containsEntry("dailyClosingsArchived", 0);

        // findByBranchIdIn NEM hívódik (üres lista → early return)
        verify(receiptSequenceRepository, never()).findByBranchIdIn(any());
        verify(dailyClosingArchiveService, never()).archiveBeforeYear(any(), anyInt());
    }

    // =========================================================================
    // 4. Happy path: 4 lépés + eredmény-térkép
    // =========================================================================

    @Test
    @DisplayName("Happy path: körlevél sorszám nullázás — 2 rekord reset-elve")
    void executeYearOpening_circularSequenceReset() {
        CircularSequence seq1 = new CircularSequence(); seq1.setLastNumber(42);
        CircularSequence seq2 = new CircularSequence(); seq2.setLastNumber(17);
        when(circularSequenceRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of(seq1, seq2));

        setupHappyPath(currentYear);
        // override circular sequences to 2
        when(circularSequenceRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of(seq1, seq2));

        Map<String, Object> result = yearOpeningService.executeYearOpening(currentYear);

        assertThat(result).containsEntry("circularSequencesReset", 2);
        assertThat(seq1.getLastNumber()).isEqualTo(0);
        assertThat(seq2.getLastNumber()).isEqualTo(0);
        verify(circularSequenceRepository).saveAll(List.of(seq1, seq2));
    }

    @Test
    @DisplayName("Happy path: bizonylat sorszám visszaállítás 100000-re — minden mező reset")
    void executeYearOpening_receiptSequenceReset_to100000() {
        Branch b1 = new Branch(); b1.setId(BRANCH_ID_1);
        when(branchRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of(b1));
        when(auditLogService.existsByActionAndReference(anyString(), anyString())).thenReturn(false);
        when(circularSequenceRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of());
        when(circularService.archiveByYear(eq(COMPANY_ID), anyInt())).thenReturn(0);
        when(dailyClosingArchiveService.archiveBeforeYear(anyList(), anyInt())).thenReturn(0);

        ReceiptSequence rs = new ReceiptSequence();
        rs.setLastSellReceipt(999999L);
        rs.setLastBuyReceipt(888888L);
        rs.setLastTransferOutReceipt(777777L);
        rs.setLastTransferInReceipt(666666L);
        rs.setLastForintTransferOutReceipt(555555L);
        rs.setLastForintTransferInReceipt(444444L);
        rs.setLastConversionReceipt(333333L);

        when(receiptSequenceRepository.findByBranchIdIn(List.of(BRANCH_ID_1))).thenReturn(List.of(rs));

        Map<String, Object> result = yearOpeningService.executeYearOpening(currentYear);

        assertThat(result).containsEntry("receiptSequencesReset", 1);
        assertThat(rs.getLastSellReceipt()).isEqualTo(100000L);
        assertThat(rs.getLastBuyReceipt()).isEqualTo(100000L);
        assertThat(rs.getLastTransferOutReceipt()).isEqualTo(100000L);
        assertThat(rs.getLastTransferInReceipt()).isEqualTo(100000L);
        assertThat(rs.getLastForintTransferOutReceipt()).isEqualTo(100000L);
        assertThat(rs.getLastForintTransferInReceipt()).isEqualTo(100000L);
        assertThat(rs.getLastConversionReceipt()).isEqualTo(100000L);
    }

    @Test
    @DisplayName("Happy path: körlevél archiválás — előző év archiválva")
    void executeYearOpening_circularArchive_previousYear() {
        setupHappyPath(currentYear);
        when(circularService.archiveByYear(COMPANY_ID, currentYear - 1)).thenReturn(5);

        Map<String, Object> result = yearOpeningService.executeYearOpening(currentYear);

        assertThat(result).containsEntry("circularsArchived", 5);
        verify(circularService).archiveByYear(COMPANY_ID, currentYear - 1);
    }

    @Test
    @DisplayName("Happy path: napi zárás archiválás — 2 évnél régebbi snapshotok törlése")
    void executeYearOpening_dailyClosingArchive_twoYearsOld() {
        Branch b1 = new Branch(); b1.setId(BRANCH_ID_1);
        when(branchRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of(b1));
        when(auditLogService.existsByActionAndReference(anyString(), anyString())).thenReturn(false);
        when(circularSequenceRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of());
        when(receiptSequenceRepository.findByBranchIdIn(anyList())).thenReturn(List.of());
        when(circularService.archiveByYear(eq(COMPANY_ID), anyInt())).thenReturn(0);
        when(dailyClosingArchiveService.archiveBeforeYear(List.of(BRANCH_ID_1), currentYear - 2)).thenReturn(100);

        Map<String, Object> result = yearOpeningService.executeYearOpening(currentYear);

        assertThat(result).containsEntry("dailyClosingsArchived", 100);
        verify(dailyClosingArchiveService).archiveBeforeYear(List.of(BRANCH_ID_1), currentYear - 2);
    }

    @Test
    @DisplayName("Happy path: eredmény-térkép tartalmaz minden kulcsot")
    void executeYearOpening_resultMapContainsAllKeys() {
        setupHappyPath(currentYear);

        Map<String, Object> result = yearOpeningService.executeYearOpening(currentYear);

        assertThat(result).containsKeys(
            "targetYear", "operator", "startedAt", "completedAt", "status",
            "circularSequencesReset", "receiptSequencesReset",
            "circularsArchived", "dailyClosingsArchived"
        );
        assertThat(result.get("operator")).isEqualTo(OPERATOR);
    }

    // =========================================================================
    // 5. getLastExecution
    // =========================================================================

    @Test
    @DisplayName("getLastExecution: egyik sem futott → canExecute mindkettőre true (companyId-scoped kulcs)")
    void getLastExecution_nothingRan_canExecuteBoth() {
        when(auditLogService.existsByActionAndReference("YEAR_OPENING", COMPANY_ID + ":" + currentYear))
            .thenReturn(false);
        when(auditLogService.existsByActionAndReference("YEAR_OPENING", COMPANY_ID + ":" + (currentYear + 1)))
            .thenReturn(false);

        Map<String, Object> status = yearOpeningService.getLastExecution();

        assertThat(status).containsEntry("executedForCurrentYear", false);
        assertThat(status).containsEntry("executedForNextYear", false);
        assertThat(status).containsEntry("canExecuteForCurrentYear", true);
        assertThat(status).containsEntry("canExecuteForNextYear", true);
    }

    @Test
    @DisplayName("getLastExecution: aktuális évre futott → canExecuteForCurrentYear false (companyId-scoped kulcs)")
    void getLastExecution_currentYearRan_cannotRepeat() {
        when(auditLogService.existsByActionAndReference("YEAR_OPENING", COMPANY_ID + ":" + currentYear))
            .thenReturn(true);
        when(auditLogService.existsByActionAndReference("YEAR_OPENING", COMPANY_ID + ":" + (currentYear + 1)))
            .thenReturn(false);

        Map<String, Object> status = yearOpeningService.getLastExecution();

        assertThat(status).containsEntry("executedForCurrentYear", true);
        assertThat(status).containsEntry("canExecuteForCurrentYear", false);
        assertThat(status).containsEntry("canExecuteForNextYear", true);
    }

    // =========================================================================
    // Helper
    // =========================================================================

    private void setupHappyPath(int targetYear) {
        // F1 fix: az idempotency-key uj formatuma <companyId>:<year>
        when(auditLogService.existsByActionAndReference("YEAR_OPENING", COMPANY_ID + ":" + targetYear))
            .thenReturn(false);
        when(branchRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of());
        when(circularSequenceRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of());
        when(circularService.archiveByYear(eq(COMPANY_ID), anyInt())).thenReturn(0);
        // No receipt sequences for empty branch list → archiveBeforeYear not called
    }
}
