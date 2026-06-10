package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.bankapi.BankApiConfigDto;
import hu.puzzleir.valuta.dto.bankapi.UpdateBankApiConfigRequest;
import hu.puzzleir.valuta.service.BankApiConfigService;
import hu.puzzleir.valuta.service.RaiffeisenRateService;
import jakarta.validation.Valid;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/bank-api-config")
@RequiredArgsConstructor
public class BankApiConfigController {

    private final BankApiConfigService bankApiConfigService;
    private final RaiffeisenRateService raiffeisenRateService;

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','TREASURY_MANAGER','MAIN_TREASURY','COMPLIANCE_OFFICER')")
    public List<BankApiConfigDto> list() {
        return bankApiConfigService.list();
    }

    @GetMapping("/{providerName}")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','TREASURY_MANAGER','MAIN_TREASURY','COMPLIANCE_OFFICER')")
    public BankApiConfigDto get(@PathVariable String providerName) {
        return bankApiConfigService.getDto(providerName);
    }

    @PutMapping("/{providerName}")
    @PreAuthorize("hasRole('ADMIN')")
    public BankApiConfigDto update(
            @PathVariable String providerName,
            @Valid @RequestBody UpdateBankApiConfigRequest request) {
        return bankApiConfigService.update(providerName, request);
    }

    @PostMapping("/raiffeisen/fetch-now")
    @PreAuthorize("hasAnyRole('ADMIN','TREASURY_MANAGER','MAIN_TREASURY')")
    public FetchNowResponse fetchRaiffeisenNow() {
        int saved = raiffeisenRateService.fetchAndCacheRates();
        FetchNowResponse response = new FetchNowResponse();
        response.setSavedRates(saved);
        response.setConfig(bankApiConfigService.getDto(BankApiConfigService.PROVIDER_RAIFFEISEN));
        return response;
    }

    @Data
    public static class FetchNowResponse {
        private int savedRates;
        private BankApiConfigDto config;
    }
}
