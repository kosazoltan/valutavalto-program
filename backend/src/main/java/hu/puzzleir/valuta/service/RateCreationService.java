package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.dto.ratecreation.BankRateDTO;
import hu.puzzleir.valuta.dto.ratecreation.BranchListDTO;
import hu.puzzleir.valuta.dto.ratecreation.CompetitorRateDTO;
import hu.puzzleir.valuta.dto.ratecreation.GroupRateDTO;
import hu.puzzleir.valuta.dto.ratecreation.RateCreationResponseDTO;
import hu.puzzleir.valuta.dto.ratecreation.RateOverviewDTO;
import hu.puzzleir.valuta.dto.ratecreation.WorkgroupDetailDTO;
import hu.puzzleir.valuta.dto.ratemaker.LocalRateMakerBootstrapDto;
import hu.puzzleir.valuta.dto.ratemaker.LocalRatePackageDto;
import hu.puzzleir.valuta.dto.ratemaker.LocalRatePublishResponseDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.CompetitorRate;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.entity.RatePublication;
import hu.puzzleir.valuta.entity.RateTemplate;
import hu.puzzleir.valuta.entity.RateWorkgroup;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CompetitorRateRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.repository.RatePublicationRepository;
import hu.puzzleir.valuta.repository.RateTemplateRepository;
import hu.puzzleir.valuta.repository.RateWorkgroupRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.HexFormat;
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
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class RateCreationService {

    private final BranchRepository branchRepository;
    private final ExchangeRateRepository exchangeRateRepository;
    private final CompetitorRateRepository competitorRateRepository;
    private final CurrencyRepository currencyRepository;
    private final CompanyRepository companyRepository;
    private final RateTemplateRepository rateTemplateRepository;
    private final RateWorkgroupRepository rateWorkgroupRepository;
    private final RatePublicationRepository ratePublicationRepository;
    private final RatePublishService ratePublishService;
    private final ObjectMapper objectMapper;

    /**
     * Bank árfolyamok lekérése az aktuális rátákból.
     * Fallback: ha a mai napra nincs adat, a legutolsó elérhető napot adja vissza.
     */
    @Transactional(readOnly = true)
    public List<BankRateDTO> getBankRates() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<ExchangeRate> rates = findActiveRatesWithFallback(companyId);

        return rates.stream().map(rate -> {
            BigDecimal middleRate = rate.getBaseBuyRate()
                    .add(rate.getBaseSellRate())
                    .divide(BigDecimal.valueOf(2), 4, RoundingMode.HALF_UP);

            String branchName = rate.getBranch() != null ? rate.getBranch().getName() : "EBC";
            String branchCode = rate.getBranch() != null
                    ? rate.getBranch().getId().toString().substring(0, 6).toUpperCase()
                    : "EBC";

            return BankRateDTO.builder()
                    .id(rate.getId())
                    .bankName(branchName)
                    .bankCode(branchCode)
                    .currencyId(rate.getCurrency().getId())
                    .currencyCode(rate.getCurrency().getCode())
                    .buyRate(rate.getBaseBuyRate())
                    .sellRate(rate.getBaseSellRate())
                    .middleRate(middleRate)
                    .validFrom(rate.getCreatedAt())
                    .source("MANUAL")
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

        return rates.stream().map(cr -> buildCompetitorRateDTO(cr)).collect(Collectors.toList());
    }

    /**
     * Árfolyam-készítés előkészítése egy adott valutához.
     * GET /api/v1/rate-creation/prepare/{currencyId}
     *
     * Összegyűjti a bank (exchange_rate) és versenytárs árfolyamokat,
     * kiszámítja a min/max/avg statisztikákat és ajánlott rátákat.
     */
    @Transactional(readOnly = true)
    public RateCreationResponseDTO prepareRateCreation(Long currencyId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        Currency currency = currencyRepository.findById(currencyId)
                .orElseThrow(() -> new ValidationException("Valuta nem található: " + currencyId));

        // Bank ráták: exchange_rate tábla aktuális bejegyzései az adott valutához
        List<ExchangeRate> exchangeRates = exchangeRateRepository
                .findActiveByCurrencyAndDateForCompany(companyId, currencyId, LocalDate.now());

        List<BankRateDTO> bankRates = exchangeRates.stream().map(rate -> {
            BigDecimal middleRate = rate.getBaseBuyRate()
                    .add(rate.getBaseSellRate())
                    .divide(BigDecimal.valueOf(2), 4, RoundingMode.HALF_UP);

            String branchName = rate.getBranch() != null ? rate.getBranch().getName() : "EBC";
            String branchCode = rate.getBranch() != null
                    ? rate.getBranch().getId().toString().substring(0, 6).toUpperCase()
                    : "EBC";

            return BankRateDTO.builder()
                    .id(rate.getId())
                    .bankName(branchName)
                    .bankCode(branchCode)
                    .currencyId(rate.getCurrency().getId())
                    .currencyCode(rate.getCurrency().getCode())
                    .buyRate(rate.getBaseBuyRate())
                    .sellRate(rate.getBaseSellRate())
                    .middleRate(middleRate)
                    .validFrom(rate.getCreatedAt())
                    .source("MANUAL")
                    .build();
        }).collect(Collectors.toList());

        // Versenytárs ráták
        List<CompetitorRate> competitorRateEntities =
                competitorRateRepository.findLatestRatesByCurrencyId(currencyId);
        List<CompetitorRateDTO> competitorRates = competitorRateEntities.stream()
                .map(this::buildCompetitorRateDTO)
                .collect(Collectors.toList());

        // Összes vételi és eladási ráta összegyűjtése a statisztikához
        List<BigDecimal> allBuyRates = new ArrayList<>();
        List<BigDecimal> allSellRates = new ArrayList<>();

        bankRates.forEach(b -> {
            if (b.getBuyRate() != null) allBuyRates.add(b.getBuyRate());
            if (b.getSellRate() != null) allSellRates.add(b.getSellRate());
        });
        competitorRates.forEach(c -> {
            if (c.getBuyRate() != null) allBuyRates.add(c.getBuyRate());
            if (c.getSellRate() != null) allSellRates.add(c.getSellRate());
        });

        BigDecimal minBuy  = allBuyRates.stream().min(BigDecimal::compareTo).orElse(null);
        BigDecimal maxBuy  = allBuyRates.stream().max(BigDecimal::compareTo).orElse(null);
        BigDecimal avgBuy  = allBuyRates.isEmpty() ? null :
                allBuyRates.stream().reduce(BigDecimal.ZERO, BigDecimal::add)
                        .divide(BigDecimal.valueOf(allBuyRates.size()), 4, RoundingMode.HALF_UP);

        BigDecimal minSell = allSellRates.stream().min(BigDecimal::compareTo).orElse(null);
        BigDecimal maxSell = allSellRates.stream().max(BigDecimal::compareTo).orElse(null);
        BigDecimal avgSell = allSellRates.isEmpty() ? null :
                allSellRates.stream().reduce(BigDecimal.ZERO, BigDecimal::add)
                        .divide(BigDecimal.valueOf(allSellRates.size()), 4, RoundingMode.HALF_UP);

        // Ajánlott ráták: a cég aktuális exchange_rate bejegyzéséből (legfrissebb)
        BigDecimal recommendedBuy  = exchangeRates.isEmpty() ? avgBuy  : exchangeRates.get(0).getBaseBuyRate();
        BigDecimal recommendedSell = exchangeRates.isEmpty() ? avgSell : exchangeRates.get(0).getBaseSellRate();
        BigDecimal recommendedMiddle = (recommendedBuy != null && recommendedSell != null)
                ? recommendedBuy.add(recommendedSell).divide(BigDecimal.valueOf(2), 4, RoundingMode.HALF_UP)
                : null;

        return RateCreationResponseDTO.builder()
                .currencyId(currency.getId())
                .currencyCode(currency.getCode())
                .currencyName(currency.getName())
                .bankRates(bankRates)
                .competitorRates(competitorRates)
                .recommendedBuyRate(recommendedBuy)
                .recommendedSellRate(recommendedSell)
                .recommendedMiddleRate(recommendedMiddle)
                .minBuyRate(minBuy)
                .maxBuyRate(maxBuy)
                .avgBuyRate(avgBuy)
                .minSellRate(minSell)
                .maxSellRate(maxSell)
                .avgSellRate(avgSell)
                .notes(null)
                .build();
    }

    /** Segédmetódus: CompetitorRate entity → CompetitorRateDTO */
    private CompetitorRateDTO buildCompetitorRateDTO(CompetitorRate cr) {
        BigDecimal middleRate = null;
        if (cr.getBuyRate() != null && cr.getSellRate() != null) {
            middleRate = cr.getBuyRate().add(cr.getSellRate())
                    .divide(BigDecimal.valueOf(2), 4, RoundingMode.HALF_UP);
        }
        // Versenytárs kód: a neve alapján generált rövidítés (első 6 karakter, nagybetű)
        // AI REVIEW FIX (PR #98 Sourcery P2): ha competitorName csak non-alphanumeric (pl. "***", "   "),
        // cleaned = "" -> empty competitorCode. Consumer (DTO) non-empty ID-t var. Fallback "COMP".
        String competitorName = cr.getCompetitor() != null ? cr.getCompetitor().getName() : null;
        String competitorCode;
        if (competitorName != null) {
            String cleaned = competitorName.replaceAll("[^A-Za-z0-9]", "").toUpperCase();
            competitorCode = cleaned.isEmpty() ? "COMP" : cleaned.substring(0, Math.min(6, cleaned.length()));
        } else {
            competitorCode = "COMP";
        }

        return CompetitorRateDTO.builder()
                .id(cr.getId())
                .competitorName(competitorName)
                .competitorCode(competitorCode)
                .currencyCode(cr.getCurrency().getCode())
                .buyRate(cr.getBuyRate())
                .sellRate(cr.getSellRate())
                .middleRate(middleRate)
                .recordedAt(cr.getCreatedAt())
                .source(cr.getSource() != null ? cr.getSource() : "MANUAL")
                .build();
    }

    /**
     * Munkacsoport részletek lekérése — branch hozzárendelésekkel.
     */
    @Transactional(readOnly = true)
    public List<WorkgroupDetailDTO> getWorkgroupDetails() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<RateWorkgroup> workgroups = rateWorkgroupRepository.findByCompanyIdAndActiveTrue(companyId);

        return workgroups.stream().map(wg -> {
            List<WorkgroupDetailDTO.BranchInfo> branchInfos = wg.getBranches().stream()
                    .map(b -> WorkgroupDetailDTO.BranchInfo.builder()
                            .id(b.getId())
                            .code(b.getCode())
                            .name(b.getName())
                            .build())
                    .sorted((a, b) -> a.getName().compareToIgnoreCase(b.getName()))
                    .collect(Collectors.toList());

            // Limit boundaries: az entity-ből, ha nincs beállítva → default értékek
            BigDecimal limit1Boundary = wg.getLimit1Boundary() != null ? wg.getLimit1Boundary() : BigDecimal.valueOf(50000);
            BigDecimal limit2Boundary = wg.getLimit2Boundary() != null ? wg.getLimit2Boundary() : BigDecimal.valueOf(300000);
            BigDecimal limit3Boundary = wg.getLimit3Boundary() != null ? wg.getLimit3Boundary() : BigDecimal.valueOf(1000000);

            return WorkgroupDetailDTO.builder()
                    .id(wg.getId())
                    .code(wg.getCode())
                    .name(wg.getName())
                    .legacyGroupNumber(wg.getLegacyGroupNumber())
                    .active(wg.getActive())
                    .branches(branchInfos)
                    .limit1Boundary(limit1Boundary)
                    .limit2Boundary(limit2Boundary)
                    .limit3Boundary(limit3Boundary)
                    .build();
        }).collect(Collectors.toList());
    }

    /**
     * Árfolyam áttekintő — ÖSSZES aktív valuta jelenlegi árfolyamokkal.
     * A főértéktáros áttekintő nézetéhez.
     */
    @Transactional(readOnly = true)
    public RateOverviewDTO getRateOverview() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        LocalDate today = LocalDate.now();

        // Összes aktív valuta
        List<Currency> activeCurrencies = currencyRepository.findByActiveTrueOrderByDisplayOrderAsc();

        // Aktuális exchange_rate-ek (company + dátum szűrés, fallback ha nincs mai adat)
        List<ExchangeRate> currentRates = findActiveRatesWithFallback(companyId);

        // Map: currencyId → legfrissebb ExchangeRate
        Map<Long, ExchangeRate> rateMap = new LinkedHashMap<>();
        for (ExchangeRate rate : currentRates) {
            Long cid = rate.getCurrency().getId();
            if (!rateMap.containsKey(cid)) {
                rateMap.put(cid, rate);
            }
        }

        List<RateOverviewDTO.CurrencyRateItem> items = activeCurrencies.stream()
                .filter(c -> !"HUF".equals(c.getCode())) // HUF-ot kiszűrjük
                .map(currency -> {
                    ExchangeRate rate = rateMap.get(currency.getId());

                    RateOverviewDTO.CurrencyRateItem.CurrencyRateItemBuilder builder =
                            RateOverviewDTO.CurrencyRateItem.builder()
                                    .currencyId(currency.getId())
                                    .currencyCode(currency.getCode())
                                    .currencyName(currency.getName())
                                    .displayOrder(currency.getDisplayOrder())
                                    .hasRate(rate != null);

                    if (rate != null) {
                        builder.currentBuyRate(rate.getBaseBuyRate())
                                .currentSellRate(rate.getBaseSellRate())
                                .officialRate(rate.getOfficialRate())
                                .limit1Amount(rate.getLimit1Amount())
                                .limit1BuyRate(rate.getLimit1BuyRate())
                                .limit1SellRate(rate.getLimit1SellRate())
                                .limit2Amount(rate.getLimit2Amount())
                                .limit2BuyRate(rate.getLimit2BuyRate())
                                .limit2SellRate(rate.getLimit2SellRate())
                                .limit3Amount(rate.getLimit3Amount())
                                .limit3BuyRate(rate.getLimit3BuyRate())
                                .limit3SellRate(rate.getLimit3SellRate())
                                .lastUpdated(rate.getCreatedAt());

                        // Középárfolyam
                        BigDecimal middle = rate.getBaseBuyRate()
                                .add(rate.getBaseSellRate())
                                .divide(BigDecimal.valueOf(2), 4, RoundingMode.HALF_UP);
                        builder.middleRate(middle);

                        // Spread %
                        if (rate.getBaseBuyRate().compareTo(BigDecimal.ZERO) > 0) {
                            BigDecimal spread = rate.getBaseSellRate().subtract(rate.getBaseBuyRate())
                                    .divide(rate.getBaseBuyRate(), 4, RoundingMode.HALF_UP)
                                    .multiply(BigDecimal.valueOf(100));
                            builder.spreadPercent(spread);
                        }

                        // MNB margin %
                        if (rate.getOfficialRate() != null && rate.getOfficialRate().compareTo(BigDecimal.ZERO) > 0) {
                            BigDecimal buyMargin = rate.getOfficialRate().subtract(rate.getBaseBuyRate())
                                    .divide(rate.getOfficialRate(), 6, RoundingMode.HALF_UP)
                                    .multiply(BigDecimal.valueOf(100));
                            BigDecimal sellMargin = rate.getBaseSellRate().subtract(rate.getOfficialRate())
                                    .divide(rate.getOfficialRate(), 6, RoundingMode.HALF_UP)
                                    .multiply(BigDecimal.valueOf(100));
                            builder.buyMarginPercent(buyMargin);
                            builder.sellMarginPercent(sellMargin);
                        }
                    }

                    return builder.build();
                })
                .collect(Collectors.toList());

        return RateOverviewDTO.builder()
                .generatedAt(LocalDateTime.now())
                .currencies(items)
                .build();
    }

    /**
     * Árfolyam tervezet generálás — MNB + bank ráták alapján margin számolással.
     */
    @Transactional(readOnly = true)
    public Map<String, Object> prepareAllRates() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<ExchangeRate> currentRates = findActiveRatesWithFallback(companyId);

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
     * Csoportos árfolyam publikálás a template → publish pipeline-on keresztül.
     *
     * Legacy: MNBArfKikuldo — a főértéktáros által elkészített árfolyamok
     * kiküldése a pénztáraknak. A régi rendszerben bináris fájlokat generált
     * (ARFDATA.DAT) és FTP-n küldte ki.
     *
     * Új rendszer: RateTemplate rekordokat hoz létre (auto-APPROVED),
     * majd a RatePublishService.publish()-on keresztül menti az exchange_rate-be
     * ÉS outbox event-et hoz létre a WebSocket push-hoz.
     */
    public void publishGroupRate(GroupRateDTO groupRateDTO) {
        publishGroupRateAndReturnPublication(groupRateDTO);
    }

    public RatePublication publishGroupRateAndReturnPublication(GroupRateDTO groupRateDTO) {
        return publishGroupRateInternal(groupRateDTO, "Árfolyam rögzítés publikálás", null);
    }

    public LocalRateMakerBootstrapDto getLocalRateMakerBootstrap() {
        return LocalRateMakerBootstrapDto.builder()
                .generatedAt(LocalDateTime.now())
                .mode("LOCAL_RATE_MAKER")
                .publishEndpoint("/api/v1/local-rate-maker/packages/publish")
                .idempotencyRequired(true)
                .overview(getRateOverview())
                .workgroups(getWorkgroupDetails())
                .build();
    }

    public LocalRatePublishResponseDto publishLocalRatePackage(LocalRatePackageDto packageDto) {
        if (packageDto.getGroupId() == null) {
            throw new ValidationException("Helyi árfolyamcsomag csak explicit munkacsoporttal publikálható.");
        }
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (ratePublicationRepository.existsByCompanyIdAndClientPackageId(companyId, packageDto.getClientPackageId())) {
            throw new ValidationException("Ez az árfolyamcsomag már beérkezett: " + packageDto.getClientPackageId());
        }

        String serverPackageHash = computeServerPackageHash(packageDto);
        GroupRateDTO groupRateDTO = GroupRateDTO.builder()
                .groupId(packageDto.getGroupId())
                .rates(packageDto.getRates())
                .build();

        String notes = buildLocalPackageNotes(packageDto, serverPackageHash);
        RatePublishService.PublicationMetadata metadata = new RatePublishService.PublicationMetadata(
                "LOCAL_RATE_MAKER",
                packageDto.getClientPackageId(),
                serverPackageHash,
                packageDto.getClientVersion(),
                packageDto.getClientDeviceId());

        RatePublication publication = publishGroupRateInternal(groupRateDTO, notes, metadata);
        RateWorkgroup workgroup = rateWorkgroupRepository.findById(packageDto.getGroupId())
                .orElseThrow(() -> new ValidationException("Munkacsoport nem található: " + packageDto.getGroupId()));

        List<String> branchCodes = workgroup.getBranches().stream()
                .map(Branch::getCode)
                .sorted()
                .toList();

        return LocalRatePublishResponseDto.builder()
                .publicationId(publication.getId())
                .workgroupId(publication.getWorkgroupId())
                .publishedAt(publication.getPublishedAt())
                .acceptedRates(packageDto.getRates().size())
                .affectedBranches(publication.getAffectedBranches() != null ? publication.getAffectedBranches() : 0)
                .status("ACCEPTED_AND_DISTRIBUTION_QUEUED")
                .serverPackageHash(serverPackageHash)
                .branchCodes(branchCodes)
                .build();
    }

    private RatePublication publishGroupRateInternal(GroupRateDTO groupRateDTO,
                                                    String publicationNotes,
                                                    RatePublishService.PublicationMetadata metadata) {
        if (groupRateDTO.getRates() == null || groupRateDTO.getRates().isEmpty()) {
            throw new ValidationException("Nincs publikálandó árfolyam!");
        }

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ValidationException("Cég nem található"));

        // Munkacsoport meghatározás
        UUID workgroupId = groupRateDTO.getGroupId();
        if (workgroupId == null) {
            workgroupId = rateWorkgroupRepository.findByCompanyIdAndActiveTrue(companyId)
                    .stream().findFirst()
                    .map(RateWorkgroup::getId)
                    .orElseThrow(() -> new ValidationException(
                            "Nincs aktív munkacsoport! Hozzon létre egyet az Árfolyam kezelés > Munkacsoportok menüben."));
        }

        log.info("Csoportos árfolyam publikálás pipeline-on: groupId={}, {} ráta",
                workgroupId, groupRateDTO.getRates().size());

        List<UUID> templateIds = new ArrayList<>();
        LocalDateTime now = LocalDateTime.now();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        for (GroupRateDTO.RateEntry entry : groupRateDTO.getRates()) {
            if (entry.getBuyRate() == null || entry.getSellRate() == null) {
                log.warn("Hiányzó árfolyam: currencyId={}", entry.getCurrencyId());
                continue;
            }

            if (entry.getSellRate().compareTo(entry.getBuyRate()) <= 0) {
                throw new ValidationException(
                        "Eladási árfolyam nagyobb kell legyen a vételinél! currencyId=" + entry.getCurrencyId());
            }

            RateTemplate template = RateTemplate.builder()
                    .company(company)
                    .currencyId(entry.getCurrencyId())
                    .workgroupId(workgroupId)
                    .baseBuyRate(entry.getBuyRate())
                    .baseSellRate(entry.getSellRate())
                    .buySpread(BigDecimal.ZERO)
                    .sellSpread(BigDecimal.ZERO)
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
                    .status(RateTemplate.RateTemplateStatus.APPROVED)
                    .createdBy(workerId)
                    .approvedBy(workerId)
                    .createdAt(now)
                    .approvedAt(now)
                    .build();

            template = rateTemplateRepository.save(template);
            templateIds.add(template.getId());
        }

        if (templateIds.isEmpty()) {
            throw new ValidationException("Nem sikerült egyetlen árfolyam sablont sem létrehozni!");
        }

        // Publish: exchange_rate INSERT + outbox event → WebSocket push a pénztáraknak
        RatePublication publication = ratePublishService.publish(workgroupId, templateIds, publicationNotes, metadata);

        log.info("Csoportos árfolyam publikálva pipeline-on: {} sablon → exchange_rate + WebSocket push", templateIds.size());
        return publication;
    }

    private String buildLocalPackageNotes(LocalRatePackageDto packageDto, String serverPackageHash) {
        List<String> parts = new ArrayList<>();
        parts.add("LOCAL_RATE_MAKER");
        parts.add("packageId=" + safeAuditValue(packageDto.getClientPackageId()));
        parts.add("clientVersion=" + safeAuditValue(packageDto.getClientVersion()));
        parts.add("deviceId=" + safeAuditValue(packageDto.getClientDeviceId()));
        parts.add("serverHash=" + serverPackageHash);
        if (packageDto.getClientPackageHash() != null && !packageDto.getClientPackageHash().isBlank()) {
            parts.add("clientHash=" + safeAuditValue(packageDto.getClientPackageHash()));
        }
        if (packageDto.getCreatedAt() != null) {
            parts.add("clientCreatedAt=" + packageDto.getCreatedAt());
        }
        if (packageDto.getOperatorNote() != null && !packageDto.getOperatorNote().isBlank()) {
            parts.add("note=" + safeAuditValue(packageDto.getOperatorNote()));
        }
        if (packageDto.getSignature() != null && !packageDto.getSignature().isBlank()) {
            parts.add("signaturePresent=true");
        }
        return String.join("; ", parts);
    }

    private String safeAuditValue(String value) {
        return value == null ? "" : value.trim().replace('\n', ' ').replace('\r', ' ');
    }

    private String computeServerPackageHash(LocalRatePackageDto packageDto) {
        try {
            Map<String, Object> canonical = new LinkedHashMap<>();
            canonical.put("clientPackageId", packageDto.getClientPackageId());
            canonical.put("clientDeviceId", packageDto.getClientDeviceId());
            canonical.put("clientVersion", packageDto.getClientVersion());
            canonical.put("createdAt", packageDto.getCreatedAt());
            canonical.put("groupId", packageDto.getGroupId());
            canonical.put("rates", packageDto.getRates());

            byte[] json = objectMapper.writeValueAsString(canonical).getBytes(StandardCharsets.UTF_8);
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(json));
        } catch (JsonProcessingException | NoSuchAlgorithmException e) {
            throw new IllegalStateException("Árfolyamcsomag hash számítás sikertelen", e);
        }
    }

    // ====== BRANCH MANAGEMENT ======

    /**
     * Összes aktív iroda lekérése, jelölve hogy melyik van hozzárendelve a megadott munkacsoporthoz.
     */
    @Transactional(readOnly = true)
    public List<BranchListDTO> getAllBranchesForWorkgroup(UUID workgroupId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        RateWorkgroup workgroup = rateWorkgroupRepository.findById(workgroupId)
                .orElseThrow(() -> new ValidationException("Munkacsoport nem található: " + workgroupId));

        if (!workgroup.getCompany().getId().equals(companyId)) {
            throw new ValidationException("Munkacsoport nem tartozik az aktuális céghez");
        }

        Set<UUID> assignedBranchIds = workgroup.getBranches().stream()
                .map(Branch::getId)
                .collect(Collectors.toSet());

        List<Branch> allActiveBranches = branchRepository.findByCompanyIdAndIsActiveTrue(companyId);

        return allActiveBranches.stream()
                .map(b -> BranchListDTO.builder()
                        .id(b.getId())
                        .code(b.getCode())
                        .name(b.getName())
                        .city(b.getCity())
                        .assignedToCurrentWorkgroup(assignedBranchIds.contains(b.getId()))
                        .build())
                .collect(Collectors.toList());
    }

    /**
     * Munkacsoport iroda-hozzárendelések frissítése (teljes csere).
     */
    public void updateWorkgroupBranches(UUID workgroupId, List<UUID> branchIds) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        RateWorkgroup workgroup = rateWorkgroupRepository.findById(workgroupId)
                .orElseThrow(() -> new ValidationException("Munkacsoport nem található: " + workgroupId));

        if (!workgroup.getCompany().getId().equals(companyId)) {
            throw new ValidationException("Munkacsoport nem tartozik az aktuális céghez");
        }

        // Meglévő hozzárendelések törlése
        workgroup.getBranches().clear();

        // Új hozzárendelések
        if (branchIds != null && !branchIds.isEmpty()) {
            List<Branch> branches = branchRepository.findAllById(branchIds);

            // Ellenőrzés: minden branch a céghez tartozik-e és aktív-e
            for (Branch branch : branches) {
                if (!branch.getCompany().getId().equals(companyId)) {
                    throw new ValidationException("Iroda nem tartozik az aktuális céghez: " + branch.getCode());
                }
                if (!Boolean.TRUE.equals(branch.getIsActive())) {
                    throw new ValidationException("Inaktív iroda nem rendelhető hozzá: " + branch.getCode());
                }
            }

            workgroup.getBranches().addAll(branches);
        }

        rateWorkgroupRepository.save(workgroup);
        log.info("Munkacsoport iroda-hozzárendelés frissítve: workgroupId={}, {} iroda", workgroupId, workgroup.getBranches().size());
    }

    /**
     * Aktív árfolyamok keresése fallback logikával.
     * Ha a mai napra nincs adat, a legutolsó elérhető napot adja vissza.
     */
    private List<ExchangeRate> findActiveRatesWithFallback(UUID companyId) {
        List<ExchangeRate> rates = exchangeRateRepository.findActiveRatesByDate(companyId, LocalDate.now());
        if (rates.isEmpty()) {
            log.info("Nincs mai aktív árfolyam (companyId={}), fallback: legutolsó elérhető nap", companyId);
            rates = exchangeRateRepository.findLatestActiveRates(companyId);
        }
        return rates;
    }

    /**
     * Munkacsoport limit határok frissítése.
     */
    public void updateWorkgroupLimits(UUID workgroupId, BigDecimal limit1Boundary, BigDecimal limit2Boundary, BigDecimal limit3Boundary) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        RateWorkgroup workgroup = rateWorkgroupRepository.findById(workgroupId)
                .orElseThrow(() -> new ValidationException("Munkacsoport nem található: " + workgroupId));

        if (!workgroup.getCompany().getId().equals(companyId)) {
            throw new ValidationException("Munkacsoport nem tartozik az aktuális céghez");
        }

        workgroup.setLimit1Boundary(limit1Boundary);
        workgroup.setLimit2Boundary(limit2Boundary);
        workgroup.setLimit3Boundary(limit3Boundary);

        rateWorkgroupRepository.save(workgroup);
        log.info("Munkacsoport limit határok frissítve: workgroupId={}, l1={}, l2={}, l3={}",
                workgroupId, limit1Boundary, limit2Boundary, limit3Boundary);
    }
}
