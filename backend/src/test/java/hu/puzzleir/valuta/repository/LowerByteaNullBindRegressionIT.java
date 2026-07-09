package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Bank;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Customer;
import hu.puzzleir.valuta.entity.TeaorCode;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.domain.Limit;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.annotation.Transactional;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.time.LocalDateTime;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;

/**
 * LOWER-BYTEA-CLASS regresszio (#1376 osztaly-fix): a kereso JPQL-ek String
 * paramja valos PostgreSQL-en null-bind eseten sem kotodhet bytea-kent.
 */
@Testcontainers
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff",
                "spring.jpa.hibernate.ddl-auto=create-drop",
                "spring.flyway.enabled=false",
                "spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect"
        })
@Transactional
class LowerByteaNullBindRegressionIT {

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
    @Autowired private BankRepository bankRepository;
    @Autowired private BranchRepository branchRepository;
    @Autowired private CurrencyRepository currencyRepository;
    @Autowired private CustomerRepository customerRepository;
    @Autowired private EmployeeRepository employeeRepository;
    @Autowired private SanctionEntryRepository sanctionEntryRepository;
    @Autowired private TeaorCodeRepository teaorCodeRepository;
    @Autowired private WorkerRepository workerRepository;
    @Autowired private WuPartnerCompanyRepository wuPartnerCompanyRepository;

    // --- null-bind probak: nem kell seed, a bind-tipushiba PREPARE-kor dobodna ---

    @Test
    @DisplayName("LOWER-BYTEA: BankRepository.searchByName null-bind nem dob")
    void bankSearchByNameNullBind() {
        assertThatCode(() -> bankRepository.searchByName(UUID.randomUUID(), null))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("LOWER-BYTEA: BranchRepository mindket kereso null-bind nem dob")
    void branchSearchNullBind() {
        assertThatCode(() -> branchRepository.searchByNameOrCode(null))
                .doesNotThrowAnyException();
        assertThatCode(() -> branchRepository.searchByCompanyIdAndNameOrCode(UUID.randomUUID(), null))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("LOWER-BYTEA: CurrencyRepository.searchByCodeOrName null-bind nem dob")
    void currencySearchNullBind() {
        assertThatCode(() -> currencyRepository.searchByCodeOrName(null))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("LOWER-BYTEA: CustomerRepository mindket kereso null-bind nem dob")
    void customerSearchNullBind() {
        assertThatCode(() -> customerRepository.searchByName(UUID.randomUUID(), null))
                .doesNotThrowAnyException();
        assertThatCode(() -> customerRepository.searchByNameOrDocument(UUID.randomUUID(), null))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("LOWER-BYTEA: EmployeeRepository.searchByName null-bind nem dob")
    void employeeSearchNullBind() {
        assertThatCode(() -> employeeRepository.searchByName(UUID.randomUUID(), null))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("LOWER-BYTEA: SanctionEntryRepository.searchByNameOrAlias null-bind nem dob")
    void sanctionSearchNullBind() {
        assertThatCode(() -> sanctionEntryRepository.searchByNameOrAlias(null))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("LOWER-BYTEA: TeaorCodeRepository.search null-bind nem dob (prefix+contains ag)")
    void teaorSearchNullBind() {
        assertThatCode(() -> teaorCodeRepository.search(null, Limit.of(20)))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("LOWER-BYTEA: WorkerRepository.searchByName null-bind nem dob")
    void workerSearchNullBind() {
        assertThatCode(() -> workerRepository.searchByName(UUID.randomUUID(), null))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("LOWER-BYTEA: WuPartnerCompanyRepository.searchByName null-bind nem dob")
    void wuPartnerSearchNullBind() {
        assertThatCode(() -> wuPartnerCompanyRepository.searchByName(UUID.randomUUID(), null))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("LOWER-BYTEA: Bank nem-null kereses valtozatlan + tenant-szurt")
    void bankSearchNonNullBehaviorUnchanged() {
        Company own = seedCompany("A");
        Company foreign = seedCompany("B");
        bankRepository.save(Bank.builder().company(own).name("OTP Bank").createdAt(LocalDateTime.now()).build());
        bankRepository.save(Bank.builder().company(own).name("KH Bank").createdAt(LocalDateTime.now()).build());
        bankRepository.save(Bank.builder().company(foreign).name("OTP Bank").createdAt(LocalDateTime.now()).build());
        bankRepository.flush();

        assertThat(bankRepository.searchByName(own.getId(), "otp"))
                .extracting(Bank::getName)
                .containsExactly("OTP Bank");
    }

    @Test
    @DisplayName("LOWER-BYTEA: Teaor prefix- es contains-ag valtozatlan, kod szerint rendezve")
    void teaorSearchNonNullBehaviorUnchanged() {
        teaorCodeRepository.save(TeaorCode.builder().code("6612").name("Ertekpapir ugynoki tevekenyseg").build());
        teaorCodeRepository.save(TeaorCode.builder().code("6619").name("Egyeb penzugyi kiegeszito tevekenyseg").build());
        teaorCodeRepository.flush();

        // kod-PREFIX ag
        assertThat(teaorCodeRepository.search("66", Limit.of(20)))
                .extracting(TeaorCode::getCode)
                .containsExactly("6612", "6619");
        // nev-CONTAINS ag (case-insensitive)
        assertThat(teaorCodeRepository.search("UGYNOKI", Limit.of(20)))
                .extracting(TeaorCode::getCode)
                .containsExactly("6612");
    }

    @Test
    @DisplayName("LOWER-BYTEA: Customer 4-mezos OR kereses valtozatlan + tenant-szurt")
    void customerSearchNonNullBehaviorUnchanged() {
        Company own = seedCompany("C");
        Company foreign = seedCompany("D");
        customerRepository.save(Customer.builder().company(own).name("Kovacs Bela")
                .documentNumber("AB123456").createdAt(LocalDateTime.now()).build());
        customerRepository.save(Customer.builder().company(foreign).name("Kovacs Bela")
                .documentNumber("AB123456").createdAt(LocalDateTime.now()).build());
        customerRepository.flush();

        assertThat(customerRepository.searchByNameOrDocument(own.getId(), "ab1234"))
                .hasSize(1)
                .allSatisfy(c -> assertThat(c.getName()).isEqualTo("Kovacs Bela"));
        assertThat(customerRepository.searchByName(own.getId(), "kovacs")).hasSize(1);
    }

    private Company seedCompany(String prefix) {
        String suffix = prefix + UUID.randomUUID().toString().substring(0, 8);
        return companyRepository.save(Company.builder()
                .code("LB" + suffix)
                .name("LowerBytea Co " + suffix)
                .createdAt(LocalDateTime.now())
                .build());
    }
}
