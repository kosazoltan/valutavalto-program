package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.customer.CreateCustomerDto;
import hu.puzzleir.valuta.dto.customer.CustomerDto;
import hu.puzzleir.valuta.dto.customer.CustomerRankingDto;
import hu.puzzleir.valuta.dto.customer.CustomerStatsDto;
import hu.puzzleir.valuta.dto.customer.MergeCustomersDto;
import hu.puzzleir.valuta.entity.Customer;
import hu.puzzleir.valuta.mapper.CustomerMapper;
import hu.puzzleir.valuta.service.CustomerService;
import hu.puzzleir.valuta.service.CustomerStatisticsService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Ügyfél controller
 *
 * Legacy: ADATLAP tábla kezelés
 */
@RestController
@RequestMapping("/api/v1/customers")
@RequiredArgsConstructor
public class CustomerController {

    private final CustomerService customerService;
    private final CustomerMapper customerMapper;
    private final CustomerStatisticsService customerStatisticsService;

    /**
     * Új ügyfél létrehozása
     *
     * POST /api/v1/customers
     */
    @PostMapping
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<CustomerDto> createCustomer(@Valid @RequestBody CreateCustomerDto dto) {
        Customer customer = customerService.createCustomer(customerMapper.toCreateRequest(dto));
        return ResponseEntity.status(HttpStatus.CREATED).body(customerMapper.toDto(customer));
    }

    /**
     * Ügyfél módosítása
     *
     * PUT /api/v1/customers/{id}
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<CustomerDto> updateCustomer(
            @PathVariable Long id,
            @Valid @RequestBody CreateCustomerDto dto) {
        Customer customer = customerService.updateCustomer(id, customerMapper.toUpdateRequest(dto));
        return ResponseEntity.ok(customerMapper.toDto(customer));
    }

    /**
     * Ügyfél lekérdezése ID alapján
     *
     * GET /api/v1/customers/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<CustomerDto> getCustomerById(@PathVariable Long id) {
        Customer customer = customerService.findById(id);
        return ResponseEntity.ok(customerMapper.toDto(customer));
    }

    /**
     * Ügyfél keresése dokumentum szám alapján
     *
     * GET /api/v1/customers/document/{documentNumber}
     */
    @GetMapping("/document/{documentNumber}")
    public ResponseEntity<CustomerDto> getCustomerByDocumentNumber(@PathVariable String documentNumber) {
        Customer customer = customerService.findByDocumentNumber(documentNumber);
        return ResponseEntity.ok(customerMapper.toDto(customer));
    }

    /**
     * Ügyfél keresése ügyfélkód alapján
     *
     * GET /api/v1/customers/code/{customerCode}
     */
    @GetMapping("/code/{customerCode}")
    public ResponseEntity<CustomerDto> getCustomerByCode(@PathVariable String customerCode) {
        Customer customer = customerService.findByCustomerCode(customerCode);
        return ResponseEntity.ok(customerMapper.toDto(customer));
    }

    /**
     * Ügyfelek keresése név alapján
     *
     * GET /api/v1/customers/search?name=...
     */
    @GetMapping("/search")
    public ResponseEntity<List<CustomerDto>> searchCustomers(@RequestParam String name) {
        List<Customer> customers = customerService.searchByName(name);
        List<CustomerDto> dtos = customers.stream()
                .map(customerMapper::toDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    /**
     * VIP ügyfelek
     *
     * GET /api/v1/customers/vip
     */
    @GetMapping("/vip")
    public ResponseEntity<List<CustomerDto>> getVipCustomers() {
        List<Customer> customers = customerService.getVipCustomers();
        List<CustomerDto> dtos = customers.stream()
                .map(customerMapper::toDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    /**
     * Aktív ügyfelek
     *
     * GET /api/v1/customers/active
     */
    @GetMapping("/active")
    public ResponseEntity<List<CustomerDto>> getActiveCustomers() {
        List<Customer> customers = customerService.getActiveCustomers();
        List<CustomerDto> dtos = customers.stream()
                .map(customerMapper::toDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    /**
     * Ügyfél inaktiválása
     *
     * POST /api/v1/customers/{id}/deactivate
     */
    @PostMapping("/{id}/deactivate")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Void> deactivateCustomer(@PathVariable Long id) {
        customerService.deactivateCustomer(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * Ügyfél aktiválása
     *
     * POST /api/v1/customers/{id}/activate
     */
    @PostMapping("/{id}/activate")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Void> activateCustomer(@PathVariable Long id) {
        customerService.activateCustomer(id);
        return ResponseEntity.noContent().build();
    }

    // ============ BATCH 5A: BŐVÍTETT ENDPOINT-OK ============

    /**
     * Ügyfél statisztikái
     *
     * GET /api/v1/customers/{id}/stats
     */
    @GetMapping("/{id}/stats")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<CustomerStatsDto> getCustomerStats(@PathVariable Long id) {
        return ResponseEntity.ok(customerStatisticsService.getCustomerStats(id));
    }

    /**
     * Ügyfél tranzakció történet
     *
     * GET /api/v1/customers/{id}/history?from=&to=
     */
    @GetMapping("/{id}/history")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<CustomerStatsDto> getCustomerHistory(
            @PathVariable Long id,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        // A stats tartalmazza a történeti adatokat is
        return ResponseEntity.ok(customerStatisticsService.getCustomerStats(id));
    }

    /**
     * Gyakori ügyfelek (VIP lista)
     *
     * GET /api/v1/customers/frequent?branchId=&minTx=
     */
    @GetMapping("/frequent")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<CustomerRankingDto>> getFrequentCustomers(
            @RequestParam(required = false) UUID branchId,
            @RequestParam(defaultValue = "5") int minTx) {
        // Frequent = top customers limitált lista, minTx szűrővel
        List<CustomerRankingDto> all = customerStatisticsService.getTopCustomers(
                branchId, null, null, 100);
        List<CustomerRankingDto> filtered = all.stream()
                .filter(r -> r.getTransactionCount() >= minTx)
                .toList();
        return ResponseEntity.ok(filtered);
    }

    /**
     * Top ügyfelek rangsor
     *
     * GET /api/v1/customers/top?branchId=&from=&to=&limit=
     */
    @GetMapping("/top")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<CustomerRankingDto>> getTopCustomers(
            @RequestParam(required = false) UUID branchId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(defaultValue = "10") int limit) {
        return ResponseEntity.ok(customerStatisticsService.getTopCustomers(branchId, from, to, limit));
    }

    /**
     * Ügyfél duplikátum összevonás
     *
     * POST /api/v1/customers/merge
     */
    @PostMapping("/merge")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<CustomerDto> mergeCustomers(@Valid @RequestBody MergeCustomersDto dto) {
        Customer primary = customerService.findById(dto.getPrimaryId());
        Customer duplicate = customerService.findById(dto.getDuplicateId());

        // A duplikátum tranzakció count-ját hozzáadjuk a primary-hoz
        primary.setTransactionCount(
                primary.getTransactionCount() + duplicate.getTransactionCount());
        if (duplicate.getLastTransactionDate() != null &&
                (primary.getLastTransactionDate() == null ||
                 duplicate.getLastTransactionDate().isAfter(primary.getLastTransactionDate()))) {
            primary.setLastTransactionDate(duplicate.getLastTransactionDate());
        }

        // Duplikátum inaktiválása
        customerService.deactivateCustomer(dto.getDuplicateId());

        return ResponseEntity.ok(customerMapper.toDto(primary));
    }
}
