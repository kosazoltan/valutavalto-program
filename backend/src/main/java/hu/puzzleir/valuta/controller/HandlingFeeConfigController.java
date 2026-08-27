package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.handlingfee.HandlingFeeBracketDto;
import hu.puzzleir.valuta.dto.handlingfee.HandlingFeeConfigDto;
import hu.puzzleir.valuta.entity.FeeConfigStatus;
import hu.puzzleir.valuta.entity.HandlingFeeBracket;
import hu.puzzleir.valuta.entity.HandlingFeeType;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.HandlingFeeBracketRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.BranchHandlingFeeConfigService;
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
    private final BranchHandlingFeeConfigService branchHandlingFeeConfigService;

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
    // FK-096 ITEM 1 (round 2, R2-D2): method-szintű RBAC felülírja a class-level bő kört —
    // íráshoz CSAK UGYVEZETO/FOERTEKTAR/ADMIN fér (IRODAVEZETO/BELSO_ELLENOR/MANAGER tiltva).
    // A GET pénztáros read-only elérhetősége (B.1) a saját method-annotációján marad.
    @PreAuthorize("hasAnyRole('UGYVEZETO','FOERTEKTAR','ADMIN')")
    public ResponseEntity<HandlingFeeConfigDto> updateConfig(@Valid @RequestBody HandlingFeeConfigDto dto) {
        // FK-096/W8/D16 + ITEM 1(c): a system_parameter felére vonatkozó warn — a legacy
        // kulcsokat írjuk, de a díjszámítás már az iroda-szintű feloldást olvassa.
        log.warn("FK-096: a legacy PUT /handling-fee-config system_parameter írása NEM"
                + " befolyásolja a díjszámítást — használd a /branch-fee-config végpontokat");
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

        // ITEM 1 (R2-D1): a sáv-fej NEM ír LIVE sort — DRAFT-ként delegál a közös
        // sáv-piszkozat-útra; élesítés CSAK POST /api/v1/handling-fee-bracket/publish-csal.
        // A warn CSAK akkor szól, ha a törzs ténylegesen hozott sávokat (ITEM 1c:
        // a tényeknek megfelelő üzenet request-szinten). Ha a validáció dob, a fenti
        // system_parameter upsertök azonos tranzakcióban visszagörgetnek (atomic).
        if (dto.getBrackets() != null) {
            branchHandlingFeeConfigService.saveBracketDraft(dto.getBrackets());
            log.warn("FK-096: a PUT /handling-fee-config sávjai PISZKOZATKÉNT (DRAFT) mentődtek —"
                    + " élesítés: POST /api/v1/handling-fee-bracket/publish");
        }

        log.info("Kezelési díj konfiguráció frissítve: type={}, perMille={}, maxAmount={}",
                dto.getFeeType(), dto.getPerMilleRate(), dto.getPerMilleMaxAmount());

        return getConfig();
    }

    @PostMapping("/brackets")
    @Transactional
    @Deprecated
    @PreAuthorize("hasAnyRole('UGYVEZETO','FOERTEKTAR','ADMIN')")
    public ResponseEntity<List<HandlingFeeBracketDto>> saveBracketsEndpoint(@RequestBody List<HandlingFeeBracketDto> dtos) {
        // ITEM 1 (R2-D1): DRAFT-delegáció — a response a mentett DRAFT-készlet (byte-kompatibilis
        // List<HandlingFeeBracketDto> alak), LIVE sor ezen az úton nem keletkezik.
        log.warn("FK-096: a legacy POST /handling-fee-config/brackets PISZKOZATKÉNT (DRAFT) ment —"
                + " élesítés: POST /api/v1/handling-fee-bracket/publish");
        return ResponseEntity.ok(branchHandlingFeeConfigService.saveBracketDraft(dtos).getDraft());
    }
}
