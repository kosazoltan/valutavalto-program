package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.CameraRecording;
import hu.puzzleir.valuta.entity.CameraTransactionLink;
import hu.puzzleir.valuta.repository.CameraRecordingRepository;
import hu.puzzleir.valuta.repository.CameraTransactionLinkRepository;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CameraTransactionLinkerTest {

    @Mock
    private CameraRecordingRepository recordingRepository;

    @Mock
    private CameraTransactionLinkRepository linkRepository;

    @InjectMocks
    private CameraTransactionLinker linker;

    @Test
    void linkTransaction_acceptsLegacyLongTransactionId() {
        UUID branchId = UUID.randomUUID();
        LocalDateTime txTime = LocalDateTime.of(2026, 3, 21, 12, 0);

        CameraRecording recording = CameraRecording.builder()
                .id(UUID.randomUUID())
                .branchId(branchId)
                .cameraId("cam1")
                .startTime(txTime.minusMinutes(1))
                .endTime(txTime.plusMinutes(1))
                .build();

        when(recordingRepository.findByBranchIdAndStartTimeBetween(any(), any(), any()))
                .thenReturn(List.of(recording));
        when(linkRepository.save(any(CameraTransactionLink.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        linker.linkTransaction(42L, branchId, txTime, "V00042");

        ArgumentCaptor<CameraTransactionLink> captor = ArgumentCaptor.forClass(CameraTransactionLink.class);
        verify(linkRepository).save(captor.capture());

        assertThat(captor.getValue().getTransactionId()).isEqualTo(42L);
        assertThat(captor.getValue().getReceiptNumber()).isEqualTo("V00042");
    }
}
