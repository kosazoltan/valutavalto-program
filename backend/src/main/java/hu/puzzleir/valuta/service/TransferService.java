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
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import hu.puzzleir.valuta.exception.ConflictException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Set;
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
    /** FKH-022 FR-K2: HUF naplókönyv éves sorszám (FF-/UF- bizonylatnál, cég+év számláló). */
    private final HufDaybookSequenceService hufDaybookSequenceService;
    private final AuditLogService auditLogService;
    // Batch3-B (currency_stock-doc FR-1/FR-2): a vault-erintett kassza-mozgasok
    // currency_stock ("B konyv") tukrozesehez.
    private final VaultStockFlowService vaultStockFlowService;
    private final AccessScopeService accessScopeService;

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

        // Azonos-fiók ellenőrzés a tenant-guard ELŐTT: olcsóbb, beszédesebb hibaüzenet, és egy
        // azonos forrás=cél fiók triviálisan ugyanahhoz a céghez tartozik (nincs cross-tenant kérdés).
        if (fromBranch.getId().equals(toBranch.getId())) {
            throw new ValidationException("A forrás és cél fiók nem lehet azonos!");
        }

        // IDOR-guard: a toBranchId user-vezérelt és eddig sosem volt cég-scope-ra validálva — a
        // transfer companyId-ja a fromBranch-ből jön, ezért a cél-fióknak a forrás cégéhez kell
        // tartoznia; cross-tenant → ResourceNotFoundException.
        if (fromBranch.getCompany() == null
                || !branchRepository.existsByIdAndCompanyId(toBranch.getId(), fromBranch.getCompany().getId())) {
            throw new ResourceNotFoundException("Célfiók nem található: " + dto.getToBranchId());
        }

        Currency currency = currencyRepository.findById(dto.getCurrencyId())
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található: " + dto.getCurrencyId()));

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

        // Kötés-típus parse + technikai gyűjtő-kód invariánsok (ERB/FRB/TRB/PRB, c4 P3#5).
        // A guard a sorszám-generálás ELŐTT fut, hogy elutasításkor ne keletkezzen sorszám-lyuk.
        if (dto.getTransferType() == null || dto.getTransferType().isBlank()) {
            // Copilot (#1092): valueOf(null) NPE-t dobna (500), a @NotNull csak a HTTP-útvonalat védi.
            throw new ValidationException("A kötés-típus megadása kötelező!");
        }
        Transfer.TransferType transferType;
        try {
            transferType = Transfer.TransferType.valueOf(dto.getTransferType());
        } catch (IllegalArgumentException e) {
            throw new ValidationException("Érvénytelen kötés-típus: " + dto.getTransferType());
        }
        if (isTechnicalRb(transferType) && !Boolean.TRUE.equals(fromBranch.getIsVault())) {
            // Codex/Copilot P2 (#1092): a vault-only szabály backend-oldali kikényszerítése —
            // a technikai RB-kötést csak értéktári fiók dolgozója rögzítheti, a FE-szűrés
            // közvetlen API-hívással nem kerülhető meg.
            throw new ValidationException(transferType + " technikai kötés csak értéktári fiókból rögzíthető!");
        }
        validateTechnicalRbCurrency(transferType, currency);
        if (isTechnicalRb(transferType) && dto.getLines() != null) {
            // A valuta-invariáns a multi-line sorokra is érvényes (a könyvelés soronként megy).
            // A findById itt tölti be először a sor-valutát; a későbbi sor-feldolgozás ugyanazt
            // a példányt a persistence contextből kapja, így összességében nincs plusz query.
            for (var l : dto.getLines()) {
                Currency lineCurrency = currencyRepository.findById(l.getCurrencyId())
                        .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található: " + l.getCurrencyId()));
                validateTechnicalRbCurrency(transferType, lineCurrency);
            }
        }
        // Az átvétel a rendszer-definíció szerint KIZÁRÓLAG a U irány (generateTransferNumber:
        // atvetel = direction == U; F/UF/FF = átadás-család) → minden mást elutasítunk,
        // a kihagyott direction default UF-ját is.
        if (transferType == Transfer.TransferType.PRB && direction != Transfer.TransferDirection.U) {
            throw new ValidationException("PRB (POS átvétel banktól) csak átvétel (U) irányban rögzíthető!");
        }

        // A sorszám és a címletezés cég-azonosítója a forrásfiók cégéből jön; a sorszám
        // tenant + prefix szinten folyamatos és DB-oldalon atomikusan léptetett.
        UUID companyId = fromBranch.getCompany() != null
                ? fromBranch.getCompany().getId() : SecurityUtils.getCurrentCompanyIdOrNull();

        // FK-053: fedezet nélkül nincs pénzmozgás. A vault-oldali currency_stock fedezetet
        // még a sorszám- és bizonylat-mentés előtt ellenőrizzük, hogy elutasított mozgásnál
        // ne keletkezzen részleges transfer/transaction/cash_balance állapot.
        validateVaultCoverageBeforeCreate(fromBranch, toBranch, currency, dto, direction);

        String transferNumber = generateTransferNumber(direction, currency, companyId);

        // FKH-022 FR-K2: FF-/UF- (HUF) bizonylat a naplókönyv cég+év szerinti éves
        // sorszámát is megkapja — a shipment-oldali kiosztással közös számlálóból.
        Integer annualJournalSequence = null;
        if (companyId != null && isHufDaybookNumber(transferNumber)) {
            annualJournalSequence = hufDaybookSequenceService.next(companyId, LocalDate.now().getYear());
        }

        // HUF-fallback (FR-5, FR-6): HUF esetén az elszámoló árfolyam konstans 1,0000 → a forintosított
        // érték = összeg (5 Ft-ra kerekítve). HUF-nál NINCS DB-árfolyam, ezért a rögzítés sosem
        // blokkolódik árfolyam hiányára. Más valutánál a kliens által küldött hufValue marad.
        boolean isHuf = "HUF".equalsIgnoreCase(currency.getCode());
        BigDecimal hufValue = isHuf ? HungarianRounding.roundToFive(dto.getAmount()) : dto.getHufValue();

        Transfer transfer = Transfer.builder()
                .transferNumber(transferNumber)
                .annualJournalSequence(annualJournalSequence)
                .companyId(companyId)
                .fromBranch(fromBranch)
                .toBranch(toBranch)
                .fromWorker(fromWorker)
                .transferType(transferType)
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
            if (!hasVaultCoverageCheckOnCreate(direction)) {
                validateUniqueTransferLineCurrencies(dto);
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
                // FK-072 (FR-4): 1 alatti (tört) névleges érték nem rögzíthető — az üzleti
                // gyakorlatban tört címlet fizikailag nem fordulhat elő.
                if (d.getFaceValue().compareTo(BigDecimal.ONE) < 0) {
                    throw new ValidationException(
                            "VV-VALID-002: A címlet névleges értéke nem lehet 1-nél kisebb"
                                    + " (tört címlet nem rögzíthető)!");
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

        Worker toWorker = workerRepository.findByIdAndCompanyId(workerId, transfer.getCompanyId())
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

        // Audit log — felelősségi nyom (hibajelentés 2026-07-14 / 3. kérdés): vitás ügyben
        // visszakereshető, MELYIK dolgozó igazolta vissza az átvételt, és a bizonylaton
        // rögzített Szállító (carrierName) neve MELLETTE szerepel ("kinek a megbízásából").
        // A "Átadás fogadva: " prefix változatlan (log-grep kompatibilitás).
        String auditMessage = String.format(
                "Átadás fogadva: %s, irány: %s, fogadott összeg: %s, különbözet: %s, igazoló dolgozó: %s (%s)",
                transfer.getTransferNumber(), direction,
                dto.getReceivedAmount(), transfer.getDifference(),
                toWorker.getName(), toWorker.getCode());
        if (transfer.getCarrierName() != null && !transfer.getCarrierName().isBlank()) {
            auditMessage += String.format(
                    ", a bizonylaton rögzített szállító (%s) megbízásából",
                    sanitizeAuditValue(transfer.getCarrierName()));
        }
        auditLogService.log("TRANSFER_RECEIVED", auditMessage, transfer.getId());

        return toDto(transfer);
    }

    private static String sanitizeAuditValue(String value) {
        return value == null ? null : value.replaceAll("[\\x00-\\x1F\\x7F]", "_");
    }

    /**
     * PENDING átadás elutasítása a FOGADÓ oldalról (a {@link #receive} ellenpárja).
     *
     * <p><b>Tenant/branch-scope guard (security hardening).</b> A metódus korábban nyers
     * {@code findOrThrow(id)}-ra épült, cég- és fiók-ellenőrzés nélkül: ismert azonosító
     * birtokában egy jogosult felhasználó MÁS cég vagy MÁS fiók PENDING átadását is
     * elutasíthatta ({@code security-standards.md} §1–§3). A guardok sorrendje a
     * {@link #storno} mintáját követi — a tenant-ellenőrzés MEGELŐZI az állapot-vizsgálatot,
     * hogy idegen azonosítóra a bizonylat létezése és státusza se szivárogjon (404, nem 403).
     *
     * <p>A fiók-guard a {@link #receive} mintája: az elutasítás a CÉLFIÓK joga (a UI is csak a
     * bejövő listán kínálja fel, és a metódus az elutasítót {@code toWorker}-ként rögzíti).
     * A {@code null} branch-ű, országos szkópú szerepköröket — a {@code receive}-hez hasonlóan —
     * szándékosan átengedi.
     */
    @Transactional(rollbackFor = Exception.class)
    public TransferDto reject(Long id, String reason, Long workerId) {
        Transfer transfer = transferRepository.findById(id).orElse(null);
        assertOwnCompany(transfer, String.valueOf(id));
        assertTerritoryVisible(transfer, String.valueOf(id));

        Worker toWorker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Dolgozó nem található: " + workerId));

        // A célfiók joga — a receive:247 guardjának tükre (országos szkóp = null branch átengedve).
        if (toWorker.getBranch() != null && !java.util.Objects.equals(
                toWorker.getBranch().getId(), transfer.getToBranch().getId())) {
            throw new ValidationException("Csak a célfiók dolgozói utasíthatják el ezt az átadást!");
        }

        if (transfer.getStatus() != Transfer.TransferStatus.PENDING) {
            throw new ValidationException("Csak függőben lévő átadás utasítható el!");
        }
        // Kötelezően nem-üres indoklás — a mai frontend-viselkedés szerveroldali kikényszerítése.
        // Enélkül üres indoklású sor kerülhetne a HUF naplókönyvbe (a megjelenítés feltétele a
        // kitöltött cancellationReason).
        String normalizedReason = normalizeStornoReason(reason);

        transfer.setToWorker(toWorker);
        transfer.setStatus(Transfer.TransferStatus.REJECTED);
        transfer.setNotes((transfer.getNotes() != null ? transfer.getNotes() + "\n" : "")
                + "Elutasítás oka: " + normalizedReason);

        // Közös adatmodell a sztornóval: a HUF naplókönyv megkülönböztetője
        // (isCancelled = true AND cancellationReason IS NOT NULL) ezt igényli — így a
        // naplókönyv-lekérdezéseken NULLA változtatás kell, a REJECTED-et is fedik.
        // Az indoklás a reversal-generálás ELŐTT áll be (a createReversalTransaction olvassa).
        transfer.setIsCancelled(true);
        transfer.setCancelledAt(LocalDateTime.now());
        transfer.setCancellationReason(normalizedReason);
        transfer.setCancelledBy(toWorker.getId());

        // FKH-022 FR-K2/3: az elutasítás-sor SAJÁT naplókönyv-sorszáma HUF-os bizonylatnál.
        if (transfer.getCompanyId() != null && isHufDaybookNumber(transfer.getTransferNumber())) {
            transfer.setStornoJournalSequence(hufDaybookSequenceService.next(
                    transfer.getCompanyId(), transfer.getCancelledAt().getYear()));
        }

        // A create-kori könyvelés visszafordítása. A visszapótlandó oldalt a DIRECTION dönti el,
        // NEM a kezdeményező: a create ugyanazt könyvelte, akár a küldő vonja vissza
        // (stornoPending), akár a fogadó utasítja el. Ezért a helper változtatás nélkül közös.
        Transfer.TransferDirection dir = transfer.getDirection() != null
                ? transfer.getDirection() : Transfer.TransferDirection.UF;
        reversePendingCounterTransactions(transfer, toWorker, dir);

        transfer = transferRepository.save(transfer);

        // KÜLÖN audit-action: az elutasítás NEM sztornó, az audit-nyom nem nevezheti annak.
        // (A bizonylat-referencia ettől függetlenül közös "-SZ" marad — follow-up #21.)
        auditLogService.log("TRANSFER_REJECTED",
                String.format("VV-TX-004: Átadás-átvétel elutasítva: %s, indoklás: %s",
                        transfer.getTransferNumber(), normalizedReason),
                transfer.getId());

        return toDto(transfer);
    }

    // A korábbi cancel(Long) metódus TÖRÖLVE: csak státuszt váltott, a create-kori könyvelést
    // nem fordította vissza, bizonylatot és auditot sem generált — a küldő fiók kasszájából a
    // pénz némán elveszett. Az egyetlen hívója a /cancel végpont volt, ami mostantól a
    // storno(id, reason) diszpécserre irányít (PENDING → stornoPending). Teszt sem hivatkozta.

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
        // Státusz-diszpécser: a PENDING bizonylat KÜLÖN útvonalon (stornoPending) szűnik meg —
        // ott a create-kori könyvelést kell visszafordítani, és csak a küldő fiók jogosult.
        // A COMPLETED-ág változatlan. A két út szándékosan külön metódus, közös helperekkel.
        if (transfer.getStatus() == Transfer.TransferStatus.PENDING) {
            return stornoPending(transfer, reason);
        }
        return stornoCompleted(transfer, reason);
    }

    /**
     * COMPLETED átadás-átvétel sztornója — a korábbi {@code storno} törzse, VÁLTOZATLAN
     * viselkedéssel. A tenant- és {@code isCancelled}-guardot a hívó {@link #storno} futtatta le.
     */
    private TransferDto stornoCompleted(Transfer transfer, String reason) {
        // Csak véglegesített (COMPLETED) bizonylat sztornózható ezen az ágon — az IN_TRANSIT/
        // REJECTED/CANCELLED továbbra is elutasított (API-megkerülés elleni védelem).
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

        // FKH-022 FR-K2/3: a sztornó-sor SAJÁT naplókönyv-sorszámot kap (nem az eredetiét
        // ismétli), a sztornó pillanatának (cancelled_at) időrendi helyén. Az évet a
        // MEGRAGADOTT cancelledAt időbélyegből vesszük (Bugbot #2, PR #1518): így az élő
        // kiosztás és a V366 backfill év-szemantikája évhatáron is azonos.
        if (transfer.getCompanyId() != null && isHufDaybookNumber(transfer.getTransferNumber())) {
            transfer.setStornoJournalSequence(hufDaybookSequenceService.next(
                    transfer.getCompanyId(), transfer.getCancelledAt().getYear()));
        }

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

    /**
     * PENDING átadás-átvétel sztornója — a korábbi {@code cancel} útvonal helyett.
     *
     * <p>A régi {@code cancel} csak státuszt váltott: a create-kor lekönyvelt összeg NEM került
     * vissza, bizonylat és audit-nyom sem keletkezett — a küldő fiók kasszájából a pénz némán
     * elveszett. Ez az útvonal ugyanazt a szerződést adja, mint a COMPLETED-sztornó: kötelező
     * indoklás, fizikai visszapótlás, ellentételező bizonylat és {@code STORNO} audit.
     *
     * <p>Guard-sorrend: az {@code isCancelled}-ellenőrzést a hívó {@link #storno} futtatta
     * (idempotencia), itt a fiók-jogosultság, majd az indoklás következik — ebben a sorrendben,
     * hogy idegen fiókból érkező kísérlet indoklás nélkül is elutasításra kerüljön.
     *
     * <p>A COMPLETED-ágtól eltérően a státusz {@code CANCELLED}-re vált: a {@code receive} és a
     * pending-listák a STÁTUSZRA szűrnek ({@code isCancelled}-re nem), ezért enélkül a visszavont
     * tétel átvehető maradna — az pedig a visszapótolt összeg újbóli jóváírását jelentené.
     */
    private TransferDto stornoPending(Transfer transfer, String reason) {
        // Fiók-guard: kizárólag a küldő fiók dolgozója — a mai cancel jogosultsági köre marad.
        UUID currentBranchId = SecurityUtils.getCurrentBranchId();
        if (!transfer.getFromBranch().getId().equals(currentBranchId)) {
            throw new ValidationException("Csak a küldő fiók dolgozói törölhetik az átadást!");
        }
        String normalizedReason = normalizeStornoReason(reason);

        Worker actor = workerRepository.findById(SecurityUtils.getCurrentWorkerId())
                .orElseThrow(() -> new ResourceNotFoundException("Dolgozó nem található"));

        transfer.setIsCancelled(true);
        transfer.setCancelledAt(LocalDateTime.now());
        // Az indoklás a reversal-generálás ELŐTT áll be: a createReversalTransaction
        // notes-sablonja ezt olvassa (a COMPLETED-ág azonos sorrendje).
        transfer.setCancellationReason(normalizedReason);
        transfer.setCancelledBy(actor.getId());
        transfer.setStatus(Transfer.TransferStatus.CANCELLED);

        // FKH-022 FR-K2/3: a sztornó-sor SAJÁT naplókönyv-sorszáma HUF-os bizonylatnál.
        // A megjelenítést a TransferRepository naplókönyv-lekérdezéseinek PENDING-sztornó
        // bővítése biztosítja (isCancelled + kitöltött cancellationReason) — enélkül a
        // kiosztott sorszám némán elveszne, lyukat ütve a naplókönyv számozásában.
        if (transfer.getCompanyId() != null && isHufDaybookNumber(transfer.getTransferNumber())) {
            transfer.setStornoJournalSequence(hufDaybookSequenceService.next(
                    transfer.getCompanyId(), transfer.getCancelledAt().getYear()));
        }

        Transfer.TransferDirection dir = transfer.getDirection() != null
                ? transfer.getDirection() : Transfer.TransferDirection.UF;
        reversePendingCounterTransactions(transfer, actor, dir);

        transferRepository.save(transfer);

        auditLogService.log("STORNO",
                String.format("VV-TX-002: Átadás-átvétel sztornózva: %s, indoklás: %s",
                        transfer.getTransferNumber(), normalizedReason),
                transfer.getId());

        return toDto(transfer);
    }

    /**
     * A PENDING bizonylat CREATE-KORI könyvelésének visszafordítása, irány szerint.
     *
     * <p>Eltér a {@link #reverseCounterTransactions} COMPLETED-változatától: PENDING-ben a
     * FOGADÁS SOSEM történt meg, ezért az F irány kizárólag a küldő oldalt fordítja vissza
     * (a COMPLETED-ág ott a fogadó kasszáját is csökkentené, ami itt nem létező mozgás volna).
     * <ul>
     *   <li>F  (create: from −) → from +</li>
     *   <li>U  (create: from +) → from −  (fordított előjel)</li>
     *   <li>FF (create: from −, to −) → from +, to +</li>
     *   <li>UF — a create azonnal COMPLETED-re vált, ide nem juthat</li>
     * </ul>
     * A {@code receivedAmount} definíció szerint {@code null}, ezért mindenhol a kiküldött
     * sor-összeg a visszafordítandó érték. Elő-lock ugyanabban a globális
     * {@code (branchId, currencyId)} sorrendben, mint a create és a COMPLETED-sztornó.
     */
    private void reversePendingCounterTransactions(Transfer transfer, Worker actor,
                                                   Transfer.TransferDirection direction) {
        if (direction == Transfer.TransferDirection.UF) {
            // Fail-fast, még a zárolás és bármely mutáció előtt.
            throw new IllegalStateException(
                    "UF irányú átadás nem lehet PENDING állapotban: " + transfer.getTransferNumber());
        }
        final java.util.List<TransferLine> bookLines = effectiveLines(transfer);
        // A create FF-nél MINDKÉT oldalt csökkentette; F és U csak a fromBranch-et mozgatta.
        final boolean touchesToBranch = direction == Transfer.TransferDirection.FF;
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
        UUID cbCompanyId = requireBranchCompanyId(transfer.getFromBranch());
        hu.puzzleir.valuta.util.CashLockOrdering.lockBranchCurrencyPairsInGlobalOrder(
                (bid, c) -> cashBalanceRepository
                        .findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(bid, c, cbCompanyId),
                lockKeys.toArray(new hu.puzzleir.valuta.util.CashLockOrdering.BranchCurrencyKey[0]));

        for (TransferLine ln : bookLines) {
            BigDecimal sent = ln.getAmount();
            switch (direction) {
                case F -> {
                    increaseCashBalance(transfer.getFromBranch(), ln.getCurrency(), sent);
                    createReversalTransaction(transfer, actor, transfer.getFromBranch(),
                            ln.getCurrency(), sent, TransactionType.TRANSFER_IN);
                }
                case U -> {
                    decreaseCashBalance(transfer.getFromBranch(), ln.getCurrency(), sent);
                    createReversalTransaction(transfer, actor, transfer.getFromBranch(),
                            ln.getCurrency(), sent, TransactionType.TRANSFER_OUT);
                }
                case FF -> {
                    increaseCashBalance(transfer.getFromBranch(), ln.getCurrency(), sent);
                    increaseCashBalance(transfer.getToBranch(), ln.getCurrency(), sent);
                    createReversalTransaction(transfer, actor, transfer.getFromBranch(),
                            ln.getCurrency(), sent, TransactionType.TRANSFER_IN);
                    createReversalTransaction(transfer, actor, transfer.getToBranch(),
                            ln.getCurrency(), sent, TransactionType.TRANSFER_IN);
                }
                default -> throw new IllegalStateException(
                        "Nem kezelt irány a PENDING sztornóban: " + direction);
            }
        }
        log.info("PENDING sztornó visszafordítás kész: {} ({} sor, irány {})",
                transfer.getTransferNumber(), bookLines.size(), direction);
    }

    @Transactional(readOnly = true)
    public TransferDto getById(Long id) {
        Transfer transfer = findOrThrow(id);
        // Multi-tenant IDOR-guard (audit 2026-06-15): szekvenciális Long id-vel enumerálható volt
        // idegen cég átadás-bizonylata; a getStornoPreview-vel azonos ownership-check.
        assertOwnCompany(transfer, String.valueOf(id));
        assertTerritoryVisible(transfer, String.valueOf(id));
        return toDto(transfer);
    }

    /**
     * Sztornó bizonylat előnézet-adatai (FR-15): az eredeti bizonylat adatai + indoklás +
     * a {@code <eredeti>-SZ} sorszám (a {@link #toDto} tölti). Tenant-szűrt.
     */
    @Transactional(readOnly = true)
    public TransferDto getStornoPreview(Long id) {
        Transfer transfer = transferRepository.findById(id).orElse(null);
        assertOwnCompany(transfer, String.valueOf(id));
        assertTerritoryVisible(transfer, String.valueOf(id));
        TransferDto preview = toDto(transfer);
        preview.setStornoSerialNumber(transfer.getTransferNumber() + "-SZ");
        return preview;
    }

    @Transactional(readOnly = true)
    public TransferDto getByTransferNumber(String transferNumber) {
        Transfer transfer = transferRepository.findByTransferNumber(transferNumber)
                .orElseThrow(() -> new ResourceNotFoundException("Átadás nem található: " + transferNumber));
        // Multi-tenant IDOR-guard (audit 2026-06-15): a transferNumber is user-controlled.
        assertOwnCompany(transfer, transferNumber);
        assertTerritoryVisible(transfer, transferNumber);
        return toDto(transfer);
    }

    /**
     * Multi-tenant ownership-guard: az átadás a hívó cégéhez tartozik-e (from- vagy to-branch
     * cége egyezik). Cross-tenant → ResourceNotFoundException (nem 403, hogy a létezés se szivárogjon).
     */
    private void assertOwnCompany(Transfer transfer, String idForMessage) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        boolean ownCompany = transfer != null && companyId != null
                && ((transfer.getFromBranch() != null && transfer.getFromBranch().getCompany() != null
                        && companyId.equals(transfer.getFromBranch().getCompany().getId()))
                    || (transfer.getToBranch() != null && transfer.getToBranch().getCompany() != null
                        && companyId.equals(transfer.getToBranch().getCompany().getId())));
        if (!ownCompany) {
            throw new ResourceNotFoundException("Átadás nem található: " + idForMessage);
        }
    }

    /**
     * Territory-scope guard (2026-07-15 hardening, Bali H. #2): territory-scoped role
     * (régiós ERTEKTAR) csak olyan átadást olvashat, amelynek BÁRMELYIK vége (from VAGY to)
     * a saját region-scope-jában van. Scope-on kívül → 404 (nem 403 — az assertOwnCompany-val
     * azonos anti-enumeráció konvenció, a létezés se szivárogjon). Központi role → null scope
     * → nincs szűkítés. A companyId-tenant-guard (assertOwnCompany) UTÁN hívandó, arra épül rá.
     */
    private void assertTerritoryVisible(Transfer transfer, String idForMessage) {
        Set<UUID> scope = accessScopeService.vaultRegionBranchScopeOrNull();
        if (scope == null) {
            return; // központi role — nincs terület-szűkítés
        }
        String fromId = transfer.getFromBranch() != null && transfer.getFromBranch().getId() != null
                ? transfer.getFromBranch().getId().toString() : null;
        String toId = transfer.getToBranch() != null && transfer.getToBranch().getId() != null
                ? transfer.getToBranch().getId().toString() : null;
        boolean visible = accessScopeService.isBranchVisible(scope, fromId)
                || accessScopeService.isBranchVisible(scope, toId);
        if (!visible) {
            throw new ResourceNotFoundException("Átadás nem található: " + idForMessage);
        }
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
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return transferRepository.findOutgoingByBranch(companyId, branchId)
                .stream().map(this::toDto).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<TransferDto> getIncoming(UUID branchId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return transferRepository.findIncomingByBranch(companyId, branchId)
                .stream().map(this::toDto).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public Page<TransferDto> search(UUID branchId, LocalDate startDate, LocalDate endDate,
                                     Transfer.TransferStatus status, Transfer.TransferType type, Pageable pageable) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Set<UUID> scope = accessScopeService.vaultRegionBranchScopeOrNull();
        if (scope != null) {
            if (scope.isEmpty()) {
                // Fail-closed (nincs meghatározható region): üres oldal, nem országos lista.
                return new PageImpl<>(List.of(), pageable, 0);
            }
            return transferRepository.searchWithinBranches(
                            companyId, scope, branchId, startDate, endDate, status, type, pageable)
                    .map(this::toDto);
        }
        return transferRepository.search(companyId, branchId, startDate, endDate, status, type, pageable)
                .map(this::toDto);
    }

    public long countPending(UUID branchId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return transferRepository.countPendingByBranch(companyId, branchId);
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
        UUID cbCompanyId = requireBranchCompanyId(transfer.getFromBranch());
        hu.puzzleir.valuta.util.CashLockOrdering.lockBranchCurrencyPairsInGlobalOrder(
                (bid, c) -> cashBalanceRepository
                        .findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(bid, c, cbCompanyId),
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
     * FK-053 front-gate a create útvonalra. Irányonként csak azokat az oldalakat ellenőrzi,
     * ahol a create ténylegesen csökkentené a készletet: F/UF a fromBranch-et, FF mindkét oldalt.
     */
    private void validateVaultCoverageBeforeCreate(Branch fromBranch, Branch toBranch, Currency headerCurrency,
                                                   CreateTransferDto dto, Transfer.TransferDirection direction) {
        boolean fromDecreases = decreasesFromVaultStockOnCreate(direction);
        boolean toDecreases = decreasesToVaultStockOnCreate(direction);
        if (!fromDecreases && !toDecreases) {
            return;
        }

        if (dto.getLines() != null && !dto.getLines().isEmpty()) {
            validateUniqueTransferLineCurrencies(dto);
            for (var lineDto : dto.getLines()) {
                Currency lineCurrency = currencyRepository.findById(lineDto.getCurrencyId())
                        .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található: " + lineDto.getCurrencyId()));
                validateVaultCoverageForDecreasingSides(
                        fromBranch, toBranch, lineCurrency, lineDto.getAmount(), fromDecreases, toDecreases);
            }
            return;
        }

        validateVaultCoverageForDecreasingSides(
                fromBranch, toBranch, headerCurrency, dto.getAmount(), fromDecreases, toDecreases);
    }

    private boolean hasVaultCoverageCheckOnCreate(Transfer.TransferDirection direction) {
        return decreasesFromVaultStockOnCreate(direction) || decreasesToVaultStockOnCreate(direction);
    }

    private boolean decreasesFromVaultStockOnCreate(Transfer.TransferDirection direction) {
        return direction == Transfer.TransferDirection.F
                || direction == Transfer.TransferDirection.UF
                || direction == Transfer.TransferDirection.FF;
    }

    private boolean decreasesToVaultStockOnCreate(Transfer.TransferDirection direction) {
        return direction == Transfer.TransferDirection.FF;
    }

    private void validateUniqueTransferLineCurrencies(CreateTransferDto dto) {
        java.util.Set<Long> seenCurrencies = new java.util.HashSet<>();
        for (var lineDto : dto.getLines()) {
            if (!seenCurrencies.add(lineDto.getCurrencyId())) {
                throw new ValidationException("Egy átadólapon egy valuta csak egyszer szerepelhet! currencyId="
                        + lineDto.getCurrencyId());
            }
        }
    }

    private void validateVaultCoverageForDecreasingSides(Branch fromBranch, Branch toBranch, Currency currency,
                                                         BigDecimal amount, boolean fromDecreases, boolean toDecreases) {
        if (fromDecreases) {
            vaultStockFlowService.validateVaultStockCoverage(fromBranch, currency.getCode(), amount);
        }
        if (toDecreases) {
            vaultStockFlowService.validateVaultStockCoverage(toBranch, currency.getCode(), amount);
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
        UUID cbCompanyId = requireBranchCompanyId(transfer.getFromBranch());
        hu.puzzleir.valuta.util.CashLockOrdering.lockBranchCurrencyPairsInGlobalOrder(
                (bid, c) -> cashBalanceRepository
                        .findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(bid, c, cbCompanyId),
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

    /** Fail-closed cég-feloldás a kassza-műveletekhez (defense-in-depth, #1389 follow-up). */
    private static UUID requireBranchCompanyId(Branch branch) {
        if (branch.getCompany() == null || branch.getCompany().getId() == null) {
            throw new ValidationException(
                    "Hiányzó cégazonosító a kassza-művelethez: " + branch.getCode());
        }
        return branch.getCompany().getId();
    }

    /**
     * Kassza egyenleg csökkentése PESSIMISTIC LOCK-kal.
     */
    private void decreaseCashBalance(Branch branch, Currency currency, BigDecimal amount) {
        UUID companyId = requireBranchCompanyId(branch);
        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(
                branch.getId(), currency.getId(), companyId)
                .orElseThrow(() -> new ValidationException(
                        String.format("Kassza egyenleg nem található: %s / %s",
                                branch.getCode(), currency.getCode())));

        // Negatív kassza védelem
        if (balance.getCurrentBalance().compareTo(amount) < 0) {
            throw new ValidationException(String.format(
                    "Fiók egyenlege nem elegendő! Iroda: %s, valuta: %s, elérhető: %s, szükséges: %s",
                    branch.getCode(), currency.getCode(), balance.getCurrentBalance(), amount));
        }

        // FK-053 mirror-védőháló: minden TransferService-en belüli készlet-csökkentésnél
        // (create, receive jövőbeli bővítés, sztornó-visszafordítás) még a cash_balance mutáció
        // előtt ellenőrizzük a vault currency_stock fedezetet. Nem-vault branch esetén no-op.
        vaultStockFlowService.validateVaultStockCoverage(branch, currency.getCode(), amount);

        balance.updateBalance(amount, false);
        cashBalanceRepository.save(balance);
        log.debug("Kassza csökkentve: {} {} -= {}", branch.getCode(), currency.getCode(), amount);
        // Batch3-B FR-2: vault branch-nel a currency_stock IS csokken — a kozos ponton
        // tukrozve a create (irany-szerinti), a receive es a sztorno-visszafordito agak
        // automatikusan konzisztensek.
        applyVaultStockMirror(branch, currency, amount, false);
    }

    /**
     * Kassza egyenleg növelése PESSIMISTIC LOCK-kal.
     */
    private void increaseCashBalance(Branch branch, Currency currency, BigDecimal amount) {
        UUID companyId = requireBranchCompanyId(branch);
        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(
                branch.getId(), currency.getId(), companyId)
                .orElseThrow(() -> new ValidationException(
                        String.format("Kassza egyenleg nem található: %s / %s",
                                branch.getCode(), currency.getCode())));

        balance.updateBalance(amount, true);
        cashBalanceRepository.save(balance);
        log.debug("Kassza növelve: {} {} += {}", branch.getCode(), currency.getCode(), amount);
        // Batch3-B FR-1: vault branch-nel a currency_stock IS no.
        applyVaultStockMirror(branch, currency, amount, true);
    }

    /**
     * Batch3-B (currency_stock-doc FR-1/FR-2 + 6.b audit): a vault branch-et erinto
     * kassza-mozgas tukrozese a currency_stock-ba (VaultStockFlowService) + kotelezo
     * audit-bejegyzes (action=VAULT_STOCK_UPDATE, TX-KAT minta). Nem-vault branch: no-op.
     */
    private void applyVaultStockMirror(Branch branch, Currency currency, BigDecimal amount, boolean increase) {
        if (!Boolean.TRUE.equals(branch.getIsVault())) {
            return;
        }
        vaultStockFlowService.applyGenericVaultStock(branch, currency.getCode(), amount, increase);
        auditLogService.log("VAULT_STOCK_UPDATE",
                String.format("Értéktári készlet %s: %s%s %s (branch: %s, territory: %s)",
                        increase ? "növelés" : "csökkentés",
                        increase ? "+" : "-", amount, currency.getCode(),
                        branch.getCode(), branch.getVaultTerritoryId()),
                branch.getId().toString());
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

    /** FKH-022 FR-K2: a HUF naplókönyvbe tartozó bizonylatszám (FF-/UF- prefix). */
    private static boolean isHufDaybookNumber(String transferNumber) {
        if (transferNumber == null) {
            return false;
        }
        String upper = transferNumber.toUpperCase();
        return upper.startsWith("FF-") || upper.startsWith("UF-");
    }

    private TransferDto toDto(Transfer t) {
        // Bizonylat-fejléc javítás (2026-06-11): a bejelentkezett értéktár branch-rekordját
        // EGYSZER olvassuk fel, és abból képezzük a címet (FR-1) és a telefonszámot (FR-2).
        Branch vaultBranch = currentVaultBranch();
        return TransferDto.builder()
                .id(t.getId())
                .transferNumber(t.getTransferNumber())
                .fromBranchId(t.getFromBranch().getId().toString())
                .fromBranchCode(t.getFromBranch().getCode())
                .fromBranchName(t.getFromBranch().getName())
                // FR-1 (bizonylat-doc 2. kör, 2026-06-12): az értéktár-azonosító
                // ("[region_code]. [név]" fejléc-formátumhoz) a kliens-oldali
                // label-összeállításhoz — mindkét oldalra, a visszanézett (szem-ikon)
                // bizonylat is tudjon region-formátumot képezni.
                .fromBranchRegionCode(t.getFromBranch().getRegionCode())
                .toBranchId(t.getToBranch().getId().toString())
                .toBranchCode(t.getToBranch().getCode())
                .toBranchName(t.getToBranch().getName())
                .toBranchRegionCode(t.getToBranch().getRegionCode())
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
                .vaultAddress(vaultBranch != null ? formatBranchAddress(vaultBranch) : null)
                .vaultPhone(vaultBranch != null ? normalizedPhone(vaultBranch.getPhone()) : null)
                .isCancelled(Boolean.TRUE.equals(t.getIsCancelled()))
                .cancellationReason(t.getCancellationReason())
                .cancelledAt(t.getCancelledAt() != null ? t.getCancelledAt().toString() : null)
                .stornoSerialNumber(Boolean.TRUE.equals(t.getIsCancelled()) ? t.getTransferNumber() + "-SZ" : null)
                .denominations(mapDenominations(t))
                .build();
    }

    /**
     * FR-1/FR-2: a bejelentkezett értéktár (Branch) rekordja a bizonylat fejlécéhez — a cím
     * "Város, Cím, IRSZ" (pl. "Szeged, Hajnóczy u. 57., 6722") és a telefonszám forrása.
     * A céget+adószámot a frontend tartja; itt CSAK a branch-adat dinamikus, a JWT branchId-ból.
     * A branchRepository.findById az aktuális tranzakción belül L1-cache-elt (azonos branchId →
     * 1 query lista-renderelésnél is).
     */
    private Branch currentVaultBranch() {
        // OrNull: SecurityContext nélküli hívás (teszt/scheduler) ne dobjon — ekkor nincs fejléc-adat.
        UUID branchId = SecurityUtils.getCurrentBranchIdOrNull();
        if (branchId == null) {
            return null;
        }
        return branchRepository.findById(branchId).orElse(null);
    }

    private String formatBranchAddress(Branch b) {
        java.util.List<String> parts = new java.util.ArrayList<>();
        if (b.getCity() != null && !b.getCity().isBlank()) parts.add(b.getCity().trim());
        if (b.getAddress() != null && !b.getAddress().isBlank()) parts.add(b.getAddress().trim());
        if (b.getZipCode() != null && !b.getZipCode().isBlank()) parts.add(b.getZipCode().trim());
        return parts.isEmpty() ? null : String.join(", ", parts);
    }

    /** TBD-3: NULL/üres {@code branch.phone} → NULL, így a bizonylaton nem jelenik meg telefon sor. */
    private String normalizedPhone(String phone) {
        return (phone == null || phone.isBlank()) ? null : phone.trim();
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

    /** A 4 technikai gyűjtő RB-kötés-kód (ERB/FRB/TRB/PRB, c4 P3#5). */
    private static boolean isTechnicalRb(Transfer.TransferType type) {
        return type == Transfer.TransferType.ERB || type == Transfer.TransferType.FRB
                || type == Transfer.TransferType.TRB || type == Transfer.TransferType.PRB;
    }

    /**
     * Technikai RB-kötés valuta-invariáns (fejléc-valutára ÉS minden multi-line sorra):
     * FRB/PRB → kizárólag HUF, ERB/TRB → kizárólag deviza. Más típusra no-op.
     */
    private void validateTechnicalRbCurrency(Transfer.TransferType type, Currency currency) {
        boolean huf = "HUF".equalsIgnoreCase(currency.getCode());
        if ((type == Transfer.TransferType.FRB || type == Transfer.TransferType.PRB) && !huf) {
            throw new ValidationException(type + " kötés csak HUF valutával rögzíthető!");
        }
        if ((type == Transfer.TransferType.ERB || type == Transfer.TransferType.TRB) && huf) {
            throw new ValidationException(type + " kötés csak devizával (nem HUF) rögzíthető!");
        }
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
            case ERB -> "Fixing valuta mozgás RB (ERB)";
            case FRB -> "Forint mozgás RB (FRB)";
            case TRB -> "Egyedi kötés RB (TRB)";
            case PRB -> "POS átvétel banktól (PRB)";
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
