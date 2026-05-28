# Pénztáros munkaállomás — v2.27.35 frissítés

**Dátum:** 2026-05-28  
**Címzett:** a pénztárakat és értéktárakat üzemeltető kollégák

---

## Mi változott?

A v2.27.35 a **központi munkaállomáson** futó FK-006/007/008 javításokhoz tartozó pénztáros oldali csomag — verzió-szinkron miatt. A pénztáros felület működése ugyanaz marad, csak a backend frissül, hogy konzisztens legyen a központi munkaállomással.

A friss bundle tartalmazza:
- a valutanem-törzs központosítását (V271 migráció — DKK/NOK/SEK inaktív, BAM/BRL/ILS/MXN/NZD/THB aktív),
- a TST ismeretlen valuta deaktiválását (V272),
- a Készlet-snapshot törzs-vezérelt valutalistáját (PR [#880](https://github.com/kosazoltan/valutavalto-program/pull/880)),
- a FK-03 munkacsoport árfolyamlap képletmotor 1. szakaszát (PR [#879](https://github.com/kosazoltan/valutavalto-program/pull/879)).

A korábbi tranzakciók, ügyfél-adatok, AML-jegyzetek és sztornók **érintetlenek** maradnak.

---

## Telepítés

1. Mentsd el a futó munkát és zárd be a programot.
2. Dupla-klikk a `Penztar-Setup-2.27.35.exe` fájlra.
3. UAC kérdésre **Igen**.
4. A telepítő mindent automatikusan elvégez:
   - régi verzió eltávolítása **adatbázis-megőrzéssel** (a PostgreSQL adatbázis és a tranzakciók nem törlődnek),
   - friss bundle telepítése (PostgreSQL 17.5, Java JRE, backend, frontend),
   - tűzfal-szabályok, parancsikonok, indító service.
5. A telepítő végén a program elindul.

---

## Ha valami nem stimmel

Ha a frissítés után hiba lép fel:
1. Indítsd újra a gépet (`Start → Indítás újra`).
2. Ha továbbra is hiba van, **NE** próbálj manuálisan beavatkozni — küldd vissza a képernyőképet és a hibajelenséget a fejlesztőnek.

A fejlesztő (én) intézkedik. **A te dolgod csak a dupla-klikk + UAC „Igen"** — semmi más.

---

## Eltávolítás (csak végszükség esetén)

Ha a teljes eltávolítást egyeztetjük, a `Penztar-Eltavolito-2.27.35.exe` standalone eltávolító kerül használatra.

> **FIGYELEM:** Az eltávolító törli az adatbázist is. Csak akkor használd, ha a fejlesztő (én) ezt **írásban** megerősíti, és előtte `pg_dump` mentés készül.

---

## Műszaki háttér (referenciának)

- Backend teszt: 1715/1715 zöld
- DigiCert EV Code Signing tanúsítvány: validáció folyamatban → ez a build **UNSIGNED** (SmartScreen warning elfogadása szükséges). Signed verzió a cert kiadása után.
- Verzió-szinkron: mind a 6 forrás (backend pom + 5 client package.json) 2.27.35-ön.
