package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Circular;
import hu.puzzleir.valuta.entity.CircularAcknowledgment;
import hu.puzzleir.valuta.repository.CircularAcknowledgmentRepository;
import hu.puzzleir.valuta.repository.CircularRepository;
import hu.puzzleir.valuta.repository.CircularSequenceRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

/**
 * CircularService unit tesztek — G21 szerepkörönkénti visszaigazolás-megoszlás.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class CircularServiceTest {

    @Mock private CircularRepository circularRepository;
    @Mock private CircularAcknowledgmentRepository acknowledgmentRepository;
    @Mock private CircularSequenceRepository sequenceRepository;
    @Mock private WorkerRepository workerRepository;

    @InjectMocks private CircularService service;

    @Test
    @DisplayName("G21: getAcknowledgmentBreakdownByRole — szerepkörönként csoportosít, null → ISMERETLEN")
    void breakdownByRole_groupsAndHandlesNull() {
        Circular circular = new Circular();
        circular.setId(1L);
        when(circularRepository.findById(1L)).thenReturn(Optional.of(circular));

        CircularAcknowledgment a1 = CircularAcknowledgment.builder().acknowledgerRole("PENZTAROS").build();
        CircularAcknowledgment a2 = CircularAcknowledgment.builder().acknowledgerRole("PENZTAROS").build();
        CircularAcknowledgment a3 = CircularAcknowledgment.builder().acknowledgerRole("BELSO_ELLENOR").build();
        CircularAcknowledgment a4 = CircularAcknowledgment.builder().acknowledgerRole(null).build(); // régi sor
        when(acknowledgmentRepository.findByCircularId(1L)).thenReturn(List.of(a1, a2, a3, a4));

        Map<String, Long> breakdown = service.getAcknowledgmentBreakdownByRole(1L);

        assertThat(breakdown).containsEntry("PENZTAROS", 2L);
        assertThat(breakdown).containsEntry("BELSO_ELLENOR", 1L);
        assertThat(breakdown).containsEntry("ISMERETLEN", 1L);
    }

    @Test
    @DisplayName("G21: üres nyugtázás-lista → üres megoszlás")
    void breakdownByRole_empty() {
        Circular circular = new Circular();
        circular.setId(2L);
        when(circularRepository.findById(2L)).thenReturn(Optional.of(circular));
        when(acknowledgmentRepository.findByCircularId(2L)).thenReturn(List.of());

        assertThat(service.getAcknowledgmentBreakdownByRole(2L)).isEmpty();
    }
}
