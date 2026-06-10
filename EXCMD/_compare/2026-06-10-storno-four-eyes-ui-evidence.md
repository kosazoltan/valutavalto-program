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

## Flag-élesítési döntés — TOVÁBBRA IS NYITOTT (üzleti döntés)

A `STORNO_APPROVAL_FOUR_EYES_ENFORCEMENT` flaget ez a kör **NEM kapcsolja be**.
A V305-ben dokumentált DEFER „külön döntés"-t ír elő, és van valós üzleti
kockázat: **egyszemélyes kis irodában** (ahol a pénztáros egyben a supervisor)
a 4-szem-elv a napi limit feletti sztornót teljesen blokkolná — független
jóváhagyó hiányában.

Élesítési előfeltétel (üzleti): döntés arról, hogy kis irodákban a központi
(távoli) supervisor jóváhagyása elegendő-e — a jóváhagyó-lista branch-izolált,
tehát ehhez a központi supervisor branch-hozzárendelésének kérdését is rendezni
kell. A technikai evidence-hiány ezzel a körrel megszűnt; a flag egy V306-os,
V305-mintájú idempotens migrációval élesíthető, amikor az üzleti döntés megvan.
