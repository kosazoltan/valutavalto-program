package hu.puzzleir.valuta.dto.employee;

import hu.puzzleir.valuta.entity.PaymentMethod;
import hu.puzzleir.valuta.entity.SalaryType;
import jakarta.validation.constraints.NotBlank;
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
    private String taxId;
    private String socialSecurityNumber;
    private String mothersName;
    private LocalDate birthDate;
    private String birthCountry;
    private String birthPlace;
    private String citizenship;

    private String idCardNumber;
    private LocalDate idCardExpiry;

    private String email;
    private String phone;

    private LocalDate pensionStartDate;
    private String pensionType;
    private Boolean reducedWorkCapacity;
    private String reducedWorkCapacityType;

    private LocalDate employmentStartDate;
    private String employmentType;
    private LocalDate employmentEndDate;
    private String feorCode;
    private String jobTitle;
    private BigDecimal workHoursPerDay;
    private Boolean hasSecondaryEducation;

    private SalaryType salaryType;
    private BigDecimal salaryAmount;
    private PaymentMethod paymentMethod;

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
