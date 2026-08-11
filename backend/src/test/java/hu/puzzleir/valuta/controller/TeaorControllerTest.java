package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.TeaorCode;
import hu.puzzleir.valuta.repository.TeaorCodeRepository;
import hu.puzzleir.valuta.service.TeaorService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Limit;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

/**
 * N2 (legacy TEAORTABLA) — TEÁOR kereső endpoint tesztjei.
 *
 * <p><b>Réteg-refaktor (2026-08-11).</b> A repository-hozzáférés a
 * {@link TeaorService} use-case rétegébe került (Clean Architecture függőségi
 * szabály: a controller nem injektál repository-t). <b>Az assertek változatlanok</b>:
 * a teszt a VALÓDI service-t példányosítja ugyanazzal a mockolt repository-val,
 * ezért továbbra is a végponti viselkedést bizonyítja — üres/null query nem hív
 * repository-t, a query trimmelve megy tovább, a találat DTO-ra mappelődik.
 */
@ExtendWith(MockitoExtension.class)
class TeaorControllerTest {

    @Mock private TeaorCodeRepository repository;
    private TeaorController controller;

    @BeforeEach
    void setUp() {
        controller = new TeaorController(new TeaorService(repository));
    }

    @Test
    @DisplayName("search — üres query nem hív repository-t, üres listát ad")
    void testBlankQueryShortCircuits() {
        var result = controller.search("   ");

        assertThat(result.getBody()).isEmpty();
        verifyNoInteractions(repository);
    }

    @Test
    @DisplayName("search — null query üres listát ad")
    void testNullQuery() {
        var result = controller.search(null);
        assertThat(result.getBody()).isEmpty();
        verifyNoInteractions(repository);
    }

    @Test
    @DisplayName("search — talált TEÁOR kódokat DTO-ra mappeli")
    void testSearchMapsToDto() {
        when(repository.search(eq("661"), any(Limit.class))).thenReturn(List.of(
                TeaorCode.builder().code("6611").name("Pénz-, tőkepiac igazgatása").build(),
                TeaorCode.builder().code("6612").name("Értékpapír-, árutőzsdei ügynöki tevékenység").build()));

        var result = controller.search("661");

        assertThat(result.getBody()).hasSize(2);
        assertThat(result.getBody().get(0).getCode()).isEqualTo("6611");
        assertThat(result.getBody().get(1).getName()).contains("Értékpapír");
    }

    @Test
    @DisplayName("search — a query trimmelve megy a repository-ba")
    void testQueryTrimmed() {
        when(repository.search(eq("6612"), any(Limit.class))).thenReturn(List.of());

        controller.search("  6612  ");

        verify(repository).search(eq("6612"), any(Limit.class));
    }
}
