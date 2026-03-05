package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.ProhibitedCompany;
import hu.puzzleir.valuta.entity.ProhibitedPerson;
import hu.puzzleir.valuta.service.BlacklistService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/blacklist")
@RequiredArgsConstructor
public class BlacklistController {

    private final BlacklistService service;

    // --- Persons ---

    @GetMapping("/persons")
    public ResponseEntity<List<ProhibitedPerson>> listPersons() {
        return ResponseEntity.ok(service.listPersons());
    }

    @PostMapping("/persons")
    public ResponseEntity<ProhibitedPerson> createPerson(@RequestBody ProhibitedPerson entity) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.createPerson(entity));
    }

    @PutMapping("/persons/{id}")
    public ResponseEntity<ProhibitedPerson> updatePerson(@PathVariable UUID id, @RequestBody ProhibitedPerson entity) {
        return ResponseEntity.ok(service.updatePerson(id, entity));
    }

    @DeleteMapping("/persons/{id}")
    public ResponseEntity<Void> deletePerson(@PathVariable UUID id) {
        service.deletePerson(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping(value = "/persons/import", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<List<ProhibitedPerson>> importPersons(@RequestParam("file") MultipartFile file) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.importPersonsCsv(file));
    }

    // --- Companies ---

    @GetMapping("/companies")
    public ResponseEntity<List<ProhibitedCompany>> listCompanies() {
        return ResponseEntity.ok(service.listCompanies());
    }

    @PostMapping("/companies")
    public ResponseEntity<ProhibitedCompany> createCompany(@RequestBody ProhibitedCompany entity) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.createCompany(entity));
    }

    @PutMapping("/companies/{id}")
    public ResponseEntity<ProhibitedCompany> updateCompany(@PathVariable UUID id, @RequestBody ProhibitedCompany entity) {
        return ResponseEntity.ok(service.updateCompany(id, entity));
    }

    @DeleteMapping("/companies/{id}")
    public ResponseEntity<Void> deleteCompany(@PathVariable UUID id) {
        service.deleteCompany(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping(value = "/companies/import", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<List<ProhibitedCompany>> importCompanies(@RequestParam("file") MultipartFile file) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.importCompaniesCsv(file));
    }
}
