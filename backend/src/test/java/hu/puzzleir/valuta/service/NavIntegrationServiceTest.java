package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.config.IntegrationTransportProperties;
import hu.puzzleir.valuta.dto.nav.NavSendResult;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThat;

class NavIntegrationServiceTest {

    @TempDir
    Path tempDir;

    private NavIntegrationService service;

    @BeforeEach
    void setUp() {
        IntegrationTransportProperties properties = new IntegrationTransportProperties();
        properties.setRootPath(tempDir.toString());
        FileTransportService fileTransportService = new FileTransportService(properties, new ObjectMapper());
        service = new NavIntegrationService(properties, fileTransportService, false);
    }

    @Test
    void sendTransactionFailsClosedByDefault() {
        NavSendResult result = service.sendTransaction(123L, "COM1");

        assertThat(result.isSuccess()).isFalse();
        assertThat(result.getReceiptNumber()).isNull();
        assertThat(result.getError()).contains("NAV bridge szimuláció tiltva");
        assertThat(tempDir).isEmptyDirectory();
    }

    @Test
    void sendQrCodeFailsClosedByDefault() {
        boolean sent = service.sendQrCode("NAV|payload", "COM1");

        assertThat(sent).isFalse();
        assertThat(tempDir).isEmptyDirectory();
    }

    @Test
    void receiveReceiptNumberDoesNotGenerateFakeReceiptByDefault() {
        String receipt = service.receiveReceiptNumber("COM1");

        assertThat(receipt).isNull();
        assertThat(tempDir).isEmptyDirectory();
    }

    @Test
    void sendTransactionCanBeExplicitlyEnabledForIsolatedTests() {
        IntegrationTransportProperties properties = new IntegrationTransportProperties();
        properties.setRootPath(tempDir.toString());
        FileTransportService fileTransportService = new FileTransportService(properties, new ObjectMapper());
        service = new NavIntegrationService(properties, fileTransportService, true);

        NavSendResult result = service.sendTransaction(123L, "COM1");

        assertThat(result.isSuccess()).isTrue();
        assertThat(result.getReceiptNumber()).startsWith("NAV-");
        assertThat(result.getError()).isNull();
        assertThat(tempDir).isNotEmptyDirectory();
    }
}
