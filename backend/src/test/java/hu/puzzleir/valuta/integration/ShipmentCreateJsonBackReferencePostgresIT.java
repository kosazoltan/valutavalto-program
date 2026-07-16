package hu.puzzleir.valuta.integration;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.config.JacksonConfig;
import hu.puzzleir.valuta.controller.ShipmentController;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.DictionaryRepository;
import hu.puzzleir.valuta.repository.ShipmentRequestRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.ExchangeRateService;
import hu.puzzleir.valuta.service.ShipmentHandlingFeeService;
import hu.puzzleir.valuta.service.ShipmentHandlingFeeSyncService;
import hu.puzzleir.valuta.service.ShipmentService;
import hu.puzzleir.valuta.service.ShipmentStockBookingService;
import hu.puzzleir.valuta.service.TransferSerialSequenceService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import tools.jackson.databind.json.JsonMapper;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * A production create-útvonal holdout tesztje: JSON HTTP payload → controller →
 * {@link ShipmentService#create(hu.puzzleir.valuta.entity.ShipmentRequest)} → valós PostgreSQL.
 */
@Testcontainers
@EnableJpaAuditing
@Import({ShipmentController.class, ShipmentService.class, TransferSerialSequenceService.class})
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff"
        })
class ShipmentCreateJsonBackReferencePostgresIT {

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void pg(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
    }

    @Autowired private ShipmentController shipmentController;
    @Autowired private ShipmentRequestRepository shipmentRequestRepository;
    @Autowired private CompanyRepository companyRepository;
    @Autowired private BranchRepository branchRepository;
    @Autowired private DictionaryRepository dictionaryRepository;
    @Autowired private WorkerRepository workerRepository;
    @Autowired private CurrencyRepository currencyRepository;
    @Autowired private TransactionTemplate txTemplate;
    @Autowired private JdbcTemplate jdbc;

    @MockitoBean private ExchangeRateService exchangeRateService;
    @MockitoBean private ShipmentStockBookingService stockBookingService;
    @MockitoBean private ShipmentHandlingFeeSyncService handlingFeeSyncService;
    @MockitoBean private ShipmentHandlingFeeService shipmentHandlingFeeService;

    private MockMvc mockMvc;
    private Company company;
    private Branch fromBranch;
    private Branch toBranch;
    private Worker worker;
    private Currency huf;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(shipmentController).build();
        seedProductionCreatePrerequisites();
        when(stockBookingService.deriveTransferType(any(), any()))
                .thenReturn(ShipmentStockBookingService.TRANSFER_BRANCH_TO_BRANCH);

        WorkerAuthenticationDetails details =
                new WorkerAuthenticationDetails(worker.getId(), company.getId(), fromBranch.getId(), "CASHIER");
        TestingAuthenticationToken authentication =
                new TestingAuthenticationToken(worker.getCode(), "test", "ROLE_CASHIER");
        authentication.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(authentication);
    }

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("POST /shipments: JSON item back-reference-ével a teljes create útvonal valós PostgreSQL-re ment")
    void jsonPostPersistsItemWithParentReferenceOnRealPostgres() throws Exception {
        String json = """
                {"fromBranchId":"%s","toBranchId":"%s",
                 "carrierName":"Brink's Hungary Kft.","sealNumber":"PG-JSON-001",
                 "items":[{"currencyId":%d,"requestedAmount":1000000.01}]}
                """.formatted(fromBranch.getId(), toBranch.getId(), huf.getId());

        MvcResult result = mockMvc.perform(post("/api/v1/shipments")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().isCreated())
                .andReturn();

        JsonMapper mapper = new JacksonConfig().jsonMapper();
        UUID shipmentId = UUID.fromString(
                mapper.readTree(result.getResponse().getContentAsString()).get("id").asText());

        assertThat(shipmentRequestRepository.findById(shipmentId)).isPresent();
        assertThat(jdbc.queryForObject(
                        "SELECT count(*) FROM shipment_request_item WHERE shipment_request_id = ?",
                        Long.class,
                        shipmentId))
                .isEqualTo(1L);
        assertThat(jdbc.queryForObject(
                        "SELECT shipment_request_id FROM shipment_request_item WHERE shipment_request_id = ?",
                        UUID.class,
                        shipmentId))
                .isEqualTo(shipmentId);
    }

    private void seedProductionCreatePrerequisites() {
        txTemplate.executeWithoutResult(status -> {
            LocalDateTime now = LocalDateTime.now();
            String suffix = UUID.randomUUID().toString().substring(0, 8).toUpperCase();

            company = companyRepository.save(Company.builder()
                    .code("SJ-" + suffix)
                    .name("Shipment JSON PostgreSQL Company")
                    .createdAt(now)
                    .build());

            Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                    .category("BRANCH_TYPE")
                    .code("BT-" + suffix)
                    .name("Shipment JSON Branch Type")
                    .createdAt(now)
                    .build());
            Dictionary country = dictionaryRepository.save(Dictionary.builder()
                    .category("COUNTRY")
                    .code("CO-" + suffix)
                    .name("Hungary")
                    .createdAt(now)
                    .build());
            Dictionary branchStatus = dictionaryRepository.save(Dictionary.builder()
                    .category("BRANCH_STATUS")
                    .code("BS-" + suffix)
                    .name("Active")
                    .createdAt(now)
                    .build());

            fromBranch = branchRepository.save(Branch.builder()
                    .code("JF-" + suffix)
                    .company(company)
                    .bankCode("JSONPG")
                    .branchType(branchType)
                    .name("JSON source branch")
                    .address("Source Street 1")
                    .city("Budapest")
                    .zipCode("1000")
                    .country(country)
                    .branchStatus(branchStatus)
                    .isVault(false)
                    .openingDate(LocalDate.now())
                    .createdAt(now)
                    .build());
            toBranch = branchRepository.save(Branch.builder()
                    .code("JT-" + suffix)
                    .company(company)
                    .bankCode("JSONPG")
                    .branchType(branchType)
                    .name("JSON target branch")
                    .address("Target Street 1")
                    .city("Budapest")
                    .zipCode("1001")
                    .country(country)
                    .branchStatus(branchStatus)
                    .isVault(false)
                    .openingDate(LocalDate.now())
                    .createdAt(now)
                    .build());
            worker = workerRepository.save(Worker.builder()
                    .company(company)
                    .branch(fromBranch)
                    .code("JW-" + suffix)
                    .name("JSON PostgreSQL Worker")
                    .passwordHash("$2a$10$test")
                    .role(WorkerRole.CASHIER)
                    .active(true)
                    .createdAt(now)
                    .build());

            huf = currencyRepository.findByCode("HUF")
                    .orElseGet(() -> currencyRepository.saveAndFlush(Currency.builder()
                            .code("HUF")
                            .name("Forint")
                            .symbol("Ft")
                            .decimalPlaces(0)
                            .active(true)
                            .displayOrder(1)
                            .createdAt(now)
                            .build()));
        });
    }
}
