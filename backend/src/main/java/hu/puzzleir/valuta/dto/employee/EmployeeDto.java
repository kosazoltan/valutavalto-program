package hu.puzzleir.valuta.dto.employee;

import hu.puzzleir.valuta.entity.EmployeePaymentMethod;
import hu.puzzleir.valuta.entity.SalaryType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Dolgozói törzsadat teljes DTO — részletes lekérdezéshez.
 * Tartalmazza a címeket és bankszámlákat is beágyazva.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EmployeeDto {
    private Long id;
    private String companyId;
    private Long workerId;
    private String organizationUnit;
    private Integer serialNumber;

    // Személyi adatok
    private String lastName;
    private String firstName;
    private String birthLastName;
    private String birthFirstName;
    private String taxId;
    private String socialSecurityNumber;
    private String mothersName;
    private LocalDate birthDate;
    private String birthCountry;
    private String birthPlace;
    private String citizenship;

    // Személyi igazolvány
    private String idCardNumber;
    private LocalDate idCardExpiry;

    // Elérhetőség
    private String email;
    private String phone;

    // Nyugdíj
    private LocalDate pensionStartDate;
    private String pensionType;
    private Boolean reducedWorkCapacity;
    private String reducedWorkCapacityType;

    // Jogviszony
    private LocalDate employmentStartDate;
    private String employmentType;
    private LocalDate employmentEndDate;
    private String feorCode;
    private String jobTitle;
    private BigDecimal workHoursPerDay;
    private Boolean hasSecondaryEducation;

    // Bér
    private SalaryType salaryType;
    private BigDecimal salaryAmount;
    private EmployeePaymentMethod paymentMethod;

    // Végzettség / Szakképzés
    private String vocationalSchoolName;
    private String vocationalQualification;
    private LocalDate certificateDate;

    // Szakmai bizonyítványok (b9 FR-03)
    private String appraiserCertificateNumber;
    private LocalDate appraiserCertificateDate;
    private String sellerCertificateNumber;
    private LocalDate sellerCertificateDate;
    private String cashierCertificateNumber;
    private LocalDate cashierCertificateDate;

    // Adókedvezmények
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

    // Státusz
    private Boolean active;

    // Kapcsolódó adatok
    private List<EmployeeAddressDto> addresses;
    private List<EmployeeBankAccountDto> bankAccounts;
}
