package hu.puzzleir.valuta.entity;

import com.puzzleir.backend.entity.Company;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Dolgozói HR törzsadat entity.
 *
 * Ez a tábla KIEGÉSZÍTI a meglévő Worker entity-t (nem helyettesíti!).
 * A Worker operatív célú (pénztáros belépés, szerep, branch),
 * az Employee a teljes HR törzsadat (személyi, bér, kedvezmények).
 *
 * Multi-tenant: company_id kötelező!
 */
@Entity
@Table(name = "employee")
@EntityListeners(AuditingEntityListener.class)
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Employee {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Multi-tenant: cég kapcsolat (kötelező) */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;

    /** Opcionális kapcsolat a meglévő Worker (pénztáros) entity-hez */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "worker_id")
    private Worker worker;

    /** Szervezeti egység / terület (pl. "Szekszárd", "Pécs") */
    @Column(name = "organization_unit", length = 100)
    private String organizationUnit;

    /** Sorszám az importból */
    @Column(name = "serial_number")
    private Integer serialNumber;

    // ===== Személyi adatok =====

    /** Vezetéknév */
    @Column(name = "last_name", nullable = false, length = 100)
    private String lastName;

    /** Keresztnév */
    @Column(name = "first_name", nullable = false, length = 100)
    private String firstName;

    /** Születési vezetéknév */
    @Column(name = "birth_last_name", length = 100)
    private String birthLastName;

    /** Születési keresztnév */
    @Column(name = "birth_first_name", length = 100)
    private String birthFirstName;

    /** Adóazonosító jel */
    @Column(name = "tax_id", length = 20)
    private String taxId;

    /** TAJ-szám */
    @Column(name = "social_security_number", length = 20)
    private String socialSecurityNumber;

    /** Anyja születési neve */
    @Column(name = "mothers_name", length = 150)
    private String mothersName;

    /** Születési dátum */
    @Column(name = "birth_date")
    private LocalDate birthDate;

    /** Születési ország */
    @Column(name = "birth_country", length = 100)
    private String birthCountry;

    /** Születési hely */
    @Column(name = "birth_place", length = 100)
    private String birthPlace;

    /** Állampolgárság */
    @Column(length = 100)
    private String citizenship;

    // ===== Személyi igazolvány =====

    /** Személyi igazolvány száma */
    @Column(name = "id_card_number", length = 30)
    private String idCardNumber;

    /** Személyi igazolvány lejárata */
    @Column(name = "id_card_expiry")
    private LocalDate idCardExpiry;

    // ===== Elérhetőség =====

    /** E-mail cím */
    @Column(length = 200)
    private String email;

    /** Telefonszám */
    @Column(length = 30)
    private String phone;

    // ===== Nyugdíj =====

    /** Nyugdíj kezdete */
    @Column(name = "pension_start_date")
    private LocalDate pensionStartDate;

    /** Nyugdíj típusa (öregségi/Nők40) */
    @Column(name = "pension_type", length = 50)
    private String pensionType;

    /** Megváltozott munkaképesség */
    @Column(name = "reduced_work_capacity")
    @Builder.Default
    private Boolean reducedWorkCapacity = false;

    /** Megváltozott munkaképesség típusa (pl. "részleges", "teljes") */
    @Column(name = "reduced_work_capacity_type", length = 100)
    private String reducedWorkCapacityType;

    // ===== Jogviszony =====

    /** Jogviszony kezdete */
    @Column(name = "employment_start_date")
    private LocalDate employmentStartDate;

    /** Jogviszony megnevezése */
    @Column(name = "employment_type", length = 200)
    private String employmentType;

    /** Jogviszony vége */
    @Column(name = "employment_end_date")
    private LocalDate employmentEndDate;

    /** FEOR kód (szöveg, pl. "4211") */
    @Column(name = "feor_code", length = 10)
    private String feorCode;

    /** Munkakör megnevezés */
    @Column(name = "job_title", length = 200)
    private String jobTitle;

    /** Napi munkaórák */
    @Column(name = "work_hours_per_day")
    private BigDecimal workHoursPerDay;

    /** Középfokú végzettség / szakképzés igazolása */
    @Column(name = "has_secondary_education")
    @Builder.Default
    private Boolean hasSecondaryEducation = false;

    // ===== Bér =====

    /** Bér típusa: HB (havibér), OB (órabér) */
    @Enumerated(EnumType.STRING)
    @Column(name = "salary_type", length = 5)
    private SalaryType salaryType;

    /** Bér összege */
    @Column(name = "salary_amount")
    private BigDecimal salaryAmount;

    /** Kifizetés módja: B (banki), K (készpénz) */
    @Enumerated(EnumType.STRING)
    @Column(name = "payment_method", length = 5)
    private PaymentMethod paymentMethod;

    // ===== Végzettség / Szakképzés =====

    /** Szakképző iskola neve */
    @Column(name = "vocational_school_name", length = 300)
    private String vocationalSchoolName;

    /** Szakképesítés */
    @Column(name = "vocational_qualification", length = 300)
    private String vocationalQualification;

    /** Bizonyítvány megszerzés dátuma */
    @Column(name = "certificate_date")
    private LocalDate certificateDate;

    // ===== Adókedvezmények =====

    /** Személyi adókedvezmény */
    @Column(name = "personal_tax_credit", length = 100)
    private String personalTaxCredit;

    /** Családi adóalapkedvezmény */
    @Column(name = "family_tax_credit", length = 100)
    private String familyTaxCredit;

    /** Két gyermekes anyák kedvezménye */
    @Column(name = "two_children_credit", length = 100)
    private String twoChildrenCredit;

    /** 4+ gyermekes anyák kedvezménye */
    @Column(name = "four_plus_children_credit", length = 100)
    private String fourPlusChildrenCredit;

    /** 3 gyermekes anyák kedvezménye */
    @Column(name = "three_children_credit", length = 100)
    private String threeChildrenCredit;

    /** Első házasok kedvezménye */
    @Column(name = "first_marriage_credit", length = 100)
    private String firstMarriageCredit;

    /** Házasságkötés időpontja */
    @Column(name = "marriage_date")
    private LocalDate marriageDate;

    /** Kedvezmény érvényesség utolsó hónapja */
    @Column(name = "credit_validity_last_month", length = 20)
    private String creditValidityLastMonth;

    /** 25 év alatti fiatalok kedvezmény összege */
    @Column(name = "under_25_youth_credit_amount", length = 100)
    private String under25YouthCreditAmount;

    /** 25 év alatti fiatalok kedvezmény lejárata */
    @Column(name = "under_25_youth_credit_expiry")
    private LocalDate under25YouthCreditExpiry;

    /** 30 év alatti anyák kedvezmény összege */
    @Column(name = "under_30_mother_credit_amount", length = 100)
    private String under30MotherCreditAmount;

    // ===== Aktív státusz =====

    /** Aktív-e a dolgozó (soft delete: false = törölt) */
    @Column(nullable = false)
    @Builder.Default
    private Boolean active = true;

    // ===== Kapcsolódó entitások =====

    /** Címek (állandó, levelezési, ideiglenes) */
    @OneToMany(mappedBy = "employee", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<EmployeeAddress> addresses = new ArrayList<>();

    /** Bankszámlák (bérszámla, SZÉP kártya) */
    @OneToMany(mappedBy = "employee", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<EmployeeBankAccount> bankAccounts = new ArrayList<>();

    // ===== Audit =====

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @Column(name = "created_by", length = 50)
    private String createdBy;

    @Column(name = "updated_by", length = 50)
    private String updatedBy;
}
