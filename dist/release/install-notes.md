# Valutaváltó — telepítési jegyzet (v2.27.52, 2026-05-29)

> **UNSIGNED build** — a DigiCert EV Code Signing validáció folyamatban. A Windows SmartScreen
> figyelmeztethet; „További információ" → „Futtatás mindenképp". A telepítő MINDENT automatikusan
> elvégez (PostgreSQL, backend, frontend, Electron, Windows-szolgáltatások, parancsikonok).

## Telepítők

| Fájl | Kinek | Méret |
|---|---|---|
| **Penztar-Setup-2.27.52-20260529.exe** | Pénztáros + Értéktáros munkaállomás | 283,8 MB |
| **Kozponti-Munkaallomas-Setup-2.27.52.exe** | Központi + Árfolyamkészítő (egy telepítő, indításkor mód-választó) | 102,4 MB |
| **Penztar-Eltavolito-2.27.52-20260529.exe** | Eltávolító (csak régi/sérült telepítés tisztításához) | 60 KB |

> ⚠️ **FIGYELEM — adatvesztés-veszély:** a `Penztar-Eltavolito` ALAPÉRTELMEZÉSBEN **törli a helyi
> PostgreSQL adatbázist** (`C:\ProgramData\BestChange` → teljes RMDir), KIVÉVE upgrade-módban
> (`/PRESERVE_DATA=1`). Éles/adatos gépen **NE futtasd** előzetes `pg_dump` mentés nélkül. Csak
> üres vagy sérült (adat nélküli) telepítés tisztításához használd.

## Telepítés (a kolléga dolga csak ennyi)
1. Dupla-klikk a telepítőre.
2. UAC → „Igen" (esetleg admin-jelszó).
3. Várd meg, amíg végez — minden automatikus.

## Mi újult (v2.27.50 → v2.27.52)
- **Árfolyamkészítő:** képletezhető csoport-árfolyamlapok (J–S oszlopok, A–I / !FEUR / #NN hivatkozások) + árfolyamvédelem (téves árfolyam mentésének blokkolása); az árfolyamvédelem mostantól az effektív (spread-del korrigált) rátát ellenőrzi.
- **Készlet pillanatkép:** a NAPI FORGALOM forint-oszlopai már a valós forgalmat mutatják (nem 0).
- **Excel összesítő:** cégcím „EXCLUSIVE BEST CHANGE ZRT.".
- **Kozmetika:** dashboard dátum a tranzakciólistában, helyes oldalsáv-kijelölés, ablak-cím kliensenként eltér.
- **Javítás (v2.27.51–52):** csoport-árfolyamlap szerkesztés stabilitása — a képlet-visszavonás (Ctrl+Z) és a csoportok közötti hivatkozások többé nem keverik a csoportok adatait.

## SHA256
- Penztar-Setup: `8FF7B477C2C7431F3C32CCC30C0ADF4364F26ECBA5D993FDAFDE9B4E36A430B1`
- Kozponti-Munkaallomas: `76134D2896342A6CEA39D634540E47A5CCBAEDE41DB36AD4E941C93140A60695`
- Eltavolito: `879F54B1A9DB16E43ADCC3AB4EE36BFAED0F28B00BB241765466F512260889B5`

A backend (excvaluta.com) már v2.27.52-n fut — a webes/szerver-funkciók a telepítő nélkül is élnek.
