# Valutaváltó — telepítési jegyzet (v2.27.99, 2026-06-11)

> **UNSIGNED build** — a DigiCert EV Code Signing validáció folyamatban. A Windows SmartScreen
> figyelmeztethet; „További információ" → „Futtatás mindenképp". A telepítő MINDENT automatikusan
> elvégez (PostgreSQL, backend, frontend, Electron, Windows-szolgáltatások, parancsikonok).

## Telepítők

| Fájl | Kinek | Méret |
|---|---|---|
| **Penztar-Setup-2.27.99-20260611.exe** | Pénztáros + Értéktáros munkaállomás | 282,3 MB |
| **Penztar-Eltavolito-2.27.99-20260611.exe** | Eltávolító (csak régi/sérült telepítés tisztításához) | 60 KB |

> ⚠️ **FIGYELEM — adatvesztés-veszély:** a `Penztar-Eltavolito` ALAPÉRTELMEZÉSBEN **törli a helyi
> PostgreSQL adatbázist** (`C:\ProgramData\BestChange` → teljes RMDir), KIVÉVE upgrade-módban
> (`/PRESERVE_DATA=1`). Éles/adatos gépen **NE futtasd** előzetes `pg_dump` mentés nélkül. Csak
> üres vagy sérült (adat nélküli) telepítés tisztításához használd.

## Telepítés (a kolléga dolga csak ennyi)
1. Dupla-klikk a telepítőre.
2. UAC → „Igen" (esetleg admin-jelszó).
3. Várd meg, amíg végez — minden automatikus.

## Mi újult (v2.27.98 → v2.27.99)
- **Átadás-átvétel bizonylat fejléc:** az iroda neve, címe és telefonszáma mostantól az iroda-törzsből
  (branch tábla) töltődik — nincs többé beégetett székhelycím/telefonszám a bizonylaton.
- **Kérő iroda mező:** automatikusan kitöltődik a bejelentkezett iroda adataival (nem marad üres).
- **Átvételi bizonylat:** kötelező jogi nyilatkozat szöveg + Átadó/Átvevő aláírás vonalak
  (sztornó bizonylaton nem jelenik meg).
- **HUF bizonylat:** forint valutanemű átadás-átvételi bizonylat automatikusan 2 példányban nyomtat
  (1. iratározás, 2. könyvelés); deviza esetén 1 példány.
- **Nyomtatási stabilitás:** ha a soros blokknyomtató részlegesen hibázik, a tartalék nyomtatás már
  csak a hiányzó példányokat nyomtatja (nem keletkezik felesleges többletpéldány).
- **Offline mód:** a bizonylat-fejléc iroda-adatai offline is elérhetők (helyi gyorsítótár bővítés).

## SHA256
- Penztar-Setup: `409065A0476778E8215B69099DC0684DB01C5006C9F231E1AD4910F31EC572DB`
- Eltavolito: `A84CA02D632FD10E89E8F20E8F36FFDDCF9BE33A00BDB193BC5A633BD656A6E7`

A backend (excvaluta.com) már a PR #1095 utáni kóddal fut — a webes/szerver-funkciók a telepítő nélkül is élnek.
