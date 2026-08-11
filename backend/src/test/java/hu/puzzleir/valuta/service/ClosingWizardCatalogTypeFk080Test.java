package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.entity.DenominationAllowed;
import hu.puzzleir.valuta.entity.DenominationType;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.ClosingWizardRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.repository.DailySessionRepository;
import hu.puzzleir.valuta.repository.DenominationAllowedRepository;
import hu.puzzleir.valuta.repository.DenominationBalanceRepository;
import hu.puzzleir.valuta.repository.DenominationRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
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

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FK-080 FR-3 + ITEM 1 (20260811-fk080-engedelyezett-ermek round-2 ruling):
 * a záró-varázsló auto-create ága a MENTETT {@code Denomination.denominationType}-ot
 * a katalógus-sorból veszi ({@code allowed.getDenominationType()}), NEM a törölt
 * {@code faceValue >= 200 -> BANKNOTE, egyébként COIN} névérték-küszöb számítja.
 *
 * <p><b>Diszkriminátor-tesztek:</b> a meglévő FR-3b eset (EUR 500 → BANKNOTE,
 * {@code ClosingWizardDenominationAllowedFk076Test:208-225}) NEM diszkriminál —
 * az 500 >= 200 küszöb is BANKNOTE-ot ad. Az itt mért mátrix:
 * <pre>
 *   eset        | katalógus-típus | régi >=200 szabály | diszkriminál?
 *   EUR 500     | BANKNOTE        | BANKNOTE           | nem
 *   HUF 500/100 | BANKNOTE / COIN | azonos             | nem (NFR-6 paraméteres teszt)
 *   HUF 200     | COIN            | BANKNOTE           | IGEN
 *   RSD 10      | BANKNOTE        | COIN               | IGEN
 * </pre>
 * Ezért ez a teszt a MENTETT típust assertálja (a {@code denominationRepository.save}
 * argumentumát kapja el) pontosan arra a két esetre, amely a régi küszöböt megcáfolja.
 * Elfogadási kritérium: a régi küszöb visszaállítása ezt a tesztet elbuktatja, a
 * katalógus-forrású implementáció pedig átviszi — lásd a round-2 RED-bizonyítékot
 * ({@code .hermes/evidence/2026-08-11/E-fk080-red-bizonyitekok-r2.md}, WU-6).
 *
 * <p>Mindkét esetben a denomination-sor még nem létezik (auto-create ág fut), és a
 * katalógus az adott (deviza, névérték) párt AKTÍV sorral engedélyezi — így a mentés
 * megtörténik, és a kérdés kizárólag a mentett SOR TÍPUSA.
 */
@ExtendWith(MockitoExtension.class)
class ClosingWizardCatalogTypeFk080Test {

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
    @InjectMocks private ClosingWizardService service;

    private final UUID branchId = UUID.randomUUID();
    private final UUID companyId = UUID.randomUUID();
    private final LocalDate businessDate = LocalDate.of(2026, 8, 11);

    @BeforeEach
    void setUp() {
        Company company = Company.builder().id(companyId).build();
        Branch branch = Branch.builder().id(branchId).code("BR001").company(company).build();

        Currency huf = Currency.builder().id(1L).code("HUF").name("Magyar forint").build();
        Currency rsd = Currency.builder().id(12L).code("RSD").name("Szerb dinár").build();

        lenient().when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(huf));
        lenient().when(currencyRepository.findByCode("RSD")).thenReturn(Optional.of(rsd));
        lenient().when(branchRepository.findByIdAndCompanyId(branchId, companyId))
                .thenReturn(Optional.of(branch));
        // Auto-create út: a denomination még nem létezik, a balance üres.
        lenient().when(denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(any(), any(), any()))
                .thenReturn(Optional.empty());
        lenient().when(denominationRepository.save(any(Denomination.class)))
                .thenAnswer(inv -> inv.getArgument(0));
        lenient().when(denominationBalanceRepository.findByCashDeskIdAndDenominationIdAndCategory(any(), any(), any()))
                .thenReturn(Optional.empty());
        lenient().when(denominationBalanceRepository.save(any()))
                .thenAnswer(inv -> inv.getArgument(0));
    }

    /** Katalógus-sor építése adott típussal. */
    private static DenominationAllowed catalogRow(BigDecimal faceValue, DenominationType type) {
        return DenominationAllowed.builder()
                .faceValue(faceValue)
                .denominationType(type)
                .active(true)
                .build();
    }

    @Test
    @DisplayName("FK-080 FR-3 diszkriminátor: RSD 10 katalógus-típus BANKNOTE → a MENTETT sor is BANKNOTE (a régi >=200 küszöb COIN-t adna)")
    void rsdTenCatalogBanknoteIsPersistedAsBanknoteNotCoin() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(companyId);
            when(denominationAllowedRepository.findActiveAllowed(companyId, 12L, new BigDecimal("10")))
                    .thenReturn(Optional.of(catalogRow(new BigDecimal("10"), DenominationType.BANKNOTE)));

            service.countDenominations(branchId, businessDate,
                    Map.of("RSD", Map.of(10, 4)));

            ArgumentCaptor<Denomination> saved = ArgumentCaptor.forClass(Denomination.class);
            verify(denominationRepository).save(saved.capture());
            // A régi "faceValue >= 200 -> BANKNOTE, egyebkent COIN" szabaly itt COIN-t
            // adott volna (10 < 200) — pontosan az a defekt (hibas kulfoldi ERME sor),
            // amit az FK-080 javit. A katalógus-forrású implementáció BANKNOTE-ot ment.
            assertThat(saved.getValue().getDenominationType()).isEqualTo(DenominationType.BANKNOTE);
            assertThat(saved.getValue().getFaceValue()).isEqualByComparingTo(new BigDecimal("10"));
            verify(denominationBalanceRepository).save(any());
        }
    }

    @Test
    @DisplayName("FK-080 FR-3 diszkriminátor: HUF 200 katalógus-típus COIN → a MENTETT sor is COIN (a régi >=200 küszöb BANKNOTE-ot adna)")
    void hufTwoHundredCatalogCoinIsPersistedAsCoinNotBanknote() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(companyId);
            when(denominationAllowedRepository.findActiveAllowed(companyId, 1L, new BigDecimal("200")))
                    .thenReturn(Optional.of(catalogRow(new BigDecimal("200"), DenominationType.COIN)));

            service.countDenominations(branchId, businessDate,
                    Map.of("HUF", Map.of(200, 3)));

            ArgumentCaptor<Denomination> saved = ArgumentCaptor.forClass(Denomination.class);
            verify(denominationRepository).save(saved.capture());
            // A regi szabaly 200 >= 200 miatt BANKNOTE-ot adott volna — a HUF 200-as
            // viszont ERME (2008 ota a legnagyobb vert erme). A katalogus-sor tipusa
            // a tenyleges kimenet; a mentett sor COIN.
            assertThat(saved.getValue().getDenominationType()).isEqualTo(DenominationType.COIN);
            assertThat(saved.getValue().getFaceValue()).isEqualByComparingTo(new BigDecimal("200"));
            verify(denominationBalanceRepository).save(any());
        }
    }
}
