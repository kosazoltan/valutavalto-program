package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.TeaorCode;
import hu.puzzleir.valuta.repository.TeaorCodeRepository;
import lombok.RequiredArgsConstructor;
import lombok.Value;
import org.springframework.data.domain.Limit;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * TEÁOR'08 tevékenységi kód kereső endpoint (legacy: teaorvalasztas / TEAORTABLA).
 *
 * <p>A jogi-személy ügyfél tevékenységi kódjának typeahead-kiválasztásához.</p>
 */
@RestController
@RequestMapping("/api/v1/teaor")
@RequiredArgsConstructor
@PreAuthorize("isAuthenticated()")
public class TeaorController {

    private static final int MAX_RESULTS = 20;

    private final TeaorCodeRepository teaorCodeRepository;

    /**
     * TEÁOR-kód keresés kód-prefix vagy megnevezés alapján.
     *
     * GET /api/v1/teaor?q=6612
     */
    @GetMapping
    public ResponseEntity<List<TeaorDto>> search(@RequestParam(name = "q", required = false) String q) {
        if (q == null || q.isBlank()) {
            return ResponseEntity.ok(List.of());
        }
        List<TeaorDto> dtos = teaorCodeRepository.search(q.trim(), Limit.of(MAX_RESULTS)).stream()
                .map(t -> new TeaorDto(t.getCode(), t.getName()))
                .toList();
        return ResponseEntity.ok(dtos);
    }

    @Value
    public static class TeaorDto {
        String code;
        String name;
    }
}
