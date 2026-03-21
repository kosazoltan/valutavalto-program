package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.wu.stub.WuStubRateResponse;
import hu.puzzleir.valuta.dto.wu.stub.WuStubStatusResponse;
import hu.puzzleir.valuta.dto.wu.stub.WuStubTransferRequest;
import hu.puzzleir.valuta.entity.SystemParameter;
import hu.puzzleir.valuta.entity.WuTransaction;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.repository.SystemParameterRepository;
import hu.puzzleir.valuta.service.wu.WesternUnionProviderAdapter;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Locale;

@Service
@RequiredArgsConstructor
@Slf4j
public class WesternUnionStubService {

    private static final String DEFAULT_PROVIDER = "INTERNAL";

    private final List<WesternUnionProviderAdapter> adapters;
    private final SystemParameterRepository systemParameterRepository;

    public WuTransaction send(WuStubTransferRequest request) {
        log.info("WU stub send kérés: provider={}, branchId={}, mtcn=****{}",
                resolveProviderCode(), request.getBranchId(), tail4(request.getMtcn()));
        return executeSafely(() -> resolveAdapter().send(request));
    }

    public WuTransaction receive(WuStubTransferRequest request) {
        log.info("WU stub receive kérés: provider={}, branchId={}, mtcn=****{}",
                resolveProviderCode(), request.getBranchId(), tail4(request.getMtcn()));
        return executeSafely(() -> resolveAdapter().receive(request));
    }

    public WuStubStatusResponse status(String mtcn) {
        log.info("WU stub status kérés: provider={}, mtcn=****{}", resolveProviderCode(), tail4(mtcn));
        return executeSafely(() -> resolveAdapter().status(mtcn));
    }

    public List<WuStubRateResponse> rates() {
        log.info("WU stub rates kérés: provider={}", resolveProviderCode());
        return executeSafely(() -> resolveAdapter().rates());
    }

    private WesternUnionProviderAdapter resolveAdapter() {
        String provider = resolveProviderCode();
        return adapters.stream()
                .filter(a -> a.providerCode().equalsIgnoreCase(provider))
                .findFirst()
                .orElseThrow(() -> new BusinessException(
                        "Ismeretlen WU provider: " + provider,
                        "WU_PROVIDER_NOT_SUPPORTED",
                        HttpStatus.SERVICE_UNAVAILABLE));
    }

    private String resolveProviderCode() {
        return systemParameterRepository.findByParameterKey("WU_PROVIDER_MODE")
                .map(SystemParameter::getParameterValue)
                .map(v -> v.toUpperCase(Locale.ROOT).trim())
                .filter(v -> !v.isBlank())
                .orElse(DEFAULT_PROVIDER);
    }

    private String tail4(String mtcn) {
        if (mtcn == null || mtcn.length() < 4) {
            return "****";
        }
        return mtcn.substring(mtcn.length() - 4);
    }

    private <T> T executeSafely(ThrowingSupplier<T> supplier) {
        try {
            return supplier.get();
        } catch (BusinessException ex) {
            throw ex;
        } catch (RuntimeException ex) {
            log.error("WU provider runtime hiba", ex);
            throw new BusinessException(
                    "WU provider feldolgozási hiba",
                    "WU_PROVIDER_RUNTIME_ERROR",
                    HttpStatus.BAD_GATEWAY);
        }
    }

    @FunctionalInterface
    private interface ThrowingSupplier<T> {
        T get();
    }
}
