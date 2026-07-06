package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Circular;
import hu.puzzleir.valuta.entity.CircularAcknowledgment;
import hu.puzzleir.valuta.entity.CircularReply;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.dto.circular.CircularReplyDto;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CircularAcknowledgmentRepository;
import hu.puzzleir.valuta.repository.CircularReplyRepository;
import hu.puzzleir.valuta.repository.CircularRepository;
import hu.puzzleir.valuta.repository.CircularSequenceRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * CircularService unit tesztek — G21 szerepkörönkénti visszaigazolás-megoszlás.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class CircularServiceTest {

    @Mock private CircularRepository circularRepository;
    @Mock private CircularAcknowledgmentRepository acknowledgmentRepository;
    @Mock private CircularReplyRepository replyRepository;
    @Mock private CircularSequenceRepository sequenceRepository;
    @Mock private WorkerRepository workerRepository;

    @InjectMocks private CircularService service;

    @BeforeEach
    void setUpSecurityContext() {
        // IDOR-guard (audit 2026-06-15): findOrThrow most findByIdAndCompanyId-t hív → auth-kontextus kell.
        WorkerAuthenticationDetails details =
                new WorkerAuthenticationDetails(1L, UUID.randomUUID(), UUID.randomUUID(), "ADMIN");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("t", "x", "ROLE_ADMIN");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @Test
    @DisplayName("G21: getAcknowledgmentBreakdownByRole — szerepkörönként csoportosít, null → ISMERETLEN")
    void breakdownByRole_groupsAndHandlesNull() {
        Circular circular = new Circular();
        circular.setId(1L);
        when(circularRepository.findByIdAndCompanyId(eq(1L), any())).thenReturn(Optional.of(circular));

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
        when(circularRepository.findByIdAndCompanyId(eq(2L), any())).thenReturn(Optional.of(circular));
        when(acknowledgmentRepository.findByCircularId(2L)).thenReturn(List.of());

        assertThat(service.getAcknowledgmentBreakdownByRole(2L)).isEmpty();
    }

    @Test
    @DisplayName("FS-C: reply — allowsReply=true körlevélre menti a választ tenant/worker bélyeggel")
    void reply_savesWithTenantStamp() {
        Circular circular = Circular.builder().id(10L).allowsReply(true).build();
        when(circularRepository.findByIdAndCompanyId(eq(10L), any())).thenReturn(Optional.of(circular));
        when(replyRepository.save(any(CircularReply.class)))
                .thenAnswer(inv -> { CircularReply r = inv.getArgument(0); r.setId(99L); return r; });

        CircularReplyDto dto = service.reply(10L, "  Értettem, intézkedem.  ");

        ArgumentCaptor<CircularReply> captor = ArgumentCaptor.forClass(CircularReply.class);
        verify(replyRepository).save(captor.capture());
        CircularReply saved = captor.getValue();
        assertThat(saved.getWorkerId()).isEqualTo(1L);
        assertThat(saved.getCompanyId()).isNotNull();
        assertThat(saved.getReplyText()).isEqualTo("Értettem, intézkedem.");
        assertThat(saved.getCreatedAt()).isNotNull();
        assertThat(dto.getId()).isEqualTo(99L);
        assertThat(dto.getCircularId()).isEqualTo(10L);
    }

    @Test
    @DisplayName("FS-C: reply — allowsReply=false (régi körlevél) → ValidationException, nincs mentés")
    void reply_rejectedWhenNotAllowed() {
        Circular circular = Circular.builder().id(11L).build();
        when(circularRepository.findByIdAndCompanyId(eq(11L), any())).thenReturn(Optional.of(circular));

        assertThatThrownBy(() -> service.reply(11L, "válasz"))
                .isInstanceOf(ValidationException.class);
        verify(replyRepository, never()).save(any());
    }

    @Test
    @DisplayName("FS-C: reply — más cég körlevele (findByIdAndCompanyId üres) → 404")
    void reply_crossTenantIs404() {
        when(circularRepository.findByIdAndCompanyId(eq(12L), any())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.reply(12L, "válasz"))
                .isInstanceOf(ResourceNotFoundException.class);
        verify(replyRepository, never()).save(any());
    }

    @Test
    @DisplayName("FS-C: reply — blank szöveg → ValidationException")
    void reply_blankRejected() {
        Circular circular = Circular.builder().id(13L).allowsReply(true).build();
        when(circularRepository.findByIdAndCompanyId(eq(13L), any())).thenReturn(Optional.of(circular));

        assertThatThrownBy(() -> service.reply(13L, "   "))
                .isInstanceOf(ValidationException.class);
        verify(replyRepository, never()).save(any());
    }

    @Test
    @DisplayName("FS-C: getReplies — cég-szűrt lista, workerName feloldva")
    void getReplies_companyScoped() {
        Circular circular = Circular.builder().id(14L).allowsReply(true).build();
        when(circularRepository.findByIdAndCompanyId(eq(14L), any())).thenReturn(Optional.of(circular));
        CircularReply r = CircularReply.builder().id(1L).circular(circular).workerId(7L)
                .companyId(UUID.randomUUID()).replyText("ok")
                .createdAt(java.time.LocalDateTime.now()).build();
        when(replyRepository.findByCircularIdAndCompanyId(eq(14L), any())).thenReturn(List.of(r));
        Worker w = new Worker();
        w.setId(7L);
        w.setName("Teszt Elek");
        when(workerRepository.findById(7L)).thenReturn(Optional.of(w));

        List<CircularReplyDto> replies = service.getReplies(14L);

        assertThat(replies).hasSize(1);
        assertThat(replies.get(0).getWorkerName()).isEqualTo("Teszt Elek");
        verify(replyRepository).findByCircularIdAndCompanyId(eq(14L), any());
    }
}
