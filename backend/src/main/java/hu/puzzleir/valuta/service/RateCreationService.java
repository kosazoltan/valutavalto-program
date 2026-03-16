package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.ratecreation.BankRateDTO;
import hu.puzzleir.valuta.dto.ratecreation.CompetitorRateDTO;
import hu.puzzleir.valuta.dto.ratecreation.GroupRateDTO;
import hu.puzzleir.valuta.entity.CompetitorRate;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CompetitorRateRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
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
 * Legacy: arfolyamkarbantarto (arftmk DLL) — a főértéktáros által
 * az árfolyam-készítő modulban végrehajtott műveletek.
 */
@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class RateCreationService {

    private final ExchangeRateRepository exchangeRateRepository;
    private final CompetitorRateRepository competitorRateRepository;
    private final CurrencyRepository currencyRepository;
    private final ExchangeRateService exchangeRateService;

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
     * Versenytárs árfolyamok lekérése a competitor_rates táblából.
     *
     * Legacy: a régi rendszerben manuálisan rögzítették a versenytársak
     * árfolyamait az összehasonlítás és versenyképes árazás érdekében.
     */
    @Transactional(readOnly = true)
    public List<CompetitorRateDTO> getCompetitorRates() {
        List<CompetitorRate> rates = competitorRateRepository.findLatestRatesWithDetails();

        return rates.stream().map(cr -> CompetitorRateDTO.builder()
                .competitorId(cr.getCompetitor().getId())
                .competitorName(cr.getCompetitor().getName())
                .currencyCode(cr.getCurrency().getCode())
                .buyRate(cr.getBuyRate())
                .sellRate(cr.getSellRate())
                .lastUpdated(cr.getCreatedAt())
                .build())
                .collect(Collectors.toList());
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
     * Legacy: MNBArfKikuldo — a főértéktáros által elkészített árfolyamok
     * kiküldése a pénztáraknak. A régi rendszerben ez bináris fájlokat
     * generált (AF100.xxx) és FTP-n küldte ki.
     *
     * Új rendszer: minden valutához létrehozza az ExchangeRate rekordot
     * az ExchangeRateService-en keresztül.
     */
    public void publishGroupRate(GroupRateDTO groupRateDTO) {
        if (groupRateDTO.getRates() == null || groupRateDTO.getRates().isEmpty()) {
            throw new ValidationException("Nincs publikálandó árfolyam!");
        }

        log.info("Csoportos árfolyam publikálás groupId={}, {} ráta",
                groupRateDTO.getGroupId(),
                groupRateDTO.getRates().size());

        int created = 0;
        for (GroupRateDTO.RateEntry entry : groupRateDTO.getRates()) {
            if (entry.getBuyRate() == null || entry.getSellRate() == null) {
                log.warn("Hiányzó árfolyam: currencyId={}", entry.getCurrencyId());
                continue;
            }

            if (entry.getSellRate().compareTo(entry.getBuyRate()) <= 0) {
                throw new ValidationException(
                        "Eladási árfolyam nagyobb kell legyen a vételinél! currencyId=" + entry.getCurrencyId());
            }

            ExchangeRateService.CreateExchangeRateRequest request =
                    ExchangeRateService.CreateExchangeRateRequest.builder()
                            .currencyId(entry.getCurrencyId())
                            .baseBuyRate(entry.getBuyRate())
                            .baseSellRate(entry.getSellRate())
                            .officialRate(entry.getOfficialRate())
                            .limit1Amount(entry.getLimit1Amount())
                            .limit1BuyRate(entry.getLimit1BuyRate())
                            .limit1SellRate(entry.getLimit1SellRate())
                            .limit2Amount(entry.getLimit2Amount())
                            .limit2BuyRate(entry.getLimit2BuyRate())
                            .limit2SellRate(entry.getLimit2SellRate())
                            .limit3Amount(entry.getLimit3Amount())
                            .limit3BuyRate(entry.getLimit3BuyRate())
                            .limit3SellRate(entry.getLimit3SellRate())
                            .build();

            exchangeRateService.createExchangeRate(request);
            created++;
        }

        log.info("Csoportos árfolyam publikálva: {} ráta létrehozva", created);
    }
}
