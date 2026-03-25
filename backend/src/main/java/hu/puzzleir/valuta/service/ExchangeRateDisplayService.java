package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.entity.ExchangeRateDisplay;
import hu.puzzleir.valuta.repository.ExchangeRateDisplayRepository;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ExchangeRateDisplayService {

    private final ExchangeRateDisplayRepository repository;
    private final ExchangeRateRepository exchangeRateRepository;

    public List<ExchangeRateDisplay> findAll() {
        return repository.findByIsActiveTrueOrderByDisplayNameAsc();
    }

    public ExchangeRateDisplay findById(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("ExchangeRateDisplay not found: " + id));
    }

    public Map<String, Object> getCurrentRates(UUID displayId) {
        ExchangeRateDisplay display = findById(displayId);
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();

        // Parse currency IDs from JSON string
        List<Long> currencyIds = parseCurrencyIds(display.getCurrencyIds());

        List<Map<String, Object>> rates = new ArrayList<>();
        for (Long currencyId : currencyIds) {
            Optional<ExchangeRate> latestRate = exchangeRateRepository.findLatestRate(companyId, currencyId, branchId);
            latestRate.ifPresent(er -> {
                Map<String, Object> rateMap = new LinkedHashMap<>();
                rateMap.put("currencyId", er.getCurrency().getId());
                rateMap.put("currencyCode", er.getCurrency().getCode());
                rateMap.put("currencyName", er.getCurrency().getName());
                rateMap.put("baseBuyRate", er.getBaseBuyRate());
                rateMap.put("baseSellRate", er.getBaseSellRate());
                rateMap.put("validDate", er.getValidDate());
                rateMap.put("validTime", er.getValidTime());
                rates.add(rateMap);
            });
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("displayId", displayId);
        result.put("displayName", display.getDisplayName());
        result.put("rates", rates);
        result.put("refreshInterval", display.getRefreshInterval());
        result.put("generatedAt", LocalDateTime.now());
        return result;
    }

    @Transactional(rollbackFor = Exception.class)
    public ExchangeRateDisplay update(UUID displayId, ExchangeRateDisplay updated) {
        ExchangeRateDisplay existing = findById(displayId);
        if (updated.getDisplayName() != null) {
            existing.setDisplayName(updated.getDisplayName());
        }
        if (updated.getCurrencyIds() != null) {
            existing.setCurrencyIds(updated.getCurrencyIds());
        }
        if (updated.getRefreshInterval() != null) {
            existing.setRefreshInterval(updated.getRefreshInterval());
        }
        if (updated.getIsActive() != null) {
            existing.setIsActive(updated.getIsActive());
        }
        return repository.save(existing);
    }

    private List<Long> parseCurrencyIds(String json) {
        List<Long> ids = new ArrayList<>();
        if (json == null || json.isBlank()) return ids;
        // Simple JSON array parsing: [1,2,3]
        String cleaned = json.replaceAll("[\\[\\]\\s]", "");
        if (cleaned.isEmpty()) return ids;
        for (String part : cleaned.split(",")) {
            try {
                ids.add(Long.parseLong(part.trim()));
            } catch (NumberFormatException ignored) {
                // skip invalid entries
            }
        }
        return ids;
    }
}
