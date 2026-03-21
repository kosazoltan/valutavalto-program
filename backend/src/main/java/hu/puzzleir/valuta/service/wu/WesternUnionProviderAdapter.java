package hu.puzzleir.valuta.service.wu;

import hu.puzzleir.valuta.dto.wu.stub.WuStubRateResponse;
import hu.puzzleir.valuta.dto.wu.stub.WuStubStatusResponse;
import hu.puzzleir.valuta.dto.wu.stub.WuStubTransferRequest;
import hu.puzzleir.valuta.entity.WuTransaction;

import java.util.List;

public interface WesternUnionProviderAdapter {

    String providerCode();

    WuTransaction send(WuStubTransferRequest request);

    WuTransaction receive(WuStubTransferRequest request);

    WuStubStatusResponse status(String mtcn);

    List<WuStubRateResponse> rates();
}
