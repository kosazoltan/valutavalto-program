package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.dto.ratecreation.BranchListDTO;
import hu.puzzleir.valuta.dto.ratecreation.WorkgroupDetailDTO;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.dto.ratecreation.RateOverviewDTO;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.entity.RateWorkgroup;
import hu.puzzleir.valuta.exception.ValidationException;
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
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
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

    // ===================== FK02-E: EUA (euró érme) az árfolyam-overview-ban =====================

    @Test
    @DisplayName("FK02-E (FR-3): getRateOverview beemeli az inaktiv EUA-t a rate-overview-ba")
    void getRateOverview_includesInactiveEua() {
        Currency eur = Currency.builder().id(1L).code("EUR").name("Euró").active(true).displayOrder(8).build();
        Currency usd = Currency.builder().id(2L).code("USD").name("US Dollár").active(true).displayOrder(21).build();
        Currency eua = Currency.builder().id(99L).code("EUA").name("Euró érme").active(false).displayOrder(17)
                .maxDeviationPercent(new BigDecimal("20.00")).build();
        // Az AKTÍV lista NEM tartalmazza az EUA-t (is_active=false) — pont ez a FR-3 gyökere.
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of(eur, usd));
        when(currencyRepository.findByCode("EUA")).thenReturn(Optional.of(eua));
        // Nincs árfolyam → fallback ág is üres (a sor hasRate=false- szal jön vissza).
        when(exchangeRateRepository.findActiveRatesByDate(any(), any())).thenReturn(List.<ExchangeRate>of());
        when(exchangeRateRepository.findLatestActiveRates(any())).thenReturn(List.<ExchangeRate>of());

        RateOverviewDTO overview = service.getRateOverview();

        assertThat(overview.getCurrencies()).extracting(RateOverviewDTO.CurrencyRateItem::getCurrencyCode)
                .as("az EUA-nak meg kell jelennie az árfolyam-overview-ban (FR-3)")
                .contains("EUA");
        RateOverviewDTO.CurrencyRateItem euaItem = overview.getCurrencies().stream()
                .filter(c -> "EUA".equals(c.getCurrencyCode())).findFirst().orElseThrow();
        assertThat(euaItem.isHasRate()).as("EUA-nak még nincs publikált árfolyama").isFalse();
    }

    @Test
    @DisplayName("FK02-E (FR-3): ha az EUA torzs hianyzik, az overview nem dob hibat (csak kihagyja)")
    void getRateOverview_eauMissing_noError() {
        Currency eur = Currency.builder().id(1L).code("EUR").name("Euró").active(true).displayOrder(8).build();
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of(eur));
        when(currencyRepository.findByCode("EUA")).thenReturn(Optional.empty());
        when(exchangeRateRepository.findActiveRatesByDate(any(), any())).thenReturn(List.<ExchangeRate>of());
        when(exchangeRateRepository.findLatestActiveRates(any())).thenReturn(List.<ExchangeRate>of());

        RateOverviewDTO overview = service.getRateOverview();

        assertThat(overview.getCurrencies()).extracting(RateOverviewDTO.CurrencyRateItem::getCurrencyCode)
                .containsExactly("EUR");
    }

    // ===================== FK02-C: Irodák listájának pénztár-szűrése =====================

    @Test
    @DisplayName("FK02-C: getAllBranchesForWorkgroup a penztar-only repo-lekerdezest hasznalja (nem a teljes aktiv listat)")
    void getAllBranchesForWorkgroup_usesCashierOnlyQuery() {
        UUID wgId = UUID.randomUUID();
        Company company = Company.builder().id(COMPANY_ID).code("EBC").name("Test").build();
        RateWorkgroup wg = RateWorkgroup.builder().id(wgId).company(company).branches(Set.of()).build();
        when(rateWorkgroupRepository.findById(wgId)).thenReturn(Optional.of(wg));

        Dictionary penztar = Dictionary.builder().code("PENZTAR").build();
        Branch cashier = Branch.builder().id(UUID.randomUUID()).code("BR020").name("Szeged Pénztár")
                .city("Szeged").company(company).branchType(penztar).isActive(true).build();
        when(branchRepository.findRateCreationAssignableCashierBranches(COMPANY_ID)).thenReturn(List.of(cashier));

        List<BranchListDTO> result = service.getAllBranchesForWorkgroup(wgId);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getCode()).isEqualTo("BR020");
        // FR-1/NFR-1: NEM a teljes aktív listát kérdezi le (az banki partnert is visszaadna).
        verify(branchRepository, never()).findByCompanyIdAndIsActiveTrue(any());
    }

    @Test
    @DisplayName("FK02-C: updateWorkgroupBranches elutasitja a nem-penztar (VAULT_COUNTERPARTY) iroda hozzarendeleset")
    void updateWorkgroupBranches_rejectsNonCashierBranch() {
        UUID wgId = UUID.randomUUID();
        Company company = Company.builder().id(COMPANY_ID).code("EBC").name("Test").build();
        RateWorkgroup wg = RateWorkgroup.builder().id(wgId).company(company).branches(new HashSet<>()).build();
        when(rateWorkgroupRepository.findById(wgId)).thenReturn(Optional.of(wg));

        Dictionary counterparty = Dictionary.builder().code("VAULT_COUNTERPARTY").build();
        UUID partnerId = UUID.randomUUID();
        Branch partner = Branch.builder().id(partnerId).code("MNB").name("MNB")
                .company(company).branchType(counterparty).isActive(true).build();
        when(branchRepository.findAllById(List.of(partnerId))).thenReturn(List.of(partner));

        assertThatThrownBy(() -> service.updateWorkgroupBranches(wgId, List.of(partnerId)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("csak pénztár");
    }

    @Test
    @DisplayName("FK02-C: updateWorkgroupBranches elutasitja az ERTEKTAR tipusu egyseget (Sourcery)")
    void updateWorkgroupBranches_rejectsVaultTypeBranch() {
        UUID wgId = UUID.randomUUID();
        Company company = Company.builder().id(COMPANY_ID).code("EBC").name("Test").build();
        RateWorkgroup wg = RateWorkgroup.builder().id(wgId).company(company).branches(new HashSet<>()).build();
        when(rateWorkgroupRepository.findById(wgId)).thenReturn(Optional.of(wg));

        Dictionary ertektar = Dictionary.builder().code("ERTEKTAR").build();
        UUID vaultId = UUID.randomUUID();
        Branch vault = Branch.builder().id(vaultId).code("ET01").name("Szeged Értéktár")
                .company(company).branchType(ertektar).isActive(true).build();
        when(branchRepository.findAllById(List.of(vaultId))).thenReturn(List.of(vault));

        assertThatThrownBy(() -> service.updateWorkgroupBranches(wgId, List.of(vaultId)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("csak pénztár");
    }

    @Test
    @DisplayName("FK02-C: updateWorkgroupBranches elutasitja az isVault=true penztarat is (Sourcery)")
    void updateWorkgroupBranches_rejectsVaultFlaggedCashier() {
        UUID wgId = UUID.randomUUID();
        Company company = Company.builder().id(COMPANY_ID).code("EBC").name("Test").build();
        RateWorkgroup wg = RateWorkgroup.builder().id(wgId).company(company).branches(new HashSet<>()).build();
        when(rateWorkgroupRepository.findById(wgId)).thenReturn(Optional.of(wg));

        // PENZTAR típuskód, de isVault=true → értéktári anomália, NEM rendelhető hozzá.
        Dictionary penztar = Dictionary.builder().code("PENZTAR").build();
        UUID id = UUID.randomUUID();
        Branch vaultFlagged = Branch.builder().id(id).code("BR099").name("Anomália")
                .company(company).branchType(penztar).isVault(true).isActive(true).build();
        when(branchRepository.findAllById(List.of(id))).thenReturn(List.of(vaultFlagged));

        assertThatThrownBy(() -> service.updateWorkgroupBranches(wgId, List.of(id)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("csak pénztár");
    }

    @Test
    @DisplayName("FK02-C: updateWorkgroupBranches elfogadja az aktiv penztarat")
    void updateWorkgroupBranches_acceptsCashierBranch() {
        UUID wgId = UUID.randomUUID();
        Company company = Company.builder().id(COMPANY_ID).code("EBC").name("Test").build();
        RateWorkgroup wg = RateWorkgroup.builder().id(wgId).company(company).branches(new HashSet<>()).build();
        when(rateWorkgroupRepository.findById(wgId)).thenReturn(Optional.of(wg));
        when(rateWorkgroupRepository.findByCompanyIdAndActiveTrue(COMPANY_ID)).thenReturn(List.of(wg));

        Dictionary penztar = Dictionary.builder().code("PENZTAR").build();
        UUID cashierId = UUID.randomUUID();
        Branch cashier = Branch.builder().id(cashierId).code("BR020").name("Szeged Pénztár")
                .company(company).branchType(penztar).isActive(true).build();
        when(branchRepository.findAllById(List.of(cashierId))).thenReturn(List.of(cashier));

        service.updateWorkgroupBranches(wgId, List.of(cashierId));

        assertThat(wg.getBranches()).extracting(Branch::getCode).containsExactly("BR020");
    }
}
