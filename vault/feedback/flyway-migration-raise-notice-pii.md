# Flyway migration RAISE NOTICE — PII maszkolás kötelező

**Hatálybalépés:** 2026-05-11 (Copilot P2 finding PR #555)

## Szabály

Flyway migrációk `RAISE NOTICE` üzeneteiben **TILOS** személyes vagy azonosító adatot (PII) kiírni teljes értékkel:
- `google_subject` (Google OAuth sub claim)
- `email`
- Bármely egyéb felhasználó-azonosító

## Helyes minta

```sql
-- ROSSZ:
RAISE NOTICE 'V204: google_subject (%) atmasolva.', bali_google_subject;

-- JO (maszkolt):
RAISE NOTICE 'V204: BALI (worker_id=%) google_subject atmasolva W-S011-re (worker_id=%).', bali_worker_id, ws011_worker_id;

-- JO (rowcount ellenorzes):
GET DIAGNOSTICS rows_affected = ROW_COUNT;
IF rows_affected > 0 THEN
    RAISE NOTICE 'V204: google_subject atmasolva (% sor).', rows_affected;
ELSE
    RAISE NOTICE 'V204: W-S011-nek mar volt sajat Google binding — nincs atmasolas.';
END IF;
```

## Háttér

- V204 `RAISE NOTICE` a teljes `google_subject` értéket kiírta a Flyway logba (Copilot P2)
- Szintén mindig "átmásolva"-t mondott, akkor is ha 0 sor érintett (Copilot P3)
- V204 egyszer futó migráció, már lefutott production-ön — utólagos fix értelmetlen
- Tanulság: jövőbeli migrációkban worker ID-ket logolni, nem PII-t, és rowcount-ot ellenőrizni
