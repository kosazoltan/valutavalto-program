package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.ratecreation.BankRateDTO;
import hu.puzzleir.valuta.dto.ratecreation.CompetitorRateDTO;
import hu.puzzleir.valuta.dto.ratecreation.GroupRateDTO;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.entity.ExchangeRateMaster;
import hu.puzzleir.valuta.entity.ExchangeRateMaster.MasterRateStatus;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Árfolyam-készítés szolgáltatás.
 * Bank és versenytárs árfolyamok kezelése, tervezet generálás, csoportos publikálás.
 *
 * A publishGroupRate() metódus most már ténylegesen létrehozza a törzs árfolyamot
 * és elosztja a pénztáraknak az ExchangeRateMasterService-en keresztül.
 */
@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class RateCreationService {

    private final ExchangeRateRepository exchangeRateRepository;
    private final ExchangeRateMasterService masterService;

    /**
     * Bank árfolyamok lekérése az aktuális rátákból.
     */
    @Transactional(readOnly = true)
    public List<BankRateDTO> getBankRates() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<ExchangeRate> rates = exchangeRateRepository.findActiveRatesByDate(companyId, LocalDate.now());

        return rates.stream().map(rate -> {
            BigDecimal middleRate = rate.getBaseBuyRate()
                    .add(rate.getBaseSellRate())
                    .divide(BigDecimal.valueOf(2), 4, RoundingMode.HALF_UP);

            return BankRateDTO.builder()
                    .currencyId(rate.getCurrency().getId())
                    .currencyCode(rate.getCurrency().getCode())
                    .bankBuyRate(rate.getBaseBuyRate())
                    .bankSellRate(rate.getBaseSellRate())
                    .middleRate(middleRate)
                    .lastUpdated(rate.getCreatedAt())
                    .build();
        }).collect(Collectors.toList());
    }

    /**
     * Versenytárs árfolyamok lekérése.
     * Placeholder — későbbi implementáció külső adatforrásból.
     */
    @Transactional(readOnly = true)
    public List<CompetitorRateDTO> getCompetitorRates() {
        return Collections.emptyList();
    }

    /**
     * Árfolyam tervezet generálás — MNB + bank ráták alapján margin számolással.
     */
    @Transactional(readOnly = true)
    public Map<String, Object> prepareAllRates() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<ExchangeRate> currentRates = exchangeRateRepository.findActiveRatesByDate(companyId, LocalDate.now());

        List<Map<String, Object>> proposals = currentRates.stream().map(rate -> {
            Map<String, Object> proposal = new LinkedHashMap<>();
            proposal.put("currencyId", rate.getCurrency().getId());
            proposal.put("currencyCode", rate.getCurrency().getCode());
            proposal.put("currentBuyRate", rate.getBaseBuyRate());
            proposal.put("currentSellRate", rate.getBaseSellRate());
            proposal.put("officialRate", rate.getOfficialRate());

            // Margin számolás az MNB árfolyam alapján
            if (rate.getOfficialRate() != null && rate.getOfficialRate().compareTo(BigDecimal.ZERO) > 0) {
                BigDecimal buyMargin = rate.getOfficialRate().subtract(rate.getBaseBuyRate())
                        .divide(rate.getOfficialRate(), 6, RoundingMode.HALF_UP)
                        .multiply(BigDecimal.valueOf(100));
                BigDecimal sellMargin = rate.getBaseSellRate().subtract(rate.getOfficialRate())
                        .divide(rate.getOfficialRate(), 6, RoundingMode.HALF_UP)
                        .multiply(BigDecimal.valueOf(100));
                proposal.put("buyMarginPercent", buyMargin);
                proposal.put("sellMarginPercent", sellMargin);
            }

            proposal.put("proposedBuyRate", rate.getBaseBuyRate());
            proposal.put("proposedSellRate", rate.getBaseSellRate());
            return proposal;
        }).collect(Collectors.toList());

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("generatedAt", LocalDateTime.now().toString());
        result.put("rateCount", proposals.size());
        result.put("proposals", proposals);
        return result;
    }

    /**
     * Csoportos árfolyam publikálás.
     *
     * Folyamat:
     * 1. Törzs árfolyam létrehozása (ExchangeRateMaster)
     * 2. Automatikus jóváhagyás (APPROVED → PUBLISHED)
     * 3. Elosztás a munkacsoport pénztárainak
     *
     * Legacy: ARFREG + ARFTMK - a főértéktáros beállítja az árfolyamot,
     * majd a rendszer automatikusan elküldi a pénztáraknak.
     */
    public void publishGroupRate(GroupRateDTO groupRateDTO) {
        if (groupRateDTO.getRates() == null || groupRateDTO.getRates().isEmpty()) {
            throw new ValidationException("Legalább egy árfolyamot meg kell adni a publikáláshoz!");
        }

        UUID workgroupId = groupRateDTO.getGroupId();
        log.info("Csoportos árfolyam publikálás indítása: groupId={}, {} ráta",
                workgroupId, groupRateDTO.getRates().size());

        for (GroupRateDTO.RateEntry entry : groupRateDTO.getRates()) {
            // Validáció
            if (entry.getBuyRate() == null || entry.getSellRate() == null) {
                throw new ValidationException(
                    "Hiányzó árfolyam érték! currencyId=" + entry.getCurrencyId());
            }
            if (entry.getBuyRate().compareTo(entry.getSellRate()) >= 0) {
                throw new ValidationException(
                    "Az eladási árfolyamnak nagyobbnak kell lennie a vételinél! currencyId="
                    + entry.getCurrencyId());
            }

            // 1. Törzs árfolyam létrehozása
            ExchangeRateMasterService.CreateMasterRateRequest request =
                    ExchangeRateMasterService.CreateMasterRateRequest.builder()
                            .currencyId(entry.getCurrencyId())
                            .baseBuyRate(entry.getBuyRate())
                            .baseSellRate(entry.getSellRate())
                            .notes("Csoportos publikálás - groupId=" + workgroupId)
                            .build();

            ExchangeRateMaster master = masterService.createMasterRate(request);

            // 2. Jóváhagyás
            master = masterService.approveMasterRate(master.getId());

            // 3. Publikálás és elosztás a munkacsoport pénztárainak
            masterService.publishAndDistribute(master.getId(), workgroupId);

            log.info("Árfolyam sikeresen publikálva: currencyId={}, buy={}, sell={}, groupId={}",
                    entry.getCurrencyId(), entry.getBuyRate(), entry.getSellRate(), workgroupId);
        }
    }
}
