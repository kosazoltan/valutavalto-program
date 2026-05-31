package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.util.CashLockOrdering;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
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
    private final CashBalanceRepository cashBalanceRepository;
    private final CurrencyRepository currencyRepository;

    @Transactional(rollbackFor = Exception.class)
    public TradeDto proposeTrade(ProposeTradeDto dto) {
        Branch fromBranch = branchRepository.findById(dto.getFromBranchId())
                .orElseThrow(() -> new ResourceNotFoundException("Forrás iroda nem található: " + dto.getFromBranchId()));
        Branch toBranch = branchRepository.findById(dto.getToBranchId())
                .orElseThrow(() -> new ResourceNotFoundException("Cél iroda nem található: " + dto.getToBranchId()));

        validateTradeProposalAccess(fromBranch, toBranch);

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

    @Transactional(rollbackFor = Exception.class)
    public TradeDto acceptTrade(UUID tradeId, Long workerId) {
        Trade trade = findOrThrow(tradeId);
        validateTradeAccess(trade);
        validateStatus(trade, Trade.TradeStatus.PROPOSED);

        trade.setStatus(Trade.TradeStatus.ACCEPTED);
        trade.setAcceptedBy(workerId);
        trade.setAcceptedAt(LocalDateTime.now());
        trade = tradeRepository.save(trade);
        log.info("Trade elfogadva: id={}", tradeId);
        return toDto(trade);
    }

    @Transactional(rollbackFor = Exception.class)
    public TradeDto rejectTrade(UUID tradeId, String reason) {
        Trade trade = findOrThrow(tradeId);
        validateTradeAccess(trade);
        validateStatus(trade, Trade.TradeStatus.PROPOSED);

        trade.setStatus(Trade.TradeStatus.REJECTED);
        if (reason != null && !reason.isBlank()) {
            trade.setNotes((trade.getNotes() != null ? trade.getNotes() + "\n" : "") + "Elutasítás: " + reason);
        }
        trade = tradeRepository.save(trade);
        log.info("Trade elutasítva: id={}, reason={}", tradeId, reason);
        return toDto(trade);
    }

    @Transactional(rollbackFor = Exception.class)
    public TradeDto completeTrade(UUID tradeId) {
        Trade trade = findOrThrow(tradeId);
        validateTradeAccess(trade);
        validateStatus(trade, Trade.TradeStatus.ACCEPTED);

        moveTradeInventory(trade);

        trade.setStatus(Trade.TradeStatus.COMPLETED);
        trade.setCompletedAt(LocalDateTime.now());
        trade = tradeRepository.save(trade);
        log.info("Trade teljesítve: id={}", tradeId);
        return toDto(trade);
    }

    @Transactional(rollbackFor = Exception.class)
    public TradeDto cancelTrade(UUID tradeId) {
        Trade trade = findOrThrow(tradeId);
        validateTradeAccess(trade);
        if (trade.getStatus() == Trade.TradeStatus.COMPLETED) {
            throw new ValidationException("Befejezett trade nem törölhető!");
        }
        trade.setStatus(Trade.TradeStatus.CANCELLED);
        trade = tradeRepository.save(trade);
        log.info("Trade törölve: id={}", tradeId);
        return toDto(trade);
    }

    public List<TradeDto> getPendingTrades(UUID branchId) {
        UUID effectiveBranch = validateRequestedBranchAccess(branchId != null ? branchId : SecurityUtils.getCurrentBranchId()).getId();
        return tradeRepository.findPendingByBranch(effectiveBranch)
                .stream().map(this::toDto).collect(Collectors.toList());
    }

    public Page<TradeDto> getTradeHistory(UUID branchId, LocalDate from, LocalDate to, Pageable pageable) {
        UUID effectiveBranch = validateRequestedBranchAccess(branchId != null ? branchId : SecurityUtils.getCurrentBranchId()).getId();
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

    private Branch validateRequestedBranchAccess(UUID branchId) {
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));

        validateBranchCompany(branch, SecurityUtils.getCurrentCompanyId(), "Iroda");

        UUID currentBranchId = SecurityUtils.getCurrentBranchId();
        if (!branchId.equals(currentBranchId) && !SecurityUtils.isManagerOrAbove()) {
            throw new ValidationException("Csak a saját iroda trade-jei érhetők el!");
        }

        return branch;
    }

    private void validateTradeProposalAccess(Branch fromBranch, Branch toBranch) {
        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        UUID currentBranchId = SecurityUtils.getCurrentBranchId();

        validateBranchCompany(fromBranch, currentCompanyId, "Forrás iroda");
        validateBranchCompany(toBranch, currentCompanyId, "Cél iroda");

        if (!currentBranchId.equals(fromBranch.getId())) {
            throw new ValidationException("Trade ajánlatot csak a saját irodából lehet indítani!");
        }
    }

    private void validateTradeAccess(Trade trade) {
        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        UUID currentBranchId = SecurityUtils.getCurrentBranchId();

        validateBranchCompany(trade.getFromBranch(), currentCompanyId, "Forrás iroda");
        validateBranchCompany(trade.getToBranch(), currentCompanyId, "Cél iroda");

        boolean currentBranchInvolved = currentBranchId.equals(trade.getFromBranch().getId())
                || currentBranchId.equals(trade.getToBranch().getId());

        if (!currentBranchInvolved && !SecurityUtils.isManagerOrAbove()) {
            throw new ValidationException("Nincs hozzáférés ehhez a trade-hez!");
        }
    }

    private void validateBranchCompany(Branch branch, UUID currentCompanyId, String label) {
        if (branch.getCompany() == null || branch.getCompany().getId() == null
                || !currentCompanyId.equals(branch.getCompany().getId())) {
            throw new ValidationException(label + " nem érhető el az aktuális cégen belül!");
        }
    }

    private void moveTradeInventory(Trade trade) {
        Currency currency = currencyRepository.findByCode(trade.getCurrencyCode())
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található: " + trade.getCurrencyCode()));

        // CROSS-BRANCH LOCK-ORDERING (deadlock-megelozes): a trade a forras- ES a cel-iroda azonos
        // valuta cash_balance sorat lockolja EGY tranzakcioban. Ezeket GLOBALISAN egyseges
        // (branchId, currencyId) sorrendben elo-lockoljuk, mielott olvasnank/mutalnank — kulonben egy
        // parhuzamos, FORDITOTT iranyu Trade(B->A) az ellentetes sorrend miatt AB-BA adatbazis-deadlockot
        // okozna. A nem letezo cel-sor lockolasa no-op (azt a lenti orElseGet hozza letre); a lenti
        // findByBranchIdAndCurrencyIdForUpdate ugyanezeket a sorokat mar lockoltan kapja. Lasd: CashLockOrdering.
        CashLockOrdering.lockBranchCurrencyPairsInGlobalOrder(
                (bid, cid) -> cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(bid, cid),
                new CashLockOrdering.BranchCurrencyKey(trade.getFromBranch().getId(), currency.getId()),
                new CashLockOrdering.BranchCurrencyKey(trade.getToBranch().getId(), currency.getId()));

        CashBalance sourceBalance = cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(
                        trade.getFromBranch().getId(), currency.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Forrás kassza egyenleg nem található"));

        if (sourceBalance.getCurrentBalance() == null
                || sourceBalance.getCurrentBalance().compareTo(trade.getAmount()) < 0) {
            throw new ValidationException("Nincs elegendő készlet a trade teljesítéséhez!");
        }

        CashBalance targetBalance = cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(
                        trade.getToBranch().getId(), currency.getId())
                .orElseGet(() -> CashBalance.builder()
                        .company(trade.getToBranch().getCompany())
                        .branch(trade.getToBranch())
                        .currency(currency)
                        .currentBalance(BigDecimal.ZERO)
                        .openingBalance(BigDecimal.ZERO)
                        .build());

        sourceBalance.updateBalance(trade.getAmount(), false);
        targetBalance.updateBalance(trade.getAmount(), true);

        cashBalanceRepository.save(sourceBalance);
        cashBalanceRepository.save(targetBalance);
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
