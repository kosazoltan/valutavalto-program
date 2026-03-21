package hu.puzzleir.valuta.service.wu;

import hu.puzzleir.valuta.dto.wu.stub.WuStubRateResponse;
import hu.puzzleir.valuta.dto.wu.stub.WuStubStatusResponse;
import hu.puzzleir.valuta.dto.wu.stub.WuStubTransferRequest;
import hu.puzzleir.valuta.entity.WuTransaction;
import hu.puzzleir.valuta.exception.BusinessException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class InactiveWesternUnionAdapter implements WesternUnionProviderAdapter {

    @Override
    public String providerCode() {
        return "INACTIVE";
    }

    @Override
    public WuTransaction send(WuStubTransferRequest request) {
        throw inactive();
    }

    @Override
    public WuTransaction receive(WuStubTransferRequest request) {
        throw inactive();
    }

    @Override
    public WuStubStatusResponse status(String mtcn) {
        throw inactive();
    }

    @Override
    public List<WuStubRateResponse> rates() {
        throw inactive();
    }

    private BusinessException inactive() {
        return new BusinessException(
                "Western Union provider inaktív vagy letiltott",
                "WU_PROVIDER_INACTIVE",
                HttpStatus.CONFLICT
        );
    }
}
