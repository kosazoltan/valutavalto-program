package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.config.IntegrationTransportProperties;
import hu.puzzleir.valuta.dto.pos.PosClosingResult;
import hu.puzzleir.valuta.dto.pos.PosResultStatus;
import hu.puzzleir.valuta.dto.pos.PosTransactionResult;
import hu.puzzleir.valuta.dto.pos.TerminalStatus;
import hu.puzzleir.valuta.entity.PosTerminal;
import hu.puzzleir.valuta.repository.PosTerminalRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;
import java.nio.file.Path;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PosTerminalServiceTest {

    @TempDir
    Path tempDir;

    @Mock
    private PosTerminalRepository repository;

    @Mock
    private SystemParameterService systemParameterService;

    @Mock
    private OtpTerminalProtocolService otpProtocol;

    private PosTerminalService service;

    @BeforeEach
    void setUp() {
        IntegrationTransportProperties properties = new IntegrationTransportProperties();
        properties.setRootPath(tempDir.toString());
        FileTransportService fileTransportService = new FileTransportService(properties, new ObjectMapper());
        service = new PosTerminalService(repository, systemParameterService, otpProtocol,
                properties, fileTransportService);
        ReflectionTestUtils.setField(service, "bridgeSimulatedApprovalEnabled", false);
    }

    @Test
    void borgunBridgePaymentFailsClosedByDefault() {
        PosTerminal terminal = activeTerminal("TERM-BORGUN", "BORGUN");
        when(repository.findByTerminalId("TERM-BORGUN")).thenReturn(Optional.of(terminal));

        PosTransactionResult result = service.initiatePayment(
                new BigDecimal("12500"), "HUF", "TERM-BORGUN");

        assertThat(result.approved()).isFalse();
        assertThat(result.status()).isEqualTo(PosResultStatus.ERROR);
        assertThat(result.errorMessage()).contains("bridge szimuláció tiltva");
        assertThat(terminal.getLastTransactionAt()).isNull();
        assertThat(tempDir).isEmptyDirectory();
        verify(repository, never()).save(any());
    }

    @Test
    void worldlineBridgeReversalFailsClosedByDefault() {
        PosTerminal terminal = activeTerminal("TERM-WORLDLINE", "WORLDLINE");
        when(repository.findByTerminalId("TERM-WORLDLINE")).thenReturn(Optional.of(terminal));

        PosTransactionResult result = service.initiateReversal("ORIGINAL-REF", "TERM-WORLDLINE");

        assertThat(result.approved()).isFalse();
        assertThat(result.status()).isEqualTo(PosResultStatus.ERROR);
        assertThat(result.errorMessage()).contains("nincs éles terminál-jóváhagyás");
        assertThat(terminal.getLastTransactionAt()).isNull();
        assertThat(tempDir).isEmptyDirectory();
        verify(repository, never()).save(any());
    }

    @Test
    void bridgeDailyCloseFailsClosedByDefault() {
        when(repository.findByTerminalId("TERM-BORGUN"))
                .thenReturn(Optional.of(activeTerminal("TERM-BORGUN", "BORGUN")));

        PosClosingResult result = service.dailyClose("TERM-BORGUN");

        assertThat(result.success()).isFalse();
        assertThat(result.errorMessage()).contains("bridge szimuláció tiltva");
        assertThat(tempDir).isEmptyDirectory();
    }

    @Test
    void bridgeStatusIsOfflineWhenSimulationIsDisabled() {
        when(repository.findByTerminalId("TERM-BORGUN"))
                .thenReturn(Optional.of(activeTerminal("TERM-BORGUN", "BORGUN")));

        TerminalStatus status = service.getStatus("TERM-BORGUN");

        assertThat(status.active()).isTrue();
        assertThat(status.reachable()).isFalse();
        assertThat(status.statusMessage()).contains("bridge heartbeat sikertelen");
        assertThat(tempDir).isEmptyDirectory();
    }

    @Test
    void bridgePaymentCanBeExplicitlyEnabledForIsolatedTests() {
        ReflectionTestUtils.setField(service, "bridgeSimulatedApprovalEnabled", true);
        PosTerminal terminal = activeTerminal("TERM-BORGUN", "BORGUN");
        when(repository.findByTerminalId("TERM-BORGUN")).thenReturn(Optional.of(terminal));

        PosTransactionResult result = service.initiatePayment(
                new BigDecimal("12500"), "HUF", "TERM-BORGUN");

        assertThat(result.approved()).isTrue();
        assertThat(result.status()).isEqualTo(PosResultStatus.APPROVED);
        assertThat(terminal.getLastTransactionAt()).isNotNull();
        verify(repository).save(terminal);
    }

    private PosTerminal activeTerminal(String terminalId, String terminalType) {
        return PosTerminal.builder()
                .terminalId(terminalId)
                .terminalName(terminalId)
                .terminalType(terminalType)
                .branchId(UUID.randomUUID())
                .isActive(true)
                .build();
    }
}
