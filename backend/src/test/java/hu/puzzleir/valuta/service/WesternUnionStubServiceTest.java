package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.wu.stub.WuStubTransferRequest;
import hu.puzzleir.valuta.entity.SystemParameter;
import hu.puzzleir.valuta.entity.WuTransaction;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.service.wu.WesternUnionProviderAdapter;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.http.HttpStatus;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import hu.puzzleir.valuta.repository.SystemParameterRepository;

@ExtendWith(MockitoExtension.class)
class WesternUnionStubServiceTest {

    @Mock
    private WesternUnionProviderAdapter internalAdapter;

    @Mock
    private WesternUnionProviderAdapter inactiveAdapter;

    @Mock
    private SystemParameterRepository systemParameterRepository;

    private WesternUnionStubService service;

    @BeforeEach
    void setUp() {
        service = new WesternUnionStubService(List.of(internalAdapter, inactiveAdapter), systemParameterRepository);
    }

    @Test
    @DisplayName("INTERNAL provider esetén send az internal adapteren megy")
    void send_internalProvider() {
        when(internalAdapter.providerCode()).thenReturn("INTERNAL");
        when(systemParameterRepository.findByParameterKey("WU_PROVIDER_MODE"))
                .thenReturn(Optional.of(SystemParameter.builder().parameterValue("INTERNAL").build()));

        WuTransaction tx = WuTransaction.builder().id(UUID.randomUUID()).transactionType("SEND").build();
        when(internalAdapter.send(any())).thenReturn(tx);

        WuTransaction result = service.send(baseRequest());

        assertThat(result).isEqualTo(tx);
        verify(internalAdapter).send(any());
    }

    @Test
    @DisplayName("provider inaktív esetén adapterből kontrollált üzleti hiba jön")
    void rates_inactiveProvider() {
        when(internalAdapter.providerCode()).thenReturn("INTERNAL");
        when(inactiveAdapter.providerCode()).thenReturn("INACTIVE");
        when(systemParameterRepository.findByParameterKey("WU_PROVIDER_MODE"))
                .thenReturn(Optional.of(SystemParameter.builder().parameterValue("INACTIVE").build()));
        when(inactiveAdapter.rates()).thenThrow(new BusinessException("inactive", "WU_PROVIDER_INACTIVE"));

        assertThatThrownBy(() -> service.rates())
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("inactive");

        verify(inactiveAdapter).rates();
    }

    @Test
    @DisplayName("ismeretlen provider esetén determinisztikus SERVICE_UNAVAILABLE + WU_PROVIDER_NOT_SUPPORTED")
    void unknownProvider_returnsControlledError() {
        when(internalAdapter.providerCode()).thenReturn("INTERNAL");
        when(inactiveAdapter.providerCode()).thenReturn("INACTIVE");
        when(systemParameterRepository.findByParameterKey("WU_PROVIDER_MODE"))
                .thenReturn(Optional.of(SystemParameter.builder().parameterValue("UNKNOWN").build()));

        assertThatThrownBy(() -> service.send(baseRequest()))
                .isInstanceOfSatisfying(BusinessException.class, ex -> {
                    assertThat(ex.getMessage()).contains("Ismeretlen WU provider");
                    assertThat(ex.getErrorCode()).isEqualTo("WU_PROVIDER_NOT_SUPPORTED");
                    assertThat(ex.getHttpStatus()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
                });
    }

    @Test
    @DisplayName("runtime exception esetén 502 + WU_PROVIDER_RUNTIME_ERROR")
    void runtimeException_wrappedToBadGateway() {
        when(internalAdapter.providerCode()).thenReturn("INTERNAL");
        when(systemParameterRepository.findByParameterKey("WU_PROVIDER_MODE"))
                .thenReturn(Optional.of(SystemParameter.builder().parameterValue("INTERNAL").build()));
        when(internalAdapter.send(any())).thenThrow(new IllegalStateException("boom"));

        assertThatThrownBy(() -> service.send(baseRequest()))
                .isInstanceOfSatisfying(BusinessException.class, ex -> {
                    assertThat(ex.getErrorCode()).isEqualTo("WU_PROVIDER_RUNTIME_ERROR");
                    assertThat(ex.getHttpStatus()).isEqualTo(HttpStatus.BAD_GATEWAY);
                    assertThat(ex.getMessage()).isEqualTo("WU provider feldolgozási hiba");
                });
    }

    private WuStubTransferRequest baseRequest() {
        return WuStubTransferRequest.builder()
                .branchId(UUID.randomUUID())
                .mtcn("1234567890")
                .amountUsd(new BigDecimal("100"))
                .amountHuf(new BigDecimal("40000"))
                .build();
    }
}
