package hu.puzzleir.valuta.service;

import com.puzzleir.backend.entity.Company;
import com.puzzleir.backend.exception.ResourceNotFoundException;
import com.puzzleir.backend.exception.ValidationException;
import com.puzzleir.backend.repository.CompanyRepository;
import hu.puzzleir.valuta.entity.Customer;
import hu.puzzleir.valuta.entity.DocumentType;
import hu.puzzleir.valuta.repository.CustomerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Ügyfél szolgáltatás.
 *
 * Legacy: ADATLAP tábla kezelés
 * - Ügyfél regisztráció és módosítás
 * - NAV azonosítás (300.000 Ft felett kötelező)
 * - VIP ügyfelek kezelése
 */
@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class CustomerService {

    private final CustomerRepository customerRepository;
    private final CompanyRepository companyRepository;

    /**
     * Ügyfél létrehozása
     */
    public Customer createCustomer(CreateCustomerRequest request) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem található"));

        // Dokumentum szám egyediség ellenőrzése
        if (request.getDocumentNumber() != null && !request.getDocumentNumber().isBlank()) {
            customerRepository.findByDocumentNumberAndCompanyId(request.getDocumentNumber(), companyId)
                    .ifPresent(c -> {
                        throw new ValidationException("Ez a dokumentum szám már regisztrálva van: " + request.getDocumentNumber());
                    });
        }

        Customer customer = Customer.builder()
                .company(company)
                .customerCode(generateCustomerCode(companyId))
                .name(request.getName())
                .birthName(request.getBirthName())
                .motherName(request.getMotherName())
                .birthDate(request.getBirthDate())
                .birthPlace(request.getBirthPlace())
                .nationality(request.getNationality())
                .documentNumber(request.getDocumentNumber())
                .documentType(request.getDocumentType())
                .documentExpiry(request.getDocumentExpiry())
                .address(request.getAddress())
                .postalCode(request.getPostalCode())
                .city(request.getCity())
                .country(request.getCountry())
                .phone(request.getPhone())
                .email(request.getEmail())
                .isCompany(request.getIsCompany() != null && request.getIsCompany())
                .companyName(request.getCompanyName())
                .taxNumber(request.getTaxNumber())
                .registrationNumber(request.getRegistrationNumber())
                .isVip(request.getIsVip() != null && request.getIsVip())
                .notes(request.getNotes())
                .active(true)
                .build();

        Customer saved = customerRepository.save(customer);
        log.info("Új ügyfél létrehozva: {} - {}", saved.getCustomerCode(), saved.getName());

        return saved;
    }

    /**
     * Ügyfél módosítása
     */
    public Customer updateCustomer(Long customerId, UpdateCustomerRequest request) {
        Customer customer = findById(customerId);

        if (request.getName() != null) customer.setName(request.getName());
        if (request.getBirthName() != null) customer.setBirthName(request.getBirthName());
        if (request.getMotherName() != null) customer.setMotherName(request.getMotherName());
        if (request.getBirthDate() != null) customer.setBirthDate(request.getBirthDate());
        if (request.getBirthPlace() != null) customer.setBirthPlace(request.getBirthPlace());
        if (request.getNationality() != null) customer.setNationality(request.getNationality());
        if (request.getDocumentNumber() != null) customer.setDocumentNumber(request.getDocumentNumber());
        if (request.getDocumentType() != null) customer.setDocumentType(request.getDocumentType());
        if (request.getDocumentExpiry() != null) customer.setDocumentExpiry(request.getDocumentExpiry());
        if (request.getAddress() != null) customer.setAddress(request.getAddress());
        if (request.getPostalCode() != null) customer.setPostalCode(request.getPostalCode());
        if (request.getCity() != null) customer.setCity(request.getCity());
        if (request.getCountry() != null) customer.setCountry(request.getCountry());
        if (request.getPhone() != null) customer.setPhone(request.getPhone());
        if (request.getEmail() != null) customer.setEmail(request.getEmail());
        if (request.getIsCompany() != null) customer.setIsCompany(request.getIsCompany());
        if (request.getCompanyName() != null) customer.setCompanyName(request.getCompanyName());
        if (request.getTaxNumber() != null) customer.setTaxNumber(request.getTaxNumber());
        if (request.getRegistrationNumber() != null) customer.setRegistrationNumber(request.getRegistrationNumber());
        if (request.getIsVip() != null) customer.setIsVip(request.getIsVip());
        if (request.getNotes() != null) customer.setNotes(request.getNotes());

        Customer saved = customerRepository.save(customer);
        log.info("Ügyfél módosítva: {} - {}", saved.getCustomerCode(), saved.getName());

        return saved;
    }

    /**
     * Ügyfél keresése ID alapján
     */
    @Transactional(readOnly = true)
    public Customer findById(Long customerId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new ResourceNotFoundException("Ügyfél nem található: " + customerId));

        // Multi-tenant ellenőrzés
        if (!customer.getCompany().getId().equals(companyId)) {
            throw new ResourceNotFoundException("Ügyfél nem található: " + customerId);
        }

        return customer;
    }

    /**
     * Ügyfél keresése dokumentum szám alapján
     */
    @Transactional(readOnly = true)
    public Customer findByDocumentNumber(String documentNumber) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return customerRepository.findByDocumentNumberAndCompanyId(documentNumber, companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Ügyfél nem található: " + documentNumber));
    }

    /**
     * Ügyfél keresése ügyfélkód alapján
     */
    @Transactional(readOnly = true)
    public Customer findByCustomerCode(String customerCode) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return customerRepository.findByCustomerCodeAndCompanyId(customerCode, companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Ügyfél nem található: " + customerCode));
    }

    /**
     * Ügyfelek keresése név alapján
     */
    @Transactional(readOnly = true)
    public List<Customer> searchByName(String name) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return customerRepository.searchByName(companyId, name);
    }

    /**
     * VIP ügyfelek listázása
     */
    @Transactional(readOnly = true)
    public List<Customer> getVipCustomers() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return customerRepository.findVipCustomers(companyId);
    }

    /**
     * Aktív ügyfelek listázása
     */
    @Transactional(readOnly = true)
    public List<Customer> getActiveCustomers() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return customerRepository.findByCompanyIdAndActiveTrue(companyId);
    }

    /**
     * Ügyfél inaktiválása
     */
    public void deactivateCustomer(Long customerId) {
        Customer customer = findById(customerId);
        customer.setActive(false);
        customerRepository.save(customer);
        log.info("Ügyfél inaktiválva: {} - {}", customer.getCustomerCode(), customer.getName());
    }

    /**
     * Ügyfél aktiválása
     */
    public void activateCustomer(Long customerId) {
        Customer customer = findById(customerId);
        customer.setActive(true);
        customerRepository.save(customer);
        log.info("Ügyfél aktiválva: {} - {}", customer.getCustomerCode(), customer.getName());
    }

    /**
     * Tranzakció rögzítése ügyfélhez
     */
    public void recordTransaction(Long customerId) {
        Customer customer = findById(customerId);
        customer.setLastTransactionDate(LocalDate.now());
        customer.setTransactionCount(customer.getTransactionCount() + 1);
        customerRepository.save(customer);
    }

    /**
     * Ügyfél kód generálása
     */
    private String generateCustomerCode(UUID companyId) {
        // Egyszerű szekvenciális kód: C + 6 számjegy
        long count = customerRepository.findByCompanyIdAndActiveTrue(companyId).size() + 1;
        return String.format("C%06d", count);
    }

    // ============ REQUEST DTO-k ============

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class CreateCustomerRequest {
        private String name;
        private String birthName;
        private String motherName;
        private LocalDate birthDate;
        private String birthPlace;
        private String nationality;
        private String documentNumber;
        private DocumentType documentType;
        private LocalDate documentExpiry;
        private String address;
        private String postalCode;
        private String city;
        private String country;
        private String phone;
        private String email;
        private Boolean isCompany;
        private String companyName;
        private String taxNumber;
        private String registrationNumber;
        private Boolean isVip;
        private String notes;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class UpdateCustomerRequest {
        private String name;
        private String birthName;
        private String motherName;
        private LocalDate birthDate;
        private String birthPlace;
        private String nationality;
        private String documentNumber;
        private DocumentType documentType;
        private LocalDate documentExpiry;
        private String address;
        private String postalCode;
        private String city;
        private String country;
        private String phone;
        private String email;
        private Boolean isCompany;
        private String companyName;
        private String taxNumber;
        private String registrationNumber;
        private Boolean isVip;
        private String notes;
    }
}
