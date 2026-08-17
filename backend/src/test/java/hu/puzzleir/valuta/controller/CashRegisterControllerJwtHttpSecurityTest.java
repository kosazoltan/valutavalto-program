package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.security.JwtAuthenticationFilter;
import hu.puzzleir.valuta.security.JwtTokenProvider;
import hu.puzzleir.valuta.service.BranchService;
import hu.puzzleir.valuta.service.CashRegisterDeviceService;
import hu.puzzleir.valuta.service.CashRegisterService;
import hu.puzzleir.valuta.service.TokenBlacklistService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
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

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * FK-085 pótlás §2: HTTP-szintű JWT-biztonsági tesztek a
 * <code>GET /api/v1/cash-register/devices</code> végpontra. A meglévő
 * {@link CashRegisterControllerSecurityTest} method-szintű (közvetlen controller-hívás);
 * ez a teszt a production JWT-láncot (valós {@link JwtTokenProvider} + valós
 * {@link JwtAuthenticationFilter}) hiteles HTTP-kéréssel gyakoroltatja:
 * <ul>
 *   <li>activeRole "CHIEF_VAULT" → ROLE_FOERTEKTAR normalizáció → 200</li>
 *   <li>activeRole "DIRECTOR" → ROLE_UGYVEZETO normalizáció → 200</li>
 *   <li>legacy CASHIER (activeRole nélkül) → 403</li>
 *   <li>token nélkül → 403 (default entry point, stateless)</li>
 * </ul>
 *
 * <p>R4: a {@link JwtTokenProvider} Spring-beanként vesz részt, ezért a
 * <code>@Value("${jwt.secret}")</code> mező-injekció a kontextus-indításkor feloldandó —
 * a {@link TestPropertySource} tesz-only titkot ad (32+ byte, sosem valódi titok).
 * R10: a worker-fixture legacy szerepe WorkerRole.CASHIER (az ADMIN szerep a devices
 * allow-listáján van, ezért azzal a 403-as eset hamisan 200-zal menne át).</p>
 */
@ExtendWith(SpringExtension.class)
@WebAppConfiguration
@ContextConfiguration(classes = CashRegisterControllerJwtHttpSecurityTest.TestConfig.class)
@TestPropertySource(properties = {
        "jwt.secret=valutavalto-test-only-secret-key-32bytes",
        "jwt.expiration=60000"})
class CashRegisterControllerJwtHttpSecurityTest {

    private static final String TEST_SECRET = "valutavalto-test-only-secret-key-32bytes";

    @Autowired
    private WebApplicationContext context;

    @Autowired
    private JwtTokenProvider jwtTokenProvider;

    private MockMvc mockMvc;

    @BeforeEach
    void setup() {
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
        CashRegisterService cashRegisterService() {
            return mock(CashRegisterService.class);
        }

        @Bean
        CashRegisterDeviceService cashRegisterDeviceService() {
            CashRegisterDeviceService service = mock(CashRegisterDeviceService.class);
            when(service.listForCurrentCompany()).thenReturn(List.of());
            return service;
        }

        @Bean
        BranchService branchService() {
            return mock(BranchService.class);
        }

        @Bean
        CashRegisterController cashRegisterController(CashRegisterService cashRegisterService,
                                                      CashRegisterDeviceService cashRegisterDeviceService,
                                                      BranchService branchService) {
            // Lombok @RequiredArgsConstructor ctor-sorrend = meződeklarációs sorrend.
            return new CashRegisterController(cashRegisterService, cashRegisterDeviceService, branchService);
        }

        @Bean
        JwtTokenProvider jwtTokenProvider() {
            // JwtTokenProviderContractTest.provider() mintája: mocked Environment +
            // ReflectionTestUtils. A @Value-mezők emellett a @TestPropertySource-ból is
            // megérkeznek (R4) — a kettő azonos értéket ad.
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
            // NEM disable-elünk CSRF-et (GET-only teszt, a GET default CSRF-exempt), és
            // NEM adunk httpBasic-ot: token nélküli kérésnél a default 403 entry point
            // viselkedést ellenőrizzük (stateless).
            http.authorizeHttpRequests(authz -> authz.anyRequest().authenticated())
                    .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);
            return http.build();
        }
    }

    // ----- ALLOW: canonical szerepkörök activeRole-normalizáción keresztül -----

    @Test
    @DisplayName("CHIEF_VAULT activeRole → ROLE_FOERTEKTAR → devices 200")
    void foertektar_jwt_200() throws Exception {
        String token = jwtTokenProvider.generateToken(cashierWorker(), "CHIEF_VAULT", List.of());

        mockMvc.perform(get("/api/v1/cash-register/devices")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("DIRECTOR activeRole → ROLE_UGYVEZETO → devices 200")
    void ugyvezeto_jwt_200() throws Exception {
        String token = jwtTokenProvider.generateToken(cashierWorker(), "DIRECTOR", List.of());

        mockMvc.perform(get("/api/v1/cash-register/devices")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk());
    }

    // ----- DENY -----

    @Test
    @DisplayName("Legacy CASHIER token (activeRole nélkül) → devices 403")
    void cashier_jwt_403() throws Exception {
        String token = jwtTokenProvider.generateToken(cashierWorker(), null, List.of());

        mockMvc.perform(get("/api/v1/cash-register/devices")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Authorization header nélkül → 403 (default entry point, stateless)")
    void noToken_403() throws Exception {
        mockMvc.perform(get("/api/v1/cash-register/devices"))
                .andExpect(status().isForbidden());
    }

    /**
     * JwtTokenProviderContractTest.worker() mintája plain setterekkel, DE WorkerRole.CASHIER
     * legacy szereppel (R10): a FOERTEKTAR/UGYVEZETO esetek az activeRole-normalizáción
     * keresztül kapnak hozzáférést — pontosan a production canonical-only worker alakja.
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
