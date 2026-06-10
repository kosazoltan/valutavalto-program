# Sztornó 4-szem-elv (#954) — UI-evidence pótlása (2026-06-10)

## Előzmény

A V305 migráció (AML go-live flagek) a `STORNO_APPROVAL_FOUR_EYES_ENFORCEMENT`
flaget kifejezetten KIHAGYTA, indoklással: „a storno four-eyes UI-készenlétére
nincs dokumentált evidence → DEFER (külön döntés)."

A kód-elleni reverifikáció kimutatta a tényleges hiányt: a backend
`POST /api/v1/stornos/approve/{approvalId}` végpontot **semmilyen UI nem hívta** —
a `stornoApi.approve` kliens-metódus létezett, de nem volt rá hivatkozás; továbbá
**nem létezett végpont** a függő (PENDING) kérések listázására, így a supervisor
nem láthatta, mit kellene jóváhagynia. A jóváhagyási kör a gyakorlatban csak
DB-manipulációval volt zárható.

## Pótolt lánc (ez a kör)

| Réteg | Változás |
|---|---|
| Repository | `StornoApprovalRepository.findPendingByBranch` — PENDING + branch-izolált, FIFO |
| Service | `StornoService.getPendingApprovals()` — security-context branch, lazy-feloldás tranzakción belül (OSIV off) |
| DTO | `StornoApprovalDto` + `workerName`, `receiptNumber`, `createdAt` (jóváhagyó-lista megjelenítés) |
| Controller | `GET /api/v1/stornos/approvals/pending` — `@PreAuthorize SUPERVISOR/MANAGER/ADMIN` |
| Frontend API | `stornoApi.pendingApprovals()` + interface-bővítés |
| Frontend UI | `StornoApprovalListPage` (`/stornos/approvals`) — lista + Engedélyezés/Elutasítás (indoklás-kötelező elutasítás), a backend 4-szem-hibaüzenete változtatás nélkül megjelenik |
| Menü | „Adminisztráció" → „Sztornó jóváhagyások" (`ugyvezeto`, `irodavezeto`) |
| OpenAPI | `openapi.json` + `openapi.d.ts` szinkron (új path + DTO-mezők + a hiányzó `approvalStatusCode` pótlása) |
| Teszt | `StornoServiceTest`: pending-lista branch-izoláció + megjelenítési mezők + üres-lista eset |

## Flag-élesítési döntés — MEGSZÜLETETT és VÉGREHAJTVA (2026-06-10, 2. kör)

**Üzleti döntés (Kósa Zoltán):** „A valutaváltóirodák általában egyszemélyes
valutaváltók, így a telefonon keresztül történő supervisor jóváhagyás pin kóddal
működhet, működjön. Ez volt a fő üzleti cél és döntés ez esetben."

A kód-felderítés kimutatta: a telefonos PIN-minta az **AML felsővezetői
jóváhagyásnál már működött** (`AmlApprovalController.verify-approver` —
pénztáros-sessionből hívható, 4-szem + szerepkör + cég + PIN + single-use grant),
de a **sztornó-jóváhagyásnál HIÁNYZOTT**: a `POST /stornos/approve` supervisor-
sessiont követelt, a `/supervisor-pin/verify` szintén SUPERVISOR+-gated — egyik
sem volt hívható pénztáros-sessionből (az AmlApprovalController javadoc-ja ezt
explicit dokumentálta).

Pótolt elemek (2. kör):
| Réteg | Változás |
|---|---|
| Service | `StornoService.approveByPin` — 4-szem KEMÉNYEN (jóváhagyó ≠ kérelmező ÉS ≠ bejelentkezett), SUPERVISOR/MANAGER/ADMIN + cég-check (AML-minta), `SupervisorPinService.verifyPin` (BCrypt + 3-hibás/5-perc lockout + audit) |
| Controller | `POST /api/v1/stornos/approve-by-pin` — `isAuthenticated()` (pénztáros hívhatja); a PIN BODY-ban (access-log védelem) |
| DTO | `StornoPinApprovalRequestDto` (validált) |
| Frontend | `StornoPinApprovalModal` (AmlApproverModal-minta: jóváhagyó-választó + PIN auto-submit) + StornoPage „Telefonos jóváhagyás (supervisor PIN)" gomb a PENDING kérésnél |
| Migráció | **V306**: `STORNO_APPROVAL_FOUR_EYES_ENFORCEMENT` = true (V305-minta, idempotens) — az egyszemélyes-iroda blokkoló a PIN-úttal megszűnt |
| OpenAPI | path + DTO szinkron; a sztornó pending-lista operationId-ütközése a rate-approvals-szal feloldva (`getPendingStornoApprovals`) |
| Teszt | `StornoServiceTest`: +6 PIN-teszt (helyes PIN → APPROVED; hibás PIN; jóváhagyó=kérelmező; jóváhagyó=bejelentkezett; nem-senior szerepkör; idegen cég — mind tiltva) |
