# Modul: Átadás-átvétel, Western Union, ÁFA, kezelési költség, haszon  (forrás: `Felmérés/Valuta/Kósa Tervezés és fejlesztés/Segédanyagok Valuta/WU e ker kktg áfa 2024 02 hó.xlsx`, `Felmérés/Valuta/Cégcsoport felmérése/Személyes találkozó összefoglalók, kapott dokumentumok, képernyőképek/Dokumentumok/Áfa, kktg  2024 10 09 hó.xlsx`, `.../EXZ haszon pt 202409 hó.xlsx`, `.../Kezelési költség jelentés.jpg`)

## 1. Cel (egy mondat)
A régi program "egyéb havi adatai" riportjának STRUKTÚRÁJÁT leírni: napi bontású Western Union, elektromos kereskedés, ÁFA-visszatérítés, kezelési költség, értéktár befizetés/átvétel, valamint a kezelési költség jelentés bizonylat-formátuma.

## 2. Scope
### IN
- "EGYÉB HAVI ADATAI" riport: napi soros (1–29/31. nap) WU + elektromos kereskedés + ÁFA-visszatérítés + kezelési költség mozgások irodánként/körzetenként/cégenként — `WU e ker kktg áfa 2024 02 hó.xlsx` (lapok: Best Change, Expressz, Munka1).
- Western Union al-blokk: NYITÓ, BEVÉTEL, KIADÁS, ZÁRÓ.
- Kezelési költség al-blokk: BEFIZETÉS ÉRTÉKTÁRNAK, BEVÉTEL ÜGYFÉLTŐL, ÁTVÉTEL PÉNZTÁRTÓL.
- Elektromos kereskedés al-blokk: NYITÓ, BEVÉTEL BANKTÓL, KIADÁS PÉNZTÁRNAK, VISSZATÉRÍTÉS (USD/HUF), ZÁRÓ.
- ÁFA-visszatérítés, MATRICA, TELEFON, ÁTADÁS, ÁTVÉTEL napi mezők.
- Kezelési költség jelentés bizonylat (napi/dekád) — `Kezelési költség jelentés.jpg`.
### OUT
- `Áfa, kktg 2024 10 09 hó.xlsx` és `EXZ haszon pt 202409 hó.xlsx` tényleges adattartalma (régi OLE2 binary → TBD).
- Az ÁFA-számítás üzleti szabálya (kulcs, alap) — nem szerepel a forrásban → TBD.
- A haszonszámítás képlete → TBD.
- Western Union külső API integráció (nincs a forrásban).

## 3. Szakteruleti szereplok
| Szerep | Jogosultsag | RBAC ertek |
|---|---|---|
| Pénztáros | WU napi mozgás rögzítés saját pénztárra | CASHIER |
| Értéktáros / Főértéktáros | Kezelési költség befizetés/átvétel, körzet egyéb-adatok | VAULT_KEEPER / HEAD_VAULT_KEEPER |
| Ügyvezető / Belsőellenőr | ÁFA, haszon, cég-szintű egyéb-adatok | EXECUTIVE / INTERNAL_AUDITOR |
| admin | Minden | ADMIN |

## 4. Funkcionalis kovetelmenyek (FR)
| ID | Leiras | Forrás-hivatkozas | Prio | Csomag |
|---|---|---|---|---|
| FR-1 | "EGYÉB HAVI ADATAI" riport fejléc cég + hónap (pl. "EXCLUSIVE BEST CHANGE KFT 2024 FEBRUAR EGYÉB HAVI ADATAI", "EXPRESSZ ÉKSZERHÁZ ...") | `WU e ker kktg áfa 2024 02 hó.xlsx` R0 + SS | M | kozponti-client, frontend-react |
| FR-2 | Napi soros bontás: minden iroda alatt 1 sor / nap (DÁTUM 2024.02.01 ... 2024.02.29) | `WU...xlsx` SS dátum-lista + sheet1 R7+ | M | frontend-react |
| FR-3 | Western Union blokk oszlopok: NYITÓ, BEVÉTEL, KIADÁS, ZÁRÓ (záró=nyitó+bevétel-kiadás) | `WU...xlsx` SS "WESTERN UNION" + R1 | M | penztar-client, frontend-react |
| FR-4 | Kezelési költség blokk: KEZELÉSI KÖLTSÉG, BEFIZETÉS ÉRTÉKTÁRNAK, BEVÉTEL ÜGYFÉLTŐL, ÁTVÉTEL PÉNZTÁRTÓL | `WU...xlsx` SS | M | penztar-client |
| FR-5 | Elektromos kereskedés blokk: NYITÓ, BEVÉTEL BANKTÓL, KIADÁS PÉNZTÁRNAK, VISSZATÉRÍTÉS, ZÁRÓ — USD és HUF dimenzióban | `WU...xlsx` SS + R2–R3 (USD/HUF al-oszlopok) | S | frontend-react |
| FR-6 | ÁFA VISSZATÉRÍTÉS napi mező | `WU...xlsx` SS "AFA VISSZATÉRÍTÉS" | M | frontend-react |
| FR-7 | MATRICA, TELEFON napi mezők (egyéb értékesítés) | `WU...xlsx` SS | C | penztar-client |
| FR-8 | ÁTADÁS / ÁTVÉTEL napi mező az egyéb-adatok riportban | `WU...xlsx` SS + R3 | S | penztar-client |
| FR-9 | Körzet → iroda hierarchia ugyanaz mint a forgalmi riportban (SZEKSZÁRD..KAPOSVÁR körzetek + EXPRESSZ körzet) | `WU...xlsx` SS körzet/iroda-lista | M | frontend-react |
| FR-10 | Cégenként külön munkalap (Best Change / Expressz) + összesítő (Munka1) | `WU...xlsx` sheet names | S | frontend-react |
| FR-11 | Kezelési költség jelentés fejléc: cégnév + "KEZELÉSI KÖLTSÉG JELENTÉS" + iroda ("BÉKÉSCSABA értéktár") + cím + dátum | `Kezelési költség jelentés.jpg` | M | penztar-client |
| FR-12 | Kezelési költség jelentés tételsor: Sorszám, Bizonylatszám (pl. "K-000675"), Tranzakció ("forint - átadás"), Bank/ptár (pl. RB), Bevétel, Kiadás | `Kezelési költség jelentés.jpg` | M | penztar-client |
| FR-13 | Kezelési költség jelentés összesítő: BEVÉTELI BIZONYLATOK (darab) / KIADÁSI BIZONYLATOK (darab); KEZELÉSI DÍJ / NYITÓ / ZÁRÓ / ÖSSZESEN mátrix | `Kezelési költség jelentés.jpg` | M | penztar-client |
| FR-14 | Kezelési költség jelentés lábléc: helyszín + dátum + "pénztáros" aláírás | `Kezelési költség jelentés.jpg` | S | penztar-client |
| FR-15 | ÁFA + kezelési költség havi összesítő riport | `Áfa, kktg 2024 10 09 hó.xlsx` (csak fájl + cím ismert) | C | kozponti-client |
| FR-16 | Haszon riport pénztáranként | `EXZ haszon pt 202409 hó.xlsx` (csak fájlnév ismert) | C | kozponti-client |

## 5. Nem-funkcionalis kovetelmenyek (NFR)
| ID | Leiras | Merheto kriterium |
|---|---|---|
| NFR-1 | WU/elektromos záró-egyenleg napi folytonosság (előző nap záró = következő nap nyitó) | invariáns-teszt nem bukik |
| NFR-2 | Multi-tenant + multi-currency (USD/HUF) az elektromos kereskedés blokkban | minden összeg currency-vel dimenzionált |
| NFR-3 | HUF 5 Ft kerekítés | minden HUF mező roundHuf |

## 6. Adatmodell-erintettseg
- Western Union napi egyenleg pénztáranként (nyitó/bevétel/kiadás/záró).
- Kezelési költség mozgás: ügyféltől bevétel + pénztártól átvétel + értéktárnak befizetés; kezelési díj mint külön bizonylat-típus ("K-" prefix bizonylatszám).
- Elektromos kereskedés: USD + HUF al-egyenleg, banki bevétel / pénztári kiadás / visszatérítés.
- ÁFA-visszatérítés, matrica, telefon mint napi tételek.
- SQLite mirror: IGEN (WU + kezelési költség penztar-client offline rögzítés); NEM az ÁFA/haszon cég-szintű összesítőre. Migráció: TBD.

## 7. Fuggosegek
- Belső: tranzakció modul, iroda/körzet törzs, kezelési költség (kktg) modul, átadás-átvétel modul.
- Külső: Western Union (a forrás nem mutat API-t, csak manuális napi egyenleg) → TBD.
- Adatbázis: Postgres + SQLite.

## 8. Domain-szotar
| Fogalom | Magyarazat |
|---|---|
| Western Union (WU) | Pénzküldő szolgáltatás napi nyitó/bevétel/kiadás/záró egyenleggel |
| Kezelési költség (kktg) | Tranzakció után felszámított díj; ügyféltől bevétel, értéktárnak befizetve |
| Kezelési díj | A jelentés összesítő sora (a nap/dekád kktg összege) |
| Elektromos kereskedés (e ker) | Banki és pénztári USD/HUF mozgások, visszatérítéssel |
| ÁFA visszatérítés | Külföldi vásárlók ÁFA-visszaigénylése |
| Dekád | ~10 napos zárási időszak (a kezelési költség jelentés "dekádzárás" mintán) |
| BEFIZETÉS ÉRTÉKTÁRNAK | A pénztár kezelési költségének átadása az értéktárba |

## 9. Vegrehajtasi utasitas az AI-ugynoknek
### 9.1 Elokeszites
- Olvasd a `WU...xlsx` sharedStrings + sheet1 első 18 sorát (blokkok + napi tételek) és a kezelési költség jelentés képet.
- A két OLE2 binary fájl (Áfa-kktg, EXZ haszon) adattartalma NEM elérhető → TBD.
### 9.2 Fazisok
- F1: WU napi egyenleg blokk (FR-1..3) — acceptance: nyitó/bevétel/kiadás/záró napi sorok, záró-folytonosság.
- F2: Kezelési költség (FR-4, FR-11..14) — acceptance: "K-" bizonylatok + KEZELÉSI DÍJ/NYITÓ/ZÁRÓ/ÖSSZESEN mátrix jelentés generálódik.
- F3: Elektromos kereskedés + ÁFA + matrica/telefon (FR-5..8) — acceptance: USD/HUF al-egyenleg helyes.
- F4: Cég/körzet/iroda aggregáció (FR-9..10) — acceptance: hierarchikus összesítő.
### 9.3 Tesztes
- Unit: WU/e-ker záró=nyitó+bevétel-kiadás; kezelési díj összegzés; ÁFA-mező napi aggregálás.
- Integration: havi egyéb-adatok riport irodánként.

## 10. Kockazatok / Nyitott kerdesek (TBD)
| # | Kerdes | Miert fontos | Mit kell tudni |
|---|---|---|---|
| 1 | ÁFA-visszatérítés számítási szabálya (kulcs, alap) | helyes ÁFA összeg | a forrás csak mezőt mutat, képletet nem; `Áfa, kktg ...xlsx` OLE2 binary nem olvasható |
| 2 | Haszonszámítás képlete pénztáranként | `EXZ haszon pt ...xlsx` riport | OLE2 binary, nem kinyerhető |
| 3 | Western Union külső integráció vs manuális rögzítés | adatforrás | a forrás csak napi manuális egyenleget mutat |
| 4 | "VISSZA TÉRITÉS" USD/HUF jelentése az e-ker blokkban | dimenzionálás | R2–R3 fejléc szerint USD+HUF, részlet TBD |
| 5 | Külön átadás-átvétel havi kimutatás struktúrája | a feladat kérte | `ÁtaDÁS ÁTVÉTEL 2024 02` és `Havi átadás-átvétel kimutatás.xlsx` nem található a forrásban |

## 11. Verifikacios checklist
- [x] minden FR-hez forrás-hivatkozás
- [x] 0 hallucináció
- [x] minden TBD jelölt
VERIFIKACIO: FR=16 db, TBD=5 db, érintett csomag(ok)=penztar-client, frontend-react, kozponti-client
