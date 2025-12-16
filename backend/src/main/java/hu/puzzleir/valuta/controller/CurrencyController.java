package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.currency.CurrencyDto;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Valuta controller - valuták listázása
 */
@RestController
@RequestMapping("/api/v1/currencies")
@RequiredArgsConstructor
public class CurrencyController {

    private final CurrencyRepository currencyRepository;

    /**
     * Összes aktív valuta
     *
     * GET /api/v1/currencies
     */
    @GetMapping
    public ResponseEntity<List<CurrencyDto>> getAllActiveCurrencies() {
        List<Currency> currencies = currencyRepository.findAllActiveOrdered();
        List<CurrencyDto> dtos = currencies.stream()
                .map(this::toDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    /**
     * Összes valuta (aktív és inaktív)
     *
     * GET /api/v1/currencies/all
     */
    @GetMapping("/all")
    public ResponseEntity<List<CurrencyDto>> getAllCurrencies() {
        List<Currency> currencies = currencyRepository.findAllByOrderByDisplayOrderAsc();
        List<CurrencyDto> dtos = currencies.stream()
                .map(this::toDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    /**
     * Valuta keresése kód alapján
     *
     * GET /api/v1/currencies/code/{code}
     */
    @GetMapping("/code/{code}")
    public ResponseEntity<CurrencyDto> getCurrencyByCode(@PathVariable String code) {
        return currencyRepository.findByCode(code.toUpperCase())
                .map(this::toDto)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * Valuta keresése ID alapján
     *
     * GET /api/v1/currencies/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<CurrencyDto> getCurrencyById(@PathVariable Long id) {
        return currencyRepository.findById(id)
                .map(this::toDto)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * Valuta keresése (név vagy kód részlet)
     *
     * GET /api/v1/currencies/search?q=...
     */
    @GetMapping("/search")
    public ResponseEntity<List<CurrencyDto>> searchCurrencies(@RequestParam String q) {
        List<Currency> currencies = currencyRepository.searchByCodeOrName(q);
        List<CurrencyDto> dtos = currencies.stream()
                .map(this::toDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    private CurrencyDto toDto(Currency entity) {
        return CurrencyDto.builder()
                .id(entity.getId())
                .code(entity.getCode())
                .name(entity.getName())
                .symbol(entity.getSymbol())
                .decimals(entity.getDecimalPlaces())
                .displayOrder(entity.getDisplayOrder())
                .active(entity.getActive())
                .build();
    }
}
