package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.mnbsettlement.MnbQueryRateDto;
import hu.puzzleir.valuta.dto.mnbsettlement.MnbSettlementRateDto;
import hu.puzzleir.valuta.dto.mnbsettlement.MnbSettlementRateUpdateRequest;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.MnbSettlementRate;
import hu.puzzleir.valuta.entity.MnbSettlementRateHistory;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.MnbSettlementRateHistoryRepository;
import hu.puzzleir.valuta.repository.MnbSettlementRateRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class MnbSettlementRateService {

    private static final String HUF = "HUF";
    private static final BigDecimal HUF_RATE = new BigDecimal("1.0000");
    private static final BigDecimal ZERO_RATE = BigDecimal.ZERO;
    private static final String ENTITY_TYPE = "MnbSettlementRate";
    private static final String AUTH_ERROR = "VV-AUTH-001";
    private static final String VALID_ERROR = "VV-VALID-028";

    private final MnbSettlementRateRepository rateRepository;
    private final MnbSettlementRateHistoryRepository historyRepository;
    private final CurrencyRepository currencyRepository;
    private final AuditLogService auditLogService;
    private final MnbRateQueryClient mnbRateQueryClient;

    /** NFR-6: worker → utolsó mnb-query hívás (epoch ms). */
    private final ConcurrentHashMap<Long, Long> lastMnbQueryAt = new ConcurrentHashMap<>();

    @Value("${mnb-settlement.query.min-interval-ms:10000}")
    private long mnbQueryMinIntervalMs = 10000L;

    @Transactional(readOnly = true)
    public List<MnbSettlementRateDto> list() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<Currency> currencies = settlementCurrencies();
        Map<String, MnbSettlementRate> rows = rateRepository.findByCompanyId(companyId).stream()
                .collect(Collectors.toMap(MnbSettlementRate::getCurrencyCode, Function.identity()));

        List<MnbSettlementRateDto> result = new ArrayList<>();
        for (Currency currency : currencies) {
            MnbSettlementRate row = rows.get(currency.getCode());
            result.add(toDto(currency, row));
        }
        return result;
    }

    @Transactional(rollbackFor = Exception.class)
    public List<MnbSettlementRateDto> update(MnbSettlementRateUpdateRequest request, boolean publish) {
        assertFoertektar(publish ? "PUBLISH" : "UPDATE");
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        String workerCode = SecurityUtils.getCurrentWorkerCode();
        Instant now = Instant.now();
        List<Currency> currencies = settlementCurrencies();
        Map<String, Currency> activeByCode = currencies.stream()
                .collect(Collectors.toMap(Currency::getCode, Function.identity(), (a, b) -> a, LinkedHashMap::new));

        List<MnbSettlementRateUpdateRequest.Item> items = validateRequest(request, activeByCode);

        for (MnbSettlementRateUpdateRequest.Item item : items) {
            String currencyCode = normalizeCode(item.getCurrencyCode());
            MnbSettlementRate row = rateRepository
                    .findByCompanyIdAndCurrencyCode(companyId, currencyCode)
                    .orElseGet(() -> MnbSettlementRate.builder()
                            .companyId(companyId)
                            .currencyCode(currencyCode)
                            .officialRate(ZERO_RATE)
                            .build());
            BigDecimal oldRate = effectiveRate(currencyCode, row);
            row.setOfficialRate(item.getOfficialRate());
            row.setUpdatedBy(workerCode);
            row.setUpdatedAt(now);
            rateRepository.save(row);
            auditRateUpdate(currencyCode, oldRate, item.getOfficialRate(), publish);
        }

        if (publish) {
            publishCompanyRows(companyId, now);
        }

        snapshot(companyId, workerCode, now, currencies);
        return list();
    }

    @Transactional(readOnly = true)
    public List<MnbQueryRateDto> mnbQuery() {
        assertFoertektar("MNB_QUERY");
        Long workerId = SecurityUtils.getCurrentWorkerId();
        enforceMnbQueryRateLimit(workerId);

        Map<String, BigDecimal> mnbRates;
        try {
            mnbRates = mnbRateQueryClient.fetchCurrentRates();
        } catch (Exception e) {
            log.warn("FK-028 MNB-lekérdezés sikertelen: {}", e.getMessage());
            throw new BusinessException(
                    "Az MNB-szolgáltatás jelenleg nem elérhető, kérjük próbálja később, "
                            + "vagy vigye be az árfolyamokat kézzel.",
                    "VV-MNB-UNAVAILABLE",
                    HttpStatus.SERVICE_UNAVAILABLE);
        }

        List<MnbQueryRateDto> result = new ArrayList<>();
        for (Currency currency : currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()) {
            String currencyCode = normalizeCode(currency.getCode());
            if (HUF.equals(currencyCode)) {
                continue;
            }
            BigDecimal rate = mnbRates.get(currencyCode);
            if (rate != null) {
                result.add(new MnbQueryRateDto(currencyCode, rate));
            }
        }
        return result;
    }

    private void enforceMnbQueryRateLimit(Long workerId) {
        long nowMs = System.currentTimeMillis();
        if (mnbQueryMinIntervalMs <= 0) {
            lastMnbQueryAt.clear();
            return;
        }

        pruneExpiredMnbQueryRateLimitEntries(nowMs);

        AtomicBoolean rateLimited = new AtomicBoolean(false);
        lastMnbQueryAt.compute(workerId, (ignored, previous) -> {
            if (previous != null && nowMs - previous < mnbQueryMinIntervalMs) {
                rateLimited.set(true);
                return previous;
            }
            return nowMs;
        });

        if (rateLimited.get()) {
            throw new BusinessException(
                    "Az MNB-lekérdezés legfeljebb 10 másodpercenként hívható. Kérjük várjon.",
                    "VV-RATE-LIMIT-001",
                    HttpStatus.TOO_MANY_REQUESTS);
        }
    }

    private void pruneExpiredMnbQueryRateLimitEntries(long nowMs) {
        long pruneWindowMs = mnbQueryMinIntervalMs > Long.MAX_VALUE / 10
                ? Long.MAX_VALUE
                : mnbQueryMinIntervalMs * 10;
        long cutoffMs = nowMs - pruneWindowMs;
        lastMnbQueryAt.entrySet().removeIf(entry -> entry.getValue() < cutoffMs);
    }

    private List<MnbSettlementRateUpdateRequest.Item> validateRequest(
            MnbSettlementRateUpdateRequest request,
            Map<String, Currency> activeByCode) {
        if (request == null || request.getItems() == null) {
            throw new ValidationException(VALID_ERROR + ": az items lista kötelező.");
        }
        Set<String> seen = new HashSet<>();
        for (MnbSettlementRateUpdateRequest.Item item : request.getItems()) {
            if (item == null) {
                throw new ValidationException(VALID_ERROR + ": üres tétel nem megengedett.");
            }
            String currencyCode = normalizeCode(item.getCurrencyCode());
            BigDecimal rate = item.getOfficialRate();
            if (HUF.equals(currencyCode)) {
                throw new ValidationException(VALID_ERROR + ": A HUF árfolyam fix 1,0000 — nem módosítható.");
            }
            if (!activeByCode.containsKey(currencyCode)) {
                throw new ValidationException(VALID_ERROR + ": Ismeretlen vagy inaktív valuta: " + currencyCode);
            }
            if (rate == null || rate.signum() <= 0 || rate.scale() > 4 || rate.precision() - rate.scale() > 11) {
                throw new ValidationException(VALID_ERROR + ": Az árfolyam pozitív, legfeljebb 11 egész és 4 tizedesjegyű szám lehet.");
            }
            if (!seen.add(currencyCode)) {
                throw new ValidationException(VALID_ERROR + ": Duplikált valuta a kérésben: " + currencyCode);
            }
            item.setCurrencyCode(currencyCode);
        }
        return request.getItems();
    }

    private void publishCompanyRows(UUID companyId, Instant now) {
        for (MnbSettlementRate row : rateRepository.findByCompanyId(companyId)) {
            row.setAvailableToOfficesAt(now);
            rateRepository.save(row);
        }
    }

    private void snapshot(UUID companyId, String workerCode, Instant recordedAt, List<Currency> currencies) {
        Map<String, MnbSettlementRate> rows = rateRepository.findByCompanyId(companyId).stream()
                .collect(Collectors.toMap(MnbSettlementRate::getCurrencyCode, Function.identity()));
        for (Currency currency : currencies) {
            MnbSettlementRate row = rows.get(currency.getCode());
            historyRepository.save(MnbSettlementRateHistory.builder()
                    .companyId(companyId)
                    .currencyCode(currency.getCode())
                    .officialRate(effectiveRate(currency.getCode(), row))
                    .availableToOfficesAt(row != null ? row.getAvailableToOfficesAt() : null)
                    .recordedBy(workerCode)
                    .recordedAt(recordedAt)
                    .build());
        }
    }

    private void auditRateUpdate(String currencyCode, BigDecimal oldRate, BigDecimal newRate, boolean publish) {
        auditLogService.logWithDetails(
                "UPDATE",
                ENTITY_TYPE,
                currencyCode,
                workerIdOrNull(),
                null,
                null,
                null,
                rateJson(oldRate),
                rateJson(newRate),
                publish ? "Rögzítés + Küldés irodáknak" : "Rögzítés",
                null);
    }

    private void assertFoertektar(String operation) {
        String role = effectiveCurrentRole();
        if (!"FOERTEKTAR".equals(role)) {
            auditLogService.logInNewTransaction(
                    "ACCESS_DENIED",
                    ENTITY_TYPE,
                    operation,
                    workerIdOrNull(),
                    null,
                    null,
                    null,
                    String.format("{\"KAT\":\"AUTH\",\"error_code\":\"%s\",\"operation\":\"%s\",\"role\":\"%s\"}",
                            AUTH_ERROR, json(operation), json(role)));
            throw new AccessDeniedException(
                    AUTH_ERROR + ": a művelet kizárólag Főértéktáros számára engedélyezett.");
        }
    }

    private String effectiveCurrentRole() {
        String activeRole = SecurityUtils.getActiveOperationalRole();
        String role = activeRole != null && !activeRole.isBlank()
                ? activeRole
                : SecurityUtils.getCurrentRole();
        return role == null ? null : role.trim().toUpperCase(Locale.ROOT);
    }

    private List<Currency> settlementCurrencies() {
        List<Currency> currencies = new ArrayList<>(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc());
        boolean hasHuf = currencies.stream().anyMatch(currency -> HUF.equals(currency.getCode()));
        if (!hasHuf) {
            currencyRepository.findByCode(HUF).ifPresent(currencies::add);
        }
        currencies.sort(Comparator
                .comparing((Currency currency) -> currency.getDisplayOrder() != null
                        ? currency.getDisplayOrder()
                        : Integer.MAX_VALUE)
                .thenComparing(Currency::getCode));
        return currencies;
    }

    private MnbSettlementRateDto toDto(Currency currency, MnbSettlementRate row) {
        return new MnbSettlementRateDto(
                currency.getCode(),
                currency.getName(),
                effectiveRate(currency.getCode(), row),
                row != null ? row.getAvailableToOfficesAt() : null);
    }

    private BigDecimal effectiveRate(String currencyCode, MnbSettlementRate row) {
        if (row != null && row.getOfficialRate() != null) {
            return row.getOfficialRate();
        }
        return HUF.equals(currencyCode) ? HUF_RATE : ZERO_RATE;
    }

    private String rateJson(BigDecimal rate) {
        return String.format("{\"KAT\":\"RATE\",\"officialRate\":\"%s\"}",
                rate != null ? json(rate.toPlainString()) : "null");
    }

    private String workerIdOrNull() {
        try {
            return SecurityUtils.getCurrentWorkerId().toString();
        } catch (Exception e) {
            return null;
        }
    }

    private String normalizeCode(String code) {
        if (code == null) {
            return null;
        }
        return code.trim().toUpperCase(Locale.ROOT);
    }

    private String json(String value) {
        if (value == null) {
            return "null";
        }
        return value.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
