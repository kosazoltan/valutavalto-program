package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import org.springframework.beans.factory.annotation.Value;

import hu.puzzleir.valuta.dto.rate.ParsedCurrencyRate;
import hu.puzzleir.valuta.dto.rate.ParsedRateFile;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.format.DateTimeParseException;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Árfolyam szolgáltatás.
 *
 * Legacy: ARFOLYAM tábla kezelés, ARFREG, ARFVALT funkciók
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class ExchangeRateService {

    private final ExchangeRateRepository exchangeRateRepository;
    private final CurrencyRepository currencyRepository;
    private final CompanyRepository companyRepository;
    private final BranchRepository branchRepository;
    private final SystemParameterService systemParameterService;
    private final AuditLogService auditLogService;

    /** Árfolyam maximális kora órában (0 = nincs limit) */
    @Value("${exchange-rate.max-age-hours:24}")
    private int maxAgeHours;

    /**
     * FKH-067 (spec doc: FKH-063): the instant AFTER which a client-recorded transaction is no
     * longer blocked by an expired exchange rate - it only warns and writes an audit entry.
     * ISO-8601 instant (e.g. 2026-09-12T06:00:00Z). Missing/blank/unparsable value -> every
     * transaction falls under the old, blocking rule (fail-closed, safe default).
     */
    public static final String TTL_NONBLOCKING_CUTOFF_KEY = "TTL_NONBLOCKING_CUTOFF";

    /** FKH-067 FR-4: audit event for every stale-rate transaction let through without blocking. */
    public static final String AUDIT_STALE_RATE_TRANSACTION_COMMITTED = "STALE_RATE_TRANSACTION_COMMITTED";

    /**
     * FKH-067 TBD-2: clientCreatedAt is a client-side, NON-authenticated timestamp. This much
     * clock skew is tolerated; beyond it a future-dated timestamp does not grant the exemption.
     */
    private static final Duration CLIENT_CLOCK_SKEW_TOLERANCE = Duration.ofMinutes(15);

    /**
     * Aktuális árfolyam lekérése egy valutához.
     *
     * <p>Unchanged (blocking) behaviour: an expired rate raises ValidationException. The
     * non-blocking path must be requested through the {@link #getCurrentRate(Long, Instant)}
     * overload, passing the client's original recording timestamp.
     */
    @Transactional(readOnly = true)
    public ExchangeRate getCurrentRate(Long currencyId) {
        return getCurrentRate(currencyId, null);
    }

    /**
     * FKH-067 FR-2: current rate resolved with the client's original recording timestamp.
     *
     * @param clientCreatedAt the unchanged creation instant recorded on the cashier client
     *                        (pending_transactions.created_at). NULL (older client version)
     *                        keeps the old, blocking branch.
     */
    @Transactional(readOnly = true)
    public ExchangeRate getCurrentRate(Long currencyId, Instant clientCreatedAt) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();

        ExchangeRate rate = exchangeRateRepository.findLatestRate(companyId, currencyId, branchId)
                .orElseThrow(() -> new ResourceNotFoundException(
                    "Nincs érvényes árfolyam ehhez a valutához: " + currencyId));

        // Árfolyam frissesség ellenőrzése
        validateRateFreshness(rate, clientCreatedAt);

        return rate;
    }

    /**
     * FKH-032 FR-6: az arfolyam kora percben, a validateRateFreshness-szel AZONOS
     * szamitassal (LocalDateTime.of(validDate, validTime) -> most). Nem dob, csak szamol —
     * igy ugyanaz a logika hasznalhato a listazo valaszban (ExchangeRateMapper) is.
     */
    public static long calculateRateAgeMinutes(LocalDate validDate, LocalTime validTime, LocalDateTime now) {
        if (validDate == null || validTime == null) {
            return 0L;
        }
        return ChronoUnit.MINUTES.between(LocalDateTime.of(validDate, validTime), now);
    }

    /**
     * FKH-032 FR-6: elavult-e az arfolyam a konfiguralt maxAgeHours szerint.
     * Pontosan a validateRateFreshness zart (>=) osszehasonlitasa, dobas nelkul.
     * maxAgeHours &lt;= 0 eseten nincs korhatar -> soha nem elavult.
     */
    public static boolean isRateStale(long minutesOld, int maxAgeHours) {
        if (maxAgeHours <= 0) {
            return false;
        }
        return minutesOld >= (long) maxAgeHours * 60L;
    }

    /**
     * Árfolyam frissesség validálása.
     * Ha az árfolyam régebbi mint a konfigurált max kor, elutasítjuk.
     * FKH-067 FR-2: EXCEPT when the transaction was recorded on the client AFTER the
     * TTL_NONBLOCKING_CUTOFF system parameter.
     */
    private void validateRateFreshness(ExchangeRate rate, Instant clientCreatedAt) {
        if (maxAgeHours <= 0) {
            return; // nincs korhatár
        }
        // Audit 2026-05-31 (P2): a ChronoUnit.HOURS egész órára CSONKOL (24h59m → 24), így a szigorú
        // "> maxAgeHours" feltétel ~25 óráig elfogadta a lejárt rátát. Percalapú, ZÁRT (>=)
        // összehasonlítás → a határ pontosan maxAgeHours (24h00m-től lejárt, nincs ~1h tolerancia).
        // FKH-032: a szamitas kozos segedmetodusba emelve (calculateRateAgeMinutes/isRateStale),
        // hogy a listazo valasz isStale mezoje ugyanazt a hatart hasznalja.
        long minutesOld = calculateRateAgeMinutes(rate.getValidDate(), rate.getValidTime(), LocalDateTime.now());
        if (!isRateStale(minutesOld, maxAgeHours)) {
            return;
        }
        long hoursOld = minutesOld / 60L;

        // FKH-067 FR-2/FR-3/FR-5: the cashier trades at the rate that was actually printed, so a
        // transaction recorded after the cutoff is not blocked. Every other case (missing timestamp,
        // pre-cutoff recording, unset/unparsable parameter, implausible future timestamp) stays on
        // the old, blocking branch - fail-closed.
        if (isTtlNonBlockingFor(clientCreatedAt)) {
            log.warn("Lejárt árfolyam ÁTENGEDVE (FKH-067, cutoff utáni rögzítés): {} — {} órás (max: {} óra), kliens-rögzítés: {}",
                    rate.getCurrency().getCode(), hoursOld, maxAgeHours, clientCreatedAt);
            auditLogService.log(
                    AUDIT_STALE_RATE_TRANSACTION_COMMITTED,
                    String.format("Elavult árfolyammal könyvelt tranzakció: %s, árfolyam kora %d óra (max: %d óra), "
                                  + "érvényesség: %s %s, kliens-rögzítés: %s",
                            rate.getCurrency().getCode(), hoursOld, maxAgeHours,
                            rate.getValidDate(), rate.getValidTime(), clientCreatedAt),
                    rate.getId() != null ? rate.getId().toString() : rate.getCurrency().getCode());
            return;
        }

        log.warn("Lejárt árfolyam: {} — {} órás (max: {} óra)",
                rate.getCurrency().getCode(), hoursOld, maxAgeHours);
        throw new ValidationException(
            String.format("Az árfolyam lejárt! (Utolsó frissítés: %s %s, %d órája — maximum: %d óra). " +
                          "Kérjük frissítse az árfolyamokat.",
                rate.getValidDate(), rate.getValidTime(), hoursOld, maxAgeHours));
    }

    /**
     * FKH-067 FR-2/FR-3: is the TTL expiry non-blocking for this client timestamp?
     * Fail-closed: any missing/invalid/implausible value yields FALSE (blocking stays).
     */
    private boolean isTtlNonBlockingFor(Instant clientCreatedAt) {
        if (clientCreatedAt == null) {
            return false; // older client version, or a non-client-originated call
        }
        // TBD-2: clientCreatedAt is unauthenticated client data - a future instant (beyond clock
        // skew) indicates manipulation, so it does not grant the exemption.
        if (clientCreatedAt.isAfter(Instant.now().plus(CLIENT_CLOCK_SKEW_TOLERANCE))) {
            log.warn("FKH-067: implauzibilis (jövőbeli) kliens-időbélyeg, a blokkoló ág marad érvényben: {}",
                    clientCreatedAt);
            return false;
        }
        Optional<String> configured = systemParameterService.findEffectiveValue(TTL_NONBLOCKING_CUTOFF_KEY);
        if (configured.isEmpty()) {
            return false; // not consciously configured -> never lets anyone through
        }
        Instant cutoff;
        try {
            cutoff = parseCutoff(configured.get().trim());
        } catch (DateTimeParseException e) {
            log.warn("FKH-067: a {} paraméter értéke nem értelmezhető ISO-8601 időpontként ({}), a blokkoló ág marad érvényben.",
                    TTL_NONBLOCKING_CUTOFF_KEY, configured.get());
            return false;
        }
        return !clientCreatedAt.isBefore(cutoff);
    }

    /**
     * FKH-067: the cutoff parameter accepts an ISO-8601 instant (2026-09-12T06:00:00Z) or a
     * zone-less local date-time (2026-09-12T06:00:00); the latter is interpreted in the server's
     * zone (the operator reasons in server time).
     */
    private static Instant parseCutoff(String value) {
        try {
            return Instant.parse(value);
        } catch (DateTimeParseException notAnInstant) {
            return LocalDateTime.parse(value).atZone(ZoneId.systemDefault()).toInstant();
        }
    }

    /**
     * Aktuális árfolyam lekérése valuta kód alapján
     */
    @Transactional(readOnly = true)
    public ExchangeRate getCurrentRateByCode(String currencyCode) {
        Currency currency = currencyRepository.findByCode(currencyCode)
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található: " + currencyCode));
        return getCurrentRate(currency.getId());
    }

    /**
     * Összes aktuális árfolyam lekérése — dátumtól függetlenül.
     * Valutánként a legfrissebb aktív árfolyamot adja vissza.
     */
    @Transactional(readOnly = true)
    public List<ExchangeRate> getAllCurrentRates() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        List<ExchangeRate> allActive = exchangeRateRepository.findAllActiveRates(companyId, branchId);

        // Valutánként a legfrissebb (első) árfolyamot tartjuk meg
        Map<Long, ExchangeRate> latestByCurrency = new LinkedHashMap<>();
        for (ExchangeRate rate : allActive) {
            latestByCurrency.putIfAbsent(rate.getCurrency().getId(), rate);
        }

        // FK-006: a valutanem-törzs az IGAZSÁGFORRÁS — csak AKTÍV valuták árfolyamát adjuk vissza,
        // a currency.display_order szerint rendezve. Az inaktív valuták (pl. DKK/NOK/SEK) árfolyamai
        // így nem jelennek meg a nézet-felületeken, a historikus tranzakciók viszont érintetlenek.
        // (Az árfolyamkészítő külön rate-creation/local-rate-maker endpointot használ — azt nem érinti.)
        List<ExchangeRate> result = new ArrayList<>();
        for (Currency currency : currencyRepository.findAllActiveOrdered()) {
            ExchangeRate rate = latestByCurrency.get(currency.getId());
            if (rate != null) {
                result.add(rate);
            }
        }
        return result;
    }

    /**
     * Megfelelő árfolyam meghatározása összeg alapján (limit szintek)
     *
     * Legacy: ARFOLYAM tábla LIMIT1, LIMIT2, LIMIT3 mezők alapján
     */
    @Transactional(readOnly = true)
    public BigDecimal getBuyRateForAmount(Long currencyId, BigDecimal hufAmount) {
        ExchangeRate rate = getCurrentRate(currencyId);
        return rate.getBuyRateForAmount(hufAmount);
    }

    @Transactional(readOnly = true)
    public BigDecimal getSellRateForAmount(Long currencyId, BigDecimal hufAmount) {
        ExchangeRate rate = getCurrentRate(currencyId);
        return rate.getSellRateForAmount(hufAmount);
    }

    /**
     * Új árfolyam létrehozása
     */
    public ExchangeRate createExchangeRate(CreateExchangeRateRequest request) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem található"));

        Currency currency = currencyRepository.findById(request.getCurrencyId())
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található: " + request.getCurrencyId()));

        // Validáció: árfolyamok pozitívak
        if (request.getBaseBuyRate() == null || request.getBaseBuyRate().compareTo(BigDecimal.ZERO) <= 0) {
            throw new ValidationException("Vételi árfolyam 0-nál nagyobb kell legyen!");
        }
        if (request.getBaseSellRate() == null || request.getBaseSellRate().compareTo(BigDecimal.ZERO) <= 0) {
            throw new ValidationException("Eladási árfolyam 0-nál nagyobb kell legyen!");
        }

        // Validáció: eladási árfolyam > vételi árfolyam
        if (request.getBaseBuyRate().compareTo(request.getBaseSellRate()) >= 0) {
            throw new ValidationException("Az eladási árfolyamnak nagyobbnak kell lennie a vételinél!");
        }

        // Validáció: MNB maximális eltérés az hivatalos (közép) árfolyamtól
        validateMaxDeviation(currency, request.getBaseBuyRate(), request.getBaseSellRate(), request.getOfficialRate());

        // Validáció: limit összegek növekvő sorrendben
        if (request.getLimit1Amount() != null && request.getLimit2Amount() != null
                && request.getLimit1Amount().compareTo(request.getLimit2Amount()) >= 0) {
            throw new ValidationException("Limit1 összegnek kisebbnek kell lennie Limit2-nél!");
        }
        if (request.getLimit2Amount() != null && request.getLimit3Amount() != null
                && request.getLimit2Amount().compareTo(request.getLimit3Amount()) >= 0) {
            throw new ValidationException("Limit2 összegnek kisebbnek kell lennie Limit3-nál!");
        }

        Branch branch = null;
        if (request.getBranchId() != null) {
            branch = branchRepository.findById(request.getBranchId())
                    .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található"));
        }

        // Régi árfolyamok inaktiválása ugyanazon a publikációs szinten:
        // iroda-specifikus árfolyam nem kapcsolhatja ki a cégszintű fallback sort.
        deactivateOldRates(companyId, currency.getId(), branch != null ? branch.getId() : null);

        ExchangeRate rate = ExchangeRate.builder()
                .company(company)
                .branch(branch)
                .currency(currency)
                .validDate(LocalDate.now())
                .validTime(LocalTime.now())
                .baseBuyRate(request.getBaseBuyRate())
                .baseSellRate(request.getBaseSellRate())
                .limit1Amount(request.getLimit1Amount())
                .limit1BuyRate(request.getLimit1BuyRate())
                .limit1SellRate(request.getLimit1SellRate())
                .limit2Amount(request.getLimit2Amount())
                .limit2BuyRate(request.getLimit2BuyRate())
                .limit2SellRate(request.getLimit2SellRate())
                .limit3Amount(request.getLimit3Amount())
                .limit3BuyRate(request.getLimit3BuyRate())
                .limit3SellRate(request.getLimit3SellRate())
                .officialRate(request.getOfficialRate())
                .active(true)
                .createdBy(SecurityUtils.getCurrentWorkerCode())
                .build();

        ExchangeRate saved = exchangeRateRepository.save(rate);
        log.info("Új árfolyam létrehozva: {} - vétel: {}, eladás: {}",
                currency.getCode(), saved.getBaseBuyRate(), saved.getBaseSellRate());

        return saved;
    }

    /**
     * Árfolyam módosítás kedvezménnyel
     *
     * Legacy: ARFVALT - kedvezményes árfolyam, supervisor ellenőrzés >2% felett
     */
    @Transactional(readOnly = true)
    public ExchangeRate applyDiscount(Long rateId, BigDecimal discountPercent) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        ExchangeRate rate = exchangeRateRepository.findByIdAndCompanyId(rateId, companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Árfolyam nem található"));

        // 2% feletti kedvezményhez supervisor jog kell
        if (discountPercent.compareTo(new BigDecimal("2.0")) > 0 && !SecurityUtils.isSupervisorOrAbove()) {
            throw new ValidationException("2% feletti kedvezményhez supervisor jogosultság szükséges!");
        }

        // Kedvezményes árfolyam számítása
        // Kedvezmény = spread csökkentés → buy rate NŐ (ügyfél többet kap), sell rate CSÖKKEN (ügyfél kevesebbet fizet)
        BigDecimal discountFraction = discountPercent.divide(new BigDecimal("100"), 6, RoundingMode.HALF_UP);
        BigDecimal newBuyRate = rate.getBaseBuyRate().multiply(BigDecimal.ONE.add(discountFraction));
        BigDecimal newSellRate = rate.getBaseSellRate().multiply(BigDecimal.ONE.subtract(discountFraction));

        log.info("Árfolyam kedvezmény alkalmazva: {}% - új vétel: {}, eladás: {}",
                discountPercent, newBuyRate, newSellRate);

        // Visszaadjuk a módosított árfolyamot tranzakció szintű használatra
        // FONTOS: NE módosítsuk a managed entity-t — az JPA dirty checking miatt perzisztálódna!
        // Ehelyett másolatot készítünk a kedvezményes értékekkel.
        return ExchangeRate.builder()
                .id(rate.getId())
                .company(rate.getCompany())
                .branch(rate.getBranch())
                .currency(rate.getCurrency())
                .validDate(rate.getValidDate())
                .validTime(rate.getValidTime())
                .baseBuyRate(newBuyRate)
                .baseSellRate(newSellRate)
                .limit1Amount(rate.getLimit1Amount())
                .limit1BuyRate(rate.getLimit1BuyRate())
                .limit1SellRate(rate.getLimit1SellRate())
                .limit2Amount(rate.getLimit2Amount())
                .limit2BuyRate(rate.getLimit2BuyRate())
                .limit2SellRate(rate.getLimit2SellRate())
                .limit3Amount(rate.getLimit3Amount())
                .limit3BuyRate(rate.getLimit3BuyRate())
                .limit3SellRate(rate.getLimit3SellRate())
                .officialRate(rate.getOfficialRate())
                .active(rate.getActive())
                .createdBy(rate.getCreatedBy())
                .build();
    }

    /**
     * Árfolyam történet lekérése
     */
    @Transactional(readOnly = true)
    public List<ExchangeRate> getRateHistory(Long currencyId, LocalDate startDate, LocalDate endDate) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return exchangeRateRepository.findRateHistory(companyId, currencyId, startDate, endDate);
    }

    @Transactional(readOnly = true)
    public List<ExchangeRate> getRateHistoryByCode(String currencyCode, LocalDate startDate, LocalDate endDate) {
        Currency currency = currencyRepository.findByCode(currencyCode)
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található: " + currencyCode));
        return getRateHistory(currency.getId(), startDate, endDate);
    }

    /**
     * MNB maximális eltérés validálása.
     *
     * Ha a valutának van beállított max_deviation_percent értéke, ellenőrzi,
     * hogy a vételi és eladási árfolyam nem tér-e el a hivatalos (közép)
     * árfolyamtól a megengedettnél jobban.
     *
     * MNB szabályozás példa: EUA (euro érme) max 20%-kal térhet el az EUR
     * hivatalos középárfolyamtól.
     *
     * @param currency       a valutanem
     * @param buyRate        vételi árfolyam
     * @param sellRate       eladási árfolyam
     * @param officialRate   hivatalos (közép) árfolyam — ha null, a validáció kihagyásra kerül
     */
    private void validateMaxDeviation(Currency currency, BigDecimal buyRate, BigDecimal sellRate, BigDecimal officialRate) {
        // GAP 2: Raiffeisen rendszerszintű max deviation limit
        // Ha van rendszerszintű paraméter, az a felső korlát MINDEN valutára vonatkozik.
        // A végső limit: min(currency-szintű, rendszerszintű) — amelyik kisebb.
        BigDecimal maxDeviation = currency.getMaxDeviationPercent();
        BigDecimal systemMaxDeviation = getSystemMaxDeviation();

        if (systemMaxDeviation != null) {
            if (maxDeviation == null || systemMaxDeviation.compareTo(maxDeviation) < 0) {
                maxDeviation = systemMaxDeviation;
            }
        }

        if (maxDeviation == null) {
            return; // nincs eltérés-korlát erre a valutára
        }

        if (officialRate == null || officialRate.compareTo(BigDecimal.ZERO) <= 0) {
            throw new ValidationException(
                String.format("A(z) %s valutához hivatalos (közép) árfolyam megadása kötelező, " +
                              "mert maximum %s%% eltérési korlát van beállítva!",
                    currency.getCode(), maxDeviation.stripTrailingZeros().toPlainString()));
        }

        BigDecimal deviationFraction = maxDeviation.divide(new BigDecimal("100"), 6, RoundingMode.HALF_UP);
        BigDecimal maxAllowed = officialRate.multiply(BigDecimal.ONE.add(deviationFraction));
        BigDecimal minAllowed = officialRate.multiply(BigDecimal.ONE.subtract(deviationFraction));

        if (buyRate.compareTo(minAllowed) < 0 || buyRate.compareTo(maxAllowed) > 0) {
            BigDecimal buyDeviation = buyRate.subtract(officialRate)
                    .abs()
                    .divide(officialRate, 4, RoundingMode.HALF_UP)
                    .multiply(new BigDecimal("100"));
            throw new ValidationException(
                String.format("A(z) %s vételi árfolyam (%.4f) %.2f%%-kal tér el a hivatalos árfolyamtól (%.4f). " +
                              "Maximum megengedett eltérés: %s%%.",
                    currency.getCode(), buyRate, buyDeviation, officialRate,
                    maxDeviation.stripTrailingZeros().toPlainString()));
        }

        if (sellRate.compareTo(minAllowed) < 0 || sellRate.compareTo(maxAllowed) > 0) {
            BigDecimal sellDeviation = sellRate.subtract(officialRate)
                    .abs()
                    .divide(officialRate, 4, RoundingMode.HALF_UP)
                    .multiply(new BigDecimal("100"));
            throw new ValidationException(
                String.format("A(z) %s eladási árfolyam (%.4f) %.2f%%-kal tér el a hivatalos árfolyamtól (%.4f). " +
                              "Maximum megengedett eltérés: %s%%.",
                    currency.getCode(), sellRate, sellDeviation, officialRate,
                    maxDeviation.stripTrailingZeros().toPlainString()));
        }

        log.debug("Maximális eltérés validáció OK: {} — buy={}, sell={}, official={}, maxDev={}%",
                currency.getCode(), buyRate, sellRate, officialRate, maxDeviation);
    }

    /**
     * Régi árfolyamok inaktiválása
     */
    private void deactivateOldRates(UUID companyId, Long currencyId, UUID branchId) {
        List<ExchangeRate> oldRates = branchId != null
                ? exchangeRateRepository.findActiveBranchRates(companyId, currencyId, branchId)
                : exchangeRateRepository.findActiveGlobalRates(companyId, currencyId);
        for (ExchangeRate oldRate : oldRates) {
            oldRate.setActive(false);
            exchangeRateRepository.save(oldRate);
        }
    }

    /**
     * GAP 2: Rendszerszintű Raiffeisen max deviation lekérése.
     * Ha a system_parameter 'raiffeisen.max.deviation.percent' létezik és aktív,
     * visszaadja az értéket. Egyébként null.
     */
    private BigDecimal getSystemMaxDeviation() {
        try {
            String value = systemParameterService.getValue("raiffeisen.max.deviation.percent");
            return new BigDecimal(value);
        } catch (Exception e) {
            // Paraméter nem létezik vagy nem parse-olható — nincs rendszerszintű limit
            return null;
        }
    }

    /**
     * Legacy GETARF fájlból importált árfolyamok alkalmazása.
     *
     * A ParsedRateFile-ból létrehozza az árfolyamokat a rendszerben.
     * Csak a rendszerben létező valutákhoz hoz létre árfolyamot.
     *
     * @param parsedFile a feldolgozott árfolyamfájl
     * @return az újonnan létrehozott árfolyamok listája
     */
    public List<ExchangeRate> importRatesFromParsedFile(ParsedRateFile parsedFile) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem található"));

        Branch branch = null;
        try {
            UUID branchId = SecurityUtils.getCurrentBranchId();
            branch = branchRepository.findById(branchId)
                    .orElse(null);
        } catch (Exception e) {
            log.debug("Nincs aktív branch a session-ben, company-szintű import");
        }

        List<ExchangeRate> importedRates = new ArrayList<>();

        for (ParsedCurrencyRate parsedRate : parsedFile.getRates()) {
            try {
                Currency currency = currencyRepository.findByCode(parsedRate.getCurrencyCode())
                        .orElse(null);

                if (currency == null) {
                    log.debug("Valuta nem található a rendszerben, kihagyva: {}", parsedRate.getCurrencyCode());
                    continue;
                }

                // Csak akkor importáljuk, ha van érvényes vételi és eladási árfolyam
                if (parsedRate.getBuyRate() == null || parsedRate.getBuyRate().compareTo(BigDecimal.ZERO) <= 0
                        || parsedRate.getSellRate() == null || parsedRate.getSellRate().compareTo(BigDecimal.ZERO) <= 0) {
                    log.warn("Érvénytelen vételi/eladási árfolyam, kihagyva: {}", parsedRate.getCurrencyCode());
                    continue;
                }

                // Régi árfolyamok inaktiválása ugyanazon a publikációs szinten
                deactivateOldRates(companyId, currency.getId(), branch != null ? branch.getId() : null);

                ExchangeRate rate = ExchangeRate.builder()
                        .company(company)
                        .branch(branch)
                        .currency(currency)
                        .validDate(LocalDate.now())
                        .validTime(LocalTime.now())
                        .baseBuyRate(parsedRate.getBuyRate())
                        .baseSellRate(parsedRate.getSellRate())
                        .officialRate(parsedRate.getMnbRate())
                        .active(true)
                        .createdBy(SecurityUtils.getCurrentWorkerCode())
                        .build();

                ExchangeRate saved = exchangeRateRepository.save(rate);
                importedRates.add(saved);

                log.info("Árfolyam importálva fájlból: {} — vétel: {}, eladás: {}, MNB: {}",
                        parsedRate.getCurrencyCode(),
                        parsedRate.getBuyRate(), parsedRate.getSellRate(), parsedRate.getMnbRate());

            } catch (Exception e) {
                log.error("Hiba az árfolyam importálásakor: {} — {}", parsedRate.getCurrencyCode(), e.getMessage());
            }
        }

        log.info("Árfolyam fájl import kész: {} valuta importálva a(z) {} feldolgozottból",
                importedRates.size(), parsedFile.getRates().size());

        return importedRates;
    }

    /**
     * Árfolyam létrehozás request DTO (belső osztály)
     */
    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class CreateExchangeRateRequest {
        private Long currencyId;
        private UUID branchId;
        private BigDecimal baseBuyRate;
        private BigDecimal baseSellRate;
        private BigDecimal limit1Amount;
        private BigDecimal limit1BuyRate;
        private BigDecimal limit1SellRate;
        private BigDecimal limit2Amount;
        private BigDecimal limit2BuyRate;
        private BigDecimal limit2SellRate;
        private BigDecimal limit3Amount;
        private BigDecimal limit3BuyRate;
        private BigDecimal limit3SellRate;
        private BigDecimal officialRate;
    }
}
