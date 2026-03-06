package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.packaging.CreatePackagingRecordDto;
import hu.puzzleir.valuta.dto.packaging.PackagingRecordDto;
import hu.puzzleir.valuta.service.PackagingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Göngyöleg kezelés REST végpontok.
 */
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
@RestController
@RequestMapping("/api/v1/packaging")
@RequiredArgsConstructor
public class PackagingController {

    private final PackagingService packagingService;

    @PostMapping
    public ResponseEntity<PackagingRecordDto> create(@Valid @RequestBody CreatePackagingRecordDto dto) {
        return ResponseEntity.ok(packagingService.create(dto));
    }

    @GetMapping
    public ResponseEntity<List<PackagingRecordDto>> list(
            @RequestParam UUID branchId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ResponseEntity.ok(packagingService.getByBranch(branchId, from, to));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        packagingService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
