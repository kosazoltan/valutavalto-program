package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Translation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TranslationRepository extends JpaRepository<Translation, Long> {

    List<Translation> findByLanguageCode(String languageCode);

    List<Translation> findByLanguageCodeAndModule(String languageCode, String module);

    Optional<Translation> findByLanguageCodeAndMessageKey(String languageCode, String messageKey);
}
