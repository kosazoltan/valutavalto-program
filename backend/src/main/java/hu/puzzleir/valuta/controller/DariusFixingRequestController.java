package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.darius.DariusBankBranchCreateDto;
import hu.puzzleir.valuta.dto.darius.DariusBankBranchDto;
import hu.puzzleir.valuta.dto.darius.DariusFixingRequestCreateDto;
import hu.puzzleir.valuta.dto.darius.DariusFixingRequestDto;
import hu.puzzleir.valuta.service.darius.DariusFixingRequestService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping({"/api/v1/darius", "/api/darius"})
@RequiredArgsConstructor
public class DariusFixingRequestController {

    private final DariusFixingRequestService service;

    @GetMapping("/bank-branches")
    @PreAuthorize("hasAnyAuthority('DARIUS_REPORT_RUN', 'MAIN_TREASURY', 'SYSTEM_ADMIN') or hasAnyRole('FOERTEKTAR', 'ADMIN')")
    public ResponseEntity<List<DariusBankBranchDto>> bankBranches(
            @RequestParam(defaultValue = "false") boolean includeInactive) {
        return ResponseEntity.ok(service.listBankBranches(includeInactive));
    }

    @PostMapping("/bank-branches")
    @PreAuthorize("hasAnyAuthority('MAIN_TREASURY', 'SYSTEM_ADMIN') or hasAnyRole('FOERTEKTAR', 'ADMIN')")
    public ResponseEntity<DariusBankBranchDto> createBankBranch(
            @RequestBody DariusBankBranchCreateDto dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.createBankBranch(dto));
    }

    @PostMapping("/bank-branches/{id}/deactivate")
    @PreAuthorize("hasAnyAuthority('MAIN_TREASURY', 'SYSTEM_ADMIN') or hasAnyRole('FOERTEKTAR', 'ADMIN')")
    public ResponseEntity<DariusBankBranchDto> deactivateBankBranch(@PathVariable UUID id) {
        return ResponseEntity.ok(service.deactivateBankBranch(id));
    }

    @GetMapping("/fixing-requests")
    @PreAuthorize("hasAnyAuthority('DARIUS_REPORT_RUN', 'MAIN_TREASURY', 'COMPLIANCE_OFFICER', 'SYSTEM_ADMIN') or hasAnyRole('FOERTEKTAR', 'BELSO_ELLENOR', 'ADMIN')")
    public ResponseEntity<List<DariusFixingRequestDto>> list(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(service.listRequests(date));
    }

    @PostMapping("/fixing-requests")
    @PreAuthorize("hasAnyAuthority('DARIUS_REPORT_RUN', 'MAIN_TREASURY', 'SYSTEM_ADMIN') or hasAnyRole('FOERTEKTAR', 'ADMIN')")
    public ResponseEntity<DariusFixingRequestDto> create(
            @RequestBody DariusFixingRequestCreateDto dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.create(dto));
    }

    @PutMapping("/fixing-requests/{id}")
    @PreAuthorize("hasAnyAuthority('DARIUS_REPORT_RUN', 'MAIN_TREASURY', 'SYSTEM_ADMIN') or hasAnyRole('FOERTEKTAR', 'ADMIN')")
    public ResponseEntity<DariusFixingRequestDto> updateLines(
            @PathVariable UUID id,
            @RequestBody DariusFixingRequestCreateDto dto) {
        return ResponseEntity.ok(service.updateLines(id, dto));
    }

    @PostMapping("/fixing-requests/{id}/approve")
    @PreAuthorize("hasAnyAuthority('DARIUS_REPORT_RUN', 'MAIN_TREASURY') or hasAnyRole('FOERTEKTAR')")
    public ResponseEntity<DariusFixingRequestDto> approve(@PathVariable UUID id) {
        return ResponseEntity.ok(service.approve(id));
    }

    @PostMapping("/fixing-requests/{id}/cancel")
    @PreAuthorize("hasAnyAuthority('DARIUS_REPORT_RUN', 'MAIN_TREASURY', 'SYSTEM_ADMIN') or hasAnyRole('FOERTEKTAR', 'ADMIN')")
    public ResponseEntity<DariusFixingRequestDto> cancel(@PathVariable UUID id) {
        return ResponseEntity.ok(service.cancel(id));
    }
}
