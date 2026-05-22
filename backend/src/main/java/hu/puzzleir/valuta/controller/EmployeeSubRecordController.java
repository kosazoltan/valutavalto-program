package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.employee.EmployeeChildDto;
import hu.puzzleir.valuta.dto.employee.EmployeeOccupationalHealthDto;
import hu.puzzleir.valuta.dto.employee.EmployeeVacationDto;
import hu.puzzleir.valuta.service.EmployeeSubRecordService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * G19 (EXCMD b9-munkavallalo): munkavállaló al-nyilvántartások REST API —
 * üzemorvosi vizsgálat (FR-22), szabadságok (FR-19), gyerekek (FR-20).
 *
 * <p>Csak MANAGER/ADMIN (a többi employee-végponttal konzisztens). Multi-tenant
 * a service-ben.</p>
 */
@RestController
@RequestMapping("/api/v1/employees/{employeeId}")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
public class EmployeeSubRecordController {

    private final EmployeeSubRecordService service;

    // ── Üzemorvosi vizsgálat ──
    @GetMapping("/occupational-health")
    public ResponseEntity<List<EmployeeOccupationalHealthDto>> listOccupationalHealth(@PathVariable Long employeeId) {
        return ResponseEntity.ok(service.listOccupationalHealth(employeeId));
    }

    @PostMapping("/occupational-health")
    public ResponseEntity<EmployeeOccupationalHealthDto> addOccupationalHealth(
            @PathVariable Long employeeId, @RequestBody EmployeeOccupationalHealthDto dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.addOccupationalHealth(employeeId, dto));
    }

    @DeleteMapping("/occupational-health/{recordId}")
    public ResponseEntity<Void> deleteOccupationalHealth(@PathVariable Long employeeId, @PathVariable Long recordId) {
        service.deleteOccupationalHealth(employeeId, recordId);
        return ResponseEntity.noContent().build();
    }

    // ── Szabadságok ──
    @GetMapping("/vacations")
    public ResponseEntity<List<EmployeeVacationDto>> listVacations(@PathVariable Long employeeId) {
        return ResponseEntity.ok(service.listVacations(employeeId));
    }

    @PostMapping("/vacations")
    public ResponseEntity<EmployeeVacationDto> addVacation(
            @PathVariable Long employeeId, @RequestBody EmployeeVacationDto dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.addVacation(employeeId, dto));
    }

    @DeleteMapping("/vacations/{recordId}")
    public ResponseEntity<Void> deleteVacation(@PathVariable Long employeeId, @PathVariable Long recordId) {
        service.deleteVacation(employeeId, recordId);
        return ResponseEntity.noContent().build();
    }

    // ── Gyerekek ──
    @GetMapping("/children")
    public ResponseEntity<List<EmployeeChildDto>> listChildren(@PathVariable Long employeeId) {
        return ResponseEntity.ok(service.listChildren(employeeId));
    }

    @PostMapping("/children")
    public ResponseEntity<EmployeeChildDto> addChild(
            @PathVariable Long employeeId, @RequestBody EmployeeChildDto dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.addChild(employeeId, dto));
    }

    @DeleteMapping("/children/{recordId}")
    public ResponseEntity<Void> deleteChild(@PathVariable Long employeeId, @PathVariable Long recordId) {
        service.deleteChild(employeeId, recordId);
        return ResponseEntity.noContent().build();
    }
}
