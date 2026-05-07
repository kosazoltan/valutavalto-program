package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.ArchiveTask;
import hu.puzzleir.valuta.entity.ArchiveTaskStatus;
import hu.puzzleir.valuta.service.ArchivingService;
import hu.puzzleir.valuta.service.MonthlyArchiveService;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class ArchivingControllerTest {

    private final ArchivingService archivingService = mock(ArchivingService.class);
    private final MonthlyArchiveService monthlyArchiveService = mock(MonthlyArchiveService.class);
    private final ArchivingController controller = new ArchivingController(archivingService, monthlyArchiveService);

    @Test
    void executeTaskReturnsOkForCompletedTask() {
        UUID taskId = UUID.randomUUID();
        ArchiveTask task = ArchiveTask.builder().id(taskId).status(ArchiveTaskStatus.COMPLETED).build();
        when(archivingService.executeTask(taskId)).thenReturn(task);

        ResponseEntity<ArchiveTask> response = controller.executeTask(taskId);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isSameAs(task);
    }

    @Test
    void executeTaskReturnsServiceUnavailableForFailedTask() {
        UUID taskId = UUID.randomUUID();
        ArchiveTask task = ArchiveTask.builder().id(taskId).status(ArchiveTaskStatus.FAILED).build();
        when(archivingService.executeTask(taskId)).thenReturn(task);

        ResponseEntity<ArchiveTask> response = controller.executeTask(taskId);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
        assertThat(response.getBody()).isSameAs(task);
    }
}
