package hu.puzzleir.valuta.entity;

import com.puzzleir.backend.entity.Company;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Ügyfél entity.
 *
 * Legacy mapping: ADATLAP tábla
 * - UGYFELSZAM: ügyfél azonosító
 * - UGYFELNEV: név
 * - UGYFELCIM: cím
 * - Jogiszemely adatok
 */
@Entity
@Table(name = "customer", indexes = {
    @Index(name = "idx_customer_company", columnList = "company_id"),
    @Index(name = "idx_customer_document", columnList = "document_number")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Customer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * MULTI-TENANT: Cég kapcsolat
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;

    /**
     * Ügyfél azonosító (belső)
     * Legacy: UGYFELSZAM
     */
    @Column(name = "customer_code", length = 50)
    private String customerCode;

    /**
     * Teljes név
     * Legacy: UGYFELNEV
     */
    @Column(nullable = false, length = 200)
    private String name;

    /**
     * Születési név
     */
    @Column(name = "birth_name", length = 200)
    private String birthName;

    /**
     * Anyja neve
     */
    @Column(name = "mother_name", length = 200)
    private String motherName;

    /**
     * Születési dátum
     */
    @Column(name = "birth_date")
    private LocalDate birthDate;

    /**
     * Születési hely
     */
    @Column(name = "birth_place", length = 100)
    private String birthPlace;

    /**
     * Nemzetiség (ISO 3166-1 alpha-3)
     */
    @Column(length = 3)
    private String nationality;

    /**
     * Személyi igazolvány / útlevél szám
     * Legacy: dokumentum azonosításhoz
     */
    @Column(name = "document_number", length = 50)
    private String documentNumber;

    /**
     * Dokumentum típusa
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "document_type", length = 30)
    private DocumentType documentType;

    /**
     * Dokumentum lejárati dátuma
     */
    @Column(name = "document_expiry")
    private LocalDate documentExpiry;

    /**
     * Lakcím
     * Legacy: UGYFELCIM
     */
    @Column(length = 500)
    private String address;

    /**
     * Irányítószám
     */
    @Column(name = "postal_code", length = 10)
    private String postalCode;

    /**
     * Város
     */
    @Column(length = 100)
    private String city;

    /**
     * Ország (ISO 3166-1 alpha-3)
     */
    @Column(length = 3)
    private String country;

    /**
     * Telefonszám
     */
    @Column(length = 30)
    private String phone;

    /**
     * Email
     */
    @Column(length = 100)
    private String email;

    /**
     * Jogi személy-e
     */
    @Column(name = "is_company")
    @Builder.Default
    private Boolean isCompany = false;

    /**
     * Cég neve (ha jogi személy)
     */
    @Column(name = "company_name", length = 200)
    private String companyName;

    /**
     * Adószám (ha jogi személy)
     */
    @Column(name = "tax_number", length = 20)
    private String taxNumber;

    /**
     * Cégjegyzékszám
     */
    @Column(name = "registration_number", length = 50)
    private String registrationNumber;

    /**
     * Aktív ügyfél-e
     */
    @Column(nullable = false)
    @Builder.Default
    private Boolean active = true;

    /**
     * VIP ügyfél (kedvezményes árfolyam)
     */
    @Column(name = "is_vip")
    @Builder.Default
    private Boolean isVip = false;

    /**
     * Megjegyzések
     */
    @Column(length = 1000)
    private String notes;

    /**
     * Utolsó tranzakció dátuma
     */
    @Column(name = "last_transaction_date")
    private LocalDate lastTransactionDate;

    /**
     * Összes tranzakció száma
     */
    @Column(name = "transaction_count")
    @Builder.Default
    private Integer transactionCount = 0;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
