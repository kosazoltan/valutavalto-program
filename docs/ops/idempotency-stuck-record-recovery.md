# Beragadt Transfer-dedup (PROCESSING) rekord manuális feloldása

> FKH-028 7. kör. Az átadás-létrehozás duplikátum-védelme (`TransferCreateDedupGuard`)
> DB-perzisztens `idempotency_record` sorokat használ `TRANSFER_CREATE_DEDUP`
> endpoint-scope-pal. Normál esetben a kulcs a tranzakció befejezésekor
> (afterCompletion, retry-jal) `COMPLETED`/`FAILED` állapotba kerül. Ritka esetben —
> pl. a backend-folyamat crash-e / deploy-közbeni megszakadás, vagy a release
> minden újrapróbálkozásának bukása — a rekord `PROCESSING`-ben ragadhat, és az
> azonos paraméterű átadás-rögzítés 409-et kap, amíg a rekord él (TTL: 1 óra).
>
> **Szándékos tervezési döntés:** automatikus időalapú átvétel NINCS (nem
> garantálható, hogy egy legitim kérés adott időn belül lefut, és a feloldás nem
> tulajdonos-alapú) — a feloldás kizárólag az alábbi, manuális, megerősítéshez
> kötött eljárással történhet.

## 1. Mikor gyanakodj beragadt rekordra

- A `TransferDedupStuckRecordWarningJob` 5 percenként ellenőrzi a
  `app.transfer-dedup.stuck-warn-minutes` (alapértelmezés: **15 perc**) küszöbnél
  régebbi `PROCESSING` rekordokat, és `WARN` logot ír:
  `BERAGADT Transfer-dedup rekord: id=…, kulcs-hash=…, N perce PROCESSING…`
- VAGY: a felhasználó ismétlődő „Valószínű duplikált beküldés…" (409) hibát kap
  olyan átadásra, amiről biztosan tudni, hogy nem fut.

## 2. Azonosítás

A dedup-kulcs SHA-256 hash (a worker/cél/valuta/összeg ebből szándékosan nem
fejthető vissza) — az érintett átadás a szerver-log **időbeli korrelációjával**
azonosítható: a rekord `created_at`-je körüli `POST /api/v1/transfers` kérés/
hiba-log adja a konkrét paramétereket.

Read-only ellenőrző lekérdezés (a prod `valuta` DB-n):

```sql
SELECT id, idempotency_key, status, created_at,
       now() - created_at AS kora, expires_at
  FROM idempotency_record
 WHERE endpoint = 'TRANSFER_CREATE_DEDUP'
   AND status = 'PROCESSING'
   AND created_at < now() - interval '15 minutes'
 ORDER BY created_at;
```

## 3. Feloldás — KIZÁRÓLAG megerősítés után

**Előfeltétel (kötelező):** igazolt, hogy az eredeti kérés ténylegesen NEM fut —
pl. a szerver-log crash/restart bejegyzése a rekord `created_at`-je után, vagy a
backend uptime rövidebb, mint a rekord kora. **TILOS** rutinszerűen futtatni egy
friss (percen belüli) 409-re — az normál duplikátum-védelem lehet.

A feloldó UPDATE (a `FAILED` állapot a kulcsot azonnal újrafoglalhatóvá teszi,
a következő legitim kérés átmegy):

```sql
UPDATE idempotency_record
   SET status = 'FAILED',
       completed_at = now()
 WHERE id = <A 2. LÉPÉSBEN AZONOSÍTOTT ID>
   AND endpoint = 'TRANSFER_CREATE_DEDUP'
   AND status = 'PROCESSING';
```

- Az `AND status = 'PROCESSING'` őrfeltétel kötelező: ha a rekord időközben
  magától lezárult, az UPDATE 0 sort érint — ilyenkor nincs teendő.
- Törölni NEM kell (és ne is törölj): az 1 órás TTL-t az `IdempotencyCleanupJob`
  kezeli.

## 4. Utólagos ellenőrzés

1. A 2. lépés SELECT-je már nem adja vissza a rekordot PROCESSING-ként.
2. A felhasználó ismételt rögzítése átmegy (vagy a szokásos üzleti validációs
   hibát adja — de már nem a duplikátum-409-et).
3. Ha ugyanaz a rekord ismételten beragad, az már nem egyszeri crash — hibajegy
   szükséges (a release-retry és a guard vizsgálatával).
