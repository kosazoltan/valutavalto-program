package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.config.IntegrationTransportProperties;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.dto.sync.SyncLogDto;
import hu.puzzleir.valuta.dto.sync.SyncStatusDto;
import hu.puzzleir.valuta.entity.SyncLog;
import hu.puzzleir.valuta.repository.DailySessionRepository;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.repository.SyncLogRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;

import java.nio.file.Path;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.IntStream;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * SyncService UNIT tesztek — Mockito.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class SyncServiceTest {

    @InjectMocks
    private SyncService service;

    @Mock
    private SyncLogRepository syncLogRepository;

    @Mock
    private BranchRepository branchRepository;

    @Mock
    private ExchangeRateRepository exchangeRateRepository;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private CashBalanceRepository cashBalanceRepository;

    @Mock
    private DailySessionRepository dailySessionRepository;

    @Mock
    private IntegrationTransportProperties integrationTransportProperties;

    @Mock
    private IntegrationTransportProperties.Sync syncProperties;

    @Mock
    private FileTransportService fileTransportService;

    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final UUID COMPANY_ID = UUID.randomUUID();

    @BeforeEach
    void setUpSecurityAndScope() {
        // IDOR-guard (audit 2026-06-15): a resolveBranch a branchId-t a hívó cégére validálja
        // (existsByIdAndCompanyId), és getCurrentCompanyId()-t hív → auth-kontextus + scope-stub kell.
        WorkerAuthenticationDetails details =
                new WorkerAuthenticationDetails(1L, COMPANY_ID, BRANCH_ID, "ADMIN");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("test", "x", "ROLE_ADMIN");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
        when(branchRepository.existsByIdAndCompanyId(any(), any())).thenReturn(true);
        lenient().when(branchRepository.findByIdAndCompanyId(eq(BRANCH_ID), eq(COMPANY_ID)))
                .thenReturn(Optional.of(createBranch()));
    }

    private Branch createBranch() {
        Branch b = new Branch();
        Company c = new Company();
        c.setId(UUID.randomUUID());
        b.setId(BRANCH_ID);
        b.setCode("B01");
        b.setName("Teszt Iroda");
        b.setCompany(c);
        return b;
    }

    private List<ExchangeRate> createRates(int count) {
        return IntStream.range(0, count)
                .mapToObj(i -> {
                    Currency currency = new Currency();
                    currency.setId((long) (i + 1));

                    ExchangeRate rate = new ExchangeRate();
                    rate.setCurrency(currency);
                    return rate;
                })
                .toList();
    }

    @Test
    @DisplayName("syncRatesDown → COMPLETED status")
    void testSyncRatesDown() throws Exception {
        Branch branch = createBranch();
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(exchangeRateRepository.findAllActiveRates(any(UUID.class), eq(BRANCH_ID))).thenReturn(createRates(15));
        when(transactionRepository.findActiveByBranchAndDate(eq(BRANCH_ID), any())).thenReturn(Collections.emptyList());
        when(cashBalanceRepository.findByBranchId(BRANCH_ID)).thenReturn(Collections.emptyList());
        when(dailySessionRepository.findOpenSessionsByBranch(org.mockito.ArgumentMatchers.eq(COMPANY_ID), org.mockito.ArgumentMatchers.eq(BRANCH_ID))).thenReturn(Collections.emptyList());
        when(syncLogRepository.save(any(SyncLog.class))).thenAnswer(inv -> {
            SyncLog s = inv.getArgument(0);
            if (s.getId() == null) s.setId(UUID.randomUUID());
            return s;
        });
        when(integrationTransportProperties.getSync()).thenReturn(syncProperties);
        when(syncProperties.getDir()).thenReturn("branch-sync");
        when(fileTransportService.sanitizePathSegment(anyString(), anyString())).thenAnswer(inv -> inv.getArgument(0));
        when(fileTransportService.writeJson(anyString(), anyString(), any())).thenReturn(Path.of("sync.json"));

        SyncLogDto result = service.syncRatesDown(BRANCH_ID);

        assertThat(result).isNotNull();
        assertThat(result.getStatus()).isEqualTo("COMPLETED");
        assertThat(result.getSyncType()).isEqualTo("RATES");
        assertThat(result.getDirection()).isEqualTo("DOWN");
        assertThat(result.getRecordCount()).isEqualTo(15);
        verify(syncLogRepository, times(2)).save(any(SyncLog.class));
    }

    @Test
    @DisplayName("syncTransactionsUp → COMPLETED status")
    void testSyncTransactionsUp() throws Exception {
        Branch branch = createBranch();
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(exchangeRateRepository.findAllActiveRates(any(UUID.class), eq(BRANCH_ID))).thenReturn(Collections.emptyList());
        when(transactionRepository.findActiveByBranchAndDate(eq(BRANCH_ID), any())).thenReturn(Collections.nCopies(50, new hu.puzzleir.valuta.entity.Transaction()));
        when(cashBalanceRepository.findByBranchId(BRANCH_ID)).thenReturn(Collections.emptyList());
        when(dailySessionRepository.findOpenSessionsByBranch(org.mockito.ArgumentMatchers.eq(COMPANY_ID), org.mockito.ArgumentMatchers.eq(BRANCH_ID))).thenReturn(Collections.emptyList());
        when(syncLogRepository.save(any(SyncLog.class))).thenAnswer(inv -> {
            SyncLog s = inv.getArgument(0);
            if (s.getId() == null) s.setId(UUID.randomUUID());
            return s;
        });
        when(integrationTransportProperties.getSync()).thenReturn(syncProperties);
        when(syncProperties.getDir()).thenReturn("branch-sync");
        when(fileTransportService.sanitizePathSegment(anyString(), anyString())).thenAnswer(inv -> inv.getArgument(0));
        when(fileTransportService.writeJson(anyString(), anyString(), any())).thenReturn(Path.of("sync.json"));

        SyncLogDto result = service.syncTransactionsUp(BRANCH_ID);

        assertThat(result).isNotNull();
        assertThat(result.getStatus()).isEqualTo("COMPLETED");
        assertThat(result.getSyncType()).isEqualTo("TRANSACTIONS");
        assertThat(result.getDirection()).isEqualTo("UP");
        assertThat(result.getRecordCount()).isEqualTo(50);
    }

    @Test
    @DisplayName("syncAll → COMPLETED status, FULL type")
    void testSyncAll() throws Exception {
        Branch branch = createBranch();
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(exchangeRateRepository.findAllActiveRates(any(UUID.class), eq(BRANCH_ID))).thenReturn(createRates(15));
        when(transactionRepository.findActiveByBranchAndDate(eq(BRANCH_ID), any())).thenReturn(Collections.nCopies(50, new hu.puzzleir.valuta.entity.Transaction()));
        when(cashBalanceRepository.findByBranchId(BRANCH_ID)).thenReturn(Collections.nCopies(25, new CashBalance()));
        when(dailySessionRepository.findOpenSessionsByBranch(org.mockito.ArgumentMatchers.eq(COMPANY_ID), org.mockito.ArgumentMatchers.eq(BRANCH_ID))).thenReturn(Collections.emptyList());
        when(syncLogRepository.save(any(SyncLog.class))).thenAnswer(inv -> {
            SyncLog s = inv.getArgument(0);
            if (s.getId() == null) s.setId(UUID.randomUUID());
            return s;
        });
        when(integrationTransportProperties.getSync()).thenReturn(syncProperties);
        when(syncProperties.getDir()).thenReturn("branch-sync");
        when(fileTransportService.sanitizePathSegment(anyString(), anyString())).thenAnswer(inv -> inv.getArgument(0));
        when(fileTransportService.writeJson(anyString(), anyString(), any())).thenReturn(Path.of("sync.json"));

        SyncLogDto result = service.syncAll(BRANCH_ID);

        assertThat(result).isNotNull();
        assertThat(result.getStatus()).isEqualTo("COMPLETED");
        assertThat(result.getSyncType()).isEqualTo("FULL");
        assertThat(result.getRecordCount()).isEqualTo(90);
    }

    @Test
    @DisplayName("getSyncStatus → returns lastSyncTimes map")
    void testGetSyncStatus() {
        SyncLog rateLog = SyncLog.builder()
                .id(UUID.randomUUID())
                .branch(createBranch())
                .syncType(SyncLog.SyncType.RATES)
                .direction(SyncLog.SyncDirection.DOWN)
                .status(SyncLog.SyncStatus.COMPLETED)
                .startedAt(LocalDateTime.now().minusMinutes(10))
                .completedAt(LocalDateTime.now().minusMinutes(5))
                .recordCount(15)
                .build();

        when(syncLogRepository.findLastCompletedByBranch(BRANCH_ID)).thenReturn(List.of(rateLog));

        SyncStatusDto result = service.getSyncStatus(BRANCH_ID);

        assertThat(result).isNotNull();
        assertThat(result.getBranchId()).isEqualTo(BRANCH_ID);
        assertThat(result.getLastSyncTimes()).containsKey("RATES");
    }
}
