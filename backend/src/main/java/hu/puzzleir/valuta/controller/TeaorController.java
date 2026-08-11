package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.TeaorService;
import lombok.RequiredArgsConstructor;
import lombok.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * TEÁOR'08 tevékenységi kód kereső endpoint (legacy: teaorvalasztas / TEAORTABLA).
 *
 * <p>A jogi-személy ügyfél tevékenységi kódjának typeahead-kiválasztásához.</p>
 *
 * <p>A keresés a {@link TeaorService} use-case rétegében fut (tranzakcióhatár);
 * a controller feladata csak a HTTP-adaptáció és az entitás → DTO leképezés,
 * hogy a JPA-entitás ne szivárogjon ki az API-határon.</p>
 */
@RestController
@RequestMapping("/api/v1/teaor")
@RequiredArgsConstructor
@PreAuthorize("isAuthenticated()")
public class TeaorController {

    private final TeaorService teaorService;

    /**
     * TEÁOR-kód keresés kód-prefix vagy megnevezés alapján.
     *
     * GET /api/v1/teaor?q=6612
     */
    @GetMapping
    public ResponseEntity<List<TeaorDto>> search(@RequestParam(name = "q", required = false) String q) {
        List<TeaorDto> dtos = teaorService.search(q).stream()
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
