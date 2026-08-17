package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.ClosingControl;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.ClosingControlRepository;
import hu.puzzleir.valuta.repository.DailyReportRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.CentralReceivedDataService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.test.context.TestSecurityContextHolder;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.test.context.web.WebAppConfiguration;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * FK-087 FR-1 HTTP-szintű elfogadási teszt (rev 2 R6): valós HTTP-hívással bizonyítja,
 * hogy a <code>/api/v1/central/received-data/status</code> zárás-riasztása CSAK a
 * <code>dailyClosingDone</code> jelzőtől függ.
 *
 * <p>Rig: a {@link CentralReceivedDataControllerSecurityTest} váza, de a TestConfig a
 * VALÓS {@link CentralReceivedDataService}-t drótozza Mockito-mockolt repository-k mögé
 * (a controller mögötti valós service regresszió-őre is egyben).</p>
 *
 * <p>Multi-tenant megjegyzés: a service {@code SecurityUtils.getCurrentCompanyId()} hívása
 * {@link WorkerAuthenticationDetails}-t vár az Authentication details-ben. A
 * {@code @WithMockUser} önmagában nem tölti ezt, ezért a test a MockMvc-filter lánc után
 * (a dispatch-feltételek már teljesültek) kiegészíti a details-t a test thread
 * SecurityContext-jén — ez nem gyengít semmilyen authorization-feltételt.</p>
 */
@ExtendWith(SpringExtension.class)
@WebAppConfiguration
@ContextConfiguration(classes = CentralReceivedDataClosingAlertHttpTest.TestConfig.class)
class CentralReceivedDataClosingAlertHttpTest {

    @Autowired
    private WebApplicationContext context;

    @Autowired
    private BranchRepository branchRepository;

    @Autowired
    private DailyReportRepository dailyReportRepository;

    @Autowired
    private ClosingControlRepository closingControlRepository;

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
        BranchRepository branchRepository() {
            return mock(BranchRepository.class);
        }

        @Bean
        DailyReportRepository dailyReportRepository() {
            return mock(DailyReportRepository.class);
        }

        @Bean
        ClosingControlRepository closingControlRepository() {
            return mock(ClosingControlRepository.class);
        }

        @Bean
        CentralReceivedDataService centralReceivedDataService(BranchRepository branchRepository,
                                                              DailyReportRepository dailyReportRepository,
                                                              ClosingControlRepository closingControlRepository) {
            return new CentralReceivedDataService(branchRepository, dailyReportRepository, closingControlRepository);
        }

        @Bean
        CentralReceivedDataController centralReceivedDataController(CentralReceivedDataService svc) {
            return new CentralReceivedDataController(svc);
        }

        @Bean
        SecurityFilterChain testSecurityFilterChain(HttpSecurity http) throws Exception {
            http.authorizeHttpRequests(authz -> authz.anyRequest().authenticated());
            return http.build();
        }
    }

    @Test
    @WithMockUser(username = "fo1", roles = {"FOERTEKTAR"})
    @DisplayName("FR-1: napi zárás kész, evening/nav nincs (értéktári fiók) → criticalClosings=0, szint NONE")
    void dailyDoneOnly_isNotCriticalClosing_http() throws Exception {
        LocalDate pastDate = LocalDate.now().minusDays(1);
        UUID companyId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();

        // A @WithMockUser auth details-ét kiegészítjük tenant-kontextussal, ahogy a
        // production JwtAuthenticationFilter is teszi (SecurityUtils.getCurrentCompanyId()).
        AbstractAuthenticationToken authentication =
                (AbstractAuthenticationToken) TestSecurityContextHolder.getContext().getAuthentication();
        authentication.setDetails(new WorkerAuthenticationDetails(1L, companyId, branchId, "FOERTEKTAR"));

        Branch vaultBranch = Branch.builder()
                .id(branchId)
                .code("VT01")
                .name("Értéktár 01")
                .city("Budapest")
                .company(Company.builder().id(companyId).name("Best Change").build())
                .isActive(true)
                .build();
        ClosingControl control = ClosingControl.builder()
                .companyId(companyId)
                .branchId(branchId)
                .controlDate(pastDate)
                .dailyClosingDone(true)
                .eveningClosingDone(false)
                .navClosingDone(false)
                .alertLevel(null)
                .build();

        when(branchRepository.findByCompanyIdAndIsActiveTrue(companyId)).thenReturn(List.of(vaultBranch));
        when(dailyReportRepository.findByCompanyIdAndReportDate(companyId, pastDate)).thenReturn(List.of());
        when(closingControlRepository.findByCompanyIdAndControlDate(companyId, pastDate)).thenReturn(List.of(control));

        mockMvc.perform(get("/api/v1/central/received-data/status")
                        .param("date", pastDate.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.criticalClosings").value(0))
                .andExpect(jsonPath("$.rows[0].closingAlertLevel").value("NONE"));
    }
}
