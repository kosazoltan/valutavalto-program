package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.TeaorCode;
import hu.puzzleir.valuta.repository.TeaorCodeRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Limit;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Karakterisztikus (behaviour-preserving) teszt a TEÁOR-kereséshez.
 *
 * <p>A tesztek a réteg-refaktor ELŐTTI, {@code TeaorController}-be ágyazott viselkedést
 * rögzítik: üres/blank/null keresőkifejezésre üres lista repository-hívás NÉLKÜL,
 * egyébként trim-elt kifejezés és {@code Limit.of(MAX_RESULTS)} korlát. Ezért bizonyítják,
 * hogy a use-case rétegbe (TeaorService) mozgatás nem változtatott viselkedést.
 */
@ExtendWith(MockitoExtension.class)
class TeaorServiceTest {

    @Mock
    private TeaorCodeRepository teaorCodeRepository;

    @InjectMocks
    private TeaorService teaorService;

    @Test
    @DisplayName("null keresőkifejezés -> üres lista, a repository-t meg sem hívjuk")
    void nullQueryReturnsEmptyWithoutRepositoryCall() {
        assertTrue(teaorService.search(null).isEmpty());
        verify(teaorCodeRepository, never()).search(anyString(), any(Limit.class));
    }

    @Test
    @DisplayName("üres és csak-whitespace keresőkifejezés -> üres lista, repository-hívás nélkül")
    void blankQueryReturnsEmptyWithoutRepositoryCall() {
        assertTrue(teaorService.search("").isEmpty());
        assertTrue(teaorService.search("   ").isEmpty());
        verify(teaorCodeRepository, never()).search(anyString(), any(Limit.class));
    }

    @Test
    @DisplayName("a keresőkifejezés trim-elve megy a repository-ba, MAX_RESULTS korláttal")
    void queryIsTrimmedAndLimited() {
        when(teaorCodeRepository.search(anyString(), any(Limit.class))).thenReturn(List.of());

        teaorService.search("  6612  ");

        ArgumentCaptor<String> queryCaptor = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<Limit> limitCaptor = ArgumentCaptor.forClass(Limit.class);
        verify(teaorCodeRepository).search(queryCaptor.capture(), limitCaptor.capture());

        assertEquals("6612", queryCaptor.getValue());
        assertEquals(TeaorService.MAX_RESULTS, limitCaptor.getValue().max());
    }

    @Test
    @DisplayName("a repository találatai változatlanul jutnak vissza")
    void repositoryResultIsPassedThrough() {
        TeaorCode hit = new TeaorCode();
        List<TeaorCode> expected = List.of(hit);
        when(teaorCodeRepository.search(anyString(), any(Limit.class))).thenReturn(expected);

        List<TeaorCode> actual = teaorService.search("6612");

        assertEquals(1, actual.size());
        assertSame(hit, actual.get(0));
    }
}
