package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.bankapi.UpdateBankApiConfigRequest;
import hu.puzzleir.valuta.entity.BankApiAuthType;
import hu.puzzleir.valuta.entity.BankApiConfig;
import hu.puzzleir.valuta.entity.BankApiMode;
import hu.puzzleir.valuta.entity.BankApiRunStatus;
import hu.puzzleir.valuta.repository.BankApiConfigRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class BankApiConfigServiceTest {

    @Mock
    private BankApiConfigRepository repository;

    @InjectMocks
    private BankApiConfigService service;

    @Test
    @DisplayName("DTO nem expose-olja a secretet, csak configured flag-et ad")
    void toDto_masksClientSecret() {
        BankApiConfig config = BankApiConfig.builder()
                .providerName("RAIFFEISEN")
                .mode(BankApiMode.REST_PRIMARY_WITH_HTML_FALLBACK)
                .authType(BankApiAuthType.OAUTH2_CLIENT_CREDENTIALS)
                .clientId("client-1")
                .clientSecret("secret-value")
                .updateFrequency("0 0 8 * * MON-FRI")
                .enabled(true)
                .lastRunStatus(BankApiRunStatus.NEVER_RUN)
                .updatedAt(LocalDateTime.now())
                .build();

        var dto = service.toDto(config);

        assertThat(dto.getClientId()).isEqualTo("client-1");
        assertThat(dto.getClientSecretConfigured()).isTrue();
    }

    @Test
    @DisplayName("Blank clientSecret update megtartja a korabbi titkot")
    void update_preservesExistingSecretWhenBlank() {
        BankApiConfig existing = BankApiConfig.builder()
                .providerName("RAIFFEISEN")
                .mode(BankApiMode.HTML_SCRAPING_FALLBACK)
                .authType(BankApiAuthType.NONE)
                .clientSecret("existing-secret")
                .updateFrequency("0 0 8 * * MON-FRI")
                .enabled(true)
                .lastRunStatus(BankApiRunStatus.NEVER_RUN)
                .build();
        when(repository.findByProviderName("RAIFFEISEN")).thenReturn(Optional.of(existing));
        when(repository.save(any(BankApiConfig.class))).thenAnswer(invocation -> invocation.getArgument(0));

        UpdateBankApiConfigRequest request = new UpdateBankApiConfigRequest();
        request.setMode(BankApiMode.REST_PRIMARY_WITH_HTML_FALLBACK);
        request.setEndpointUrl("https://bank.example/rates");
        request.setAuthType(BankApiAuthType.OAUTH2_CLIENT_CREDENTIALS);
        request.setClientId("client-2");
        request.setClientSecret("   ");
        request.setUpdateFrequency("0 30 8 * * MON-FRI");
        request.setEnabled(true);

        service.update("raiffeisen", request);

        ArgumentCaptor<BankApiConfig> captor = ArgumentCaptor.forClass(BankApiConfig.class);
        verify(repository).save(captor.capture());
        assertThat(captor.getValue().getClientSecret()).isEqualTo("existing-secret");
        assertThat(captor.getValue().getEndpointUrl()).isEqualTo("https://bank.example/rates");
    }

    @Test
    @DisplayName("recordRun frissiti az utolso futasi statust es roviditi a tul hosszu uzenetet")
    void recordRun_updatesStatusAndLimitsMessage() {
        BankApiConfig existing = BankApiConfig.builder()
                .providerName("RAIFFEISEN")
                .mode(BankApiMode.HTML_SCRAPING_FALLBACK)
                .authType(BankApiAuthType.NONE)
                .updateFrequency("0 0 8 * * MON-FRI")
                .enabled(true)
                .lastRunStatus(BankApiRunStatus.NEVER_RUN)
                .build();
        when(repository.findByProviderName("RAIFFEISEN")).thenReturn(Optional.of(existing));

        service.recordRun("raiffeisen", BankApiRunStatus.FAILED, "x".repeat(2500));

        ArgumentCaptor<BankApiConfig> captor = ArgumentCaptor.forClass(BankApiConfig.class);
        verify(repository).save(captor.capture());
        assertThat(captor.getValue().getLastRunStatus()).isEqualTo(BankApiRunStatus.FAILED);
        assertThat(captor.getValue().getLastRunTimestamp()).isNotNull();
        assertThat(captor.getValue().getLastRunMessage()).hasSize(2000);
    }
}
