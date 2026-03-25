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
     * ÁFA kulcs (27% — magyar szabályozás).
     * A kezelési díjra vetítve.
     */
    private static final BigDecimal VAT_RATE = new BigDecimal("0.27");

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

        // ÁFA számítás a kezelési díjra
        BigDecimal vatAmount = totalHandlingFee.multiply(VAT_RATE)
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
        return navClosingRepository.findById(closingId)
            .orElseThrow(() -> new ResourceNotFoundException("NAV zárás nem található: " + closingId));
    }

    /**
     * Zárások listázása szűréssel.
     */
    @Transactional(readOnly = true)
    public Page<NavClosing> listClosings(UUID branchId, NavClosingType closingType,
                                          NavClosingStatus status, LocalDate dateFrom,
                                          LocalDate dateTo, Pageable pageable) {
        return navClosingRepository.findWithFilters(branchId, closingType, status, dateFrom, dateTo, pageable);
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
