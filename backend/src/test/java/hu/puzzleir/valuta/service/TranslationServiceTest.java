package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.translation.TranslationDto;
import hu.puzzleir.valuta.entity.Translation;
import hu.puzzleir.valuta.repository.TranslationRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.*;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * TranslationService UNIT tesztek.
 */
@ExtendWith(MockitoExtension.class)
class TranslationServiceTest {

    @InjectMocks
    private TranslationService translationService;

    @Mock
    private TranslationRepository translationRepository;

    @Test
    @DisplayName("translate: meglévő kulcs → fordított érték")
    void testTranslate_existing() {
        Translation t = Translation.builder()
            .id(1L)
            .languageCode("hu")
            .messageKey("ui.menu.sell")
            .messageValue("Eladás")
            .module("UI")
            .build();

        when(translationRepository.findByLanguageCodeAndMessageKey("hu", "ui.menu.sell"))
            .thenReturn(Optional.of(t));

        String result = translationService.translate("ui.menu.sell", "hu");

        assertThat(result).isEqualTo("Eladás");
    }

    @Test
    @DisplayName("translate: nem létező kulcs → kulcsot adja vissza")
    void testTranslate_missing() {
        when(translationRepository.findByLanguageCodeAndMessageKey("en", "unknown.key"))
            .thenReturn(Optional.empty());

        String result = translationService.translate("unknown.key", "en");

        assertThat(result).isEqualTo("unknown.key");
    }

    @Test
    @DisplayName("getTranslations: összes fordítás Map-ben")
    void testGetTranslations() {
        List<Translation> translations = List.of(
            Translation.builder().languageCode("hu").messageKey("ui.menu.buy").messageValue("Vétel").module("UI").build(),
            Translation.builder().languageCode("hu").messageKey("ui.menu.sell").messageValue("Eladás").module("UI").build()
        );

        when(translationRepository.findByLanguageCode("hu")).thenReturn(translations);

        Map<String, String> result = translationService.getTranslations("hu");

        assertThat(result).hasSize(2);
        assertThat(result.get("ui.menu.buy")).isEqualTo("Vétel");
        assertThat(result.get("ui.menu.sell")).isEqualTo("Eladás");
    }

    @Test
    @DisplayName("importTranslations: tömeges import sikeres")
    void testImportTranslations() {
        Map<String, String> imports = Map.of(
            "ui.button.save", "Save",
            "ui.button.cancel", "Cancel"
        );

        when(translationRepository.findByLanguageCodeAndMessageKey(anyString(), anyString()))
            .thenReturn(Optional.empty());
        when(translationRepository.save(any(Translation.class)))
            .thenAnswer(inv -> inv.getArgument(0));

        int count = translationService.importTranslations("en", imports);

        assertThat(count).isEqualTo(2);
        verify(translationRepository, times(2)).save(any(Translation.class));
    }
}
