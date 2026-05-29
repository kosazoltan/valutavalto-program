# Valutaváltó — telepítési jegyzet (v2.27.50, 2026-05-29)

> **UNSIGNED build** — a DigiCert EV Code Signing validáció folyamatban. A Windows SmartScreen
> figyelmeztethet; „További információ" → „Futtatás mindenképp". A telepítő MINDENT automatikusan
> elvégez (PostgreSQL, backend, frontend, Electron, Windows-szolgáltatások, parancsikonok).

## Telepítők

| Fájl | Kinek | Méret |
|---|---|---|
| **Penztar-Setup-2.27.50-20260529.exe** | Pénztáros + Értéktáros munkaállomás | 283,8 MB |
| **Kozponti-Munkaallomas-Setup-2.27.50.exe** | Központi + Árfolyamkészítő (egy telepítő, indításkor mód-választó) | 102,4 MB |
| **Penztar-Eltavolito-2.27.50-20260529.exe** | Eltávolító (csak régi/sérült telepítés tisztításához) | 60 KB |

> ⚠️ **FIGYELEM — adatvesztés-veszély:** a `Penztar-Eltavolito` ALAPÉRTELMEZÉSBEN **törli a helyi
> PostgreSQL adatbázist** (`C:\ProgramData\BestChange` → teljes RMDir), KIVÉVE upgrade-módban
> (`/PRESERVE_DATA=1`). Éles/adatos gépen **NE futtasd** előzetes `pg_dump` mentés nélkül. Csak
> üres vagy sérült (adat nélküli) telepítés tisztításához használd.

## Telepítés (a kolléga dolga csak ennyi)
1. Dupla-klikk a telepítőre.
2. UAC → „Igen" (esetleg admin-jelszó).
3. Várd meg, amíg végez — minden automatikus.

## Mi újult (v2.27.50)
- **Árfolyamkészítő:** képletezhető csoport-árfolyamlapok (J–S oszlopok, A–I / !FEUR / #NN hivatkozások) + árfolyamvédelem (téves árfolyam mentésének blokkolása).
- **Készlet pillanatkép:** a NAPI FORGALOM forint-oszlopai már a valós forgalmat mutatják (nem 0).
- **Excel összesítő:** cégcím „EXCLUSIVE BEST CHANGE ZRT.".
- **Kozmetika:** dashboard dátum a tranzakciólistában, helyes oldalsáv-kijelölés, ablak-cím kliensenként eltér.

## SHA256
- Penztar-Setup: `30E7DD833FA6E660EE76762804764D196EB39E97318D9324009D92F28E72A9A1`
- Kozponti-Munkaallomas: `DA58A3BAAD88E96605F5B8F131A3F664861E317EA0B3F42522BB9CB7A98DD59E`
- Eltavolito: `5DA69DEC2671EC8CFA715C2B02BD1B22AFFD320C921159CC64CA3B391C1A2A78`

A backend (excvaluta.com) már v2.27.50-en fut — a webes/szerver-funkciók a telepítő nélkül is élnek.
