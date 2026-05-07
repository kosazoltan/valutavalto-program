package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.config.ConfigBundleDto;
import hu.puzzleir.valuta.dto.config.ImportResultDto;
import hu.puzzleir.valuta.service.ConfigExportService;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class ConfigExportControllerTest {

    private final ConfigExportService configExportService = mock(ConfigExportService.class);
    private final ConfigExportController controller = new ConfigExportController(configExportService);

    @Test
    void importConfigReturnsOkForSuccessfulImport() {
        UUID branchId = UUID.randomUUID();
        ConfigBundleDto bundle = ConfigBundleDto.builder().branchId(branchId.toString()).build();
        ImportResultDto success = ImportResultDto.builder().success(true).build();
        when(configExportService.importConfig(branchId, bundle)).thenReturn(success);

        ResponseEntity<ImportResultDto> response = controller.importConfig(branchId, bundle);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isSameAs(success);
    }

    @Test
    void importConfigReturnsServiceUnavailableForFailedImport() {
        UUID branchId = UUID.randomUUID();
        ConfigBundleDto bundle = ConfigBundleDto.builder().branchId(branchId.toString()).build();
        ImportResultDto failed = ImportResultDto.builder()
                .success(false)
                .errors(List.of("system parameter import failed"))
                .build();
        when(configExportService.importConfig(branchId, bundle)).thenReturn(failed);

        ResponseEntity<ImportResultDto> response = controller.importConfig(branchId, bundle);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
        assertThat(response.getBody()).isSameAs(failed);
    }
}
