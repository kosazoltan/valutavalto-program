package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.bankapi.BankApiConfigDto;
import hu.puzzleir.valuta.dto.bankapi.UpdateBankApiConfigRequest;
import hu.puzzleir.valuta.entity.BankApiAuthType;
import hu.puzzleir.valuta.entity.BankApiConfig;
import hu.puzzleir.valuta.entity.BankApiMode;
import hu.puzzleir.valuta.entity.BankApiRunStatus;
import hu.puzzleir.valuta.repository.BankApiConfigRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Locale;

@Service
@RequiredArgsConstructor
public class BankApiConfigService {

    public static final String PROVIDER_RAIFFEISEN = "RAIFFEISEN";
    public static final String PROVIDER_MNB = "MNB";

    private static final String DEFAULT_RAIFFEISEN_URL =
            "https://www.raiffeisen.hu/hasznos/arfolyamok/lakossagi/"
                    + "deviza%C3%A1rfolyamok-bej%C3%B6v%C5%91-%C3%A9s-bankon-bel%C3%BCli-"
                    + "%C3%A1tutal%C3%A1si-tranzakci%C3%B3k-elsz%C3%A1mol%C3%A1s%C3%A1hoz";

    private final BankApiConfigRepository repository;

    @Transactional(readOnly = true)
    public List<BankApiConfigDto> list() {
        return repository.findAll().stream()
                .map(this::toDto)
                .toList();
    }

    @Transactional
    public BankApiConfig getOrCreate(String providerName) {
        String provider = normalizeProvider(providerName);
        return repository.findByProviderName(provider)
                .orElseGet(() -> repository.save(defaultConfig(provider)));
    }

    @Transactional(readOnly = true)
    public BankApiConfigDto getDto(String providerName) {
        return toDto(repository.findByProviderName(normalizeProvider(providerName))
                .orElseGet(() -> defaultConfig(normalizeProvider(providerName))));
    }

    @Transactional
    public BankApiConfigDto update(String providerName, UpdateBankApiConfigRequest request) {
        BankApiConfig config = getOrCreate(providerName);
        config.setMode(request.getMode());
        config.setEndpointUrl(trimToNull(request.getEndpointUrl()));
        config.setAuthType(request.getAuthType());
        config.setClientId(trimToNull(request.getClientId()));
        if (StringUtils.hasText(request.getClientSecret())) {
            config.setClientSecret(request.getClientSecret().trim());
        }
        config.setMtlsCertificateAlias(trimToNull(request.getMtlsCertificateAlias()));
        config.setUpdateFrequency(request.getUpdateFrequency().trim());
        config.setEnabled(request.getEnabled());
        return toDto(repository.save(config));
    }

    @Transactional
    public void recordRun(String providerName, BankApiRunStatus status, String message) {
        BankApiConfig config = getOrCreate(providerName);
        config.setLastRunTimestamp(LocalDateTime.now());
        config.setLastRunStatus(status);
        config.setLastRunMessage(limit(message, 2000));
        repository.save(config);
    }

    public BankApiConfigDto toDto(BankApiConfig config) {
        return BankApiConfigDto.builder()
                .id(config.getId())
                .providerName(config.getProviderName())
                .mode(config.getMode())
                .endpointUrl(config.getEndpointUrl())
                .authType(config.getAuthType())
                .clientId(config.getClientId())
                .clientSecretConfigured(StringUtils.hasText(config.getClientSecret()))
                .mtlsCertificateAlias(config.getMtlsCertificateAlias())
                .updateFrequency(config.getUpdateFrequency())
                .enabled(config.getEnabled())
                .lastRunTimestamp(config.getLastRunTimestamp())
                .lastRunStatus(config.getLastRunStatus())
                .lastRunMessage(config.getLastRunMessage())
                .updatedAt(config.getUpdatedAt())
                .build();
    }

    private BankApiConfig defaultConfig(String providerName) {
        if (PROVIDER_RAIFFEISEN.equals(providerName)) {
            return BankApiConfig.builder()
                    .providerName(PROVIDER_RAIFFEISEN)
                    .mode(BankApiMode.HTML_SCRAPING_FALLBACK)
                    .endpointUrl(DEFAULT_RAIFFEISEN_URL)
                    .authType(BankApiAuthType.NONE)
                    .updateFrequency("0 0 8 * * MON-FRI")
                    .enabled(true)
                    .lastRunStatus(BankApiRunStatus.NEVER_RUN)
                    .build();
        }
        return BankApiConfig.builder()
                .providerName(providerName)
                .mode(BankApiMode.HTML_SCRAPING_FALLBACK)
                .authType(BankApiAuthType.NONE)
                .updateFrequency("ON_DEMAND")
                .enabled(true)
                .lastRunStatus(BankApiRunStatus.NEVER_RUN)
                .build();
    }

    private String normalizeProvider(String providerName) {
        if (!StringUtils.hasText(providerName)) {
            throw new IllegalArgumentException("providerName is required");
        }
        return providerName.trim().toUpperCase(Locale.ROOT);
    }

    private String trimToNull(String value) {
        return StringUtils.hasText(value) ? value.trim() : null;
    }

    private String limit(String value, int maxLength) {
        if (value == null || value.length() <= maxLength) {
            return value;
        }
        return value.substring(0, maxLength);
    }
}
