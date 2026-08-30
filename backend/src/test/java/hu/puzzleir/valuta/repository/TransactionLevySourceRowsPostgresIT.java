package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FK-099 P-sorozat (delta WU4b) — a riport-univerzum JPQL-je valós PostgreSQL-en,
 * valódi {@code Transaction} entitásokkal (D14).
 *
 * <p>Harness: {@code HandlingFeeDailySummaryPostgresIT} minta; a {@code saveTransaction}
 * FK-099-változata hufAmount / conversionGroupId / financialEffective paraméterekkel
 * bővül (a FK-053 eredeti ezeket hardkódolja).</p>
 *
 * <p>A vetület oszlop-sorrendje SZERZŐDÉS: (date, branchId, branchCode, branchName,
 * type, hufAmount, conversionGroupId, financialEffective, customerId, status) — a P12
 * minden oszlopot pinel, az index-csúszás itt bukik el, nem a foldban. A status
 * oszlop (row[9]) a round-2 D19 parent-status projekciója (FR-16 csoport-szint).</p>
 */
@Testcontainers
@EnableJpaAuditing
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff"
        })
class TransactionLevySourceRowsPostgresIT {

    private static final LocalDate D1 = LocalDate.of(2026, 8, 3);
    private static final LocalDate D2 = LocalDate.of(2026, 8, 4);

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
    }

    @Autowired private CompanyRepository companyRepository;
    @Autowired private DictionaryRepository dictionaryRepository;
    @Autowired private BranchRepository branchRepository;
    @Autowired private WorkerRepository workerRepository;
    @Autowired private CurrencyRepository currencyRepository;
    @Autowired private TransactionRepository transactionRepository;
    @Autowired private TransactionTemplate transactionTemplate;

    /** A vetületi oszlop-sorrend SZERZŐDÉS (P12 pineli). */
    private record SourceRow(LocalDate date, String branchCode, TransactionType type,
                             BigDecimal hufAmount, UUID conversionGroupId,
                             boolean financialEffective, String customerId,
                             TransactionStatus status) {}

    private static SourceRow toSourceRow(Object[] row) {
        return new SourceRow(
                (LocalDate) row[0],
                (String) row[2],
                (TransactionType) row[4],
                (BigDecimal) row[5],
                (UUID) row[6],
                (Boolean) row[7],
                (String) row[8],
                (TransactionStatus) row[9]);
    }

    @Test
    @DisplayName("FK-099 P1–P14: a riport-univerzum pontos sorhalmaza valós PostgreSQL-en")
    void universeReturnsExactlyTheExpectedRows() {
        Seed seed = transactionTemplate.execute(status -> seed());
        assertThat(seed).isNotNull();

        List<Object[]> rows = transactionRepository.findTransactionLevySourceRows(
                seed.companyA().getId(), null, D1, D2);

        List<SourceRow> actual = rows.stream().map(TransactionLevySourceRowsPostgresIT::toSourceRow).toList();

        // ============================ P8: IDENTITÁS (pontos halmaz, 10 sor) ============================
        List<SourceRow> expected = List.of(
                new SourceRow(D1, seed.branchA1().getCode(), TransactionType.BUY,
                        new BigDecimal("3000000.00"), null, true, "C1", TransactionStatus.COMPLETED),
                new SourceRow(D1, seed.branchA1().getCode(), TransactionType.SELL,
                        new BigDecimal("1000000.00"), null, true, "C2", TransactionStatus.COMPLETED),
                new SourceRow(D1, seed.branchA1().getCode(), TransactionType.CONVERSION,
                        new BigDecimal("3000000.00"), seed.groupG1(), false, "C3", TransactionStatus.COMPLETED),
                new SourceRow(D1, seed.branchA1().getCode(), TransactionType.BUY,
                        new BigDecimal("3000000.00"), seed.groupG1(), true, "C3", TransactionStatus.COMPLETED),
                new SourceRow(D2, seed.branchA1().getCode(), TransactionType.SELL,
                        new BigDecimal("2990000.00"), seed.groupG1(), true, "C3", TransactionStatus.COMPLETED),
                new SourceRow(D1, seed.branchA2().getCode(), TransactionType.BUY,
                        new BigDecimal("4444444.00"), null, true, "", TransactionStatus.COMPLETED),
                new SourceRow(D1, seed.branchA2().getCode(), TransactionType.BUY,
                        new BigDecimal("4444445.00"), null, true, "C7", TransactionStatus.COMPLETED),
                // G2 (round-2 D19): a REVERSED parent LÁTSZIK a halmazban, hogy a fold
                // megkülönböztesse a „sztornózott" és a „ténylegesen hiányzó parent" alakot.
                new SourceRow(D1, seed.branchA1().getCode(), TransactionType.CONVERSION,
                        new BigDecimal("3000000.00"), seed.groupG2(), false, "C10", TransactionStatus.REVERSED),
                new SourceRow(D1, seed.branchA1().getCode(), TransactionType.BUY,
                        new BigDecimal("3000000.00"), seed.groupG2(), true, "C10", TransactionStatus.COMPLETED),
                new SourceRow(D1, seed.branchA1().getCode(), TransactionType.SELL,
                        new BigDecimal("2990000.00"), seed.groupG2(), true, "C10", TransactionStatus.COMPLETED));

        assertThat(actual)
                .as("P8/FR-5/FR-15/FR-16: a visszaadott halmaz EXAKTAN {T1,T2,T3,T4,T5,T10,T11,T15,T16,T17} — "
                        + "nem szuperszett (a mutációs bizonyíték erre épül)")
                .containsExactlyInAnyOrderElementsOf(expected);

        // ============================ P1: önálló BUY/SELL ============================
        assertThat(actual).anySatisfy(row -> {
            assertThat(row.type()).isEqualTo(TransactionType.BUY);
            assertThat(row.conversionGroupId()).isNull();
            assertThat(row.financialEffective()).isTrue();
            assertThat(row.hufAmount()).isEqualByComparingTo("3000000.00");
            assertThat(row.customerId()).isEqualTo("C1");
        });
        assertThat(actual).anySatisfy(row -> {
            assertThat(row.type()).isEqualTo(TransactionType.SELL);
            assertThat(row.conversionGroupId()).isNull();
            assertThat(row.hufAmount()).isEqualByComparingTo("1000000.00");
            assertThat(row.customerId()).isEqualTo("C2");
        });

        // ============================ P2: konverzió-csoport mindhárom sora ============================
        assertThat(actual).filteredOn(row -> seed.groupG1().equals(row.conversionGroupId()))
                .as("P2/FR-5: a parent CONVERSION + convBuy + convSell MINDHÁROM sorban jön, "
                        + "hogy a service egyetlen csoportként fold-olja")
                .hasSize(3)
                .anySatisfy(row -> assertThat(row.type()).isEqualTo(TransactionType.CONVERSION))
                .anySatisfy(row -> assertThat(row.type()).isEqualTo(TransactionType.BUY))
                .anySatisfy(row -> assertThat(row.type()).isEqualTo(TransactionType.SELL));

        // ============================ P3: WU/MG/VIGNETTE kizárva ============================
        assertThat(actual)
                .as("P3/FR-15: WESTERN_UNION_SEND, MONEYGRAM_RECEIVE, VIGNETTE nincs az univerzumban")
                .noneSatisfy(row -> assertThat(row.type()).isIn(
                        TransactionType.WESTERN_UNION_SEND,
                        TransactionType.MONEYGRAM_RECEIVE,
                        TransactionType.VIGNETTE));

        // ============================ P4: REVERSED kizárva ============================
        assertThat(actual)
                .as("P4/FR-16: a 9 000 000-os REVERSED BUY nem szivárog be")
                .noneSatisfy(row -> assertThat(row.hufAmount()).isEqualByComparingTo("9000000.00"));

        // ============================ P6: ablakon kívüli sor kizárva ============================
        assertThat(actual)
                .as("P6: a D2+10-i 7 000 000-os BUY nincs az ablakban")
                .noneSatisfy(row -> assertThat(row.hufAmount()).isEqualByComparingTo("7000000.00"));

        // ============================ P7: nem-effective önálló sor kizárva ============================
        assertThat(actual)
                .as("P7: a financialEffective=false önálló BUY (2 000 000) egyik ágba sem illik")
                .noneSatisfy(row -> assertThat(row.hufAmount()).isEqualByComparingTo("2000000.00"));

        // ============================ P9: küszöb-pár kerekítetlenül ============================
        assertThat(actual)
                .filteredOn(row -> row.conversionGroupId() == null
                        && row.branchCode().equals(seed.branchA2().getCode()))
                .as("P9/FR-7: 4 444 444 és 4 444 445 scale-2 HUF-ként, kerekítetlenül")
                .hasSize(2)
                .anySatisfy(row -> assertThat(row.hufAmount()).isEqualByComparingTo("4444444.00"))
                .anySatisfy(row -> assertThat(row.hufAmount()).isEqualByComparingTo("4444445.00"));

        // ============================ P11: rendezés ============================
        for (int i = 1; i < rows.size(); i++) {
            LocalDate prevDate = (LocalDate) rows.get(i - 1)[0];
            LocalDate currDate = (LocalDate) rows.get(i)[0];
            assertThat(currDate).isAfterOrEqualTo(prevDate);
            if (prevDate.equals(currDate)) {
                String prevCode = (String) rows.get(i - 1)[2];
                String currCode = (String) rows.get(i)[2];
                assertThat(currCode.compareTo(prevCode))
                        .as("P11: azonos napon a branch-kód nem csökken (index %d)", i)
                        .isGreaterThanOrEqualTo(0);
            }
        }

        // ============================ P12: vetület-oszlopok ============================
        for (Object[] row : rows) {
            assertThat(row).as("P12: minden sor 10 oszlopos").hasSize(10);
            assertThat(row[1]).as("P12: row[1] a branch UUID").isInstanceOf(UUID.class);
            assertThat(row[3]).as("P12: row[3] a branch név").isInstanceOf(String.class);
            assertThat(row[8]).as("P12: row[8] a customerId").isInstanceOf(String.class);
            assertThat(row[9]).as("P12: row[9] a TransactionStatus").isInstanceOf(TransactionStatus.class);
        }

        // ============================ P13: D19 — sztornózott parent látszik (FR-16 csoport-szint) ============================
        assertThat(actual)
                .filteredOn(row -> seed.groupG2().equals(row.conversionGroupId()))
                .as("P13/FR-16/D19: a G2 csoport MINDHÁROM sora jön, parent REVERSED státusszal — "
                        + "a fold így különbözteti meg a sztornózott és a ténylegesen hiányzó parentet")
                .hasSize(3)
                .anySatisfy(row -> {
                    assertThat(row.type()).isEqualTo(TransactionType.CONVERSION);
                    assertThat(row.status()).isEqualTo(TransactionStatus.REVERSED);
                })
                .anySatisfy(row -> {
                    assertThat(row.type()).isEqualTo(TransactionType.BUY);
                    assertThat(row.status()).isEqualTo(TransactionStatus.COMPLETED);
                })
                .anySatisfy(row -> {
                    assertThat(row.type()).isEqualTo(TransactionType.SELL);
                    assertThat(row.status()).isEqualTo(TransactionStatus.COMPLETED);
                });

        // ============================ P14: pitfall 26 — csak a parent status-exempt ============================
        assertThat(actual)
                .filteredOn(row -> seed.groupG1().equals(row.conversionGroupId()))
                .as("P14/pitfall 26: a T18 REVERSED convBuy child (G1, 1 000 000) NEM szivárog be — "
                        + "a konverzió-ágon CSAK a parent státusz-exempt, a childoké nem; "
                        + "a G1 három VALID sora érintetlen")
                .hasSize(3)
                .noneSatisfy(row -> assertThat(row.hufAmount()).isEqualByComparingTo("1000000.00"));
    }

    @Test
    @DisplayName("FK-099 P5: idegen tenant sorai nem szivárognak — CO_B pontosan T13-at látja")
    void foreignTenantIsolation() {
        Seed seed = transactionTemplate.execute(status -> seed());
        assertThat(seed).isNotNull();

        List<Object[]> rowsA = transactionRepository.findTransactionLevySourceRows(
                seed.companyA().getId(), null, D1, D2);
        assertThat(rowsA.stream().map(TransactionLevySourceRowsPostgresIT::toSourceRow))
                .as("P5: a B-cég 5 000 000-os BUY-a (X1) nem jelenik meg az A-cég riportjában")
                .noneSatisfy(row -> assertThat(row.customerId()).isEqualTo("X1"));

        List<Object[]> rowsB = transactionRepository.findTransactionLevySourceRows(
                seed.companyB().getId(), null, D1, D2);
        assertThat(rowsB.stream().map(TransactionLevySourceRowsPostgresIT::toSourceRow))
                .as("P5: a B-cég pontosan a saját T13 sorát látja")
                .hasSize(1)
                .first()
                .satisfies(row -> {
                    assertThat(row.customerId()).isEqualTo("X1");
                    assertThat(row.hufAmount()).isEqualByComparingTo("5000000.00");
                    assertThat(row.type()).isEqualTo(TransactionType.BUY);
                });
    }

    @Test
    @DisplayName("FK-099 P10: branch-szűrő — csak BR_A2 sorai jönnek (a :branchId IS NULL OR … jó fele)")
    void branchFilterNarrowsToBranchRows() {
        Seed seed = transactionTemplate.execute(status -> seed());
        assertThat(seed).isNotNull();

        List<Object[]> rows = transactionRepository.findTransactionLevySourceRows(
                seed.companyA().getId(), seed.branchA2().getId(), D1, D2);

        assertThat(rows.stream().map(TransactionLevySourceRowsPostgresIT::toSourceRow))
                .as("P10: pontosan {T10, T11}")
                .hasSize(2)
                .allSatisfy(row -> assertThat(row.branchCode()).isEqualTo(seed.branchA2().getCode()))
                .anySatisfy(row -> assertThat(row.hufAmount()).isEqualByComparingTo("4444444.00"))
                .anySatisfy(row -> assertThat(row.hufAmount()).isEqualByComparingTo("4444445.00"));
    }

    // ============================ P15–P17: FK-100 FR-6 — region-szűrő (valós PostgreSQL) ============================

    @Test
    @DisplayName("FK-100 P15: region = branchA1.region → CSAK branchA1 univerzum-sorai (branchA2 sora nincs)")
    void regionFilterNarrowsToRegionBranchRows() {
        Seed seed = transactionTemplate.execute(status -> seed());
        assertThat(seed).isNotNull();

        List<Object[]> rows = transactionRepository.findTransactionLevySourceRows(
                seed.companyA().getId(), null, D1, D2, seed.branchA1().getRegion());

        List<SourceRow> actual = rows.stream().map(TransactionLevySourceRowsPostgresIT::toSourceRow).toList();
        assertThat(actual)
                .as("P15: a region-szűrő minden sora branchA1-hez tartozik")
                .isNotEmpty()
                .allSatisfy(row -> assertThat(row.branchCode()).isEqualTo(seed.branchA1().getCode()));
        assertThat(actual)
                .as("P15: a DEBRECEN branchA2 egyetlen sora sem szivárog be a SZEGED szűrőbe")
                .noneSatisfy(row -> assertThat(row.branchCode()).isEqualTo(seed.branchA2().getCode()));
    }

    @Test
    @DisplayName("FK-100 P16: a 4-arg default túlterhelés azonos halmazt ad, mint a region=null univerzum")
    void defaultOverloadMatchesUniverse() {
        Seed seed = transactionTemplate.execute(status -> seed());
        assertThat(seed).isNotNull();

        List<SourceRow> viaDefault = transactionRepository
                .findTransactionLevySourceRows(seed.companyA().getId(), null, D1, D2)
                .stream().map(TransactionLevySourceRowsPostgresIT::toSourceRow).toList();
        List<SourceRow> viaNullRegion = transactionRepository
                .findTransactionLevySourceRows(seed.companyA().getId(), null, D1, D2, null)
                .stream().map(TransactionLevySourceRowsPostgresIT::toSourceRow).toList();

        assertThat(viaDefault)
                .as("P16: a 4-arg túlterhelés pontosan a region=null univerzum-halmazt adja "
                        + "(a régi hívók regresszió-pinje)")
                .containsExactlyInAnyOrderElementsOf(viaNullRegion);
    }

    @Test
    @DisplayName("FK-100 P17: olyan region, amellyel egyetlen branch sem rendelkezik → üres lista, nincs hiba")
    void regionWithoutBranchesReturnsEmptyList() {
        Seed seed = transactionTemplate.execute(status -> seed());
        assertThat(seed).isNotNull();

        List<Object[]> rows = transactionRepository.findTransactionLevySourceRows(
                seed.companyA().getId(), null, D1, D2, "IRODA");

        assertThat(rows)
                .as("P17: a seed-ben IRODA regionű branch nincs — üres eredmény, nem kivétel")
                .isEmpty();
    }

    // ============================ SEED ============================

    private Seed seed() {
        LocalDateTime now = D1.atTime(8, 0);
        String suffix = UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_TYPE")
                .code("FK099-BT-" + suffix)
                .name("FK-099 branch type")
                .createdAt(now)
                .build());
        Dictionary country = dictionaryRepository.save(Dictionary.builder()
                .category("COUNTRY")
                .code("FK099-CO-" + suffix)
                .name("Hungary")
                .createdAt(now)
                .build());
        Dictionary branchStatus = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_STATUS")
                .code("FK099-BS-" + suffix)
                .name("Active")
                .createdAt(now)
                .build());
        Currency huf = currencyRepository.findByCode("HUF")
                .orElseGet(() -> currencyRepository.saveAndFlush(Currency.builder()
                        .code("HUF")
                        .name("Forint")
                        .symbol("Ft")
                        .decimalPlaces(0)
                        .active(true)
                        .displayOrder(1)
                        .createdAt(now)
                        .build()));

        Tenant tenantA = seedTenant("A" + suffix, branchType, country, branchStatus, now, "FK099A1",
                // FK-100 FR-6: branchA1 SZEGED (a kontraszt-ág DEBRECEN — P15 csak
                // eltérő regionökkel nem üres állítás).
                "SZEGED");
        Branch branchA2 = seedBranch(tenantA.company(), "A2" + suffix, branchType, country,
                branchStatus, now, "FK099A2",
                // P15 kontraszt: branchA2 MÁS terület (DEBRECEN), hogy a region-szűrő
                // ténylegesen kizárhassa a sorait.
                "DEBRECEN");
        Tenant tenantB = seedTenant("B" + suffix, branchType, country, branchStatus, now, "FK099B1",
                "SZEGED");

        UUID groupG1 = UUID.randomUUID();
        UUID groupG2 = UUID.randomUUID();

        // T1: önálló BUY, COMPLETED, 3M, effective, C1 (D1)
        saveTransaction(tenantA, huf, D1, TransactionType.BUY, TransactionStatus.COMPLETED,
                "3000000.00", null, true, "C1", "T1-" + suffix);
        // T2: önálló SELL, COMPLETED, 1M, effective, C2 (D1)
        saveTransaction(tenantA, huf, D1, TransactionType.SELL, TransactionStatus.COMPLETED,
                "1000000.00", null, true, "C2", "T2-" + suffix);
        // T3: parent CONVERSION, financialEffective = FALSE (a dupla-adó csapda első fele)
        saveTransaction(tenantA, huf, D1, TransactionType.CONVERSION, TransactionStatus.COMPLETED,
                "3000000.00", groupG1, false, "C3", "T3-" + suffix);
        // T4: convBuy child
        saveTransaction(tenantA, huf, D1, TransactionType.BUY, TransactionStatus.COMPLETED,
                "3000000.00", groupG1, true, "C3", "T4-" + suffix);
        // T5: convSell child — D2-n, hogy a dátum-csoportosítás query-szinten ne olvassza a csoportot
        saveTransaction(tenantA, huf, D2, TransactionType.SELL, TransactionStatus.COMPLETED,
                "2990000.00", groupG1, true, "C3", "T5-" + suffix);
        // T6: REVERSED BUY — ki kell maradnia (FR-16, 2. mutáció célpontja)
        saveTransaction(tenantA, huf, D1, TransactionType.BUY, TransactionStatus.REVERSED,
                "9000000.00", null, true, "C4", "T6-" + suffix);
        // T7: WESTERN_UNION_SEND — ki kell maradnia (FR-15)
        saveTransaction(tenantA, huf, D1, TransactionType.WESTERN_UNION_SEND, TransactionStatus.COMPLETED,
                "4000000.00", null, true, "C5", "T7-" + suffix);
        // T8: MONEYGRAM_RECEIVE — ki kell maradnia (FR-15)
        saveTransaction(tenantA, huf, D1, TransactionType.MONEYGRAM_RECEIVE, TransactionStatus.COMPLETED,
                "1500000.00", null, true, "C6", "T8-" + suffix);
        // T9: VIGNETTE — ki kell maradnia (FR-15)
        saveTransaction(tenantA, huf, D1, TransactionType.VIGNETTE, TransactionStatus.COMPLETED,
                "12000.00", null, true, "", "T9-" + suffix);
        // T10/T11: küszöb-pár BR_A2-n (4 444 444 normál, 4 444 445 küszöb feletti)
        Tenant tenantA2 = new Tenant(tenantA.company(), branchA2, tenantA.worker());
        saveTransaction(tenantA2, huf, D1, TransactionType.BUY, TransactionStatus.COMPLETED,
                "4444444.00", null, true, "", "T10-" + suffix);
        saveTransaction(tenantA2, huf, D1, TransactionType.BUY, TransactionStatus.COMPLETED,
                "4444445.00", null, true, "C7", "T11-" + suffix);
        // T12: ablakon KÍVÜL (D2 + 10 nap)
        saveTransaction(tenantA, huf, D2.plusDays(10), TransactionType.BUY, TransactionStatus.COMPLETED,
                "7000000.00", null, true, "C8", "T12-" + suffix);
        // T13: idegen tenant (CO_B) sora
        saveTransaction(tenantB, huf, D1, TransactionType.BUY, TransactionStatus.COMPLETED,
                "5000000.00", null, true, "X1", "T13-" + suffix);
        // T14: nem-effective önálló BUY — egyik univerzum-ágba sem illik
        saveTransaction(tenantA, huf, D1, TransactionType.BUY, TransactionStatus.COMPLETED,
                "2000000.00", null, false, "C9", "T14-" + suffix);
        // T15–T17 (round-2 D19): G2 konverzió-csoport SZTORNÓZOTT parenttel (ugyanaznapi storno alakja).
        // T15: parent CONVERSION, REVERSED — a query-nak vissza KELL adnia, hogy a fold lássa.
        saveTransaction(tenantA, huf, D1, TransactionType.CONVERSION, TransactionStatus.REVERSED,
                "3000000.00", groupG2, false, "C10", "T15-" + suffix);
        // T16: convBuy child — COMPLETED (a storno a childokat nem érinti)
        saveTransaction(tenantA, huf, D1, TransactionType.BUY, TransactionStatus.COMPLETED,
                "3000000.00", groupG2, true, "C10", "T16-" + suffix);
        // T17: convSell child — COMPLETED
        saveTransaction(tenantA, huf, D1, TransactionType.SELL, TransactionStatus.COMPLETED,
                "2990000.00", groupG2, true, "C10", "T17-" + suffix);
        // T18 (round-2, pitfall 26): REVERSED convBuy child a G1-ben — ki kell maradnia
        saveTransaction(tenantA, huf, D1, TransactionType.BUY, TransactionStatus.REVERSED,
                "1000000.00", groupG1, true, "C11", "T18-" + suffix);

        transactionRepository.flush();
        return new Seed(tenantA.company(), tenantA.branch(), branchA2,
                tenantB.company(), groupG1, groupG2);
    }

    private Tenant seedTenant(
            String suffix,
            Dictionary branchType,
            Dictionary country,
            Dictionary branchStatus,
            LocalDateTime now,
            String branchCodePrefix,
            String region) {
        Company company = companyRepository.save(Company.builder()
                .code("FK099-C-" + suffix)
                .name("FK-099 Company " + suffix)
                .createdAt(now)
                .build());
        Branch branch = seedBranch(company, suffix, branchType, country, branchStatus, now,
                branchCodePrefix, region);
        Worker worker = seedWorker(company, branch, suffix, now);
        return new Tenant(company, branch, worker);
    }

    private Branch seedBranch(
            Company company,
            String suffix,
            Dictionary branchType,
            Dictionary country,
            Dictionary branchStatus,
            LocalDateTime now,
            String codePrefix,
            String region) {
        return branchRepository.save(Branch.builder()
                .code(codePrefix + "-" + suffix)
                .company(company)
                .bankCode("FK099BANK")
                .branchType(branchType)
                .name("FK-099 Branch " + suffix)
                .address("Test Street 1")
                .city("Budapest")
                .zipCode("1000")
                .country(country)
                .branchStatus(branchStatus)
                .isVault(false)
                .openingDate(D1)
                .createdAt(now)
                // FK-100 FR-6: a region-oszlop a P15–P17 szűrő-tesztek alapja
                // (szöveges dictionary REGION kód, NEM a numerikus region_code).
                .region(region)
                .build());
    }

    private Worker seedWorker(Company company, Branch branch, String suffix, LocalDateTime now) {
        return workerRepository.save(Worker.builder()
                .company(company)
                .branch(branch)
                .code("FK099-W-" + suffix)
                .name("FK-099 Worker " + suffix)
                .passwordHash("$2a$10$test")
                .role(WorkerRole.CASHIER)
                .active(true)
                .createdAt(now)
                .build());
    }

    /**
     * FK-099 saveTransaction: a FK-053 eredetihez képest hufAmount / conversionGroupId /
     * financialEffective paraméterekkel (az eredeti ezeket hardkódolja — pitfall delta-1).
     */
    private void saveTransaction(
            Tenant tenant,
            Currency currency,
            LocalDate date,
            TransactionType type,
            TransactionStatus status,
            String hufAmount,
            UUID conversionGroupId,
            boolean financialEffective,
            String customerId,
            String receiptNumber) {
        Transaction transaction = Transaction.builder()
                .company(tenant.company())
                .branch(tenant.branch())
                .worker(tenant.worker())
                .receiptNumber(receiptNumber)
                .transactionType(type)
                .status(status)
                .transactionDate(date)
                .transactionTime(LocalTime.NOON)
                .currency(currency)
                .currencyAmount(BigDecimal.ONE)
                .exchangeRate(BigDecimal.ONE)
                .hufAmount(new BigDecimal(hufAmount))
                .customerId(customerId)
                .conversionGroupId(conversionGroupId)
                .financialEffective(financialEffective)
                .createdAt(date.atTime(12, 0))
                .build();
        transactionRepository.save(transaction);
    }

    private record Tenant(Company company, Branch branch, Worker worker) {}

    private record Seed(Company companyA, Branch branchA1, Branch branchA2,
                        Company companyB, UUID groupG1, UUID groupG2) {}
}
