package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.nav.NavSendResult;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.dto.nav.NavClosingLineDto;
import hu.puzzleir.valuta.dto.nav.NavClosingSummaryDto;
import hu.puzzleir.valuta.dto.nav.NavSubmissionResult;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.NavClosingRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * NAV zárás szolgáltatás — adóhatósági kötelezettség.
 *
 * Legacy: NAVZARO.DLL — napi/havi zárás a NAV felé.
 * Összegyűjti a napi bevételt (eladás), kiadást (vásárlás),
 * kezelési díjat és ÁFA-t.
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class NavClosingService {

    private final NavClosingRepository navClosingRepository;
    private final TransactionRepository transactionRepository;
    private final BranchRepository branchRepository;
    private final NavIntegrationService navIntegrationService;
    private final SystemParameterService systemParameterService;

    /**
     * Magyar ÁFA-kulcs táblázat — <code>SystemParameter</code> override nélkül ezek a fallback értékek.
     *
     * <p>Minden kulcshoz létezik egy konfigurálható SystemParameter
     * <code>nav.vat-rate.&lt;TAX_CODE&gt;</code> formában (ld. V143 Flyway migráció).
     * Ha a paraméter hiányzik vagy értelmezhetetlen szám, a service loggol és
     * visszalép erre a fallback táblára — így jogszabályváltozáskor sem omlik össze a zárás.</p>
     */
    private static final Map<NavTaxCode, BigDecimal> DEFAULT_VAT_RATES =
        new EnumMap<>(Map.of(
            NavTaxCode.STANDARD,   new BigDecimal("0.27"),
            NavTaxCode.REDUCED_18, new BigDecimal("0.18"),
            NavTaxCode.REDUCED_5,  new BigDecimal("0.05"),
            NavTaxCode.ZERO,       BigDecimal.ZERO
        ));

    private static final String VAT_RATE_KEY_PREFIX = "nav.vat-rate.";

    /**
     * Startup-time validation: biztositja hogy minden NavTaxCode enum ertekhez van fallback rate.
     * Ha uj enum ertek bejon es nincs DEFAULT_VAT_RATES-ben, IllegalStateException -> applikacio nem indul.
     * Ez megvedi a rendszert a silent-ZERO fallback regressziotol.
     */
    @PostConstruct
    void validateVatRateCoverage() {
        for (NavTaxCode code : NavTaxCode.values()) {
            if (!DEFAULT_VAT_RATES.containsKey(code)) {
                throw new IllegalStateException(
                    "VAT rate coverage missing for NavTaxCode." + code.name() +
                    ". Add it to DEFAULT_VAT_RATES in NavClosingService.");
            }
        }
        log.info("NavClosingService VAT rate coverage validated: {} codes OK", NavTaxCode.values().length);
    }

    /**
     * Napi NAV zárás létrehozása.
     *
     * Összegyűjti:
     * - Bevétel: eladás HUF (ügyfél fizet)
     * - Kiadás: vásárlás HUF (cég fizet)
     * - Kezelési díj: handling fee összeg
     * - ÁFA: kezelési díj * 27%
     */
    public NavClosing createDailyNavClosing(UUID branchId, LocalDate date) {
        log.info("NAV napi zárás létrehozása: branchId={}, date={}", branchId, date);

        Branch branch = branchRepository.findById(branchId)
            .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));

        // Ellenőrzés: létezik-e már
        Optional<NavClosing> existing = navClosingRepository
            .findByBranchIdAndClosingDateAndClosingType(branchId, date, NavClosingType.DAILY);
        if (existing.isPresent()) {
            throw new ValidationException("Már létezik NAV napi zárás erre a dátumra: " + date);
        }

        // Tranzakciók lekérése
        List<Transaction> transactions = transactionRepository.findActiveByBranchAndDate(branchId, date);

        // NAV zárás létrehozása
        NavClosing closing = NavClosing.builder()
            .closingDate(date)
            .branch(branch)
            .closingType(NavClosingType.DAILY)
            .status(NavClosingStatus.OPEN)
            .build();

        // Valutánkénti bontás és összesítés
        Map<String, NavCurrencyAggregation> aggregations = new TreeMap<>();
        BigDecimal totalRevenue = BigDecimal.ZERO;   // eladás (bevétel)
        BigDecimal totalExpense = BigDecimal.ZERO;   // vásárlás (kiadás)
        BigDecimal totalHandlingFee = BigDecimal.ZERO;

        for (Transaction tx : transactions) {
            if (tx.getCurrency() == null) continue;
            String currCode = tx.getCurrency().getCode();
            if ("HUF".equals(currCode)) continue;

            NavCurrencyAggregation agg = aggregations.computeIfAbsent(
                currCode, k -> new NavCurrencyAggregation());

            if (tx.getTransactionType().isSellType()) {
                // Eladás = bevétel (ügyfél fizet HUF-ot)
                agg.sellAmount = agg.sellAmount.add(tx.getCurrencyAmount());
                agg.sellHuf = agg.sellHuf.add(tx.getHufAmount());
                totalRevenue = totalRevenue.add(tx.getHufAmount());
            } else if (tx.getTransactionType().isBuyType()) {
                // Vétel = kiadás (cég fizet HUF-ot)
                agg.buyAmount = agg.buyAmount.add(tx.getCurrencyAmount());
                agg.buyHuf = agg.buyHuf.add(tx.getHufAmount());
                totalExpense = totalExpense.add(tx.getHufAmount());
            }

            if (tx.getHandlingFee() != null) {
                agg.handlingFee = agg.handlingFee.add(tx.getHandlingFee());
                totalHandlingFee = totalHandlingFee.add(tx.getHandlingFee());
            }

            agg.txCount++;
        }

        // Sorok hozzáadása
        for (Map.Entry<String, NavCurrencyAggregation> entry : aggregations.entrySet()) {
            NavCurrencyAggregation agg = entry.getValue();

            NavClosingLine line = NavClosingLine.builder()
                .currencyCode(entry.getKey())
                .buyAmount(agg.buyAmount)
                .sellAmount(agg.sellAmount)
                .buyHuf(agg.buyHuf)
                .sellHuf(agg.sellHuf)
                .handlingFee(agg.handlingFee)
                .transactionCount(agg.txCount)
                .build();

            closing.addLine(line);
        }

        // ÁFA számítás a kezelési díjra — STANDARD kulcs (jelenleg 27%).
        // Az érték SystemParameter-ből jön (nav.vat-rate.STANDARD), így
        // jogszabályváltozáskor redeploy nélkül módosítható.
        BigDecimal vatAmount = totalHandlingFee.multiply(resolveVatRate(NavTaxCode.STANDARD))
            .setScale(0, java.math.RoundingMode.HALF_UP);

        closing.setTotalRevenue(totalRevenue);
        closing.setTotalExpense(totalExpense);
        closing.setHandlingFeeTotal(totalHandlingFee);
        closing.setVatAmount(vatAmount);
        closing.setStatus(NavClosingStatus.CLOSED);
        closing.setClosedAt(LocalDateTime.now());

        NavClosing saved = navClosingRepository.save(closing);

        log.info("NAV napi zárás létrehozva: id={}, bevétel={}, kiadás={}, díj={}, áfa={}",
            saved.getId(), totalRevenue, totalExpense, totalHandlingFee, vatAmount);

        return saved;
    }

    /**
     * NAV zárás beküldése.
     */
    public NavSubmissionResult submitToNav(UUID closingId) {
        NavClosing closing = navClosingRepository.findById(closingId)
            .orElseThrow(() -> new ResourceNotFoundException("NAV zárás nem található: " + closingId));

        // Multi-tenant IDOR guard (NEW-2): idegen cég zárása nem küldhető be NAV felé.
        // A létezést sem szabad elárulni → cross-tenant esetén ResourceNotFoundException.
        verifyClosingTenant(closing, closingId);

        if (closing.getStatus() != NavClosingStatus.CLOSED) {
            throw new ValidationException(
                "Csak CLOSED státuszú zárás küldhető be! Jelenlegi: " + closing.getStatus());
        }

        String comPort = resolveNavComPort();
        long syntheticTransactionId = Math.abs(closingId.getLeastSignificantBits());

        NavSendResult sendResult = navIntegrationService.sendTransaction(syntheticTransactionId, comPort);
        if (!sendResult.isSuccess()) {
            throw new ValidationException("NAV beküldés sikertelen: " + sendResult.getError());
        }

        String qrPayload = buildNavQrPayload(closing);
        boolean qrSent = navIntegrationService.sendQrCode(qrPayload, comPort);
        if (!qrSent) {
            throw new ValidationException("NAV QR payload küldés sikertelen");
        }

        String refNumber = sendResult.getReceiptNumber();
        if (refNumber == null || refNumber.isBlank()) {
            refNumber = navIntegrationService.receiveReceiptNumber(comPort);
        }

        closing.setStatus(NavClosingStatus.SUBMITTED);
        closing.setNavReferenceNumber(refNumber);
        navClosingRepository.save(closing);

        log.info("NAV zárás beküldve: closingId={}, comPort={}, ref={}", closingId, comPort, refNumber);

        return NavSubmissionResult.builder()
            .success(true)
            .referenceNumber(refNumber)
            .build();
    }

    /**
     * Napi zárás összesítő lekérése.
     */
    @Transactional(readOnly = true)
    public NavClosingSummaryDto getDailyClosingSummary(UUID branchId, LocalDate date) {
        NavClosing closing = navClosingRepository
            .findByBranchIdAndClosingDateAndClosingType(branchId, date, NavClosingType.DAILY)
            .orElseThrow(() -> new ResourceNotFoundException(
                "NAV napi zárás nem található: branchId=" + branchId + ", date=" + date));

        List<NavClosingLineDto> linesDtos = closing.getLines().stream()
            .map(l -> NavClosingLineDto.builder()
                .id(l.getId())
                .currencyCode(l.getCurrencyCode())
                .buyAmount(l.getBuyAmount())
                .sellAmount(l.getSellAmount())
                .buyHuf(l.getBuyHuf())
                .sellHuf(l.getSellHuf())
                .handlingFee(l.getHandlingFee())
                .transactionCount(l.getTransactionCount())
                .build())
            .collect(Collectors.toList());

        int totalTx = closing.getLines().stream()
            .mapToInt(NavClosingLine::getTransactionCount)
            .sum();

        return NavClosingSummaryDto.builder()
            .closingDate(date)
            .totalRevenue(closing.getTotalRevenue())
            .totalExpense(closing.getTotalExpense())
            .netResult(closing.getTotalRevenue().subtract(closing.getTotalExpense()))
            .handlingFeeTotal(closing.getHandlingFeeTotal())
            .vatAmount(closing.getVatAmount())
            .totalTransactions(totalTx)
            .currencyBreakdown(linesDtos)
            .build();
    }

    /**
     * Zárás lekérdezése ID alapján.
     */
    @Transactional(readOnly = true)
    public NavClosing getClosingById(UUID closingId) {
        NavClosing closing = navClosingRepository.findById(closingId)
            .orElseThrow(() -> new ResourceNotFoundException("NAV zárás nem található: " + closingId));

        // Multi-tenant IDOR guard (NEW-2): idegen cég zárása nem olvasható (és így a
        // controller summary-útja sem deriválhat belőle branchId-t idegen cég napi
        // összesítőjéhez). Cross-tenant → ResourceNotFoundException (létezés sem szivárog).
        verifyClosingTenant(closing, closingId);
        return closing;
    }

    /**
     * Ellenőrzi, hogy a NAV zárás a bejelentkezett felhasználó cégéhez tartozik-e.
     * Cross-tenant (vagy hiányzó branch/company) esetén ResourceNotFoundException,
     * hogy az idegen erőforrás létezése se szivárogjon ki.
     *
     * <p>Csak user-facing (controller) úton hívjuk: a service-nek nincs @Scheduled /
     * auth-kontextus nélküli hívója (NavClosingController az egyetlen belépési pont),
     * így a getCurrentCompanyId() biztosan kap bejelentkezett usert.</p>
     */
    private void verifyClosingTenant(NavClosing closing, UUID closingId) {
        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        Branch branch = closing.getBranch();
        UUID ownerCompanyId = (branch != null && branch.getCompany() != null)
            ? branch.getCompany().getId()
            : null;
        if (ownerCompanyId == null || !ownerCompanyId.equals(currentCompanyId)) {
            throw new ResourceNotFoundException("NAV zárás nem található: " + closingId);
        }
    }

    /**
     * Zárások listázása szűréssel.
     */
    @Transactional(readOnly = true)
    public Page<NavClosing> listClosings(UUID branchId, NavClosingType closingType,
                                          NavClosingStatus status, LocalDate dateFrom,
                                          LocalDate dateTo, Pageable pageable) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return navClosingRepository.findWithFilters(companyId, branchId, closingType, status, dateFrom, dateTo, pageable);
    }

    // ============ BELSŐ SEGÉDOSZTÁLY ============

    private static class NavCurrencyAggregation {
        BigDecimal buyAmount = BigDecimal.ZERO;
        BigDecimal sellAmount = BigDecimal.ZERO;
        BigDecimal buyHuf = BigDecimal.ZERO;
        BigDecimal sellHuf = BigDecimal.ZERO;
        BigDecimal handlingFee = BigDecimal.ZERO;
        int txCount = 0;
    }

    /**
     * Magyar ÁFA kategóriák, amelyek a <code>system_parameter</code> táblában
     * <code>nav.vat-rate.&lt;NAME&gt;</code> kulcsokkal bindolhatók.
     *
     * <ul>
     *   <li>{@link #STANDARD}   &mdash; 27% (általános, alapértelmezett kezelési díjra)</li>
     *   <li>{@link #REDUCED_18} &mdash; 18% (kedvezményes kulcs)</li>
     *   <li>{@link #REDUCED_5}  &mdash; 5%  (kedvezményes kulcs)</li>
     *   <li>{@link #ZERO}       &mdash; 0%  (adómentes)</li>
     * </ul>
     *
     * <p>Új áfa-kategória bevezetéséhez a felsorolás + V### migráció + fallback-érték bővítése kell.</p>
     */
    public enum NavTaxCode {
        STANDARD,
        REDUCED_18,
        REDUCED_5,
        ZERO
    }

    private String resolveNavComPort() {
        try {
            String configured = systemParameterService.getValue("nav.com-port");
            if (configured != null && !configured.isBlank()) {
                return configured.trim();
            }
        } catch (Exception ignored) {
            // Fallback handled below.
        }
        return "COM1";
    }

    /**
     * ÁFA kulcs feloldása tax code alapján.
     *
     * <p>Lookup sorrend:</p>
     * <ol>
     *   <li>SystemParameter <code>nav.vat-rate.&lt;TAX_CODE&gt;</code> (pl. <code>nav.vat-rate.STANDARD</code>)</li>
     *   <li>Ha nincs paraméter, hibás BigDecimal, vagy negatív érték &rarr;
     *       {@link #DEFAULT_VAT_RATES} fallback + warn log</li>
     * </ol>
     *
     * <p>Így a NAV zárás <b>soha nem hal meg</b> csak azért, mert valaki kitöröl
     * egy paramétert, de az áfa mégis mindig a legfrissebb konfigurált értéket használja.</p>
     *
     * @param taxCode a keresett áfa-kulcs kategória
     * @return a kulcs decimális értéke (0 &le; x &le; 1)
     */
    BigDecimal resolveVatRate(NavTaxCode taxCode) {
        String key = VAT_RATE_KEY_PREFIX + taxCode.name();
        BigDecimal fallback = DEFAULT_VAT_RATES.getOrDefault(taxCode, BigDecimal.ZERO);
        try {
            String raw = systemParameterService.getValue(key);
            if (raw == null || raw.isBlank()) {
                log.warn("VAT-rate paraméter üres, fallback használata: key={}, fallback={}", key, fallback);
                return fallback;
            }
            BigDecimal parsed = new BigDecimal(raw.trim());
            if (parsed.signum() < 0) {
                log.warn("VAT-rate paraméter negatív, fallback használata: key={}, raw={}, fallback={}",
                    key, raw, fallback);
                return fallback;
            }
            return parsed;
        } catch (NumberFormatException ex) {
            log.warn("VAT-rate paraméter nem decimális, fallback használata: key={}, hiba={}",
                key, ex.getMessage());
            return fallback;
        } catch (Exception ex) {
            log.info("VAT-rate paraméter hiányzik, fallback: key={}, fallback={}", key, fallback);
            return fallback;
        }
    }

    private String buildNavQrPayload(NavClosing closing) {
        return String.format(
            Locale.ROOT,
            "NAVCLOSE|id=%s|date=%s|type=%s|revenue=%s|expense=%s|fee=%s|vat=%s",
            closing.getId(),
            closing.getClosingDate(),
            closing.getClosingType(),
            closing.getTotalRevenue(),
            closing.getTotalExpense(),
            closing.getHandlingFeeTotal(),
            closing.getVatAmount());
    }
}
