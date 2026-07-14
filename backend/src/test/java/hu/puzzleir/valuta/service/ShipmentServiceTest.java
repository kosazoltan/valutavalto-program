package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.shipment.ShipmentRequestResponseDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestItem;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.repository.ShipmentRequestRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ShipmentServiceTest {

    @Mock
    private ShipmentRequestRepository repository;

    @Mock
    private hu.puzzleir.valuta.repository.BranchRepository branchRepository;

    @Mock
    private hu.puzzleir.valuta.repository.CurrencyRepository currencyRepository;

    @Mock
    private WorkerRepository workerRepository;

    @Mock
    private ExchangeRateService exchangeRateService;

    @Mock
    private TransferSerialSequenceService transferSerialSequenceService;

    @Mock
    private ShipmentStockBookingService stockBookingService;

    @Mock
    private ShipmentHandlingFeeSyncService handlingFeeSyncService;

    @Mock
    private AuditLogService auditLogService;

    @Mock
    private CashBalanceRepository cashBalanceRepository;

    @Mock
    private CurrencyStockRepository currencyStockRepository;

    @InjectMocks
    private ShipmentService service;

    /**
     * A create() happy-path (FR-1) most már a from/to fiókot betölti a könyvelési irány
     * (transfer_type) szerveroldali derivációjához. A validRequest() random branch-eit
     * lenient stubbal elégítjük ki — pénztár-pénztár (BRANCH_TO_BRANCH) az alapeset.
     */
    private void stubBranchLookupsForCreate() {
        lenient().when(branchRepository.findByIdAndCompanyId(any(UUID.class), any(UUID.class)))
                .thenAnswer(inv -> java.util.Optional.of(
                        Branch.builder().id(inv.getArgument(0)).isVault(false).build()));
        lenient().when(stockBookingService.deriveTransferType(any(), any()))
                .thenReturn(ShipmentStockBookingService.TRANSFER_BRANCH_TO_BRANCH);
    }

    @Test
    void createSetsDraftMetadataForValidRequest() {
        stubBranchLookupsForCreate();
        when(currencyRepository.findById(4L)).thenReturn(java.util.Optional.of(currency("EUR")));
        when(transferSerialSequenceService.next(any(), eq("AT"))).thenReturn(1L);
        when(repository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        // D Codex P1: az autofill ValidationException-t dob, ha nincs rate — minden
        // happy-path tesztben mock-olni kell az aktuális elszámoló árfolyamot.
        when(exchangeRateService.getCurrentRate(4L)).thenReturn(
                ExchangeRate.builder().officialRate(new BigDecimal("400")).build());

        UUID companyId = UUID.randomUUID();
        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            security.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(UUID.randomUUID());
            security.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            ShipmentRequest saved = service.create(validRequest());

            assertThat(saved.getRequestNumber()).isEqualTo("AT-000001");
            assertThat(saved.getCompanyId()).isEqualTo(companyId);
            assertThat(saved.getSerialPrefix()).isEqualTo("AT");
            assertThat(saved.getSerialNumber()).isEqualTo(1L);
            assertThat(saved.getRequestedById()).isEqualTo(42L);
            assertThat(saved.getStatus().name()).isEqualTo("DRAFT");
        }
    }

    @Test
    void createResponseEnrichesBranchAndWorkerNames() {
        UUID companyId = UUID.randomUUID();
        UUID fromBranchId = UUID.randomUUID();
        UUID toBranchId = UUID.randomUUID();
        Company company = Company.builder().id(companyId).build();
        Branch fromBranch = Branch.builder()
                .id(fromBranchId)
                .company(company)
                .code("BR075")
                .name("Szeged Értéktár")
                .build();
        Branch toBranch = Branch.builder()
                .id(toBranchId)
                .company(company)
                .code("BR027")
                .name("Szeged Tesco")
                .build();
        Worker worker = Worker.builder()
                .id(42L)
                .company(company)
                .branch(fromBranch)
                .name("Bali Henriett")
                .build();

        when(currencyRepository.findById(4L)).thenReturn(java.util.Optional.of(currency("EUR")));
        when(transferSerialSequenceService.next(any(), eq("AT"))).thenReturn(1L);
        when(repository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(exchangeRateService.getCurrentRate(4L)).thenReturn(
                ExchangeRate.builder().officialRate(new BigDecimal("400")).build());
        when(branchRepository.findByIdAndCompanyId(fromBranchId, companyId))
                .thenReturn(java.util.Optional.of(fromBranch));
        when(branchRepository.findByIdAndCompanyId(toBranchId, companyId))
                .thenReturn(java.util.Optional.of(toBranch));
        when(workerRepository.findByIdAndCompanyId(42L, companyId))
                .thenReturn(java.util.Optional.of(worker));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            security.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(UUID.randomUUID());
            security.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            ShipmentRequest request = validRequest();
            request.setFromBranchId(fromBranchId);
            request.setToBranchId(toBranchId);

            ShipmentRequestResponseDto response = service.createResponse(request);

            assertThat(response.getFromBranchCode()).isEqualTo("BR075");
            assertThat(response.getFromBranchName()).isEqualTo("Szeged Értéktár");
            assertThat(response.getToBranchCode()).isEqualTo("BR027");
            assertThat(response.getToBranchName()).isEqualTo("Szeged Tesco");
            assertThat(response.getRequestedByWorkerName()).isEqualTo("Bali Henriett");
            assertThat(response.getRequestingBranchName()).isEqualTo("Szeged Értéktár");
            assertThat(response.getTargetBranchName()).isEqualTo("Szeged Tesco");
        }
    }

    @Test
    void createRejectsSameSourceAndTargetBranch() {
        ShipmentRequest request = validRequest();
        request.setToBranchId(request.getFromBranchId());

        assertThatThrownBy(() -> service.create(request))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("nem lehet ugyanaz");
        verifyNoInteractions(repository);
    }

    @Test
    void createRejectsMissingItems() {
        ShipmentRequest request = validRequest();
        request.setItems(List.of());

        assertThatThrownBy(() -> service.create(request))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Legalább egy");
        verifyNoInteractions(repository);
    }

    @Test
    void createAutoFillsAppliedRateAndHufValueFromCurrentRate() {
        // D self-review P1-4: happy-path — ha van aktuális officialRate, az appliedRate
        // + hufValue automatikusan kitöltődik a service-ben (1250 EUR × 400 = 500 000 Ft).
        stubBranchLookupsForCreate();
        when(currencyRepository.findById(4L)).thenReturn(java.util.Optional.of(currency("EUR")));
        when(transferSerialSequenceService.next(any(), eq("AT"))).thenReturn(1L);
        when(repository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(exchangeRateService.getCurrentRate(4L)).thenReturn(
                ExchangeRate.builder().officialRate(new BigDecimal("400")).build());

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(UUID.randomUUID());
            security.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(UUID.randomUUID());
            security.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            ShipmentRequest req = validRequest();
            req.getItems().getFirst().setRequestedAmount(new BigDecimal("1250"));
            ShipmentRequest saved = service.create(req);

            ShipmentRequestItem item = saved.getItems().getFirst();
            assertThat(item.getAppliedRate()).isEqualByComparingTo("400");
            assertThat(item.getHufValue()).isEqualByComparingTo("500000");
        }
    }

    @Test
    void createRejectsWhenCurrentRateIsMissing() {
        // D Codex P1 (overrides earlier P0-1 tolerance): a D pont szövege „kötelezően és
        // automatikusan a rendszerben lévő aktuális elszámoló árból" — ha nincs aktív
        // rate, a service NE perzisztáljon NULL rate-tel; explicit ValidationException-t
        // dob, a kliens értesül a kötelező árfolyam-frissítésről.
        when(currencyRepository.findById(4L)).thenReturn(java.util.Optional.of(currency("EUR")));
        when(transferSerialSequenceService.next(any(), eq("AT"))).thenReturn(1L);
        when(exchangeRateService.getCurrentRate(4L))
                .thenThrow(new ResourceNotFoundException("Nincs aktuális árfolyam"));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(UUID.randomUUID());
            security.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(UUID.randomUUID());
            security.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            assertThatThrownBy(() -> service.create(validRequest()))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("nincs aktuális");
            verify(repository, never()).save(any());
        }
    }

    @Test
    void createOverwritesClientProvidedAppliedRateWithServerSide() {
        // D self-review + Codex P1: a D követelmény szövege „kötelezően és automatikusan
        // a rendszerben lévő aktuális elszámoló árból" — a kliens által küldött appliedRate
        // / hufValue mezőket figyelmen kívül hagyjuk, MINDIG a server-side rate az
        // authoritative. A kliens 999-et próbál küldeni, de a 400 official rate győz.
        stubBranchLookupsForCreate();
        when(currencyRepository.findById(4L)).thenReturn(java.util.Optional.of(currency("EUR")));
        when(transferSerialSequenceService.next(any(), eq("AT"))).thenReturn(1L);
        when(repository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(exchangeRateService.getCurrentRate(4L)).thenReturn(
                ExchangeRate.builder().officialRate(new BigDecimal("400")).build());

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(UUID.randomUUID());
            security.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(UUID.randomUUID());
            security.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            ShipmentRequest req = validRequest();
            req.getItems().getFirst().setAppliedRate(new BigDecimal("999")); // manipulált kliens-érték
            req.getItems().getFirst().setHufValue(new BigDecimal("123456"));  // manipulált kliens-érték
            ShipmentRequest saved = service.create(req);

            ShipmentRequestItem item = saved.getItems().getFirst();
            assertThat(item.getAppliedRate()).isEqualByComparingTo("400");      // server-side
            assertThat(item.getHufValue()).isEqualByComparingTo("400000");      // 1000 × 400
        }
    }

    @Test
    void createRejectsNonPositiveAmount() {
        ShipmentRequest request = validRequest();
        request.getItems().getFirst().setRequestedAmount(BigDecimal.ZERO);

        assertThatThrownBy(() -> service.create(request))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("pozitív összeg");
        verifyNoInteractions(repository);
    }

    @Test
    void createHufUsesRateOneAndUfPrefixForInbound() {
        UUID ownBranchId = UUID.randomUUID();
        UUID fromBranchId = UUID.randomUUID();
        ShipmentRequest request = ShipmentRequest.builder()
                .fromBranchId(fromBranchId)
                .toBranchId(ownBranchId)
                .deliveryDate(LocalDate.now().plusDays(1))
                .items(new ArrayList<>(List.of(ShipmentRequestItem.builder()
                        .currencyId(6L)
                        .requestedAmount(new BigDecimal("1000000"))
                        .build())))
                .build();

        when(currencyRepository.findById(6L)).thenReturn(java.util.Optional.of(currency("HUF")));
        when(transferSerialSequenceService.next(any(), eq("UF"))).thenReturn(23L);
        when(repository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        lenient().when(branchRepository.findByIdAndCompanyId(any(UUID.class), any(UUID.class)))
                .thenAnswer(inv -> java.util.Optional.of(
                        Branch.builder().id(inv.getArgument(0)).isVault(false).build()));
        lenient().when(stockBookingService.deriveTransferType(any(), any()))
                .thenReturn(ShipmentStockBookingService.TRANSFER_BRANCH_TO_BRANCH);

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(UUID.randomUUID());
            security.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(ownBranchId);
            security.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);

            ShipmentRequest saved = service.create(request);

            assertThat(saved.getRequestNumber()).isEqualTo("UF-000023");
            assertThat(saved.getItems().getFirst().getAppliedRate()).isEqualByComparingTo("1");
            assertThat(saved.getItems().getFirst().getHufValue()).isEqualByComparingTo("1000000");
        }

        verify(exchangeRateService, never()).getCurrentRate(6L);
    }

    @Test
    void reject_setsRejectedStatusAndAuditFields() {
        // F3 (2026-06-01): dedikált elutasítás — REJECTED státusz + audit-mezők; a workerId a
        // hitelesített userből (nem kliens-trusted).
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        ShipmentRequest sr = rejectableShipment(shipmentId, companyId);
        when(repository.findByIdForUpdate(shipmentId)).thenReturn(java.util.Optional.of(sr));
        when(repository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            security.when(SecurityUtils::getCurrentWorkerId).thenReturn(77L);
            ShipmentRequest result = service.reject(shipmentId, "Hibás összeg");

            assertThat(result.getStatus()).isEqualTo(hu.puzzleir.valuta.entity.ShipmentRequestStatus.REJECTED);
            assertThat(result.getRejectionReason()).isEqualTo("Hibás összeg");
            assertThat(result.getRejectedByWorkerId()).isEqualTo(77L);
        }
    }

    @Test
    void reject_onlyAllowedFromSubmitted() {
        // Codex P2: az elutasítás CSAK SUBMITTED-ből megengedett (az approve párja). Egy már
        // APPROVED kérés közvetlen API-hívással NEM érvényteleníthető.
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        ShipmentRequest sr = rejectableShipment(shipmentId, companyId);
        sr.setStatus(hu.puzzleir.valuta.entity.ShipmentRequestStatus.APPROVED);
        when(repository.findByIdForUpdate(shipmentId)).thenReturn(java.util.Optional.of(sr));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            assertThatThrownBy(() -> service.reject(shipmentId, "kesoi"))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("SUBMITTED");
            verify(repository, never()).save(any());
        }
    }

    /** SUBMITTED státuszú, tenant-konzisztens (from+to branch a companyId-hez) shipment a reject-teszthez. */
    private ShipmentRequest rejectableShipment(UUID shipmentId, UUID companyId) {
        UUID fromBranch = UUID.randomUUID();
        UUID toBranch = UUID.randomUUID();
        hu.puzzleir.valuta.entity.Company company =
                hu.puzzleir.valuta.entity.Company.builder().id(companyId).build();
        hu.puzzleir.valuta.entity.Branch from =
                hu.puzzleir.valuta.entity.Branch.builder().id(fromBranch).company(company).build();
        hu.puzzleir.valuta.entity.Branch to =
                hu.puzzleir.valuta.entity.Branch.builder().id(toBranch).company(company).build();
        when(branchRepository.findById(fromBranch)).thenReturn(java.util.Optional.of(from));
        when(branchRepository.findById(toBranch)).thenReturn(java.util.Optional.of(to));
        return ShipmentRequest.builder()
                .id(shipmentId)
                .fromBranchId(fromBranch)
                .toBranchId(toBranch)
                .status(hu.puzzleir.valuta.entity.ShipmentRequestStatus.SUBMITTED)
                .items(new ArrayList<>())
                .build();
    }

    @Test
    void findAll_withBranchId_usesNativeBranchFilter() {
        // F2 (2026-06-01): branchId megadva → a natív, DB-szintű findByBranchAndCompanyId fut
        // (NEM a teljes lista + kliens-szűrés). Tenant-scope: companyId.
        UUID companyId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        when(repository.findByBranchAndCompanyId(
                org.mockito.ArgumentMatchers.eq(branchId),
                org.mockito.ArgumentMatchers.isNull(),
                org.mockito.ArgumentMatchers.eq(companyId),
                any())).thenReturn(org.springframework.data.domain.Page.empty());

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            service.findAll(null, branchId, org.springframework.data.domain.PageRequest.of(0, 20));
        }

        verify(repository).findByBranchAndCompanyId(
                org.mockito.ArgumentMatchers.eq(branchId),
                org.mockito.ArgumentMatchers.isNull(),
                org.mockito.ArgumentMatchers.eq(companyId),
                any());
        verify(repository, never()).findAllOrderedByCompanyId(any(), any());
    }

    @Test
    void findAll_withoutBranchId_usesCompanyScopedListing() {
        // branchId == null → a meglévő cég-szintű listázás (visszafelé kompatibilis).
        UUID companyId = UUID.randomUUID();
        when(repository.findAllOrderedByCompanyId(org.mockito.ArgumentMatchers.eq(companyId), any()))
                .thenReturn(org.springframework.data.domain.Page.empty());

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            service.findAll(null, null, org.springframework.data.domain.PageRequest.of(0, 20));
        }

        verify(repository).findAllOrderedByCompanyId(org.mockito.ArgumentMatchers.eq(companyId), any());
        verify(repository, never()).findByBranchAndCompanyId(any(), any(), any(), any());
    }

    // ===================== FK orkesztráció: a ShipmentService a könyvelő-motort delegálja =====================

    @Test
    void submit_delegatesStockOutThenSetsSubmitted() {
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        ShipmentRequest sr = bookedShipment(shipmentId, companyId,
                hu.puzzleir.valuta.entity.ShipmentRequestStatus.DRAFT);
        when(repository.findByIdForUpdate(shipmentId)).thenReturn(java.util.Optional.of(sr));
        when(repository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            ShipmentRequest result = service.submit(shipmentId);

            assertThat(result.getStatus())
                    .isEqualTo(hu.puzzleir.valuta.entity.ShipmentRequestStatus.SUBMITTED);
        }
        // FR-2: a beküldés OUT-könyvel az átadón, a státuszváltás ELŐTT (elégtelen → 422 rollback).
        verify(stockBookingService).bookStockOut(eq(sr), eq(companyId));
        verify(stockBookingService, never()).bookStockIn(any(), any());
    }

    @Test
    void deliver_enforcesReceiverGateThenBooksStockIn() {
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        ShipmentRequest sr = bookedShipment(shipmentId, companyId,
                hu.puzzleir.valuta.entity.ShipmentRequestStatus.APPROVED);
        when(repository.findByIdForUpdate(shipmentId)).thenReturn(java.util.Optional.of(sr));
        when(repository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            ShipmentRequest result = service.deliver(shipmentId);

            assertThat(result.getStatus())
                    .isEqualTo(hu.puzzleir.valuta.entity.ShipmentRequestStatus.DELIVERED);
        }
        // FR-4: az átvevő-gate a könyvelés ELŐTT fut; FR-3: utána IN-könyvel az átvevőn.
        org.mockito.InOrder order = inOrder(stockBookingService);
        order.verify(stockBookingService).assertReceiver(sr);
        order.verify(stockBookingService).bookStockIn(eq(sr), eq(companyId));
    }

    @Test
    void deliver_whenReceiverGateDenies_propagates403AndSkipsStockIn() {
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        ShipmentRequest sr = bookedShipment(shipmentId, companyId,
                hu.puzzleir.valuta.entity.ShipmentRequestStatus.APPROVED);
        when(repository.findByIdForUpdate(shipmentId)).thenReturn(java.util.Optional.of(sr));
        doThrow(new org.springframework.security.access.AccessDeniedException("VV-AUTH-001"))
                .when(stockBookingService).assertReceiver(sr);

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            assertThatThrownBy(() -> service.deliver(shipmentId))
                    .isInstanceOf(org.springframework.security.access.AccessDeniedException.class)
                    .hasMessageContaining("VV-AUTH-001");
        }
        // a gate bukása után NINCS IN-könyvelés és NINCS státuszváltás (save).
        verify(stockBookingService, never()).bookStockIn(any(), any());
        verify(repository, never()).save(any());
    }

    @Test
    void approve_deniedWhenCallerNotFromBranch() {
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        ShipmentRequest sr = bookedShipment(shipmentId, companyId,
                hu.puzzleir.valuta.entity.ShipmentRequestStatus.SUBMITTED);
        UUID attemptBranch = UUID.randomUUID();
        when(repository.findById(shipmentId)).thenReturn(java.util.Optional.of(sr));
        ShipmentService serviceWithRealRequesterGate = serviceWithRealStockBookingService();

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            security.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(attemptBranch);
            security.when(SecurityUtils::getCurrentWorkerId).thenReturn(77L);

            assertThatThrownBy(() -> serviceWithRealRequesterGate.approve(shipmentId))
                    .isInstanceOf(org.springframework.security.access.AccessDeniedException.class)
                    .hasMessageContaining("VV-AUTH-002");
        }

        assertThat(sr.getStatus()).isEqualTo(hu.puzzleir.valuta.entity.ShipmentRequestStatus.SUBMITTED);
        verify(auditLogService).logInNewTransaction(
                org.mockito.ArgumentMatchers.eq(ShipmentStockBookingService.ACTION_ACCESS_DENIED),
                org.mockito.ArgumentMatchers.eq("ShipmentRequest"),
                org.mockito.ArgumentMatchers.eq(shipmentId.toString()),
                org.mockito.ArgumentMatchers.eq("77"),
                org.mockito.ArgumentMatchers.isNull(),
                org.mockito.ArgumentMatchers.eq(attemptBranch.toString()),
                org.mockito.ArgumentMatchers.isNull(),
                org.mockito.ArgumentMatchers.argThat(changes -> changes != null
                        && changes.contains("\"KAT\":\"AUTH\"")
                        && changes.contains("\"error_code\":\"" + ShipmentStockBookingService.ERR_NOT_REQUESTER + "\"")
                        && changes.contains("\"from_branch_id\":\"" + sr.getFromBranchId() + "\"")
                        && changes.contains("\"attempt_branch_id\":\"" + attemptBranch + "\"")));
        verifyNoInteractions(stockBookingService);
        verify(repository, never()).save(any());
    }

    @Test
    void approve_allowedWhenCallerIsFromBranch() {
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        ShipmentRequest sr = bookedShipment(shipmentId, companyId,
                hu.puzzleir.valuta.entity.ShipmentRequestStatus.SUBMITTED);
        when(repository.findById(shipmentId)).thenReturn(java.util.Optional.of(sr));
        when(repository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            security.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(sr.getFromBranchId());

            ShipmentRequest result = service.approve(shipmentId);

            assertThat(result.getStatus())
                    .isEqualTo(hu.puzzleir.valuta.entity.ShipmentRequestStatus.APPROVED);
        }

        org.mockito.InOrder order = inOrder(stockBookingService, repository);
        order.verify(stockBookingService).assertRequester(sr);
        order.verify(repository).save(sr);
    }

    @Test
    void approve_deniedWhenNoBranchInToken() {
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        long workerId = 77L;
        ShipmentRequest sr = bookedShipment(shipmentId, companyId,
                hu.puzzleir.valuta.entity.ShipmentRequestStatus.SUBMITTED);
        when(repository.findById(shipmentId)).thenReturn(java.util.Optional.of(sr));
        ShipmentService serviceWithRealRequesterGate = serviceWithRealStockBookingService();

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            security.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(null);
            security.when(SecurityUtils::getCurrentWorkerId).thenReturn(workerId);

            assertThatThrownBy(() -> serviceWithRealRequesterGate.approve(shipmentId))
                    .isInstanceOf(org.springframework.security.access.AccessDeniedException.class)
                    .hasMessageContaining("VV-AUTH-002");
        }

        assertThat(sr.getStatus()).isEqualTo(hu.puzzleir.valuta.entity.ShipmentRequestStatus.SUBMITTED);
        verify(auditLogService).logInNewTransaction(
                org.mockito.ArgumentMatchers.eq(ShipmentStockBookingService.ACTION_ACCESS_DENIED),
                org.mockito.ArgumentMatchers.eq("ShipmentRequest"),
                org.mockito.ArgumentMatchers.eq(shipmentId.toString()),
                org.mockito.ArgumentMatchers.eq(String.valueOf(workerId)),
                org.mockito.ArgumentMatchers.isNull(),
                org.mockito.ArgumentMatchers.isNull(),
                org.mockito.ArgumentMatchers.isNull(),
                org.mockito.ArgumentMatchers.argThat(changes -> changes != null
                        && changes.contains("\"KAT\":\"AUTH\"")
                        && changes.contains("\"error_code\":\"" + ShipmentStockBookingService.ERR_NOT_REQUESTER + "\"")
                        && changes.contains("\"from_branch_id\":\"" + sr.getFromBranchId() + "\"")
                        && changes.contains("\"attempt_branch_id\":\"null\"")));
        verifyNoInteractions(stockBookingService);
        verify(repository, never()).save(any());
    }

    @Test
    void toResponseDto_itemsIncludeCurrencyCode() {
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        UUID fromBranchId = UUID.randomUUID();
        UUID toBranchId = UUID.randomUUID();
        Company company = Company.builder().id(companyId).build();
        Branch from = Branch.builder().id(fromBranchId).company(company).build();
        Branch to = Branch.builder().id(toBranchId).company(company).build();
        ShipmentRequest request = ShipmentRequest.builder()
                .id(shipmentId)
                .companyId(companyId)
                .fromBranchId(fromBranchId)
                .toBranchId(toBranchId)
                .status(hu.puzzleir.valuta.entity.ShipmentRequestStatus.SUBMITTED)
                .items(new ArrayList<>(List.of(
                        ShipmentRequestItem.builder()
                                .currencyId(4L)
                                .requestedAmount(new BigDecimal("100"))
                                .build(),
                        ShipmentRequestItem.builder()
                                .currencyId(999L)
                                .requestedAmount(new BigDecimal("200"))
                                .build(),
                        ShipmentRequestItem.builder()
                                .currencyId(null)
                                .requestedAmount(new BigDecimal("300"))
                                .build())))
                .build();
        when(branchRepository.findByIdAndCompanyId(fromBranchId, companyId)).thenReturn(java.util.Optional.of(from));
        when(branchRepository.findByIdAndCompanyId(toBranchId, companyId)).thenReturn(java.util.Optional.of(to));
        when(currencyRepository.findAllById(org.mockito.ArgumentMatchers.anyIterable()))
                .thenReturn(List.of(currency("EUR")));

        ShipmentRequestResponseDto response = service.toResponseDto(request);

        assertThat(response.getItems()).hasSize(3);
        assertThat(response.getItems().get(0).getCurrencyCode()).isEqualTo("EUR");
        assertThat(response.getItems().get(1).getCurrencyCode()).isNull();
        assertThat(response.getItems().get(2).getCurrencyCode()).isNull();
        verify(currencyRepository).findAllById(org.mockito.ArgumentMatchers.argThat(ids -> {
            List<Long> collected = new ArrayList<>();
            ids.forEach(collected::add);
            return collected.containsAll(List.of(4L, 999L)) && collected.size() == 2;
        }));
    }

    private ShipmentService serviceWithRealStockBookingService() {
        ShipmentStockBookingService realStockBookingService = new ShipmentStockBookingService(
                branchRepository,
                cashBalanceRepository,
                currencyStockRepository,
                currencyRepository,
                auditLogService);
        return new ShipmentService(
                repository,
                branchRepository,
                currencyRepository,
                workerRepository,
                exchangeRateService,
                transferSerialSequenceService,
                realStockBookingService,
                handlingFeeSyncService);
    }

    @Test
    void cancel_fromSubmitted_reversesStockOut() {
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        ShipmentRequest sr = bookedShipment(shipmentId, companyId,
                hu.puzzleir.valuta.entity.ShipmentRequestStatus.SUBMITTED);
        when(repository.findByIdForUpdate(shipmentId)).thenReturn(java.util.Optional.of(sr));
        when(repository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            ShipmentRequest result = service.cancel(shipmentId);

            assertThat(result.getStatus())
                    .isEqualTo(hu.puzzleir.valuta.entity.ShipmentRequestStatus.CANCELLED);
        }
        // TBD-1: OUT-könyvelt (SUBMITTED) állapotból visszavonva a készletet vissza kell pótolni.
        verify(stockBookingService).reverseStockOut(eq(sr), eq(companyId));
    }

    @Test
    void cancel_fromDraft_doesNotReverseStock() {
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        ShipmentRequest sr = bookedShipment(shipmentId, companyId,
                hu.puzzleir.valuta.entity.ShipmentRequestStatus.DRAFT);
        when(repository.findByIdForUpdate(shipmentId)).thenReturn(java.util.Optional.of(sr));
        when(repository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            ShipmentRequest result = service.cancel(shipmentId);

            assertThat(result.getStatus())
                    .isEqualTo(hu.puzzleir.valuta.entity.ShipmentRequestStatus.CANCELLED);
        }
        // DRAFT-ból NEM volt OUT-könyvelés → NINCS reverzió (dupla-jóváírás elkerülése).
        verify(stockBookingService, never()).reverseStockOut(any(), any());
    }

    @Test
    void reject_reversesStockOutFromSubmitted() {
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        ShipmentRequest sr = bookedShipment(shipmentId, companyId,
                hu.puzzleir.valuta.entity.ShipmentRequestStatus.SUBMITTED);
        when(repository.findByIdForUpdate(shipmentId)).thenReturn(java.util.Optional.of(sr));
        when(repository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            security.when(SecurityUtils::getCurrentWorkerId).thenReturn(77L);
            service.reject(shipmentId, "Hibás összeg");
        }
        // TBD-1: a reject CSAK SUBMITTED-ből → mindig OUT-könyvelt → mindig reverzió.
        verify(stockBookingService).reverseStockOut(eq(sr), eq(companyId));
    }

    // ===================== P1 (Codex): transition-ek pesszimista sor-lockkal töltenek =====================

    @Test
    void submit_loadsShipmentWithPessimisticLock_notPlainFindById() {
        // P1: a státuszváltás a @Lock(PESSIMISTIC_WRITE) findByIdForUpdate-et használja (nem a sima
        // findById-t) — így két párhuzamos /submit szerializálódik és nincs kétszeres készlet-levonás.
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        ShipmentRequest sr = bookedShipment(shipmentId, companyId,
                hu.puzzleir.valuta.entity.ShipmentRequestStatus.DRAFT);
        when(repository.findByIdForUpdate(shipmentId)).thenReturn(java.util.Optional.of(sr));
        when(repository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            service.submit(shipmentId);
        }
        verify(repository).findByIdForUpdate(shipmentId);
        verify(repository, never()).findById(shipmentId);
    }

    // ===================== P2 (Codex): update újra-derivál transfer_type-ot =====================

    @Test
    void update_recomputesTransferTypeAfterBranchEdit() {
        // P2: a DRAFT szerkesztés felülírja a from/to fiókot → a transfer_type-ot ÚJRA kell deriválni,
        // különben a tárolt/auditált irány a régi maradna. A from most VAULT, to CASHIER → VAULT_TO_BRANCH.
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        UUID fromBranch = UUID.randomUUID();
        UUID toBranch = UUID.randomUUID();
        Company company = Company.builder().id(companyId).build();
        Branch fromVault = Branch.builder().id(fromBranch).company(company).isVault(true).build();
        Branch toCashier = Branch.builder().id(toBranch).company(company).isVault(false).build();
        ShipmentRequest existing = ShipmentRequest.builder()
                .id(shipmentId).requestNumber("AT-000200")
                .fromBranchId(fromBranch).toBranchId(toBranch)
                .status(hu.puzzleir.valuta.entity.ShipmentRequestStatus.DRAFT)
                .transferType("BRANCH_TO_BRANCH") // régi, elavult irány
                .items(new ArrayList<>(List.of(ShipmentRequestItem.builder()
                        .currencyId(4L)
                        .requestedAmount(new BigDecimal("100"))
                        .build())))
                .build();
        // branch-edit update valid (HUF) tétellel: a HUF-ág appliedRate=ONE-t állít, nincs
        // exchangeRateService-hívás → a teszt a P2-derivációra fókuszál, törékeny rate-stub nélkül.
        ShipmentRequest updated = ShipmentRequest.builder()
                .fromBranchId(fromBranch).toBranchId(toBranch)
                .items(new ArrayList<>(List.of(ShipmentRequestItem.builder()
                        .currencyId(6L)
                        .requestedAmount(new BigDecimal("100"))
                        .build())))
                .build();

        when(repository.findById(shipmentId)).thenReturn(java.util.Optional.of(existing));
        when(currencyRepository.findById(6L)).thenReturn(java.util.Optional.of(currency("HUF")));
        // findById guard: branchRepository.findById a tenant-ellenőrzéshez
        when(branchRepository.findById(fromBranch)).thenReturn(java.util.Optional.of(fromVault));
        when(branchRepository.findById(toBranch)).thenReturn(java.util.Optional.of(toCashier));
        // P2 deriváció: tenant-ellenőrzött findByIdAndCompanyId + deriveTransferType
        when(branchRepository.findByIdAndCompanyId(fromBranch, companyId)).thenReturn(java.util.Optional.of(fromVault));
        when(branchRepository.findByIdAndCompanyId(toBranch, companyId)).thenReturn(java.util.Optional.of(toCashier));
        when(stockBookingService.deriveTransferType(fromVault, toCashier))
                .thenReturn(ShipmentStockBookingService.TRANSFER_VAULT_TO_BRANCH);
        when(repository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            ShipmentRequest result = service.update(shipmentId, updated);
            assertThat(result.getTransferType())
                    .isEqualTo(ShipmentStockBookingService.TRANSFER_VAULT_TO_BRANCH);
        }
        verify(stockBookingService).deriveTransferType(fromVault, toCashier);
    }

    /**
     * Tenant-konzisztens (from+to branch a companyId-hez) shipment adott státuszban, az
     * orkesztráció-tesztekhez. A {@link ShipmentService#findById} guard-ja a branchRepository.findById-t
     * használja a cross-tenant ellenőrzéshez — itt mindkét branch a companyId-hez tartozik.
     */
    private ShipmentRequest bookedShipment(UUID shipmentId, UUID companyId,
                                           hu.puzzleir.valuta.entity.ShipmentRequestStatus status) {
        UUID fromBranch = UUID.randomUUID();
        UUID toBranch = UUID.randomUUID();
        Company company = Company.builder().id(companyId).build();
        Branch from = Branch.builder().id(fromBranch).company(company).build();
        Branch to = Branch.builder().id(toBranch).company(company).build();
        when(branchRepository.findById(fromBranch)).thenReturn(java.util.Optional.of(from));
        when(branchRepository.findById(toBranch)).thenReturn(java.util.Optional.of(to));
        return ShipmentRequest.builder()
                .id(shipmentId)
                .requestNumber("AT-000123")
                .fromBranchId(fromBranch)
                .toBranchId(toBranch)
                .status(status)
                .items(new ArrayList<>(List.of(ShipmentRequestItem.builder()
                        .currencyId(4L)
                        .requestedAmount(new BigDecimal("300"))
                        .build())))
                .build();
    }

    private static ShipmentRequest validRequest() {
        return ShipmentRequest.builder()
                .fromBranchId(UUID.randomUUID())
                .toBranchId(UUID.randomUUID())
                .deliveryDate(LocalDate.now().plusDays(1))
                .items(new ArrayList<>(List.of(ShipmentRequestItem.builder()
                        .currencyId(4L)
                        .requestedAmount(new BigDecimal("1000"))
                        .build())))
                .build();
    }

    private static Currency currency(String code) {
        return Currency.builder().id("HUF".equals(code) ? 6L : 4L).code(code).build();
    }
}
