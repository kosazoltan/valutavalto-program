package hu.puzzleir.valuta.service.wu;

import hu.puzzleir.valuta.dto.wu.WuTransactionDto;
import hu.puzzleir.valuta.dto.wu.stub.WuStubRateResponse;
import hu.puzzleir.valuta.dto.wu.stub.WuStubStatusResponse;
import hu.puzzleir.valuta.dto.wu.stub.WuStubTransferRequest;
import hu.puzzleir.valuta.entity.SystemParameter;
import hu.puzzleir.valuta.entity.WuTransaction;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.SystemParameterRepository;
import hu.puzzleir.valuta.repository.WuTransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.WesternUnionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.List;

@Component
@RequiredArgsConstructor
public class InternalWesternUnionAdapter implements WesternUnionProviderAdapter {

    private final WesternUnionService westernUnionService;
    private final WuTransactionRepository wuTransactionRepository;
    private final SystemParameterRepository systemParameterRepository;

    @Override
    public String providerCode() {
        return "INTERNAL";
    }

    @Override
    public WuTransaction send(WuStubTransferRequest request) {
        return westernUnionService.recordSend(toDto(request));
    }

    @Override
    public WuTransaction receive(WuStubTransferRequest request) {
        return westernUnionService.recordReceive(toDto(request));
    }

    @Override
    public WuStubStatusResponse status(String mtcn) {
        WuTransaction tx = wuTransactionRepository
                .findFirstByMtcnAndCompanyIdOrderByTransactionDateDesc(mtcn, SecurityUtils.getCurrentCompanyId())
                .orElseThrow(() -> new ResourceNotFoundException("WU tranzakció nem található MTCN alapján"));

        return WuStubStatusResponse.builder()
                .mtcn(mtcn)
                .status(tx.getStatus() != null ? tx.getStatus().name() : "UNKNOWN")
                .transactionType(tx.getTransactionType())
                .transactionId(tx.getId())
                .transactionDate(tx.getTransactionDate())
                .provider(providerCode())
                .build();
    }

    @Override
    public List<WuStubRateResponse> rates() {
        BigDecimal buy = readRate("WU_RATE_USD_HUF_BUY", "395.00");
        BigDecimal sell = readRate("WU_RATE_USD_HUF_SELL", "405.00");

        return List.of(WuStubRateResponse.builder()
                .pair("USD/HUF")
                .buyRate(buy)
                .sellRate(sell)
                .provider(providerCode())
                .build());
    }

    private BigDecimal readRate(String key, String fallback) {
        return systemParameterRepository.findByParameterKey(key)
                .map(SystemParameter::getParameterValue)
                .map(v -> {
                    try {
                        return new BigDecimal(v);
                    } catch (NumberFormatException ex) {
                        return new BigDecimal(fallback);
                    }
                })
                .orElse(new BigDecimal(fallback));
    }

    private WuTransactionDto toDto(WuStubTransferRequest request) {
        return WuTransactionDto.builder()
                .branchId(request.getBranchId())
                .wuCustomerId(request.getWuCustomerId())
                .mtcn(request.getMtcn())
                .amountUsd(request.getAmountUsd())
                .amountHuf(request.getAmountHuf())
                .feeAmount(request.getFeeAmount())
                .exchangeRate(request.getExchangeRate())
                .senderName(request.getSenderName())
                .receiverName(request.getReceiverName())
                .destinationCountry(request.getDestinationCountry())
                .receiptNumber(request.getReceiptNumber())
                .transactionDate(request.getTransactionDate())
                .build();
    }
}
