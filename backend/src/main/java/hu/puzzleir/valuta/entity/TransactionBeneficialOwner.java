package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * V325 (Batch3-C): tényleges tulajdonos (Pmt. 9.§) jogi személy ügyfélnél —
 * a legacy UJTULAJOK tábla tükre (TULAJNEV, LAKCIM, SZULHELY+SZULIDO,
 * ALLAMPOLGAR, TARTHELY, ERDJELLEG, ERDMERTEK, TULKOZSZEREP).
 * Maximum 4 tulajdonos tranzakciónként (legacy array[1..4] — a
 * TransactionService érvényesíti).
 */
@Entity
@Table(name = "transaction_beneficial_owner")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TransactionBeneficialOwner {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @Column(name = "transaction_id", nullable = false)
    private Long transactionId;

    /** Sorszám a bizonylaton (1..4) — legacy "N. tulajdonos:" fejléc. */
    @Column(name = "owner_no", nullable = false)
    private Integer ownerNo;

    @Column(name = "owner_name", nullable = false, length = 255)
    private String ownerName;

    @Column(name = "owner_address", length = 500)
    private String ownerAddress;

    @Column(name = "owner_birth_place", length = 255)
    private String ownerBirthPlace;

    @Column(name = "owner_birth_date", length = 20)
    private String ownerBirthDate;

    @Column(name = "owner_nationality", length = 100)
    private String ownerNationality;

    /** Külföldi tartózkodási hely (legacy TARTHELY) — csak ha van. */
    @Column(name = "owner_residence_abroad", length = 255)
    private String ownerResidenceAbroad;

    /** Az érdekeltség/tulajdonosi jogviszony jellege (legacy ERDJELLEG). */
    @Column(name = "owner_interest_nature", length = 255)
    private String ownerInterestNature;

    /** A részesedés mértéke szövegesen, pl. "50%" (legacy ERDMERTEK). */
    @Column(name = "owner_interest_extent", length = 100)
    private String ownerInterestExtent;

    @Column(name = "owner_is_pep", nullable = false)
    @Builder.Default
    private Boolean ownerIsPep = Boolean.FALSE;

    @Column(name = "created_at", nullable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}
