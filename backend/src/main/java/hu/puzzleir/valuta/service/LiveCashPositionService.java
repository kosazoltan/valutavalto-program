package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.report.LiveCashPositionDto;
import hu.puzzleir.valuta.entity.DailyBalance;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.DailyBalanceRepository;
import hu.puzzleir.valuta.repository.DailySubledgerSnapshotRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * G9: Pillanatnyi pénztárállás (Delphi: PenztarAllas) — valutánkénti NYITÓ/BEVÉTEL/KIADÁS/ZÁRÓ
 * a napi mozgásokból (DailyBalance), plusz a napi kezelési-díj egyenleg.
 * Forrás: EXCMD/b5-penztarallas-listak.md + EXCMD/_compare/c4.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class LiveCashPositionService {

    private final DailyBalanceRepository dailyBalanceRepository;
    private final DailySubledgerSnapshotRepository subledgerSnapshotRepository;
    private final CurrencyRepository currencyRepository;

    public LiveCashPositionDto getLivePosition(UUID branchId) {
        LocalDate today = LocalDate.now();

        Map<String, String> nameMap = new HashMap<>();
        currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()
                .forEach(c -> nameMap.put(c.getCode(), c.getName()));

        List<LiveCashPositionDto.CurrencyLineDto> lines =
                dailyBalanceRepository.findByBranchIdAndBalanceDate(branchId, today).stream()
                        .map(b -> LiveCashPositionDto.CurrencyLineDto.builder()
                                .currencyCode(b.getCurrencyCode())
                                .currencyName(nameMap.getOrDefault(b.getCurrencyCode(), b.getCurrencyCode()))
                                .opening(nz(b.getOpeningBalance()))
                                .income(nz(b.getPurchases()).add(nz(b.getTransfersIn())))
                                .expense(nz(b.getSales()).add(nz(b.getTransfersOut())))
                                .closing(nz(b.getClosingBalance()))
                                .build())
                        .sorted(Comparator.comparing(LiveCashPositionDto.CurrencyLineDto::getCurrencyCode))
                        .collect(Collectors.toList());

        BigDecimal handlingFeeHuf = subledgerSnapshotRepository
                .findByBranchIdAndSnapshotDateAndSubledgerTypeAndCurrencyCode(branchId, today, "HANDLING_FEE", "HUF")
                .map(s -> nz(s.getClosingBalance()))
                .orElse(BigDecimal.ZERO);

        return LiveCashPositionDto.builder()
                .branchId(branchId.toString())
                .date(today)
                .lines(lines)
                .handlingFeeHuf(handlingFeeHuf)
                .build();
    }

    private static BigDecimal nz(BigDecimal v) {
        return v == null ? BigDecimal.ZERO : v;
    }
}
