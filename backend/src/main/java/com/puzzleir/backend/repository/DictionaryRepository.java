package com.puzzleir.backend.repository;

import com.puzzleir.backend.entity.Dictionary;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DictionaryRepository extends JpaRepository<Dictionary, UUID> {

    /**
     * Keresés kategória és kód szerint
     */
    Optional<Dictionary> findByCategoryAndCode(String category, String code);

    /**
     * Összes elem egy kategóriából
     */
    List<Dictionary> findByCategory(String category);

    /**
     * Aktív elemek egy kategóriából
     */
    List<Dictionary> findByCategoryAndIsActiveTrue(String category);
}
