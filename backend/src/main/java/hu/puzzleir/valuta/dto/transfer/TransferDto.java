package hu.puzzleir.valuta.dto.transfer;

import lombok.*;
import java.math.BigDecimal;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class TransferDto {
    /** #6: több-valutás átadólap sorai (üres a hagyományos egy-valutás átadásnál). */
    private List<TransferLineDto> lines;
    private Long id;
    private String transferNumber;
    private String fromBranchId;
    private String fromBranchCode;
    private String fromBranchName;
    /** FR-1 (bizonylat-doc 2. kör): branch.region_code — az értéktár "[azonosító]. [név]" fejléc-formátumához. */
    private String fromBranchRegionCode;
    private String toBranchId;
    private String toBranchCode;
    private String toBranchName;
    /** FR-1 (bizonylat-doc 2. kör): branch.region_code — az értéktár "[azonosító]. [név]" fejléc-formátumához. */
    private String toBranchRegionCode;
    private Long fromWorkerId;
    private String fromWorkerName;
    private Long toWorkerId;
    private String toWorkerName;
    private String transferType;
    private String transferTypeDisplay;
    private String direction;
    private String directionDisplay;
    private String status;
    private String statusDisplay;
    private String transferDate;
    private String transferTime;
    private String receivedDate;
    private String receivedTime;
    private Long currencyId;
    private String currencyCode;
    private String currencyName;
    private BigDecimal amount;
    private BigDecimal hufValue;
    private BigDecimal receivedAmount;
    private BigDecimal difference;
    private String notes;
    private String carrierName;
    private String sealNumber;
    private Boolean handoverPrinted;
    private Boolean receiptPrinted;
    private String createdAt;
    private Boolean hasDifference;
    private Boolean isCompleted;
    private Boolean isPending;

    // Értéktári átadás-átvétel bizonylat bővítések:
    /** A bejelentkezett értéktár (Branch) saját helyi címe a bizonylat fejlécéhez (FR-1). */
    private String vaultAddress;
    /**
     * A bejelentkezett értéktár (Branch) telefonszáma a bizonylat fejlécéhez (FR-2,
     * bizonylat-fejléc javítás 2026-06-11). NULL/üres branch.phone esetén NULL —
     * a kliens ekkor nem jelenít meg telefon sort (TBD-3 döntés).
     */
    private String vaultPhone;
    /** Sztornózva van-e (FR-14 lista-jelölés). */
    private Boolean isCancelled;
    /** Sztornó indoklása (FR-12, FR-15). */
    private String cancellationReason;
    /** Sztornózás időpontja. */
    private String cancelledAt;
    /** A sztornó bizonylat sorszáma: {@code <eredeti>-SZ} (FR-13). Sztornózott rekordnál és preview-ban töltött. */
    private String stornoSerialNumber;
    /** Opcionális címletezés sorai (FR-17..19). Üres/null → a bizonylaton nem jelenik meg. */
    private List<TransferDenominationDto> denominations;
}
