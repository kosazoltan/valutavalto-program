# Rate-print Proof-of-Print HMAC secret (RP-HA)

Ez a doc a `APP_RATE_PRINT_HMAC_SECRET` env valtozo celjat, alivepitasat es a
prod ops-lepest irja le.

## Cel

A `RatePrintProofService` HMAC tokeneket allit ki a rate-change print
acknowledgementhez (jogilag kotelezo nyomtatas). A secret hianyaban a service
processz-lokalis `UUID.randomUUID()` secretre esik vissza — minden restart
utan mas secret → a korabban kiadott (es a penztar-client altal vegtelenul
ujraprobalkozott) tokenek ellenorzese veglegesen elbukik.

A `app.rate-print.hmac-secret=${APP_RATE_PRINT_HMAC_SECRET:}` bekotes
(`application.properties`) ugyel arra, hogy ures env eseten a viselkedes ma
valtozatlan maradjon (dev random-fallback), de prodban a secret env-bol jovo determinisztikus
ertek legyen.

## Bootstrap (uj VPS — automatikus)

A `bootstrap-vps.sh` egy uj `.env` letrehozasanal automatikusan generalja:
`rate_print_secret="$(gen_secret_hex 32)"` es beleirja a heredocba.

FIGYELEM: a bootstrap CSAK akkor fut le, ha a `.env` meg nem letezik (vagy nem
tartalmaz `DATABASE_PASSWORD=`-t). Egy meglevo prod `.env`-et NEM modositja.

## Prod ops-lepes (MANUALIS, egyszer — meglevo VPS-en)

A jelenlegi prod `.env` nem tartalmazza a secret-et. Egy egyszeri lepesben hozza
kell adni, majd ujrainditani a backendet. A VPS-en, root-kent:

```bash
# 1. Secret generalasa es bele a .env-be (ha meg nincs benne)
grep -qE '^APP_RATE_PRINT_HMAC_SECRET=' /opt/valutavalto/backend/.env \
  || printf 'APP_RATE_PRINT_HMAC_SECRET=%s\n' "$(openssl rand -hex 32)" \
       >> /opt/valutavalto/backend/.env

# 2. Backend ujrainditasa az uj env-vel
systemctl restart valuta-backend

# 3. Ellenorzes: a secret bekerult-e a service env-jebe
systemctl show valuta-backend --property=Environment | grep -c APP_RATE_PRINT
```

### Restart side-effect

A restart utan minden a restart ELOTT kiadott token ervenytelenne valik — de ezek
ugyis random-secret tokenek voltak,igy elvileg nem hibasak a nyomtatas. A fiokok
ugy tudjak ujra kinyomtatni, hogy a pending-print listat ujra lekerdezik
(a `syncRatePrintObligations` ciklus a kovetkezo menetben uj tokeneket allit ki).

### Outbox poison-message figyelmeztetes

A penztar-client `flushRatePrintOutbox` (sync-engine.ts:2085) az elso HTTP 400-on
kivetel dob es a sort nem torli — egyetlen ervenytelen token a teljes rate-print
sync-ciklust beragadja (poison message). A stabil secret ritkava teszi a triggert,
de a minta maga kulon issue (nem ebben a slice-ban).

## Kovetkezo lepes (NEM implementalva ebben a slice-ban)

Ha a `StaticAuditService` kimeneteben az `APP_RATE_PRINT_HMAC_SECRET = SET`
megbiztosan megjelenik prod-on, egy opt-in fail-fast flag kovetkezik
kulon slice-kent:

```
app.rate-print.require-secret=${APP_RATE_PRINT_REQUIRE_SECRET:false}
```

Ez NEM profile-kulcssal mukodik (a #1293 PROD-502 tanulsag: a profile-nev
ambiguitas miatt a trigger feltetel megbizhatatlan lenne), hanem explicit
opt-in env flag-kel.
