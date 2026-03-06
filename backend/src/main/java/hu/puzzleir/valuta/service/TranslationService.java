package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.translation.TranslationDto;
import hu.puzzleir.valuta.entity.Translation;
import hu.puzzleir.valuta.repository.TranslationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Többnyelvűség (i18n) szolgáltatás.
 *
 * A rendszer alapból magyar. A bizonylatok, kijelzők, riportok
 * angol és német nyelvre is fordíthatók.
 */
@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class TranslationService {

    private final TranslationRepository translationRepository;

    /**
     * Egyedi kulcs fordítása adott nyelvre.
     * Ha nincs fordítás, a kulcsot adja vissza.
     */
    @Transactional(readOnly = true)
    public String translate(String key, String languageCode) {
        if (key == null || languageCode == null) return key;

        Optional<Translation> translation = translationRepository
            .findByLanguageCodeAndMessageKey(languageCode, key);
        return translation.map(Translation::getMessageValue).orElse(key);
    }

    /**
     * Összes fordítás lekérése adott nyelvre (Map<key, value>).
     */
    @Transactional(readOnly = true)
    public Map<String, String> getTranslations(String languageCode) {
        return translationRepository.findByLanguageCode(languageCode).stream()
            .collect(Collectors.toMap(
                Translation::getMessageKey,
                Translation::getMessageValue,
                (a, b) -> b // ha duplikáció van, az utolsót vesszük
            ));
    }

    /**
     * Fordítások lekérése modul szerint (RECEIPT/UI/REPORT/DISPLAY).
     */
    @Transactional(readOnly = true)
    public Map<String, String> getTranslationsByModule(String languageCode, String module) {
        return translationRepository.findByLanguageCodeAndModule(languageCode, module).stream()
            .collect(Collectors.toMap(
                Translation::getMessageKey,
                Translation::getMessageValue,
                (a, b) -> b
            ));
    }

    /**
     * Egyedi fordítás mentése/frissítése.
     */
    public Translation saveTranslation(TranslationDto dto) {
        Optional<Translation> existing = translationRepository
            .findByLanguageCodeAndMessageKey(dto.getLanguageCode(), dto.getMessageKey());

        Translation translation;
        if (existing.isPresent()) {
            translation = existing.get();
            translation.setMessageValue(dto.getMessageValue());
            translation.setModule(dto.getModule());
            log.info("Fordítás frissítve: {}:{} ({})", dto.getLanguageCode(), dto.getMessageKey(), dto.getModule());
        } else {
            translation = Translation.builder()
                .languageCode(dto.getLanguageCode())
                .messageKey(dto.getMessageKey())
                .messageValue(dto.getMessageValue())
                .module(dto.getModule())
                .build();
            log.info("Új fordítás: {}:{} ({})", dto.getLanguageCode(), dto.getMessageKey(), dto.getModule());
        }

        return translationRepository.save(translation);
    }

    /**
     * Tömeges fordítás import.
     *
     * @param languageCode nyelv kód (hu/en/de)
     * @param translations Map<kulcs, érték>
     * @return importált rekordok száma
     */
    public int importTranslations(String languageCode, Map<String, String> translations) {
        int count = 0;
        for (Map.Entry<String, String> entry : translations.entrySet()) {
            TranslationDto dto = TranslationDto.builder()
                .languageCode(languageCode)
                .messageKey(entry.getKey())
                .messageValue(entry.getValue())
                .module("UI") // default modul import-nál
                .build();
            saveTranslation(dto);
            count++;
        }
        log.info("Fordítás import kész: {} nyelv, {} rekord", languageCode, count);
        return count;
    }
}
