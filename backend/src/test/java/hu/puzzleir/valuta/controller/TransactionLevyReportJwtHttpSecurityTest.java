package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.exception.GlobalExceptionHandler;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.DictionaryRepository;
import hu.puzzleir.valuta.repository.TransactionLevyRateHistoryRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.JwtAuthenticationFilter;
import hu.puzzleir.valuta.security.JwtTokenProvider;
import hu.puzzleir.valuta.service.AuditLogService;
import hu.puzzleir.valuta.service.TokenBlacklistService;
import hu.puzzleir.valuta.service.TransactionLevyReportService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.test.context.web.WebAppConfiguration;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * FK-100 FR-7 — HTTP-szintű JWT-biztonsági tesztek a
 * <code>GET /api/v1/reports/transaction-levy</code> végpontra.
 *
 * <p>A {@link TransactionLevyControllerSecurityTest} method-szintű (közvetlen
 * controller-hívás, mockolt service); ez a teszt a production JWT-láncot (valós
 * {@link JwtTokenProvider} + valós {@link JwtAuthenticationFilter}) ÉS a VALÓS
 * {@link TransactionLevyReportService} szerep-ágát gyakoroltatja hiteles
 * HTTP-kéréssel — csak a repository/audit I/O mockolt (a role-deny útvonal
 * production kód).</p>
 *
 * <ul>
 *   <li>H1: PENZTAR-alakú JWT (WorkerRole.CASHIER, activeRole nélkül) →
 *       {@code @PreAuthorize("isAuthenticated()")} átenged, a service
 *       {@code assertAuthorized()} megtagad → HTTP 403 + pontosan EGY
 *       ACCESS_DENIED / TRANSACTION_LEVY_REPORT audit-sor VV-AUTH-006-tal.</li>
 *   <li>H2: CHIEF_VAULT activeRole (→ ROLE_FOERTEKTAR) → HTTP 200, üres sorok
 *       (a jó útvonal eljut a valós service-ig és visszatér).</li>
 *   <li>H3: token nélkül → HTTP 403, audit-írás NÉLKÜL (filter-szintű
 *       megtagadás nem ír auditot).</li>
 * </ul>
 *
 * <p>Minta: {@link CashRegisterControllerJwtHttpSecurityTest} (strukturális
 * másolat). Kiegészítések (FK-100 orchestrator-addendum): a
 * {@link GlobalExceptionHandler} TestConfig-beanként regisztrálva, hogy az
 * {@code AccessDeniedException} HTTP 403-ra képződjön (a production handler
 * {@code @RestControllerAdvice} — egy minimális {@code @ContextConfiguration}
 * NEM fedezi fel automatikusan; nélküle H1 500-at adna). Az
 * {@code @EnableTransactionManagement} SZÁNDÉKOSAN hiányzik: nincs
 * PlatformTransactionManager ebben a tesztben, a service tranzakció-kezelés
 * nélkül fut — a role-deny útvonalat ez nem érinti (az audit
 * {@code logInNewTransaction} mock).</p>
 */
@ExtendWith(SpringExtension.class)
@WebAppConfiguration
@ContextConfiguration(classes = TransactionLevyReportJwtHttpSecurityTest.TestConfig.class)
@TestPropertySource(properties = {
        "jwt.secret=valutavalto-test-only-secret-key-32bytes",
        "jwt.expiration=60000"})
class TransactionLevyReportJwtHttpSecurityTest {

    private static final String TEST_SECRET = "valutavalto-test-only-secret-key-32bytes";

    @Autowired
    private WebApplicationContext context;

    @Autowired
    private JwtTokenProvider jwtTokenProvider;

    @Autowired
    private AuditLogService auditLogService;

    private MockMvc mockMvc;

    @BeforeEach
    void setup() {
        // A Spring-kontextus cache-elt — a mock audit-bean szivárogna az esetek között.
        reset(auditLogService);
        mockMvc = MockMvcBuilders.webAppContextSetup(context)
                .apply(springSecurity())
                .build();
    }

    @Configuration
    @EnableWebMvc
    @EnableWebSecurity
    @EnableMethodSecurity
    static class TestConfig {

        @Bean
        TransactionRepository transactionRepository() {
            return mock(TransactionRepository.class);
        }

        @Bean
        TransactionLevyRateHistoryRepository transactionLevyRateHistoryRepository() {
            return mock(TransactionLevyRateHistoryRepository.class);
        }

        @Bean
        BranchRepository branchRepository() {
            return mock(BranchRepository.class);
        }

        @Bean
        DictionaryRepository dictionaryRepository() {
            return mock(DictionaryRepository.class);
        }

        @Bean
        AuditLogService auditLogService() {
            return mock(AuditLogService.class);
        }

        @Bean
        TransactionLevyReportService transactionLevyReportService(
                TransactionRepository transactionRepository,
                TransactionLevyRateHistoryRepository rateHistoryRepository,
                BranchRepository branchRepository,
                AuditLogService auditLogService,
                DictionaryRepository dictionaryRepository) {
            // VALÓS service mockolt I/O-val — a role-deny útvonal production kód.
            // Lombok @RequiredArgsConstructor ctor-sorrend = meződeklarációs sorrend.
            return new TransactionLevyReportService(transactionRepository, rateHistoryRepository,
                    branchRepository, auditLogService, dictionaryRepository);
        }

        @Bean
        TransactionLevyReportController transactionLevyReportController(
                TransactionLevyReportService reportService) {
            return new TransactionLevyReportController(reportService);
        }

        @Bean
        GlobalExceptionHandler globalExceptionHandler() {
            // NEM @RestControllerAdvice-felfedezés: a minimális @ContextConfiguration
            // nem komponens-szkennel — bean-regisztrációval kötjük be, hogy az
            // AccessDeniedException → 403 leképzés érvényesüljön (H1).
            return new GlobalExceptionHandler();
        }

        @Bean
        JwtTokenProvider jwtTokenProvider() {
            // CashRegisterControllerJwtHttpSecurityTest mintája: mocked Environment +
            // ReflectionTestUtils MINDKÉT mezőre (secretKey, expiration) + validateSecret().
            Environment environment = mock(Environment.class);
            when(environment.getActiveProfiles()).thenReturn(new String[0]);
            JwtTokenProvider provider = new JwtTokenProvider(environment);
            ReflectionTestUtils.setField(provider, "secretKey", TEST_SECRET);
            ReflectionTestUtils.setField(provider, "expiration", 60_000L);
            provider.validateSecret();
            return provider;
        }

        @Bean
        TokenBlacklistService tokenBlacklistService() {
            // Mockito default: isBlacklisted(...) → false.
            return mock(TokenBlacklistService.class);
        }

        @Bean
        JwtAuthenticationFilter jwtAuthenticationFilter(JwtTokenProvider provider,
                                                        TokenBlacklistService tokenBlacklistService) {
            return new JwtAuthenticationFilter(provider, tokenBlacklistService);
        }

        @Bean
        SecurityFilterChain securityFilterChain(HttpSecurity http,
                                                JwtAuthenticationFilter jwtFilter) throws Exception {
            // GET CSRF-exempt — CSRF-et NEM disable-elünk; token nélküli kérésnél a
            // default 403 entry point viselkedést ellenőrizzük (stateless).
            http.authorizeHttpRequests(authz -> authz.anyRequest().authenticated())
                    .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);
            return http.build();
        }
    }

    @Test
    @DisplayName("H1/FR-7: PENZTAR-alakú JWT (CASHIER, activeRole nélkül) → 403 + pontosan egy "
            + "ACCESS_DENIED/TRANSACTION_LEVY_REPORT audit VV-AUTH-006-tal")
    void cashierShapedJwt403WithExactlyOneAuditRow() throws Exception {
        String token = jwtTokenProvider.generateToken(cashierWorker(), null, List.of());

        mockMvc.perform(get("/api/v1/reports/transaction-levy")
                        .param("from", "2026-08-01")
                        .param("to", "2026-08-31")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isForbidden());

        ArgumentCaptor<String> changes = ArgumentCaptor.forClass(String.class);
        verify(auditLogService, times(1)).logInNewTransaction(
                eq("ACCESS_DENIED"), eq("TRANSACTION_LEVY_REPORT"), any(),
                any(), any(), any(), any(), changes.capture());
        assertThat(changes.getValue()).contains("VV-AUTH-006");
    }

    @Test
    @DisplayName("H2/FR-7 jó fele: CHIEF_VAULT activeRole (→ ROLE_FOERTEKTAR) → 200, üres sorok")
    void chiefVaultJwt200GoodPath() throws Exception {
        String token = jwtTokenProvider.generateToken(cashierWorker(), "CHIEF_VAULT", List.of());

        mockMvc.perform(get("/api/v1/reports/transaction-levy")
                        .param("from", "2026-08-01")
                        .param("to", "2026-08-31")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.rows").isEmpty());

        verify(auditLogService, never()).logInNewTransaction(
                eq("ACCESS_DENIED"), eq("TRANSACTION_LEVY_REPORT"), any(),
                any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("H3/FR-7: Authorization header nélkül → 403, audit-írás nélkül (filter-szintű deny)")
    void noToken403WithoutAudit() throws Exception {
        mockMvc.perform(get("/api/v1/reports/transaction-levy")
                        .param("from", "2026-08-01")
                        .param("to", "2026-08-31"))
                .andExpect(status().isForbidden());

        verify(auditLogService, never()).logInNewTransaction(
                any(), any(), any(), any(), any(), any(), any(), any());
    }

    /**
     * CashRegisterControllerJwtHttpSecurityTest.cashierWorker() mintája: a
     * PENZTAR-alakú JWT-hez WorkerRole.CASHIER legacy szerep kell — activeRole
     * nélkül a filter CSAK ROLE_CASHIER authority-t ad, ami a service
     * ALLOWED_ROLES listáján nincs rajta (a @PreAuthorize isAuthenticated()
     * viszont átengedi — pontosan a production alak).
     */
    private static Worker cashierWorker() {
        Company company = new Company();
        company.setId(UUID.randomUUID());
        company.setCode("EBC");
        company.setName("Exclusive Best Change");

        Branch branch = new Branch();
        branch.setId(UUID.randomUUID());
        branch.setCode("B001");
        branch.setCompany(company);
        branch.setName("Teszt fiók");

        Worker worker = new Worker();
        worker.setId(42L);
        worker.setCode("W001");
        worker.setName("Teszt Elek");
        worker.setRole(WorkerRole.CASHIER);
        worker.setCompany(company);
        worker.setBranch(branch);
        worker.setActive(true);
        return worker;
    }
}
