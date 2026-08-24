package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.entity.DenominationAllowed;
import hu.puzzleir.valuta.entity.DenominationType;
import hu.puzzleir.valuta.exception.ValidationException;
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
import hu.puzzleir.valuta.repository.VatSupplyStockRepository;
import hu.puzzleir.valuta.repository.ShipmentRequestRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
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
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FK-076 FR-3 + FK-080 FR-4: a záró-varázsló auto-create ága a denomination_allowed
 * törzsadat ellen validál — nem engedélyezett kombinációra 4xx-elutasítás
 * (VV-VALID-006), NEM csendes új denomination-sor.
 *
 * <p><b>FK-080 által MEGFORDÍTOTT invariáns (szándékos, dokumentált spec-változás):</b>
 * az FK-076 idején a HUF-ra a validáció explicit KI VOLT kapcsolva (a HUF nem szerepelt
 * a katalógusban), és az akkori teszt épp azt bizonyította, hogy a katalógus-lekérdezés
 * HUF-ra SOHA nem fut le. A V379 óta a HUF is a katalógusban van (12 sor), ezért minden
 * pénznem UGYANAZON a gáton megy át — a lekérdezés HUF-ra MOST MÁR LEFUT.
 *
 * <p>Az NFR-6 ("törvényes HUF-zárás soha nem utasítható el") változatlanul érvényes, de
 * mostantól ADAT garantálja: mind a 12 törvényes HUF névérték (5–200 érme, 500–20000
 * bankjegy) benne van a katalógusban. Cserébe a 2008-ban bevont HUF 1/2 forint és a
 * szemét névérték (pl. HUF 3) elutasításra kerül — ez az FK-080 kért viselkedése.
 */
@ExtendWith(MockitoExtension.class)
class ClosingWizardDenominationAllowedFk076Test {

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
    // FKH-036 WU-5: az új konstruktor-függőségek mockjai (pitfall 1).
    @Mock private ShipmentRequestRepository shipmentRequestRepository;
    @Mock private ShipmentHandlingFeeRepository shipmentHandlingFeeRepository;
    @Mock private VatSupplyStockRepository vatSupplyStockRepository;
    @InjectMocks private ClosingWizardService service;

    private final UUID branchId = UUID.randomUUID();
    private final UUID companyId = UUID.randomUUID();
    private final LocalDate businessDate = LocalDate.of(2026, 8, 7);

    /** A HUF törvényes érme-névértékei (V379 katalógus). */
    private static final java.util.Set<Integer> HUF_COIN_VALUES =
            java.util.Set.of(5, 10, 20, 50, 100, 200);

    @BeforeEach
    void setUp() {
        Company company = Company.builder().id(companyId).build();
        Branch branch = Branch.builder().id(branchId).code("BR001").company(company).build();

        Currency huf = Currency.builder().id(1L).code("HUF").name("Magyar forint").build();
        Currency eur = Currency.builder().id(4L).code("EUR").name("Euró").build();
        Currency chf = Currency.builder().id(5L).code("CHF").name("Svájci frank").build();

        lenient().when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(huf));
        lenient().when(currencyRepository.findByCode("EUR")).thenReturn(Optional.of(eur));
        lenient().when(currencyRepository.findByCode("CHF")).thenReturn(Optional.of(chf));
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

    /** Katalógus-sor a HUF törvényes névértékeihez (érme 5–200, bankjegy 500–20000). */
    private static DenominationAllowed hufCatalogRow(int faceValue) {
        return DenominationAllowed.builder()
                .faceValue(BigDecimal.valueOf(faceValue))
                .denominationType(HUF_COIN_VALUES.contains(faceValue)
                        ? DenominationType.COIN : DenominationType.BANKNOTE)
                .active(true)
                .build();
    }

    @ParameterizedTest(name = "HUF {0} menthető — a törvényes címletek soha nem utasíthatók el")
    @ValueSource(ints = {20000, 10000, 5000, 2000, 1000, 500, 200, 100, 50, 20, 10, 5})
    @DisplayName("NFR-6 HUF-védelem (FK-080): mind a 12 TÖRVÉNYES HUF címlet átmegy — a gát MOST MÁR lefut HUF-ra is")
    void everyLawfulHufDenominationIsAcceptedThroughTheSameGateFk080(int faceValue) {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(companyId);
            when(denominationAllowedRepository.findActiveAllowed(
                    companyId, 1L, BigDecimal.valueOf(faceValue)))
                    .thenReturn(Optional.of(hufCatalogRow(faceValue)));

            assertThatCode(() ->
                    service.countDenominations(branchId, businessDate,
                            Map.of("HUF", Map.of(faceValue, 1))))
                    .doesNotThrowAnyException();

            // MEGFORDÍTOTT INVARIÁNS (FK-080 FR-4): az FK-076 idején itt
            // verify(never()).existsAllowed(...) állt, mert a HUF ki volt véve a
            // validáció alól. A V379 óta a HUF is a katalógusban van, ezért a
            // lekérdezésnek MEG KELL történnie — a HUF nem kivétel többé.
            verify(denominationAllowedRepository)
                    .findActiveAllowed(companyId, 1L, BigDecimal.valueOf(faceValue));
        }
    }

    @ParameterizedTest(name = "HUF {0} elutasítva — nincs katalógus-sora")
    @ValueSource(ints = {1, 2, 3})
    @DisplayName("FK-080 FR-4: a bevont HUF 1/2 forint és a szemét névérték (3) VV-VALID-006-tal elutasítva")
    void unlawfulHufDenominationIsRejectedFk080(int faceValue) {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(companyId);
            when(denominationAllowedRepository.findActiveAllowed(
                    companyId, 1L, BigDecimal.valueOf(faceValue)))
                    .thenReturn(Optional.empty());

            assertThatThrownBy(() ->
                    service.countDenominations(branchId, businessDate,
                            Map.of("HUF", Map.of(faceValue, 1))))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("VV-VALID-006")
                    .hasMessageContaining("HUF " + faceValue);

            // Korábban ez CSENDESEN létrehozott egy HUF 1/2 forintos ÉRME sort.
            verify(denominationRepository, never()).save(any());
            verify(denominationBalanceRepository, never()).save(any());
        }
    }

    @Test
    @DisplayName("FR-3a: nem engedélyezett nem-HUF kombináció (CHF 5 érme) → VV-VALID-006, nincs új denomination-sor")
    void nonAllowedForeignDenominationRejected() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(companyId);
            // CHF 5 érme nincs a denomination_allowed-ban (nem-EUR érme sehol).
            when(denominationAllowedRepository.findActiveAllowed(companyId, 5L, new BigDecimal("5")))
                    .thenReturn(Optional.empty());

            assertThatThrownBy(() ->
                    service.countDenominations(branchId, businessDate,
                            Map.of("CHF", Map.of(5, 3))))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("VV-VALID-006")
                    .hasMessageContaining("CHF 5");

            verify(denominationRepository, never()).save(any());
            verify(denominationBalanceRepository, never()).save(any());
            // FR-3 audit: a pénzügyi törzsadat-jellegű elutasítás a REQUIRES_NEW
            // auditcsatornába kerül (KAT=VALID), hogy rollback ellenére is megmaradjon.
            verify(auditLogService).logInNewTransactionForCompany(
                    org.mockito.ArgumentMatchers.eq("DENOMINATION_ALLOWED_REJECTED"),
                    org.mockito.ArgumentMatchers.contains("VV-VALID-006"),
                    org.mockito.ArgumentMatchers.eq(branchId.toString()),
                    org.mockito.ArgumentMatchers.eq(companyId));
        }
    }

    @Test
    @DisplayName("FR-3b: engedélyezett nem-HUF kombináció (EUR 500) változatlanul ment, a típus a katalógusból jön")
    void allowedForeignDenominationStillPersisted() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(companyId);
            when(denominationAllowedRepository.findActiveAllowed(companyId, 4L, new BigDecimal("500")))
                    .thenReturn(Optional.of(DenominationAllowed.builder()
                            .faceValue(new BigDecimal("500"))
                            .denominationType(DenominationType.BANKNOTE)
                            .active(true)
                            .build()));

            service.countDenominations(branchId, businessDate,
                    Map.of("EUR", Map.of(500, 2)));

            // FK-080 FR-3: a mentett sor típusa a katalógus-soré, nem névérték-küszöbé.
            ArgumentCaptor<Denomination> saved = ArgumentCaptor.forClass(Denomination.class);
            verify(denominationRepository).save(saved.capture());
            assertThat(saved.getValue().getDenominationType()).isEqualTo(DenominationType.BANKNOTE);
            verify(denominationBalanceRepository).save(any());
        }
    }

    @Test
    @DisplayName("FR-3c: meglévő denomination-sor mentésekor NINCS denomination_allowed-validáció (csak az auto-create ág ellenőriz)")
    void existingDenominationBypassesValidation() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(companyId);
            // A sor már létezik a fiókon → orElseGet/auto-create ág nem fut.
            lenient().when(denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(any(), any(), any()))
                    .thenReturn(Optional.of(Denomination.builder()
                            .id(99L)
                            .faceValue(BigDecimal.ONE)
                            .build()));

            assertThatCode(() ->
                    service.countDenominations(branchId, businessDate,
                            Map.of("EUR", Map.of(1, 2))))
                    .doesNotThrowAnyException();

            verify(denominationAllowedRepository, never()).findActiveAllowed(any(), anyLong(), any());
        }
    }

    /**
     * ellenor1 WARNING-1 (FK-076 review) regressziós védelme: a companyId a
     * SecurityUtils-ból jön, NEM a {@code branch.getCompany()} lazy-proxy láncból.
     * Korábban a lazy-proxy null-esete AUDIT NÉLKÜL utasított el.
     */
    @Test
    @DisplayName("WARNING-1: a companyId a SecurityUtils-ból jön — a lazy branch.company nem befolyásolja az elutasítást/auditot")
    void companyIdComesFromSecurityContextNotLazyBranchProxy() {
        Branch branchWithoutCompany = Branch.builder().id(branchId).code("BR001").company(null).build();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(companyId);
            lenient().when(branchRepository.findByIdAndCompanyId(branchId, companyId))
                    .thenReturn(Optional.of(branchWithoutCompany));
            when(denominationAllowedRepository.findActiveAllowed(companyId, 5L, new BigDecimal("5")))
                    .thenReturn(Optional.empty());

            assertThatThrownBy(() ->
                    service.countDenominations(branchId, businessDate,
                            Map.of("CHF", Map.of(5, 3))))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("VV-VALID-006");

            // A lenyeg: az elutasitas AUDITALVA van, noha a branch.company null.
            verify(auditLogService).logInNewTransactionForCompany(
                    org.mockito.ArgumentMatchers.eq("DENOMINATION_ALLOWED_REJECTED"),
                    org.mockito.ArgumentMatchers.contains("VV-VALID-006"),
                    org.mockito.ArgumentMatchers.eq(branchId.toString()),
                    org.mockito.ArgumentMatchers.eq(companyId));
            verify(denominationRepository, never()).save(any());
        }
    }
}
