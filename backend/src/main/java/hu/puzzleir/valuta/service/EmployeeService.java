package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.dto.employee.*;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Employee HR törzsadat service.
 * CRUD + lista + szűrés + JSON import.
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class EmployeeService {

    private final EmployeeRepository employeeRepository;
    private final EmployeeAddressRepository addressRepository;
    private final EmployeeBankAccountRepository bankAccountRepository;
    private final FeorCodeRepository feorCodeRepository;
    private final CompanyRepository companyRepository;
    private final WorkerRepository workerRepository;
    private final ObjectMapper objectMapper;

    private static final DateTimeFormatter HU_DATE = DateTimeFormatter.ofPattern("yyyy.MM.dd");

    // ===== Lekérdezések =====

    /**
     * Dolgozók listázása szűréssel.
     */
    @Transactional(readOnly = true)
    public List<EmployeeListDto> listEmployees(String organizationUnit, String jobTitle, Boolean active) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        List<Employee> employees;
        if (organizationUnit != null && active != null) {
            employees = employeeRepository.findByCompanyIdAndOrganizationUnitAndActive(companyId, organizationUnit, active);
        } else if (organizationUnit != null) {
            employees = employeeRepository.findByCompanyIdAndOrganizationUnit(companyId, organizationUnit);
        } else if (active != null) {
            employees = employeeRepository.findByCompanyIdAndActive(companyId, active);
        } else {
            employees = employeeRepository.findByCompanyId(companyId);
        }

        // Szűrés munkakörre ha van
        if (jobTitle != null && !jobTitle.isBlank()) {
            String lower = jobTitle.toLowerCase();
            employees = employees.stream()
                    .filter(e -> e.getJobTitle() != null && e.getJobTitle().toLowerCase().contains(lower))
                    .collect(Collectors.toList());
        }

        return employees.stream()
                .map(this::toListDto)
                .collect(Collectors.toList());
    }

    /**
     * Dolgozók keresése névre.
     */
    @Transactional(readOnly = true)
    public List<EmployeeListDto> searchByName(String name) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return employeeRepository.searchByName(companyId, name).stream()
                .map(this::toListDto)
                .collect(Collectors.toList());
    }

    /**
     * Dolgozó részletes lekérdezés ID alapján.
     */
    @Transactional(readOnly = true)
    public EmployeeDto getById(Long id) {
        Employee employee = findEmployeeOrThrow(id);
        return toDto(employee);
    }

    // ===== Létrehozás =====

    /**
     * Új dolgozó létrehozása.
     */
    public EmployeeDto createEmployee(CreateEmployeeDto dto) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Cég nem található: " + companyId));

        Employee employee = Employee.builder()
                .company(company)
                .organizationUnit(dto.getOrganizationUnit())
                .serialNumber(dto.getSerialNumber())
                .lastName(dto.getLastName())
                .firstName(dto.getFirstName())
                .birthLastName(dto.getBirthLastName())
                .birthFirstName(dto.getBirthFirstName())
                .taxId(dto.getTaxId())
                .socialSecurityNumber(dto.getSocialSecurityNumber())
                .mothersName(dto.getMothersName())
                .birthDate(dto.getBirthDate())
                .birthCountry(dto.getBirthCountry())
                .birthPlace(dto.getBirthPlace())
                .citizenship(dto.getCitizenship())
                .idCardNumber(dto.getIdCardNumber())
                .idCardExpiry(dto.getIdCardExpiry())
                .email(dto.getEmail())
                .phone(dto.getPhone())
                .pensionStartDate(dto.getPensionStartDate())
                .pensionType(dto.getPensionType())
                .reducedWorkCapacity(dto.getReducedWorkCapacity() != null ? dto.getReducedWorkCapacity() : false)
                .reducedWorkCapacityType(dto.getReducedWorkCapacityType())
                .employmentStartDate(dto.getEmploymentStartDate())
                .employmentType(dto.getEmploymentType())
                .employmentEndDate(dto.getEmploymentEndDate())
                .feorCode(dto.getFeorCode())
                .jobTitle(dto.getJobTitle())
                .workHoursPerDay(dto.getWorkHoursPerDay())
                .hasSecondaryEducation(dto.getHasSecondaryEducation() != null ? dto.getHasSecondaryEducation() : false)
                .salaryType(dto.getSalaryType())
                .salaryAmount(dto.getSalaryAmount())
                .paymentMethod(dto.getPaymentMethod())
                .vocationalSchoolName(dto.getVocationalSchoolName())
                .vocationalQualification(dto.getVocationalQualification())
                .certificateDate(dto.getCertificateDate())
                .personalTaxCredit(dto.getPersonalTaxCredit())
                .familyTaxCredit(dto.getFamilyTaxCredit())
                .twoChildrenCredit(dto.getTwoChildrenCredit())
                .fourPlusChildrenCredit(dto.getFourPlusChildrenCredit())
                .threeChildrenCredit(dto.getThreeChildrenCredit())
                .firstMarriageCredit(dto.getFirstMarriageCredit())
                .marriageDate(dto.getMarriageDate())
                .creditValidityLastMonth(dto.getCreditValidityLastMonth())
                .under25YouthCreditAmount(dto.getUnder25YouthCreditAmount())
                .under25YouthCreditExpiry(dto.getUnder25YouthCreditExpiry())
                .under30MotherCreditAmount(dto.getUnder30MotherCreditAmount())
                .active(true)
                .build();

        // Worker hozzárendelés (opcionális) — CSAK az aktuális céghez tartozó worker köthető (PP-02 IDOR).
        if (dto.getWorkerId() != null) {
            employee.setWorker(workerRepository.findByIdAndCompanyId(dto.getWorkerId(), companyId)
                    .orElseThrow(() -> new ResourceNotFoundException("Worker nem található: " + dto.getWorkerId())));
        }

        employee = employeeRepository.save(employee);

        // Címek mentése
        saveAddresses(employee, dto.getAddresses());
        // Bankszámlák mentése
        saveBankAccounts(employee, dto.getBankAccounts());

        return toDto(employee);
    }

    // ===== Módosítás =====

    /**
     * Dolgozó módosítása.
     */
    public EmployeeDto updateEmployee(Long id, UpdateEmployeeDto dto) {
        Employee employee = findEmployeeOrThrow(id);

        // Személyi adatok frissítése
        if (dto.getLastName() != null) employee.setLastName(dto.getLastName());
        if (dto.getFirstName() != null) employee.setFirstName(dto.getFirstName());
        if (dto.getOrganizationUnit() != null) employee.setOrganizationUnit(dto.getOrganizationUnit());
        if (dto.getBirthLastName() != null) employee.setBirthLastName(dto.getBirthLastName());
        if (dto.getBirthFirstName() != null) employee.setBirthFirstName(dto.getBirthFirstName());
        if (dto.getTaxId() != null) employee.setTaxId(dto.getTaxId());
        if (dto.getSocialSecurityNumber() != null) employee.setSocialSecurityNumber(dto.getSocialSecurityNumber());
        if (dto.getMothersName() != null) employee.setMothersName(dto.getMothersName());
        if (dto.getBirthDate() != null) employee.setBirthDate(dto.getBirthDate());
        if (dto.getBirthCountry() != null) employee.setBirthCountry(dto.getBirthCountry());
        if (dto.getBirthPlace() != null) employee.setBirthPlace(dto.getBirthPlace());
        if (dto.getCitizenship() != null) employee.setCitizenship(dto.getCitizenship());
        if (dto.getIdCardNumber() != null) employee.setIdCardNumber(dto.getIdCardNumber());
        if (dto.getIdCardExpiry() != null) employee.setIdCardExpiry(dto.getIdCardExpiry());
        if (dto.getEmail() != null) employee.setEmail(dto.getEmail());
        if (dto.getPhone() != null) employee.setPhone(dto.getPhone());
        if (dto.getPensionStartDate() != null) employee.setPensionStartDate(dto.getPensionStartDate());
        if (dto.getPensionType() != null) employee.setPensionType(dto.getPensionType());
        if (dto.getReducedWorkCapacity() != null) employee.setReducedWorkCapacity(dto.getReducedWorkCapacity());
        if (dto.getReducedWorkCapacityType() != null) employee.setReducedWorkCapacityType(dto.getReducedWorkCapacityType());
        if (dto.getEmploymentStartDate() != null) employee.setEmploymentStartDate(dto.getEmploymentStartDate());
        if (dto.getEmploymentType() != null) employee.setEmploymentType(dto.getEmploymentType());
        if (dto.getEmploymentEndDate() != null) employee.setEmploymentEndDate(dto.getEmploymentEndDate());
        if (dto.getFeorCode() != null) employee.setFeorCode(dto.getFeorCode());
        if (dto.getJobTitle() != null) employee.setJobTitle(dto.getJobTitle());
        if (dto.getWorkHoursPerDay() != null) employee.setWorkHoursPerDay(dto.getWorkHoursPerDay());
        if (dto.getHasSecondaryEducation() != null) employee.setHasSecondaryEducation(dto.getHasSecondaryEducation());
        if (dto.getSalaryType() != null) employee.setSalaryType(dto.getSalaryType());
        if (dto.getSalaryAmount() != null) employee.setSalaryAmount(dto.getSalaryAmount());
        if (dto.getPaymentMethod() != null) employee.setPaymentMethod(dto.getPaymentMethod());
        if (dto.getVocationalSchoolName() != null) employee.setVocationalSchoolName(dto.getVocationalSchoolName());
        if (dto.getVocationalQualification() != null) employee.setVocationalQualification(dto.getVocationalQualification());
        if (dto.getCertificateDate() != null) employee.setCertificateDate(dto.getCertificateDate());
        if (dto.getPersonalTaxCredit() != null) employee.setPersonalTaxCredit(dto.getPersonalTaxCredit());
        if (dto.getFamilyTaxCredit() != null) employee.setFamilyTaxCredit(dto.getFamilyTaxCredit());
        if (dto.getTwoChildrenCredit() != null) employee.setTwoChildrenCredit(dto.getTwoChildrenCredit());
        if (dto.getFourPlusChildrenCredit() != null) employee.setFourPlusChildrenCredit(dto.getFourPlusChildrenCredit());
        if (dto.getThreeChildrenCredit() != null) employee.setThreeChildrenCredit(dto.getThreeChildrenCredit());
        if (dto.getFirstMarriageCredit() != null) employee.setFirstMarriageCredit(dto.getFirstMarriageCredit());
        if (dto.getMarriageDate() != null) employee.setMarriageDate(dto.getMarriageDate());
        if (dto.getCreditValidityLastMonth() != null) employee.setCreditValidityLastMonth(dto.getCreditValidityLastMonth());
        if (dto.getUnder25YouthCreditAmount() != null) employee.setUnder25YouthCreditAmount(dto.getUnder25YouthCreditAmount());
        if (dto.getUnder25YouthCreditExpiry() != null) employee.setUnder25YouthCreditExpiry(dto.getUnder25YouthCreditExpiry());
        if (dto.getUnder30MotherCreditAmount() != null) employee.setUnder30MotherCreditAmount(dto.getUnder30MotherCreditAmount());
        if (dto.getActive() != null) employee.setActive(dto.getActive());

        // Worker hozzárendelés frissítése — CSAK az aktuális (employee-vel egyező) céghez tartozó worker
        // köthető (PP-02 IDOR). Az employee a findEmployeeOrThrow után már garantáltan az aktuális cégé.
        if (dto.getWorkerId() != null) {
            employee.setWorker(workerRepository
                    .findByIdAndCompanyId(dto.getWorkerId(), employee.getCompany().getId())
                    .orElseThrow(() -> new ResourceNotFoundException("Worker nem található: " + dto.getWorkerId())));
        }

        employee = employeeRepository.save(employee);

        // Címek és bankszámlák frissítése (ha küldtek)
        if (dto.getAddresses() != null) {
            employee.getAddresses().clear();
            employeeRepository.flush();
            saveAddresses(employee, dto.getAddresses());
        }
        if (dto.getBankAccounts() != null) {
            employee.getBankAccounts().clear();
            employeeRepository.flush();
            saveBankAccounts(employee, dto.getBankAccounts());
        }

        return toDto(employee);
    }

    // ===== Törlés (soft delete) =====

    /**
     * Dolgozó soft delete — active = false.
     */
    public void deleteEmployee(Long id) {
        Employee employee = findEmployeeOrThrow(id);
        employee.setActive(false);
        employeeRepository.save(employee);
        log.info("Dolgozó inaktiválva: id={}, név={} {}", id, employee.getLastName(), employee.getFirstName());
    }

    // ===== Import =====

    /**
     * JSON import — EBC dolgozói adatok beolvasása.
     * A JSON az ebc_employees.json formátumban érkezik.
     *
     * @param jsonContent a JSON tartalom stringként
     * @return az importált dolgozók száma
     */
    public int importFromJson(String jsonContent) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Cég nem található: " + companyId));

        try {
            List<Map<String, Object>> records = objectMapper.readValue(jsonContent, new TypeReference<>() {});
            int count = 0;

            for (Map<String, Object> rec : records) {
                Employee employee = mapJsonToEmployee(rec, company);
                employee = employeeRepository.save(employee);

                // Címek
                List<EmployeeAddress> addresses = mapJsonToAddresses(rec, employee);
                employee.getAddresses().addAll(addresses);

                // Bankszámlák
                List<EmployeeBankAccount> accounts = mapJsonToBankAccounts(rec, employee);
                employee.getBankAccounts().addAll(accounts);

                employeeRepository.save(employee);
                count++;
            }

            log.info("Dolgozói import befejezve: {} rekord importálva, companyId={}", count, companyId);
            return count;

        } catch (Exception e) {
            log.error("Dolgozói import hiba", e);
            throw new BusinessException("Import hiba: " + e.getMessage(), "EMPLOYEE_IMPORT_FAILED");
        }
    }

    // ===== FEOR kódok =====

    /**
     * Összes FEOR kód lekérdezése.
     */
    @Transactional(readOnly = true)
    public List<FeorCode> getAllFeorCodes() {
        return feorCodeRepository.findAll();
    }

    // ===== Privát segédmetódusok =====

    private Employee findEmployeeOrThrow(Long id) {
        Employee employee = employeeRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Dolgozó nem található: " + id));
        // Multi-tenant IDOR védelem (PP-02): idegen céghez tartozó dolgozó NEM adható vissza/módosítható/
        // törölhető. Az EmployeeDto érzékeny PII-t tartalmaz (TAJ, adóazonosító, bér, bankszámla, anyja
        // neve) → cross-tenant lekérés GDPR/Pmt. sértés lenne. (A SubRecordService.loadScoped azonos mintája.)
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (employee.getCompany() == null || !employee.getCompany().getId().equals(companyId)) {
            throw new ResourceNotFoundException("Dolgozó nem található: " + id);
        }
        return employee;
    }

    private void saveAddresses(Employee employee, List<EmployeeAddressDto> dtos) {
        if (dtos == null) return;
        for (EmployeeAddressDto dto : dtos) {
            EmployeeAddress address = EmployeeAddress.builder()
                    .employee(employee)
                    .addressType(dto.getAddressType())
                    .postalCode(dto.getPostalCode())
                    .city(dto.getCity())
                    .streetName(dto.getStreetName())
                    .streetType(dto.getStreetType())
                    .houseNumber(dto.getHouseNumber())
                    .building(dto.getBuilding())
                    .staircase(dto.getStaircase())
                    .floor(dto.getFloor())
                    .door(dto.getDoor())
                    .build();
            employee.getAddresses().add(address);
        }
    }

    private void saveBankAccounts(Employee employee, List<EmployeeBankAccountDto> dtos) {
        if (dtos == null) return;
        for (EmployeeBankAccountDto dto : dtos) {
            EmployeeBankAccount account = EmployeeBankAccount.builder()
                    .employee(employee)
                    .accountType(dto.getAccountType())
                    .bankCode(dto.getBankCode())
                    .accountNumber(dto.getAccountNumber())
                    .build();
            employee.getBankAccounts().add(account);
        }
    }

    /**
     * JSON rekord → Employee entity mapping.
     */
    private Employee mapJsonToEmployee(Map<String, Object> rec, Company company) {
        return Employee.builder()
                .company(company)
                .serialNumber(toInt(rec.get("Sorszám")))
                .organizationUnit(toStr(rec.get("szervezeti egység/terület")))
                .lastName(toStr(rec.get("Vezetéknév")))
                .firstName(toStr(rec.get("Keresztnév")))
                .birthLastName(toStr(rec.get("Születési vezetéknév")))
                .birthFirstName(toStr(rec.get("Születési keresztnév")))
                .taxId(toStr(rec.get("Adóazonosító")))
                .socialSecurityNumber(toStr(rec.get("TAJ-szám")))
                .mothersName(toStr(rec.get("Anyja születési neve")))
                .birthDate(parseDate(toStr(rec.get("Születési dátum"))))
                .birthCountry(toStr(rec.get("Születési ország")))
                .birthPlace(toStr(rec.get("Születési hely")))
                .citizenship(toStr(rec.get("Állampolgárság")))
                .idCardNumber(toStr(rec.get("Személyi igazolvány száma")))
                .idCardExpiry(parseDate(toStr(rec.get("Személyi igazolvány lejárta"))))
                .email(toStr(rec.get("Elektronikus bérjegyzék E-mail cím")))
                .pensionStartDate(parseDate(toStr(rec.get("Nyugdíj kezdete (dátum)"))))
                .pensionType(toStr(rec.get("Nyugdíj típusa öregségi/Nők40")))
                .reducedWorkCapacity(toStr(rec.get("Megváltozott munkaképességgel járó ellátás típusa")) != null)
                .reducedWorkCapacityType(toStr(rec.get("Megváltozott munkaképességgel járó ellátás típusa")))
                .employmentStartDate(parseDate(toStr(rec.get("Jogviszony kezdete"))))
                .employmentType(toStr(rec.get("Jogviszony megnevezése")))
                .feorCode(toStr(rec.get("FEOR")))
                .jobTitle(toStr(rec.get("Munkakör")))
                .hasSecondaryEducation("igen".equalsIgnoreCase(toStr(rec.get("Középfokú végz./szakképz. ig. tevékenység"))))
                .salaryType(parseSalaryType(toStr(rec.get("Bér típusa"))))
                .salaryAmount(parseBigDecimal(toStr(rec.get("Bér összege"))))
                .paymentMethod(parsePaymentMethod(toStr(rec.get("Kifizetés módja"))))
                .personalTaxCredit(toStr(rec.get("Személyi adókedvezmény")))
                .familyTaxCredit(toStr(rec.get("Családi adóalapkedvezmény ")))
                .twoChildrenCredit(toStr(rec.get("Két gyermekes anyák kedvezménye")))
                .fourPlusChildrenCredit(toStr(rec.get("Négy- v. többgyermekes anyák kedv.")))
                .threeChildrenCredit(toStr(rec.get("Háromgyermekes anyák kedv.")))
                .firstMarriageCredit(toStr(rec.get("Első házasok kedvezmény")))
                .marriageDate(parseDate(toStr(rec.get("Házasságkötés időpontja"))))
                .creditValidityLastMonth(toStr(rec.get("Érvényesség utolsó hónapja")))
                .under25YouthCreditAmount(toStr(rec.get("25 év alatti fiatalok kedv. összege")))
                .under25YouthCreditExpiry(parseDate(toStr(rec.get("25 év alatti fiatalok kedv. lejárata"))))
                .under30MotherCreditAmount(toStr(rec.get("30 év alatti anyák kedv. összege")))
                .vocationalSchoolName(toStr(rec.get("Szakképző Iskola neve")))
                .vocationalQualification(toStr(rec.get("Szakképesítés ")))
                .certificateDate(parseDate(toStr(rec.get("Bizonyítvány megszerzés dátuma"))))
                .active(true)
                .build();
    }

    /**
     * JSON rekord → Címek mapping (állandó, levelezési, ideiglenes).
     */
    private List<EmployeeAddress> mapJsonToAddresses(Map<String, Object> rec, Employee employee) {
        List<EmployeeAddress> addresses = new ArrayList<>();

        // Állandó lakcím
        String permCity = toStr(rec.get("Állandó lakcím város"));
        if (permCity != null && !permCity.isBlank()) {
            addresses.add(EmployeeAddress.builder()
                    .employee(employee)
                    .addressType(AddressType.PERMANENT)
                    .postalCode(toStr(rec.get("Állandó lakcím irányítószám")))
                    .city(permCity)
                    .streetName(toStr(rec.get("Közterület")))
                    .streetType(toStr(rec.get("Közterület jellege")))
                    .houseNumber(toStr(rec.get("Házszám")))
                    .building(toStr(rec.get("Épület")))
                    .staircase(toStr(rec.get("Lépcsőház")))
                    .floor(toStr(rec.get("Emelet")))
                    .door(toStr(rec.get("Ajtó")))
                    .build());
        }

        // Levelezési cím
        String mailCity = toStr(rec.get("Város Levelezési"));
        if (mailCity != null && !mailCity.isBlank()) {
            addresses.add(EmployeeAddress.builder()
                    .employee(employee)
                    .addressType(AddressType.MAILING)
                    .postalCode(toStr(rec.get("Irányítószám Levelezési")))
                    .city(mailCity)
                    .streetName(toStr(rec.get("Közterület Levelezési")))
                    .streetType(toStr(rec.get("Közterület jellege Levelezési")))
                    .houseNumber(toStr(rec.get("Házszám Levelezési")))
                    .building(toStr(rec.get("Épület Levelezési")))
                    .staircase(toStr(rec.get("Lépcsőház Levelezési")))
                    .floor(toStr(rec.get("Emelet Levelezési")))
                    .door(toStr(rec.get("Ajtó Levelezési")))
                    .build());
        }

        // Ideiglenes cím
        String tempCity = toStr(rec.get("Város Ideiglenes"));
        if (tempCity != null && !tempCity.isBlank()) {
            addresses.add(EmployeeAddress.builder()
                    .employee(employee)
                    .addressType(AddressType.TEMPORARY)
                    .postalCode(toStr(rec.get("Irányítószám Ideiglenes")))
                    .city(tempCity)
                    .streetName(toStr(rec.get("Közterület Ideiglenes")))
                    .streetType(toStr(rec.get("Közterület jellege Ideiglenes")))
                    .houseNumber(toStr(rec.get("Házszám Ideiglenes")))
                    .building(toStr(rec.get("Épület Ideiglenes")))
                    .staircase(toStr(rec.get("Lépcsőház Ideiglenes")))
                    .floor(toStr(rec.get("Emelet Ideiglenes")))
                    .door(toStr(rec.get("Ajtó Ideiglenes")))
                    .build());
        }

        return addresses;
    }

    /**
     * JSON rekord → Bankszámlák mapping.
     */
    private List<EmployeeBankAccount> mapJsonToBankAccounts(Map<String, Object> rec, Employee employee) {
        List<EmployeeBankAccount> accounts = new ArrayList<>();

        // Bérszámla
        String accountNum = toStr(rec.get("Bankszámlaszám"));
        if (accountNum != null && !accountNum.isBlank()) {
            accounts.add(EmployeeBankAccount.builder()
                    .employee(employee)
                    .accountType(BankAccountType.SALARY)
                    .bankCode(toStr(rec.get("Bank (kód)")))
                    .accountNumber(accountNum.trim())
                    .build());
        }

        // SZÉP kártya
        String szepNum = toStr(rec.get("SZÉP kártya bankszámlaszám"));
        if (szepNum != null && !szepNum.isBlank()) {
            accounts.add(EmployeeBankAccount.builder()
                    .employee(employee)
                    .accountType(BankAccountType.SZEP_CARD)
                    .bankCode(toStr(rec.get("Főszámla bank (kód)")))
                    .accountNumber(szepNum.trim())
                    .build());
        }

        return accounts;
    }

    // ===== Mapping: Entity → DTO =====

    private EmployeeDto toDto(Employee e) {
        return EmployeeDto.builder()
                .id(e.getId())
                .companyId(e.getCompany().getId().toString())
                .workerId(e.getWorker() != null ? e.getWorker().getId() : null)
                .organizationUnit(e.getOrganizationUnit())
                .serialNumber(e.getSerialNumber())
                .lastName(e.getLastName())
                .firstName(e.getFirstName())
                .birthLastName(e.getBirthLastName())
                .birthFirstName(e.getBirthFirstName())
                .taxId(e.getTaxId())
                .socialSecurityNumber(e.getSocialSecurityNumber())
                .mothersName(e.getMothersName())
                .birthDate(e.getBirthDate())
                .birthCountry(e.getBirthCountry())
                .birthPlace(e.getBirthPlace())
                .citizenship(e.getCitizenship())
                .idCardNumber(e.getIdCardNumber())
                .idCardExpiry(e.getIdCardExpiry())
                .email(e.getEmail())
                .phone(e.getPhone())
                .pensionStartDate(e.getPensionStartDate())
                .pensionType(e.getPensionType())
                .reducedWorkCapacity(e.getReducedWorkCapacity())
                .reducedWorkCapacityType(e.getReducedWorkCapacityType())
                .employmentStartDate(e.getEmploymentStartDate())
                .employmentType(e.getEmploymentType())
                .employmentEndDate(e.getEmploymentEndDate())
                .feorCode(e.getFeorCode())
                .jobTitle(e.getJobTitle())
                .workHoursPerDay(e.getWorkHoursPerDay())
                .hasSecondaryEducation(e.getHasSecondaryEducation())
                .salaryType(e.getSalaryType())
                .salaryAmount(e.getSalaryAmount())
                .paymentMethod(e.getPaymentMethod())
                .vocationalSchoolName(e.getVocationalSchoolName())
                .vocationalQualification(e.getVocationalQualification())
                .certificateDate(e.getCertificateDate())
                .personalTaxCredit(e.getPersonalTaxCredit())
                .familyTaxCredit(e.getFamilyTaxCredit())
                .twoChildrenCredit(e.getTwoChildrenCredit())
                .fourPlusChildrenCredit(e.getFourPlusChildrenCredit())
                .threeChildrenCredit(e.getThreeChildrenCredit())
                .firstMarriageCredit(e.getFirstMarriageCredit())
                .marriageDate(e.getMarriageDate())
                .creditValidityLastMonth(e.getCreditValidityLastMonth())
                .under25YouthCreditAmount(e.getUnder25YouthCreditAmount())
                .under25YouthCreditExpiry(e.getUnder25YouthCreditExpiry())
                .under30MotherCreditAmount(e.getUnder30MotherCreditAmount())
                .active(e.getActive())
                .addresses(e.getAddresses().stream().map(this::toAddressDto).collect(Collectors.toList()))
                .bankAccounts(e.getBankAccounts().stream().map(this::toBankAccountDto).collect(Collectors.toList()))
                .build();
    }

    private EmployeeListDto toListDto(Employee e) {
        return EmployeeListDto.builder()
                .id(e.getId())
                .lastName(e.getLastName())
                .firstName(e.getFirstName())
                .organizationUnit(e.getOrganizationUnit())
                .jobTitle(e.getJobTitle())
                .feorCode(e.getFeorCode())
                .employmentStartDate(e.getEmploymentStartDate())
                .active(e.getActive())
                .build();
    }

    private EmployeeAddressDto toAddressDto(EmployeeAddress a) {
        return EmployeeAddressDto.builder()
                .id(a.getId())
                .addressType(a.getAddressType())
                .postalCode(a.getPostalCode())
                .city(a.getCity())
                .streetName(a.getStreetName())
                .streetType(a.getStreetType())
                .houseNumber(a.getHouseNumber())
                .building(a.getBuilding())
                .staircase(a.getStaircase())
                .floor(a.getFloor())
                .door(a.getDoor())
                .build();
    }

    private EmployeeBankAccountDto toBankAccountDto(EmployeeBankAccount b) {
        return EmployeeBankAccountDto.builder()
                .id(b.getId())
                .accountType(b.getAccountType())
                .bankCode(b.getBankCode())
                .accountNumber(b.getAccountNumber())
                .build();
    }

    // ===== Segéd konverziók =====

    private String toStr(Object val) {
        if (val == null) return null;
        String s = val.toString().trim();
        return s.isEmpty() ? null : s;
    }

    private Integer toInt(Object val) {
        if (val == null) return null;
        if (val instanceof Number) return ((Number) val).intValue();
        try {
            return Integer.parseInt(val.toString().trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private LocalDate parseDate(String val) {
        if (val == null || val.isBlank()) return null;
        String trimmed = val.trim();

        // Ha szám → Excel serial date (1900-01-01-től számított napok)
        if (trimmed.matches("\\d+")) {
            try {
                int excelSerial = Integer.parseInt(trimmed);
                // Excel epoch: 1900-01-01 (Excel bug miatt -2 nap korrekció)
                return LocalDate.of(1900, 1, 1).plusDays(excelSerial - 2);
            } catch (Exception e) {
                log.warn("Excel serial date parse hiba: '{}'", val);
                return null;
            }
        }

        // Magyar formátum (yyyy.MM.dd)
        try {
            return LocalDate.parse(trimmed, HU_DATE);
        } catch (Exception e) {
            log.warn("Dátum parse hiba: '{}'", val);
            return null;
        }
    }

    private SalaryType parseSalaryType(String val) {
        if (val == null || val.isBlank()) return null;
        try {
            return SalaryType.valueOf(val.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            log.warn("Ismeretlen bér típus: '{}'", val);
            return null;
        }
    }

    private EmployeePaymentMethod parsePaymentMethod(String val) {
        if (val == null || val.isBlank()) return null;
        try {
            return EmployeePaymentMethod.valueOf(val.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            log.warn("Ismeretlen kifizetés mód: '{}'", val);
            return null;
        }
    }

    private BigDecimal parseBigDecimal(String val) {
        if (val == null || val.isBlank()) return null;
        try {
            return new BigDecimal(val.trim().replace(",", "."));
        } catch (Exception e) {
            log.warn("Szám parse hiba: '{}'", val);
            return null;
        }
    }
}
