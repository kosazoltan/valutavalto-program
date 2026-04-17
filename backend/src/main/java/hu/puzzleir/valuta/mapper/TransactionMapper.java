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
                .build();
    }

    public TransactionService.BuyRequest toBuyRequest(BuyRequestDto dto) {
        return TransactionService.BuyRequest.builder()
                .currencyId(dto.getCurrencyId())
                .currencyCode(dto.getCurrencyCode())
                .currencyAmount(dto.getCurrencyAmount())
                .discountPercent(dto.getDiscountPercent())
                .handlingFee(dto.getHandlingFee())
                .customExchangeRate(dto.getCustomExchangeRate())
                .customerId(dto.getCustomerId())
                .customerName(dto.getCustomerName())
                .customerAddress(dto.getCustomerAddress())
                .customerDocumentNumber(dto.getCustomerDocumentNumber())
                .customerNationality(dto.getCustomerNationality())
                .sourceOfFunds(dto.getSourceOfFunds())
                .customerIsPep(dto.getCustomerIsPep())
                .notes(dto.getNotes())
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
                .customExchangeRate(dto.getCustomExchangeRate())
                .customerId(dto.getCustomerId())
                .customerName(dto.getCustomerName())
                .customerAddress(dto.getCustomerAddress())
                .customerDocumentNumber(dto.getCustomerDocumentNumber())
                .customerNationality(dto.getCustomerNationality())
                .sourceOfFunds(dto.getSourceOfFunds())
                .customerIsPep(dto.getCustomerIsPep())
                .notes(dto.getNotes())
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
                .handlingFee(dto.getHandlingFee())
                .customerId(dto.getCustomerId())
                .customerName(dto.getCustomerName())
                .customerAddress(dto.getCustomerAddress())
                .customerDocumentNumber(dto.getCustomerDocumentNumber())
                .customerNationality(dto.getCustomerNationality())
                .sourceOfFunds(dto.getSourceOfFunds())
                .customerIsPep(dto.getCustomerIsPep())
                .build();
    }
}
