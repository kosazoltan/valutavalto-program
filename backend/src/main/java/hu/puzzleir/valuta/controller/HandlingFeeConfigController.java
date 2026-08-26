package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.handlingfee.HandlingFeeBracketDto;
import hu.puzzleir.valuta.dto.handlingfee.HandlingFeeConfigDto;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.FeeConfigStatus;
import hu.puzzleir.valuta.entity.HandlingFeeBracket;
import hu.puzzleir.valuta.entity.HandlingFeeType;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.HandlingFeeBracketRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.SystemParameterService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/handling-fee-config")
@RequiredArgsConstructor
// FK-KEZDÍJ (2026-06-02): a "Kezelési költség beállítás" menüpont (menuGroups.ts) az
// ugyvezeto/irodavezeto/belso_ellenor kanonikus role-oknak látszik, de a controller eddig csak
// MANAGER/ADMIN-t engedett → 403. A JWT authority `ROLE_<kanonikus>` (JwtAuthenticationFilter),
// ezért a kanonikus neveket is fel kell venni. Pénztáros (PENZTAR) TILOS (a menüből is hiányzik).
// FK-KEZDÍJ-RBAC (2026-06-02 audit A2): a FOERTEKTAR (főértéktáros) is jogosult a kezelési-díj
// konfigurációra (spec FR-KC-15 + konzisztens a #999 override-mátrixszal, ahol főértéktáros módosíthat).
@PreAuthorize("hasAnyRole('MANAGER','ADMIN','UGYVEZETO','FOERTEKTAR','IRODAVEZETO','BELSO_ELLENOR')")
@Slf4j
public class HandlingFeeConfigController {

    private final SystemParameterService systemParameterService;
    private final HandlingFeeBracketRepository bracketRepository;
    private final CompanyRepository companyRepository;

    @GetMapping
    // FK-KEZDIJ B.1 (2026-06-12, penztar-batch): a PENZTAROS READ-ONLY lekerheti a konfigot,
    // hogy a kepernyo/helyi bizonylat a szerverrel azonos AUTOMATIKUS dijat mutassa (a kepernyo
    // eddig 0 Ft-ot mutatott, mikozben a szerver a konfig szerintit konyvelte). A method-szintu
    // @PreAuthorize feluldefinialja az osztaly-szintut; a PUT valtozatlanul vezetoi jog marad.
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN','UGYVEZETO','FOERTEKTAR','IRODAVEZETO','BELSO_ELLENOR','CASHIER','PENZTAR','SUPERVISOR','ERTEKTAR')")
    public ResponseEntity<HandlingFeeConfigDto> getConfig() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        String feeType;
        try {
            feeType = systemParameterService.getValue("HANDLING_FEE_TYPE");
        } catch (Exception e) {
            feeType = "BRACKET";
        }

        // A per-mille paraméterek OPCIONÁLISAK: ha nincsenek beállítva (ResourceNotFoundException) vagy
        // nem szám-formátumúak (NumberFormatException), a default (ZERO / null) marad érvényben. CSAK ezt
        // a KÉT várt kivételt kezeljük defaultként — egy váratlan hiba (pl. DB/tranzakció) NEM nyelődik el
        // "opcionális config"-ként, hanem felszáll (Copilot review). A trace-log az okot is rögzíti.
        BigDecimal perMilleRate = BigDecimal.ZERO;
        try {
            perMilleRate = new BigDecimal(systemParameterService.getValue("HANDLING_FEE_PER_MILLE"));
        } catch (ResourceNotFoundException | NumberFormatException e) {
            log.trace("HANDLING_FEE_PER_MILLE nincs beállítva/érvénytelen, default ZERO: {}", e.toString());
        }

        BigDecimal perMilleMax = null;
        try {
            perMilleMax = new BigDecimal(systemParameterService.getValue("HANDLING_FEE_PER_MILLE_MAX"));
        } catch (ResourceNotFoundException | NumberFormatException e) {
            log.trace("HANDLING_FEE_PER_MILLE_MAX nincs beállítva/érvénytelen, default null: {}", e.toString());
        }

        List<HandlingFeeBracket> brackets = bracketRepository
                .findByCompanyIdAndStatusAndActiveOrderByBracketOrder(companyId, FeeConfigStatus.LIVE, true);

        List<HandlingFeeBracketDto> bracketDtos = brackets.stream()
                .map(b -> HandlingFeeBracketDto.builder()
                        .id(b.getId())
                        .bracketOrder(b.getBracketOrder())
                        .upperLimit(b.getUpperLimit())
                        .feeAmount(b.getFeeAmount())
                        .active(b.getActive())
                        .build())
                .toList();

        return ResponseEntity.ok(HandlingFeeConfigDto.builder()
                .feeType(feeType)
                .perMilleRate(perMilleRate)
                .perMilleMaxAmount(perMilleMax)
                .brackets(bracketDtos)
                .build());
    }

    @PutMapping
    @Transactional
    @Deprecated
    public ResponseEntity<HandlingFeeConfigDto> updateConfig(@Valid @RequestBody HandlingFeeConfigDto dto) {
        // FK-096/W8/D16: a legacy PUT továbbra is írja a HANDLING_FEE_* system_parametereket
        // és 200-at ad, DE a díjszámítás azokat NEM olvassa többé (iroda-szintű feloldás).
        // Nyilvánvalóvá tesszük a logban, hogy az operátor itt hiába "javít".
        log.warn("FK-096: a legacy PUT /handling-fee-config írás NEM befolyásolja a díjszámítást"
                + " — használd a /branch-fee-config végpontokat");
        if (dto.getFeeType() == null || dto.getFeeType().isBlank()) {
            return ResponseEntity.badRequest().build();
        }
        try {
            HandlingFeeType.valueOf(dto.getFeeType().toUpperCase());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }

        systemParameterService.upsert("HANDLING_FEE_TYPE", dto.getFeeType().toUpperCase(), "HANDLING_FEE", "Kezelési díj típusa");
        if (dto.getPerMilleRate() != null) {
            systemParameterService.upsert("HANDLING_FEE_PER_MILLE", dto.getPerMilleRate().toPlainString(), "HANDLING_FEE", "Ezrelék mértéke");
        }
        if (dto.getPerMilleMaxAmount() != null) {
            systemParameterService.upsert("HANDLING_FEE_PER_MILLE_MAX", dto.getPerMilleMaxAmount().toPlainString(), "HANDLING_FEE", "Ezrelékes maximum összeg");
        }

        if (dto.getBrackets() != null) {
            saveBrackets(dto.getBrackets());
        }

        log.info("Kezelési díj konfiguráció frissítve: type={}, perMille={}, maxAmount={}",
                dto.getFeeType(), dto.getPerMilleRate(), dto.getPerMilleMaxAmount());

        return getConfig();
    }

    @PostMapping("/brackets")
    @Transactional
    public ResponseEntity<List<HandlingFeeBracketDto>> saveBracketsEndpoint(@RequestBody List<HandlingFeeBracketDto> dtos) {
        saveBrackets(dtos);
        return ResponseEntity.ok(dtos);
    }

    private void saveBrackets(List<HandlingFeeBracketDto> dtos) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new IllegalStateException("Company not found: " + companyId));

        List<HandlingFeeBracket> existing = bracketRepository
                .findByCompanyIdAndActiveOrderByBracketOrder(companyId, true);
        for (HandlingFeeBracket b : existing) {
            b.setActive(false);
        }
        bracketRepository.saveAll(existing);

        int order = 1;
        for (HandlingFeeBracketDto dto : dtos) {
            HandlingFeeBracket bracket = HandlingFeeBracket.builder()
                    .company(company)
                    .bracketOrder(order++)
                    .upperLimit(dto.getUpperLimit())
                    .feeAmount(dto.getFeeAmount())
                    .active(true)
                    .build();
            bracketRepository.save(bracket);
        }
    }
}
