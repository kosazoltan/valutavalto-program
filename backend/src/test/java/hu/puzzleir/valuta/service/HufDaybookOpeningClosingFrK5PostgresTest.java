package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.dto.daybook.HufDaybookDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestItem;
import hu.puzzleir.valuta.entity.Transfer;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.DictionaryRepository;
import hu.puzzleir.valuta.repository.ShipmentRequestRepository;
import hu.puzzleir.valuta.repository.TransferRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;

import java.lang.reflect.Field;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.UUID;

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

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.fail;

/**
 * FKH-022 kiegészítés FR-K5 (RED-fázis): Nyitó/Záró HUF-egyenleg IMPLICIT horgonnyal.
 *
 * <p>Szemantika (lezárt spec-döntés): Nyitó = a lekérdezett nap ELŐTTI összes FF/UF tétel
 * előjeles összege (UF = átvétel +, FF = átadás −, sztornó negálva), dátum-alsókorlát
 * NÉLKÜL; Záró = Nyitó + napi UF − napi FF (= Nyitó + totalAtvetelHuf − totalAtadasHuf,
 * mert a napi totálok a sztornó-sorokat előjelesen már tartalmazzák).</p>
 *
 * <p>Kontraktus-döntések (spec-hézagok, dokumentálva a beadási jelentésben):
 * <ul>
 *   <li>Nap-hozzárendelés a kumulálásban: eredeti tétel a {@code requestDate}/{@code transferDate}
 *       napján, sztornó-hatás a {@code cancelledAt} napján számít — konzisztensen a napi lista
 *       FR-K6/11 szemantikájával.</li>
 *   <li>A CANCELLED/REJECTED státuszú (soha nem teljesült, FR-K13 szerint kizárt) transfer
 *       SEMMILYEN irányban nem számít bele a kumulált egyenlegbe.</li>
 *   <li>Az is_cancelled=true sztornó nettó hatása 0 (eredeti + negált sztornó-esemény),
 *       ha mindkét esemény a lekérdezett nap előtt van.</li>
 *   <li>A DTO-mezők olvasása reflectionnel történik, hogy a RED-fázisban a teljes
 *       teszt-suite forduljon (a hiányzó mező assertion-bukás, nem compile-hiba).</li>
 * </ul></p>
 */
@Testcontainers
@Import(HufDaybookService.class)
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff",
                "spring.jpa.hibernate.ddl-auto=create-drop",
                "spring.flyway.enabled=false",
                "spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect"
        })
class HufDaybookOpeningClosingFrK5PostgresTest {

    private static final LocalDate DAY_1 = LocalDate.of(2026, 7, 1);
    private static final LocalDate DAY_2 = LocalDate.of(2026, 7, 2);

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
    @Autowired private CurrencyRepository currencyRepository;
    @Autowired private WorkerRepository workerRepository;
    @Autowired private ShipmentRequestRepository shipmentRequestRepository;
    @Autowired private TransferRepository transferRepository;
    @Autowired private HufDaybookService hufDaybookService;
    @Autowired private TransactionTemplate transactionTemplate;

    /** A régió-scope guard kikapcsolva (null scope) — a fókusz a kumulált egyenleg. */
    @MockitoBean
    private AccessScopeService accessScopeService;

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    // =====================================================================
    // FR-K5 / 1. G-W-T: Nyitó = előző nap Zárója, Záró = Nyitó + UF − FF
    // =====================================================================
    @Test
    @DisplayName("FR-K5/1: a 2. nap Nyitója = az 1. nap Zárója (kumulált UF−FF), Zárója = Nyitó + napi UF − napi FF — shipment és transfer forrás vegyesen")
    void openingEqualsPreviousDayClosingAcrossDays() {
        Seed seed = transactionTemplate.execute(status -> seedBase("K5T1"));
        assertThat(seed).isNotNull();

        transactionTemplate.executeWithoutResult(status -> {
            // 1. nap: UF transfer 100 000 (B→A, átvétel) + FF shipment 30 000 (A-ról, átadás).
            saveTransfer(seed, "UF-110001", seed.branchB(), seed.branchA(),
                    DAY_1.atTime(9, 0, 0), new BigDecimal("100000"), false, null, Transfer.TransferStatus.COMPLETED);
            saveShipment(seed, "FF-110002", "FF", seed.branchA().getId(), seed.branchB().getId(),
                    DAY_1.atTime(10, 0, 0), new BigDecimal("30000"), null);
            // 2. nap: UF shipment 50 000 (A-ra, átvétel) + FF transfer 20 000 (A-ról, átadás).
            saveShipment(seed, "UF-110003", "UF", seed.branchB().getId(), seed.branchA().getId(),
                    DAY_2.atTime(9, 30, 0), new BigDecimal("50000"), null);
            saveTransfer(seed, "FF-110004", seed.branchA(), seed.branchB(),
                    DAY_2.atTime(11, 0, 0), new BigDecimal("20000"), false, null, Transfer.TransferStatus.COMPLETED);
        });

        authenticate(seed.company().getId(), seed.branchA().getId());

        HufDaybookDto day1 = hufDaybookService.getDaybook(seed.branchA().getId(), DAY_1);
        assertThat(balanceField(day1, "openingBalanceHuf"))
                .as("RED (FR-K5): az 1. nap előtt nincs tétel — a Nyitó 0 (implicit horgony)")
                .isEqualByComparingTo("0");
        assertThat(balanceField(day1, "closingBalanceHuf"))
                .as("Az 1. nap Zárója = 0 + 100 000 (UF) − 30 000 (FF) = 70 000")
                .isEqualByComparingTo("70000");

        HufDaybookDto day2 = hufDaybookService.getDaybook(seed.branchA().getId(), DAY_2);
        assertThat(balanceField(day2, "openingBalanceHuf"))
                .as("A 2. nap Nyitója = az 1. nap Zárója (70 000)")
                .isEqualByComparingTo(balanceField(day1, "closingBalanceHuf"))
                .isEqualByComparingTo("70000");
        assertThat(balanceField(day2, "closingBalanceHuf"))
                .as("A 2. nap Zárója = 70 000 + 50 000 (UF) − 20 000 (FF) = 100 000")
                .isEqualByComparingTo("100000");
    }

    // =====================================================================
    // FR-K5 / 2. G-W-T: első valaha rögzített nap — Nyitó = 0, dátumtól függetlenül
    // =====================================================================
    @Test
    @DisplayName("FR-K5/2: az első valaha rögzített FF/UF nap Nyitója 0 — tetszőleges (akár feature-kor előtti) dátumon, dátum-alsókorlát-függőség nélkül")
    void firstEverDayHasZeroOpeningRegardlessOfDate() {
        Seed seed = transactionTemplate.execute(status -> seedBase("K5T2"));
        assertThat(seed).isNotNull();

        // Szándékosan a feature-bevezetés (2026-06) ELŐTTI dátum: az implicit horgonynak
        // semmilyen beégetett dátum-alsókorláttól nem szabad függenie.
        LocalDate earlyDay = LocalDate.of(2025, 1, 10);
        transactionTemplate.executeWithoutResult(status ->
                saveTransfer(seed, "UF-120001", seed.branchB(), seed.branchA(),
                        earlyDay.atTime(9, 0, 0), new BigDecimal("42000"), false, null,
                        Transfer.TransferStatus.COMPLETED));

        authenticate(seed.company().getId(), seed.branchA().getId());
        HufDaybookDto daybook = hufDaybookService.getDaybook(seed.branchA().getId(), earlyDay);

        assertThat(balanceField(daybook, "openingBalanceHuf"))
                .as("RED (FR-K5): a rendszer első FF/UF napján a Nyitó pontosan 0")
                .isEqualByComparingTo("0");
        assertThat(balanceField(daybook, "closingBalanceHuf"))
                .as("Záró = 0 + 42 000 (UF)")
                .isEqualByComparingTo("42000");
    }

    // =====================================================================
    // FR-K5 / 3. G-W-T: sztornó/voided tételek kizárása a kumulált Nyitóból
    // =====================================================================
    @Test
    @DisplayName("FR-K5/3: a nap előtti sztornózott (is_cancelled/cancelledAt) tétel nettó 0-val, a CANCELLED/REJECTED (voided) transfer egyáltalán nem számít a Nyitóba")
    void stornoAndVoidedItemsExcludedFromCumulatedOpening() {
        Seed seed = transactionTemplate.execute(status -> seedBase("K5T3"));
        assertThat(seed).isNotNull();

        transactionTemplate.executeWithoutResult(status -> {
            // Normál UF 100 000 — egyedül ennek szabad a Nyitóban maradnia.
            saveTransfer(seed, "UF-130001", seed.branchB(), seed.branchA(),
                    DAY_1.atTime(9, 0, 0), new BigDecimal("100000"), false, null, Transfer.TransferStatus.COMPLETED);
            // Sztornózott FF transfer 40 000: eredeti (DAY_1) + sztornó-esemény (DAY_1 11:00) → nettó 0.
            saveTransfer(seed, "FF-130002", seed.branchA(), seed.branchB(),
                    DAY_1.atTime(9, 30, 0), new BigDecimal("40000"), true, DAY_1.atTime(11, 0), Transfer.TransferStatus.COMPLETED);
            // Sztornózott FF shipment 50 000: eredeti + sztornó ugyanaznap → nettó 0.
            saveShipment(seed, "FF-130003", "FF", seed.branchA().getId(), seed.branchB().getId(),
                    DAY_1.atTime(10, 0, 0), new BigDecimal("50000"), DAY_1.atTime(12, 0));
            // Voided (FR-K13): CANCELLED státuszú FF 77 000 — SEMMILYEN irányban nem számít.
            saveTransfer(seed, "FF-130004", seed.branchA(), seed.branchB(),
                    DAY_1.atTime(10, 30, 0), new BigDecimal("77000"), false, null, Transfer.TransferStatus.CANCELLED);
            // Voided (FR-K13): REJECTED státuszú UF 88 000 — nem számít.
            saveTransfer(seed, "UF-130005", seed.branchB(), seed.branchA(),
                    DAY_1.atTime(10, 45, 0), new BigDecimal("88000"), false, null, Transfer.TransferStatus.REJECTED);
        });

        authenticate(seed.company().getId(), seed.branchA().getId());
        HufDaybookDto day2 = hufDaybookService.getDaybook(seed.branchA().getId(), DAY_2);

        assertThat(balanceField(day2, "openingBalanceHuf"))
                .as("RED (FR-K5): a 2. nap Nyitója KIZÁRÓLAG a normál UF 100 000 — a sztornó nettó 0, "
                        + "a CANCELLED (77 000) és REJECTED (88 000) voided tétel teljesen kizárva "
                        + "(nem 100−40−50=10 ezer, nem 100+88−77 ezer, hanem pontosan 100 000)")
                .isEqualByComparingTo("100000");
        assertThat(balanceField(day2, "closingBalanceHuf"))
                .as("A 2. napon nincs tétel: Záró = Nyitó")
                .isEqualByComparingTo("100000");
    }

    // =====================================================================
    // FR-K5 / 4. G-W-T: KK bizonylat regressziós kizárása
    // =====================================================================
    @Test
    @DisplayName("FR-K5/4: a nap előtti KK (kezelési költség) bizonylat összege NEM része a Nyitó/Záró egyenlegnek — a szűrő FF/UF-ra korlátozott marad")
    void kkDocumentsExcludedFromCumulatedBalance() {
        Seed seed = transactionTemplate.execute(status -> seedBase("K5T4"));
        assertThat(seed).isNotNull();

        transactionTemplate.executeWithoutResult(status -> {
            // KK bizonylat mindkét irányban, kiugró összeggel — ha a szűrő valaha KK-ra bővülne,
            // a Nyitó azonnal elszállna.
            saveShipment(seed, "KK-140001", "KK", seed.branchA().getId(), seed.branchB().getId(),
                    DAY_1.atTime(8, 0, 0), new BigDecimal("9999995"), null);
            saveShipment(seed, "KK-140002", "KK", seed.branchB().getId(), seed.branchA().getId(),
                    DAY_1.atTime(8, 30, 0), new BigDecimal("8888880"), null);
            // Az egyetlen napló-releváns tétel: UF transfer 10 000.
            saveTransfer(seed, "UF-140003", seed.branchB(), seed.branchA(),
                    DAY_1.atTime(9, 0, 0), new BigDecimal("10000"), false, null, Transfer.TransferStatus.COMPLETED);
        });

        authenticate(seed.company().getId(), seed.branchA().getId());
        HufDaybookDto day2 = hufDaybookService.getDaybook(seed.branchA().getId(), DAY_2);

        assertThat(balanceField(day2, "openingBalanceHuf"))
                .as("RED (FR-K5): a Nyitó pontosan 10 000 — a KK bizonylatok (9 999 995 / 8 888 880) "
                        + "egyik irányban sem szivároghatnak be")
                .isEqualByComparingTo("10000");
    }

    // =====================================================================
    // FR-K5 / 5. G-W-T: cross-tenant izoláció a kumulált egyenlegben (§1 kötelező)
    // =====================================================================
    @Test
    @DisplayName("FR-K5/5: a Nyitó/Záró kizárólag a hívó tenant tételeit összegzi — másik tenant azonos napi FF/UF forgalma nem szivárog át")
    void crossTenantBalanceIsolation() {
        Seed tenant1 = transactionTemplate.execute(status -> seedBase("K5T5A"));
        Seed tenant2 = transactionTemplate.execute(status -> seedBase("K5T5B"));
        assertThat(tenant1).isNotNull();
        assertThat(tenant2).isNotNull();

        transactionTemplate.executeWithoutResult(status -> {
            // T1 forgalma ugyanazon a napon — a T2 egyenlegében nem jelenhet meg.
            saveTransfer(tenant1, "UF-150001", tenant1.branchB(), tenant1.branchA(),
                    DAY_1.atTime(9, 0, 0), new BigDecimal("500000"), false, null, Transfer.TransferStatus.COMPLETED);
            // T2 saját forgalma: UF 40 000 + FF 15 000.
            saveTransfer(tenant2, "UF-150002", tenant2.branchB(), tenant2.branchA(),
                    DAY_1.atTime(9, 30, 0), new BigDecimal("40000"), false, null, Transfer.TransferStatus.COMPLETED);
            saveShipment(tenant2, "FF-150003", "FF", tenant2.branchA().getId(), tenant2.branchB().getId(),
                    DAY_1.atTime(10, 0, 0), new BigDecimal("15000"), null);
        });

        authenticate(tenant2.company().getId(), tenant2.branchA().getId());
        HufDaybookDto day2 = hufDaybookService.getDaybook(tenant2.branchA().getId(), DAY_2);

        assertThat(balanceField(day2, "openingBalanceHuf"))
                .as("RED (FR-K5): a T2 Nyitója = 40 000 − 15 000 = 25 000 — a T1 500 000-es UF-je "
                        + "NEM számíthat bele (cross-tenant izoláció)")
                .isEqualByComparingTo("25000");
        assertThat(balanceField(day2, "closingBalanceHuf"))
                .as("A 2. napon nincs T2 tétel: Záró = Nyitó = 25 000")
                .isEqualByComparingTo("25000");
    }

    // ============================ HELPEREK ============================

    /**
     * RED-biztos mező-olvasó: amíg a HufDaybookDto-n nincs meg a mező, egyértelmű
     * RED-üzenettel bukik (nem compile-hibával); az implementáció után módosítás
     * nélkül a valódi értéket adja.
     */
    private static BigDecimal balanceField(HufDaybookDto dto, String fieldName) {
        try {
            Field field = HufDaybookDto.class.getDeclaredField(fieldName);
            field.setAccessible(true);
            return (BigDecimal) field.get(dto);
        } catch (NoSuchFieldException e) {
            fail("RED (FR-K5): a HufDaybookDto." + fieldName + " mező még nem létezik — "
                    + "a Nyitó/Záró egyenleg (implicit horgonyú kumulált UF−FF) implementációja hiányzik");
            return null;
        } catch (IllegalAccessException e) {
            throw new IllegalStateException(e);
        }
    }

    private void authenticate(UUID companyId, UUID branchId) {
        TestingAuthenticationToken authentication =
                new TestingAuthenticationToken("K5-TESZT", "test", "ROLE_ERTEKTAR");
        authentication.setDetails(new WorkerAuthenticationDetails(42L, companyId, branchId, "ERTEKTAR"));
        SecurityContextHolder.getContext().setAuthentication(authentication);
    }

    private void saveShipment(Seed seed, String requestNumber, String prefix,
                              UUID fromBranchId, UUID toBranchId, LocalDateTime createdAt,
                              BigDecimal hufValue, LocalDateTime cancelledAt) {
        ShipmentRequest request = ShipmentRequest.builder()
                .requestNumber(requestNumber)
                .companyId(seed.company().getId())
                .serialPrefix(prefix)
                .serialNumber(Long.parseLong(requestNumber.substring(3)))
                .fromBranchId(fromBranchId)
                .toBranchId(toBranchId)
                .requestedById(seed.worker().getId())
                .requestDate(createdAt.toLocalDate())
                .carrierName("Teszt Szallito")
                .sealNumber("PL-1")
                .cancelledAt(cancelledAt)
                .createdAt(createdAt)
                .build();
        request.addItem(ShipmentRequestItem.builder()
                .currencyId(seed.huf().getId())
                .requestedAmount(hufValue)
                .appliedRate(BigDecimal.ONE)
                .hufValue(hufValue)
                .build());
        shipmentRequestRepository.save(request);
    }

    private void saveTransfer(Seed seed, String transferNumber, Branch fromBranch, Branch toBranch,
                              LocalDateTime createdAt, BigDecimal hufAmount,
                              boolean isCancelled, LocalDateTime cancelledAt,
                              Transfer.TransferStatus status) {
        transferRepository.save(Transfer.builder()
                .transferNumber(transferNumber)
                .companyId(seed.company().getId())
                .fromBranch(fromBranch)
                .toBranch(toBranch)
                .fromWorker(seed.worker())
                .transferType(Transfer.TransferType.CASH)
                .status(status)
                .transferDate(createdAt.toLocalDate())
                .transferTime(createdAt.toLocalTime())
                .currency(seed.huf())
                .amount(hufAmount)
                .hufValue(hufAmount)
                .direction(Transfer.TransferDirection.F)
                .isCancelled(isCancelled)
                .cancelledAt(cancelledAt)
                .createdAt(createdAt)
                .build());
    }

    private Seed seedBase(String tag) {
        LocalDateTime now = DAY_1.atTime(6, 0);
        String suffix = UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        Company company = companyRepository.save(Company.builder()
                .code(tag + "-" + suffix)
                .name("FR-K5 balance company " + tag)
                .createdAt(now)
                .build());
        Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_TYPE")
                .code(tag + "-BT-" + suffix)
                .name("FR-K5 branch type")
                .createdAt(now)
                .build());
        Dictionary country = dictionaryRepository.save(Dictionary.builder()
                .category("COUNTRY")
                .code(tag + "-CO-" + suffix)
                .name("Hungary")
                .createdAt(now)
                .build());
        Dictionary branchStatus = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_STATUS")
                .code(tag + "-BS-" + suffix)
                .name("Active")
                .createdAt(now)
                .build());
        Branch branchA = seedBranch(company, tag + "-A-" + suffix, branchType, country, branchStatus, now);
        Branch branchB = seedBranch(company, tag + "-B-" + suffix, branchType, country, branchStatus, now);
        Worker worker = workerRepository.save(Worker.builder()
                .company(company)
                .branch(branchA)
                .code(("W" + suffix).substring(0, Math.min(10, ("W" + suffix).length())))
                .name("FR-K5 Teszt Dolgozo")
                .passwordHash("$2a$10$test")
                .role(WorkerRole.CASHIER)
                .active(true)
                .createdAt(now)
                .build());
        Currency huf = currencyRepository.findByCode("HUF")
                .orElseGet(() -> currencyRepository.saveAndFlush(Currency.builder()
                        .code("HUF")
                        .name("Forint")
                        .symbol("Ft")
                        .decimalPlaces(0)
                        .active(true)
                        .createdAt(now)
                        .build()));
        return new Seed(company, branchA, branchB, worker, huf);
    }

    private Branch seedBranch(Company company, String code, Dictionary branchType,
                              Dictionary country, Dictionary branchStatus, LocalDateTime now) {
        return branchRepository.save(Branch.builder()
                .code(code)
                .company(company)
                .bankCode("K5BANK")
                .branchType(branchType)
                .name("FR-K5 Branch " + code)
                .address("Teszt utca 1")
                .city("Budapest")
                .zipCode("1000")
                .country(country)
                .branchStatus(branchStatus)
                .isVault(false)
                .isActive(true)
                .openingDate(DAY_1)
                .createdAt(now)
                .build());
    }

    private record Seed(Company company, Branch branchA, Branch branchB, Worker worker, Currency huf) {
    }
}
