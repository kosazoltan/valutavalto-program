package hu.puzzleir.valuta.service;

import tools.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * FK-066: Pénznemenkénti záráskori tolerancia — RED-fázis tesztek (teszt-vezérelt).
 *
 * <p>SZERZŐDÉS (Fázis 0 felderítés + Fázis 1 korrekciók szerint; az operátor-korrekció
 * a spec és a blokkoló-kérdés válasz-dokumentuma alapján rögzített, nem új döntés):
 * <ul>
 *   <li>Új komponens: {@code ClosingToleranceService} (Spring service, konstruktor-injektált
 *       {@code SystemParameterService}-szel), egyetlen publikus lekérdezéssel:
 *       {@code ClosingTolerance getToleranceFor(String currencyCode)}.</li>
 *   <li>{@code ClosingTolerance}: immutábilis értéktípus a {@code hu.puzzleir.valuta.service}
 *       csomagban — {@code value()} (BigDecimal), {@code explicit()} (boolean, az ág jelzése),
 *       gyárak: {@code explicitOf(BigDecimal)}, {@code fallbackOf(BigDecimal)}, és az
 *       EGYETLEN közös döntési pont: {@code boolean blocks(BigDecimal diff)}.</li>
 *   <li>ÁG-FÜGGŐ OPERÁTOR (KRITIKUS, FR-2/FR-3/FR-6):
 *       <ul>
 *         <li>EXPLICIT ág (van system_parameter sor): {@code |diff| >= value} BLOKKOL —
 *             a pontosan egyező eltérés IS blokkol; az utolsó átengedett érték
 *             {@code |diff| == value - 1}.</li>
 *         <li>FALLBACK ág (nincs sor): {@code |diff| > value} blokkol — a mai,
 *             változatlan viselkedés.</li>
 *         <li>Nulla eltérés SOHA nem blokkol (explicit 0-toleranciánál sem).</li>
 *       </ul>
 *       Mivel az operátor ág-függő, a döntés kizárólag a {@code ClosingTolerance.blocks()}
 *       közös metódusában élhet — a két kapu NEM implementálhat saját összehasonlítást.</li>
 *   <li>Kulcs-minta (FR-1): {@code "CLOSING_TOLERANCE_" + currencyCode}
 *       (pl. CLOSING_TOLERANCE_HUF, CLOSING_TOLERANCE_EUR). A lekérdezés a
 *       {@code SystemParameterService.findEffectiveValue(key)} útvonalon megy
 *       (findEffective-mechanizmus — a cég-szintű felülírást így ingyen kapja),
 *       és az explicit/fallback ág a SOR JELENLÉTÉBŐL dől el (Codex M1 fix), nem
 *       az érték/kód-default egyezéséből: a kód-defaulttal azonos értékű explicit
 *       sor is explicit ág ({@code >=}).</li>
 *   <li>KÓD-SZINTŰ fallback-default (FR-5), ha nincs system_parameter sor:
 *       {@code "HUF".equals(code) ? "1" : "0"} — a mai viselkedés tükre. Az 5-ös érték
 *       KIZÁRÓLAG a migráció által beszúrt explicit HUF-sor tartalma, NEM kód-fallback.</li>
 *   <li>Érvénytelen (nem szám) vagy negatív paraméter-érték → TELJES fallback-ág:
 *       pénznemenkénti default-érték ÉS fallback-operátor ({@code explicit() == false});
 *       WARN-log (tartalma itt nem assertált).</li>
 *   <li>FR-6 (közös forrás): a kemény kapu (DailyClosingService.checkEveningDenomination)
 *       ÉS a puha kapu (ClosingWizardService.finalizeClosing) UGYANAZT a
 *       {@code ClosingToleranceService.getToleranceFor}-t hívja, és a döntést a kapott
 *       {@code ClosingTolerance.blocks()}-ra bízza — ezt a gate-tesztek {@code verify()}-a
 *       + a strukturális tesztek rögzítik.</li>
 *   <li>FR-7: a blokkoló hibaüzenet tartalmazza az érintett pénznem kódját ÉS az
 *       alkalmazott tolerancia számértékét. A tolerancia-kiírást olyan esettel bizonyítjuk,
 *       ahol diff != tolerancia és az összegek számjegyei nem tartalmazzák a tolerancia
 *       számjegyét (a határ-eseteknél diff == tolerancia, ott ez nem szétválasztható).</li>
 *   <li>A statikus gate-helperek ({@code perCurrencyDiscrepancyBlockReason},
 *       {@code closingDiscrepancyBlockReason}) szignatúra-evolúciója az implementációs
 *       fázisban megengedett, dokumentált spec-változás (ág-vak csupasz BigDecimal
 *       paraméterrel a kettős operátor nem kifejezhető); a ClosingDiscrepancyGateTest
 *       TOL=1 tesztjei a fallback-szemantikát pinnelik. A JELEN fájl a publikus
 *       viselkedésen (executeStepCheck / finalizeClosing) keresztül fagyaszt.</li>
 *   <li>Nem-cél: vault-ág (FK-061 skip és exact-match kapu változatlan), cache-réteg
 *       bevezetése (NFR-2: nincs), nem-HUF fallback-tolerancia lazítása.</li>
 * </ul>
 *
 * <p>EBBEN A FÁZISBAN MINDEN TESZTNEK BUKNIA KELL (a {@code ClosingToleranceService} és a
 * {@code ClosingTolerance} még nem létezik — a fájl fordítási hibával piros, az FK-065
 * RED-minta szerint). Tesztet a bukás elfedésére módosítani TILOS.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class ClosingTolerancePerCurrencyFk066Test {

    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final LocalDate CLOSING_DATE = LocalDate.of(2026, 7, 24);

    private static CashBalance cashBalanceOf(String code, BigDecimal balance) {
        Currency currency = new Currency();
        currency.setCode(code);
        CashBalance cb = new CashBalance();
        cb.setCurrency(currency);
        cb.setCurrentBalance(balance);
        return cb;
    }

    // =====================================================================
    // FR-1 / FR-5 / FR-6-operátor: getToleranceFor + ClosingTolerance.blocks
    // =====================================================================

    @Nested
    @MockitoSettings(strictness = Strictness.LENIENT)
    class ToleranceLookup {

        @Mock private SystemParameterService systemParameterService;
        @InjectMocks private ClosingToleranceService toleranceService;

        @Test
        @DisplayName("FK-066 FR-1: explicit CLOSING_TOLERANCE_HUF='5' sor → érték 5, explicit ág (findEffectiveValue-n át)")
        void explicitHufValueWins() {
            when(systemParameterService.findEffectiveValue("CLOSING_TOLERANCE_HUF"))
                    .thenReturn(Optional.of("5"));

            ClosingTolerance tolerance = toleranceService.getToleranceFor("HUF");

            assertThat(tolerance.value()).isEqualByComparingTo("5");
            assertThat(tolerance.explicit()).isTrue();
            // A kulcs-minta pinnelve:
            verify(systemParameterService).findEffectiveValue("CLOSING_TOLERANCE_HUF");
        }

        @Test
        @DisplayName("FK-066 FR-6 operátor: explicit ágon |diff| >= tolerancia blokkol — diff==5 MÁR blokkol, 4 az utolsó átengedett")
        void explicitBranchBlocksAtEquality() {
            when(systemParameterService.findEffectiveValue("CLOSING_TOLERANCE_HUF"))
                    .thenReturn(Optional.of("5"));

            ClosingTolerance tolerance = toleranceService.getToleranceFor("HUF");

            assertThat(tolerance.blocks(new BigDecimal("4"))).isFalse();
            assertThat(tolerance.blocks(new BigDecimal("-4"))).isFalse();
            assertThat(tolerance.blocks(new BigDecimal("5"))).isTrue();
            assertThat(tolerance.blocks(new BigDecimal("-5"))).isTrue();
            assertThat(tolerance.blocks(new BigDecimal("6"))).isTrue();
            assertThat(tolerance.blocks(BigDecimal.ZERO)).isFalse();
        }

        @Test
        @DisplayName("FK-066 FR-1: explicit CLOSING_TOLERANCE_EUR='2' sor → érték 2, explicit ág (diff==2 blokkol, 1 átmegy)")
        void explicitNonHufValueWins() {
            when(systemParameterService.findEffectiveValue("CLOSING_TOLERANCE_EUR"))
                    .thenReturn(Optional.of("2"));

            ClosingTolerance tolerance = toleranceService.getToleranceFor("EUR");

            assertThat(tolerance.value()).isEqualByComparingTo("2");
            assertThat(tolerance.explicit()).isTrue();
            assertThat(tolerance.blocks(BigDecimal.ONE)).isFalse();
            assertThat(tolerance.blocks(new BigDecimal("2"))).isTrue();
            verify(systemParameterService).findEffectiveValue("CLOSING_TOLERANCE_EUR");
        }

        @Test
        @DisplayName("FK-066 Codex M1: a kód-defaulttal AZONOS értékű explicit sor is EXPLICIT ág — HUF '1' sor: diff==1 MÁR blokkol")
        void explicitRowEqualToCodeDefaultIsStillExplicit() {
            // A javított ág-eldöntés a sor jelenlétét nézi, nem az érték/default egyezését:
            when(systemParameterService.findEffectiveValue("CLOSING_TOLERANCE_HUF"))
                    .thenReturn(Optional.of("1"));

            ClosingTolerance tolerance = toleranceService.getToleranceFor("HUF");

            assertThat(tolerance.value()).isEqualByComparingTo("1");
            assertThat(tolerance.explicit()).isTrue();
            assertThat(tolerance.blocks(BigDecimal.ONE)).isTrue();
            assertThat(tolerance.blocks(BigDecimal.ZERO)).isFalse();
        }

        @Test
        @DisplayName("FK-066 FR-5: paraméter-sor nélkül fallback-ág, pénznemenként helyes defaulttal — HUF→1, EUR/USD/CZK→0")
        void fallbackDefaultsPerCurrency() {
            // A hiányzó sort a findEffectiveValue szerződése szerint az empty jelzi:
            when(systemParameterService.findEffectiveValue(anyString()))
                    .thenReturn(Optional.empty());

            ClosingTolerance huf = toleranceService.getToleranceFor("HUF");
            assertThat(huf.value()).isEqualByComparingTo("1");
            assertThat(huf.explicit()).isFalse();

            for (String code : List.of("EUR", "USD", "CZK")) {
                ClosingTolerance tolerance = toleranceService.getToleranceFor(code);
                assertThat(tolerance.value()).as(code).isEqualByComparingTo("0");
                assertThat(tolerance.explicit()).as(code).isFalse();
            }
            verify(systemParameterService).findEffectiveValue("CLOSING_TOLERANCE_USD");
            verify(systemParameterService).findEffectiveValue("CLOSING_TOLERANCE_CZK");
        }

        @Test
        @DisplayName("FK-066 FR-5/FR-6 operátor: fallback-ágon marad a mai > — HUF diff==1 átmegy, 2 blokkol; nem-HUF diff==1 blokkol")
        void fallbackBranchKeepsStrictGreaterOperator() {
            when(systemParameterService.findEffectiveValue(anyString()))
                    .thenReturn(Optional.empty());

            ClosingTolerance huf = toleranceService.getToleranceFor("HUF");
            assertThat(huf.blocks(BigDecimal.ONE)).isFalse();
            assertThat(huf.blocks(new BigDecimal("-1"))).isFalse();
            assertThat(huf.blocks(new BigDecimal("2"))).isTrue();

            ClosingTolerance eur = toleranceService.getToleranceFor("EUR");
            assertThat(eur.blocks(BigDecimal.ONE)).isTrue();
            assertThat(eur.blocks(BigDecimal.ZERO)).isFalse();
        }

        @Test
        @DisplayName("FK-066 FR-5: érvénytelen (nem szám) paraméter-érték → TELJES fallback-ág (érték ÉS operátor)")
        void invalidValueFallsBackPerCurrency() {
            when(systemParameterService.findEffectiveValue("CLOSING_TOLERANCE_HUF"))
                    .thenReturn(Optional.of("abc"));
            when(systemParameterService.findEffectiveValue("CLOSING_TOLERANCE_EUR"))
                    .thenReturn(Optional.of("abc"));

            ClosingTolerance huf = toleranceService.getToleranceFor("HUF");
            assertThat(huf.value()).isEqualByComparingTo("1");
            assertThat(huf.explicit())
                    .as("Érvénytelen sor nem explicit ág: a fallback > operátor él")
                    .isFalse();
            assertThat(huf.blocks(BigDecimal.ONE)).isFalse();

            assertThat(toleranceService.getToleranceFor("EUR").value()).isEqualByComparingTo("0");
        }

        @Test
        @DisplayName("FK-066 FR-5: negatív paraméter-érték → TELJES fallback-ág (tolerancia nem lehet negatív)")
        void negativeValueFallsBack() {
            when(systemParameterService.findEffectiveValue("CLOSING_TOLERANCE_HUF"))
                    .thenReturn(Optional.of("-3"));

            ClosingTolerance tolerance = toleranceService.getToleranceFor("HUF");
            assertThat(tolerance.value()).isEqualByComparingTo("1");
            assertThat(tolerance.explicit()).isFalse();
        }

        @Test
        @DisplayName("FK-066 Codex LOW: pénznemkód normalizálva (trim+uppercase) — ' huf ' ≡ 'HUF' kulcsban és fallbackben is")
        void currencyCodeNormalizedBeforeLookup() {
            when(systemParameterService.findEffectiveValue("CLOSING_TOLERANCE_HUF"))
                    .thenReturn(Optional.of("5"));

            for (String variant : List.of("HUF", "huf", " HUF ", " hUf")) {
                ClosingTolerance tolerance = toleranceService.getToleranceFor(variant);
                assertThat(tolerance.value()).as(variant).isEqualByComparingTo("5");
                assertThat(tolerance.explicit()).as(variant).isTrue();
            }
            // Mindegyik hívás a NORMALIZÁLT kulccsal ment ki:
            verify(systemParameterService, times(4)).findEffectiveValue("CLOSING_TOLERANCE_HUF");

            // Fallback-ágon is a normalizált kód dönt (HUF-default 1, nem 0):
            when(systemParameterService.findEffectiveValue("CLOSING_TOLERANCE_HUF"))
                    .thenReturn(Optional.empty());
            ClosingTolerance fallback = toleranceService.getToleranceFor(" huf ");
            assertThat(fallback.value()).isEqualByComparingTo("1");
            assertThat(fallback.explicit()).isFalse();
        }
    }

    // =====================================================================
    // FR-2 / FR-6 / FR-7: kemény kapu (DailyClosingService.checkEveningDenomination)
    // =====================================================================

    @Nested
    @MockitoSettings(strictness = Strictness.LENIENT)
    class HardGate {

        @InjectMocks private DailyClosingService dailyClosingService;

        @Mock private DailySessionService dailySessionService;
        @Mock private TransactionRepository transactionRepository;
        @Mock private CashBalanceRepository cashBalanceRepository;
        @Mock private DenominationBalanceRepository denominationBalanceRepository;
        @Mock private ClosingWizardRepository closingWizardRepository;
        @Mock private ExchangeRateRepository exchangeRateRepository;
        @Mock private CurrencyRepository currencyRepository;
        @Mock private SystemParameterService systemParameterService;
        @Mock private AuditLogService auditLogService;
        @Mock private BranchRepository branchRepository;
        /** FK-066: közös tolerancia-forrás — az implementációs fázis veszi fel a konstruktorba. */
        @Mock private ClosingToleranceService closingToleranceService;

        @BeforeEach
        void setUpSecurityContext() {
            hu.puzzleir.valuta.security.WorkerAuthenticationDetails details =
                    new hu.puzzleir.valuta.security.WorkerAuthenticationDetails(
                            1L, COMPANY_ID, BRANCH_ID, "ADMIN");
            TestingAuthenticationToken auth =
                    new TestingAuthenticationToken("test", "pass", "ROLE_ADMIN");
            auth.setDetails(details);
            SecurityContextHolder.getContext().setAuthentication(auth);

            Branch nonVaultBranch = new Branch();
            nonVaultBranch.setId(BRANCH_ID);
            nonVaultBranch.setIsVault(false);
            when(branchRepository.findById(any(UUID.class)))
                    .thenReturn(Optional.of(nonVaultBranch));
            when(denominationBalanceRepository.existsByBranchIdAndDateAndCategory(
                    any(), any(), eq(DenominationCategory.EVENING))).thenReturn(true);
        }

        @AfterEach
        void clearSecurityContext() {
            SecurityContextHolder.clearContext();
        }

        private void stubTolerances(Map<String, ClosingTolerance> byCode) {
            when(closingToleranceService.getToleranceFor(anyString()))
                    .thenAnswer(inv -> byCode.getOrDefault((String) inv.getArgument(0),
                            ClosingTolerance.fallbackOf(BigDecimal.ZERO)));
        }

        private void stubCounts(List<Object[]> denominated, List<CashBalance> expected) {
            when(denominationBalanceRepository.sumActualStockByCurrency(
                    BRANCH_ID, CLOSING_DATE, DenominationCategory.EVENING)).thenReturn(denominated);
            when(cashBalanceRepository.findByBranchIdAndCompanyId(BRANCH_ID, COMPANY_ID))
                    .thenReturn(expected);
        }

        @Test
        @DisplayName("FK-066 FR-2: explicit HUF-tolerancia 5 — |diff|=4 (tolerancia-1) az utolsó átengedett")
        void explicitHufTolerance_lastPassBoundary() {
            stubTolerances(Map.of("HUF", ClosingTolerance.explicitOf(new BigDecimal("5"))));
            stubCounts(
                    List.<Object[]>of(new Object[]{"HUF", new BigDecimal("100004")}),
                    List.of(cashBalanceOf("HUF", new BigDecimal("100000"))));

            DailyClosingService.StepCheckResult result =
                    dailyClosingService.executeStepCheck(2, BRANCH_ID, CLOSING_DATE);

            assertThat(result.isPassed()).isTrue();
            // FR-6 közös forrás: a kemény kapu a ClosingToleranceService-ből olvas.
            verify(closingToleranceService, atLeastOnce()).getToleranceFor("HUF");
        }

        @Test
        @DisplayName("FK-066 FR-2: explicit HUF-tolerancia 5 — |diff|=5 (pontos egyezés) MÁR BLOKKOL")
        void explicitHufTolerance_blocksAtEquality() {
            stubTolerances(Map.of("HUF", ClosingTolerance.explicitOf(new BigDecimal("5"))));
            // diff = 5: 100006 - 100001 (a határon a diff==tolerancia, ezért itt csak a
            // blokkolás tényét és a pénznemet assertáljuk; a tolerancia-kiírást az FR-7 teszt).
            stubCounts(
                    List.<Object[]>of(new Object[]{"HUF", new BigDecimal("100006")}),
                    List.of(cashBalanceOf("HUF", new BigDecimal("100001"))));

            DailyClosingService.StepCheckResult result =
                    dailyClosingService.executeStepCheck(2, BRANCH_ID, CLOSING_DATE);

            assertThat(result.isPassed()).isFalse();
            assertThat(result.getMessage()).contains("HUF");
            verify(closingToleranceService, atLeastOnce()).getToleranceFor("HUF");
        }

        @Test
        @DisplayName("FK-066 FR-7: blokkoló üzenet pénznem + ALKALMAZOTT tolerancia (diff=7, tol=5 — az '5' csak a toleranciából jöhet)")
        void blockMessageNamesCurrencyAndAppliedTolerance() {
            stubTolerances(Map.of("HUF", ClosingTolerance.explicitOf(new BigDecimal("5"))));
            // Számjegy-ütközés-mentes: 100008/100001, diff=7 — sem az összegek, sem a diff
            // nem tartalmaz '5'-öst, így a "5" assert CSAK a kiírt toleranciától teljesülhet.
            stubCounts(
                    List.<Object[]>of(new Object[]{"HUF", new BigDecimal("100008")}),
                    List.of(cashBalanceOf("HUF", new BigDecimal("100001"))));

            DailyClosingService.StepCheckResult result =
                    dailyClosingService.executeStepCheck(2, BRANCH_ID, CLOSING_DATE);

            assertThat(result.isPassed()).isFalse();
            assertThat(result.getMessage()).contains("HUF").contains("5");
        }

        @Test
        @DisplayName("FK-066 FR-2: explicit EUR-tolerancia 2 — diff=1 átmegy, diff=2 (pontos egyezés) blokkol EUR nevesítéssel")
        void explicitEurTolerance_boundary() {
            stubTolerances(Map.of(
                    "HUF", ClosingTolerance.fallbackOf(BigDecimal.ONE),
                    "EUR", ClosingTolerance.explicitOf(new BigDecimal("2"))));

            stubCounts(
                    List.<Object[]>of(
                            new Object[]{"HUF", new BigDecimal("100000")},
                            new Object[]{"EUR", new BigDecimal("101")}),
                    List.of(
                            cashBalanceOf("HUF", new BigDecimal("100000")),
                            cashBalanceOf("EUR", new BigDecimal("100"))));
            assertThat(dailyClosingService.executeStepCheck(2, BRANCH_ID, CLOSING_DATE).isPassed())
                    .isTrue();

            // diff = 2: 108 - 106 (a határon diff==tolerancia — pénznem-nevesítést assertálunk).
            stubCounts(
                    List.<Object[]>of(
                            new Object[]{"HUF", new BigDecimal("100000")},
                            new Object[]{"EUR", new BigDecimal("108")}),
                    List.of(
                            cashBalanceOf("HUF", new BigDecimal("100000")),
                            cashBalanceOf("EUR", new BigDecimal("106"))));
            DailyClosingService.StepCheckResult blocked =
                    dailyClosingService.executeStepCheck(2, BRANCH_ID, CLOSING_DATE);

            assertThat(blocked.isPassed()).isFalse();
            assertThat(blocked.getMessage()).contains("EUR");
            verify(closingToleranceService, atLeastOnce()).getToleranceFor("EUR");
        }

        @Test
        @DisplayName("FK-066 FR-2/FR-5: fallback-tolerancián (HUF=1) a diff=1 átmegy — de már a közös forrásból")
        void fallbackHufTolerance_oneStillPasses() {
            stubTolerances(Map.of("HUF", ClosingTolerance.fallbackOf(BigDecimal.ONE)));
            stubCounts(
                    List.<Object[]>of(new Object[]{"HUF", new BigDecimal("100001")}),
                    List.of(cashBalanceOf("HUF", new BigDecimal("100000"))));

            assertThat(dailyClosingService.executeStepCheck(2, BRANCH_ID, CLOSING_DATE).isPassed())
                    .isTrue();
            // RED-kulcs: a mai hardkódolt ternary ezt a hívást nem adja ki.
            verify(closingToleranceService, atLeastOnce()).getToleranceFor("HUF");
        }

        @Test
        @DisplayName("FK-066 FR-2/FR-5: fallback-tolerancián HUF diff=2 blokkol, EUR diff=1 blokkol (mai szemantika őrzése)")
        void fallbackTolerance_aboveBlocks() {
            stubTolerances(Map.of(
                    "HUF", ClosingTolerance.fallbackOf(BigDecimal.ONE),
                    "EUR", ClosingTolerance.fallbackOf(BigDecimal.ZERO)));

            stubCounts(
                    List.<Object[]>of(new Object[]{"HUF", new BigDecimal("100002")}),
                    List.of(cashBalanceOf("HUF", new BigDecimal("100000"))));
            assertThat(dailyClosingService.executeStepCheck(2, BRANCH_ID, CLOSING_DATE).isPassed())
                    .isFalse();

            stubCounts(
                    List.<Object[]>of(
                            new Object[]{"HUF", new BigDecimal("100000")},
                            new Object[]{"EUR", new BigDecimal("101")}),
                    List.of(
                            cashBalanceOf("HUF", new BigDecimal("100000")),
                            cashBalanceOf("EUR", new BigDecimal("100"))));
            DailyClosingService.StepCheckResult blocked =
                    dailyClosingService.executeStepCheck(2, BRANCH_ID, CLOSING_DATE);
            assertThat(blocked.isPassed()).isFalse();
            assertThat(blocked.getMessage()).contains("EUR");
            verify(closingToleranceService, atLeastOnce()).getToleranceFor("EUR");
        }
    }

    // =====================================================================
    // FR-3 / FR-6 / FR-7: puha kapu (ClosingWizardService.finalizeClosing)
    // =====================================================================

    @Nested
    @MockitoSettings(strictness = Strictness.LENIENT)
    class SoftGate {

        @InjectMocks private ClosingWizardService service;

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
        @Mock private AuditLogService auditLogService;
        /** FK-066: közös tolerancia-forrás — az implementációs fázis veszi fel a konstruktorba. */
        @Mock private ClosingToleranceService closingToleranceService;
        // FKH-036 WU-5: az új konstruktor-függőségek mockjai (pitfall 1).
        @Mock private ShipmentRequestRepository shipmentRequestRepository;
        @Mock private ShipmentHandlingFeeRepository shipmentHandlingFeeRepository;

        private ClosingWizard wizard;

        @BeforeEach
        void setUpWizard() {
            wizard = ClosingWizard.builder()
                    .id(UUID.randomUUID())
                    .branch(Branch.builder()
                            .id(BRANCH_ID)
                            .company(Company.builder().id(COMPANY_ID).build())
                            .build())
                    .closingDate(CLOSING_DATE)
                    .closingType(ClosingType.DAILY)
                    .wizardStatus(WizardStatus.IN_PROGRESS)
                    .startedByWorker(Worker.builder().id(1L).build())
                    .startedAt(LocalDateTime.now().minusMinutes(30))
                    .build();

            when(closingWizardRepository.findByIdWithSteps(wizard.getId()))
                    .thenReturn(Optional.of(wizard));
            when(closingWizardRepository.save(any(ClosingWizard.class)))
                    .thenAnswer(inv -> inv.getArgument(0));
            when(workerRepository.findById(2L))
                    .thenReturn(Optional.of(Worker.builder().id(2L).build()));
            // G3 enforcement BE (V307 óta prod-default):
            when(systemParameterService.getValue(eq("CLOSING_DISCREPANCY_EXPLANATION_REQUIRED"), anyString()))
                    .thenReturn("true");
            when(dailyClosingService.startDailyClosing(CLOSING_DATE))
                    .thenReturn(DailyClosingService.ClosingWizardResult.builder()
                            .allPassed(true)
                            .steps(List.of())
                            .build());
        }

        @AfterEach
        void clearSecurityContext() {
            SecurityContextHolder.clearContext();
        }

        private void stubTolerances(Map<String, ClosingTolerance> byCode) {
            when(closingToleranceService.getToleranceFor(anyString()))
                    .thenAnswer(inv -> byCode.getOrDefault((String) inv.getArgument(0),
                            ClosingTolerance.fallbackOf(BigDecimal.ZERO)));
        }

        private void stubCounts(List<Object[]> denominated, List<CashBalance> expected) {
            when(denominationBalanceRepository.sumActualStockByCurrency(
                    BRANCH_ID, CLOSING_DATE, DenominationCategory.EVENING)).thenReturn(denominated);
            when(cashBalanceRepository.findByBranchIdAndCompanyId(BRANCH_ID, COMPANY_ID))
                    .thenReturn(expected);
        }

        private boolean finalizeWith(String explanation) {
            try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
                su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
                su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
                su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_ID);
                return service.finalizeClosing(wizard.getId(), 2L, explanation);
            }
        }

        @Test
        @DisplayName("FK-066 FR-3: explicit HUF-tolerancia 5 — |diff|=4 (tolerancia-1) magyarázat NÉLKÜL véglegesíthető")
        void explicitHufTolerance_lastPassBoundaryFinalizes() {
            stubTolerances(Map.of("HUF", ClosingTolerance.explicitOf(new BigDecimal("5"))));
            stubCounts(
                    List.<Object[]>of(new Object[]{"HUF", new BigDecimal("100004")}),
                    List.of(cashBalanceOf("HUF", new BigDecimal("100000"))));

            assertThat(finalizeWith(null)).isTrue();
            verify(dailyClosingService).startDailyClosing(CLOSING_DATE);
            // FR-6 közös forrás: a puha kapu UGYANABBÓL a metódusból olvas, mint a kemény.
            verify(closingToleranceService, atLeastOnce()).getToleranceFor("HUF");
        }

        @Test
        @DisplayName("FK-066 FR-3: explicit HUF-tolerancia 5 — |diff|=5 (pontos egyezés) MÁR BLOKKOL magyarázat nélkül")
        void explicitHufTolerance_blocksAtEquality() {
            stubTolerances(Map.of("HUF", ClosingTolerance.explicitOf(new BigDecimal("5"))));
            // diff = 5: 100006 - 100001 (határ-eset: diff==tolerancia — blokkolás + pénznem).
            stubCounts(
                    List.<Object[]>of(new Object[]{"HUF", new BigDecimal("100006")}),
                    List.of(cashBalanceOf("HUF", new BigDecimal("100001"))));

            assertThatThrownBy(() -> finalizeWith(null))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("HUF");
            verify(dailyClosingService, never()).startDailyClosing(any());
            verify(closingToleranceService, atLeastOnce()).getToleranceFor("HUF");
        }

        @Test
        @DisplayName("FK-066 FR-7: blokkoló üzenet pénznem + ALKALMAZOTT tolerancia (diff=7, tol=5 — az '5' csak a toleranciából jöhet)")
        void blockMessageNamesCurrencyAndAppliedTolerance() {
            stubTolerances(Map.of("HUF", ClosingTolerance.explicitOf(new BigDecimal("5"))));
            // Számjegy-ütközés-mentes: 100008/100001, diff=7 — a "5" assert csak a
            // kiírt toleranciától teljesülhet (FR-7).
            stubCounts(
                    List.<Object[]>of(new Object[]{"HUF", new BigDecimal("100008")}),
                    List.of(cashBalanceOf("HUF", new BigDecimal("100001"))));

            assertThatThrownBy(() -> finalizeWith(null))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("HUF")
                    .hasMessageContaining("5");
            verify(dailyClosingService, never()).startDailyClosing(any());
        }

        @Test
        @DisplayName("FK-066 FR-3: explicit EUR-tolerancia 2 — diff=1 véglegesíthető, diff=2 (pontos egyezés) blokkol EUR nevesítéssel")
        void explicitEurTolerance_boundary() {
            stubTolerances(Map.of(
                    "HUF", ClosingTolerance.fallbackOf(BigDecimal.ONE),
                    "EUR", ClosingTolerance.explicitOf(new BigDecimal("2"))));

            stubCounts(
                    List.<Object[]>of(
                            new Object[]{"HUF", new BigDecimal("100000")},
                            new Object[]{"EUR", new BigDecimal("101")}),
                    List.of(
                            cashBalanceOf("HUF", new BigDecimal("100000")),
                            cashBalanceOf("EUR", new BigDecimal("100"))));
            assertThat(finalizeWith(null)).isTrue();

            wizard.setWizardStatus(WizardStatus.IN_PROGRESS);
            // diff = 2: 108 - 106 (határ-eset: diff==tolerancia — blokkolás + pénznem).
            stubCounts(
                    List.<Object[]>of(
                            new Object[]{"HUF", new BigDecimal("100000")},
                            new Object[]{"EUR", new BigDecimal("108")}),
                    List.of(
                            cashBalanceOf("HUF", new BigDecimal("100000")),
                            cashBalanceOf("EUR", new BigDecimal("106"))));
            assertThatThrownBy(() -> finalizeWith(null))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("EUR");
            verify(closingToleranceService, atLeastOnce()).getToleranceFor("EUR");
        }

        @Test
        @DisplayName("FK-066 FR-3/FR-5: fallback-tolerancián (HUF=1) diff=2 blokkol — a közös forrásból olvasva")
        void fallbackHufTolerance_aboveBlocks() {
            stubTolerances(Map.of("HUF", ClosingTolerance.fallbackOf(BigDecimal.ONE)));
            stubCounts(
                    List.<Object[]>of(new Object[]{"HUF", new BigDecimal("100002")}),
                    List.of(cashBalanceOf("HUF", new BigDecimal("100000"))));

            assertThatThrownBy(() -> finalizeWith(null))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("HUF");
            // RED-kulcs: a mai hardkódolt DISCREPANCY_TOLERANCE_HUF ezt a hívást nem adja ki.
            verify(closingToleranceService, atLeastOnce()).getToleranceFor("HUF");
        }

        @Test
        @DisplayName("FK-066 FR-3: a magyarázat-escape változatlan — a határon (diff==tolerancia) blokkolt eltérés magyarázattal véglegesíthető")
        void explanationStillOverridesBlock() {
            stubTolerances(Map.of("HUF", ClosingTolerance.explicitOf(new BigDecimal("5"))));
            stubCounts(
                    List.<Object[]>of(new Object[]{"HUF", new BigDecimal("100006")}),
                    List.of(cashBalanceOf("HUF", new BigDecimal("100001"))));

            assertThat(finalizeWith("Sérült bankjegy bevonva, igazgatói jóváhagyással")).isTrue();
            verify(dailyClosingService).startDailyClosing(CLOSING_DATE);
            verify(closingToleranceService, atLeastOnce()).getToleranceFor("HUF");
        }
    }

    // =====================================================================
    // FR-6: strukturális pin — közös forrás, nem két külön implementáció
    // =====================================================================

    @Nested
    class SameSourceContract {

        @Test
        @DisplayName("FK-066 FR-6: mindkét kapu-service a KÖZÖS ClosingToleranceService-t deklarálja függőségként")
        void bothGatesDeclareSharedToleranceService() {
            assertThat(Arrays.stream(DailyClosingService.class.getDeclaredFields())
                    .anyMatch(f -> f.getType().equals(ClosingToleranceService.class)))
                    .as("A kemény kapu (DailyClosingService) a közös ClosingToleranceService-ből olvas")
                    .isTrue();
            assertThat(Arrays.stream(ClosingWizardService.class.getDeclaredFields())
                    .anyMatch(f -> f.getType().equals(ClosingToleranceService.class)))
                    .as("A puha kapu (ClosingWizardService) a közös ClosingToleranceService-ből olvas")
                    .isTrue();
        }

        @Test
        @DisplayName("FK-066 FR-6: a lekérdezés belépési pontja getToleranceFor(String) → ClosingTolerance, a döntésé blocks(BigDecimal)")
        void singleLookupAndDecisionEntryPoints() throws NoSuchMethodException {
            assertThat(ClosingToleranceService.class
                    .getMethod("getToleranceFor", String.class).getReturnType())
                    .isEqualTo(ClosingTolerance.class);
            // Az ág-függő operátor (explicit >=, fallback >) EGYETLEN közös döntési
            // pontja — a kapuk nem implementálhatnak saját összehasonlítást:
            assertThat(ClosingTolerance.class
                    .getMethod("blocks", BigDecimal.class).getReturnType())
                    .isEqualTo(boolean.class);
        }
    }
}
