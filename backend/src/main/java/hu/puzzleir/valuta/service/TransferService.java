package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.dto.transfer.*;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.util.HungarianRounding;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import hu.puzzleir.valuta.exception.ConflictException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class TransferService {

    private final TransferRepository transferRepository;
    private final BranchRepository branchRepository;
    private final CurrencyRepository currencyRepository;
    private final WorkerRepository workerRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final TransactionRepository transactionRepository;
    private final ReceiptSequenceService receiptSequenceService;
    private final TransferSerialSequenceService transferSerialSequenceService;
    private final AuditLogService auditLogService;

    @Transactional(rollbackFor = Exception.class)
    public TransferDto create(CreateTransferDto dto, Long workerId) {
        Worker fromWorker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Dolgozó nem található: " + workerId));
        Branch fromBranch = fromWorker.getBranch();
        if (fromBranch == null) {
            throw new ValidationException("A dolgozóhoz nincs fiók rendelve!");
        }

        Branch toBranch = branchRepository.findById(UUID.fromString(dto.getToBranchId()))
                .orElseThrow(() -> new ResourceNotFoundException("Célfiók nem található: " + dto.getToBranchId()));

        Currency currency = currencyRepository.findById(dto.getCurrencyId())
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található: " + dto.getCurrencyId()));

        if (fromBranch.getId().equals(toBranch.getId())) {
            throw new ValidationException("A forrás és cél fiók nem lehet azonos!");
        }

        // Direction meghatározása (default: UF)
        Transfer.TransferDirection direction = Transfer.TransferDirection.UF;
        if (dto.getDirection() != null && !dto.getDirection().isBlank()) {
            try {
                direction = Transfer.TransferDirection.valueOf(dto.getDirection());
            } catch (IllegalArgumentException e) {
                throw new ValidationException("Érvénytelen átadás irány: " + dto.getDirection()
                        + ". Lehetséges értékek: F, U, UF, FF");
            }
        }

        // A sorszám és a címletezés cég-azonosítója a forrásfiók cégéből jön; a sorszám
        // tenant + prefix szinten folyamatos és DB-oldalon atomikusan léptetett.
        UUID companyId = fromBranch.getCompany() != null
                ? fromBranch.getCompany().getId() : SecurityUtils.getCurrentCompanyIdOrNull();

        String transferNumber = generateTransferNumber(direction, currency, companyId);

        // HUF-fallback (FR-5, FR-6): HUF esetén az elszámoló árfolyam konstans 1,0000 → a forintosított
        // érték = összeg (5 Ft-ra kerekítve). HUF-nál NINCS DB-árfolyam, ezért a rögzítés sosem
        // blokkolódik árfolyam hiányára. Más valutánál a kliens által küldött hufValue marad.
        boolean isHuf = "HUF".equalsIgnoreCase(currency.getCode());
        BigDecimal hufValue = isHuf ? HungarianRounding.roundToFive(dto.getAmount()) : dto.getHufValue();

        Transfer transfer = Transfer.builder()
                .transferNumber(transferNumber)
                .companyId(companyId)
                .fromBranch(fromBranch)
                .toBranch(toBranch)
                .fromWorker(fromWorker)
                .transferType(Transfer.TransferType.valueOf(dto.getTransferType()))
                .status(Transfer.TransferStatus.PENDING)
                .transferDate(LocalDate.now())
                .transferTime(LocalTime.now())
                .currency(currency)
                .amount(dto.getAmount())
                .hufValue(hufValue)
                .direction(direction)
                .handoverPrinted(false)
                .receiptPrinted(false)
                .notes(dto.getNotes())
                .carrierName(dto.getCarrierName())
                .sealNumber(dto.getSealNumber())
                .build();

        // #6: több-valutás átadólap — a sorokat a transfer-hez csatoljuk (cascade ALL menti).
        if (dto.getLines() != null && !dto.getLines().isEmpty()) {
            // Korai duplikált-valuta védelem (a DB unique index csak később dobna).
            java.util.Set<Long> seenCurrencies = new java.util.HashSet<>();
            for (var l : dto.getLines()) {
                if (!seenCurrencies.add(l.getCurrencyId())) {
                    throw new ValidationException("Egy átadólapon egy valuta csak egyszer szerepelhet! currencyId=" + l.getCurrencyId());
                }
            }
            int lineNo = 1;
            for (var lineDto : dto.getLines()) {
                Currency lineCurrency = currencyRepository.findById(lineDto.getCurrencyId())
                        .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található: " + lineDto.getCurrencyId()));
                transfer.getLines().add(TransferLine.builder()
                        .transfer(transfer)
                        .currency(lineCurrency)
                        .amount(lineDto.getAmount())
                        .lineNo(lineNo++)
                        .build());
            }
        }

        // Opcionális címletezés (FR-17..20b): szabad bevitel (darab × névleges érték). Ha van legalább
        // egy sor, az összegük KÖTELEZŐEN egyezik az átadás összegével (részleges címletezés tilos).
        if (dto.getDenominations() != null && !dto.getDenominations().isEmpty()) {
            BigDecimal denomSum = BigDecimal.ZERO;
            for (var d : dto.getDenominations()) {
                if (d.getQuantity() == null || d.getQuantity() <= 0
                        || d.getFaceValue() == null || d.getFaceValue().compareTo(BigDecimal.ZERO) <= 0) {
                    throw new ValidationException("VV-VALID-002: A címletezés darabszáma és névleges értéke pozitív kell legyen!");
                }
                BigDecimal lineTotal = d.getFaceValue().multiply(BigDecimal.valueOf(d.getQuantity()));
                denomSum = denomSum.add(lineTotal);
                transfer.getDenominations().add(TransferDenomination.builder()
                        .companyId(companyId)
                        .transfer(transfer)
                        .quantity(d.getQuantity())
                        .faceValue(d.getFaceValue())
                        .currencyCode(currency.getCode())
                        .lineTotal(lineTotal)
                        .build());
            }
            if (denomSum.compareTo(dto.getAmount()) != 0) {
                throw new ValidationException("VV-VALID-002: A címletezés összege (" + denomSum
                        + ") nem egyezik az átadás összegével (" + dto.getAmount() + ")!");
            }
        }

        transfer = transferRepository.save(transfer);

        // Counter-tranzakciók létrehozása a direction alapján
        createCounterTransactions(transfer, fromWorker, direction);

        // Audit log
        auditLogService.log("TRANSFER_CREATED",
                String.format("Átadás létrehozva: %s, irány: %s, összeg: %s %s, %s -> %s",
                        transferNumber, direction, dto.getAmount(), currency.getCode(),
                        fromBranch.getCode(), toBranch.getCode()),
                transfer.getId());

        return toDto(transfer);
    }

    @Transactional(rollbackFor = Exception.class)
    public TransferDto receive(Long id, ReceiveTransferDto dto, Long workerId) {
        Transfer transfer = findOrThrow(id);
        if (transfer.getStatus() != Transfer.TransferStatus.PENDING &&
            transfer.getStatus() != Transfer.TransferStatus.IN_TRANSIT) {
            throw new ValidationException("Csak függőben lévő vagy szállítás alatt lévő átadás fogadható!");
        }

        Worker toWorker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Dolgozó nem található: " + workerId));

        // HIGH FIX #10: Objects.equals használata — biztos összehasonlítás LAZY branch esetén is
        if (toWorker.getBranch() != null && !java.util.Objects.equals(
                toWorker.getBranch().getId(), transfer.getToBranch().getId())) {
            throw new ValidationException("Csak a célfiók dolgozói fogadhatják ezt az átadást!");
        }

        transfer.setToWorker(toWorker);
        transfer.setReceivedAmount(dto.getReceivedAmount());
        transfer.setReceivedDate(LocalDate.now());
        transfer.setReceivedTime(LocalTime.now());
        transfer.setDifference(dto.getReceivedAmount().subtract(transfer.getAmount()));
        transfer.setStatus(Transfer.TransferStatus.COMPLETED);

        if (dto.getNotes() != null) {
            transfer.setNotes((transfer.getNotes() != null ? transfer.getNotes() + "\n" : "") + dto.getNotes());
        }

        Transfer.TransferDirection direction = transfer.getDirection() != null
                ? transfer.getDirection() : Transfer.TransferDirection.UF;

        // Kassza egyenleg frissítés PESSIMISTIC LOCK-kal, direction alapján
        updateCashBalancesOnReceive(transfer, dto.getReceivedAmount(), direction);

        // TRANSFER_IN tranzakció létrehozása a fogadó fióknál (U és FF módot a create már kezelte)
        // Receive-nél csak F és UF módban kell TRANSFER_IN-t létrehozni
        // F mód: a create-nál TRANSFER_OUT jött létre, receive-nél nincs TRANSFER_IN (csak kassza frissül)
        // U mód: a create-nál nincs TRANSFER_OUT, receive-nél TRANSFER_IN jön létre — DE a create-nál már létrejött
        // Valójában: receive-nél nincs új tranzakció, a create-nál már minden létrejött direction szerint
        // KIVÉVE: F mód esetén a fogadó oldal tranzakciója a receive-nél jön létre
        if (direction == Transfer.TransferDirection.F) {
            // F mód: receive-nél a fogadó oldali TRANSFER_IN tranzakció — multi-line esetén soronként.
            for (TransferLine ln : effectiveLines(transfer)) {
                createTransferInTransaction(transfer, toWorker, transfer.getToBranch(), ln.getCurrency(), ln.getAmount());
            }
            log.info("TRANSFER_IN tranzakció(k) létrehozva receive-nél (F mód): {}", transfer.getTransferNumber());
        }

        transfer = transferRepository.save(transfer);

        // Audit log
        auditLogService.log("TRANSFER_RECEIVED",
                String.format("Átadás fogadva: %s, irány: %s, fogadott összeg: %s, különbözet: %s",
                        transfer.getTransferNumber(), direction,
                        dto.getReceivedAmount(), transfer.getDifference()),
                transfer.getId());

        return toDto(transfer);
    }

    @Transactional(rollbackFor = Exception.class)
    public TransferDto reject(Long id, String reason, Long workerId) {
        Transfer transfer = findOrThrow(id);
        if (transfer.getStatus() != Transfer.TransferStatus.PENDING) {
            throw new ValidationException("Csak függőben lévő átadás utasítható el!");
        }

        Worker toWorker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Dolgozó nem található: " + workerId));

        transfer.setToWorker(toWorker);
        transfer.setStatus(Transfer.TransferStatus.REJECTED);
        transfer.setNotes((transfer.getNotes() != null ? transfer.getNotes() + "\n" : "") + "Elutasítás oka: " + reason);
        transfer = transferRepository.save(transfer);
        return toDto(transfer);
    }

    @Transactional(rollbackFor = Exception.class)
    public void cancel(Long id) {
        Transfer transfer = findOrThrow(id);
        if (transfer.getStatus() != Transfer.TransferStatus.PENDING) {
            throw new ValidationException("Csak függőben lévő átadás törölhető!");
        }

        // IDOR védelem: csak a küldő fiók dolgozói törölhetik
        UUID currentBranchId = SecurityUtils.getCurrentBranchId();
        if (!transfer.getFromBranch().getId().equals(currentBranchId)) {
            throw new ValidationException("Csak a küldő fiók dolgozói törölhetik az átadást!");
        }

        transfer.setStatus(Transfer.TransferStatus.CANCELLED);
        transferRepository.save(transfer);
    }

    /**
     * Értéktári átadás-átvétel bizonylat SZTORNÓZÁSA indoklással (FR-12..16, FR-20).
     *
     * Az eredeti rekord megmarad, csak megjelölődik ({@code is_cancelled=true} + indoklás + ki/mikor).
     * A sztornó bizonylat sorszáma {@code <eredeti>-SZ} (a DTO számolja, nincs külön rekord).
     *
     * Tenant-izoláció (FR-20): kizárólag a SAJÁT cég bizonylata sztornózható — más cégé → 404
     * (VV-TENANT-001 audit), hogy a létezés se szivárogjon. Már sztornózott → 409 (VV-TX-003).
     */
    @Transactional(rollbackFor = Exception.class)
    public TransferDto storno(Long id, String reason) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        // Pessimistic lock: a konkurens dupla-sztornó (kétszeres készlet-visszafordítás) ellen — az
        // isCancelled ellenőrzés+állítás atomi a sorzáron belül (a második kérés a lockon vár, majd 409-et kap).
        Transfer transfer = transferRepository.findByIdForUpdate(id).orElse(null);
        // Cross-tenant védelem: ha nincs, vagy NEM a saját céghez tartozik → 404 (létezést sem áruljuk el).
        boolean ownCompany = transfer != null
                && ((transfer.getFromBranch() != null && transfer.getFromBranch().getCompany() != null
                        && companyId.equals(transfer.getFromBranch().getCompany().getId()))
                    || (transfer.getToBranch() != null && transfer.getToBranch().getCompany() != null
                        && companyId.equals(transfer.getToBranch().getCompany().getId())));
        if (!ownCompany) {
            auditLogService.log("STORNO_DENIED",
                    "VV-TENANT-001: Idegen cég átadás-átvétel bizonylatának sztornó kísérlete: id=" + id,
                    id);
            throw new ResourceNotFoundException("Átadás nem található: " + id);
        }
        if (Boolean.TRUE.equals(transfer.getIsCancelled())) {
            throw new ConflictException("VV-TX-003: Ez a bizonylat már sztornózva van: " + transfer.getTransferNumber());
        }
        // Csak véglegesített (COMPLETED) bizonylat sztornózható — a PENDING/IN_TRANSIT-et a /cancel kezeli
        // (API-megkerülés elleni védelem; a UI is csak COMPLETED-en mutatja a sztornó gombot).
        if (transfer.getStatus() != Transfer.TransferStatus.COMPLETED) {
            throw new ValidationException(
                    "Csak véglegesített (lezárt) átadás-átvétel bizonylat sztornózható. Függőben lévő bizonylatot a törlés (cancel) kezel.");
        }
        String normalizedReason = normalizeStornoReason(reason);

        // A sztornózó dolgozó (az ellentételező tranzakciókhoz).
        Worker actor = workerRepository.findById(SecurityUtils.getCurrentWorkerId())
                .orElseThrow(() -> new ResourceNotFoundException("Dolgozó nem található"));

        transfer.setIsCancelled(true);
        transfer.setCancelledAt(LocalDateTime.now());
        transfer.setCancellationReason(normalizedReason);
        transfer.setCancelledBy(actor.getId());

        // FIZIKAI KÉSZLET-VISSZAFORDÍTÁS: az eredeti (COMPLETED) átadás-átvétel készletmozgását
        // visszafordítjuk (a készpénz visszakerül/kikerül), ellentételező TRANSFER tranzakciókkal.
        // Ha a visszafordítandó összeg már nincs meg a fogadó kasszában, a (negatív-védett) helper
        // hibát dob → a teljes sztornó rollbackel (a bizonylat nem-sztornózott marad, tiszta hibával).
        Transfer.TransferDirection dir = transfer.getDirection() != null
                ? transfer.getDirection() : Transfer.TransferDirection.UF;
        reverseCounterTransactions(transfer, actor, dir);

        transferRepository.save(transfer);

        // Audit (FR/NFR-8): VV-TX-002, action=STORNO, entity=TransferRequest.
        auditLogService.log("STORNO",
                String.format("VV-TX-002: Átadás-átvétel sztornózva: %s, indoklás: %s",
                        transfer.getTransferNumber(), normalizedReason),
                transfer.getId());

        return toDto(transfer);
    }

    @Transactional(readOnly = true)
    public TransferDto getById(Long id) {
        return toDto(findOrThrow(id));
    }

    /**
     * Sztornó bizonylat előnézet-adatai (FR-15): az eredeti bizonylat adatai + indoklás +
     * a {@code <eredeti>-SZ} sorszám (a {@link #toDto} tölti). Tenant-szűrt.
     */
    @Transactional(readOnly = true)
    public TransferDto getStornoPreview(Long id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Transfer transfer = transferRepository.findById(id).orElse(null);
        boolean ownCompany = transfer != null
                && ((transfer.getFromBranch() != null && transfer.getFromBranch().getCompany() != null
                        && companyId.equals(transfer.getFromBranch().getCompany().getId()))
                    || (transfer.getToBranch() != null && transfer.getToBranch().getCompany() != null
                        && companyId.equals(transfer.getToBranch().getCompany().getId())));
        if (!ownCompany) {
            throw new ResourceNotFoundException("Átadás nem található: " + id);
        }
        TransferDto preview = toDto(transfer);
        preview.setStornoSerialNumber(transfer.getTransferNumber() + "-SZ");
        return preview;
    }

    @Transactional(readOnly = true)
    public TransferDto getByTransferNumber(String transferNumber) {
        Transfer transfer = transferRepository.findByTransferNumber(transferNumber)
                .orElseThrow(() -> new ResourceNotFoundException("Átadás nem található: " + transferNumber));
        return toDto(transfer);
    }

    @Transactional(readOnly = true)
    public List<TransferDto> getPending() {
        UUID currentBranchId = SecurityUtils.getCurrentBranchId();
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        // Csak az aktuális fiókhoz tartozó (bejövő vagy kimenő) PENDING átadások.
        // DB-oldali szűrés + JOIN FETCH (nincs N+1 lazy-load, nincs LazyInitializationException).
        return transferRepository
                .findPendingForBranch(companyId, currentBranchId, Transfer.TransferStatus.PENDING)
                .stream()
                .map(this::toDto).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<TransferDto> getOutgoing(UUID branchId) {
        return transferRepository.findOutgoingByBranch(branchId)
                .stream().map(this::toDto).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<TransferDto> getIncoming(UUID branchId) {
        return transferRepository.findIncomingByBranch(branchId)
                .stream().map(this::toDto).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public Page<TransferDto> search(UUID branchId, LocalDate startDate, LocalDate endDate,
                                     Transfer.TransferStatus status, Transfer.TransferType type, Pageable pageable) {
        return transferRepository.search(branchId, startDate, endDate, status, type, pageable)
                .map(this::toDto);
    }

    public long countPending(UUID branchId) {
        return transferRepository.countPendingByBranch(branchId);
    }

    // --- Counter-transaction logic ---

    /**
     * Counter-tranzakciók létrehozása a direction alapján a transfer LÉTREHOZÁSAKOR.
     *
     * F  = Feladó: TRANSFER_OUT a küldő fióknál + kassza csökkentés
     * U  = Vevő: TRANSFER_IN a fogadó fióknál + kassza növelés (fogadó-indítás)
     * UF = Teljes: TRANSFER_OUT + TRANSFER_IN egyszerre + mindkét kassza frissítés
     * FF = Korrekció: két TRANSFER_OUT (mindkét fióknál csökkentés)
     */
    private void createCounterTransactions(Transfer transfer, Worker fromWorker,
                                            Transfer.TransferDirection direction) {
        // #6: soronként könyvelünk (egy-valutás átadásnál egyetlen szintetikus sor a headerből).
        final java.util.List<TransferLine> bookLines = effectiveLines(transfer);

        // CROSS-BRANCH + CASH-FIRST LOCK-ORDERING (deadlock-megelozes, #952): az UF/FF mod a kuldo ES a
        // fogado iroda cash_balance sorat is lockolja (soronkent, tobb valutaban is). Ezeket — az F/U
        // single-branch soraival egyutt — GLOBALISAN egyseges (branchId, currencyId) sorrendben, a
        // bizonylatszam-generalas (createTransfer*Transaction -> ReceiptSequenceService per-branch
        // PESSIMISTIC lock) ELOTT ELO-LOCKOLJUK. Igy (a) a forditott iranyu transfer/trade nem okoz
        // cash<->cash AB-BA deadlockot, es (b) minden penzmozgato ut cash->receipt sorrendben halad
        // (BUY/SELL/sztorno/refund is) -> nincs cash<->receipt_sequence deadlock-axis. Lasd: CashLockOrdering.
        final boolean touchesToBranch = direction == Transfer.TransferDirection.UF
                || direction == Transfer.TransferDirection.FF;
        final java.util.List<hu.puzzleir.valuta.util.CashLockOrdering.BranchCurrencyKey> lockKeys =
                new java.util.ArrayList<>();
        for (TransferLine ln : bookLines) {
            Long cid = ln.getCurrency().getId();
            lockKeys.add(new hu.puzzleir.valuta.util.CashLockOrdering.BranchCurrencyKey(
                    transfer.getFromBranch().getId(), cid));
            if (touchesToBranch) {
                lockKeys.add(new hu.puzzleir.valuta.util.CashLockOrdering.BranchCurrencyKey(
                        transfer.getToBranch().getId(), cid));
            }
        }
        hu.puzzleir.valuta.util.CashLockOrdering.lockBranchCurrencyPairsInGlobalOrder(
                (bid, c) -> cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(bid, c),
                lockKeys.toArray(new hu.puzzleir.valuta.util.CashLockOrdering.BranchCurrencyKey[0]));

        switch (direction) {
            case F -> {
                for (TransferLine ln : bookLines) {
                    createTransferOutTransaction(transfer, fromWorker, ln.getCurrency(), ln.getAmount());
                    decreaseCashBalance(transfer.getFromBranch(), ln.getCurrency(), ln.getAmount());
                }
                log.info("F mód — {} sor TRANSFER_OUT: {}", bookLines.size(), transfer.getTransferNumber());
            }
            case U -> {
                for (TransferLine ln : bookLines) {
                    createTransferInTransaction(transfer, fromWorker, transfer.getFromBranch(), ln.getCurrency(), ln.getAmount());
                    increaseCashBalance(transfer.getFromBranch(), ln.getCurrency(), ln.getAmount());
                }
                log.info("U mód — {} sor TRANSFER_IN (fogadó: {}): {}",
                        bookLines.size(), transfer.getFromBranch().getCode(), transfer.getTransferNumber());
            }
            case UF -> {
                for (TransferLine ln : bookLines) {
                    createTransferOutTransaction(transfer, fromWorker, ln.getCurrency(), ln.getAmount());
                    createTransferInTransaction(transfer, fromWorker, transfer.getToBranch(), ln.getCurrency(), ln.getAmount());
                    decreaseCashBalance(transfer.getFromBranch(), ln.getCurrency(), ln.getAmount());
                    increaseCashBalance(transfer.getToBranch(), ln.getCurrency(), ln.getAmount());
                }
                // UF módban az átadás azonnal COMPLETED — multi-line sorok is fogadottnak jelölve.
                markLinesReceived(transfer);
                transfer.setStatus(Transfer.TransferStatus.COMPLETED);
                transfer.setReceivedAmount(transfer.getAmount());
                transfer.setReceivedDate(LocalDate.now());
                transfer.setReceivedTime(LocalTime.now());
                transfer.setDifference(BigDecimal.ZERO);
                log.info("UF mód — {} sor TRANSFER_OUT+IN: {}", bookLines.size(), transfer.getTransferNumber());
            }
            case FF -> {
                for (TransferLine ln : bookLines) {
                    createTransferOutTransaction(transfer, fromWorker, ln.getCurrency(), ln.getAmount());
                    createCorrectionTransferOutTransaction(transfer, fromWorker, ln.getCurrency(), ln.getAmount());
                    decreaseCashBalance(transfer.getFromBranch(), ln.getCurrency(), ln.getAmount());
                    decreaseCashBalance(transfer.getToBranch(), ln.getCurrency(), ln.getAmount());
                }
                log.info("FF mód — {} sor 2x TRANSFER_OUT: {}", bookLines.size(), transfer.getTransferNumber());
            }
        }
    }

    /**
     * SZTORNÓ — az EREDETI (COMPLETED) átadás-átvétel készletmozgásának FIZIKAI visszafordítása.
     * Az eredeti net cash-hatás negálása irányonként, soronként, cash-lock-kal (deadlock-safe), és
     * ellentételező TRANSFER tranzakciók (referencia: {@code <sorszám>-SZ}) az audit/készlet-invariánshoz.
     * <ul>
     *   <li>F/UF (átadás):  fromBranch += , toBranch -=  (a készpénz VISSZAKERÜL a feladóhoz)</li>
     *   <li>U   (átvétel):  fromBranch -=                (a készpénz KIKERÜL a fogadóból)</li>
     *   <li>FF  (korrekció): fromBranch += , toBranch += (a két kivét visszafordítása)</li>
     * </ul>
     */
    private void reverseCounterTransactions(Transfer transfer, Worker actor, Transfer.TransferDirection direction) {
        final java.util.List<TransferLine> bookLines = effectiveLines(transfer);
        // A toBranch-et minden irány érinti a visszafordításnál, KIVÉVE az U-t (ott csak a fromBranch mozdult).
        final boolean touchesToBranch = direction != Transfer.TransferDirection.U;
        // PRE-LOCK ugyanabban a globális (branchId, currencyId) sorrendben, mint a create — nincs deadlock.
        final java.util.List<hu.puzzleir.valuta.util.CashLockOrdering.BranchCurrencyKey> lockKeys =
                new java.util.ArrayList<>();
        for (TransferLine ln : bookLines) {
            Long cid = ln.getCurrency().getId();
            lockKeys.add(new hu.puzzleir.valuta.util.CashLockOrdering.BranchCurrencyKey(
                    transfer.getFromBranch().getId(), cid));
            if (touchesToBranch) {
                lockKeys.add(new hu.puzzleir.valuta.util.CashLockOrdering.BranchCurrencyKey(
                        transfer.getToBranch().getId(), cid));
            }
        }
        hu.puzzleir.valuta.util.CashLockOrdering.lockBranchCurrencyPairsInGlobalOrder(
                (bid, c) -> cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(bid, c),
                lockKeys.toArray(new hu.puzzleir.valuta.util.CashLockOrdering.BranchCurrencyKey[0]));

        final boolean multiLine = transfer.getLines() != null && !transfer.getLines().isEmpty();
        for (TransferLine ln : bookLines) {
            // A FELADÓ kasszáját a KIKÜLDÖTT (ln.amount), a FOGADÓ kasszáját a TÉNYLEGESEN FOGADOTT
            // összeggel kell visszafordítani (F-átadásnál a receive a receivedAmount-tal könyvelt).
            BigDecimal sent = ln.getAmount();
            BigDecimal received = multiLine
                    ? (ln.getReceivedAmount() != null ? ln.getReceivedAmount() : ln.getAmount())
                    : (transfer.getReceivedAmount() != null ? transfer.getReceivedAmount() : ln.getAmount());
            switch (direction) {
                case F, UF -> {
                    increaseCashBalance(transfer.getFromBranch(), ln.getCurrency(), sent);
                    decreaseCashBalance(transfer.getToBranch(), ln.getCurrency(), received);
                    createReversalTransaction(transfer, actor, transfer.getFromBranch(), ln.getCurrency(), sent, TransactionType.TRANSFER_IN);
                    createReversalTransaction(transfer, actor, transfer.getToBranch(), ln.getCurrency(), received, TransactionType.TRANSFER_OUT);
                }
                case U -> {
                    decreaseCashBalance(transfer.getFromBranch(), ln.getCurrency(), sent);
                    createReversalTransaction(transfer, actor, transfer.getFromBranch(), ln.getCurrency(), sent, TransactionType.TRANSFER_OUT);
                }
                case FF -> {
                    increaseCashBalance(transfer.getFromBranch(), ln.getCurrency(), sent);
                    increaseCashBalance(transfer.getToBranch(), ln.getCurrency(), sent);
                    createReversalTransaction(transfer, actor, transfer.getFromBranch(), ln.getCurrency(), sent, TransactionType.TRANSFER_IN);
                    createReversalTransaction(transfer, actor, transfer.getToBranch(), ln.getCurrency(), sent, TransactionType.TRANSFER_IN);
                }
            }
        }
        log.info("Sztornó visszafordítás kész: {} ({} sor, irány {})",
                transfer.getTransferNumber(), bookLines.size(), direction);
    }

    /** Ellentételező (sztornó) tranzakció — a kassza-mozgást alátámasztó audit/könyvelési tétel. */
    private void createReversalTransaction(Transfer transfer, Worker worker, Branch branch,
                                           Currency currency, BigDecimal amount, TransactionType type) {
        String receiptNumber = receiptSequenceService.generateReceiptNumber(branch.getId(), type);
        Transaction tx = Transaction.builder()
                .company(branch.getCompany())
                .branch(branch)
                .worker(worker)
                .receiptNumber(receiptNumber)
                .transactionType(type)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.now())
                .transactionTime(LocalTime.now())
                .currency(currency)
                .currencyAmount(amount)
                .exchangeRate(BigDecimal.ONE)
                .hufAmount(transfer.getHufValue() != null ? transfer.getHufValue() : BigDecimal.ZERO)
                .referenceNumber(transfer.getTransferNumber() + "-SZ")
                .notes(String.format("Sztornó visszafordítás: %s [%s]",
                        transfer.getTransferNumber(), transfer.getCancellationReason()))
                .build();
        transactionRepository.save(tx);
        log.debug("Sztornó ellentételező tx: {} {} {} @ {}", type, currency.getCode(), amount, branch.getCode());
    }

    /**
     * Könyvelendő sorok: ha a transfernek vannak valuta-sorai (#6 multi-line), azokat;
     * különben egyetlen szintetikus sor a header currency+amount-ból (egy-valutás kompat).
     */
    private java.util.List<TransferLine> effectiveLines(Transfer transfer) {
        if (transfer.getLines() != null && !transfer.getLines().isEmpty()) {
            return transfer.getLines();
        }
        return java.util.List.of(TransferLine.builder()
                .currency(transfer.getCurrency())
                .amount(transfer.getAmount())
                .build());
    }

    /** Multi-line sorok fogadottnak jelölése (received = amount, difference = 0). */
    private void markLinesReceived(Transfer transfer) {
        if (transfer.getLines() != null) {
            for (TransferLine ln : transfer.getLines()) {
                ln.setReceivedAmount(ln.getAmount());
                ln.setDifference(BigDecimal.ZERO);
            }
        }
    }

    /**
     * TRANSFER_OUT tranzakció létrehozása a küldő fióknál.
     */
    private Transaction createTransferOutTransaction(Transfer transfer, Worker worker) {
        return createTransferOutTransaction(transfer, worker, transfer.getCurrency(), transfer.getAmount());
    }

    private Transaction createTransferOutTransaction(Transfer transfer, Worker worker, Currency currency, BigDecimal amount) {
        Branch fromBranch = transfer.getFromBranch();
        String receiptNumber = receiptSequenceService.generateReceiptNumber(
                fromBranch.getId(), TransactionType.TRANSFER_OUT);

        Transaction tx = Transaction.builder()
                .company(fromBranch.getCompany())
                .branch(fromBranch)
                .worker(worker)
                .receiptNumber(receiptNumber)
                .transactionType(TransactionType.TRANSFER_OUT)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.now())
                .transactionTime(LocalTime.now())
                .currency(currency)
                .currencyAmount(amount)
                .exchangeRate(BigDecimal.ONE) // Átadásnál nincs árfolyam
                .hufAmount(transfer.getHufValue() != null ? transfer.getHufValue() : BigDecimal.ZERO)
                .referenceNumber(transfer.getTransferNumber())
                .notes(String.format("Átadás (%s): %s -> %s [%s]",
                        transfer.getDirection(),
                        fromBranch.getCode(),
                        transfer.getToBranch().getCode(),
                        transfer.getTransferNumber()))
                .build();

        tx = transactionRepository.save(tx);
        log.debug("TRANSFER_OUT tx létrehozva: receipt={}, transfer={}", receiptNumber, transfer.getTransferNumber());
        return tx;
    }

    /**
     * TRANSFER_IN tranzakció létrehozása a megadott fióknál.
     */
    private Transaction createTransferInTransaction(Transfer transfer, Worker worker, Branch atBranch) {
        return createTransferInTransaction(transfer, worker, atBranch, transfer.getCurrency(), transfer.getAmount());
    }

    private Transaction createTransferInTransaction(Transfer transfer, Worker worker, Branch atBranch, Currency currency, BigDecimal amount) {
        Branch sourceBranch = atBranch.getId().equals(transfer.getToBranch().getId())
                ? transfer.getFromBranch() : transfer.getToBranch();
        String receiptNumber = receiptSequenceService.generateReceiptNumber(
                atBranch.getId(), TransactionType.TRANSFER_IN);

        Transaction tx = Transaction.builder()
                .company(atBranch.getCompany())
                .branch(atBranch)
                .worker(worker)
                .receiptNumber(receiptNumber)
                .transactionType(TransactionType.TRANSFER_IN)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.now())
                .transactionTime(LocalTime.now())
                .currency(currency)
                .currencyAmount(amount)
                .exchangeRate(BigDecimal.ONE)
                .hufAmount(transfer.getHufValue() != null ? transfer.getHufValue() : BigDecimal.ZERO)
                .referenceNumber(transfer.getTransferNumber())
                .notes(String.format("Átvétel (%s): %s <- %s [%s]",
                        transfer.getDirection(),
                        atBranch.getCode(),
                        sourceBranch.getCode(),
                        transfer.getTransferNumber()))
                .build();

        tx = transactionRepository.save(tx);
        log.debug("TRANSFER_IN tx létrehozva: receipt={}, transfer={}", receiptNumber, transfer.getTransferNumber());
        return tx;
    }

    /**
     * FF korrekciós TRANSFER_OUT a fogadó fióknál (második kimenő tranzakció).
     */
    private Transaction createCorrectionTransferOutTransaction(Transfer transfer, Worker worker) {
        return createCorrectionTransferOutTransaction(transfer, worker, transfer.getCurrency(), transfer.getAmount());
    }

    private Transaction createCorrectionTransferOutTransaction(Transfer transfer, Worker worker, Currency currency, BigDecimal amount) {
        Branch toBranch = transfer.getToBranch();
        String receiptNumber = receiptSequenceService.generateReceiptNumber(
                toBranch.getId(), TransactionType.TRANSFER_OUT);

        Transaction tx = Transaction.builder()
                .company(toBranch.getCompany())
                .branch(toBranch)
                .worker(worker)
                .receiptNumber(receiptNumber)
                .transactionType(TransactionType.TRANSFER_OUT)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.now())
                .transactionTime(LocalTime.now())
                .currency(currency)
                .currencyAmount(amount)
                .exchangeRate(BigDecimal.ONE)
                .hufAmount(transfer.getHufValue() != null ? transfer.getHufValue() : BigDecimal.ZERO)
                .referenceNumber(transfer.getTransferNumber())
                .notes(String.format("Korrekciós átadás (FF): %s [%s]",
                        toBranch.getCode(), transfer.getTransferNumber()))
                .build();

        tx = transactionRepository.save(tx);
        log.debug("FF korrekciós TRANSFER_OUT tx létrehozva: receipt={}, transfer={}",
                receiptNumber, transfer.getTransferNumber());
        return tx;
    }

    // --- Cash balance updates with pessimistic locking ---

    /**
     * Kassza egyenleg csökkentése PESSIMISTIC LOCK-kal.
     */
    private void decreaseCashBalance(Branch branch, Currency currency, BigDecimal amount) {
        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(
                branch.getId(), currency.getId())
                .orElseThrow(() -> new ValidationException(
                        String.format("Kassza egyenleg nem található: %s / %s",
                                branch.getCode(), currency.getCode())));

        // Negatív kassza védelem
        if (balance.getCurrentBalance().compareTo(amount) < 0) {
            throw new ValidationException(String.format(
                    "Fiók egyenlege nem elegendő! Iroda: %s, valuta: %s, elérhető: %s, szükséges: %s",
                    branch.getCode(), currency.getCode(), balance.getCurrentBalance(), amount));
        }

        balance.updateBalance(amount, false);
        cashBalanceRepository.save(balance);
        log.debug("Kassza csökkentve: {} {} -= {}", branch.getCode(), currency.getCode(), amount);
    }

    /**
     * Kassza egyenleg növelése PESSIMISTIC LOCK-kal.
     */
    private void increaseCashBalance(Branch branch, Currency currency, BigDecimal amount) {
        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(
                branch.getId(), currency.getId())
                .orElseThrow(() -> new ValidationException(
                        String.format("Kassza egyenleg nem található: %s / %s",
                                branch.getCode(), currency.getCode())));

        balance.updateBalance(amount, true);
        cashBalanceRepository.save(balance);
        log.debug("Kassza növelve: {} {} += {}", branch.getCode(), currency.getCode(), amount);
    }

    /**
     * Kassza egyenleg frissítés a receive (fogadás) művelet során.
     * Az F módnál a create-nál már megtörtént a fromBranch csökkentés,
     * itt a fogadó oldal történik.
     */
    private void updateCashBalancesOnReceive(Transfer transfer, BigDecimal receivedAmount,
                                              Transfer.TransferDirection direction) {
        switch (direction) {
            case F -> {
                // F mód: a küldő oldal a create-nál már csökkent, itt a fogadó oldal növekszik.
                if (transfer.getLines() != null && !transfer.getLines().isEmpty()) {
                    // #6 multi-line: minden valuta-sor a saját összegével a fogadó kasszájába.
                    for (TransferLine ln : transfer.getLines()) {
                        increaseCashBalance(transfer.getToBranch(), ln.getCurrency(), ln.getAmount());
                        ln.setReceivedAmount(ln.getAmount());
                        ln.setDifference(BigDecimal.ZERO);
                    }
                } else {
                    increaseCashBalance(transfer.getToBranch(), transfer.getCurrency(), receivedAmount);
                }
            }
            case U, UF, FF -> {
                // U/UF/FF: a create-nál már mindkét oldal kassza frissült, receive-nél nincs kassza módosítás
                log.debug("Receive: {} módban nincs további kassza módosítás: {}",
                        direction, transfer.getTransferNumber());
            }
        }
    }

    // --- Helpers ---

    private Transfer findOrThrow(Long id) {
        return transferRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Átadás nem található: " + id));
    }

    /**
     * FK-005/B2+B3: átadólap-sorszám a spec szerint — átadás/átvétel + valuta/HUF szerint
     * külön prefixszel, gap-mentes szekvenciával:
     * <ul>
     *   <li>deviza átadás  → {@code AT-NNNNNN}  pl. AT-000001</li>
     *   <li>deviza átvétel → {@code AV-NNNNNN}  pl. AV-000001</li>
     *   <li>HUF átadás     → {@code FF-NNNNNN}  pl. FF-000001</li>
     *   <li>HUF átvétel    → {@code UF-NNNNNN}  pl. UF-000001</li>
     * </ul>
     * CÉGSZINTŰ folyamatos sorszám (NEM pénztáranként, NEM dátum-alapú); egyediség: tenant + prefix
     * atomikus DB számláló + a (company_id, transfer_number) COMPOSITE UNIQUE (V299).
     * Két cég azonos sorszáma megengedett.
     * Az átadás/átvétel az üzleti irányból: {@code U} (Vevő) = átvétel; minden más (F/UF/FF)
     * = átadás — a "mindkét-irány" és "korrekció" edge-case az átadás-családba (Kósa Zoltán
     * döntés, 2026-05-25). A branch-szám a forrásfiók kódjának numerikus része (BR020 → 020).
     * Konkurencia: a számláló {@code INSERT ... ON CONFLICT ... DO UPDATE ... RETURNING}
     * művelettel lép, ezért párhuzamos hívásoknál sem keletkezhet duplikált tenant/prefix sorszám.
     */
    private String generateTransferNumber(Transfer.TransferDirection direction, Currency currency, UUID companyId) {
        boolean atvetel = direction == Transfer.TransferDirection.U;
        boolean huf = currency != null && "HUF".equalsIgnoreCase(currency.getCode());
        // Értéktári átadás-átvétel sorszám-prefix: deviza átadás=AT, deviza átvétel=AV;
        // HUF átadás=FF, HUF átvétel=UF. Az átvétel CSAK a U irány; a "mindkét-irány"/korrekció
        // (UF/FF direction) az átadás-családba esik (Kósa Zoltán döntés). Minden prefix 2 karakter.
        String prefix = huf ? (atvetel ? "UF" : "FF") : (atvetel ? "AV" : "AT");
        long next = transferSerialSequenceService.next(companyId, prefix);
        return prefix + "-" + String.format("%06d", next);
    }

    private TransferDto toDto(Transfer t) {
        return TransferDto.builder()
                .id(t.getId())
                .transferNumber(t.getTransferNumber())
                .fromBranchId(t.getFromBranch().getId().toString())
                .fromBranchCode(t.getFromBranch().getCode())
                .fromBranchName(t.getFromBranch().getName())
                .toBranchId(t.getToBranch().getId().toString())
                .toBranchCode(t.getToBranch().getCode())
                .toBranchName(t.getToBranch().getName())
                .fromWorkerId(t.getFromWorker().getId())
                .fromWorkerName(t.getFromWorker().getName())
                .toWorkerId(t.getToWorker() != null ? t.getToWorker().getId() : null)
                .toWorkerName(t.getToWorker() != null ? t.getToWorker().getName() : null)
                .transferType(t.getTransferType().name())
                .transferTypeDisplay(getTransferTypeDisplay(t.getTransferType()))
                .direction(t.getDirection() != null ? t.getDirection().name() : "UF")
                .directionDisplay(getDirectionDisplay(t.getDirection()))
                .status(t.getStatus().name())
                .statusDisplay(getStatusDisplay(t.getStatus()))
                .transferDate(t.getTransferDate().toString())
                .transferTime(t.getTransferTime().toString())
                .receivedDate(t.getReceivedDate() != null ? t.getReceivedDate().toString() : null)
                .receivedTime(t.getReceivedTime() != null ? t.getReceivedTime().toString() : null)
                .currencyId(t.getCurrency().getId())
                .currencyCode(t.getCurrency().getCode())
                .currencyName(t.getCurrency().getName())
                .amount(t.getAmount())
                .hufValue(t.getHufValue())
                .receivedAmount(t.getReceivedAmount())
                .difference(t.getDifference())
                .notes(t.getNotes())
                .carrierName(t.getCarrierName())
                .sealNumber(t.getSealNumber())
                .handoverPrinted(t.getHandoverPrinted())
                .receiptPrinted(t.getReceiptPrinted())
                .createdAt(t.getCreatedAt() != null ? t.getCreatedAt().toString() : null)
                .hasDifference(t.getDifference() != null && t.getDifference().compareTo(BigDecimal.ZERO) != 0)
                .isCompleted(t.getStatus() == Transfer.TransferStatus.COMPLETED)
                .isPending(t.getStatus() == Transfer.TransferStatus.PENDING)
                .lines(mapLines(t))
                // Értéktári átadás-átvétel bizonylat bővítések:
                .vaultAddress(currentVaultAddress())
                .isCancelled(Boolean.TRUE.equals(t.getIsCancelled()))
                .cancellationReason(t.getCancellationReason())
                .cancelledAt(t.getCancelledAt() != null ? t.getCancelledAt().toString() : null)
                .stornoSerialNumber(Boolean.TRUE.equals(t.getIsCancelled()) ? t.getTransferNumber() + "-SZ" : null)
                .denominations(mapDenominations(t))
                .build();
    }

    /**
     * FR-1: a bejelentkezett értéktár (Branch) saját helyi címe a bizonylat fejlécéhez —
     * "Város, Cím, IRSZ" (pl. "Szeged, Hajnóczy u. 57., 6722"). A céget+adószámot a frontend tartja;
     * itt CSAK a cím dinamikus, a JWT branchId-ból. A branchRepository.findById az aktuális
     * tranzakción belül L1-cache-elt (azonos branchId → 1 query lista-renderelésnél is).
     */
    private String currentVaultAddress() {
        // OrNull: SecurityContext nélküli hívás (teszt/scheduler) ne dobjon — ekkor nincs vaultAddress.
        UUID branchId = SecurityUtils.getCurrentBranchIdOrNull();
        if (branchId == null) {
            return null;
        }
        return branchRepository.findById(branchId).map(this::formatBranchAddress).orElse(null);
    }

    private String formatBranchAddress(Branch b) {
        java.util.List<String> parts = new java.util.ArrayList<>();
        if (b.getCity() != null && !b.getCity().isBlank()) parts.add(b.getCity().trim());
        if (b.getAddress() != null && !b.getAddress().isBlank()) parts.add(b.getAddress().trim());
        if (b.getZipCode() != null && !b.getZipCode().isBlank()) parts.add(b.getZipCode().trim());
        return parts.isEmpty() ? null : String.join(", ", parts);
    }

    private java.util.List<TransferDenominationDto> mapDenominations(Transfer t) {
        if (t.getDenominations() == null || t.getDenominations().isEmpty()) {
            return null; // nincs címletezés → NON_NULL miatt kimarad a JSON-ból (a bizonylaton sem jelenik meg)
        }
        return t.getDenominations().stream()
                .map(d -> TransferDenominationDto.builder()
                        .quantity(d.getQuantity())
                        .faceValue(d.getFaceValue())
                        .currencyCode(d.getCurrencyCode())
                        .lineTotal(d.getLineTotal())
                        .build())
                .toList();
    }

    private String normalizeStornoReason(String reason) {
        if (reason == null || reason.trim().isEmpty()) {
            throw new ValidationException("A sztornó indoklása kötelező.");
        }
        String normalized = reason.trim();
        if (normalized.length() > 500) {
            throw new ValidationException("A sztornó indoklása legfeljebb 500 karakter lehet.");
        }
        return normalized;
    }

    private java.util.List<hu.puzzleir.valuta.dto.transfer.TransferLineDto> mapLines(Transfer t) {
        if (t.getLines() == null || t.getLines().isEmpty()) {
            return null; // egy-valutás átadás → nincs sor (NON_NULL inclusion miatt kimarad a JSON-ból)
        }
        return t.getLines().stream()
                .sorted(java.util.Comparator.comparing(l -> l.getLineNo() != null ? l.getLineNo() : 0))
                .map(l -> hu.puzzleir.valuta.dto.transfer.TransferLineDto.builder()
                        .currencyId(l.getCurrency().getId())
                        .currencyCode(l.getCurrency().getCode())
                        .currencyName(l.getCurrency().getName())
                        .amount(l.getAmount())
                        .receivedAmount(l.getReceivedAmount())
                        .difference(l.getDifference())
                        .lineNo(l.getLineNo())
                        .build())
                .toList();
    }

    private String getTransferTypeDisplay(Transfer.TransferType type) {
        return switch (type) {
            case CURRENCY -> "Deviza";
            case CASH -> "Készpénz";
            case HANDLING_FEE -> "Kezelési díj";
            case VAULT_DEPOSIT -> "Széf befizetés";
            case VAULT_WITHDRAW -> "Széf kivét";
            case CORRECTION -> "Korrekció";
            case OTHER -> "Egyéb";
        };
    }

    private String getDirectionDisplay(Transfer.TransferDirection direction) {
        if (direction == null) return "Teljes (UF)";
        return switch (direction) {
            case F -> "Feladó (F)";
            case U -> "Vevő (U)";
            case UF -> "Teljes (UF)";
            case FF -> "Korrekció (FF)";
        };
    }

    private String getStatusDisplay(Transfer.TransferStatus status) {
        return switch (status) {
            case PENDING -> "Függőben";
            case IN_TRANSIT -> "Szállítás alatt";
            case RECEIVED -> "Átvéve";
            case COMPLETED -> "Befejezve";
            case REJECTED -> "Elutasítva";
            case CANCELLED -> "Törölve";
        };
    }
}
