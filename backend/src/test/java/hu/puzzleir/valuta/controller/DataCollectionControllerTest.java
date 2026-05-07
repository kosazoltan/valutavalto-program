package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.datacollection.CollectAllRequestDto;
import hu.puzzleir.valuta.dto.datacollection.CollectRequestDto;
import hu.puzzleir.valuta.dto.datacollection.DataCollectionDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.DataCollection;
import hu.puzzleir.valuta.entity.DataCollectionStatus;
import hu.puzzleir.valuta.entity.DataCollectionType;
import hu.puzzleir.valuta.service.DataCollectionService;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class DataCollectionControllerTest {

    private static final LocalDate COLLECTION_DATE = LocalDate.of(2026, 5, 7);

    private final DataCollectionService service = mock(DataCollectionService.class);
    private final DataCollectionController controller = new DataCollectionController(service);

    @Test
    void collectBranchReturnsOkForCompletedCollection() {
        UUID branchId = UUID.randomUUID();
        LocalDate date = COLLECTION_DATE;
        CollectRequestDto request = CollectRequestDto.builder().branchId(branchId).date(date).build();
        when(service.collectBranchData(branchId, date))
                .thenReturn(collection(branchId, DataCollectionStatus.COMPLETED, date));

        ResponseEntity<DataCollectionDto> response = controller.collectBranch(request);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getStatus()).isEqualTo(DataCollectionStatus.COMPLETED.name());
    }

    @Test
    void collectBranchReturnsServiceUnavailableForFailedCollection() {
        UUID branchId = UUID.randomUUID();
        LocalDate date = COLLECTION_DATE;
        CollectRequestDto request = CollectRequestDto.builder().branchId(branchId).date(date).build();
        when(service.collectBranchData(branchId, date))
                .thenReturn(collection(branchId, DataCollectionStatus.FAILED, date));

        ResponseEntity<DataCollectionDto> response = controller.collectBranch(request);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getStatus()).isEqualTo(DataCollectionStatus.FAILED.name());
    }

    @Test
    void collectAllReturnsOkWhenAllCollectionsCompleted() {
        UUID firstBranchId = UUID.randomUUID();
        UUID secondBranchId = UUID.randomUUID();
        LocalDate date = COLLECTION_DATE;
        CollectAllRequestDto request = CollectAllRequestDto.builder().date(date).build();
        when(service.collectAllBranches(date)).thenReturn(List.of(
                collection(firstBranchId, DataCollectionStatus.COMPLETED, date),
                collection(secondBranchId, DataCollectionStatus.COMPLETED, date)));

        ResponseEntity<List<DataCollectionDto>> response = controller.collectAll(request);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).hasSize(2);
    }

    @Test
    void collectAllReturnsServiceUnavailableWhenAnyCollectionFailed() {
        UUID okBranchId = UUID.randomUUID();
        UUID failedBranchId = UUID.randomUUID();
        LocalDate date = COLLECTION_DATE;
        CollectAllRequestDto request = CollectAllRequestDto.builder().date(date).build();
        when(service.collectAllBranches(date)).thenReturn(List.of(
                collection(okBranchId, DataCollectionStatus.COMPLETED, date),
                collection(failedBranchId, DataCollectionStatus.FAILED, date)));

        ResponseEntity<List<DataCollectionDto>> response = controller.collectAll(request);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
        assertThat(response.getBody()).hasSize(2);
    }

    @Test
    void collectAllReturnsServiceUnavailableWhenNoCollectionsReturned() {
        LocalDate date = COLLECTION_DATE;
        CollectAllRequestDto request = CollectAllRequestDto.builder().date(date).build();
        when(service.collectAllBranches(date)).thenReturn(List.of());

        ResponseEntity<List<DataCollectionDto>> response = controller.collectAll(request);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
        assertThat(response.getBody()).isEmpty();
    }

    private DataCollection collection(UUID branchId, DataCollectionStatus status, LocalDate collectionDate) {
        Branch branch = new Branch();
        branch.setId(branchId);
        return DataCollection.builder()
                .id(UUID.randomUUID())
                .branch(branch)
                .collectionDate(collectionDate)
                .collectionType(DataCollectionType.DAILY)
                .status(status)
                .build();
    }
}
