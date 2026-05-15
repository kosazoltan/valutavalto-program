package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.repository.DictionaryRepository;
import lombok.RequiredArgsConstructor;
import lombok.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Comparator;
import java.util.List;
import java.util.UUID;

/**
 * Dictionary lookup endpoint a frontend dropdownokhoz.
 *
 * <p>BRANCH_TYPE, COUNTRY, BRANCH_STATUS és minden további dictionary kategória
 * lekérdezésére. A BranchPage admin UI bővítéséhez (HIBA #2, 2026-05-15
 * user-direktíva) szükséges.</p>
 */
@RestController
@RequestMapping("/api/v1/dictionaries")
@RequiredArgsConstructor
@PreAuthorize("isAuthenticated()")
public class DictionaryController {

    private final DictionaryRepository dictionaryRepository;

    /**
     * Dictionary entries egy adott kategóriában (csak aktívak, sortOrder szerint).
     *
     * GET /api/v1/dictionaries/{category}
     */
    @GetMapping("/{category}")
    public ResponseEntity<List<DictionaryDto>> getByCategory(@PathVariable String category) {
        List<Dictionary> entries = dictionaryRepository.findByCategoryAndIsActiveTrue(category);
        List<DictionaryDto> dtos = entries.stream()
                .sorted(Comparator.comparing(d -> d.getSortOrder() == null ? Integer.MAX_VALUE : d.getSortOrder()))
                .map(d -> new DictionaryDto(
                        d.getId(),
                        d.getCategory(),
                        d.getCode(),
                        d.getName(),
                        d.getNameHu(),
                        d.getSortOrder() == null ? 0 : d.getSortOrder()))
                .toList();
        return ResponseEntity.ok(dtos);
    }

    @Value
    public static class DictionaryDto {
        UUID id;
        String category;
        String code;
        String name;
        String nameHu;
        int sortOrder;
    }
}
