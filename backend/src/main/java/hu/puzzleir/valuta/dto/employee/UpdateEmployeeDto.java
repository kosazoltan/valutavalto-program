package hu.puzzleir.valuta.dto.employee;

import hu.puzzleir.valuta.entity.EmployeePaymentMethod;
import hu.puzzleir.valuta.entity.SalaryType;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Dolgozó módosítás DTO.
 * Minden mező opcionális — csak a küldött mezők frissülnek.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateEmployeeDto {

    private Long workerId;
    private String organizationUnit;
    private Integer serialNumber;

    private String lastName;
    private String firstName;
    private String birthLastName;
    private String birthFirstName;
    // Lásd CreateEmployeeDto: @Size = DB-oszlophossz (nem regressziós), szigorú @Pattern szándékosan nincs.
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

    // Szakmai bizonyítványok (b9 FR-03). Review #1088 (törölhetőség): a dátumok STRING-ként
    // érkeznek — az üres string "törlés"-t jelent, a null "nincs változás"-t (LocalDate-tel
    // a kettő nem különböztethető meg, mert a Jackson az üres stringet null-lá alakítja).
    private String appraiserCertificateNumber;
    private String appraiserCertificateDate;
    private String sellerCertificateNumber;
    private String sellerCertificateDate;
    private String cashierCertificateNumber;
    private String cashierCertificateDate;

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

    private Boolean active;

    private List<EmployeeAddressDto> addresses;
    private List<EmployeeBankAccountDto> bankAccounts;
}
