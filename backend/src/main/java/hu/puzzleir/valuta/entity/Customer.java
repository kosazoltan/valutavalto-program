package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.entity.Company;
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

    @Builder.Default
    @jakarta.persistence.Version
    @Column(name = "version", nullable = false)
    private Long version = 0L;

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
     * Allampolgarsag — humanreadable szoveg (NEM csak ISO3 kod).
     *
     * <p>V236 (2026-05-19 HIBA #13): VARCHAR(3) -> VARCHAR(100). A frontend
     * "Magyar" / "EU-allampolgarsag" / "Egyeb" szoveget kuldte, ami a V3-as
     * VARCHAR(3)-ba nem fert bele -> HTTP 500 "Belso szerverhiba".</p>
     */
    @Column(length = 100)
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
     * Személyi igazolvány szám (külön mező)
     */
    @Column(name = "id_card_number", length = 30)
    private String idCardNumber;

    /**
     * Személyi igazolvány lejárat
     */
    @Column(name = "id_card_expiry")
    private LocalDate idCardExpiry;

    /**
     * Útlevél szám (külön mező)
     */
    @Column(name = "passport_number", length = 30)
    private String passportNumber;

    /**
     * Útlevél lejárat
     */
    @Column(name = "passport_expiry")
    private LocalDate passportExpiry;

    /**
     * Tartózkodási hely (AML teljes azonosítás, 2017. LIII. tv. 7.§)
     */
    @Column(length = 500)
    private String residence;

    /**
     * Lakcímkártya száma (AML teljes azonosítás)
     */
    @Column(name = "address_card_number", length = 30)
    private String addressCardNumber;

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
     * Ország — humanreadable országnév (NEM csak ISO 3166-1 alpha-3 kód).
     * V268 (2026-05-27): VARCHAR(3) → VARCHAR(100), mert a frontend a "Magyarország"
     * teljes országnevet küldi (HIBA #5, élő-API teszt). Lásd V236 (nationality).
     */
    @Column(length = 100)
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
     * TEÁOR tevékenységi kód (ha jogi személy) — G27, legacy BIGCTRL/TEAOR
     * (UPDATE JOGI SET TEAOR). A jogi-személy ügyfél fő tevékenységi köre.
     */
    @Column(name = "teaor_code", length = 16)
    private String teaorCode;

    /**
     * Ügyfél típusa: FULL (teljes KYC) vagy SIMPLIFIED (kis ügyfél).
     * Legacy: KISUGYFEL — egyszerűsített ügyfélnyilvántartás
     * 300.000 Ft alatti tranzakciókhoz nem szükséges teljes azonosítás.
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "customer_type", nullable = false, length = 20)
    @Builder.Default
    private CustomerType customerType = CustomerType.FULL;

    /**
     * Aktív ügyfél-e
     */
    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean active = true;

    /**
     * VIP ügyfél (kedvezményes árfolyam)
     */
    @Column(name = "is_vip")
    @Builder.Default
    private Boolean isVip = false;

    /**
     * Külföldi ügyfél
     * Legacy: BIGCTRL.DLL TranzTipus 2 / -1
     */
    @Column(name = "is_foreign")
    @Builder.Default
    private Boolean isForeign = false;

    /**
     * Kiemelt közszereplő (Politically Exposed Person)
     * Legacy: BIGCTRL.DLL TranzTipus 1
     */
    @Column(name = "is_pep")
    @Builder.Default
    private Boolean isPep = false;

    /**
     * Magas kockázatú ügyfél jelölés (AML göngyölési limit elérése után)
     * Legacy: BIGCTRL.DLL "nagy ügyfél" státusz
     */
    @Column(name = "high_risk_flag")
    @Builder.Default
    private Boolean highRiskFlag = false;

    /**
     * Magas kockázat oka
     */
    @Column(name = "high_risk_reason", length = 500)
    private String highRiskReason;

    /**
     * Magas kockázat beállításának időpontja
     */
    @Column(name = "high_risk_set_at")
    private LocalDateTime highRiskSetAt;

    /**
     * Megerősített eljárás (EDD, V.2.7) 1 éves ablakának vége.
     * Amíg >= mai nap, a tranzakciónál fokozott átvilágítás kötelező (V309).
     */
    @Column(name = "edd_until")
    private LocalDate eddUntil;

    /**
     * Az EDD-ablak indoka (pl. >=50M egyedi / >=100M havi készpénzforgalom)
     */
    @Column(name = "edd_reason", length = 500)
    private String eddReason;

    /**
     * Az EDD-ablak (utolsó) beállításának időpontja
     */
    @Column(name = "edd_set_at")
    private LocalDateTime eddSetAt;

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

    /**
     * Heti göngyölt összeg (HUF) — az elmúlt 7 nap tranzakcióinak összege.
     * Legacy: HETIOSSZ mező
     * Frissítése: minden tranzakció könyvelésekor (AmlService.setHighRiskFlagIfNeeded)
     */
    @Column(name = "weekly_total", precision = 18, scale = 2)
    @Builder.Default
    private java.math.BigDecimal weeklyTotal = java.math.BigDecimal.ZERO;

    /**
     * Éves göngyölt összeg (HUF) — az aktuális naptári év tranzakcióinak összege.
     * Legacy: HASFORINT mező
     * Frissítése: minden tranzakció könyvelésekor
     */
    @Column(name = "annual_total", precision = 18, scale = 2)
    @Builder.Default
    private java.math.BigDecimal annualTotal = java.math.BigDecimal.ZERO;

    /**
     * Éves maximum egyszeri tranzakció összeg (HUF).
     * Legacy: EVIMAX mező
     * Frissítése: ha az aktuális tranzakció meghaladja az eddigi maximumot
     */
    @Column(name = "annual_max", precision = 18, scale = 2)
    @Builder.Default
    private java.math.BigDecimal annualMax = java.math.BigDecimal.ZERO;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
