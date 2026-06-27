package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.dto.ratecreation.BranchListDTO;
import hu.puzzleir.valuta.dto.ratecreation.TerritoryWorkgroupRateDTO;
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
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalTime;
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
    @Mock private AccessScopeService accessScopeService;

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

    // ===================== FK-041: területi (régió) munkacsoport-árfolyam variánsok =====================

    private static ExchangeRate eurRate(Currency eur) {
        return ExchangeRate.builder()
                .currency(eur)
                .baseBuyRate(new BigDecimal("343.00"))
                .baseSellRate(new BigDecimal("362.99"))
                .officialRate(new BigDecimal("352.68"))
                .limit1Amount(new BigDecimal("50000"))
                .limit1BuyRate(new BigDecimal("343.50"))
                .limit1SellRate(new BigDecimal("362.49"))
                .validTime(LocalTime.of(15, 12))
                .build();
    }

    @Test
    @DisplayName("FK-041: national scope (scope==null) — minden munkacsoport, pénztárnevek név-szerint rendezve + ráta")
    void getTerritoryWorkgroupRates_nationalScope_allWorkgroups() {
        Company company = Company.builder().id(COMPANY_ID).code("EBC").name("Test").build();
        Currency eur = Currency.builder().id(1L).code("EUR").name("Euró").active(true).displayOrder(8).build();
        Branch br1 = Branch.builder().id(UUID.randomUUID()).code("BR01").name("Árkád").build();
        Branch br2 = Branch.builder().id(UUID.randomUUID()).code("BR02").name("Tisza Sarok").build();
        RateWorkgroup wg = RateWorkgroup.builder()
                .id(UUID.randomUUID()).company(company).code("WG01").name("Belváros").active(true)
                .tileColor("blue")
                .limit1Boundary(new BigDecimal("50000"))
                .limit2Boundary(new BigDecimal("300000"))
                .limit3Boundary(new BigDecimal("1000000"))
                .branches(Set.of(br1, br2))
                .build();

        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);
        when(rateWorkgroupRepository.findByCompanyIdAndActiveTrue(COMPANY_ID)).thenReturn(List.of(wg));
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of(eur));
        when(exchangeRateRepository.findAllActiveRates(any(), any())).thenReturn(List.of(eurRate(eur)));

        List<TerritoryWorkgroupRateDTO> result = service.getTerritoryWorkgroupRates();

        assertThat(result).hasSize(1);
        TerritoryWorkgroupRateDTO g = result.get(0);
        assertThat(g.getWorkgroupName()).isEqualTo("Belváros");
        assertThat(g.getTileColor()).isEqualTo("blue");
        assertThat(g.getBranchNames())
                .as("a pénztárnevek név szerint rendezve jönnek a címsorba")
                .containsExactly("Árkád", "Tisza Sarok");
        assertThat(g.getCurrencies()).hasSize(1);
        TerritoryWorkgroupRateDTO.CurrencyRate cr = g.getCurrencies().get(0);
        assertThat(cr.getCurrencyCode()).isEqualTo("EUR");
        assertThat(cr.isHasRate()).isTrue();
        assertThat(cr.getBaseBuyRate()).isEqualByComparingTo("343.00");
        assertThat(cr.getBaseSellRate()).isEqualByComparingTo("362.99");
        assertThat(cr.getOfficialRate()).isEqualByComparingTo("352.68");
        assertThat(cr.getLimit1BuyRate()).isEqualByComparingTo("343.50");
        assertThat(cr.getValidTime()).isEqualTo("15:12");
    }

    @Test
    @DisplayName("FK-041: régió-scope (ERTEKTAR) — a régión kívüli pénztár nem kerül a címsorba")
    void getTerritoryWorkgroupRates_regionScope_filtersOutOfRegionBranches() {
        Company company = Company.builder().id(COMPANY_ID).code("EBC").name("Test").build();
        Currency eur = Currency.builder().id(1L).code("EUR").name("Euró").active(true).displayOrder(8).build();
        Branch inRegion = Branch.builder().id(UUID.randomUUID()).code("BR01").name("Tisza Sarok").build();
        Branch outRegion = Branch.builder().id(UUID.randomUUID()).code("BR99").name("Debrecen Fő").build();
        RateWorkgroup wg = RateWorkgroup.builder()
                .id(UUID.randomUUID()).company(company).code("WG01").name("Vegyes").active(true)
                .branches(Set.of(inRegion, outRegion))
                .build();

        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(Set.of(inRegion.getId()));
        when(rateWorkgroupRepository.findByCompanyIdAndActiveTrue(COMPANY_ID)).thenReturn(List.of(wg));
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of(eur));
        when(exchangeRateRepository.findAllActiveRates(any(), any())).thenReturn(List.of(eurRate(eur)));

        List<TerritoryWorkgroupRateDTO> result = service.getTerritoryWorkgroupRates();

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getBranchNames())
                .as("a régión kívüli pénztárat (más companyId-scope) ki kell szűrni")
                .containsExactly("Tisza Sarok");
    }

    @Test
    @DisplayName("FK-041: a hívó területén pénztár nélküli munkacsoport kimarad az eredményből")
    void getTerritoryWorkgroupRates_workgroupWithNoBranchInScope_excluded() {
        Company company = Company.builder().id(COMPANY_ID).code("EBC").name("Test").build();
        Currency eur = Currency.builder().id(1L).code("EUR").name("Euró").active(true).displayOrder(8).build();
        Branch otherRegion = Branch.builder().id(UUID.randomUUID()).code("BR99").name("Pécs").build();
        RateWorkgroup wg = RateWorkgroup.builder()
                .id(UUID.randomUUID()).company(company).code("WG09").name("Másik terület").active(true)
                .branches(Set.of(otherRegion))
                .build();

        // A scope egy MÁSIK pénztárat tartalmaz → a wg egyetlen pénztára sem látható.
        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(Set.of(UUID.randomUUID()));
        when(rateWorkgroupRepository.findByCompanyIdAndActiveTrue(COMPANY_ID)).thenReturn(List.of(wg));
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of(eur));

        List<TerritoryWorkgroupRateDTO> result = service.getTerritoryWorkgroupRates();

        assertThat(result).isEmpty();
    }

    @Test
    @DisplayName("FK-041: a service valutánként az ELSŐ rátát tartja (putIfAbsent first-wins a repo branch-first sorrendjére)")
    void getTerritoryWorkgroupRates_keepsFirstRatePerCurrency() {
        // A branch-specifikus precedencia a repo findAllActiveRates ORDER BY-jában él
        // (CASE WHEN er.branch.id = :branchId THEN 0 ELSE 1) — ezt a TÉNYLEGES sorrendet valós PG-n a
        // ExchangeRateRepositoryFindAllActiveRatesPostgresIT fedi. Ez a UNIT teszt a SERVICE szerződését
        // rögzíti: putIfAbsent-tel az ELSŐ (= repo szerint branch-specifikus) rekordot tartja, NEM put-tal
        // (last-wins) — egy putIfAbsent→put regressziót elkapna. A repo a mockolt, ezért a sorrendet itt
        // a mock szimulálja (branch-specifikus elöl, globális fallback hátul), nem ez a teszt bizonyítja.
        Company company = Company.builder().id(COMPANY_ID).code("EBC").name("Test").build();
        Currency eur = Currency.builder().id(1L).code("EUR").name("Euró").active(true).displayOrder(8).build();
        Branch br1 = Branch.builder().id(UUID.randomUUID()).code("BR01").name("Tisza Sarok").build();
        RateWorkgroup wg = RateWorkgroup.builder()
                .id(UUID.randomUUID()).company(company).code("WG01").name("Belváros").active(true)
                .branches(Set.of(br1))
                .build();

        ExchangeRate branchSpecific = eurRate(eur); // 343.00 — a repo branch-first sorrendjében elöl
        ExchangeRate global = ExchangeRate.builder()
                .currency(eur)
                .baseBuyRate(new BigDecimal("340.00"))
                .baseSellRate(new BigDecimal("366.00"))
                .officialRate(new BigDecimal("352.68"))
                .build();

        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);
        when(rateWorkgroupRepository.findByCompanyIdAndActiveTrue(COMPANY_ID)).thenReturn(List.of(wg));
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of(eur));
        when(exchangeRateRepository.findAllActiveRates(any(), any()))
                .thenReturn(List.of(branchSpecific, global)); // branch-specifikus elöl, globális fallback hátul

        List<TerritoryWorkgroupRateDTO> result = service.getTerritoryWorkgroupRates();

        assertThat(result.get(0).getCurrencies().get(0).getBaseBuyRate())
                .as("a service az első (repo szerint branch-specifikus) rátát tartja, nem a globálisat")
                .isEqualByComparingTo("343.00");
    }

    @Test
    @DisplayName("FK-041: publikált ráta nélküli aktív valuta -> hasRate=false, ráták null-ok")
    void getTerritoryWorkgroupRates_currencyWithoutRate_hasRateFalse() {
        Company company = Company.builder().id(COMPANY_ID).code("EBC").name("Test").build();
        Currency eur = Currency.builder().id(1L).code("EUR").name("Euró").active(true).displayOrder(8).build();
        Currency usd = Currency.builder().id(2L).code("USD").name("US dollár").active(true).displayOrder(21).build();
        Branch br1 = Branch.builder().id(UUID.randomUUID()).code("BR01").name("Tisza Sarok").build();
        RateWorkgroup wg = RateWorkgroup.builder()
                .id(UUID.randomUUID()).company(company).code("WG01").name("Belváros").active(true)
                .branches(Set.of(br1))
                .build();

        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);
        when(rateWorkgroupRepository.findByCompanyIdAndActiveTrue(COMPANY_ID)).thenReturn(List.of(wg));
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of(eur, usd));
        // Csak EUR-ra van publikált ráta; USD-re nincs (aktív valuta árfolyam nélkül).
        when(exchangeRateRepository.findAllActiveRates(any(), any())).thenReturn(List.of(eurRate(eur)));

        List<TerritoryWorkgroupRateDTO> result = service.getTerritoryWorkgroupRates();

        List<TerritoryWorkgroupRateDTO.CurrencyRate> rates = result.get(0).getCurrencies();
        TerritoryWorkgroupRateDTO.CurrencyRate eurRate = rates.stream()
                .filter(c -> "EUR".equals(c.getCurrencyCode())).findFirst().orElseThrow();
        TerritoryWorkgroupRateDTO.CurrencyRate usdRate = rates.stream()
                .filter(c -> "USD".equals(c.getCurrencyCode())).findFirst().orElseThrow();

        assertThat(eurRate.isHasRate()).isTrue();
        assertThat(eurRate.getBaseBuyRate()).isEqualByComparingTo("343.00");
        assertThat(usdRate.isHasRate())
                .as("az aktív valutának publikált ráta nélkül hasRate=false-szal kell jönnie (frontend em-dash)")
                .isFalse();
        assertThat(usdRate.getBaseBuyRate()).isNull();
        assertThat(usdRate.getBaseSellRate()).isNull();
    }

    @Test
    @DisplayName("FK-041: a HUF valutát kiszűri, és a companyId a hívó cégéé (multi-tenant, ArgumentCaptor)")
    void getTerritoryWorkgroupRates_filtersHufAndScopesByCompanyId() {
        Company company = Company.builder().id(COMPANY_ID).code("EBC").name("Test").build();
        Currency huf = Currency.builder().id(9L).code("HUF").name("Forint").active(true).displayOrder(1).build();
        Currency eur = Currency.builder().id(1L).code("EUR").name("Euró").active(true).displayOrder(8).build();
        Branch br1 = Branch.builder().id(UUID.randomUUID()).code("BR01").name("Tisza Sarok").build();
        RateWorkgroup wg = RateWorkgroup.builder()
                .id(UUID.randomUUID()).company(company).code("WG01").name("Belváros").active(true)
                .branches(Set.of(br1))
                .build();

        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);
        when(rateWorkgroupRepository.findByCompanyIdAndActiveTrue(COMPANY_ID)).thenReturn(List.of(wg));
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of(huf, eur));
        when(exchangeRateRepository.findAllActiveRates(any(), any())).thenReturn(List.of(eurRate(eur)));

        List<TerritoryWorkgroupRateDTO> result = service.getTerritoryWorkgroupRates();

        assertThat(result.get(0).getCurrencies())
                .extracting(TerritoryWorkgroupRateDTO.CurrencyRate::getCurrencyCode)
                .as("a HUF nem jelenhet meg a területi valuta-árfolyam nézetben")
                .containsExactly("EUR");

        // Multi-tenant: a companyId ténylegesen a hívó cégéé (nem any()) — workgroup ÉS ráta lekérdezésen is.
        ArgumentCaptor<UUID> wgCompany = ArgumentCaptor.forClass(UUID.class);
        verify(rateWorkgroupRepository).findByCompanyIdAndActiveTrue(wgCompany.capture());
        assertThat(wgCompany.getValue()).isEqualTo(COMPANY_ID);

        ArgumentCaptor<UUID> rateCompany = ArgumentCaptor.forClass(UUID.class);
        verify(exchangeRateRepository).findAllActiveRates(rateCompany.capture(), any());
        assertThat(rateCompany.getValue()).isEqualTo(COMPANY_ID);
    }
}
