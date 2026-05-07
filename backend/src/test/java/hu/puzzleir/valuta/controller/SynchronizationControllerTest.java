package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.SynchronizationService;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class SynchronizationControllerTest {

    private final SynchronizationService service = mock(SynchronizationService.class);
    private final SynchronizationController controller = new SynchronizationController(service);

    @Test
    void syncReturnsOkForSuccessMap() {
        UUID branchId = UUID.randomUUID();
        Map<String, Object> result = Map.of("success", true, "status", "COMPLETED");
        when(service.sync(branchId, 7L)).thenReturn(result);

        ResponseEntity<Map<String, Object>> response = controller.sync(branchId, 7L);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isSameAs(result);
    }

    @Test
    void syncReturnsServiceUnavailableForFailureMap() {
        UUID branchId = UUID.randomUUID();
        Map<String, Object> result = Map.of("success", false, "status", "FAILED");
        when(service.sync(branchId, 7L)).thenReturn(result);

        ResponseEntity<Map<String, Object>> response = controller.sync(branchId, 7L);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
        assertThat(response.getBody()).isSameAs(result);
    }
}
