# Modul: Bizonylat-minták (régi program nyomtatott bizonylatai)  (forrás: Bizonylatok/Forint átvételi bizonylat.jpg; Extra tranzakciós díjak _ Foglaló _ Pénztári adatlap.jpg; KKTG átadás és átvétel.jpg; kktg átadás átvétel II.jpg; Kezelési költség dekádzárása és Pénztári átadás.jpg; Pénztári átadás 2.jpg; pénztári átvétel.jpeg; Áfolyam nyomtatás _ Pénztárosi nyilatkozat.jpg; Pénztár állás.jpg)

## 1. Cel
A régi pénzváltó-program nyomtatott bizonylatainak mező- és fejléc-szintű specifikációja, hogy az új rendszer azonos tartalmú, jogszerű bizonylatokat tudjon kiállítani.

## 2. Scope
### IN
- Forint átvételi bizonylat (NYUGTA / EXCHANGE PURCHASE) + JOGCIM NYILATKOZAT.
- Extra tranzakciós díjak lista (egyedi kezelési díjak).
- Pénztári adatlap (átadólap belső dokumentum).
- Kezelési költség átadási/átvételi bizonylat (KKTG) + Kezelési költség dekádzárása.
- Pénztári átadás / pénztári átvétel bizonylat.
- Árfolyam nyomtatás (vételi/eladási + elszámoló árfolyam lista) + Pénztárosi nyilatkozat.
- Pénztár állás (pillanatnyi készlet/forgalom kimutatás).
### OUT
- A bizonylatokhoz tartozó tranzakció-folyamatok üzleti logikája (külön modulok).
- Foglaló bizonylat — külön MD (`b4-foglalo.md`).
- A díjak/árfolyamok kiszámításának szabályai — itt csak a megjelenítendő mezők. **TBD** ahol a számítás nem látszik.

## 3. Szakteruleti szereplok
| Szerep | Jogosultsag | RBAC ertek |
| --- | --- | --- |
| Pénztáros | Nyugta/átvételi bizonylat kiállítás, pénztári átadás/átvétel aláírás, pénztárosi nyilatkozat aláírás, árfolyam/pénztár állás nyomtatás | TBD |
| Értéktáros (átvevő/átadó "ertektar") | Pénztári átadásnál szállító/átvevő (átadás 1: "SZALLITO NEVE: ertektar") | TBD |
| Belsőellenőr / Ügyvezető | Dekádzárás, kezelési költség ellenőrzés (a forrásból nem azonosítható) | TBD |

## 4. Funkcionalis kovetelmenyef (FR)
| ID | Leiras | Forrás-hivatkozas | Prio | Csomag |
| --- | --- | --- | --- | --- |
| FR-1 | Minden bizonylat közös fejléce: cégnév "EXCLUSIVE BEST CHANGE ZRT.", fiók-szám+város (pl. "75. <VAROS>"), cím ("<CIM>"), adószám "<ADOSZAM>", telefon "06/XX-XXX-XXXX" | forint_atveteli.jpg, kktg1.jpg, kktg2.jpg, penztar_atadas2.jpg | M | penztar-client |
| FR-2 | **Forint átvételi bizonylat (NYUGTA / EXCHANGE PURCHASE):** sorszám (INVOICE NR, pl. <BIZONYLAT_SZAM>), dátum (DATE), idő (TIME), nyugtaszám | forint_atveteli.jpg ("NYUGTA", "Valuta vetel / EXCHANGE (PURCHASE)", "Sorszam (INVOICE NR)", "Datum (DATE)", "Ido (TIME)", "Nyugtaszam") | M | penztar-client |
| FR-3 | Forint átvételi bizonylaton áfa-mentesség jelölés + jogszabályi hivatkozás | forint_atveteli.jpg ("Adomentes", "Szj - 67.13.10.0", "...2007. evi CXVII tv. 86 § e) alapjan mentes az ado alol") | M | penztar-client |
| FR-4 | Devizaváltási tételek táblázat: V.nem (CURR), Árfolyam (RATE), B.jegy CASH (mennyiség), Forint VALUE | forint_atveteli.jpg ("V.nem Arfolyam B.jegy Forint / CURR. RATE CASH VALUE", "EUR 38,840 26,000 1,009,840") | M | penztar-client |
| FR-5 | Összesítő sorok: Kerekítés (ROUNDING), Nettó Ft (SUM TOTAL), Kez. ktsg (HANDLING-FEE), Kifizetve (PAID) | forint_atveteli.jpg ("Kerekites (ROUNDING): 0", "Netto Ft (SUM TOTAL): 1,007B,400", "Kez. ktsg (HANDLING-FEE): 9,990", "Kifizetve (PAID): 1,088,410") | M | penztar-client |
| FR-6 | Ügyfél adatai blokk: név (NAME), anyja neve, szül. hely, szül. idő, lakcím (ADDRESS), okmánytípus (DOC TYPE), okmány szám (NR), kiemelt közszereplő jelölés, teljesítés módja (készpénz), deviza-státusz (Belföldi) | forint_atveteli.jpg ("ugyfel adatai / Nev (NAME): <NEV>", "anyja neve: <ANYJA_NEVE>", "szul-i hely: <SZUL_HELY>", "szul-i ido: <SZUL_DATUM>", "Lakcim (ADDRESS)", "DOC TYPE: SZIG", "NR: <OKMANY_SZAM>", "Az ugyfel nem kozszereplo", "keszpenzben teljesitjuk", "Deviza-statusz: Belfoldi") | M | penztar-client |
| FR-7 | Lábléc: "Raiffeisen Bank Zrt. KIEMELT KOZVETITOJE" + reklám szöveg ("EXCLUSIVE CHANGE KEDVEZOBB, GYORSABB, BIZTONSAGOSABB") | forint_atveteli.jpg | C | penztar-client |
| FR-8 | **JOGCIM NYILATKOZAT** külön bizonylat: büntetőjogi felelősség tudatában tett nyilatkozat a tranzakció megbízásáról, 5 (öt) munkanapos bejelentési kötelezettség az adatváltozásra, "Pénzeszk(öz) forrasa: GH", aláírás-hely + felelős név ("<NEV>") | forint_atveteli.jpg jobb oldal ("JOGCIM NYILATKOZAT", "Buntetojogi felelossegem tudataban nyilatkozom...", "5 (ot) munkanapon belul koteles vagyok bejelenteni", "Penzeszk... forrasa: GH", "ugyfel alairasa") | M | penztar-client |
| FR-9 | **Extra tranzakciós díjak lista:** oszlopok Datum/Biz., Fbeszr/Kezdij, Engedélyező; soronként bizonylatszám + összeg + "EGYEDI KEZDIJ" jelölés + díj | extra_dij.jpg ("Datum/Biz. Fbeszr/Kezdij Engedelyezo", "2024.03.06 387,000 Ft EGYEDI KEZDIJ / <BIZONYLAT_SZAM> 590 Ft", "2024.03.07 778,800 Ft ... 1,180 Ft", "...36,830 Ft... 60 Ft", "...1,034,474 Ft... 1,550 Ft") | M | penztar-client |
| FR-10 | **Pénztári adatlap (belső):** pénztárszám, dátum, átadó, átvevő, "KORLEVELEK" (iktatószámmal), "UGYFELEK RENDELESE", "KESZLET RENDELESE ERTEKTAR FELE", "KONKURENCIAVAL KAPCS TUDNIVALOK", "EGYEB TUDNIVALOK" szabad-szöveges rovatok | extra_dij.jpg ("PENZTARI ADATLAP", "Penztarszam", "Datum: 2024.03.12", "Atado: <NEV>", "Atvevo: <NEV>", "KORLEVELEK", "2023.06.30 Targy:...", "Iktatoszam: <IKTATO_SZAM>", a rovatok címei) | C | penztar-client |
| FR-11 | **Kezelési költség ÁTVÉTELI bizonylat (KKTG):** fejléc "KEZELESI KOLTSEG ATVETELI BIZONYLATA", bizonylatszám (B-000756), bizonylat kelte, átadó pénztár (0074), átvett összeg (1,000,000 Ft), szállítónév, plomba-szám, megjegyzés, 2 aláírás (atado/atvevo) | kktg1.jpg | M | penztar-client |
| FR-12 | **Kezelési költség ÁTADÁSI bizonylat (KKTG):** fejléc "KEZELESI KOLTSEG ATADASI BIZONYLATA", bizonylatszám (K-000756), bizonylat kelte, átvevő pénztár (RB), átadott összeg (5,347,015 Ft), szállítónév, plomba-szám, megjegyzés, 2 aláírás | kktg2.jpg | M | penztar-client |
| FR-13 | **Kezelési költség dekádzárása (10 nap):** fejléc "X. PENZTAR" + cím, időszak ("2024 MARCIUS HAVI 1. DEKAD KEZ-I DIJAK 2024.03.01 - 2024.03.10"), tételsorok (Sor, Np, Bizonylat, Ft.atvetel, Ft.atadas), "Dekad forgalom", "Nyito forint", "Zaro forint", "Osszes forint", dátum + penztaros | kktg_dekad.jpg ("KEZELESI KOLTSEG DEKADZARASA", "Sor Np Bizon. Ft.atvetel Ft.atadas", "Dekad forgalom", "Nyito/Zaro/Osszes forint") | M | penztar-client |
| FR-14 | **Pénztári átadás bizonylat:** fejléc + "Penztari atadas" + "MASOLATI PELDGNY", átvevő (76), sorszám (INVOICE NR FF07541444), dátum, idő, adómentes Szj, deviza-tétel sor (V.nem/Árf/B.jegy/Forint, pl. HUF 100.000 1,631,650), Kifizetve (PAID), SZALLITO NEVE (ertektar), PLOMBA SZAMA, 2 aláírás (atado/atvevo) | kktg_dekad.jpg alsó rész, penztar_atadas2.jpg ("Penztari atadas", "MASOLATI PELDGNY", "Atvevo: 76", "Sorszam FF07541444", "HUF 100.000 1,631,650", "Kifizetve(PAID): 1,631,650", "SZALLITO NEVE: ertektar", "PLOMBA SZAMA") | M | penztar-client |
| FR-15 | A pénztári átadás devizában is mehet: EUR-tétel (V.nem EUR, Árf 39418.0000, B.jegy 15.000, Forint 5,912,700), bizonylat "EGYEDI KOTES", átvevő ERB | penztar_atadas2.jpg ("Penztari atadas", "EGYEDI KOTES RB", "INVOICE NR FF07514435", "EUR 39418.0000 15.000 5,912,700", "SZALLITO NEVE: <NEV>", "PLOMBA SZAMA <PLOMBA_SZAM>") | M | penztar-client |
| FR-16 | **Pénztári átvétel bizonylat:** fejléc + "Penztari atvetel" + "MASOLATI PELDGNY", átadó (0074), sorszám (V07S141183), dátum, idő, adómentes Szj, több deviza-tétel (CHF 41220.0000 3.000 1,236,600; EUR 39530.0000 25.000 9,882,500), Kifizetve (PAID 11,119,100), szállítónév, plomba-szám, nyilatkozat-szöveg (átvettem a pénzkészletet, tételesen visszaszámoltam), 2 aláírás | penztar_atvetel.jpeg | M | penztar-client |
| FR-17 | **Árfolyam nyomtatás (vételi/eladási):** fejléc + dátum-idő "orai valuta arfolyamok", oszlopok: Valuta nem, Egyseg (100), Veteli arfolyam, Eladasi arfolyam; soronként valutakód + két árfolyam (pl. EUR 100 38970.0000 39739.0000); a nem-kereskedett valuták ".0" jelöléssel (HRK, RCH) | arfolyam_nyilatkozat.jpg bal ("...orai valuta arfolyamok", "Valuta nem Egyseg Veteli arfolyam Eladasi arfolyam") | M | arfolyam-keszito-client |
| FR-18 | **Elszámoló árfolyam lista:** fejléc + dátum-idő "orai elszamolo arfolyamok", oszlopok: Valuta nem, A valuta megnevezese (teljes név), Elszamolo arfolyam; valutakód+név+egy árfolyam (pl. EUR EURO 39700.0000) | arfolyam_nyilatkozat.jpg közép ("...orai elszamolo arfolyamok", "Valuta nem / A valuta megnevezese / Elszamolo arfolyam") | M | arfolyam-keszito-client |
| FR-19 | **Pénztárosi nyilatkozat:** fejléc "NYILATKOZAT", szöveg (alulírott <pénztáros> az EXCLUSIVE BEST CHANGE ZRT <fiók>. szamu penztaranak dolgozoja kijelentem, hogy a <dátum> napi zaroszalagon szereplo osszegek a valosagnak megfelelnek es a penztar trezorjaban elzarasra kerultek), unnepi/vasarnapi zarvatartas indok, dátum, penztaros aláírás | arfolyam_nyilatkozat.jpg jobb ("NYILATKOZAT", "Alulirott <NEV> az EXCLUSIVE BEST CHANGE ZRT 76. szamu penztaranak dolgozoja kijelentem...", "Datum: 2024.03.09") | M | penztar-client |
| FR-20 | **Pénztár állás (pillanatnyi):** fejléc + cég + fiók ("75 BIKISCSABAI IRTIKTOR") + dátum-idő "perci penztar allas", oszlopok: Val.nem, Nyito osszeg, Forgalom egyenlege, Penztar allas; soronként valuta + 3 érték (pl. EUR 102.000 -85.000 17.000); HUF sor nagy összeggel | penztar_allas.jpg ("...perci penztar allas", "Val.nem Nyito osszeg Forgalom egyenlege Penztar allas", "CHF/CZK/EUR/HUF/ILS/PLN/RON/RSD/TRY/USD" sorok) | M | penztar-client |
| FR-21 | A pénztár állás bizonylat alján kezelési-díj egyenleg blokk: "Napi nyito kez-i dij", "Kezelesi dij atvetel", "Kezelesi dij atadas", "Pillanatnyi zaro osszeg" Ft-ban | penztar_allas.jpg alsó rész ("Napi nyito kez-i dij ...: 3,482,805 Ft", "Kezelesi dij atvetel", "Kezelesi dij atadas ...: 3,482,805 Ft", "Pillanatnyi zaro osszeg") | M | penztar-client |

## 5. Nem-funkcionalis kovetelmenyef (NFR)
| ID | Leiras | Merheto kriterium |
| --- | --- | --- |
| NFR-1 | Hőnyomtató keskeny szalag formátum, monospace, pontozott elválasztó vonalak | A képek mind ESC/POS-szerű szalag-bizonylatok |
| NFR-2 | Kétnyelvű (magyar / angol zárójeles) mezőcímkék a vevői bizonylatokon | forint_atveteli.jpg: "Sorszam (INVOICE NR)", "Kifizetve (PAID)" |
| NFR-3 | Pénznem-formátum ezres tagolással (vessző), pl. "1,009,840" / "11,119,100" | minden tranzakciós bizonylat |
| NFR-4 | "MASOLATI PELDGNY" jelölés a belső/másolati átadás-átvétel bizonylatokon | penztar_atadas2.jpg, kktg_dekad.jpg |
| NFR-5 | Sorszám-prefixek konzisztensek típusonként (V=vétel, FF=átadás, K=kez.ktg átadás, B=kez.ktg átvétel) | a látható sorszámok prefixei |

## 6. Adatmodell-erintettseg
- A bizonylatok meglévő tranzakció/átadás-átvétel/dekádzárás/árfolyam/készlet entitásokból renderelődnek. Új tárolt entitás itt nem feltétlen kell — a fókusz a render-mező-leképezés.
- Mezők, amelyek a forrásból kötelezőek a rendereléshez: cég-fejléc (cég, fiók, cím, adószám, tel), bizonylat sorszám/prefix, dátum, idő, deviza-tétel sorok (devizanem, árfolyam, mennyiség, forintérték), kerekítés, kezelési költség, kifizetett összeg, ügyfél-snapshot, szállítónév, plomba-szám.
- SQLite mirror: **IGEN** a pénztári bizonylatokra (penztar-client lokálisan nyomtat); az árfolyam-listák az arfolyam-keszito-client-en. Indok: offline nyomtatás.
- Migráció szükséges: valószínűleg **NEM** új tábla (renderelés), kivéve ha a sorszám-prefix séma vagy plomba/szállító mezők hiányoznak → **TBD**.

## 7. Fuggosegek
- Árfolyam-modul (vételi/eladási/elszámoló) — FR-17/18 forrása.
- Tranzakció-modul (vétel) — FR-2..8.
- Pénztári átadás-átvétel modul — FR-11..16.
- Dekádzárás / kezelési költség elszámolás — FR-13, FR-21.
- Külső: jogszabályi hivatkozás (2007. évi CXVII. tv. 86. § e) — fix szöveg; NAV/MNB API a forrásban nem szerepel → **TBD**.

## 8. Domain-szotar
| Fogalom | Magyarazat |
| --- | --- |
| Forint átvételi bizonylat / NYUGTA | Valuta vétel (EXCHANGE PURCHASE) vevői nyugtája. |
| Jogcím nyilatkozat | Ügyfél büntetőjogi felelősség mellett tett nyilatkozata a pénzeszköz forrásáról. |
| Kezelési költség (kez. ktsg / kez-i dij) | A tranzakcióhoz felszámított kezelési díj. |
| KKTG átadás/átvétel | Kezelési költség pénztárak/értéktár közötti átadása-átvétele (plombával). |
| Dekádzárás | 10 napos időszaki zárás (kezelési díjak elszámolása). |
| Pénztári átadás/átvétel | Készpénz/deviza átadása-átvétele pénztár↔értéktár között, szállító+plomba. |
| Elszámoló árfolyam | A belső elszámoláshoz használt egységes árfolyam (vételi/eladási helyett egy érték). |
| Pénztárosi nyilatkozat | Zárás utáni nyilatkozat a zárószalag valódiságáról és a trezor-elzárásról. |
| Pénztár állás | Pillanatnyi nyitó/forgalom/egyenleg kimutatás valutánként + kez.díj egyenleg. |
| Plomba-szám | A pénzszállító zacskó/doboz egyedi plomba-azonosítója. |

## 9. Vegrehajtasi utasitas az AI-ugynoknek
### 9.1 Elokeszites
- Olvasd be a 9 forrásképet; mindegyik bizonylathoz készítsd el a mező-leképezést a 4. szekció alapján. Ne hasonlíts a meglévő programhoz.
### 9.2 Fazisok
1. **Vevői bizonylatok** (Forint átvételi NYUGTA + Jogcím nyilatkozat). AC: minden FR-2..8 mező renderelődik, kétnyelvű címkék, áfa-mentesség szöveg.
2. **Belső dokumentumok** (Extra díjak lista, Pénztári adatlap). AC: FR-9/10 rovatok megjelennek.
3. **Átadás-átvétel + KKTG** (FR-11..16). AC: szállítónév + plomba-szám kötelező, helyes prefix (B/K/FF), 2 aláírás-hely.
4. **Dekádzárás + Pénztár állás + kez.díj egyenleg** (FR-13, FR-20, FR-21). AC: nyitó/forgalom/záró egyenleg valutánként.
5. **Árfolyam nyomtatás + Pénztárosi nyilatkozat** (FR-17..19). AC: vételi/eladási + elszámoló lista + nem-kereskedett valuta jelölés.
### 9.3 Tesztes
- Snapshot/render teszt minden bizonylat-típusra a forráskép mezőivel.
- Számformátum teszt (ezres tagolás), kétnyelvű címke teszt.
- Egyenleg-konzisztencia teszt (pénztár állás: nyitó + forgalom = egyenleg).

## 10. Kockazatok / Nyitott kerdesek (TBD)
| # | Kerdes | Miert fontos | Mit kell tudni |
| --- | --- | --- | --- |
| TBD-1 | A kezelési költség (HANDLING-FEE) számítási szabálya | Pontos összeg | A bizonylaton csak az eredmény látszik (9,990; 1,550 Ft stb.) |
| TBD-2 | A sorszám-prefix séma teljes katalógusa (V, FF, K, B, U?, K00?) | Egyediség, típus-azonosítás | Csak részleges prefixek láthatók |
| TBD-3 | Az "EGYEDI KEZDIJ" / "EGYEDI KOTES" engedélyezési folyamata | Jogosultság/audit | A lista mutat "Engedelyezo" oszlopot, de a folyamat nem |
| TBD-4 | Elszámoló árfolyam forrása és frissítési ciklusa | Helyes érték | A bizonylat csak a kész listát mutatja |
| TBD-5 | A pénztári adatlap (KORLEVELEK / RENDELESEK) digitalizálandó-e strukturáltan vagy szabad szöveg | Adatmodell | A rovatok címei láthatók, kitöltés szabad szöveg |
| TBD-6 | A "Pénzeszk forrasa: GH" kódszótár (GH, egyéb kódok) | Jogcím nyilatkozat | Csak "GH" érték látható |
| TBD-7 | RBAC: ki nyomtathat árfolyam-listát / pénztár állást / dekádzárást | Jogosultság | A forrás csak penztaros aláírást mutat |
| TBD-8 | Néhány érték kézírásos/elmosódott (egyes összegek pontossága) | Adathűség | Pl. forint_atveteli.jpg "1,007B,400" tizedesjegy bizonytalan |

## 11. Verifikacios checklist
- [x] minden FR-hez forrás-hivatkozás
- [x] 0 hallucináció (csak forrásban látható adat; bizonytalan értékek TBD-8 alatt jelölve)
- [x] minden TBD jelölt
VERIFIKACIO: FR=21 db, TBD=8 db, érintett csomag(ok)=penztar-client (vevői + átadás-átvétel + zárás bizonylatok), arfolyam-keszito-client (FR-17, FR-18)
