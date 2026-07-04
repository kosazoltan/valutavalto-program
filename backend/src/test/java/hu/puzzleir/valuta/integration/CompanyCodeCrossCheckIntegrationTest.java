package hu.puzzleir.valuta.integration;

import tools.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.config.ProductionCorsFilter;
import hu.puzzleir.valuta.config.SecurityConfig;
import hu.puzzleir.valuta.controller.TransactionController;
import hu.puzzleir.valuta.dto.transaction.BuyRequestDto;
import hu.puzzleir.valuta.dto.transaction.TransactionDto;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.mapper.TransactionMapper;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.security.CompanyCodeCrossCheckFilter;
import hu.puzzleir.valuta.security.IdempotencyFilter;
import hu.puzzleir.valuta.security.JwtAuthenticationFilter;
import hu.puzzleir.valuta.security.JwtTokenProvider;
import hu.puzzleir.valuta.service.TokenBlacklistService;
import hu.puzzleir.valuta.service.TransactionService;
import hu.puzzleir.valuta.util.IdempotencyGuard;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringBootConfiguration;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(
        classes = CompanyCodeCrossCheckIntegrationTest.TestApp.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "jwt.secret=test-secret-key-for-testing-only-32chars!!",
                "cors.allowed-origins=http://localhost:3000",
                "spring.datasource.url=jdbc:h2:mem:company-cross-check;DB_CLOSE_DELAY=-1;MODE=PostgreSQL",
                "spring.datasource.driver-class-name=org.h2.Driver",
                "spring.datasource.username=sa",
                "spring.datasource.password=",
                "spring.flyway.enabled=false",
                "spring.jpa.hibernate.ddl-auto=none"
        })
class CompanyCodeCrossCheckIntegrationTest {

    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID BRANCH_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");

    private MockMvc mockMvc;

    @Autowired
    private WebApplicationContext context;

    @Autowired
    private JwtTokenProvider jwtTokenProvider;

    @Autowired
    private TokenBlacklistService tokenBlacklistService;

    @Autowired
    private CompanyRepository companyRepository;

    @Autowired
    private TransactionService transactionService;

    @Autowired
    private TransactionMapper transactionMapper;

    @Autowired
    private IdempotencyGuard idempotencyGuard;

    private AtomicInteger transactionCount;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.webAppContextSetup(context)
                .apply(springSecurity())
                .build();
        reset(jwtTokenProvider, tokenBlacklistService, companyRepository, transactionService, transactionMapper, idempotencyGuard);
        transactionCount = new AtomicInteger(0);

        when(jwtTokenProvider.validateToken("valid-token")).thenReturn(true);
        when(jwtTokenProvider.getTokenIdFromToken("valid-token")).thenReturn("token-id-1");
        when(jwtTokenProvider.getWorkerIdFromToken("valid-token")).thenReturn(42L);
        when(jwtTokenProvider.getWorkerCodeFromToken("valid-token")).thenReturn("P001");
        when(jwtTokenProvider.getRoleFromToken("valid-token")).thenReturn("CASHIER");
        when(jwtTokenProvider.getCompanyIdFromToken("valid-token")).thenReturn(COMPANY_ID);
        when(jwtTokenProvider.getBranchIdFromToken("valid-token")).thenReturn(BRANCH_ID);
        when(jwtTokenProvider.getActiveRoleFromToken("valid-token")).thenReturn(null);
        when(jwtTokenProvider.getPermissionsFromToken("valid-token")).thenReturn(List.of());
        when(tokenBlacklistService.isBlacklisted("token-id-1")).thenReturn(false);
        when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company("BEST")));

        when(idempotencyGuard.tryAcquire(anyString(), anyString(), any(), eq(TransactionDto.class)))
                .thenReturn(new IdempotencyGuard.Acquired<>(null, null, TransactionDto.class));
        when(transactionMapper.toBuyRequest(any(BuyRequestDto.class)))
                .thenReturn(TransactionService.BuyRequest.builder()
                        .currencyCode("EUR")
                        .currencyAmount(new BigDecimal("100"))
                        .build());
        when(transactionService.executeBuy(any(TransactionService.BuyRequest.class))).thenAnswer(invocation -> {
            Transaction transaction = new Transaction();
            transaction.setId((long) transactionCount.incrementAndGet());
            return transaction;
        });
        when(transactionMapper.toDto(any(Transaction.class))).thenAnswer(invocation -> {
            Transaction transaction = invocation.getArgument(0);
            return TransactionDto.builder().id(transaction.getId()).build();
        });
    }

    @Test
    @DisplayName("buy with matching X-Company-Code reaches controller and returns 201")
    void buy_match_returnsCreated() throws Exception {
        mockMvc.perform(post("/api/v1/transactions/buy")
                        .header("Authorization", "Bearer valid-token")
                        .header("Idempotency-Key", "idem-match")
                        .header(CompanyCodeCrossCheckFilter.COMPANY_CODE_HEADER, " best ")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(buyBody()))
                .andExpect(status().isCreated());
    }

    @Test
    @DisplayName("buy with mismatched X-Company-Code returns 409 before booking")
    void buy_mismatch_returnsConflict_andTransactionCountDoesNotIncrease() throws Exception {
        int before = transactionCount.get();

        mockMvc.perform(post("/api/v1/transactions/buy")
                        .header("Authorization", "Bearer valid-token")
                        .header("Idempotency-Key", "idem-mismatch")
                        .header(CompanyCodeCrossCheckFilter.COMPANY_CODE_HEADER, "MASIKCEG")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(buyBody()))
                .andExpect(status().isConflict())
                .andExpect(content().string(org.hamcrest.Matchers.containsString("Cégeltérés")));

        org.assertj.core.api.Assertions.assertThat(transactionCount.get()).isEqualTo(before);
    }

    @Test
    @DisplayName("buy without X-Company-Code remains backward-compatible and returns 201")
    void buy_withoutHeader_returnsCreated() throws Exception {
        mockMvc.perform(post("/api/v1/transactions/buy")
                        .header("Authorization", "Bearer valid-token")
                        .header("Idempotency-Key", "idem-legacy")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(buyBody()))
                .andExpect(status().isCreated());
    }

    private String buyBody() {
        return "{\"currencyCode\":\"EUR\",\"currencyAmount\":100}";
    }

    private Company company(String code) {
        Company company = new Company();
        company.setId(COMPANY_ID);
        company.setCode(code);
        company.setName("Test Company");
        return company;
    }

    @SpringBootConfiguration
    @EnableAutoConfiguration
    @Import({
            SecurityConfig.class,
            ProductionCorsFilter.class,
            JwtAuthenticationFilter.class,
            IdempotencyFilter.class,
            CompanyCodeCrossCheckFilter.class,
            TransactionController.class
    })
    static class TestApp {
        @Bean
        JwtTokenProvider jwtTokenProvider() {
            return mock(JwtTokenProvider.class);
        }

        @Bean
        TokenBlacklistService tokenBlacklistService() {
            return mock(TokenBlacklistService.class);
        }

        @Bean
        CompanyRepository companyRepository() {
            return mock(CompanyRepository.class);
        }

        @Bean
        TransactionService transactionService() {
            return mock(TransactionService.class);
        }

        @Bean
        TransactionMapper transactionMapper() {
            return mock(TransactionMapper.class);
        }

        @Bean
        IdempotencyGuard idempotencyGuard() {
            return mock(IdempotencyGuard.class);
        }

        @Bean
        ObjectMapper objectMapper() {
            return new ObjectMapper();
        }
    }
}
