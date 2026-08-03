package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.ClosingWizardRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.repository.DailySessionRepository;
import hu.puzzleir.valuta.repository.DenominationBalanceRepository;
import hu.puzzleir.valuta.repository.DenominationRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

/**
 * FK-072 biztonsági fix-kör (Codex HIGH): a záró-varázsló countDenominations guardja a
 * {@code count != 0} feltétel miatt átengedte a 0 darabszámú, de érvénytelen (0 vagy
 * negatív) névértékű kulcsot — a Denomination auto-create így érvénytelen faceValue-val
 * futott le (törzs-szennyezés direkt API-hívásból). Az elvárt viselkedés: MINDEN 1 alatti
 * kulcs elutasítása (darabszámtól függetlenül), mielőtt bármilyen auto-create történne.
 */
@ExtendWith(MockitoExtension.class)
class ClosingWizardZeroFaceValueAutoCreateFk072Test {

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
    @InjectMocks private ClosingWizardService service;

    private final UUID branchId = UUID.randomUUID();
    private final LocalDate businessDate = LocalDate.of(2026, 8, 3);

    @BeforeEach
    void setUp() {
        Currency eur = Currency.builder().id(4L).code("EUR").name("Euró").build();
        // Lenient stubok: a GREEN implementáció már a guardnál dob, így az auto-create út
        // stubjai nem futnak — a RED fázisban viszont a mai kód végigmegy rajtuk (ezek
        // bizonyítják, hogy auto-create történne érvénytelen faceValue-val).
        lenient().when(currencyRepository.findByCode("EUR")).thenReturn(Optional.of(eur));
        lenient().when(denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(any(), any(), any()))
                .thenReturn(Optional.empty());
        Company company = Company.builder().id(UUID.randomUUID()).build();
        lenient().when(branchRepository.findById(branchId))
                .thenReturn(Optional.of(Branch.builder().id(branchId).code("BR001").company(company).build()));
        lenient().when(denominationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        lenient().when(denominationBalanceRepository.findByCashDeskIdAndDenominationId(any(), any()))
                .thenReturn(Optional.empty());
        lenient().when(denominationBalanceRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
    }

    @Test
    @DisplayName("HIGH: 0 névértékű kulcs 0 darabszámmal → VV-VALID-004, NINCS Denomination auto-create")
    void zeroFaceValueKey_rejectedWithoutAutoCreate() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            assertThatThrownBy(() ->
                    service.countDenominations(branchId, businessDate, Map.of("EUR", Map.of(0, 0))))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("VV-VALID-004");

            verify(denominationRepository, never()).save(any());
            verify(denominationBalanceRepository, never()).save(any());
        }
    }

    @Test
    @DisplayName("HIGH: negatív névértékű kulcs 0 darabszámmal → VV-VALID-004, NINCS auto-create")
    void negativeFaceValueKey_rejectedWithoutAutoCreate() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            assertThatThrownBy(() ->
                    service.countDenominations(branchId, businessDate, Map.of("EUR", Map.of(-5, 0))))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("VV-VALID-004");

            verify(denominationRepository, never()).save(any());
            verify(denominationBalanceRepository, never()).save(any());
        }
    }

    @Test
    @DisplayName("MEDIUM: negatív darabszám érvényes kulcson → VV-VALID-005 (a törttől ELTÉRŐ üzenet), nincs balance-írás")
    void negativeCount_rejectedWithDistinctMessage() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            assertThatThrownBy(() ->
                    service.countDenominations(branchId, businessDate, Map.of("EUR", Map.of(20000, -5))))
                    .isInstanceOf(ValidationException.class)
                    // Külön kód + "negatív" szó — a hívó megkülönböztetheti a névérték- és
                    // a darabszám-szabálysértést (a VV-VALID-004 névértékről beszél).
                    .hasMessageContaining("VV-VALID-005")
                    .hasMessageContaining("negatív");

            // Codex LOW: az auto-create ág (denominationRepository.save) sem futhat le —
            // ugyanaz a védelmi szint, mint a 0/negatív névérték teszteknél.
            verify(denominationRepository, never()).save(any());
            verify(denominationBalanceRepository, never()).save(any());
        }
    }

    @Test
    @DisplayName("Regresszió: érvényes egész kulcsok (EUR 1, 2) változatlanul mentődnek")
    void wholeFaceValueKeys_stillPersisted() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            service.countDenominations(branchId, businessDate, Map.of("EUR", Map.of(1, 2, 2, 3)));

            verify(denominationBalanceRepository, org.mockito.Mockito.times(2)).save(any());
        }
    }
}
