package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * ÁFA visszatérítés tranzakció napló.
 *
 * Legacy mapping: WAFATABLAK tábla
 * Bizonylat típusok:
 *   AK = külföldi ügyfél ÁFA visszatérítés (EU-s ügyfél HUF-ban kapja vissza)
 *   AB = céges ÁFA kifizetés
 *   AV = Innova Invest ellátmány
 */
@Entity
@Table(name = "vat_refund_transaction", indexes = {
    @Index(name = "idx_vat_refund_company_date", columnList = "company_id, transaction_date"),
    @Index(name = "idx_vat_refund_serial", columnList = "serial_number"),
    @Index(name = "idx_vat_refund_type", columnList = "voucher_type")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VatRefundTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Multi-tenant: cég azonosító
     */
    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    /**
     * Iroda (branch) azonosító
     */
    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    /**
     * Bizonylat típus
     * Legacy: BIZONYLATTIPUS
     * AK = külföldi ügyfél ÁFA visszatérítés
     * AB = céges ÁFA kifizetés
     * AV = Innova Invest ellátmány
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "voucher_type", nullable = false, length = 2)
    private VoucherType voucherType;

    /**
     * Bizonylat sorszáma
     * Legacy: SORSZAM
     */
    @Column(name = "serial_number", nullable = false, length = 30)
    private String serialNumber;

    /**
     * Tranzakció dátuma
     * Legacy: DATUM
     */
    @Column(name = "transaction_date", nullable = false)
    private LocalDate transactionDate;

    /**
     * Tranzakció időpontja
     * Legacy: IDO
     */
    @Column(name = "transaction_time")
    private LocalTime transactionTime;

    /**
     * Főegység: 3=Innova Invest, 4=pénztár, 6=ügyfél
     * Legacy: FOEGYSEG
     */
    @Column(name = "main_unit")
    private Integer mainUnit;

    /**
     * Ellátmány összeg (Innova Invest esetén)
     * Legacy: ELLATMANY
     */
    @Column(name = "supply_amount", precision = 18, scale = 2)
    private BigDecimal supplyAmount;

    /**
     * Bruttó összeg
     * Legacy: BRUTTO
     */
    @Column(name = "gross_amount", nullable = false, precision = 18, scale = 2)
    private BigDecimal grossAmount;

    /**
     * ÁFA összeg
     * Legacy: AFA
     */
    @Column(name = "vat_amount", nullable = false, precision = 18, scale = 2)
    private BigDecimal vatAmount;

    /**
     * ÁFA százalék
     * Legacy: SZAZALEK
     */
    @Column(name = "vat_percentage", precision = 5, scale = 2)
    private BigDecimal vatPercentage;

    /**
     * Ügyfél neve
     * Legacy: UGYFELNEV
     */
    @Column(name = "customer_name", length = 200)
    private String customerName;

    /**
     * Ügyfél lakcíme
     * Legacy: LAKCIM
     */
    @Column(name = "customer_address", length = 500)
    private String customerAddress;

    /**
     * Ügyfél azonosítója (személyi ig. / útlevél szám)
     * Legacy: AZONOSITO
     */
    @Column(name = "customer_identifier", length = 50)
    private String customerIdentifier;

    /**
     * Bankszámlaszám
     * Legacy: SZAMLASZAM
     */
    @Column(name = "bank_account_number", length = 50)
    private String bankAccountNumber;

    /**
     * Cég neve (jogi személy esetén)
     * Legacy: CEGNEV
     */
    @Column(name = "company_name", length = 200)
    private String companyName;

    /**
     * Telephely cím
     * Legacy: TELEPHELYCIM
     */
    @Column(name = "site_address", length = 500)
    private String siteAddress;

    /**
     * Okiratszám (cégkivonat / meghatalmazás száma)
     * Legacy: OKIRATSZAM
     */
    @Column(name = "deed_number", length = 50)
    private String deedNumber;

    /**
     * Stornójel: igaz = sztornózott bizonylat
     * Legacy: STORNOJEL
     */
    @Column(name = "is_reversed", nullable = false)
    @Builder.Default
    private Boolean isReversed = false;

    /**
     * Sztornó eredeti tranzakció ID
     */
    @Column(name = "original_transaction_id")
    private Long originalTransactionId;

    /**
     * Létrehozó pénztáros kódja
     */
    @Column(name = "created_by_worker", length = 50)
    private String createdByWorker;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    /**
     * Bizonylat típus enum
     */
    public enum VoucherType {
        /** Külföldi ügyfél ÁFA visszatérítés */
        AK,
        /** Céges ÁFA kifizetés */
        AB,
        /** Innova Invest ellátmány */
        AV
    }
}
