package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.dto.ratecreation.WorkgroupDetailDTO;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.RateWorkgroup;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.util.List;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

/**
 * FK-02 / FK-04-E regressziós teszt (Codex P2 #916): a rate-maker csempés kezelő nézet a
 * {@code GET /rate-creation/workgroups} bootstrapból olvas. Ha a {@link WorkgroupDetailDTO}
 * NEM viszi a {@code tileColor}/{@code protectionEnabled} mezőt, a csempe-szín soha nem
 * jelenik meg, és az árfolyamvédelem-toggle reload után mindig true-ra esik vissza.
 * Ez a teszt rögzíti, hogy a mapping mindkét mezőt kitölti az entity-ből.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class RateCreationServiceTest {

    @InjectMocks
    private RateCreationService service;

    @Mock private BranchRepository branchRepository;
    @Mock private ExchangeRateRepository exchangeRateRepository;
    @Mock private CompetitorRateRepository competitorRateRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private CompanyRepository companyRepository;
    @Mock private RateTemplateRepository rateTemplateRepository;
    @Mock private RateWorkgroupRepository rateWorkgroupRepository;
    @Mock private RatePublicationRepository ratePublicationRepository;
    @Mock private RatePublishService ratePublishService;
    @Mock private ObjectMapper objectMapper;
    @Mock private SystemParameterService systemParameterService;

    private static final UUID COMPANY_ID = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        WorkerAuthenticationDetails details = new WorkerAuthenticationDetails(
                1L, COMPANY_ID, UUID.randomUUID(), "FOERTEKTAR");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("ft", "pw", "ROLE_FOERTEKTAR");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @Test
    @DisplayName("getWorkgroupDetails - a DTO viszi a tileColor + protectionEnabled mezot (Codex P2 #916)")
    void getWorkgroupDetails_exposesTileColorAndProtectionEnabled() {
        Company company = Company.builder().id(COMPANY_ID).code("EBC").name("Test").build();
        Branch branch = Branch.builder().id(UUID.randomUUID()).code("B01").name("Iroda 1").build();
        RateWorkgroup wg = RateWorkgroup.builder()
                .id(UUID.randomUUID())
                .company(company)
                .code("WG01")
                .name("Budapest")
                .legacyGroupNumber(1)
                .active(true)
                .tileColor("amber")
                .protectionEnabled(false)            // explicit KIKAPCSOLT — ennek vissza kell jönnie
                .limit1Boundary(new BigDecimal("50000"))
                .branches(Set.of(branch))
                .build();
        when(rateWorkgroupRepository.findByCompanyIdAndActiveTrue(COMPANY_ID)).thenReturn(List.of(wg));

        List<WorkgroupDetailDTO> result = service.getWorkgroupDetails();

        assertThat(result).hasSize(1);
        WorkgroupDetailDTO dto = result.get(0);
        assertThat(dto.getTileColor()).isEqualTo("amber");
        assertThat(dto.getProtectionEnabled())
                .as("a kikapcsolt vedelemnek false-kent kell visszajonnie (nem null/true fallback)")
                .isFalse();
    }

    @Test
    @DisplayName("getWorkgroupDetails - null tileColor / true protection valtozatlanul atjon")
    void getWorkgroupDetails_passesThroughDefaults() {
        Company company = Company.builder().id(COMPANY_ID).code("EBC").name("Test").build();
        RateWorkgroup wg = RateWorkgroup.builder()
                .id(UUID.randomUUID())
                .company(company)
                .code("WG02")
                .name("Pécs")
                .legacyGroupNumber(2)
                .active(true)
                .tileColor(null)
                .protectionEnabled(true)
                .branches(Set.of())
                .build();
        when(rateWorkgroupRepository.findByCompanyIdAndActiveTrue(COMPANY_ID)).thenReturn(List.of(wg));

        WorkgroupDetailDTO dto = service.getWorkgroupDetails().get(0);

        assertThat(dto.getTileColor()).isNull();
        assertThat(dto.getProtectionEnabled()).isTrue();
    }
}
