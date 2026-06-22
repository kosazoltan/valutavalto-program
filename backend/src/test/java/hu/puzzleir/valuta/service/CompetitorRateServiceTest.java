package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.competitor.CompetitorRateEntryDto;
import hu.puzzleir.valuta.dto.competitor.CompetitorTodayRateDto;
import hu.puzzleir.valuta.dto.competitor.CompetitorWatchBootstrapDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Competitor;
import hu.puzzleir.valuta.entity.CompetitorRate;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompetitorRateRepository;
import hu.puzzleir.valuta.repository.CompetitorRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
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
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FK-041/II — versenytárs-árfolyam bevitel (árfolyam néző) service tesztek: régió-scope, multi-tenant
 * (területen kívüli / más cég versenyhelye → 404), upsert, kosár-szűrés, vétel/eladás validáció.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class CompetitorRateServiceTest {

    @InjectMocks
    private CompetitorRateService service;

    @Mock private CompetitorRepository competitorRepository;
    @Mock private CompetitorRateRepository competitorRateRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private SystemParameterService systemParameterService;

    private static final Long WORKER_ID = 88L;
    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final UUID BRANCH2_ID = UUID.randomUUID();

    private Currency eur;
    private Currency usd;

    @BeforeEach
    void setUp() {
        WorkerAuthenticationDetails details =
                new WorkerAuthenticationDetails(WORKER_ID, COMPANY_ID, BRANCH_ID, "ARFOLYAM_NEZO");
        TestingAuthenticationToken auth =
                new TestingAuthenticationToken("nezo", "pw", "ROLE_ARFOLYAM_NEZO");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);

        eur = Currency.builder().id(1L).code("EUR").name("Euró").active(true).displayOrder(8).build();
        usd = Currency.builder().id(2L).code("USD").name("US dollár").active(true).displayOrder(21).build();
        Currency huf = Currency.builder().id(9L).code("HUF").name("Forint").active(true).displayOrder(1).build();

        // A hívó régiója = a saját irodája régiója (SZEGED), abban 2 pénztár.
        Branch own = Branch.builder().id(BRANCH_ID).name("Tisza Sarok").region("SZEGED").build();
        Branch other = Branch.builder().id(BRANCH2_ID).name("Árkád").region("SZEGED").build();
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(own));
        when(branchRepository.existsByIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(true);
        when(branchRepository.findActiveByCompanyIdAndRegion(COMPANY_ID, "SZEGED"))
                .thenReturn(List.of(own, other));

        // Figyelt valutakosár: EUR/USD/CHF/GBP; az aktívak közül EUR+USD szerepel (HUF kiesik).
        when(systemParameterService.getValue(CompetitorRateService.WATCH_CURRENCIES_PARAM,
                CompetitorRateService.DEFAULT_WATCH_CURRENCIES)).thenReturn("EUR,USD,CHF,GBP");
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc())
                .thenReturn(List.of(huf, eur, usd));
        when(currencyRepository.findById(1L)).thenReturn(Optional.of(eur));
        when(currencyRepository.findById(2L)).thenReturn(Optional.of(usd));
    }

    private Competitor competitorInRegion(UUID branchId) {
        return Competitor.builder()
                .id(UUID.randomUUID()).name("Rivál Change").branchId(branchId).isActive(true).build();
    }

    @Test
    @DisplayName("FK-041/II: bootstrap a régió versenyhelyeit + a figyelt valutakosarat (HUF nélkül) adja")
    void getBootstrap_returnsRegionCompetitorsAndWatchBasket() {
        Competitor c1 = competitorInRegion(BRANCH_ID);
        Competitor c2 = competitorInRegion(BRANCH2_ID);
        when(competitorRepository.findByBranchIdInAndIsActiveTrueOrderByNameAsc(any()))
                .thenReturn(List.of(c1, c2));

        CompetitorWatchBootstrapDto dto = service.getBootstrap();

        assertThat(dto.getCompetitors()).hasSize(2)
                .extracting(CompetitorWatchBootstrapDto.CompetitorOption::getBranchName)
                .containsExactlyInAnyOrder("Tisza Sarok", "Árkád");
        assertThat(dto.getCurrencies())
                .extracting(CompetitorWatchBootstrapDto.WatchCurrency::getCode)
                .as("a kosár ∩ aktív valuták (HUF nincs a kosárban, CHF/GBP nem aktív)")
                .containsExactly("EUR", "USD");
    }

    @Test
    @DisplayName("FK-041/II: submit egy ÚJ versenytárs-árfolyamot upsert-tel ment (source + worker + ma)")
    void submit_insertsNewRate() {
        Competitor competitor = competitorInRegion(BRANCH_ID);
        when(competitorRepository.findById(competitor.getId())).thenReturn(Optional.of(competitor));
        when(competitorRateRepository.findFirstByCompetitorIdAndCurrencyIdAndRateDateOrderByCreatedAtDesc(
                eq(competitor.getId()), eq(1L), any(LocalDate.class))).thenReturn(Optional.empty());

        CompetitorRateEntryDto dto = new CompetitorRateEntryDto(competitor.getId(), List.of(
                new CompetitorRateEntryDto.CurrencyRateLine(1L, new BigDecimal("390.00"), new BigDecimal("400.00"))));

        service.submit(dto);

        ArgumentCaptor<CompetitorRate> captor = ArgumentCaptor.forClass(CompetitorRate.class);
        verify(competitorRateRepository).save(captor.capture());
        CompetitorRate saved = captor.getValue();
        assertThat(saved.getCurrency().getCode()).isEqualTo("EUR");
        assertThat(saved.getBuyRate()).isEqualByComparingTo("390.00");
        assertThat(saved.getSellRate()).isEqualByComparingTo("400.00");
        assertThat(saved.getSource()).isEqualTo(CompetitorRateService.SOURCE);
        assertThat(saved.getCreatedBy()).isEqualTo(WORKER_ID);
        assertThat(saved.getRateDate()).isEqualTo(LocalDate.now());
    }

    @Test
    @DisplayName("FK-041/II: submit a MAI meglévő sort FRISSÍTI (upsert, nem új beszúrás)")
    void submit_updatesExistingRate() {
        Competitor competitor = competitorInRegion(BRANCH_ID);
        when(competitorRepository.findById(competitor.getId())).thenReturn(Optional.of(competitor));
        CompetitorRate existing = CompetitorRate.builder()
                .id(UUID.randomUUID()).competitor(competitor).currency(eur)
                .rateDate(LocalDate.now()).buyRate(new BigDecimal("388.00")).sellRate(new BigDecimal("402.00"))
                .createdBy(99L) // egy MÁSIK árfolyam néző hozta létre eredetileg
                .build();
        when(competitorRateRepository.findFirstByCompetitorIdAndCurrencyIdAndRateDateOrderByCreatedAtDesc(
                eq(competitor.getId()), eq(1L), any(LocalDate.class))).thenReturn(Optional.of(existing));

        service.submit(new CompetitorRateEntryDto(competitor.getId(), List.of(
                new CompetitorRateEntryDto.CurrencyRateLine(1L, new BigDecimal("391.00"), new BigDecimal("399.00")))));

        ArgumentCaptor<CompetitorRate> captor = ArgumentCaptor.forClass(CompetitorRate.class);
        verify(competitorRateRepository).save(captor.capture());
        CompetitorRate saved = captor.getValue();
        assertThat(saved.getId()).as("a meglévő sort frissíti (id megmarad)").isEqualTo(existing.getId());
        assertThat(saved.getBuyRate()).isEqualByComparingTo("391.00");
        assertThat(saved.getSellRate()).isEqualByComparingTo("399.00");
        assertThat(saved.getCreatedBy())
                .as("update-nél az EREDETI rögzítő createdBy-ja megmarad (nem a frissítő worker)")
                .isEqualTo(99L);
    }

    @Test
    @DisplayName("FK-041/II: a hívó TERÜLETÉN kívüli (vagy más cég) versenyhelye → 404 (multi-tenant)")
    void submit_competitorOutsideRegion_throwsNotFound() {
        // A versenyhely egy MÁSIK iroda mellett van, ami NINCS a hívó régiós scope-jában.
        Competitor foreign = competitorInRegion(UUID.randomUUID());
        when(competitorRepository.findById(foreign.getId())).thenReturn(Optional.of(foreign));

        CompetitorRateEntryDto dto = new CompetitorRateEntryDto(foreign.getId(), List.of(
                new CompetitorRateEntryDto.CurrencyRateLine(1L, new BigDecimal("390.00"), new BigDecimal("400.00"))));

        assertThatThrownBy(() -> service.submit(dto))
                .isInstanceOf(ResourceNotFoundException.class);
        verify(competitorRateRepository, never()).save(any());
    }

    @Test
    @DisplayName("FK-041/II: eladás <= vétel → ValidationException, nem ment")
    void submit_sellNotGreaterThanBuy_throwsValidation() {
        Competitor competitor = competitorInRegion(BRANCH_ID);
        when(competitorRepository.findById(competitor.getId())).thenReturn(Optional.of(competitor));

        CompetitorRateEntryDto dto = new CompetitorRateEntryDto(competitor.getId(), List.of(
                new CompetitorRateEntryDto.CurrencyRateLine(1L, new BigDecimal("400.00"), new BigDecimal("390.00"))));

        assertThatThrownBy(() -> service.submit(dto))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("eladási");
        verify(competitorRateRepository, never()).save(any());
    }

    @Test
    @DisplayName("FK-041/II: a figyelt kosáron kívüli valuta → ValidationException")
    void submit_currencyNotInBasket_throwsValidation() {
        Competitor competitor = competitorInRegion(BRANCH_ID);
        when(competitorRepository.findById(competitor.getId())).thenReturn(Optional.of(competitor));

        // 9L = HUF, ami nincs a figyelt kosárban (EUR/USD).
        CompetitorRateEntryDto dto = new CompetitorRateEntryDto(competitor.getId(), List.of(
                new CompetitorRateEntryDto.CurrencyRateLine(9L, new BigDecimal("1.00"), new BigDecimal("1.10"))));

        assertThatThrownBy(() -> service.submit(dto))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("kosár");
        verify(competitorRateRepository, never()).save(any());
    }

    @Test
    @DisplayName("FK-041/II: irreális eladás/vétel arány (>3x) → ValidationException")
    void submit_implausibleSpread_throws() {
        Competitor competitor = competitorInRegion(BRANCH_ID);
        when(competitorRepository.findById(competitor.getId())).thenReturn(Optional.of(competitor));

        // sell = buy * ~97 (400 -> 39000): durva elgépelés, irreális arány.
        CompetitorRateEntryDto dto = new CompetitorRateEntryDto(competitor.getId(), List.of(
                new CompetitorRateEntryDto.CurrencyRateLine(1L, new BigDecimal("400"), new BigDecimal("39000"))));

        assertThatThrownBy(() -> service.submit(dto))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("irreális");
        verify(competitorRateRepository, never()).save(any());
    }

    @Test
    @DisplayName("FK-041/II: egy payloadon belüli duplikált valuta → last-wins, csak EGY mentés")
    void submit_duplicateCurrencyInPayload_lastWins() {
        Competitor competitor = competitorInRegion(BRANCH_ID);
        when(competitorRepository.findById(competitor.getId())).thenReturn(Optional.of(competitor));
        when(competitorRateRepository.findFirstByCompetitorIdAndCurrencyIdAndRateDateOrderByCreatedAtDesc(
                any(), any(), any())).thenReturn(Optional.empty());

        CompetitorRateEntryDto dto = new CompetitorRateEntryDto(competitor.getId(), List.of(
                new CompetitorRateEntryDto.CurrencyRateLine(1L, new BigDecimal("390"), new BigDecimal("400")),
                new CompetitorRateEntryDto.CurrencyRateLine(1L, new BigDecimal("392"), new BigDecimal("398"))));

        service.submit(dto);

        ArgumentCaptor<CompetitorRate> captor = ArgumentCaptor.forClass(CompetitorRate.class);
        verify(competitorRateRepository, times(1)).save(captor.capture());
        assertThat(captor.getValue().getBuyRate())
                .as("egy valutából csak egy sor, az UTOLSÓ értékkel (last-wins)")
                .isEqualByComparingTo("392");
    }

    @Test
    @DisplayName("FK-041/II: branchId nélküli hívó üres scope-ot kap (üres bootstrap, submit 404)")
    void noBranchId_emptyScope() {
        WorkerAuthenticationDetails details =
                new WorkerAuthenticationDetails(WORKER_ID, COMPANY_ID, null, "ARFOLYAM_NEZO");
        TestingAuthenticationToken auth =
                new TestingAuthenticationToken("nezo", "pw", "ROLE_ARFOLYAM_NEZO");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);

        assertThat(service.getBootstrap().getCompetitors()).isEmpty();

        Competitor any = competitorInRegion(BRANCH_ID);
        when(competitorRepository.findById(any.getId())).thenReturn(Optional.of(any));
        CompetitorRateEntryDto dto = new CompetitorRateEntryDto(any.getId(), List.of(
                new CompetitorRateEntryDto.CurrencyRateLine(1L, new BigDecimal("390"), new BigDecimal("400"))));
        assertThatThrownBy(() -> service.submit(dto)).isInstanceOf(ResourceNotFoundException.class);
        verify(competitorRateRepository, never()).save(any());
    }

    @Test
    @DisplayName("FK-041/II: terület (régió) nélküli iroda → saját irodára esik vissza; idegen iroda versenyhelye 404")
    void noRegion_fallbackToOwnBranch() {
        Branch ownNoRegion = Branch.builder().id(BRANCH_ID).name("Tisza Sarok").region(null).build();
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(ownNoRegion));
        when(competitorRateRepository.findFirstByCompetitorIdAndCurrencyIdAndRateDateOrderByCreatedAtDesc(
                any(), any(), any())).thenReturn(Optional.empty());

        // A saját iroda versenyhelye bevihető (a fallback scope = {saját iroda}).
        Competitor ownComp = competitorInRegion(BRANCH_ID);
        when(competitorRepository.findById(ownComp.getId())).thenReturn(Optional.of(ownComp));
        service.submit(new CompetitorRateEntryDto(ownComp.getId(), List.of(
                new CompetitorRateEntryDto.CurrencyRateLine(1L, new BigDecimal("390"), new BigDecimal("400")))));
        verify(competitorRateRepository, times(1)).save(any());

        // Egy MÁSIK iroda versenyhelye NINCS a fallback scope-ban → 404 (terület-szivárgás ellen).
        Competitor foreign = competitorInRegion(UUID.randomUUID());
        when(competitorRepository.findById(foreign.getId())).thenReturn(Optional.of(foreign));
        assertThatThrownBy(() -> service.submit(new CompetitorRateEntryDto(foreign.getId(), List.of(
                new CompetitorRateEntryDto.CurrencyRateLine(1L, new BigDecimal("390"), new BigDecimal("400"))))))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    @DisplayName("FK-041/II: üres régió-scope (idegen cég / nincs irodája a régióban) → bootstrap üres, submit 404")
    void emptyRegionScope_noLeak() {
        when(branchRepository.findActiveByCompanyIdAndRegion(COMPANY_ID, "SZEGED")).thenReturn(List.of());

        assertThat(service.getBootstrap().getCompetitors()).isEmpty();

        Competitor foreign = competitorInRegion(UUID.randomUUID());
        when(competitorRepository.findById(foreign.getId())).thenReturn(Optional.of(foreign));
        assertThatThrownBy(() -> service.submit(new CompetitorRateEntryDto(foreign.getId(), List.of(
                new CompetitorRateEntryDto.CurrencyRateLine(1L, new BigDecimal("390"), new BigDecimal("400"))))))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    @DisplayName("FK-041/II: getTodayRates valutánként a LEGFRISSEBBET adja (dedup) és scope-ot ellenőriz")
    void getTodayRates_dedupAndScope() {
        Competitor competitor = competitorInRegion(BRANCH_ID);
        when(competitorRepository.findById(competitor.getId())).thenReturn(Optional.of(competitor));

        // findTodayByCompetitor createdAt DESC sorrendben adja: első = legfrissebb.
        CompetitorRate newer = CompetitorRate.builder().currency(eur)
                .buyRate(new BigDecimal("391")).sellRate(new BigDecimal("399")).rateDate(LocalDate.now()).build();
        CompetitorRate older = CompetitorRate.builder().currency(eur)
                .buyRate(new BigDecimal("388")).sellRate(new BigDecimal("402")).rateDate(LocalDate.now()).build();
        when(competitorRateRepository.findTodayByCompetitor(eq(competitor.getId()), any(LocalDate.class)))
                .thenReturn(List.of(newer, older));

        List<CompetitorTodayRateDto> today = service.getTodayRates(competitor.getId());
        assertThat(today).hasSize(1);
        assertThat(today.get(0).getCurrencyCode()).isEqualTo("EUR");
        assertThat(today.get(0).getBuyRate())
                .as("valutánként a legfrissebb (lista első eleme) érték")
                .isEqualByComparingTo("391");

        // Területen kívüli competitor → 404 (scope-ellenőrzés a getTodayRates-en is).
        Competitor foreign = competitorInRegion(UUID.randomUUID());
        when(competitorRepository.findById(foreign.getId())).thenReturn(Optional.of(foreign));
        assertThatThrownBy(() -> service.getTodayRates(foreign.getId()))
                .isInstanceOf(ResourceNotFoundException.class);
    }
}
