package hu.puzzleir.valuta.service;

import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.exception.ResourceNotFoundException;
import com.puzzleir.backend.exception.ValidationException;
import com.puzzleir.backend.repository.BranchRepository;
import hu.puzzleir.valuta.dto.trade.ProposeTradeDto;
import hu.puzzleir.valuta.dto.trade.TradeDto;
import hu.puzzleir.valuta.entity.Trade;
import hu.puzzleir.valuta.repository.TradeRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Trade service — devizakereskedés irodák között.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class TradeService {

    private final TradeRepository tradeRepository;
    private final BranchRepository branchRepository;

    @Transactional
    public TradeDto proposeTrade(ProposeTradeDto dto) {
        Branch fromBranch = branchRepository.findById(dto.getFromBranchId())
                .orElseThrow(() -> new ResourceNotFoundException("Forrás iroda nem található: " + dto.getFromBranchId()));
        Branch toBranch = branchRepository.findById(dto.getToBranchId())
                .orElseThrow(() -> new ResourceNotFoundException("Cél iroda nem található: " + dto.getToBranchId()));

        if (dto.getFromBranchId().equals(dto.getToBranchId())) {
            throw new ValidationException("A forrás és cél iroda nem lehet azonos!");
        }
        if (dto.getAmount() == null || dto.getAmount().compareTo(BigDecimal.ZERO) <= 0) {
            throw new ValidationException("Az összeg pozitív kell legyen!");
        }

        Trade trade = Trade.builder()
                .fromBranch(fromBranch)
                .toBranch(toBranch)
                .currencyCode(dto.getCurrencyCode())
                .amount(dto.getAmount())
                .rate(dto.getRate() != null ? dto.getRate() : BigDecimal.ONE)
                .status(Trade.TradeStatus.PROPOSED)
                .proposedBy(SecurityUtils.getCurrentWorkerId())
                .proposedAt(LocalDateTime.now())
                .notes(dto.getNotes())
                .build();

        trade = tradeRepository.save(trade);
        log.info("Trade ajánlat létrehozva: id={}, from={}, to={}, {} {}",
                trade.getId(), fromBranch.getCode(), toBranch.getCode(), dto.getAmount(), dto.getCurrencyCode());
        return toDto(trade);
    }

    @Transactional
    public TradeDto acceptTrade(UUID tradeId, Long workerId) {
        Trade trade = findOrThrow(tradeId);
        validateStatus(trade, Trade.TradeStatus.PROPOSED);

        trade.setStatus(Trade.TradeStatus.ACCEPTED);
        trade.setAcceptedBy(workerId);
        trade.setAcceptedAt(LocalDateTime.now());
        trade = tradeRepository.save(trade);
        log.info("Trade elfogadva: id={}", tradeId);
        return toDto(trade);
    }

    @Transactional
    public TradeDto rejectTrade(UUID tradeId, String reason) {
        Trade trade = findOrThrow(tradeId);
        validateStatus(trade, Trade.TradeStatus.PROPOSED);

        trade.setStatus(Trade.TradeStatus.REJECTED);
        if (reason != null && !reason.isBlank()) {
            trade.setNotes((trade.getNotes() != null ? trade.getNotes() + "\n" : "") + "Elutasítás: " + reason);
        }
        trade = tradeRepository.save(trade);
        log.info("Trade elutasítva: id={}, reason={}", tradeId, reason);
        return toDto(trade);
    }

    @Transactional
    public TradeDto completeTrade(UUID tradeId) {
        Trade trade = findOrThrow(tradeId);
        validateStatus(trade, Trade.TradeStatus.ACCEPTED);

        trade.setStatus(Trade.TradeStatus.COMPLETED);
        trade.setCompletedAt(LocalDateTime.now());
        trade = tradeRepository.save(trade);
        log.info("Trade teljesítve: id={}", tradeId);
        // NOTE: Inventory mozgatás a production verzióban implementálandó
        return toDto(trade);
    }

    @Transactional
    public TradeDto cancelTrade(UUID tradeId) {
        Trade trade = findOrThrow(tradeId);
        if (trade.getStatus() == Trade.TradeStatus.COMPLETED) {
            throw new ValidationException("Befejezett trade nem törölhető!");
        }
        trade.setStatus(Trade.TradeStatus.CANCELLED);
        trade = tradeRepository.save(trade);
        log.info("Trade törölve: id={}", tradeId);
        return toDto(trade);
    }

    public List<TradeDto> getPendingTrades(UUID branchId) {
        UUID effectiveBranch = branchId != null ? branchId : SecurityUtils.getCurrentBranchId();
        return tradeRepository.findPendingByBranch(effectiveBranch)
                .stream().map(this::toDto).collect(Collectors.toList());
    }

    public Page<TradeDto> getTradeHistory(UUID branchId, LocalDate from, LocalDate to, Pageable pageable) {
        UUID effectiveBranch = branchId != null ? branchId : SecurityUtils.getCurrentBranchId();
        LocalDateTime fromDt = from.atStartOfDay();
        LocalDateTime toDt = to.plusDays(1).atStartOfDay();
        return tradeRepository.findHistoryByBranch(effectiveBranch, fromDt, toDt, pageable)
                .map(this::toDto);
    }

    private Trade findOrThrow(UUID id) {
        return tradeRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Trade nem található: " + id));
    }

    private void validateStatus(Trade trade, Trade.TradeStatus expected) {
        if (trade.getStatus() != expected) {
            throw new ValidationException(
                    String.format("Trade státusz '%s', de '%s' volt várva!", trade.getStatus(), expected));
        }
    }

    private TradeDto toDto(Trade t) {
        return TradeDto.builder()
                .id(t.getId())
                .fromBranchId(t.getFromBranch().getId())
                .fromBranchName(t.getFromBranch().getName())
                .toBranchId(t.getToBranch().getId())
                .toBranchName(t.getToBranch().getName())
                .currencyCode(t.getCurrencyCode())
                .amount(t.getAmount())
                .rate(t.getRate())
                .status(t.getStatus().name())
                .proposedBy(t.getProposedBy())
                .acceptedBy(t.getAcceptedBy())
                .proposedAt(t.getProposedAt())
                .acceptedAt(t.getAcceptedAt())
                .completedAt(t.getCompletedAt())
                .notes(t.getNotes())
                .build();
    }
}
