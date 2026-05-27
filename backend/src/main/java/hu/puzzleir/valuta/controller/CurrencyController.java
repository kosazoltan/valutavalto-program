package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.currency.CurrencyDto;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.service.AdminCurrencyService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Valuta controller - valuták listázása
 *
 * FK-006 / Codex P1 #876: a /rates nézet (és más árfolyam-felületek) a GET /currencies-t is
 * lekéri a valutalistához — ezért az olvasó (GET) végpontok ugyanazon szerepköröknek elérhetők,
 * mint az árfolyam-olvasás (ExchangeRateController RATE_READ_ROLES), különben a FOERTEKTAR/
 * UGYVEZETO/ERTEKTAR/PENZTAR 403-at kapna a valutalistára. A POST/PATCH (admin) végpontok a saját,
 * szigorúbb method-level @PreAuthorize-jukat tartják meg.
 */
@PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN', 'PENZTAR', 'ERTEKTAR', 'FOERTEKTAR', 'UGYVEZETO')")
@RestController
@RequestMapping("/api/v1/currencies")
@RequiredArgsConstructor
public class CurrencyController {

    private final CurrencyRepository currencyRepository;
    private final AdminCurrencyService adminCurrencyService;

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

    // ============ V238 (2026-05-19): Currency admin endpoints — auditalt ============

    /**
     * Uj valuta hozzaadasa (admin / foertekitaros / ugyvezeto). NEM duplikalhato.
     *
     * <p>POST /api/v1/currencies</p>
     */
    @PostMapping
    // 2026-05-24 fix: a Valutakezelőt a FŐÉRTÉKTÁROS használja az árfolyamkészítőben (a Javadoc
    // és a frontend canWriteRateCreation = foertektar/ugyvezeto/admin szerint), de a backend eddig
    // csak ADMIN/MANAGER-t engedett → 403 a főértéktárosnak (létrehozási hiba). A rate-maker
    // konvencióval (LocalRateMakerController) összhangba hozva.
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<CurrencyDto> createCurrency(@Valid @RequestBody CreateCurrencyRequest req) {
        Currency saved = adminCurrencyService.createCurrency(
                req.getCode(),
                req.getName(),
                req.getSymbol(),
                req.getDecimalPlaces(),
                req.getDisplayOrder()
        );
        return ResponseEntity.ok(toDto(saved));
    }

    /**
     * Valuta aktivalas vagy deaktivalas. NEM DELETE — Pmt./NAV 8-eves megorzes.
     *
     * <p>PATCH /api/v1/currencies/{id}/active</p>
     */
    @PatchMapping("/{id}/active")
    // 2026-05-24 fix: aktiválás/inaktiválás is a főértéktáros joga (rate-maker) → FOERTEKTAR/UGYVEZETO.
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<CurrencyDto> setActive(
            @PathVariable Long id,
            @Valid @RequestBody SetActiveRequest req) {
        Currency saved = adminCurrencyService.setActive(id, req.isActive(), req.getNote());
        return ResponseEntity.ok(toDto(saved));
    }

    // ============ Request DTO-k ============

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreateCurrencyRequest {
        @NotNull
        @Pattern(regexp = "^[A-Za-z0-9]{3,10}$",
                message = "Valuta kod 3-10 alfanumerikus karakter")
        private String code;

        @NotNull
        @Size(min = 1, max = 200)
        private String name;

        @Size(max = 10)
        private String symbol;

        private Integer decimalPlaces;
        private Integer displayOrder;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SetActiveRequest {
        private boolean active;
        @Size(max = 500)
        private String note;
    }
}
