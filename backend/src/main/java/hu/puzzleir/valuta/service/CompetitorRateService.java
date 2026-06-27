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
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * FK-041/II — versenytárs-árfolyam BEVITEL az „árfolyam néző" szerepkörnek.
 *
 * <p>Az árfolyam néző a dolgozói törzsben egy TERÜLETHEZ (a saját irodája régiója) van rendelve, és a
 * területén lévő versenyhelyek (Competitor, irodához kötve) vétel/eladás árfolyamait viszi be egy
 * egyszerű (mobil/PWA) űrlapon. A bevitt {@link CompetitorRate} sorok a meglévő company-scope-olt
 * lekérdezéseken ({@code RateCreationService.getCompetitorRates}) keresztül megjelennek a főértéktáros
 * konkurencia-árfolyam adatlapján, aki ez alapján igazítja a versenyhely-közeli irodák versenyár-ait.</p>
 *
 * <p>Multi-tenant: minden hatókör a hívó cégének RÉGIÓS irodáira korlátozott
 * ({@code findActiveByCompanyIdAndRegion}); a versenyhely a hívó területén kívül / más cégé esetén 404.
 * A figyelt valutakosár konfigurálható ({@code SystemParameter COMPETITOR_WATCH_CURRENCIES}).</p>
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class CompetitorRateService {

    static final String WATCH_CURRENCIES_PARAM = "COMPETITOR_WATCH_CURRENCIES";
    static final String DEFAULT_WATCH_CURRENCIES = "EUR,USD,CHF,GBP";
    static final String SOURCE = "COMPETITOR_WATCHER";
    /** Laza józansági korlát: eladás > vétel * 3 → irreális arány (durva elgépelés). */
    static final BigDecimal MAX_SPREAD_FACTOR = new BigDecimal("3");

    private final CompetitorRepository competitorRepository;
    private final CompetitorRateRepository competitorRateRepository;
    private final CurrencyRepository currencyRepository;
    private final BranchRepository branchRepository;
    private final SystemParameterService systemParameterService;

    /**
     * A hívó TERÜLETÉNEK (a saját irodája régiója) aktív pénztárai — companyId-scope-oltan.
     * Ha nincs terület beállítva, a hívó saját (cég-ellenőrzött) irodájára esik vissza.
     */
    private List<Branch> regionBranches() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchIdOrNull();
        if (branchId == null) {
            return List.of();
        }
        // Explicit cég-tulajdon ellenőrzés a régió kiolvasása ELŐTT — a védelem ne csak a token
        // branchId-invariánsára támaszkodjon, hanem a CompetitorService IDOR-mintájával konzisztens legyen.
        if (!branchRepository.existsByIdAndCompanyId(branchId, companyId)) {
            return List.of();
        }
        Branch own = branchRepository.findById(branchId).orElse(null);
        if (own == null) {
            return List.of();
        }
        String region = own.getRegion();
        if (region == null || region.isBlank()) {
            // Nincs terület beállítva → csak a saját (már cég-ellenőrzött) iroda.
            return List.of(own);
        }
        return branchRepository.findActiveByCompanyIdAndRegion(companyId, region);
    }

    /** A figyelt valuták: a kosár (SystemParameter, default EUR/USD/CHF/GBP) ∩ aktív valuták, sorrendben. */
    private List<Currency> watchCurrencies() {
        String csv = systemParameterService.getValue(WATCH_CURRENCIES_PARAM, DEFAULT_WATCH_CURRENCIES);
        Set<String> basket = Arrays.stream(csv.split(","))
                .map(s -> s.trim().toUpperCase(Locale.ROOT))
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toCollection(java.util.LinkedHashSet::new));
        return currencyRepository.findByActiveTrueOrderByDisplayOrderAsc().stream()
                .filter(c -> basket.contains(c.getCode()))
                .collect(Collectors.toList());
    }

    /** A beíró oldal bootstrapja: a hívó régiójának versenyhelyei + a figyelt valutakosár. */
    @Transactional(readOnly = true)
    public CompetitorWatchBootstrapDto getBootstrap() {
        Map<UUID, String> branchNames = regionBranches().stream()
                .collect(Collectors.toMap(Branch::getId, Branch::getName, (a, b) -> a));

        List<CompetitorWatchBootstrapDto.CompetitorOption> competitors = branchNames.isEmpty()
                ? List.of()
                : competitorRepository
                        .findByBranchIdInAndIsActiveTrueOrderByNameAsc(branchNames.keySet())
                        .stream()
                        .map(c -> CompetitorWatchBootstrapDto.CompetitorOption.builder()
                                .id(c.getId())
                                .name(c.getName())
                                .branchName(branchNames.get(c.getBranchId()))
                                .build())
                        .collect(Collectors.toList());

        List<CompetitorWatchBootstrapDto.WatchCurrency> currencies = watchCurrencies().stream()
                .map(c -> CompetitorWatchBootstrapDto.WatchCurrency.builder()
                        .id(c.getId())
                        .code(c.getCode())
                        .name(c.getName())
                        .build())
                .collect(Collectors.toList());

        return CompetitorWatchBootstrapDto.builder()
                .competitors(competitors)
                .currencies(currencies)
                .build();
    }

    /** Egy versenyhely MAI bevitt versenytárs-árfolyamai (előtöltéshez), valutánként a legfrissebb. */
    @Transactional(readOnly = true)
    public List<CompetitorTodayRateDto> getTodayRates(UUID competitorId) {
        assertCompetitorInScope(competitorId);
        Map<Long, CompetitorTodayRateDto> byCurrency = new LinkedHashMap<>();
        for (CompetitorRate cr : competitorRateRepository.findTodayByCompetitor(competitorId, LocalDate.now())) {
            byCurrency.putIfAbsent(cr.getCurrency().getId(), CompetitorTodayRateDto.builder()
                    .currencyId(cr.getCurrency().getId())
                    .currencyCode(cr.getCurrency().getCode())
                    .buyRate(cr.getBuyRate())
                    .sellRate(cr.getSellRate())
                    .build());
        }
        return new ArrayList<>(byCurrency.values());
    }

    /**
     * Versenytárs-árfolyam beküldés (upsert versenyhely + valuta + ma szerint). Csak a hívó területén
     * lévő versenyhelyre és a figyelt valutakosár valutáira enged bevitelt.
     */
    public void submit(CompetitorRateEntryDto dto) {
        Competitor competitor = assertCompetitorInScope(dto.getCompetitorId());
        Long workerId = SecurityUtils.getCurrentWorkerId();
        LocalDate today = LocalDate.now();

        // Csak a figyelt valutakosár valutáira engedünk bevitelt (különben hibát adunk).
        Map<Long, Currency> basket = watchCurrencies().stream()
                .collect(Collectors.toMap(Currency::getId, c -> c, (a, b) -> a));

        // Egy payloadon belül valutánként az UTOLSÓ sor érvényes (last-wins) — egyetlen beküldés se
        // próbáljon két sort írni ugyanarra a valutára (a DB-szintű egyediséget a V335 UNIQUE index +
        // ON CONFLICT upsert garantálja párhuzamos beküldésnél is).
        Map<Long, CompetitorRateEntryDto.CurrencyRateLine> byCurrency = new LinkedHashMap<>();
        for (CompetitorRateEntryDto.CurrencyRateLine line : dto.getRates()) {
            byCurrency.put(line.getCurrencyId(), line);
        }

        for (CompetitorRateEntryDto.CurrencyRateLine line : byCurrency.values()) {
            Currency currency = basket.get(line.getCurrencyId());
            if (currency == null) {
                throw new ValidationException(
                        "A megadott valuta nem szerepel a figyelt versenytárs-valutakosárban.");
            }
            if (line.getSellRate().compareTo(line.getBuyRate()) <= 0) {
                throw new ValidationException(
                        "Az eladási árfolyamnak nagyobbnak kell lennie a vételinél (" + currency.getCode() + ").");
            }
            // Laza józansági felső korlát: a versenytárs spread-je tág lehet, de a nyilvánvalóan irreális
            // arányt (pl. számjegy-csere elgépelés) elutasítjuk, hogy ne torzítsa a versenyár-igazítást.
            if (line.getSellRate().compareTo(line.getBuyRate().multiply(MAX_SPREAD_FACTOR)) > 0) {
                throw new ValidationException(
                        "Az eladási/vételi árfolyam aránya irreális (" + currency.getCode()
                                + ") — kérjük, ellenőrizze az értéket.");
            }

            // Atomi upsert (versenyhely + valuta + ma) kulcson. A V335 UNIQUE index +
            // PostgreSQL ON CONFLICT DO UPDATE race-free: párhuzamos beküldés se hoz létre
            // duplikált sort, és nem dob DataIntegrityViolationException-t. INSERT-nél a hívó
            // worker a createdBy; UPDATE-nél a createdBy/createdAt megmarad (eredeti rögzítő).
            competitorRateRepository.upsertCompetitorRate(
                    competitor.getId(), currency.getId(), today,
                    line.getBuyRate(), line.getSellRate(), SOURCE, workerId);
        }

        log.info("Versenytárs-árfolyam beküldve: competitorId={}, {} valuta, worker={}",
                competitor.getId(), byCurrency.size(), workerId);
    }

    /**
     * A versenyhely a hívó TERÜLETÉN (régió + companyId) van-e. Ha nem (vagy más cégé), 404 —
     * a multi-tenant + terület-szivárgás ellen.
     */
    private Competitor assertCompetitorInScope(UUID competitorId) {
        Competitor competitor = competitorRepository.findById(competitorId)
                .orElseThrow(() -> new ResourceNotFoundException("Versenyhely nem található: " + competitorId));
        Set<UUID> scope = regionBranches().stream().map(Branch::getId).collect(Collectors.toSet());
        if (competitor.getBranchId() == null || !scope.contains(competitor.getBranchId())) {
            throw new ResourceNotFoundException("Versenyhely nem található: " + competitorId);
        }
        return competitor;
    }
}
