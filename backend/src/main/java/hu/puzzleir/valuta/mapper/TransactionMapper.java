package hu.puzzleir.valuta.mapper;

import hu.puzzleir.valuta.dto.transaction.*;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionLine;
import hu.puzzleir.valuta.service.TransactionService;
import org.springframework.stereotype.Component;

import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Transaction entity <-> DTO mapper
 */
@Component
public class TransactionMapper {

    public TransactionDto toDto(Transaction entity) {
        if (entity == null) return null;

        // Multi-line sorok mappolasa ha multiLine=true es vannak sorok
        List<TransactionLineDto> lineDtos = null;
        if (Boolean.TRUE.equals(entity.getMultiLine()) && entity.getLines() != null && !entity.getLines().isEmpty()) {
            lineDtos = entity.getLines().stream()
                    .map(this::toLineDto)
                    .collect(Collectors.toList());
        }

        return TransactionDto.builder()
                .id(entity.getId())
                .receiptNumber(entity.getReceiptNumber())
                .transactionType(entity.getTransactionType())
                .status(entity.getStatus())
                .transactionDate(entity.getTransactionDate())
                .transactionTime(entity.getTransactionTime())
                .currencyId(entity.getCurrency() != null ? entity.getCurrency().getId() : null)
                .currencyCode(entity.getCurrency() != null ? entity.getCurrency().getCode() : null)
                .currencyName(entity.getCurrency() != null ? entity.getCurrency().getName() : null)
                .currencyAmount(entity.getCurrencyAmount())
                .exchangeRate(entity.getExchangeRate())
                .hufAmount(entity.getHufAmount())
                .handlingFee(entity.getHandlingFee())
                .discountAmount(entity.getDiscountAmount())
                .discountPercent(entity.getDiscountPercent())
                .customerId(entity.getCustomerId())
                .customerName(entity.getCustomerName())
                .customerAddress(entity.getCustomerAddress())
                .customerDocumentNumber(entity.getCustomerDocumentNumber())
                .customerNationality(entity.getCustomerNationality())
                .workerId(entity.getWorker() != null ? entity.getWorker().getId() : null)
                .workerCode(entity.getWorker() != null ? entity.getWorker().getCode() : null)
                .workerName(entity.getWorker() != null ? entity.getWorker().getName() : null)
                .branchId(entity.getBranch() != null ? entity.getBranch().getId().toString() : null)
                .branchName(entity.getBranch() != null ? entity.getBranch().getName() : null)
                .originalTransactionId(entity.getOriginalTransaction() != null ? entity.getOriginalTransaction().getId() : null)
                .originalReceiptNumber(entity.getOriginalTransaction() != null ? entity.getOriginalTransaction().getReceiptNumber() : null)
                .reversalReason(entity.getReversalReason())
                .approvedBy(entity.getApprovedBy())
                .notes(entity.getNotes())
                .foreignStatus(entity.getForeignStatus() != null ? entity.getForeignStatus().name() : null)
                .printed(entity.getPrinted())
                .mtcn(entity.getMtcn())
                .referenceNumber(entity.getReferenceNumber())
                .createdAt(entity.getCreatedAt())
                .multiLine(entity.getMultiLine())
                .lineCount(entity.getLineCount())
                .lines(lineDtos)
                .build();
    }

    public TransactionLineDto toLineDto(TransactionLine line) {
        if (line == null) return null;

        return TransactionLineDto.builder()
                .id(line.getId())
                .lineNumber(line.getLineNumber())
                .currencyId(line.getCurrency() != null ? line.getCurrency().getId() : null)
                .currencyCode(line.getCurrency() != null ? line.getCurrency().getCode() : null)
                .currencyName(line.getCurrency() != null ? line.getCurrency().getName() : null)
                .appliedRate(line.getAppliedRate())
                .originalRate(line.getOriginalRate())
                .banknoteCount(line.getBanknoteCount())
                .hufValue(line.getHufValue())
                .lineDiscount(line.getLineDiscount())
                .discountType(line.getDiscountType())
                .foreignStatus(line.getForeignStatus() != null ? line.getForeignStatus().name() : null)
                .build();
    }

    public TransactionService.BuyRequest toBuyRequest(BuyRequestDto dto) {
        return TransactionService.BuyRequest.builder()
                .currencyId(dto.getCurrencyId())
                .currencyCode(dto.getCurrencyCode())
                .currencyAmount(dto.getCurrencyAmount())
                .discountPercent(dto.getDiscountPercent())
                .handlingFee(dto.getHandlingFee())
                // FK-KEZDÍJ (2026-06-02): kezelési díj override
                .handlingFeeOverrideType(dto.getHandlingFeeOverrideType())
                .handlingFeeOverrideReason(dto.getHandlingFeeOverrideReason())
                .customerCardNumber(dto.getCustomerCardNumber())
                .customExchangeRate(dto.getCustomExchangeRate())
                .customerId(dto.getCustomerId())
                .customerName(dto.getCustomerName())
                .customerAddress(dto.getCustomerAddress())
                .customerDocumentNumber(dto.getCustomerDocumentNumber())
                .customerNationality(dto.getCustomerNationality())
                .sourceOfFunds(dto.getSourceOfFunds())
                // A3 (Pmt. 50M, b4-foglalo FR-16): strukturált forrás-dokumentum továbbítása a service-be
                .sourceOfFundsDocType(dto.getSourceOfFundsDocType())
                .sourceOfFundsDocDate(dto.getSourceOfFundsDocDate())
                // AML felsővezetői jóváhagyás (Pmt. 14/A.§(4) V.2.6): POS-on megadott engedélyező
                .approverWorkerId(dto.getApproverWorkerId())
                .approvalSessionId(dto.getApprovalSessionId())
                .customerIsPep(dto.getCustomerIsPep())
                // V229 Pmt. snapshot (HIBA #5+#7+#8)
                .customerBirthPlace(dto.getCustomerBirthPlace())
                .customerBirthDate(dto.getCustomerBirthDate())
                .customerMotherName(dto.getCustomerMotherName())
                .customerDocumentType(dto.getCustomerDocumentType())
                .customerOnOwnBehalf(dto.getCustomerOnOwnBehalf())
                .customerActorName(dto.getCustomerActorName())
                // V235 PEP minoseg + actor teljes azonositasa (HIBA #15 + #17)
                .customerPepKind(dto.getCustomerPepKind())
                .customerActorBirthPlace(dto.getCustomerActorBirthPlace())
                .customerActorBirthDate(dto.getCustomerActorBirthDate())
                .customerActorMotherName(dto.getCustomerActorMotherName())
                .customerActorNationality(dto.getCustomerActorNationality())
                .customerActorDocumentType(dto.getCustomerActorDocumentType())
                .customerActorDocumentNumber(dto.getCustomerActorDocumentNumber())
                .customerActorAddress(dto.getCustomerActorAddress())
                .notes(dto.getNotes())
                .cashierCustomRate(dto.getCashierCustomRate())
                .foreignStatus(dto.getForeignStatus())
                .lines(toLineRequests(dto.getLines()))
                .build();
    }

    public TransactionService.SellRequest toSellRequest(SellRequestDto dto) {
        return TransactionService.SellRequest.builder()
                .currencyId(dto.getCurrencyId())
                .currencyCode(dto.getCurrencyCode())
                .currencyAmount(dto.getCurrencyAmount())
                .discountPercent(dto.getDiscountPercent())
                .handlingFee(dto.getHandlingFee())
                // FK-KEZDÍJ (2026-06-02): kezelési díj override
                .handlingFeeOverrideType(dto.getHandlingFeeOverrideType())
                .handlingFeeOverrideReason(dto.getHandlingFeeOverrideReason())
                .customerCardNumber(dto.getCustomerCardNumber())
                .customExchangeRate(dto.getCustomExchangeRate())
                .customerId(dto.getCustomerId())
                .customerName(dto.getCustomerName())
                .customerAddress(dto.getCustomerAddress())
                .customerDocumentNumber(dto.getCustomerDocumentNumber())
                .customerNationality(dto.getCustomerNationality())
                .sourceOfFunds(dto.getSourceOfFunds())
                // A3 (Pmt. 50M, b4-foglalo FR-16): strukturált forrás-dokumentum továbbítása a service-be
                .sourceOfFundsDocType(dto.getSourceOfFundsDocType())
                .sourceOfFundsDocDate(dto.getSourceOfFundsDocDate())
                // AML felsővezetői jóváhagyás (Pmt. 14/A.§(4) V.2.6): POS-on megadott engedélyező
                .approverWorkerId(dto.getApproverWorkerId())
                .approvalSessionId(dto.getApprovalSessionId())
                .customerIsPep(dto.getCustomerIsPep())
                // V229 Pmt. snapshot (HIBA #5+#7+#8)
                .customerBirthPlace(dto.getCustomerBirthPlace())
                .customerBirthDate(dto.getCustomerBirthDate())
                .customerMotherName(dto.getCustomerMotherName())
                .customerDocumentType(dto.getCustomerDocumentType())
                .customerOnOwnBehalf(dto.getCustomerOnOwnBehalf())
                .customerActorName(dto.getCustomerActorName())
                // V235 PEP minoseg + actor teljes azonositasa (HIBA #15 + #17)
                .customerPepKind(dto.getCustomerPepKind())
                .customerActorBirthPlace(dto.getCustomerActorBirthPlace())
                .customerActorBirthDate(dto.getCustomerActorBirthDate())
                .customerActorMotherName(dto.getCustomerActorMotherName())
                .customerActorNationality(dto.getCustomerActorNationality())
                .customerActorDocumentType(dto.getCustomerActorDocumentType())
                .customerActorDocumentNumber(dto.getCustomerActorDocumentNumber())
                .customerActorAddress(dto.getCustomerActorAddress())
                .notes(dto.getNotes())
                .cashierCustomRate(dto.getCashierCustomRate())
                .foreignStatus(dto.getForeignStatus())
                .lines(toLineRequests(dto.getLines()))
                .build();
    }

    private List<TransactionService.LineRequest> toLineRequests(List<TransactionLineRequestDto> dtos) {
        if (dtos == null || dtos.isEmpty()) {
            return null;
        }
        return dtos.stream()
                .map(d -> TransactionService.LineRequest.builder()
                        .currencyId(d.getCurrencyId())
                        .currencyCode(d.getCurrencyCode())
                        .banknoteCount(d.getBanknoteCount())
                        .customExchangeRate(d.getCustomExchangeRate())
                        .discountType(d.getDiscountType())
                        .foreignStatus(d.getForeignStatus())
                        .build())
                .collect(Collectors.toList());
    }

    public TransactionService.ReversalRequest toReversalRequest(ReversalRequestDto dto) {
        return TransactionService.ReversalRequest.builder()
                .originalTransactionId(dto.getOriginalTransactionId())
                .reason(dto.getReason())
                .approvedBy(dto.getApprovedBy())
                .build();
    }

    public TransactionService.ConversionRequest toConversionRequest(ConversionRequestDto dto) {
        return TransactionService.ConversionRequest.builder()
                .fromCurrencyId(dto.getFromCurrencyId())
                .fromCurrencyCode(dto.getFromCurrencyCode())
                .toCurrencyId(dto.getToCurrencyId())
                .toCurrencyCode(dto.getToCurrencyCode())
                .fromAmount(dto.getFromAmount())
                .toAmount(dto.getToAmount())
                .foreignStatus(dto.getForeignStatus())
                .handlingFee(dto.getHandlingFee())
                .customerId(dto.getCustomerId())
                .customerName(dto.getCustomerName())
                .customerAddress(dto.getCustomerAddress())
                .customerDocumentNumber(dto.getCustomerDocumentNumber())
                .customerNationality(dto.getCustomerNationality())
                .sourceOfFunds(dto.getSourceOfFunds())
                // A3 (Pmt. 50M, b4-foglalo FR-16): strukturált forrás-dokumentum továbbítása a service-be
                .sourceOfFundsDocType(dto.getSourceOfFundsDocType())
                .sourceOfFundsDocDate(dto.getSourceOfFundsDocDate())
                // AML felsővezetői jóváhagyás (Pmt. 14/A.§(4) V.2.6): POS-on megadott engedélyező
                .approverWorkerId(dto.getApproverWorkerId())
                .approvalSessionId(dto.getApprovalSessionId())
                .customerIsPep(dto.getCustomerIsPep())
                // V235 + V236 Konverzio Pmt. azonositas (HIBA #19 2026-05-19)
                .customerBirthPlace(dto.getCustomerBirthPlace())
                .customerBirthDate(dto.getCustomerBirthDate())
                .customerMotherName(dto.getCustomerMotherName())
                .customerDocumentType(dto.getCustomerDocumentType())
                .customerOnOwnBehalf(dto.getCustomerOnOwnBehalf())
                .customerActorName(dto.getCustomerActorName())
                .customerPepKind(dto.getCustomerPepKind())
                .customerActorBirthPlace(dto.getCustomerActorBirthPlace())
                .customerActorBirthDate(dto.getCustomerActorBirthDate())
                .customerActorMotherName(dto.getCustomerActorMotherName())
                .customerActorNationality(dto.getCustomerActorNationality())
                .customerActorDocumentType(dto.getCustomerActorDocumentType())
                .customerActorDocumentNumber(dto.getCustomerActorDocumentNumber())
                .customerActorAddress(dto.getCustomerActorAddress())
                .build();
    }
}
