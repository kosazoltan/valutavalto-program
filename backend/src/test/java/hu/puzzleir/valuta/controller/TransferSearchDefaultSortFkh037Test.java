package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.transfer.TransferDto;
import hu.puzzleir.valuta.service.TransferService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableHandlerMethodArgumentResolver;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;

/**
 * FKH-037 FR-1 (TBD-3): a {@code GET /api/v1/transfers} alapértelmezett rendezése
 * legfrissebb-elöl: {@code transferDate DESC, transferTime DESC, createdAt DESC},
 * amikor a kliens NEM küld {@code sort=} paramétert. A rendezés a controller
 * {@code @PageableDefault} annotációjából jön — JPQL ORDER BY szándékosan NINCS
 * (a Spring Data a Pageable sortját fűzné a lekérdezéshez; kettő ütközne).
 *
 * <p>Szándékosan Mockito-only + standalone MockMvc: nincs Spring-kontextus, nincs
 * {@code @EnableJpaAuditing}, nincs adatbázis. A Pageable a service-határon
 * elfogva — ez a "repo legfrissebb-elöl rendezéssel hívódik" őszinte megfigyelhetője.
 */
@ExtendWith(MockitoExtension.class)
class TransferSearchDefaultSortFkh037Test {

    private MockMvc mockMvc;

    @Mock private TransferService transferService;

    @InjectMocks private TransferController controller;

    @BeforeEach
    void setUp() {
        // A PageableHandlerMethodArgumentResolver NEM része a puszta standaloneSetup-nak —
        // regisztrálni kell, különben a Pageable-paraméter nem kötődik és a teszt értelmetlen.
        mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setCustomArgumentResolvers(new PageableHandlerMethodArgumentResolver())
                .build();
    }

    @Test
    void unsortedSearchGetsNewestFirstDefaultSort() throws Exception {
        when(transferService.search(any(), any(), any(), any(), any(), any()))
                .thenReturn(new PageImpl<>(List.<TransferDto>of()));

        mockMvc.perform(get("/api/v1/transfers").param("page", "0").param("size", "50"));

        ArgumentCaptor<Pageable> captor = ArgumentCaptor.forClass(Pageable.class);
        verify(transferService).search(any(), any(), any(), any(), any(), captor.capture());
        assertThat(captor.getValue().getSort()).containsExactly(
                Sort.Order.desc("transferDate"),
                Sort.Order.desc("transferTime"),
                Sort.Order.desc("createdAt"));
    }

    @Test
    void explicitClientSortStillWinsOverTheDefault() throws Exception {
        when(transferService.search(any(), any(), any(), any(), any(), any()))
                .thenReturn(new PageImpl<>(List.<TransferDto>of()));

        mockMvc.perform(get("/api/v1/transfers")
                .param("page", "0")
                .param("size", "50")
                .param("sort", "amount,asc"));

        ArgumentCaptor<Pageable> captor = ArgumentCaptor.forClass(Pageable.class);
        verify(transferService).search(any(), any(), any(), any(), any(), captor.capture());
        assertThat(captor.getValue().getSort()).containsExactly(Sort.Order.asc("amount"));
    }
}
