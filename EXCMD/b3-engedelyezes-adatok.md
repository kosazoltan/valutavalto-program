# Modul: Tranzakció-engedélyezéshez szükséges adatok  (forrás: Kósa Tervezés és fejlesztés/Segédanyagok Valuta/Engedélyezéshez szükséges adatok.docx)

## 1. Cel (egy mondat)
Egy tranzakció felettesi engedélyezéséhez bemutatott engedélykérő adatlap mezőkészletének rögzítése a forrás-minta alapján.

## 2. Scope
### IN
- A „Engedély megadása egy tranzakcióhoz" engedélykérő adatlap mezői: pénztár-azonosítás, bizonylat, tranzakció-érték + valuta-sorok, ügyfél-azonosító adatok, engedélyező.
### OUT
- MNB/hatósági engedélyezési folyamat (a fájl tartalma tranzakciós engedélykérő minta, NEM hatósági engedélyeztetés) — a forrás erre nem tér ki → TBD.
- Az engedélyezés kiváltó küszöbe / üzleti szabálya (mikor kell engedély) → TBD.

## 3. Szakteruleti szereplok
| Szerep | Jogosultsag | RBAC ertek |
|---|---|---|
| Engedélyező (a forrásban „engedelyezo: KOSA ZOLTAN", felettesi jóváhagyó) | Tranzakció engedélyezése | TBD (a forrás nem ad RBAC-értéket) |
| Pénztáros (a tranzakciót kezdeményező, pénztár 105) | Engedélyt kér | TBD |

## 4. Funkcionalis kovetelmenyef (FR)
| ID | Leiras | Forrás-hivatkozas | Prio | Csomag |
|---|---|---|---|---|
| FR-1 | Engedélykérő adatlap pénztár-azonosítással: pénztár száma + pénztár neve. | „Penztar szama: 105", „Penztar neve: BEKESCSABA BELVAROS II." | TBD | TBD |
| FR-2 | Bizonylatszám megjelenítése az engedélykérőn. | „Bizonylatszam: V105007798" | TBD | TBD |
| FR-3 | Tranzakció teljes összege (HUF) megjelenítése. | „Tranz.osszege: 10088410" | TBD | TBD |
| FR-4 | Valuta-soronkénti bontás: valuta összege + valutanem, árfolyam, forintérték. | „1. valuta: 26,000 EUR / 1. arfoly: 38840 / 1. ertek: 10,098,400 Ft" | TBD | TBD |
| FR-5 | Ügyfél-azonosító adatok az engedélykérőn: név, anyja neve, születési idő, születési hely, lakcím, okmány típus, okmány szám, állampolgárság, tartózkodási hely. | „Ugyfel adatai: neve / anyja / szul.ido / szul.hely / lakcime / okmany tip. / okm. szama / allampolgar / tart-i hely" | TBD | TBD |
| FR-6 | Engedélyező személy rögzítése. | „engedelyezo: KOSA ZOLTAN" | TBD | TBD |

## 5. Nem-funkcionalis kovetelmenyef (NFR)
| ID | Leiras | Merheto kriterium |
|---|---|---|
| NFR-1 | Az engedélykérő bizonylat formátuma/megjelenítése | TBD — a forrás csak szöveges listát ad |

## 6. Adatmodell-erintettseg
A mezők egy tranzakcióra + ügyfélre mutatnak (bizonylatszám V105007798, pénztár 105, valuta-sorok, ügyfél-azonosító mezők). A konkrét Postgres-entitás / SQLite-mirror / migráció a forrásból NEM derül ki → TBD. (Megjegyzés: a forrás csak az adatlap-mintát adja, nem adatbázis-sémát.)

## 7. Fuggosegek
- Belső modul: tranzakció-kezelés (bizonylat, valuta-sor, árfolyam) + ügyfél-nyilvántartás. Pontos modulnév: TBD.
- Külső API: nincs a forrásban.

## 8. Domain-szotar
| Fogalom | Magyarazat |
|---|---|
| Engedélyezés (egy tranzakcióhoz) | Felettesi jóváhagyás egy konkrét tranzakcióra; a forrás egy kitöltött engedélykérő mintát mutat. |
| Bizonylatszám | A tranzakció azonosítója (minta: V105007798). |
| Valuta-sor | Egy tranzakción belüli valutatétel: összeg + valutanem + árfolyam + forintérték. |

## 9. Vegrehajtasi utasitas az AI-ugynoknek
### 9.1 Elokeszites
- A forrás egy kitöltött engedélykérő adatlap; a 6 FR a mezőkészletet rögzíti. Az engedélyezés kiváltó szabálya (küszöb, kötelezőség) tisztázandó — TBD.
### 9.2 Fazisok (acceptance criteria-val)
- Fázis 1: engedélykérő adatlap a felsorolt mezőkkel. AC: a megjelenített/nyomtatott adatlap tartalmazza FR-1..FR-6 minden mezőjét a minta szerint.
### 9.3 Tesztes
- AC-teszt a minta-rekorddal (pénztár 105, V105007798, 26 000 EUR @ 38840 = 10 098 400 Ft, ügyfél ANDRASI ROLAND, engedélyező KOSA ZOLTAN) — minden mező megjelenik. Üzleti küszöb-tesztek: TBD.

## 10. Kockazatok / Nyitott kerdesek (TBD)
| # | Kerdes | Miert fontos | Mit kell tudni |
|---|---|---|---|
| TBD-1 | Mi váltja ki az engedélyezést (összeghatár, valutanem, ügyfél-kockázat)? | Az egész folyamat triggere | A forrás csak kitöltött mintát ad |
| TBD-2 | Melyik szereplő/RBAC engedélyezhet? | Jogosultság | „engedelyezo" név van, nem szerepkör |
| TBD-3 | Adatlap megjelenés: képernyő, nyomtatott bizonylet vagy mindkettő? | UI/PDF döntés | Nincs a forrásban |
| TBD-4 | A „tart-i hely" (tartózkodási hely) mező a mintában üres — kötelező-e? | Validáció | Üresen jött a forrásban |

## 11. Verifikacios checklist
- [x] minden FR-hez forrás-hivatkozás
- [x] 0 hallucináció (a minta-értékeken túli szabály TBD)
- [x] minden TBD jelölt

VERIFIKACIO: FR=6 db, TBD=4 db, érintett csomag(ok)=TBD (forrás nem mondja meg)
