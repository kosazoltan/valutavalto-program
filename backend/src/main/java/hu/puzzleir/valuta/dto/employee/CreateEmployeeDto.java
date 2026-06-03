package hu.puzzleir.valuta.dto.employee;

import hu.puzzleir.valuta.entity.EmployeePaymentMethod;
import hu.puzzleir.valuta.entity.SalaryType;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Dolgozó létrehozás DTO.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateEmployeeDto {

    private Long workerId;
    private String organizationUnit;
    private Integer serialNumber;

    @NotBlank(message = "Vezetéknév kötelező")
    private String lastName;

    @NotBlank(message = "Keresztnév kötelező")
    private String firstName;

    private String birthLastName;
    private String birthFirstName;
    // A @Size felső korlátok = a DB-oszlophosszok (tax_id/ssn=20), így meglévő, perzisztálható
    // adatot nem utasítanak el; csak túlcsordulásnál adnak tiszta 400-at a nyers 500 helyett.
    // Szigorúbb @Pattern (pl. 9/10 jegy) SZÁNDÉKOSAN nincs: a 196 importált dolgozó tárolt
    // formátuma nem verifikált, és a teljes DTO újra-validálódna minden részleges módosításnál.
    @Size(max = 20, message = "Adóazonosító maximum 20 karakter")
    private String taxId;
    @Size(max = 20, message = "TAJ szám maximum 20 karakter")
    private String socialSecurityNumber;
    private String mothersName;
    private LocalDate birthDate;
    private String birthCountry;
    private String birthPlace;
    private String citizenship;

    private String idCardNumber;
    private LocalDate idCardExpiry;

    @Email(message = "Érvénytelen email cím formátum")
    @Size(max = 200, message = "Email maximum 200 karakter")
    private String email;
    @Size(max = 30, message = "Telefonszám maximum 30 karakter")
    private String phone;

    private LocalDate pensionStartDate;
    private String pensionType;
    private Boolean reducedWorkCapacity;
    private String reducedWorkCapacityType;

    private LocalDate employmentStartDate;
    private String employmentType;
    private LocalDate employmentEndDate;
    @Size(max = 10, message = "FEOR kód maximum 10 karakter")
    private String feorCode;
    private String jobTitle;
    private BigDecimal workHoursPerDay;
    private Boolean hasSecondaryEducation;

    private SalaryType salaryType;
    private BigDecimal salaryAmount;
    private EmployeePaymentMethod paymentMethod;

    private String vocationalSchoolName;
    private String vocationalQualification;
    private LocalDate certificateDate;

    private String personalTaxCredit;
    private String familyTaxCredit;
    private String twoChildrenCredit;
    private String fourPlusChildrenCredit;
    private String threeChildrenCredit;
    private String firstMarriageCredit;
    private LocalDate marriageDate;
    private String creditValidityLastMonth;
    private String under25YouthCreditAmount;
    private LocalDate under25YouthCreditExpiry;
    private String under30MotherCreditAmount;

    private List<EmployeeAddressDto> addresses;
    private List<EmployeeBankAccountDto> bankAccounts;
}
