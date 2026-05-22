# Modul: EXPRESSZ ZALOG (zalogos kulon termek) — forras-katalogus  (forras: `Felmérés/Valuta/Kósa Szervezés/Követelmény lista/zalog_requirment.rqm`, `Felmérés/Valuta/.../Dokumentumok/`)

## 1. Cel (egy mondat)
A zalogos (zaloghaz) rendszerhez tartozo banki import-, ugyfeles jelentes- es keszletjelentes-formatumok katalogizalasa annak rogzitesere, hogy ezek **KULON termekhez** (EXPRESSZ ZALOG/EXZ) tartoznak, NEM a valutavaltohoz.

## 2. Scope
### IN
- A zalogos forrasfajlok formatum-szintu leirasa (mit tartalmaznak).
### OUT
- **Teljes modul OUT a valutavalto ERP szempontjabol** — kulon zalog-termek. A valutavalto (EXV) es a zalog (EXZ) ket elkulonult rendszer.
- TILOS a zalog-funkciot a valutavalto programba beemelni hallucinacioval.

## 3. Szakteruleti szereplok
| Szerep | Jogosultsag | RBAC ertek |
|---|---|---|
| (zalogos/becsus, EXZ rendszer) | n/a (kulon termek) | n/a (OUT) |

## 4. Funkcionalis kovetelmenyek (FR)
| ID | Leiras | Forrás-hivatkozas | Prio | Csomag |
|---|---|---|---|---|
| — | Nincs valutavalto-FR. A zalog kulon termek; a `.rqm` zalog-kovetelmenymodell, NEM EXV. | `zalog_requirment.rqm` | — | OUT |

## 5. Nem-funkcionalis kovetelmenyek (NFR)
| ID | Leiras | Merheto kriterium |
|---|---|---|
| NFR-ZAL-01 | A banki import / ugyfeles jelentes CSV szerkezete a HATOSAGI (Pmt./NAV ugyfeles) jelentes formatumahoz hasonlit — ez a valuta-oldalon mar letezo igeny is. | TBD: uzleti dontes, hogy a valuta-oldal NAV/ugyfeles exportja ezt a mezostrukturat kovesse-e (kapcsolat: meglevo NAV-riport, de NEM e modulbol). |

## 6. Adatmodell-erintettseg
Nincs (OUT). A valutavalto Postgres/SQLite semajat nem erinti. Migracio nem szukseges.

## 7. Fuggosegek
Kulso: a zalogos forrasokban hivatkozott banki/hatosagi import (FRB/ERB/RB/… bank-kodok a forgalmi jelentesekben). Belso valutavalto-modul: NINCS.

## 8. Domain-szotar
| Fogalom | Magyarazat |
|---|---|
| EXPRESSZ EKSZERHAZ / Minibank | A zalogos tarsasag (a forgalmi jelentes fejlecе) |
| PV_AZONOSITO | Penzvalto/penztar azonosito a zalog jelentesben (pl. A0AYTS) |
| UZLETHELYISEG_AZONOSITO | Uzlethelyiseg numerikus azonosito (pl. 1551, 1679) |
| Ugyfeles jelentes | Hatosagi adatszolgaltatas: tranzakcionkenti termeszetes-szemely/ceg azonosito mezok |
| Banki import TXT | Bankok fele kuldott ugyfeles tranzakcios export (CSV `;` szeparator) |

## Forras-fajlok katalogus
**A) `Kósa Szervezés/Követelmény lista/zalog_requirment.rqm`** — SAP/Sybase **PowerDesigner** Requirements Model (XML, `signature=RQM_MODEL_XML`, v16.5). Neve `zalog_kovetelmenyek`, Objects=135. A modell-opciok (NamingOptions, fontok) kinyerhetok; a 135 kovetelmeny-objektum reszletes tartalma PowerDesigner nelkul nem trivialisan olvashato → TBD ha uzletileg kell. **Zalog-termek**, NEM EXV.
**B) `.../Dokumentumok/Banki import TXT fájl ügyfeles ZÁLOG ZA20241029.csv`** — `;`-szeparalt ugyfeles tranzakcios export. Fejlec-csoportok: tranzakcio adatai (ugyfel tipus, uzlethelyiseg azonosito, datum, osszeg, valutanem, eladas/vetel, alkalmazott arfolyam, Ft osszeg, tranzakcio egyedi azonositoja) + termeszetes szemely azonosito (csaladi+utonev, szuletesi nev, szul. datum/hely, anyja neve, allampolgarsag, okmany tipus/szam, lakcim) + ceges ugyfel + ceg neveben eljaro szemely adatai. Encoding: legacy (nem UTF-8). Pelda sorok valos PII-t tartalmaznak (zalog forgalom 2024.10.29).
**C) `.../Dokumentumok/Ügyfeles jelentés_ BE20241026.csv`** — azonos mezostrukturaju ugyfeles jelentes (BE prefixu sorok, 2024.10.26).
**D) `.../Dokumentumok/Forgalmi és készlet jelentés ZÁLOG ZM241024.txt`** — strukturalt szovegformatum: `BEGIN` / `JELENTES PENZTARALLOMANY` blokkok uzlethelyisegenkent, `KP <valuta> <cimlet> <darab>` cimletes keszletsorokkal (pl. `KP EUR 100 39`). Fejlec: EXPRESSZ EKSZERHAZ, TNAP, PV_AZONOSITO.
**E) `.../Dokumentumok/Zálog kk 202409 hó.xlsx`** — zalog kezelesi koltseg kimutatas 2024.09 (xlsx, zalog-termek).
**F) `.../Dokumentumok/Expressz Ékszerház és Minibank Kft forgalom 202409 hó.ods`** — havi forgalmi kimutatas a zalogos tarsasagra (ODS).
**G) `.../Dokumentumok/P91.TXT`** — bizonylat-listazas adott idoszakra (Datum/Ido/Blokk/Valuta osszege/Ft osszege/Kedv.arf/Arfolyam oszlopok; V…/E… blokk-azonositok). Tartalmilag valuta-tranzakcios bizonylat-export jellegu, de a zalogos `Dokumentumok` mappabol szarmazik → besorolas TBD.

## 9. Vegrehajtasi utasitas az AI-ugynoknek
### 9.1 Elokeszites
Ez katalogus-stub. NINCS valutavalto implementacios feladat. A fajlok a zalog (EXZ) kulon termek input-jai.
### 9.2 Fazisok (acceptance criteria-val)
- Fazis 0 (egyetlen): rogziteni hogy zalog-scope OUT. AC: uzleti dontes, hogy az ugyfeles/banki export mezostrukturaja relevans-e a valuta NAV-riportjahoz (NFR-ZAL-01) — kulon feladatban, NEM itt.
### 9.3 Tesztes
Nincs (OUT).

## 10. Kockazatok / Nyitott kerdesek (TBD)
| # | Kerdes | Miert fontos | Mit kell tudni |
|---|---|---|---|
| 1 | A zalog-termek egyaltalan resze-e a megbizasnak? | A teljes mappa OUT, ha nem | Uzleti dontes (Kósa) |
| 2 | Az ugyfeles/banki CSV mezostruktura atveheto-e a valuta NAV-exporthoz? | Hatosagi parity | Csak ha igen → kulon EXV-feladat, NEM zalog |
| 3 | `P91.TXT` valuta vagy zalog? | Bizonylat-export jellegu | Forras-mappa zalogos, de tartalom valutas → tisztazni |
| 4 | `zalog_requirment.rqm` 135 objektumanak tartalma | Ha kell, PowerDesigner export | Tool-fuggo kinyeres TBD |

## 11. Verifikacios checklist
- [x] minden FR-hez forrás-hivatkozás (nincs EXV-FR — OUT)
- [x] 0 hallucináció (csak a kinyert CSV/TXT/RQM fej + minta)
- [x] minden TBD jelölt
VERIFIKACIO: FR=0 db, TBD=4 db (+1 NFR), érintett csomag(ok)=NINCS (kulon zalog-termek, OUT). Katalogizalt forras: 7 fajl (rqm + 2 csv + 1 txt + 1 xlsx + 1 ods + P91.TXT).
