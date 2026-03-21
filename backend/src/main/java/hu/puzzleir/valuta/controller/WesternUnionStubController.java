package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.wu.stub.WuStubRateResponse;
import hu.puzzleir.valuta.dto.wu.stub.WuStubStatusResponse;
import hu.puzzleir.valuta.dto.wu.stub.WuStubTransferRequest;
import hu.puzzleir.valuta.entity.WuTransaction;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.service.WesternUnionStubService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Pattern;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
@RestController
@RequestMapping("/api/v1/western-union-stub")
@Tag(name = "Western Union (Compatibility)", description = "Western Union kompatibilitási endpointok adapteres belső flow-val")
@Validated
@RequiredArgsConstructor
public class WesternUnionStubController {

    private final WesternUnionStubService westernUnionStubService;

    @PostMapping("/send")
    @Operation(summary = "[COMPAT] Pénzküldés indítása")
    public WuTransaction sendMoney(@Valid @RequestBody WuStubTransferRequest request) {
        return westernUnionStubService.send(request);
    }

    @PostMapping("/receive")
    @Operation(summary = "[COMPAT] Pénz átvétel")
    public WuTransaction receiveMoney(@Valid @RequestBody WuStubTransferRequest request) {
        return westernUnionStubService.receive(request);
    }

    @GetMapping("/status/{mtcn}")
    @Operation(summary = "[COMPAT] Tranzakció státusz lekérdezés")
    public WuStubStatusResponse getStatus(
            @PathVariable
            @Pattern(regexp = "\\d{10}", message = "Az MTCN pontosan 10 számjegy lehet") String mtcn) {
        if (mtcn == null || !mtcn.matches("\\d{10}")) {
            throw new ValidationException("Az MTCN pontosan 10 számjegy lehet");
        }
        return westernUnionStubService.status(mtcn);
    }

    @GetMapping("/rates")
    @Operation(summary = "[COMPAT] WU árfolyamok lekérdezése")
    public List<WuStubRateResponse> getRates() {
        return westernUnionStubService.rates();
    }
}
