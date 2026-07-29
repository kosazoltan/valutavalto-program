package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.dto.daybook.HufDaybookDto;
import hu.puzzleir.valuta.dto.daybook.HufDaybookRowDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.DictionaryRepository;
import hu.puzzleir.valuta.repository.ShipmentRequestRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Map;
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

/**
 * FKH-022 kiegészítés FR-K3 (RED-fázis): partner-azonosító típus-elágazás a HUF naplókönyvben.
 *
 * <p>Kontraktus: a {@link HufDaybookRowDto} új {@code partnerCode} mezőt kap.
 * <ul>
 *   <li>Fizikai pénztár partner (Branch.type != VAULT_COUNTERPARTY): numerikus, 3 jegyű,
 *       0-paddelt kód a Branch.code numerikus részéből (BR076 → "076") — a
 *       {@code ReceiptSequenceService.extractBranchCode} legacy pénztárszám-mintája szerint.</li>
 *   <li>VAULT_COUNTERPARTY partner (PRB, ERB, ...): a betűkód VÁLTOZATLANUL jelenik meg,
 *       NEM eshet a numerikus/hash-alapú kinyerési ágba.</li>
 * </ul>
 * Partner-irány: FF bizonylatnál a partner a {@code toBranch}, UF-nél a {@code fromBranch}
 * (a daybook-lekérdezés irány-szemantikája szerint).</p>
 *
 * <p>A mező-asszerció Jackson property-térképen keresztül történik, hogy a teszt már MOST
 * leforduljon (RED = a partnerCode property hiányzik), és az implementáció után módosítás
 * nélkül váljon zölddé.</p>
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
class HufDaybookPartnerCodeFrK3PostgresTest {

    private static final LocalDate DAY = LocalDate.of(2026, 7, 1);

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
    @Autowired private ShipmentRequestRepository shipmentRequestRepository;
    @Autowired private HufDaybookService hufDaybookService;
    @Autowired private TransactionTemplate transactionTemplate;

    /** A régió-scope guard kikapcsolva (null scope) — a teszt fókusza a partner-kód. */
    @MockitoBean
    private AccessScopeService accessScopeService;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    // =====================================================================
    // FR-K3 / 5. G-W-T: fizikai pénztár partner → numerikus kód (BR076 → 076)
    // =====================================================================
    @Test
    @DisplayName("FR-K3/5: fizikai pénztár partnernél a partner-azonosító numerikus kód (BR076 → 076)")
    void physicalBranchPartnerYieldsNumericCode() {
        Seed seed = transactionTemplate.execute(status -> seed("K3T5"));
        assertThat(seed).isNotNull();

        // FF bizonylat: a kérdezett iroda a fromBranch, a partner a toBranch (BR076).
        transactionTemplate.executeWithoutResult(status ->
                saveShipment(seed.company(), "FF-000031", "FF",
                        seed.vaultBranch().getId(), seed.physicalBranch().getId(), DAY.atTime(9, 0)));

        authenticate(seed.company().getId(), seed.vaultBranch().getId());
        HufDaybookDto daybook = hufDaybookService.getDaybook(seed.vaultBranch().getId(), DAY);

        assertThat(daybook.getRows())
                .extracting(HufDaybookRowDto::getReceiptNumber)
                .contains("FF-000031");
        Map<String, Object> row = rowAsMap(daybook, "FF-000031");
        assertThat(row)
                .as("RED (FR-K3): a HufDaybookRowDto-n még nincs partnerCode mező — "
                        + "fizikai pénztárnál a numerikus kód (BR076 → 076) az elvárás")
                .containsEntry("partnerCode", "076");
    }

    // =====================================================================
    // FR-K3 / 6. G-W-T: VAULT_COUNTERPARTY partner → betűkód változatlanul
    // =====================================================================
    @Test
    @DisplayName("FR-K3/6: VAULT_COUNTERPARTY partnernél a betűkód (PRB) változatlanul jelenik meg, nem numerikus/hash-kinyeréssel")
    void vaultCounterpartyPartnerKeepsLetterCode() {
        Seed seed = transactionTemplate.execute(status -> seed("K3T6"));
        assertThat(seed).isNotNull();

        // UF bizonylat: a kérdezett iroda a toBranch, a partner a fromBranch (PRB counterparty).
        transactionTemplate.executeWithoutResult(status ->
                saveShipment(seed.company(), "UF-000032", "UF",
                        seed.counterpartyBranch().getId(), seed.vaultBranch().getId(), DAY.atTime(10, 0)));

        authenticate(seed.company().getId(), seed.vaultBranch().getId());
        HufDaybookDto daybook = hufDaybookService.getDaybook(seed.vaultBranch().getId(), DAY);

        assertThat(daybook.getRows())
                .extracting(HufDaybookRowDto::getReceiptNumber)
                .contains("UF-000032");
        Map<String, Object> row = rowAsMap(daybook, "UF-000032");
        assertThat(row)
                .as("RED (FR-K3): a HufDaybookRowDto-n még nincs partnerCode mező — "
                        + "VAULT_COUNTERPARTY-nál a betűkód (PRB) változatlan megjelenítése az elvárás")
                .containsEntry("partnerCode", "PRB");
        Object partnerCode = row.get("partnerCode");
        if (partnerCode instanceof String code) {
            assertThat(code)
                    .as("A counterparty betűkód NEM eshet a numerikus/hash-alapú 3 jegyű kinyerésbe")
                    .doesNotMatch("\\d{3}");
        }
    }

    // ============================ HELPEREK ============================

    private Map<String, Object> rowAsMap(HufDaybookDto daybook, String receiptNumber) {
        HufDaybookRowDto row = daybook.getRows().stream()
                .filter(r -> receiptNumber.equals(r.getReceiptNumber()))
                .findFirst()
                .orElseThrow(() -> new AssertionError("Hiányzó naplókönyv-sor: " + receiptNumber));
        return objectMapper.convertValue(row, new TypeReference<Map<String, Object>>() {
        });
    }

    private void authenticate(UUID companyId, UUID branchId) {
        TestingAuthenticationToken authentication =
                new TestingAuthenticationToken("K3-TESZT", "test", "ROLE_ERTEKTAR");
        authentication.setDetails(new WorkerAuthenticationDetails(42L, companyId, branchId, "ERTEKTAR"));
        SecurityContextHolder.getContext().setAuthentication(authentication);
    }

    private void saveShipment(Company company, String requestNumber, String prefix,
                              UUID fromBranchId, UUID toBranchId, LocalDateTime createdAt) {
        shipmentRequestRepository.save(ShipmentRequest.builder()
                .requestNumber(requestNumber)
                .companyId(company.getId())
                .serialPrefix(prefix)
                .serialNumber(Long.parseLong(requestNumber.substring(3)))
                .fromBranchId(fromBranchId)
                .toBranchId(toBranchId)
                .requestedById(42L)
                .requestDate(createdAt.toLocalDate())
                .carrierName("Teszt Szallito")
                .sealNumber("PL-1")
                .createdAt(createdAt)
                .build());
    }

    private Seed seed(String tag) {
        LocalDateTime now = DAY.atTime(6, 0);
        String suffix = UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        // CI-fix (PR #1518, branch_code_key duplikáció) — VÉGLEGES, shared-company megoldás:
        // az osztály két tesztmetódusa KÖZÖS sémán fut, a partner-kódok pedig literálisak és
        // globálisan unique-ok. Ezért a teszt-cég FIX kódú (FRK3-SHARED), find-or-create:
        // az elsőként futó metódus hozza létre, a második változtatás NÉLKÜL újrahasználja —
        // így a BR076/PRB partnerek is tiszta find-or-create-tel seedelhetők, companyId-átírás
        // SEHOL nincs. KIZÁRÓLAG setup-plumbing — egyetlen assertion sem változott.
        Company company = companyRepository.findByCode("FRK3-SHARED")
                .orElseGet(() -> companyRepository.save(Company.builder()
                        .code("FRK3-SHARED")
                        .name("FR-K3 megosztott partner teszt-ceg")
                        .createdAt(now)
                        .build()));
        Dictionary normalType = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_TYPE")
                .code(tag + "-BT-" + suffix)
                .name("FR-K3 normal branch type")
                .createdAt(now)
                .build());
        Dictionary counterpartyType = dictionaryRepository
                .findByCategoryAndCode("BRANCH_TYPE", "VAULT_COUNTERPARTY")
                .orElseGet(() -> dictionaryRepository.save(Dictionary.builder()
                        .category("BRANCH_TYPE")
                        .code("VAULT_COUNTERPARTY")
                        .name("Vault counterparty")
                        .createdAt(now)
                        .build()));
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

        // A kérdezett értéktár-iroda (a naplókönyv "saját" pénztára).
        Branch vaultBranch = seedBranch(company, tag + "-V-" + suffix, "FR-K3 Erektar",
                normalType, country, branchStatus, now, true);
        // Fizikai pénztár partner — a kód numerikus része a spec-példa szerinti 076.
        // A megosztott FRK3-SHARED cég alatt tiszta find-or-create: ha a másik metódus már
        // létrehozta, az EREDETI (közös cégű) branch változtatás nélkül újrahasznált.
        Branch physicalBranch = findOrCreateBranch("BR076", "Bekescsaba Tesco", company,
                normalType, country, branchStatus, now);
        // Virtuális banki partner — V277-minta: betűkód, VAULT_COUNTERPARTY branch-type.
        Branch counterpartyBranch = findOrCreateBranch("PRB", "POS Raiffeisen Bank", company,
                counterpartyType, country, branchStatus, now);

        return new Seed(company, vaultBranch, physicalBranch, counterpartyBranch);
    }

    /**
     * Literál-kódú partner-branch find-or-create seedje (setup-only): a globálisan unique
     * {@code branch.code} miatt a második tesztmetódus nem szúrhatja be újra ugyanazt a kódot.
     * A partnerek a fix kódú FRK3-SHARED teszt-céghez tartoznak, ezért a talált branch
     * MÓDOSÍTÁS NÉLKÜL újrahasználható — companyId-átírás nincs. (A {@code @Deprecated
     * findByCode} global lookup teszt-seed célra legitim.)
     */
    @SuppressWarnings("deprecation")
    private Branch findOrCreateBranch(String code, String name, Company company,
                                      Dictionary branchType, Dictionary country,
                                      Dictionary branchStatus, LocalDateTime now) {
        return branchRepository.findByCode(code)
                .orElseGet(() -> seedBranch(company, code, name, branchType, country,
                        branchStatus, now, false));
    }

    private Branch seedBranch(Company company, String code, String name, Dictionary branchType,
                              Dictionary country, Dictionary branchStatus, LocalDateTime now, boolean isVault) {
        return branchRepository.save(Branch.builder()
                .code(code)
                .company(company)
                .bankCode(code)
                .branchType(branchType)
                .name(name)
                .address("Teszt utca 1")
                .city("Budapest")
                .zipCode("1000")
                .country(country)
                .branchStatus(branchStatus)
                .isVault(isVault)
                .isActive(true)
                .openingDate(DAY)
                .createdAt(now)
                .build());
    }

    private record Seed(Company company, Branch vaultBranch, Branch physicalBranch,
                        Branch counterpartyBranch) {
    }
}
