package hu.puzzleir.valuta.mapper;

import hu.puzzleir.valuta.dto.transaction.*;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.service.TransactionService;
import org.springframework.stereotype.Component;

/**
 * Transaction entity <-> DTO mapper
 */
@Component
public class TransactionMapper {

    public TransactionDto toDto(Transaction entity) {
        if (entity == null) return null;

        return TransactionDto.builder()
                .id(entity.getId())
                .receiptNumber(entity.getReceiptNumber())
                .transactionType(entity.getTransactionType())
                .status(entity.getStatus())
                .transactionDate(entity.getTransactionDate())
                .transactionTime(entity.getTransactionTime())
                .currencyId(entity.getCurrency().getId())
                .currencyCode(entity.getCurrency().getCode())
                .currencyName(entity.getCurrency().getName())
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
                .workerId(entity.getWorker().getId())
                .workerCode(entity.getWorker().getCode())
                .workerName(entity.getWorker().getName())
                .branchId(entity.getBranch().getId().toString())
                .branchName(entity.getBranch().getName())
                .originalTransactionId(entity.getOriginalTransaction() != null ? entity.getOriginalTransaction().getId() : null)
                .originalReceiptNumber(entity.getOriginalTransaction() != null ? entity.getOriginalTransaction().getReceiptNumber() : null)
                .reversalReason(entity.getReversalReason())
                .approvedBy(entity.getApprovedBy())
                .notes(entity.getNotes())
                .printed(entity.getPrinted())
                .mtcn(entity.getMtcn())
                .referenceNumber(entity.getReferenceNumber())
                .createdAt(entity.getCreatedAt())
                .build();
    }

    public TransactionService.BuyRequest toBuyRequest(BuyRequestDto dto) {
        return TransactionService.BuyRequest.builder()
                .currencyId(dto.getCurrencyId())
                .currencyAmount(dto.getCurrencyAmount())
                .discountPercent(dto.getDiscountPercent())
                .handlingFee(dto.getHandlingFee())
                .customerId(dto.getCustomerId())
                .customerName(dto.getCustomerName())
                .customerAddress(dto.getCustomerAddress())
                .customerDocumentNumber(dto.getCustomerDocumentNumber())
                .customerNationality(dto.getCustomerNationality())
                .notes(dto.getNotes())
                .build();
    }

    public TransactionService.SellRequest toSellRequest(SellRequestDto dto) {
        return TransactionService.SellRequest.builder()
                .currencyId(dto.getCurrencyId())
                .currencyAmount(dto.getCurrencyAmount())
                .discountPercent(dto.getDiscountPercent())
                .handlingFee(dto.getHandlingFee())
                .customerId(dto.getCustomerId())
                .customerName(dto.getCustomerName())
                .customerAddress(dto.getCustomerAddress())
                .customerDocumentNumber(dto.getCustomerDocumentNumber())
                .customerNationality(dto.getCustomerNationality())
                .notes(dto.getNotes())
                .build();
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
                .toCurrencyId(dto.getToCurrencyId())
                .fromAmount(dto.getFromAmount())
                .handlingFee(dto.getHandlingFee())
                .customerId(dto.getCustomerId())
                .customerName(dto.getCustomerName())
                .build();
    }
}
