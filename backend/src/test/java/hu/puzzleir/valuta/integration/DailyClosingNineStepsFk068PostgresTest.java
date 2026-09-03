package hu.puzzleir.valuta.integration;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.dto.closingwizard.ClosingWizardDto;
import hu.puzzleir.valuta.dto.eveningclosing.DailyDataPackage;
import hu.puzzleir.valuta.dto.eveningclosing.DataSyncResult;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.ClosingWizard;
import hu.puzzleir.valuta.entity.ClosingWizardStep;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.DailySession;
import hu.puzzleir.valuta.entity.DailySessionStatus;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.WizardStatus;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.ClosingWizardRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.DailySessionRepository;
import hu.puzzleir.valuta.repository.DictionaryRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.ClosingToleranceService;
import hu.puzzleir.valuta.service.ClosingWizardService;
import hu.puzzleir.valuta.service.DailyClosingService;
import hu.puzzleir.valuta.service.DailySessionService;
import hu.puzzleir.valuta.service.SystemParameterService;
import hu.puzzleir.valuta.service.AccessScopeService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

/**
 * FK-068 FR-3/FR-4: napi zárás vége-a-végéig valós PostgreSQL-en (Testcontainers) —
 * RED-fázis integrációs tesztek.
 *
 * <p>SZERZŐDÉS (FK-068 dokumentum, 9.2 tesztkör):
 * <ul>
 *   <li><b>FR-3 (pénztári):</b> wizard indítás DAILY típusra → a 9 ellenőrzés-pozíció
 *       elvégzettként jelölve → becímletezés beküldve (a nyilvántartással egyezően) →
 *       {@code finalizeClosing} hiba nélkül véglegesít (nincs
 *       "Nem minden lépés lett végrehajtva" hiba), a wizard COMPLETED, a napi
 *       munkamenet CLOSED.</li>
 *   <li><b>FR-4 (értéktári):</b> vault-kontextusú branch, a 9 ellenőrzés-pozíció
 *       elvégzettként jelölve → a lépés-teljesség-ellenőrzés NEM blokkol, a folyamat
 *       eljut az értéktár-specifikus, pénznemenkénti currency_stock
 *       egyezés-vizsgálatig (a teszt szándékolt eltéréssel ennek hibaüzenetét
 *       várja, bizonyítva hogy a vizsgálat elérésre került).</li>
 * </ul>
 *
 * <p>A "9 lépés elvégzettként jelölve" a wizard 1–9. POZÍCIÓJÁT jelenti — pontosan
 * ennyit jár be a frontend (ClosingWizardPage INITIAL_STEPS, 9 ellenőrzés), és a
 * {@code DailyClosingService.executeStepCheck} is csak az 1–9 pozíciókat ismeri.
 * A MOSTANI kódon a DAILY wizard 10 perzisztált lépéssel jön létre, így a 10.
 * pozíció soha nem teljesíthető a felületről → mindkét teszt a
 * "Nem minden lépés lett végrehajtva: Lépés 10" hibával BUKIK (RED). Tesztet a
 * bukás elfedésére módosítani TILOS.
 *
 * <p>Külső határfelület: az {@code EveningClosingService} (központba küldés —
 * HTTP/fájl-transport) mockolt; minden más (repository-k, service-lánc, Postgres)
 * valós. Lokálisan Docker hiányában a konténer-indítás hibája ismert baseline;
 * a teszt CI-ben fut élesben.
 */
@Testcontainers
// A TestApplication szándékosan nem component-scannel (ld. annak javadocja) —
// a valós zárási service-lánc a Shipment*PostgresIT-minta szerint @Import-tal
// kerül a kontextusba; a láncon kívüli kollaborátorok @MockitoBean-ek.
// SZÁNDÉKOSAN NINCS @EnableJpaAuditing: a mvn-test-suite többi tesztje arra épül,
// hogy a TestApplication-kontextusokban a @CreatedDate nem íródik felül (kézi
// createdAt-seedelés) — az auditingot igénylő írásokat (AuditLogService,
// ClosingControlService) ezért mockoljuk, a Denomination-sorokat pedig a seed
// hozza létre, hogy a countDenominations auto-create ága ne fusson.
@Import({
        ClosingWizardService.class,
        DailyClosingService.class,
        DailySessionService.class,
        SystemParameterService.class,
        ClosingToleranceService.class,
        AccessScopeService.class
})
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff",
                "spring.jpa.hibernate.ddl-auto=create-drop",
                "spring.flyway.enabled=false",
                "spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect"
        })
class DailyClosingNineStepsFk068PostgresTest {

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.datasource.driver-class-name", POSTGRES::getDriverClassName);
    }

    @Autowired private CompanyRepository companyRepository;
    @Autowired private DictionaryRepository dictionaryRepository;
    @Autowired private BranchRepository branchRepository;
    @Autowired private WorkerRepository workerRepository;
    @Autowired private CurrencyRepository currencyRepository;
    @Autowired private CashBalanceRepository cashBalanceRepository;
    @Autowired private hu.puzzleir.valuta.repository.DenominationRepository denominationRepository;
    @Autowired private DailySessionRepository dailySessionRepository;
    @Autowired private ClosingWizardRepository closingWizardRepository;
    @Autowired private ClosingWizardService closingWizardService;
    @Autowired private TransactionTemplate transactionTemplate;

    /**
     * Külső határfelület: a központba küldés (HTTP / fájl-transport) nem része az
     * FR-3 elfogadási feltételnek — a sikeres válasz stubolt, minden más valós.
     */
    @MockitoBean private hu.puzzleir.valuta.service.EveningClosingService eveningClosingService;

    // A zárási láncon kívüli kollaborátorok — az executeClosing ezeket try/catch-csel
    // (warning-ként) kezeli, vagy az adott ágon nem is hívja; a lépés-teljesség
    // (FR-3) és a vault-egyezés (FR-4) szerződését nem érintik. Az audit- és
    // zárás-kontroll írás @CreatedDate-auditingot igényelne (ld. osztály-komment),
    // ezért mock — az audit-trail nem része az FK-068 elfogadási feltételeknek.
    @MockitoBean private hu.puzzleir.valuta.service.AuditLogService auditLogService;
    @MockitoBean private hu.puzzleir.valuta.service.ClosingControlService closingControlService;
    @MockitoBean private hu.puzzleir.valuta.service.DailyBalanceService dailyBalanceService;
    @MockitoBean private hu.puzzleir.valuta.service.PosTerminalService posTerminalService;
    @MockitoBean private hu.puzzleir.valuta.service.MonthlyArchiveService monthlyArchiveService;
    @MockitoBean private hu.puzzleir.valuta.service.DailyClosingArchiveService dailyClosingArchiveService;
    @MockitoBean private hu.puzzleir.valuta.service.DecadeReportService decadeReportService;
    @MockitoBean private hu.puzzleir.valuta.service.AmlService amlService;
    @MockitoBean private hu.puzzleir.valuta.service.ReceiptSequenceService receiptSequenceService;
    @MockitoBean private hu.puzzleir.valuta.service.NotificationService notificationService;
    @MockitoBean private hu.puzzleir.valuta.service.CashBalanceService cashBalanceService;

    /** A becímletezett HUF összeg — a seedelt cash_balance-szal pontosan egyezik (0 eltérés). */
    private static final Map<String, Map<Integer, Integer>> HUF_DENOMS =
            Map.of("HUF", Map.of(20000, 5, 10000, 3, 5000, 2)); // = 140 000 Ft
    private static final BigDecimal HUF_TOTAL = new BigDecimal("140000.00");

    @AfterEach
    void tearDownSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("FK-068 FR-3: pénztári napi zárás — 9 elvégzett lépés + egyező becímletezés → véglegesítés hiba nélkül")
    void cashDeskDailyClosing_nineCompletedSteps_finalizesSuccessfully() {
        LocalDate today = LocalDate.now();
        Seed seed = transactionTemplate.execute(status -> seedBranch("FK68-CD", false, true));
        authenticateAs(seed);

        lenient().when(eveningClosingService.prepareDailyPackage(any(UUID.class), any(LocalDate.class)))
                .thenReturn(DailyDataPackage.builder().date(today).build());
        lenient().when(eveningClosingService.sendToHeadquarters(any()))
                .thenReturn(DataSyncResult.success("FK068-TEST-CHECKSUM"));
        lenient().when(receiptSequenceService.checkReceiptContinuity(any(UUID.class), any(LocalDate.class)))
                .thenReturn(java.util.List.of());

        ClosingWizardDto wizard = closingWizardService.startWizard(
                seed.branchId(), null, "DAILY", seed.workerId());
        UUID wizardId = UUID.fromString(wizard.getId());

        // Becímletezés beküldése — pontosan a nyilvántartott HUF készlet (0 eltérés).
        closingWizardService.countDenominations(seed.branchId(), today, HUF_DENOMS);

        completeFirstNinePositions(wizardId);

        // FR-3 acceptance: véglegesítéskor NINCS "nem minden lépés lett végrehajtva"
        // hiba, a zárás véglegesül. (A mostani kódon itt ValidationException:
        // "Nem minden lépés lett végrehajtva: Lépés 10" — ez az FK-068 hiba maga.)
        boolean finalized = closingWizardService.finalizeClosing(wizardId, seed.workerId());
        assertThat(finalized).isTrue();

        transactionTemplate.executeWithoutResult(status -> {
            ClosingWizard reloaded = closingWizardRepository.findByIdWithSteps(wizardId).orElseThrow();
            assertThat(reloaded.getWizardStatus()).isEqualTo(WizardStatus.COMPLETED);
            assertThat(dailySessionRepository.findByBranchIdAndSessionDate(
                            seed.companyId(), seed.branchId(), today)
                    .orElseThrow()
                    .getStatus())
                    .isEqualTo(DailySessionStatus.CLOSED);
        });
    }

    @Test
    @DisplayName("FK-068 FR-4: értéktári napi zárás — 9 elvégzett lépés után a folyamat eljut a currency_stock egyezés-vizsgálatig")
    void vaultDailyClosing_nineCompletedSteps_reachesVaultStockMatchCheck() {
        LocalDate today = LocalDate.now();
        Seed seed = transactionTemplate.execute(status -> seedBranch("FK68-VT", true, false));
        authenticateAs(seed);

        ClosingWizardDto wizard = closingWizardService.startWizard(
                seed.branchId(), null, "DAILY", seed.workerId());
        UUID wizardId = UUID.fromString(wizard.getId());

        // Becímletezés rögzítve, de currency_stock sor szándékosan NINCS seedelve →
        // a vault-specifikus egyezés-vizsgálatnak eltérést KELL jeleznie. Így a
        // teszt azt bizonyítja, hogy a lépés-teljesség-ellenőrzés után a folyamat
        // TÉNYLEGESEN eléri az értéktári vizsgálatot (FR-4 acceptance).
        closingWizardService.countDenominations(seed.branchId(), today, HUF_DENOMS);

        completeFirstNinePositions(wizardId);

        assertThatThrownBy(() -> closingWizardService.finalizeClosing(wizardId, seed.workerId()))
                .isInstanceOf(ValidationException.class)
                // Az értéktár-specifikus egyezés-vizsgálat üzenete — NEM a
                // lépés-teljesség hibája. (A mostani kódon az üzenet:
                // "Nem minden lépés lett végrehajtva: Lépés 10" → RED.)
                // FKH-036 kieg. #2 FR-13: az üzenet ékezetesített (a korábbi ékezet
                // nélküli "egyezese" helyett) — az elvárás a viselkedésváltozással
                // együtt frissítve, nem gyengítve.
                .hasMessageContaining("currency_stock teljes egyezése")
                .satisfies(ex -> assertThat(ex.getMessage())
                        .doesNotContain("Nem minden lépés lett végrehajtva"));
    }

    // ===== HELPER =====

    private record Seed(UUID companyId, UUID branchId, Long workerId) {
    }

    /**
     * A wizard 1–9. pozíciójának elvégzettként jelölése — pontosan az a halmaz,
     * amelyet a frontend 9 ellenőrzés-lépése (INITIAL_STEPS) bejár, és amelyet a
     * DailyClosingService.executeStepCheck ismer. A 9-en túli pozíció a felületről
     * soha nem teljesíthető — ez az FK-068 hiba gyökere.
     */
    private void completeFirstNinePositions(UUID wizardId) {
        transactionTemplate.executeWithoutResult(status -> {
            ClosingWizard reloaded = closingWizardRepository.findByIdWithSteps(wizardId).orElseThrow();
            for (ClosingWizardStep step : reloaded.getSteps()) {
                if (step.getStepNumber() <= 9) {
                    step.setCompleted(true);
                }
            }
            closingWizardRepository.save(reloaded);
        });
    }

    private void authenticateAs(Seed seed) {
        WorkerAuthenticationDetails details = new WorkerAuthenticationDetails(
                seed.workerId(), seed.companyId(), seed.branchId(), "PENZTAROS");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("t", "x", "ROLE_PENZTAROS");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    private Seed seedBranch(String prefix, boolean vault, boolean withOpenSession) {
        LocalDateTime now = LocalDateTime.now();
        String suffix = prefix + "-" + Long.toString(System.nanoTime());

        Company company = companyRepository.save(Company.builder()
                .code(shortCode("C", suffix))
                .name("FK-068 Company " + suffix)
                .createdAt(now)
                .build());

        Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_TYPE").code(shortCode("BT", suffix))
                .name("FK-068 branch type").createdAt(now).build());
        Dictionary country = dictionaryRepository.save(Dictionary.builder()
                .category("COUNTRY").code(shortCode("CO", suffix))
                .name("Hungary").createdAt(now).build());
        Dictionary statusDictionary = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_STATUS").code(shortCode("BS", suffix))
                .name("Active").createdAt(now).build());

        Branch branch = branchRepository.save(Branch.builder()
                .code(shortCode("BR", suffix))
                .company(company)
                .bankCode("FK68BANK")
                .branchType(branchType)
                .name("FK-068 Branch " + suffix)
                .address("Teszt utca 1")
                .city("Budapest")
                .zipCode("1000")
                .country(country)
                .branchStatus(statusDictionary)
                .openingDate(LocalDate.now())
                .isVault(vault)
                .vaultTerritoryId(vault ? 4242 : null)
                .createdAt(now)
                .build());

        Worker worker = workerRepository.save(Worker.builder()
                .company(company)
                .branch(branch)
                .code(shortCode("W", suffix))
                .name("FK-068 Pénztáros")
                .passwordHash("$2a$10$test")
                .role(WorkerRole.CASHIER)
                .active(true)
                .createdAt(now)
                .build());

        Currency huf = currencyRepository.findByCode("HUF")
                .orElseGet(() -> currencyRepository.saveAndFlush(Currency.builder()
                        .code("HUF").name("Forint").symbol("Ft")
                        .decimalPlaces(0).active(true).displayOrder(1)
                        .createdAt(now).build()));

        cashBalanceRepository.save(CashBalance.builder()
                .company(company)
                .branch(branch)
                .currency(huf)
                .openingBalance(HUF_TOTAL)
                .currentBalance(HUF_TOTAL)
                .createdAt(now)
                .build());

        // A becímletezett HUF címletek előseedelve (kézi createdAt-tal): a
        // countDenominations auto-create ága @CreatedDate-auditingot igényelne,
        // ami a TestApplication-kontextusokban szándékosan nincs bekapcsolva.
        for (int faceValue : new int[]{20000, 10000, 5000}) {
            denominationRepository.save(hu.puzzleir.valuta.entity.Denomination.builder()
                    .company(company)
                    .branch(branch)
                    .currency(huf)
                    .faceValue(BigDecimal.valueOf(faceValue))
                    .denominationType(hu.puzzleir.valuta.entity.DenominationType.BANKNOTE)
                    .active(true)
                    .createdAt(now)
                    .build());
        }

        if (withOpenSession) {
            dailySessionRepository.save(DailySession.builder()
                    .company(company)
                    .branch(branch)
                    .sessionDate(LocalDate.now())
                    .status(DailySessionStatus.OPEN)
                    .openedByWorker(worker)
                    .openedAt(now)
                    .openingBalanceHuf(HUF_TOTAL)
                    .transactionCount(0)
                    .buyCount(0)
                    .sellCount(0)
                    .buyTurnoverHuf(BigDecimal.ZERO)
                    .sellTurnoverHuf(BigDecimal.ZERO)
                    .createdAt(now)
                    .build());
        }

        return new Seed(company.getId(), branch.getId(), worker.getId());
    }

    /** A SeededPostgresAcceptanceIT mintája: prefix + max 8 számjegy — belefér a worker.code varchar(10)-be. */
    private static String shortCode(String kind, String suffix) {
        String digits = suffix.replaceAll("[^0-9]", "");
        String tail = digits.length() <= 8 ? digits : digits.substring(digits.length() - 8);
        return kind + tail;
    }
}
