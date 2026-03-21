package hu.puzzleir.valuta.service.wu;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.SystemParameterRepository;
import hu.puzzleir.valuta.repository.WuTransactionRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.WesternUnionService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class InternalWesternUnionAdapterTest {

    @Mock
    private WesternUnionService westernUnionService;
    @Mock
    private WuTransactionRepository wuTransactionRepository;
    @Mock
    private SystemParameterRepository systemParameterRepository;

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("status not-found hibaüzenet nem szivárogtat teljes MTCN-t")
    void status_notFound_doesNotLeakMtcn() {
        UUID companyId = UUID.randomUUID();
        UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken("tester", "n/a");
        auth.setDetails(new WorkerAuthenticationDetails(1L, companyId, UUID.randomUUID(), "ADMIN"));
        SecurityContextHolder.getContext().setAuthentication(auth);

        String mtcn = "1234567890";
        when(wuTransactionRepository.findFirstByMtcnAndCompanyIdOrderByTransactionDateDesc(eq(mtcn), eq(companyId)))
                .thenReturn(Optional.empty());

        InternalWesternUnionAdapter adapter = new InternalWesternUnionAdapter(
                westernUnionService,
                wuTransactionRepository,
                systemParameterRepository
        );

        assertThatThrownBy(() -> adapter.status(mtcn))
                .isInstanceOfSatisfying(ResourceNotFoundException.class, ex -> {
                    assertThat(ex.getMessage()).contains("WU tranzakció nem található MTCN alapján");
                    assertThat(ex.getMessage()).doesNotContain(mtcn);
                });
    }
}
