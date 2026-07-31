package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import jakarta.persistence.*;
import jakarta.persistence.Version;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.UUID;

/**
 * Tranzakció (Bizonylat) entity.
 *
 * Legacy mapping: TRAD+MMDD táblák (pl. TRAD1214)
 * - BIZONYLATSZAM: V/E + sorozat (pl. V00001, E00002)
 * - FIZETENDO: összeg Ft-ban
 * - VALUTANEM: valuta kód
 * - ARFOLYAM: alkalmazott árfolyam
 * - TIPUS: V=vétel, E=eladás, F=fronton, stb.
 * - PENZTAROSNEV, IDO
 * - UGYFELSZAM, UGYFELNEV, UGYFELCIM
 */
@Entity
@Table(name = "transaction", indexes = {
    @Index(name = "idx_transaction_date", columnList = "transaction_date"),
    @Index(name = "idx_transaction_branch", columnList = "branch_id"),
    @Index(name = "idx_transaction_worker", columnList = "worker_id"),
    @Index(name = "idx_transaction_receipt", columnList = "receipt_number"),
    @Index(name = "idx_transaction_company", columnList = "company_id")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Transaction {

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
     * Iroda/pénztár
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    /**
     * Pénztáros
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "worker_id", nullable = false)
    private Worker worker;

    /**
     * Bizonylat szám (pl. V00001, E00002)
     * Legacy: BIZONYLATSZAM
     */
    @Column(name = "receipt_number", nullable = false, length = 20)
    private String receiptNumber;

    /**
     * Tranzakció típusa
     * Legacy: TIPUS
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "transaction_type", nullable = false, length = 30)
    private TransactionType transactionType;

    /**
     * Tranzakció státusza
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private TransactionStatus status = TransactionStatus.COMPLETED;

    /**
     * Tranzakció dátuma
     * Legacy: DATUM (a tábla nevéből)
     */
    @Column(name = "transaction_date", nullable = false)
    private LocalDate transactionDate;

    /**
     * Tranzakció időpontja
     * Legacy: IDO
     */
    @Column(name = "transaction_time", nullable = false)
    private LocalTime transactionTime;

    // ============ VALUTA ADATOK ============

    /**
     * Valutanem
     * Legacy: VALUTANEM
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "currency_id", nullable = false)
    private Currency currency;

    /**
     * Valuta összeg
     */
    @Column(name = "currency_amount", nullable = false, precision = 15, scale = 2)
    private BigDecimal currencyAmount;

    /**
     * Alkalmazott árfolyam
     * Legacy: ARFOLYAM
     */
    @Column(name = "exchange_rate", nullable = false, precision = 12, scale = 4)
    private BigDecimal exchangeRate;

    /**
     * Forint összeg (fizetendő/kapott)
     * Legacy: FIZETENDO
     */
    @Column(name = "huf_amount", nullable = false, precision = 15, scale = 2)
    private BigDecimal hufAmount;

    // ============ DÍJAK ============

    /**
     * Kezelési díj
     */
    @Column(name = "handling_fee", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal handlingFee = BigDecimal.ZERO;

    /**
     * Kedvezmény összege
     * Legacy: SORENGEDMENY
     */
    @Column(name = "discount_amount", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal discountAmount = BigDecimal.ZERO;

    /**
     * Kedvezmény százalék
     */
    @Column(name = "discount_percent", precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal discountPercent = BigDecimal.ZERO;

    /**
     * Penztarosi sav: egyedi arfolyam hasznalva (napi 5x limit)
     */
    @Column(name = "cashier_custom_rate")
    @Builder.Default
    private Boolean cashierCustomRate = false;

    // ============ ÜGYFÉL ADATOK ============

    /**
     * Ügyfél azonosító
     * Legacy: UGYFELSZAM
     */
    @Column(name = "customer_id", length = 50)
    private String customerId;

    /**
     * Ügyfél neve
     * Legacy: UGYFELNEV
     */
    @Column(name = "customer_name", length = 200)
    private String customerName;

    /**
     * Ügyfél címe
     * Legacy: UGYFELCIM
     */
    @Column(name = "customer_address", length = 500)
    private String customerAddress;

    /**
     * Személyi/útlevél szám (adóhatósági azonosításhoz)
     */
    @Column(name = "customer_document_number", length = 50)
    private String customerDocumentNumber;

    /**
     * Ügyfél nemzetisége
     */
    // V236 (2026-05-19 HIBA #13): VARCHAR(3) -> VARCHAR(100). A frontend
    // humanreadable szoveget kuld ("Magyar" / "EU-allampolgarsag" / "Egyeb"),
    // nem ISO3 kodot.
    @Column(name = "customer_nationality", length = 100)
    private String customerNationality;

    // ============ SZTORNÓ / VISSZATÉRÍTÉS KAPCSOLAT ============

    /**
     * Eredeti tranzakció (ha ez sztornó vagy részleges visszatérítés)
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "original_transaction_id")
    private Transaction originalTransaction;

    /**
     * Részleges visszatérítés összege HUF-ban (csak PARTIAL_REFUND típusnál)
     */
    @Column(name = "partial_refund_amount", precision = 18, scale = 4)
    private BigDecimal partialRefundAmount;

    /**
     * Sztornó oka
     */
    @Column(name = "reversal_reason", length = 500)
    private String reversalReason;

    /**
     * Sztornót jóváhagyó supervisor
     */
    @Column(name = "approved_by", length = 100)
    private String approvedBy;

    // ============ EGYÉB ============

    /**
     * Megjegyzés
     */
    @Column(length = 1000)
    private String notes;

    /**
     * Nyomtatva lett-e
     */
    @Column(name = "printed")
    @Builder.Default
    private Boolean printed = false;

    /**
     * MTCN szám (Western Union)
     */
    @Column(name = "mtcn", length = 50)
    private String mtcn;

    /**
     * Referencia szám (külső rendszerhez)
     */
    @Column(name = "reference_number", length = 100)
    private String referenceNumber;

    /**
     * Kapcsolt bizonylat szám (konverziónál: a pár bizonylata).
     * GAP 4: Magyar jogszabály szerint konverzió = 2 bizonylat (konverziós vétel + konverziós eladás).
     */
    @Column(name = "linked_receipt_number", length = 20)
    private String linkedReceiptNumber;

    // ============ KONVERZIO METADATA (Audit P0.8, V177, 2026-05-03) ============

    /**
     * Konverzio-grouping: a parent CONVERSION + child convBuy + child convSell sorok
     * ugyanazon `conversion_group_id`-vel rendelkeznek, igy egyszeru `JOIN` vagy
     * `WHERE conversion_group_id = ?` lekerdezesekkel a teljes konverzios csoport
     * lekerheto. NULL = NEM konverzios sor.
     */
    @Column(name = "conversion_group_id")
    private UUID conversionGroupId;

    /**
     * Penzugyi-effective flag: a riportok / AML / NGM / cash-balance reconciliation
     * default `WHERE financial_effective = TRUE`-ra szur.
     *
     * <p>A parent CONVERSION soron `false` — csak metadata/grouping/receipt-summary,
     * NEM duplikalja a tenyleges penzmozgast a child sorokkal.</p>
     *
     * <p>BUY / SELL / REVERSAL / WESTERN_UNION_* / MONEYGRAM_* / convBuy / convSell soron `true`.</p>
     */
    @Builder.Default
    @Column(name = "financial_effective", nullable = false)
    private boolean financialEffective = true;
    // Sourcery PR #360 follow-up: primitive `boolean` (a schema BOOLEAN NOT NULL),
    // NPE-vedelem es kovetkezetes a DB DEFAULT TRUE-vel.

    // ============ POS TERMINÁL / BANKKÁRTYA ============

    /**
     * Fizetési mód (CASH/CARD)
     * Legacy: a Delphi-ben implicit — kártyás fizetés OTP DLL-en keresztül ment.
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "payment_method", length = 20)
    @Builder.Default
    private PaymentMethod paymentMethod = PaymentMethod.CASH;

    /**
     * POS terminál autorizációs kód (kártyás fizetésnél)
     */
    @Column(name = "pos_authorization_code", length = 50)
    private String posAuthorizationCode;

    /**
     * POS terminál referencia szám
     */
    @Column(name = "pos_reference_number", length = 100)
    private String posReferenceNumber;

    /**
     * POS terminál azonosító (melyik terminálon történt)
     */
    @Column(name = "pos_terminal_id", length = 50)
    private String posTerminalId;

    /**
     * Devizastatusz: DOMESTIC (belfoldi) / FOREIGN (kulfoldi).
     * V210 migracio — bizonylatra nyomtatott mezo.
     * V214 migracio (2026-05-13 v2.5.50): DB-szintu CHECK constraint + Enum tipus.
     */
    @Enumerated(jakarta.persistence.EnumType.STRING)
    @Column(name = "foreign_status", length = 10)
    private ForeignStatus foreignStatus;

    @Version
    private Long version;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    /**
     * {@code created_at} védőháló: a mező {@code nullable = false}, de az értéket kizárólag a
     * {@code @CreatedDate} auditing tölti — a {@link Transaction}-t építő service-ek (pl.
     * {@code TransferService.createReversalTransaction}) szándékosan nem állítják be kézzel.
     * Ha az auditing egy adott kontextusban nincs bekapcsolva, az INSERT NOT NULL-sértéssel
     * elhasal, holott a mentendő adat maga hibátlan.
     *
     * <p><b>Élesben ez sosem sül el.</b> A {@code ValutaBackendApplication} hordozza az
     * {@code @EnableJpaAuditing}-et, és a JPA-specifikáció szerint az {@code @EntityListeners}
     * callbackjei (itt: {@code AuditingEntityListener}) az entitás SAJÁT callbackjei ELŐTT
     * futnak — mire ide jutunk, a {@code createdAt} már ki van töltve, és a null-check no-op.
     *
     * <p>Kizárólag null-check + kitöltés: meglévő értéket — akár auditing állította be, akár
     * a hívó adta meg expliciten — SOHA nem ír felül.
     */
    @PrePersist
    void applyCreatedAtFallback() {
        if (this.createdAt == null) {
            this.createdAt = LocalDateTime.now();
        }
    }

    // ============ MULTI-LINE SUPPORT ============

    /**
     * Bizonylat tetelek (max 6 valutasor).
     * Legacy: BLOKKTETEL tabla — egy bizonylaton max 6 kulonbozo valuta.
     */
    @OneToMany(mappedBy = "transaction", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @OrderBy("lineNumber ASC")
    @Builder.Default
    private java.util.List<TransactionLine> lines = new java.util.ArrayList<>();

    /**
     * Multi-line bizonylat (tobb valutasor)?
     */
    @Column(name = "multi_line")
    @Builder.Default
    private Boolean multiLine = false;

    /**
     * Tetelsorok szama
     */
    @Column(name = "line_count")
    @Builder.Default
    private Integer lineCount = 1;

    /**
     * Kezelesi dij tipusa (NONE/PER_MILLE/BRACKET)
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "handling_fee_type", length = 20)
    private HandlingFeeType handlingFeeType;

    // ============ FK-KEZDÍJ (V287, 2026-06-02): kezelési díj módosítás (override) audit ============
    @Enumerated(EnumType.STRING)
    @Column(name = "handling_fee_override_type", length = 20)
    private HandlingFeeOverrideType handlingFeeOverrideType;

    @Enumerated(EnumType.STRING)
    @Column(name = "handling_fee_override_reason", length = 30)
    private HandlingFeeOverrideReason handlingFeeOverrideReason;

    @Column(name = "handling_fee_base", precision = 15, scale = 2)
    private BigDecimal handlingFeeBase;

    @Column(name = "customer_card_number", length = 100)
    private String customerCardNumber;

    /**
     * Kezdojegy osszeg
     */
    @Column(name = "initial_fee", precision = 10, scale = 0)
    @Builder.Default
    private BigDecimal initialFee = BigDecimal.ZERO;

    /**
     * Kedvezmeny tipus kod (legacy: _kedvWord)
     * 0=nincs, 4=VIP, 20=F1, 32=foertektaros, 33=ertektaros, 34=jutalektmentes
     */
    @Column(name = "discount_type_code")
    @Builder.Default
    private Integer discountTypeCode = 0;

    /**
     * Magyar 5 Ft-os kerekítési különbözet.
     * roundingAmount = payableAmount - bruttó
     * Pozitív = felkerekítés, negatív = lekerekítés.
     */
    @Column(name = "rounding_amount", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal roundingAmount = BigDecimal.ZERO;

    /**
     * Konverziónál a cél-összeg lefelé módosításából (címletezés) adódó, készpénzben
     * visszaadott forint (visszajáró). A parent CONVERSION soron jelenik meg, a bizonylaton
     * fel kell tüntetni (HIBA 2026-05-26).
     */
    @Column(name = "returned_huf", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal returnedHuf = BigDecimal.ZERO;

    /**
     * AML flag - gyanus tranzakcio
     */
    @Column(name = "aml_suspicious")
    @Builder.Default
    private Boolean amlSuspicious = false;

    /**
     * AML flag - eves limit elerve
     */
    @Column(name = "aml_annual_limit_reached")
    @Builder.Default
    private Boolean amlAnnualLimitReached = false;

    /**
     * Pénzeszköz forrása — 300.000 Ft feletti tranzakciónál kötelező.
     * Legacy: BLOKNYOM/Jogcimnyilatkozat → _forras mező.
     */
    @Column(name = "source_of_funds", length = 500)
    private String sourceOfFunds;

    /**
     * A3 (Pmt. 50M, b4-foglalo FR-16): a forrás-dokumentum strukturált típusa.
     * MAGANOKIRAT_KOZJEGYZO / MAGANOKIRAT_UGYVED / BANK_SZLIP (KET_TANU TILOS 50M felett).
     */
    @Column(name = "source_of_funds_doc_type", length = 50)
    private String sourceOfFundsDocType;

    /**
     * A3 (Pmt. 50M): banki bizonylat (szlip) kiállítási dátuma — max. 3 év (1095 nap).
     */
    @Column(name = "source_of_funds_doc_date")
    private java.time.LocalDate sourceOfFundsDocDate;

    /**
     * Ügyfél PEP (kiemelt közszereplő) státusza a tranzakció pillanatában.
     * Legacy: _kozszereplo mező.
     */
    @Column(name = "customer_is_pep")
    @Builder.Default
    private Boolean customerIsPep = false;

    /**
     * AML jóváhagyás-session azonosító (kliens-generált, opaque) — V312, FR-BSZUR-05.
     * A tranzakciót a {@code transaction_aml_approval} rekordhoz köti, így a bizonylat-
     * böngésző meg tudja jeleníteni az ENGEDÉLYEZŐ nevét + beosztását.
     */
    @Column(name = "approval_session_id", length = 64)
    private String approvalSessionId;

    // ============ V229: Pmt. azonosítási snapshot mezok (HIBA #5+#7+#8 2026-05-15) ============

    @Column(name = "customer_birth_place", length = 255)
    private String customerBirthPlace;

    @Column(name = "customer_birth_date")
    private java.time.LocalDate customerBirthDate;

    @Column(name = "customer_mother_name", length = 255)
    private String customerMotherName;

    @Column(name = "customer_document_type", length = 50)
    private String customerDocumentType;

    /**
     * 300k+ Pmt. JOGCIM nyilatkozat: saját nevében jár-e az ügyfél?
     * NULL = nem keruelt megkerdezesre. TRUE = saját nevben. FALSE = mas nevben (akkor actorName).
     */
    @Column(name = "customer_on_own_behalf")
    private Boolean customerOnOwnBehalf;

    @Column(name = "customer_actor_name", length = 255)
    private String customerActorName;

    // ============ V235: Pmt. PEP minoseg + actor teljes azonositasa (HIBA #15 + #17 2026-05-19) ============

    /**
     * HIBA #15: PEP minoseg. Ha customerIsPep=TRUE, kotelezo megjelolni MILYEN
     * minosegben kiemelt kozszereplo. NULL ha nem PEP vagy &lt;300k tranzakcio.
     * Ervenyes ertekek: CSALADTAG, KOZELI_MUNKATARS, KORMANYFO, PARLAMENTI,
     * NAV_VEZETO, EGYEB. (CHECK constraint a DB-ben — V235.)
     */
    @Column(name = "customer_pep_kind", length = 50)
    private String customerPepKind;

    /**
     * HIBA #17: actor (kepviselt fel) teljes azonositasa. A Pmt. tv. 6.§ (2)
     * szerint ha az ugyfel mas neveben jar el (customerOnOwnBehalf=FALSE),
     * akkor a kepviselt felre is teljes azonositast kell vegezni. A bizony-
     * laton mindkettonek meg kell jelennie.
     */
    @Column(name = "customer_actor_birth_place", length = 255)
    private String customerActorBirthPlace;

    @Column(name = "customer_actor_birth_date")
    private java.time.LocalDate customerActorBirthDate;

    @Column(name = "customer_actor_mother_name", length = 255)
    private String customerActorMotherName;

    @Column(name = "customer_actor_nationality", length = 100)
    private String customerActorNationality;

    @Column(name = "customer_actor_document_type", length = 50)
    private String customerActorDocumentType;

    @Column(name = "customer_actor_document_number", length = 100)
    private String customerActorDocumentNumber;

    @Column(name = "customer_actor_address", length = 500)
    private String customerActorAddress;

    // ============ V325 (Batch3-C): JOGI SZEMELY ugyfel ============
    // Legacy BLOKNYOM JogiAdatokBeolvasasa (JOGISZEMELY tabla) tukre. A pultnal
    // allo kepviselo/megbizott adatait a meglevo customer_* mezok hordozzak;
    // a tenyleges tulajdonosok a transaction_beneficial_owner altablaban.

    @Column(name = "is_legal_entity_customer")
    private Boolean isLegalEntityCustomer;

    @Column(name = "legal_entity_name", length = 255)
    private String legalEntityName;

    @Column(name = "legal_entity_seat", length = 500)
    private String legalEntitySeat;

    @Column(name = "legal_entity_tax_number", length = 50)
    private String legalEntityTaxNumber;

    @Column(name = "legal_deed_number", length = 100)
    private String legalDeedNumber;

    // ============ HELPER METHODS ============

    /**
     * Nettó összeg számítása (díjak nélkül).
     * BUY: hufAmount = bruttó (fee már levonva a payable-ből), ezért fee-t HOZZÁADJUK a nettóhoz.
     * SELL: hufAmount = bruttó (fee hozzáadva a payable-hez), ezért fee-t LEVONJUK a nettóhoz.
     */
    public BigDecimal getNetHufAmount() {
        if (transactionType == TransactionType.BUY) {
            // hufAmount = payable = calcHuf - fee + rounding → nettó = hufAmount + fee
            return hufAmount.add(handlingFee);
        }
        // SELL/CONVERSION/other: hufAmount = payable = calcHuf + fee + rounding → nettó = hufAmount - fee
        return hufAmount.subtract(handlingFee);
    }

    /**
     * Ez sztornó tranzakció?
     */
    public boolean isReversal() {
        return transactionType == TransactionType.REVERSAL;
    }

    /**
     * Ez részleges visszatérítés tranzakció?
     */
    public boolean isPartialRefund() {
        return transactionType == TransactionType.PARTIAL_REFUND;
    }

    /**
     * Sztornózva lett-e?
     * HIGH FIX #13: null-safe.
     */
    public boolean isReversed() {
        return TransactionStatus.REVERSED.equals(status);
    }

    /**
     * Aktív (nem sztornózott) tranzakció?
     * HIGH FIX #13: null-safe — ha status null, nem aktív.
     */
    public boolean isActive() {
        return TransactionStatus.COMPLETED.equals(status);
    }
}
