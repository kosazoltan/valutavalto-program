package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.customer.CreateCustomerDto;
import hu.puzzleir.valuta.dto.customer.CustomerDto;
import hu.puzzleir.valuta.entity.Customer;
import hu.puzzleir.valuta.mapper.CustomerMapper;
import hu.puzzleir.valuta.service.CustomerService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
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
}
