package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CompanyRepository;
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
import java.util.Optional;
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
@Transactional(rollbackFor = Exception.class)
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

        // 2026-05-15 user-direktíva (HIBA #9): a régi duplikáció-hiba megtévesztő
        // volt — a pénztáros nem tudja, hogy ez ugyanaz a customer-e már, ezért
        // a duplikációkor IDEMPOTENS upsert: visszaadja a létező customer-t (HTTP 200).
        // A "rögzítés" műveletet sikeresnek tekintjük, ha végén van customer ID.
        if (request.getDocumentNumber() != null && !request.getDocumentNumber().isBlank()) {
            Optional<Customer> existing = customerRepository
                    .findByDocumentNumberAndCompanyId(request.getDocumentNumber(), companyId);
            if (existing.isPresent()) {
                log.info("Customer reuse (idempotens upsert): docNum={}, customerCode={}",
                        request.getDocumentNumber(), existing.get().getCustomerCode());
                return existing.get();
            }
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
                .idCardNumber(request.getIdCardNumber())
                .idCardExpiry(request.getIdCardExpiry())
                .passportNumber(request.getPassportNumber())
                .passportExpiry(request.getPassportExpiry())
                .residence(request.getResidence())
                .addressCardNumber(request.getAddressCardNumber())
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
                .teaorCode(request.getTeaorCode())
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
        if (request.getIdCardNumber() != null) customer.setIdCardNumber(request.getIdCardNumber());
        if (request.getIdCardExpiry() != null) customer.setIdCardExpiry(request.getIdCardExpiry());
        if (request.getPassportNumber() != null) customer.setPassportNumber(request.getPassportNumber());
        if (request.getPassportExpiry() != null) customer.setPassportExpiry(request.getPassportExpiry());
        if (request.getResidence() != null) customer.setResidence(request.getResidence());
        if (request.getAddressCardNumber() != null) customer.setAddressCardNumber(request.getAddressCardNumber());
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
        if (request.getTeaorCode() != null) customer.setTeaorCode(request.getTeaorCode());
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
     * Ügyfél keresése személyi ig. szám alapján
     */
    @Transactional(readOnly = true)
    public Customer findByIdCardNumber(String idCardNumber) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return customerRepository.findByIdCardNumberAndCompanyId(idCardNumber, companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Ügyfél nem található személyi ig. szám alapján: " + idCardNumber));
    }

    /**
     * Ügyfél keresése útlevél szám alapján
     */
    @Transactional(readOnly = true)
    public Customer findByPassportNumber(String passportNumber) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return customerRepository.findByPassportNumberAndCompanyId(passportNumber, companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Ügyfél nem található útlevél szám alapján: " + passportNumber));
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
    /**
     * Ügyfél mentése (merge/frissítés után).
     */
    public Customer save(Customer customer) {
        return customerRepository.save(customer);
    }

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
     * Pont-alapú ügyfél azonosítás / keresés.
     *
     * Logika: anyjaneve + születési idő + születési hely + azonosítószám → 4 kritérium közül
     * legalább 2 egyezés = azonosított ügyfél.
     *
     * Legacy: BIGCTRL.DLL / ADATLAP matchelés logika
     *
     * @param documentNumber  okmányszám (legmagasabb prioritású — 1 egyezés = 2 pont)
     * @param motherName      anyja neve
     * @param birthDate       születési dátum
     * @param birthPlace      születési hely
     * @return azonosított ügyfél (ha van legalább 2 pont), üres ha nem azonosítható
     */
    @Transactional(readOnly = true)
    public Optional<Customer> findOrMatchCustomer(
            String documentNumber,
            String motherName,
            LocalDate birthDate,
            String birthPlace) {

        UUID companyId = SecurityUtils.getCurrentCompanyId();

        // 1. Közvetlen okmányszám alapú keresés (2 pont = azonosított)
        if (documentNumber != null && !documentNumber.isBlank()) {
            Optional<Customer> byDoc = customerRepository
                .findByDocumentNumberAndCompanyId(documentNumber, companyId);
            if (byDoc.isPresent()) {
                log.debug("Pont-alapú match: közvetlen okmányszám egyezés, customerId={}",
                    byDoc.get().getId());
                return byDoc;
            }
            Optional<Customer> byIdCard = customerRepository
                .findByIdCardNumberAndCompanyId(documentNumber, companyId);
            if (byIdCard.isPresent()) {
                log.debug("Pont-alapú match: személyi ig. egyezés, customerId={}",
                    byIdCard.get().getId());
                return byIdCard;
            }
            Optional<Customer> byPassport = customerRepository
                .findByPassportNumberAndCompanyId(documentNumber, companyId);
            if (byPassport.isPresent()) {
                log.debug("Pont-alapú match: útlevél egyezés, customerId={}",
                    byPassport.get().getId());
                return byPassport;
            }
        }

        // 2. Pont-alapú matching: 4 kritérium közül min. 2 egyezés
        List<Customer> candidates = customerRepository.findByCompanyIdAndActiveTrue(companyId);

        Customer best = null;
        int bestScore = 0;

        for (Customer c : candidates) {
            int score = 0;

            if (motherName != null && !motherName.isBlank()
                    && motherName.equalsIgnoreCase(c.getMotherName())) {
                score++;
            }
            if (birthDate != null && birthDate.equals(c.getBirthDate())) {
                score++;
            }
            if (birthPlace != null && !birthPlace.isBlank()
                    && birthPlace.equalsIgnoreCase(c.getBirthPlace())) {
                score++;
            }
            if (documentNumber != null && !documentNumber.isBlank()
                    && (documentNumber.equalsIgnoreCase(c.getDocumentNumber())
                        || documentNumber.equalsIgnoreCase(c.getIdCardNumber())
                        || documentNumber.equalsIgnoreCase(c.getPassportNumber()))) {
                score++;
            }

            if (score > bestScore) {
                bestScore = score;
                best = c;
            }
        }

        if (bestScore >= 2) {
            log.debug("Pont-alapú match: {} pont egyezés, customerId={}", bestScore, best.getId());
            return Optional.of(best);
        }

        log.debug("Pont-alapú match: nem azonosítható ügyfél (legjobb pontszám: {})", bestScore);
        return Optional.empty();
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
        private String idCardNumber;
        private LocalDate idCardExpiry;
        private String passportNumber;
        private LocalDate passportExpiry;
        private String residence;
        private String addressCardNumber;
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
        private String teaorCode;
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
        private String idCardNumber;
        private LocalDate idCardExpiry;
        private String passportNumber;
        private LocalDate passportExpiry;
        private String residence;
        private String addressCardNumber;
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
        private String teaorCode;
        private Boolean isVip;
        private String notes;
    }
}
