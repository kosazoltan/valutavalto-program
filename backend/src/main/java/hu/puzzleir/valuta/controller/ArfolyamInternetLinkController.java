package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.ArfolyamInternetLink;
import hu.puzzleir.valuta.service.ArfolyamInternetLinkService;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Árfolyamkészítő internet-link endpoint (legacy ARFOLYAM / TINTERNETTMKFORM).
 */
@RestController
@RequestMapping("/api/v1/arfolyam-internet-links")
@RequiredArgsConstructor
@PreAuthorize("isAuthenticated()")
public class ArfolyamInternetLinkController {

    private final ArfolyamInternetLinkService service;

    @GetMapping
    public ResponseEntity<List<Dto>> list() {
        List<Dto> dtos = service.list().stream()
                .map(l -> new Dto(l.getId(), l.getButtonNumber(), l.getLabel(), l.getUrl()))
                .toList();
        return ResponseEntity.ok(dtos);
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('SUPERVISOR','MANAGER','ADMIN')")
    public ResponseEntity<Dto> create(@RequestBody CreateRequest req) {
        ArfolyamInternetLink l = service.create(req.getButtonNumber(), req.getLabel(), req.getUrl());
        return ResponseEntity.ok(new Dto(l.getId(), l.getButtonNumber(), l.getLabel(), l.getUrl()));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('SUPERVISOR','MANAGER','ADMIN')")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }

    @Value
    public static class Dto {
        UUID id;
        Integer buttonNumber;
        String label;
        String url;
    }

    @Data
    public static class CreateRequest {
        @NotNull
        private Integer buttonNumber;
        @NotBlank
        private String label;
        @NotBlank
        private String url;
    }
}
